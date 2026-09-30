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
      'Show recent commits with abbreviated hash and subject. Optionally scope '
      'history to a path.';

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
      '--oneline',
      '--no-decorate',
    ];
    final path = optionalString(arguments, 'path');
    if (path.isNotEmpty) args.addAll(<String>['--', path]);
    final result = await _runGit(args, context);
    if (result.isError) return result;
    final commits = (result.data!['stdout'] as String)
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          final separator = line.indexOf(' ');
          return <String, dynamic>{
            'hash': separator < 0 ? line : line.substring(0, separator),
            'subject': separator < 0 ? '' : line.substring(separator + 1),
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
    final result = await _runGit(
      <String>['branch', '--list', '--no-color'],
      context,
    );
    if (result.isError) return result;
    final branches = (result.data!['stdout'] as String)
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          final trimmed = line.trimLeft();
          final current = trimmed.startsWith('*');
          return <String, dynamic>{
            'name': current ? trimmed.substring(1).trim() : trimmed.trim(),
            'current': current,
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

class GitFetchTool extends _GitTool {
  @override
  String get name => 'git_fetch';

  @override
  ToolRisk get risk => ToolRisk.auto;

  @override
  String get description =>
      'Fetch references from a remote repository without merging. '
      'Use all=true to fetch from all remotes.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'remote': <String, dynamic>{
        'type': 'string',
        'description': 'Remote name (default: origin).',
      },
      'all': <String, dynamic>{'type': 'boolean'},
    },
  };

  @override
  String describeCall(Map<String, dynamic> arguments) {
    if (optionalBool(arguments, 'all')) return 'git_fetch --all';
    final remote = optionalString(arguments, 'remote');
    return 'git_fetch ${remote.isEmpty ? 'origin' : remote}';
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) {
    final args = <String>['fetch'];
    if (optionalBool(arguments, 'all')) {
      args.add('--all');
    } else {
      final remote = optionalString(arguments, 'remote');
      if (remote.isNotEmpty) args.add(remote);
    }
    return _runGit(args, context, isErrorOnNonZero: true);
  }
}

class GitPullTool extends _GitTool {
  @override
  String get name => 'git_pull';

  @override
  ToolRisk get risk => ToolRisk.confirm;

  @override
  String get description =>
      'Fetch from remote and merge into the current branch. '
      'Requires approval as it modifies the working tree.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'remote': <String, dynamic>{'type': 'string'},
      'branch': <String, dynamic>{'type': 'string'},
      'rebase': <String, dynamic>{'type': 'boolean'},
    },
  };

  @override
  String describeCall(Map<String, dynamic> arguments) {
    final remote = optionalString(arguments, 'remote');
    final branch = optionalString(arguments, 'branch');
    final rebase = optionalBool(arguments, 'rebase');
    final parts = <String>['git_pull'];
    if (remote.isNotEmpty) parts.add(remote);
    if (branch.isNotEmpty) parts.add(branch);
    if (rebase) parts.add('--rebase');
    return parts.join(' ');
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) {
    final args = <String>['pull'];
    if (optionalBool(arguments, 'rebase')) args.add('--rebase');
    final remote = optionalString(arguments, 'remote');
    if (remote.isNotEmpty) args.add(remote);
    final branch = optionalString(arguments, 'branch');
    if (branch.isNotEmpty) args.add(branch);
    return _runGit(args, context, isErrorOnNonZero: true);
  }
}

class GitPushTool extends _GitTool {
  @override
  String get name => 'git_push';

  @override
  ToolRisk get risk => ToolRisk.strong;

  @override
  String get description =>
      'Push local commits to a remote repository. This is a destructive operation '
      'that cannot be undone. Requires explicit confirmation showing remote, branch, '
      'and commit count.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'remote': <String, dynamic>{
        'type': 'string',
        'description': 'Remote name (default: origin).',
      },
      'branch': <String, dynamic>{
        'type': 'string',
        'description': 'Branch to push (default: current).',
      },
      'force': <String, dynamic>{
        'type': 'boolean',
        'description': 'Force push (dangerous: overwrites remote history).',
      },
      'tags': <String, dynamic>{
        'type': 'boolean',
        'description': 'Push tags along with commits.',
      },
    },
  };

  @override
  String describeCall(Map<String, dynamic> arguments) {
    final remote = optionalString(arguments, 'remote');
    final branch = optionalString(arguments, 'branch');
    final force = optionalBool(arguments, 'force');
    final parts = <String>['git_push'];
    if (force) parts.add('--force');
    parts.add(remote.isEmpty ? 'origin' : remote);
    if (branch.isNotEmpty) parts.add(branch);
    return parts.join(' ');
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) {
    final args = <String>['push'];
    if (optionalBool(arguments, 'force')) args.add('--force');
    if (optionalBool(arguments, 'tags')) args.add('--tags');
    final remote = optionalString(arguments, 'remote');
    args.add(remote.isEmpty ? 'origin' : remote);
    final branch = optionalString(arguments, 'branch');
    if (branch.isNotEmpty) args.add(branch);
    return _runGit(args, context, isErrorOnNonZero: true);
  }
}

