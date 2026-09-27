/// Domain models for workspaces, sessions and the persisted transcript.
///
/// These are plain, persistence-agnostic classes (no Drift imports). The storage
/// layer maps them to/from generated rows, and the UI/engine consume them
/// directly. [TranscriptMessage] is the durable form of a [ChatMessage] that also
/// keeps tool metadata (error flag, structured `data`) needed to re-render diffs
/// and terminal output when a session is reopened.
library;

import '../core/message.dart';

/// A persisted execution environment that can be attached to a workspace.
///
/// Credentials are deliberately absent: passwords, tokens and private keys are
/// addressed by this configuration's [id] and live in [SecretStore].
class RuntimeConfig {
  const RuntimeConfig({
    required this.id,
    required this.label,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
    this.options = const <String, dynamic>{},
  });

  final String id;
  final String label;

  /// `local`, `termux`, `ssh`, or a future runtime kind.
  final String kind;

  /// Non-secret transport settings such as host, port and remote root.
  final Map<String, dynamic> options;
  final DateTime createdAt;
  final DateTime updatedAt;

  RuntimeConfig copyWith({
    String? label,
    String? kind,
    Map<String, dynamic>? options,
    DateTime? updatedAt,
  }) =>
      RuntimeConfig(
        id: id,
        label: label ?? this.label,
        kind: kind ?? this.kind,
        options: options ?? this.options,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// A connected project the agent operates on (design doc §18).
class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.rootDirectory,
    required this.createdAt,
    this.runtimeId = 'local',
    this.settings = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final String rootDirectory;
  final DateTime createdAt;

  /// `local` | `termux` | `ssh` ...
  final String runtimeId;

  /// Free-form per-workspace settings.
  final Map<String, dynamic> settings;

  bool get autoApprove => settings['autoApprove'] == true;

  List<String> get disabledTools =>
      (settings['disabledTools'] as List<dynamic>?)?.cast<String>() ??
      const <String>[];

  Workspace copyWith({
    String? name,
    String? rootDirectory,
    String? runtimeId,
    Map<String, dynamic>? settings,
  }) =>
      Workspace(
        id: id,
        name: name ?? this.name,
        rootDirectory: rootDirectory ?? this.rootDirectory,
        createdAt: createdAt,
        runtimeId: runtimeId ?? this.runtimeId,
        settings: settings ?? this.settings,
      );
}

/// One task/conversation inside a workspace (design doc §19).
class Session {
  const Session({
    required this.id,
    required this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
    this.title = 'New session',
    this.status = 'idle',
  });

  final String id;
  final String workspaceId;
  final String title;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Session copyWith({String? title, String? status, DateTime? updatedAt}) =>
      Session(
        id: id,
        workspaceId: workspaceId,
        title: title ?? this.title,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// A persisted message: a [ChatMessage] plus tool metadata for rendering.
class TranscriptMessage {
  const TranscriptMessage({
    required this.role,
    this.content = '',
    this.toolCalls = const <ToolCall>[],
    this.toolCallId,
    this.name,
    this.isError = false,
    this.data,
    required this.createdAt,
  });

  final MessageRole role;
  final String content;
  final List<ToolCall> toolCalls;
  final String? toolCallId;
  final String? name;
  final bool isError;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  bool get hasToolCalls => toolCalls.isNotEmpty;

  /// The model-facing view (drops UI-only metadata).
  ChatMessage toChatMessage() => ChatMessage(
        role: role,
        content: content,
        toolCalls: toolCalls,
        toolCallId: toolCallId,
        name: name,
        createdAt: createdAt,
      );

  factory TranscriptMessage.fromChat(ChatMessage m) => TranscriptMessage(
        role: m.role,
        content: m.content,
        toolCalls: m.toolCalls,
        toolCallId: m.toolCallId,
        name: m.name,
        createdAt: m.createdAt,
      );

  factory TranscriptMessage.fromToolResult(ToolResult r) => TranscriptMessage(
        role: MessageRole.tool,
        content: r.content,
        toolCallId: r.toolCallId,
        name: r.name,
        isError: r.isError,
        data: r.data,
        createdAt: DateTime.now(),
      );

  /// Serializes tool calls for storage using the OpenAI tool-call shape, which
  /// [ToolCall.fromJson] can read back.
  List<Map<String, dynamic>> toolCallsToJson() =>
      toolCalls.map((ToolCall c) => c.toOpenAiJson()).toList();

  static List<ToolCall> toolCallsFromJson(List<dynamic>? raw) {
    if (raw == null) return const <ToolCall>[];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> e) => ToolCall.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
