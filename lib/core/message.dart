/// Core conversation primitives shared by the Agent Core, model providers and
/// the persistence layer.
///
/// AgentFlow is not a plain chat app: a single turn can interleave user text,
/// assistant reasoning, tool invocations and tool observations. These models
/// capture that structure in a provider-agnostic way. The OpenAI-compatible
/// wire format is produced by [ChatMessage.toOpenAiJson] so the rest of the
/// codebase never depends on a concrete vendor schema.
library;

import 'dart:convert';

/// The author of a [ChatMessage].
enum MessageRole {
  system,
  user,
  assistant,

  /// A tool observation fed back into the model after a [ToolCall] executed.
  tool,
}

/// A request from the model to execute one of the registered tools.
class ToolCall {
  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  /// Provider-assigned id, echoed back on the matching [ToolResult].
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    final function = json['function'] as Map<String, dynamic>? ?? json;
    final rawArgs = function['arguments'];
    return ToolCall(
      id: (json['id'] ?? function['id'] ?? '') as String,
      name: (function['name'] ?? '') as String,
      arguments: _decodeArguments(rawArgs),
    );
  }

  static Map<String, dynamic> _decodeArguments(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      // Providers serialize arguments as a JSON string.
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Fall through to empty args; the tool layer validates required keys.
      }
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> toOpenAiJson() => <String, dynamic>{
        'id': id,
        'type': 'function',
        'function': <String, dynamic>{
          'name': name,
          'arguments': jsonEncode(arguments),
        },
      };
}

/// The outcome of executing a [ToolCall].
///
/// [content] is what the model sees on the next loop iteration. [data] carries
/// structured payloads (diffs, file listings, exit codes) for the UI without
/// bloating the model context.
class ToolResult {
  const ToolResult({
    required this.toolCallId,
    required this.name,
    required this.content,
    this.isError = false,
    this.data,
  });

  final String toolCallId;
  final String name;
  final String content;
  final bool isError;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toOpenAiJson() => <String, dynamic>{
        'role': 'tool',
        'tool_call_id': toolCallId,
        'content': content,
      };
}

/// A single message in a conversation.
class ChatMessage {
  ChatMessage({
    required this.role,
    this.content = '',
    this.toolCalls = const <ToolCall>[],
    this.toolCallId,
    this.name,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final MessageRole role;
  final String content;

  /// Present on assistant messages that request tool execution.
  final List<ToolCall> toolCalls;

  /// Present on [MessageRole.tool] messages, linking back to the [ToolCall].
  final String? toolCallId;
  final String? name;
  final DateTime createdAt;

  bool get hasToolCalls => toolCalls.isNotEmpty;

  /// True when the assistant produced a natural-language answer with no pending
  /// tool calls — i.e. the loop can terminate.
  bool get isFinalAnswer => role == MessageRole.assistant && !hasToolCalls;

  ChatMessage copyWith({String? content, List<ToolCall>? toolCalls}) =>
      ChatMessage(
        role: role,
        content: content ?? this.content,
        toolCalls: toolCalls ?? this.toolCalls,
        toolCallId: toolCallId,
        name: name,
        createdAt: createdAt,
      );

  /// Converts to the OpenAI chat-completions message schema.
  Map<String, dynamic> toOpenAiJson() {
    switch (role) {
      case MessageRole.tool:
        return <String, dynamic>{
          'role': 'tool',
          'tool_call_id': toolCallId ?? '',
          'content': content,
        };
      case MessageRole.assistant:
        final json = <String, dynamic>{
          'role': 'assistant',
          'content': content.isEmpty ? null : content,
        };
        if (hasToolCalls) {
          json['tool_calls'] =
              toolCalls.map((ToolCall c) => c.toOpenAiJson()).toList();
        }
        return json;
      case MessageRole.system:
        return <String, dynamic>{'role': 'system', 'content': content};
      case MessageRole.user:
        return <String, dynamic>{'role': 'user', 'content': content};
    }
  }

  factory ChatMessage.system(String content) =>
      ChatMessage(role: MessageRole.system, content: content);

  factory ChatMessage.user(String content) => ChatMessage(
        role: MessageRole.user,
        content: content,
        createdAt: DateTime.now(),
      );

  factory ChatMessage.fromToolResult(ToolResult result) => ChatMessage(
        role: MessageRole.tool,
        content: result.content,
        toolCallId: result.toolCallId,
        name: result.name,
        createdAt: DateTime.now(),
      );
}