class GitCheckoutTool extends _GitTool {
  @override
  String get name => 'git_checkout';

  @override
  ToolRisk get risk => ToolRisk.confirm;

  @override
  String get description =>
      'Switch branches or create a new branch. Use create=true to create and '
      'switch to a new branch. Requires approval as it modifies the working tree.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'branch': <String, dynamic>{
        'type': 'string',
        'description': 'Branch name to checkout.',
      },
      'create': <String, dynamic>{
        'type': 'boolean',
        'description': 'Create the branch before switching to it.',
      },
      'startPoint': <String, dynamic>{
        'type': 'string',
        'description': 'Starting point for new branch (commit, branch, or tag).',
      },
    },
    'required': <String>['branch'],
  };

  @override
  String describeCall(Map<String, dynamic> arguments) {
    final branch = optionalString(arguments, 'branch');
    final create = optionalBool(arguments, 'create');
    return create ? 'git_checkout -b $branch' : 'git_checkout $branch';
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) {
    final branch = requireString(arguments, 'branch');
    final create = optionalBool(arguments, 'create');
    final args = <String>['checkout'];
    if (create) {
      args.add('-b');
      args.add(branch);
      final startPoint = optionalString(arguments, 'startPoint');
      if (startPoint.isNotEmpty) args.add(startPoint);
    } else {
      args.add(branch);
    }
    return _runGit(args, context, isErrorOnNonZero: true);
  }
}

class GitMergeTool extends _GitTool {
  @override
  String get name => 'git_merge';

  @override
  ToolRisk get risk => ToolRisk.confirm;

  @override
  String get description =>
      'Merge a branch into the current branch. Use no_ff=true to create a merge '
      'commit even when fast-forward is possible. Requires approval.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'branch': <String, dynamic>{
        'type': 'string',
        'description': 'Branch to merge into current.',
      },
      'no_ff': <String, dynamic>{
        'type': 'boolean',
        'description': 'Always create a merge commit (no fast-forward).',
      },
      'abort': <String, dynamic>{
        'type': 'boolean',
        'description': 'Abort an in-progress merge.',
      },
    },
    'required': <String>['branch'],
  };

  @override
  String describeCall(Map<String, dynamic> arguments) {
    if (optionalBool(arguments, 'abort')) return 'git_merge --abort';
    final branch = optionalString(arguments, 'branch');
    final noFf = optionalBool(arguments, 'no_ff');
    return 'git_merge ${noFf ? '--no-ff ' : ''}$branch';
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) {
    if (optionalBool(arguments, 'abort')) {
      return _runGit(<String>['merge', '--abort'], context, isErrorOnNonZero: true);
    }
    final branch = requireString(arguments, 'branch');
    final args = <String>['merge'];
    if (optionalBool(arguments, 'no_ff')) args.add('--no-ff');
    args.add(branch);
    return _runGit(args, context, isErrorOnNonZero: true);
  }
}

class GitStashTool extends _GitTool {
  @override
  String get name => 'git_stash';

  @override
  ToolRisk get risk => ToolRisk.confirm;

  @override
  String get description =>
      'Save or restore uncommitted changes. Actions: push (save), pop (restore and remove), '
      'list (show stashes), drop (remove without applying). Requires approval for mutating actions.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'action': <String, dynamic>{
        'type': 'string',
        'enum': <String>['push', 'pop', 'list', 'drop', 'show', 'apply'],
        'description': 'Stash action to perform.',
      },
      'message': <String, dynamic>{
        'type': 'string',
        'description': 'Message for stash push.',
      },
      'index': <String, dynamic>{
        'type': 'integer',
        'description': 'Stash index for pop/drop/apply (default: 0).',
      },
      'includeUntracked': <String, dynamic>{
        'type': 'boolean',
        'description': 'Include untracked files in stash push.',
      },
    },
    'required': <String>['action'],
  };

  @override
  String describeCall(Map<String, dynamic> arguments) {
    final action = optionalString(arguments, 'action');
    final index = optionalInt(arguments, 'index');
    return 'git_stash $action${index > 0 ? ' $index' : ''}';
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) {
    final action = requireString(arguments, 'action');
    final args = <String>['stash'];

    switch (action) {
      case 'push':
        args.add('push');
        if (optionalBool(arguments, 'includeUntracked')) {
          args.add('--include-untracked');
        }
        final message = optionalString(arguments, 'message');
        if (message.isNotEmpty) {
          args.addAll(<String>['-m', message]);
        }
      case 'pop':
        args.add('pop');
        final index = optionalInt(arguments, 'index');
        if (index > 0) args.add('stash@{$index}');
      case 'apply':
        args.add('apply');
        final index = optionalInt(arguments, 'index');
        if (index > 0) args.add('stash@{$index}');
      case 'drop':
        args.add('drop');
        final index = optionalInt(arguments, 'index');
        if (index > 0) args.add('stash@{$index}');
      case 'list':
        args.add('list');
      case 'show':
        args.add('show');
        final index = optionalInt(arguments, 'index');
        if (index > 0) args.add('stash@{$index}');
      default:
        throw ToolExecutionException(
          'Unknown stash action: $action. Use push, pop, apply, drop, list, or show.',
        );
    }
    return _runGit(args, context, isErrorOnNonZero: true);
  }
}

