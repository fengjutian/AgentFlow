/// The uniform Tool interface. Every AgentFlow capability — file access, code
/// search, Git, shell, documents, MCP — is an [AgentTool]. The engine only ever
/// sees this abstraction, which is what keeps the loop vendor- and
/// runtime-agnostic.
library;

import '../core/message.dart';
import '../core/model/model_provider.dart';
import '../runtime/runtime.dart';

/// Risk classification driving the approval policy (see the design doc §3.3).
enum ToolRisk {
  /// Read-only, safe to run automatically (read_file, list_files, git_status).
  auto,

  /// Mutates the workspace or runs arbitrary code — needs a tap-to-confirm
  /// (write_file, apply_patch, run_shell, git_commit).
  confirm,

  /// Destructive or hard to undo — needs an explicit typed confirmation
  /// (git_push, delete_file).
  strong,
}

/// Everything a tool needs to do its job, injected by the engine at execution
/// time. Tools stay stateless and testable.
class ToolContext {
  const ToolContext({
    required this.runtime,
    required this.workingDirectory,
    this.workspaceId,
    this.sessionId,
  });

  final Runtime runtime;
  final String workingDirectory;
  final String? workspaceId;
  final String? sessionId;

  ToolContext copyWith({String? workingDirectory}) => ToolContext(
        runtime: runtime,
        workingDirectory: workingDirectory ?? this.workingDirectory,
        workspaceId: workspaceId,
        sessionId: sessionId,
      );
}

/// Raised by a tool for expected, recoverable failures (missing file, bad
/// argument). The engine converts it into an error [ToolResult] that the model
/// can read and react to, rather than crashing the loop.
class ToolExecutionException implements Exception {
  const ToolExecutionException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class AgentTool {
  /// Unique tool name the model calls, e.g. `read_file`.
  String get name;

  /// Natural-language description shown to the model; write it like API docs.
  String get description;

  /// JSON schema for [execute]'s `arguments`.
  Map<String, dynamic> get inputSchema;

  /// Approval policy for this tool.
  ToolRisk get risk;

  /// The [ToolSpec] advertised to the model.
  ToolSpec get spec => ToolSpec(
        name: name,
        description: description,
        parameters: inputSchema,
      );

  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  );

  /// Short human label for the Activity feed, e.g. `read_file lib/main.dart`.
  String describeCall(Map<String, dynamic> arguments) => name;
}

/// Convenience base for tools with no side effects.
abstract class ReadOnlyTool extends AgentTool {
  @override
  ToolRisk get risk => ToolRisk.auto;
}

/// Convenience base for tools that mutate state or run code.
abstract class MutatingTool extends AgentTool {
  @override
  ToolRisk get risk => ToolRisk.confirm;
}

/// A mutating tool that calculates its exact effect before approval.
abstract class PreviewableTool extends AgentTool {
  Future<ToolPreview> preview(
    Map<String, dynamic> arguments,
    ToolContext context,
  );

  Future<ToolResult> executePrepared(
    Map<String, dynamic> arguments,
    ToolContext context,
    ToolPreview preview,
  );
}

class ToolPreview {
  const ToolPreview({required this.data, this.state});
  final Map<String, dynamic> data;
  final Object? state;
}
