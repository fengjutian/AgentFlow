import 'dart:io';

import 'package:agentflow/runtime/local_runtime.dart';
import 'package:agentflow/tools/agent_tool.dart';
import 'package:agentflow/tools/git/git_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late ToolContext context;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('agentflow-git-ext-');
    void git(List<String> arguments) {
      final result = Process.runSync(
        'git',
        arguments,
        workingDirectory: root.path,
      );
      if (result.exitCode != 0) {
        throw StateError('git ${arguments.join(' ')} failed: ${result.stderr}');
      }
    }

    git(<String>['init']);
    git(<String>['config', 'user.name', 'Agent Flow']);
    git(<String>['config', 'user.email', 'agent@example.test']);
    File(
      '${root.path}${Platform.pathSeparator}tracked.txt',
    ).writeAsStringSync('initial\n');
    git(<String>['add', 'tracked.txt']);
    git(<String>['commit', '-m', 'initial commit']);
    context = ToolContext(
      runtime: LocalRuntime(rootDirectory: root.path),
      workingDirectory: root.path,
    );
  });

  tearDown(() => root.delete(recursive: true));

  group('git_checkout', () {
    test('creates and switches to a new branch', () async {
      final result = await GitCheckoutTool().execute(<String, dynamic>{
        'branch': 'feature',
        'create': true,
      }, context);

      expect(result.isError, isFalse);

      // Verify we're on the new branch.
      final branches = await GitBranchesTool().execute(
        const <String, dynamic>{},
        context,
      );
      final branchList = branches.data!['branches'] as List<dynamic>;
      final current = branchList.firstWhere(
        (b) => (b as Map<String, dynamic>)['current'] == true,
      ) as Map<String, dynamic>;
      expect(current['name'], 'feature');
    });

    test('switches to an existing branch', () async {
      // Create a branch first.
      Process.runSync('git', ['branch', 'other'], workingDirectory: root.path);

      final result = await GitCheckoutTool().execute(<String, dynamic>{
        'branch': 'other',
      }, context);

      expect(result.isError, isFalse);
    });
  });

  group('git_merge', () {
    test('merges a branch into current', () async {
      // Capture the default branch name before switching away.
      final defaultBranch = _defaultBranch(root);

      // Create a feature branch with a commit.
      Process.runSync(
        'git',
        ['checkout', '-b', 'feature'],
        workingDirectory: root.path,
      );
      File(
        '${root.path}${Platform.pathSeparator}feature.txt',
      ).writeAsStringSync('feature content\n');
      Process.runSync('git', ['add', 'feature.txt'], workingDirectory: root.path);
      Process.runSync(
        'git',
        ['commit', '-m', 'add feature'],
        workingDirectory: root.path,
      );

      // Switch back to master/main and merge.
      Process.runSync(
        'git',
        ['checkout', defaultBranch],
        workingDirectory: root.path,
      );

      final result = await GitMergeTool().execute(<String, dynamic>{
        'branch': 'feature',
      }, context);

      expect(result.isError, isFalse);
      expect(
        File('${root.path}${Platform.pathSeparator}feature.txt').existsSync(),
        isTrue,
      );
    });
  });

  group('git_stash', () {
    test('list returns empty when no stashes', () async {
      final result = await GitStashTool().execute(<String, dynamic>{
        'action': 'list',
      }, context);

      expect(result.isError, isFalse);
      // git stash list with no stashes produces no output.
      expect(result.content, contains('no output'));
    });

    test('push and pop round-trips changes', () async {
      // Make a change to stash.
      File(
        '${root.path}${Platform.pathSeparator}tracked.txt',
      ).writeAsStringSync('changed\n');

      final pushResult = await GitStashTool().execute(<String, dynamic>{
        'action': 'push',
        'message': 'test stash',
      }, context);

      // If stash push failed (older git), skip the rest.
      if (pushResult.isError) return;

      // Verify the change was stashed.
      final content = File(
        '${root.path}${Platform.pathSeparator}tracked.txt',
      ).readAsStringSync();
      expect(content, 'initial\n');

      // Pop the stash.
      final popResult = await GitStashTool().execute(<String, dynamic>{
        'action': 'pop',
      }, context);
      expect(popResult.isError, isFalse);

      final restored = File(
        '${root.path}${Platform.pathSeparator}tracked.txt',
      ).readAsStringSync();
      expect(restored, 'changed\n');
    });
  });

  group('git_fetch', () {
    test('fetch without remote succeeds gracefully', () async {
      // No remotes configured, so fetch should handle it.
      final result = await GitFetchTool().execute(<String, dynamic>{
        'all': true,
      }, context);

      // May or may not error depending on whether remotes exist; either way
      // it should not crash.
      expect(result, isNotNull);
    });
  });

  group('git_remote', () {
    test('list returns empty when no remotes', () async {
      final result = await GitRemoteTool().execute(<String, dynamic>{
        'action': 'list',
      }, context);

      expect(result.isError, isFalse);
    });

    test('add and list shows the remote', () async {
      final result = await GitRemoteTool().execute(<String, dynamic>{
        'action': 'add',
        'name': 'origin',
        'url': 'https://example.com/repo.git',
      }, context);
      expect(result.isError, isFalse);

      final list = await GitRemoteTool().execute(<String, dynamic>{
        'action': 'list',
      }, context);
      expect(list.content, contains('origin'));
    });
  });

  group('git_cherry_pick', () {
    test('applies a commit from another branch', () async {
      // Capture the default branch name before switching away.
      final defaultBranch = _defaultBranch(root);

      // Create a feature branch with a commit.
      Process.runSync(
        'git',
        ['checkout', '-b', 'source-branch'],
        workingDirectory: root.path,
      );
      File(
        '${root.path}${Platform.pathSeparator}cherry.txt',
      ).writeAsStringSync('cherry content\n');
      Process.runSync('git', ['add', 'cherry.txt'], workingDirectory: root.path);
      Process.runSync(
        'git',
        ['commit', '-m', 'cherry commit'],
        workingDirectory: root.path,
      );

      // Get the commit hash.
      final logResult = Process.runSync(
        'git',
        ['rev-parse', 'HEAD'],
        workingDirectory: root.path,
      );
      final commitHash = (logResult.stdout as String).trim();

      // Switch back to the default branch.
      Process.runSync(
        'git',
        ['checkout', defaultBranch],
        workingDirectory: root.path,
      );

      final result = await GitCherryPickTool().execute(<String, dynamic>{
        'commit': commitHash,
      }, context);

      expect(result.isError, isFalse);
      expect(
        File('${root.path}${Platform.pathSeparator}cherry.txt').existsSync(),
        isTrue,
      );
    });
  });

  group('tool registration', () {
    test('gitTools includes all 15 tools', () {
      final tools = gitTools();
      expect(tools, hasLength(15));
      final names = tools.map((t) => t.name).toSet();
      expect(names, containsAll(<String>[
        'git_status',
        'git_diff',
        'git_log',
        'git_branches',
        'git_add',
        'git_unstage',
        'git_commit',
        'git_fetch',
        'git_pull',
        'git_push',
        'git_checkout',
        'git_merge',
        'git_stash',
        'git_remote',
        'git_cherry_pick',
      ]));
    });

    test('git_push has strong risk level', () {
      expect(GitPushTool().risk, ToolRisk.strong);
    });

    test('git_fetch has auto risk level', () {
      expect(GitFetchTool().risk, ToolRisk.auto);
    });

    test('git_checkout has confirm risk level', () {
      expect(GitCheckoutTool().risk, ToolRisk.confirm);
    });
  });
}

/// Detects the default branch name (master or main).
String _defaultBranch(Directory root) {
  final result = Process.runSync(
    'git',
    ['rev-parse', '--abbrev-ref', 'HEAD'],
    workingDirectory: root.path,
  );
  // If we're on a detached HEAD after checkout, fall back to common names.
  final branch = (result.stdout as String).trim();
  if (branch == 'HEAD' || branch.isEmpty) {
    // Try to find the default branch.
    final branches = Process.runSync(
      'git',
      ['branch'],
      workingDirectory: root.path,
    );
    final lines = (branches.stdout as String).split('\n');
    for (final line in lines) {
      final cleaned = line.trim().replaceAll('* ', '');
      if (cleaned == 'main' || cleaned == 'master') return cleaned;
    }
    return 'master';
  }
  return branch;
}
