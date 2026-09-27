/// Filesystem tools: list_files, read_file, write_file.
///
/// These are the backbone of the coding agent. Reads are auto-approved; writes
/// require confirmation and return a structured [FileDiff] so the UI can render
/// an accept/reject Diff card (design doc §21).
library;

import '../../core/message.dart';
import '../../core/diff/line_diff.dart';
import '../../runtime/runtime.dart';
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
    final lines = entries
        .map((e) {
          final marker = e.isDirectory ? '/' : '';
          return '${e.type.padRight(9)} ${e.name}$marker';
        })
        .join('\n');
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
class _WriteSnapshot {
  const _WriteSnapshot(this.path, this.existed, this.oldText, this.newText);
  final String path;
  final bool existed;
  final String oldText;
  final String newText;
}

class _CommittedWrite {
  const _CommittedWrite(this.snapshots, this.runtime);
  final List<_WriteSnapshot> snapshots;
  final Runtime runtime;
}

class FileChangeJournal {
  final Map<String, _CommittedWrite> _entries = <String, _CommittedWrite>{};
  int _sequence = 0;

  String _record(List<_WriteSnapshot> snapshots, Runtime runtime) {
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
    _entries[id] = _CommittedWrite(
      List<_WriteSnapshot>.unmodifiable(snapshots),
      runtime,
    );
    return id;
  }

  Future<String> undo(String id) async {
    final entry = _entries[id];
    if (entry == null) {
      throw const ToolExecutionException('Undo is no longer available.');
    }
    final runtime = entry.runtime;
    for (final snapshot in entry.snapshots) {
      final exists = await runtime.fileExists(snapshot.path);
      final current = exists ? await runtime.readFile(snapshot.path) : '';
      if (current != snapshot.newText) {
        throw ToolExecutionException(
          'Cannot undo ${snapshot.path}: the file changed after the agent write.',
        );
      }
    }
    for (final snapshot in entry.snapshots.reversed) {
      if (snapshot.existed) {
        await runtime.writeFile(snapshot.path, snapshot.oldText);
      } else {
        await runtime.deleteFile(snapshot.path);
      }
    }
    _entries.remove(id);
    final paths = entry.snapshots.map((snapshot) => snapshot.path).join(', ');
    return 'Undid changes to $paths.';
  }
}

final FileChangeJournal fileChangeJournal = FileChangeJournal();

class WriteFileTool extends MutatingTool implements PreviewableTool {
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
  ) async =>
      executePrepared(arguments, context, await preview(arguments, context));

  @override
  Future<ToolPreview> preview(
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
    return ToolPreview(
      data: <String, dynamic>{'path': path, 'diff': diff.toJson()},
      state: _WriteSnapshot(path, exists, oldText, content),
    );
  }

  @override
  Future<ToolResult> executePrepared(
    Map<String, dynamic> arguments,
    ToolContext context,
    ToolPreview preview,
  ) async {
    final snapshot = preview.state! as _WriteSnapshot;
    final existsNow = await context.runtime.fileExists(snapshot.path);
    final current = existsNow
        ? await context.runtime.readFile(snapshot.path)
        : '';
    if (existsNow != snapshot.existed || current != snapshot.oldText) {
      throw ToolExecutionException(
        'Refusing to write "${snapshot.path}": it changed after approval.',
      );
    }

    try {
      await context.runtime.writeFile(snapshot.path, snapshot.newText);
      final verified = await context.runtime.readFile(snapshot.path);
      if (verified != snapshot.newText) {
        throw const ToolExecutionException('Write verification failed.');
      }
    } catch (error) {
      try {
        if (snapshot.existed) {
          await context.runtime.writeFile(snapshot.path, snapshot.oldText);
        } else {
          await context.runtime.deleteFile(snapshot.path);
        }
      } catch (_) {
        throw ToolExecutionException(
          'Write and rollback both failed for "${snapshot.path}": $error',
        );
      }
      throw ToolExecutionException(
        'Write failed; the original file was restored: $error',
      );
    }

    final diff = FileDiff.fromJson(
      (preview.data['diff'] as Map).cast<String, dynamic>(),
    );
    final transactionId = fileChangeJournal._record(<_WriteSnapshot>[
      snapshot,
    ], context.runtime);
    final action = !snapshot.existed
        ? 'Created'
        : (diff.isEmpty ? 'Wrote (no change)' : 'Updated');
    return ToolResult(
      toolCallId: '',
      name: name,
      content: '$action ${snapshot.path} (${diff.summary}).',
      data: <String, dynamic>{
        'path': snapshot.path,
        'diff': diff.toJson(),
        'isNewFile': !snapshot.existed,
        'transactionId': transactionId,
        'undoAvailable': true,
      },
    );
  }
}

