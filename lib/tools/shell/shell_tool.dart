/// Shell tool: run_shell.
///
/// Executes a command through the workspace [Runtime] (Termux on Android, a
/// local shell on desktop). This is a `confirm`-risk tool because arbitrary
/// command execution can mutate or destroy state. Output is streamed back as a
/// single [ToolResult] for MVP; a PTY-backed streaming terminal is the MVP-2
/// upgrade path.
library;

import '../../core/message.dart';
import '../agent_tool.dart';
import '../tool_args.dart';

class RunShellTool extends MutatingTool {
  @override
  String get name => 'run_shell';

  @override
  String get description =>
      'Run a shell command in the workspace and return stdout, stderr and the '
      'exit code. Use it to build, test, install dependencies or inspect state '
      '(e.g. "npm test", "git log --oneline -5"). Long-running or interactive '
      'commands are not supported; they time out. Requires user approval.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'command': <String, dynamic>{
            'type': 'string',
            'description': 'The command line to execute.',
          },
          'cwd': <String, dynamic>{
            'type': 'string',
            'description': 'Optional working directory relative to the workspace root.',
          },
          'timeoutMillis': <String, dynamic>{
            'type': 'integer',
            'description': 'Optional timeout in milliseconds (default 60000).',
          },
        },
        'required': <String>['command'],
      };

  @override
  String describeCall(Map<String, dynamic> arguments) =>
      '\$ ${optionalString(arguments, 'command')}';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final command = requireString(arguments, 'command');
    final cwd = optionalString(arguments, 'cwd');
    final timeout = optionalInt(arguments, 'timeoutMillis', fallback: 60000);

    final result = await context.runtime.execute(
      command,
      workingDirectory: cwd.isEmpty ? context.workingDirectory : cwd,
      timeoutMillis: timeout,
    );

    final header = 'Exit code: ${result.exitCode}'
        '${result.timedOut ? ' (timed out)' : ''}';
    final body = result.combinedOutput;
    final content = clampOutput('$header\n${body.isEmpty ? '(no output)' : body}');

    return ToolResult(
      toolCallId: '',
      name: name,
      content: content,
      isError: !result.success,
      data: <String, dynamic>{
        'command': command,
        'cwd': result.workingDirectory,
        'exitCode': result.exitCode,
        'stdout': result.stdout,
        'stderr': result.stderr,
        'timedOut': result.timedOut,
      },
    );
  }
}

List<AgentTool> shellTools() => <AgentTool>[RunShellTool()];
