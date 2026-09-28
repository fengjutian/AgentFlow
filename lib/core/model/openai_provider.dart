/// OpenAI-compatible model provider with SSE streaming.
///
/// Speaks the `/chat/completions` tool-calling protocol used by OpenAI, DeepSeek,
/// Qwen, Groq, Together, OpenRouter, llama.cpp servers and most self-hosted
/// gateways. All endpoint/credential data comes from [ModelRequest.config], so a
/// single provider instance serves any configured backend — matching the design
/// doc's "OpenAI Compatible API" decision (§33).
///
/// Requests include `"stream": true` and the response is consumed as a
/// Server-Sent Events (SSE) stream. Each `data:` payload is parsed and mapped
/// to a [ModelChunk]: [ContentDelta] for incremental text, [ToolCallDelta] for
/// tool invocations, and [FinishChunk] when the model signals completion.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../message.dart';
import 'model_provider.dart';

class OpenAiCompatibleProvider implements ModelProvider {
  OpenAiCompatibleProvider({
    http.Client? client,
    this.timeout = const Duration(seconds: 120),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  @override
  String get id => 'openai-compatible';

  @override
  String get displayName => 'OpenAI-compatible';

  /// Resolves the full completions URL from a configured base URL that may or
  /// may not already include `/chat/completions`.
  Uri _endpoint(ModelConfig config) {
    var base = config.baseUrl.trim();
    if (base.isEmpty) {
      throw const ModelException('Missing API base URL. Configure it in Settings.');
    }
    base = base.replaceAll(RegExp(r'/+$'), '');
    if (base.endsWith('/chat/completions')) return Uri.parse(base);
    if (!base.endsWith('/v1')) {
      // Convenience: most OpenAI-compatible hosts expect a /v1 prefix.
      base = '$base/v1';
    }
    return Uri.parse('$base/chat/completions');
  }

  @override
  Stream<ModelChunk> generate(ModelRequest request) async* {
    final config = request.config;
    final uri = _endpoint(config);

    final body = <String, dynamic>{
      'model': config.model,
      'messages': request.messages.map((m) => m.toOpenAiJson()).toList(),
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
      'stream': true,
      if (request.tools.isNotEmpty)
        'tools': request.tools.map((t) => t.toOpenAiJson()).toList(),
      if (request.tools.isNotEmpty) 'tool_choice': 'auto',
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (config.apiKey.isNotEmpty) 'Authorization': 'Bearer ${config.apiKey}',
    };

    final http.StreamedResponse response;
    try {
      final req = http.Request('POST', uri)
        ..headers.addAll(headers)
        ..body = jsonEncode(body);
      response = await _client.send(req).timeout(timeout);
    } on TimeoutException {
      throw ModelException('Request to ${uri.host} timed out.');
    } on http.ClientException catch (e) {
      throw ModelException('Network error: ${e.message}');
    }

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw ModelException(
        _extractError(errorBody) ??
            'Provider returned ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    // --- SSE stream parsing ---------------------------------------------------
    // Each SSE event is delimited by blank lines. We look for `data:` lines,
    // skip comments and `[DONE]`, and parse the JSON payload into ModelChunks.
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    // Tool call arguments may arrive across multiple SSE deltas keyed by index.
    final toolCallParts = <int, _ToolCallParts>{};

    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;

      final data = trimmed.substring(5).trim();
      if (data == '[DONE]') break;

      final dynamic decoded;
      try {
        decoded = jsonDecode(data);
      } on FormatException {
        continue; // Skip malformed SSE payloads.
      }
      if (decoded is! Map<String, dynamic>) continue;

      final choices = decoded['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) continue;
      final choice = choices.first as Map<String, dynamic>;
      final delta = choice['delta'] as Map<String, dynamic>?;

      if (delta != null) {
        // Incremental text.
        final content = delta['content'] as String?;
        if (content != null && content.isNotEmpty) {
          yield ContentDelta(content);
        }

        // Incremental tool calls — arguments can span multiple deltas.
        final rawToolCalls = delta['tool_calls'] as List<dynamic>?;
        if (rawToolCalls != null) {
          for (final raw in rawToolCalls) {
            if (raw is Map<String, dynamic>) {
              final index = raw['index'] as int? ?? 0;
              final parts = toolCallParts.putIfAbsent(
                index,
                _ToolCallParts.new,
              );

              final id = raw['id'] as String?;
              if (id != null) parts.id = id;

              final function = raw['function'] as Map<String, dynamic>?;
              if (function != null) {
                final name = function['name'] as String?;
                if (name != null) parts.name = name;
                final arguments = function['arguments'] as String?;
                if (arguments != null) parts.argumentsBuffer.write(arguments);
              }
            }
          }
        }
      }

      // Some providers include finish_reason in the last chunk alongside delta.
      final finishReason = choice['finish_reason'] as String?;
      if (finishReason != null && finishReason != 'null') {
        for (final parts in toolCallParts.values) {
          if (parts.id.isNotEmpty) {
            yield ToolCallDelta(parts.toToolCall());
          }
        }
        toolCallParts.clear();

        final usage = decoded['usage'] as Map<String, dynamic>?;
        yield FinishChunk(
          reason: _mapFinish(finishReason),
          usage: usage == null
              ? null
              : <String, int>{
                  for (final entry in usage.entries)
                    if (entry.value is num)
                      entry.key: (entry.value as num).toInt(),
                },
        );
        return;
      }
    }

    // Stream ended without an explicit finish_reason — flush any accumulated
    // tool calls and emit a stop signal.
    for (final parts in toolCallParts.values) {
      if (parts.id.isNotEmpty) {
        yield ToolCallDelta(parts.toToolCall());
      }
    }
    toolCallParts.clear();
    yield const FinishChunk(reason: FinishReason.stop);
  }

  FinishReason _mapFinish(String finish) {
    switch (finish) {
      case 'length':
        return FinishReason.length;
      case 'tool_calls':
      case 'function_call':
        return FinishReason.toolCalls;
      case 'stop':
      default:
        return FinishReason.stop;
    }
  }

  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          return error['message'] as String;
        }
        if (decoded['message'] is String) return decoded['message'] as String;
      }
    } catch (_) {
      // fall through to raw body
    }
    return body.isEmpty ? null : body;
  }

  void close() => _client.close();
}

/// Accumulates fragments of a single tool call arriving across multiple SSE
/// deltas. The model streams function `arguments` as partial JSON strings
/// that must be concatenated before parsing.
class _ToolCallParts {
  String id = '';
  String name = '';
  final StringBuffer argumentsBuffer = StringBuffer();

  ToolCall toToolCall() {
    Map<String, dynamic> args;
    try {
      final raw = argumentsBuffer.toString();
      final decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
      args = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      args = <String, dynamic>{'_raw': argumentsBuffer.toString()};
    }
    return ToolCall(id: id, name: name, arguments: args);
  }
}
