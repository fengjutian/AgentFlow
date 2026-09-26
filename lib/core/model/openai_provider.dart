/// OpenAI-compatible model provider.
///
/// Speaks the `/chat/completions` tool-calling protocol used by OpenAI, DeepSeek,
/// Qwen, Groq, Together, OpenRouter, llama.cpp servers and most self-hosted
/// gateways. All endpoint/credential data comes from [ModelRequest.config], so a
/// single provider instance serves any configured backend — matching the design
/// doc's "OpenAI Compatible API" decision (§33).
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../message.dart';
import 'model_provider.dart';

class OpenAiCompatibleProvider implements ModelProvider {
  OpenAiCompatibleProvider({http.Client? client, this.timeout = const Duration(seconds: 120)})
      : _client = client ?? http.Client();

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
  Future<ModelResponse> generate(ModelRequest request) async {
    final config = request.config;
    final uri = _endpoint(config);

    final body = <String, dynamic>{
      'model': config.model,
      'messages': request.messages.map((m) => m.toOpenAiJson()).toList(),
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
      if (request.tools.isNotEmpty)
        'tools': request.tools.map((t) => t.toOpenAiJson()).toList(),
      if (request.tools.isNotEmpty) 'tool_choice': 'auto',
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (config.apiKey.isNotEmpty) 'Authorization': 'Bearer ${config.apiKey}',
    };

    final http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeout);
    } on TimeoutException {
      throw ModelException('Request to ${uri.host} timed out.');
    } on http.ClientException catch (e) {
      throw ModelException('Network error: ${e.message}');
    }

    if (response.statusCode != 200) {
      throw ModelException(
        _extractError(response.body) ?? 'Provider returned ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    return _parse(response.body);
  }

  ModelResponse _parse(String rawBody) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawBody);
    } on FormatException catch (e) {
      throw ModelException('Malformed JSON from provider: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ModelException('Unexpected provider response shape.');
    }

    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const ModelException('Provider returned no choices.');
    }
    final message = (choices.first as Map<String, dynamic>)['message']
        as Map<String, dynamic>?;
    if (message == null) {
      throw const ModelException('Choice has no message.');
    }

    final content = (message['content'] as String?) ?? '';
    final rawToolCalls = message['tool_calls'] as List<dynamic>?;
    final toolCalls = <ToolCall>[];
    if (rawToolCalls != null) {
      for (final raw in rawToolCalls) {
        if (raw is Map<String, dynamic>) {
          toolCalls.add(ToolCall.fromJson(raw));
        }
      }
    }

    final finish =
        ((choices.first as Map<String, dynamic>)['finish_reason'] as String?) ??
            (toolCalls.isNotEmpty ? 'tool_calls' : 'stop');

    final usage = decoded['usage'] as Map<String, dynamic>?;
    return ModelResponse(
      content: content,
      toolCalls: toolCalls,
      finishReason: _mapFinish(finish, toolCalls.isNotEmpty),
      rawUsage: usage == null
          ? null
          : <String, int>{
              for (final entry in usage.entries)
                if (entry.value is num) entry.key: (entry.value as num).toInt(),
            },
    );
  }

  FinishReason _mapFinish(String finish, bool hasToolCalls) {
    if (hasToolCalls) return FinishReason.toolCalls;
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
