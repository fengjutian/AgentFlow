/// Git tools: git_status, git_diff, git_commit.
///
/// Implemented on top of the Git CLI through the workspace [Runtime] (design doc
/// §33 lists "Git CLI / JGit fallback"). Read-only inspection is auto-approved;
/// committing requires confirmation. Push is intentionally NOT exposed in MVP —
/// the design doc forbids automatic git push (§34).
library;

import '../../core/message.dart';
import '../agent_tool.dart';
import '../tool_args.dart';

/// Base for tools that shell out to `git`.
abstract class _GitTool extends AgentTool {
  Future<ToolResult> _runGit(
    List<String> args,
    ToolContext context, {
    bool isErrorOnNonZero = true,
  }) async {
    final result = await context.runtime.execute(
      'git ${args.join(' ')}',
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
  ) =>
      _runGit(<String>['status', '--porcelain', '-b'], context,
          isErrorOnNonZero: true);
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
    if (path.isNotEmpty) args.add(path);
    final result = await _runGit(args, context, isErrorOnNonZero: true);
    if (result.content.trim().isEmpty) {
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

class GitCommitTool extends _GitTool {
  @override
  String get name => 'git_commit';

  @override
  ToolRisk get risk => ToolRisk.confirm;

  @override
  String get description =>
      'Stage all changes and create a commit with the given message. Runs '
      '"git add -A" then "git commit -m". Requires user approval. Never pushes.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'message': <String, dynamic>{
            'type': 'string',
            'description': 'Commit message.',
          },
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
    await _runGit(<String>['add', '-A'], context);
    final escaped = message.replaceAll('"', r'\"');
    final commit = await _runGit(
      <String>['commit', '-m', '"$escaped"'],
      context,
      isErrorOnNonZero: true,
    );
    return commit;
  }
}

List<AgentTool> gitTools() => <AgentTool>[
      GitStatusTool(),
      GitDiffTool(),
      GitCommitTool(),
    ];
