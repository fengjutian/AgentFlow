import 'dart:io';

import 'package:agentflow/runtime/local_runtime.dart';
import 'package:agentflow/tools/agent_tool.dart';
import 'package:agentflow/tools/git/git_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late ToolContext context;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('agentflow-git-tools-');
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

  test('git_log returns structured commits', () async {
    final result = await GitLogTool().execute(<String, dynamic>{
      'limit': 5,
    }, context);

    expect(result.isError, isFalse);
    final commits = result.data!['commits'] as List<dynamic>;
    expect(commits, hasLength(1));
    expect(
      (commits.single as Map<String, dynamic>)['subject'],
      'initial commit',
    );
  });

  test('git_branches identifies the current branch', () async {
    final result = await GitBranchesTool().execute(
      const <String, dynamic>{},
      context,
    );

    expect(result.isError, isFalse);
    final branches = result.data!['branches'] as List<dynamic>;
    expect(
      branches.where(
        (branch) => (branch as Map<String, dynamic>)['current'] == true,
      ),
      hasLength(1),
    );
  });

  test('git_add and git_unstage only change the index', () async {
    final file = File('${root.path}${Platform.pathSeparator}tracked.txt');
    file.writeAsStringSync('changed\n');

    final staged = await GitAddTool().execute(<String, dynamic>{
      'paths': <String>['tracked.txt'],
    }, context);
    expect(staged.isError, isFalse);
    var diff = await GitDiffTool().execute(<String, dynamic>{
      'staged': true,
    }, context);
    expect(diff.content, contains('changed'));

    final unstaged = await GitUnstageTool().execute(<String, dynamic>{
      'paths': <String>['tracked.txt'],
    }, context);
    expect(unstaged.isError, isFalse);
    diff = await GitDiffTool().execute(<String, dynamic>{
      'staged': true,
    }, context);
    expect(diff.content, contains('No differences'));
    expect(file.readAsStringSync(), 'changed\n');
  });

  test(
    'git_commit can safely commit a message containing spaces and quotes',
    () async {
      File(
        '${root.path}${Platform.pathSeparator}tracked.txt',
      ).writeAsStringSync('changed\n');
      final result = await GitCommitTool().execute(<String, dynamic>{
        'message': 'fix "quoted" behavior',
        'stage_all': true,
      }, context);

      expect(result.isError, isFalse);
      final log = await GitLogTool().execute(<String, dynamic>{
        'limit': 1,
      }, context);
      final commit =
          (log.data!['commits'] as List<dynamic>).single
              as Map<String, dynamic>;
      expect(commit['subject'], 'fix "quoted" behavior');
    },
  );
}
