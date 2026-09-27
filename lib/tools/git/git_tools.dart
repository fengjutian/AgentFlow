/// Git inspection and local workflow tools.
///
/// Implemented on top of the Git CLI through the workspace [Runtime] (design doc
/// §33 lists "Git CLI / JGit fallback"). Read-only inspection is auto-approved;
/// committing requires confirmation. Push is intentionally NOT exposed in MVP —
/// the design doc forbids automatic git push (§34).
library;

import 'dart:io';

import '../../core/message.dart';
import '../../runtime/runtime.dart';
import '../agent_tool.dart';
import '../tool_args.dart';

/// Base for tools that shell out to `git`.
abstract class _GitTool extends AgentTool {
  Future<ToolResult> _runGit(
    List<String> args,
    ToolContext context, {
    bool isErrorOnNonZero = true,
  }) async {
    final windowsLocal =
        context.runtime.kind == RuntimeKind.local && Platform.isWindows;
    final result = await context.runtime.execute(
      'git ${args.map((arg) => _shellQuote(arg, windows: windowsLocal)).join(' ')}',
      workingDirectory: context.workingDirectory,
    );
    final output = result.combinedOutput;
    return ToolResult(
      toolCallId: '',
      name: name,
      content: clampOutput(output.isEmpty ? '(no output)' : output),
      isError: isErrorOnNonZero && !result.success,
      data: <String, dynamic>{
        'exitCode': result.exitCode,
        'stdout': result.stdout,
        'stderr': result.stderr,
      },
    );
  }
}

String _shellQuote(String value, {required bool windows}) {
  if (RegExp(r'^[A-Za-z0-9_./:@=+-]+$').hasMatch(value)) return value;
  if (windows) {
    final escaped = value.replaceAll('%', '%%').replaceAll('"', r'\"');
    return '"$escaped"';
  }
  return "'${value.replaceAll("'", "'\\''")}'";
}

class GitStatusTool extends _GitTool {
  @override
  String get name => 'git_status';

  @override
  ToolRisk get risk => ToolRisk.auto;

  @override
  String get description =>
      'Show the working tree status (staged, modified, untracked files) using '
      'porcelain output for reliable parsing.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{},
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) => _runGit(
    <String>['status', '--porcelain', '-b'],
    context,
    isErrorOnNonZero: true,
  );
}

class GitDiffTool extends _GitTool {
  @override
  String get name => 'git_diff';

  @override
  ToolRisk get risk => ToolRisk.auto;

  @override
  String get description =>
      'Show changes in the working tree. Pass staged=true to show staged changes '
      '(git diff --cached), or a specific path to scope the diff.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'path': <String, dynamic>{'type': 'string'},
      'staged': <String, dynamic>{'type': 'boolean'},
    },
  };

  @override
  String describeCall(Map<String, dynamic> arguments) {
    final staged = optionalBool(arguments, 'staged');
    final path = optionalString(arguments, 'path');
    return 'git_diff${staged ? ' --cached' : ''}${path.isEmpty ? '' : ' $path'}';
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final args = <String>['diff'];
    if (optionalBool(arguments, 'staged')) args.add('--cached');
    final path = optionalString(arguments, 'path');
    if (path.isNotEmpty) args.addAll(<String>['--', path]);
    final result = await _runGit(args, context, isErrorOnNonZero: true);
    if ((result.data?['stdout'] as String? ?? '').trim().isEmpty &&
        !result.isError) {
      return ToolResult(
        toolCallId: '',
        name: name,
        content: 'No differences found.',
        data: result.data,
      );
    }
    return result;
  }
}

class GitLogTool extends _GitTool {
  @override
  String get name => 'git_log';

  @override
  ToolRisk get risk => ToolRisk.auto;

  @override
  String get description =>
      'Show recent commits with hash, author, date and subject. Optionally '
      'scope history to a path.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'limit': <String, dynamic>{
        'type': 'integer',
        'minimum': 1,
        'maximum': 100,
      },
      'path': <String, dynamic>{'type': 'string'},
    },
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final limit = optionalInt(arguments, 'limit', fallback: 10).clamp(1, 100);
    final args = <String>[
      'log',
      '-$limit',
      '--date=short',
      '--pretty=format:%h%x1f%an%x1f%ad%x1f%s',
    ];
    final path = optionalString(arguments, 'path');
    if (path.isNotEmpty) args.addAll(<String>['--', path]);
    final result = await _runGit(args, context);
    if (result.isError) return result;
    final commits = (result.data!['stdout'] as String)
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          final fields = line.split('\x1f');
          return <String, dynamic>{
            'hash': fields.isNotEmpty ? fields[0] : '',
            'author': fields.length > 1 ? fields[1] : '',
            'date': fields.length > 2 ? fields[2] : '',
            'subject': fields.length > 3 ? fields.sublist(3).join('\x1f') : '',
          };
        })
        .toList(growable: false);
    return ToolResult(
      toolCallId: '',
      name: name,
      content: result.content,
      data: <String, dynamic>{...result.data!, 'commits': commits},
    );
  }
}

