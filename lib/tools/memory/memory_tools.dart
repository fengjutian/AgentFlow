/// Agent tools for long-term memory (design doc §17).
///
/// Three tools let the agent manage durable workspace-scoped notes:
/// `remember` to save facts, `recall` to list or search them, and `forget` to
/// delete entries that are no longer relevant. The [MemoryManager] handles
/// persistence; these tools are the agent's only path to modify it.
library;

import '../../core/memory/memory_manager.dart';
import '../../core/message.dart';
import '../agent_tool.dart';
import '../tool_args.dart';

List<AgentTool> memoryTools(MemoryManager manager) => <AgentTool>[
  RememberTool(manager),
  RecallTool(manager),
  ForgetTool(manager),
];

/// Saves a new durable note for the workspace.
class RememberTool extends MutatingTool {
  RememberTool(this._manager);

  final MemoryManager _manager;

  @override
  String get name => 'remember';

  @override
  String get description =>
      'Save an important fact, decision, or observation about the current '
      'workspace so it persists across sessions. Use this when you learn '
      'something the user would want you to remember (e.g. "the project uses '
      'PostgreSQL 15", "deploy scripts live in /scripts"). Returns the saved '
      'entry id.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'content': <String, dynamic>{
        'type': 'string',
        'description':
            'The fact or observation to remember. Keep it concise and self-contained.',
      },
      'tags': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{'type': 'string'},
        'description':
            'Optional list of short topic tags for later retrieval (e.g. ["database", "config"]).',
      },
    },
    'required': <String>['content'],
  };

  @override
  String describeCall(Map<String, dynamic> arguments) =>
      'remember "${_truncate(optionalString(arguments, 'content'))}"';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final content = requireString(arguments, 'content');
    final wsId = _requireWorkspace(context);

    final rawTags = arguments['tags'];
    final tags = <String>[];
    if (rawTags is List) {
      for (final t in rawTags) {
        if (t is String && t.trim().isNotEmpty) tags.add(t.trim());
      }
    }

    final entry = MemoryEntry(
      id: _newId(),
      content: content,
      createdAt: DateTime.now(),
      tags: tags,
    );
    await _manager.remember(wsId, entry);

    return ToolResult(
      toolCallId: '',
      name: name,
      content: 'Saved memory ${entry.id}: "$content"'
          '${tags.isEmpty ? '' : ' (tags: ${tags.join(', ')})'}.',
      isError: false,
      data: <String, dynamic>{'id': entry.id},
    );
  }
}

/// Lists or searches workspace memories, optionally filtered by tag.
class RecallTool extends ReadOnlyTool {
  RecallTool(this._manager);

  final MemoryManager _manager;

  @override
  String get name => 'recall';

  @override
  String get description =>
      'List the durable memories saved for this workspace. Optionally filter '
      'by tag or keyword. Use this before making decisions that might benefit '
      'from previously learned context.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'tag': <String, dynamic>{
        'type': 'string',
        'description': 'Optional tag to filter memories by.',
      },
      'query': <String, dynamic>{
        'type': 'string',
        'description':
            'Optional keyword to search within memory content (case-insensitive).',
      },
      'limit': <String, dynamic>{
        'type': 'integer',
        'description': 'Maximum number of entries to return (default 20).',
      },
    },
  };

  @override
  String describeCall(Map<String, dynamic> arguments) {
    final tag = optionalString(arguments, 'tag');
    final query = optionalString(arguments, 'query');
    if (tag.isNotEmpty) return 'recall tag=$tag';
    if (query.isNotEmpty) return 'recall query="$query"';
    return 'recall';
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final wsId = _requireWorkspace(context);
    final tag = optionalString(arguments, 'tag').toLowerCase();
    final query = optionalString(arguments, 'query').toLowerCase();
    final limit = optionalInt(arguments, 'limit', fallback: 20);

    var entries = await _manager.entries(wsId);

    if (tag.isNotEmpty) {
      entries = entries
          .where(
            (e) => e.tags.any((t) => t.toLowerCase().contains(tag)),
          )
          .toList();
    }
    if (query.isNotEmpty) {
      entries = entries
          .where((e) => e.content.toLowerCase().contains(query))
          .toList();
    }

    // Most recent last so the model sees recency order.
    if (entries.length > limit) {
      entries = entries.sublist(entries.length - limit);
    }

    if (entries.isEmpty) {
      return ToolResult(
        toolCallId: '',
        name: name,
        content: 'No memories found.',
        isError: false,
      );
    }

    final buffer = StringBuffer('${entries.length} memories:\n');
    for (final e in entries) {
      final tagsLabel = e.tags.isEmpty ? '' : ' [${e.tags.join(', ')}]';
      buffer.writeln('- [${e.id}] ${e.content}$tagsLabel');
    }
    return ToolResult(
      toolCallId: '',
      name: name,
      content: clampOutput(buffer.toString().trim()),
      isError: false,
    );
  }
}

/// Deletes a workspace memory by id.
class ForgetTool extends MutatingTool {
  ForgetTool(this._manager);

  final MemoryManager _manager;

  @override
  String get name => 'forget';

  @override
  String get description =>
      'Delete a previously saved memory by its id. Use this when a remembered '
      'fact is no longer accurate or relevant.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'id': <String, dynamic>{
        'type': 'string',
        'description': 'The id of the memory to delete (from a recall result).',
      },
    },
    'required': <String>['id'],
  };

  @override
  String describeCall(Map<String, dynamic> arguments) =>
      'forget ${optionalString(arguments, 'id')}';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final id = requireString(arguments, 'id');
    final wsId = _requireWorkspace(context);
    await _manager.forget(wsId, id);
    return ToolResult(
      toolCallId: '',
      name: name,
      content: 'Memory "$id" has been deleted.',
      isError: false,
    );
  }
}

String _requireWorkspace(ToolContext context) {
  final value = context.workspaceId;
  if (value == null || value.isEmpty) {
    throw const ToolExecutionException(
      'Memory tools require an active workspace.',
    );
  }
  return value;
}

String _truncate(String text, {int maxLen = 60}) =>
    text.length <= maxLen ? text : '${text.substring(0, maxLen)}…';

/// Simple id generator — avoids importing uuid just for tool-local ids.
String _newId() {
  final now = DateTime.now();
  final random = now.microsecondsSinceEpoch.toRadixString(36);
  return 'mem_$random';
}