class GitRemoteTool extends _GitTool {
  @override
  String get name => 'git_remote';

  @override
  ToolRisk get risk => ToolRisk.confirm;

  @override
  String get description =>
      'Manage remote repositories. List remotes (auto), or add/remove (requires approval).';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'action': <String, dynamic>{
        'type': 'string',
        'enum': <String>['list', 'add', 'remove', 'rename', 'set-url'],
        'description': 'Remote action (default: list).',
      },
      'name': <String, dynamic>{
        'type': 'string',
        'description': 'Remote name.',
      },
      'url': <String, dynamic>{
        'type': 'string',
        'description': 'Remote URL.',
      },
      'newName': <String, dynamic>{
        'type': 'string',
        'description': 'New name for rename action.',
      },
      'verbose': <String, dynamic>{
        'type': 'boolean',
        'description': 'Show URLs for list action.',
      },
    },
  };

  @override
  String describeCall(Map<String, dynamic> arguments) {
    final action = optionalString(arguments, 'action');
    final name = optionalString(arguments, 'name');
    return 'git_remote ${action.isEmpty ? 'list' : action}${name.isNotEmpty ? ' $name' : ''}';
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) {
    final action = optionalString(arguments, 'action');
    final args = <String>['remote'];

    switch (action.isEmpty ? 'list' : action) {
      case 'list':
        if (optionalBool(arguments, 'verbose')) args.add('-v');
      case 'add':
        final name = requireString(arguments, 'name');
        final url = requireString(arguments, 'url');
        args.addAll(<String>['add', name, url]);
      case 'remove':
        final name = requireString(arguments, 'name');
        args.addAll(<String>['remove', name]);
      case 'rename':
        final name = requireString(arguments, 'name');
        final newName = requireString(arguments, 'newName');
        args.addAll(<String>['rename', name, newName]);
      case 'set-url':
        final name = requireString(arguments, 'name');
        final url = requireString(arguments, 'url');
        args.addAll(<String>['set-url', name, url]);
      default:
        throw ToolExecutionException(
          'Unknown remote action: $action. Use list, add, remove, rename, or set-url.',
        );
    }
    return _runGit(args, context, isErrorOnNonZero: true);
  }
}

class GitCherryPickTool extends _GitTool {
  @override
  String get name => 'git_cherry_pick';

  @override
  ToolRisk get risk => ToolRisk.confirm;

  @override
  String get description =>
      'Apply changes from a specific commit to the current branch. '
      'Use abort=true to cancel an in-progress cherry-pick. Requires approval.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'commit': <String, dynamic>{
        'type': 'string',
        'description': 'Commit hash or reference to cherry-pick.',
      },
      'abort': <String, dynamic>{
        'type': 'boolean',
        'description': 'Abort an in-progress cherry-pick.',
      },
      'continue_': <String, dynamic>{
        'type': 'boolean',
        'description': 'Continue an in-progress cherry-pick after resolving conflicts.',
      },
      'noCommit': <String, dynamic>{
        'type': 'boolean',
        'description': 'Apply changes without committing.',
      },
    },
  };

  @override
  String describeCall(Map<String, dynamic> arguments) {
    if (optionalBool(arguments, 'abort')) return 'git_cherry_pick --abort';
    if (optionalBool(arguments, 'continue_')) return 'git_cherry_pick --continue';
    final commit = optionalString(arguments, 'commit');
    return 'git_cherry_pick $commit';
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) {
    if (optionalBool(arguments, 'abort')) {
      return _runGit(<String>['cherry-pick', '--abort'], context, isErrorOnNonZero: true);
    }
    if (optionalBool(arguments, 'continue_')) {
      return _runGit(<String>['cherry-pick', '--continue'], context, isErrorOnNonZero: true);
    }
    final commit = requireString(arguments, 'commit');
    final args = <String>['cherry-pick'];
    if (optionalBool(arguments, 'noCommit')) args.add('--no-commit');
    args.add(commit);
    return _runGit(args, context, isErrorOnNonZero: true);
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
  GitFetchTool(),
  GitPullTool(),
  GitPushTool(),
  GitCheckoutTool(),
  GitMergeTool(),
  GitStashTool(),
  GitRemoteTool(),
  GitCherryPickTool(),
];