/// `apply_patch` — make one or more exact, targeted replacements atomically.
///
/// Exact old text is required so a patch cannot silently land in the wrong
/// location. All files are revalidated after approval and rolled back together
/// if any write or verification fails.
class ApplyPatchTool extends MutatingTool implements PreviewableTool {
  @override
  String get name => 'apply_patch';

  @override
  String get description =>
      'Apply targeted text replacements to one or more existing files. Each '
      'change supplies path, old_text and new_text. By default old_text must '
      'occur exactly once; set replace_all only when every occurrence should '
      'change. The complete multi-file diff is previewed and applied atomically.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'changes': <String, dynamic>{
        'type': 'array',
        'minItems': 1,
        'items': <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'path': <String, dynamic>{'type': 'string'},
            'old_text': <String, dynamic>{'type': 'string'},
            'new_text': <String, dynamic>{'type': 'string'},
            'replace_all': <String, dynamic>{'type': 'boolean'},
          },
          'required': <String>['path', 'old_text', 'new_text'],
        },
      },
    },
    'required': <String>['changes'],
  };

  @override
  String describeCall(Map<String, dynamic> arguments) {
    final raw = arguments['changes'];
    final count = raw is List ? raw.length : 0;
    return 'apply_patch $count file${count == 1 ? '' : 's'}';
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async =>
      executePrepared(arguments, context, await preview(arguments, context));

  @override
  Future<ToolPreview> preview(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final changes = _parseChanges(arguments);
    final seenPaths = <String>{};
    final snapshots = <_WriteSnapshot>[];
    final diffs = <FileDiff>[];
    for (final change in changes) {
      if (!seenPaths.add(change.path)) {
        throw ToolExecutionException(
          'Patch contains more than one change for "${change.path}".',
        );
      }
      if (!await context.runtime.fileExists(change.path)) {
        throw ToolExecutionException(
          'Cannot patch "${change.path}": the file does not exist.',
        );
      }
      final oldContent = await context.runtime.readFile(change.path);
      final occurrences = _countOccurrences(oldContent, change.oldText);
      if (occurrences == 0) {
        throw ToolExecutionException(
          'Cannot patch "${change.path}": old_text was not found.',
        );
      }
      if (!change.replaceAll && occurrences != 1) {
        throw ToolExecutionException(
          'Cannot patch "${change.path}": old_text occurs $occurrences times. '
          'Provide more context or set replace_all.',
        );
      }
      final newContent = change.replaceAll
          ? oldContent.replaceAll(change.oldText, change.newText)
          : oldContent.replaceFirst(change.oldText, change.newText);
      final snapshot = _WriteSnapshot(
        change.path,
        true,
        oldContent,
        newContent,
      );
      snapshots.add(snapshot);
      diffs.add(
        buildFileDiff(
          path: change.path,
          oldText: oldContent,
          newText: newContent,
        ),
      );
    }
    return ToolPreview(
      data: <String, dynamic>{
        'paths': snapshots.map((snapshot) => snapshot.path).toList(),
        'diff': diffs.first.toJson(),
        'diffs': diffs.map((diff) => diff.toJson()).toList(),
      },
      state: snapshots,
    );
  }

  @override
  Future<ToolResult> executePrepared(
    Map<String, dynamic> arguments,
    ToolContext context,
    ToolPreview preview,
  ) async {
    final snapshots = (preview.state! as List<_WriteSnapshot>);
    for (final snapshot in snapshots) {
      final exists = await context.runtime.fileExists(snapshot.path);
      final current = exists
          ? await context.runtime.readFile(snapshot.path)
          : '';
      if (!exists || current != snapshot.oldText) {
        throw ToolExecutionException(
          'Refusing to patch "${snapshot.path}": it changed after approval.',
        );
      }
    }

    final written = <_WriteSnapshot>[];
    try {
      for (final snapshot in snapshots) {
        await context.runtime.writeFile(snapshot.path, snapshot.newText);
        written.add(snapshot);
        final verified = await context.runtime.readFile(snapshot.path);
        if (verified != snapshot.newText) {
          throw ToolExecutionException(
            'Patch verification failed for "${snapshot.path}".',
          );
        }
      }
    } catch (error) {
      final rollbackErrors = <String>[];
      for (final snapshot in written.reversed) {
        try {
          await context.runtime.writeFile(snapshot.path, snapshot.oldText);
        } catch (rollbackError) {
          rollbackErrors.add('${snapshot.path}: $rollbackError');
        }
      }
      if (rollbackErrors.isNotEmpty) {
        throw ToolExecutionException(
          'Patch failed and rollback was incomplete: '
          '${rollbackErrors.join('; ')}. Original error: $error',
        );
      }
      throw ToolExecutionException(
        'Patch failed; all written files were restored: $error',
      );
    }

    final transactionId = fileChangeJournal._record(snapshots, context.runtime);
    final diffs = (preview.data['diffs'] as List<dynamic>)
        .map(
          (value) => FileDiff.fromJson(
            (value as Map<dynamic, dynamic>).cast<String, dynamic>(),
          ),
        )
        .toList(growable: false);
    final added = diffs.fold<int>(0, (sum, diff) => sum + diff.addedCount);
    final removed = diffs.fold<int>(0, (sum, diff) => sum + diff.removedCount);
    return ToolResult(
      toolCallId: '',
      name: name,
      content:
          'Patched ${snapshots.length} file${snapshots.length == 1 ? '' : 's'} '
          '(+$added -$removed).',
      data: <String, dynamic>{
        ...preview.data,
        'transactionId': transactionId,
        'undoAvailable': true,
      },
    );
  }

  List<_PatchChange> _parseChanges(Map<String, dynamic> arguments) {
    final raw = arguments['changes'];
    if (raw is! List || raw.isEmpty) {
      throw const ToolExecutionException(
        "'changes' must be a non-empty array.",
      );
    }
    return raw
        .map((value) {
          if (value is! Map) {
            throw const ToolExecutionException(
              'Every patch change must be an object.',
            );
          }
          final change = value.cast<String, dynamic>();
          final path = requireString(change, 'path');
          final oldText = optionalString(change, 'old_text');
          if (oldText.isEmpty) {
            throw ToolExecutionException(
              'old_text cannot be empty for "$path"; use write_file to create files.',
            );
          }
          if (!change.containsKey('new_text') ||
              change['new_text'] is! String) {
            throw ToolExecutionException(
              'Missing required string argument \'new_text\' for "$path".',
            );
          }
          return _PatchChange(
            path,
            oldText,
            change['new_text'] as String,
            optionalBool(change, 'replace_all'),
          );
        })
        .toList(growable: false);
  }

  int _countOccurrences(String source, String pattern) {
    var count = 0;
    var offset = 0;
    while (true) {
      final index = source.indexOf(pattern, offset);
      if (index < 0) return count;
      count++;
      offset = index + pattern.length;
    }
  }
}

class _PatchChange {
  const _PatchChange(this.path, this.oldText, this.newText, this.replaceAll);

  final String path;
  final String oldText;
  final String newText;
  final bool replaceAll;
}

/// Builds the standard filesystem tool set.
List<AgentTool> fileTools() => <AgentTool>[
  ListFilesTool(),
  ReadFileTool(),
  WriteFileTool(),
  ApplyPatchTool(),
];
