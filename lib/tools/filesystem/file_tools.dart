/// Filesystem tools: list_files, read_file, write_file.
///
/// These are the backbone of the coding agent. Reads are auto-approved; writes
/// require confirmation and return a structured [FileDiff] so the UI can render
/// an accept/reject Diff card (design doc §21).
library;

import '../../core/message.dart';
import '../../core/diff/line_diff.dart';
import '../agent_tool.dart';
import '../tool_args.dart';

/// `list_files` — enumerate a directory (design doc §11).
class ListFilesTool extends ReadOnlyTool {
  @override
  String get name => 'list_files';

  @override
  String get description =>
      'List the files and directories at a path relative to the workspace root. '
      'Returns each entry with name, type (file|directory) and size. '
      'Use "." for the workspace root.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'path': <String, dynamic>{
            'type': 'string',
            'description': 'Directory to list, relative to workspace root.',
          },
        },
      };

  @override
  String describeCall(Map<String, dynamic> arguments) =>
      'list_files ${optionalString(arguments, 'path', fallback: '.')}';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final path = optionalString(arguments, 'path', fallback: '.');
    final entries = await context.runtime.listFiles(path);
    final lines = entries.map((e) {
      final marker = e.isDirectory ? '/' : '';
      return '${e.type.padRight(9)} ${e.name}$marker';
    }).join('\n');
    return ToolResult(
      toolCallId: '',
      name: name,
      content: entries.isEmpty
          ? '(empty directory: $path)'
          : '${entries.length} entries in $path:\n$lines',
      data: <String, dynamic>{
        'path': path,
        'files': entries.map((e) => e.toJson()).toList(),
      },
    );
  }
}

/// `read_file` — read a text file, optionally a line range.
class ReadFileTool extends ReadOnlyTool {
  @override
  String get name => 'read_file';

  @override
  String get description =>
      'Read a text file from the workspace. Optionally pass startLine and '
      'endLine (1-based, inclusive) to read a slice of a large file. '
      'Returns the file content.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'path': <String, dynamic>{
            'type': 'string',
            'description': 'File path relative to the workspace root.',
          },
          'startLine': <String, dynamic>{'type': 'integer'},
          'endLine': <String, dynamic>{'type': 'integer'},
        },
        'required': <String>['path'],
      };

  @override
  String describeCall(Map<String, dynamic> arguments) =>
      'read_file ${optionalString(arguments, 'path')}';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final path = requireString(arguments, 'path');
    final String content;
    try {
      content = await context.runtime.readFile(path);
    } catch (e) {
      throw ToolExecutionException('Could not read "$path": $e');
    }

    final start = optionalInt(arguments, 'startLine', fallback: 0);
    final end = optionalInt(arguments, 'endLine', fallback: 0);
    final sliced = _slice(content, start, end);

    return ToolResult(
      toolCallId: '',
      name: name,
      content: clampOutput(sliced),
      data: <String, dynamic>{'path': path, 'bytes': content.length},
    );
  }

  String _slice(String content, int start, int end) {
    if (start <= 0 && end <= 0) return content;
    final lines = content.split('\n');
    final from = start <= 0 ? 0 : start - 1;
    final to = end <= 0 ? lines.length : end.clamp(0, lines.length);
    if (from >= lines.length) return '(startLine beyond end of file)';
    final buffer = StringBuffer();
    for (var i = from; i < to; i++) {
      buffer.writeln('${(i + 1).toString().padLeft(5)}  ${lines[i]}');
    }
    return buffer.toString();
  }
}

/// `write_file` — create or overwrite a file, returning a diff.
class WriteFileTool extends MutatingTool {
  @override
  String get name => 'write_file';

  @override
  String get description =>
      'Write text to a file, creating parent directories as needed. Overwrites '
      'the file if it exists. Returns a unified diff of the change. Requires '
      'user approval. Prefer targeted edits; only rewrite whole files when '
      'necessary.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'path': <String, dynamic>{
            'type': 'string',
            'description': 'File path relative to the workspace root.',
          },
          'content': <String, dynamic>{
            'type': 'string',
            'description': 'Full new content of the file.',
          },
        },
        'required': <String>['path', 'content'],
      };

  @override
  String describeCall(Map<String, dynamic> arguments) =>
      'write_file ${optionalString(arguments, 'path')}';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final path = requireString(arguments, 'path');
    final content = optionalString(arguments, 'content');

    String oldText = '';
    final exists = await context.runtime.fileExists(path);
    if (exists) {
      try {
        oldText = await context.runtime.readFile(path);
      } catch (_) {
        oldText = '';
      }
    }

    final diff = buildFileDiff(path: path, oldText: oldText, newText: content);
    await context.runtime.writeFile(path, content);

    final action = !exists ? 'Created' : (diff.isEmpty ? 'Wrote (no change)' : 'Updated');
    return ToolResult(
      toolCallId: '',
      name: name,
      content: '$action $path (${diff.summary}).',
      data: <String, dynamic>{
        'path': path,
        'diff': diff.toJson(),
        'isNewFile': !exists,
      },
    );
  }
}

/// Builds the standard filesystem tool set.
List<AgentTool> fileTools() => <AgentTool>[
      ListFilesTool(),
      ReadFileTool(),
      WriteFileTool(),
    ];