class GitBranchesTool extends _GitTool {
  @override
  String get name => 'git_branches';

  @override
  ToolRisk get risk => ToolRisk.auto;

  @override
  String get description =>
      'List local branches and identify the currently checked out branch.';

  @override
  Map<String, dynamic> get inputSchema => const <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{},
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final result = await _runGit(<String>[
      'branch',
      '--format=%(HEAD)|%(refname:short)',
    ], context);
    if (result.isError) return result;
    final branches = (result.data!['stdout'] as String)
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          final fields = line.split('|');
          return <String, dynamic>{
            'name': fields.length > 1 ? fields[1] : line.trim(),
            'current': fields.isNotEmpty && fields[0].trim() == '*',
          };
        })
        .toList(growable: false);
    return ToolResult(
      toolCallId: '',
      name: name,
      content: result.content,
      data: <String, dynamic>{...result.data!, 'branches': branches},
    );
  }
}

class GitAddTool extends _GitTool {
  @override
  String get name => 'git_add';

  @override
  ToolRisk get risk => ToolRisk.confirm;

  @override
  String get description =>
      'Stage selected paths, or all workspace changes when all=true. Requires '
      'approval and does not commit or push.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'paths': <String, dynamic>{
        'type': 'array',
        'items': <String, dynamic>{'type': 'string'},
      },
      'all': <String, dynamic>{'type': 'boolean'},
    },
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final all = optionalBool(arguments, 'all');
    final paths = _stringList(arguments, 'paths');
    if (!all && paths.isEmpty) {
      throw const ToolExecutionException(
        'git_add requires at least one path or all=true.',
      );
    }
    return _runGit(
      all ? <String>['add', '-A'] : <String>['add', '--', ...paths],
      context,
    );
  }
}

class GitUnstageTool extends _GitTool {
  @override
  String get name => 'git_unstage';

  @override
  ToolRisk get risk => ToolRisk.confirm;

  @override
  String get description =>
      'Remove selected paths from the Git staging area without changing working '
      'tree files. Use all=true to unstage everything.';

  @override
  Map<String, dynamic> get inputSchema => GitAddTool().inputSchema;

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final all = optionalBool(arguments, 'all');
    final paths = _stringList(arguments, 'paths');
    if (!all && paths.isEmpty) {
      throw const ToolExecutionException(
        'git_unstage requires at least one path or all=true.',
      );
    }
    return _runGit(
      all
          ? <String>['reset', '--mixed', 'HEAD']
          : <String>['reset', '--mixed', 'HEAD', '--', ...paths],
      context,
    );
  }
}

class GitCommitTool extends _GitTool {
  @override
  String get name => 'git_commit';

  @override
  ToolRisk get risk => ToolRisk.confirm;

  @override
  String get description =>
      'Create a local commit from staged changes. Set stage_all=true to stage '
      'the entire workspace first. Requires approval and never pushes.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'message': <String, dynamic>{
        'type': 'string',
        'description': 'Commit message.',
      },
      'stage_all': <String, dynamic>{'type': 'boolean'},
    },
    'required': <String>['message'],
  };

  @override
  String describeCall(Map<String, dynamic> arguments) =>
      'git_commit "${optionalString(arguments, 'message')}"';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final message = requireString(arguments, 'message');
    if (optionalBool(arguments, 'stage_all')) {
      final staged = await _runGit(<String>['add', '-A'], context);
      if (staged.isError) return staged;
    }
    final messagePath =
        '.agentflow-commit-message-${DateTime.now().microsecondsSinceEpoch}.txt';
    try {
      await context.runtime.writeFile(messagePath, '$message\n');
      return await _runGit(
        <String>['commit', '-F', messagePath],
        context,
        isErrorOnNonZero: true,
      );
    } finally {
      if (await context.runtime.fileExists(messagePath)) {
        await context.runtime.deleteFile(messagePath);
      }
    }
  }
}

List<String> _stringList(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value == null) return const <String>[];
  if (value is! List) {
    throw ToolExecutionException("'$key' must be an array of strings.");
  }
  final values = <String>[];
  for (final item in value) {
    if (item is! String || item.isEmpty) {
      throw ToolExecutionException("'$key' must contain non-empty strings.");
    }
    values.add(item);
  }
  return values;
}

List<AgentTool> gitTools() => <AgentTool>[
  GitStatusTool(),
  GitDiffTool(),
  GitLogTool(),
  GitBranchesTool(),
  GitAddTool(),
  GitUnstageTool(),
  GitCommitTool(),
];
