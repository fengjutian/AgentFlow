/// Context assembly (design doc §17).
///
/// The naive approach — dump the entire transcript to the model every turn —
/// blows the context window and degrades reasoning. [ContextManager] composes a
/// focused request: a stable system prompt, workspace facts, long-term memory,
/// and the most recent turns that fit the configured budget. It is a pure
/// function over state, which makes the loop's decisions reproducible in tests.
library;

import '../message.dart';
import '../model/model_provider.dart';
import '../../tools/tool_registry.dart';

/// Snapshot of the environment the agent is operating in.
class WorkspaceContext {
  const WorkspaceContext({
    required this.workspaceName,
    required this.rootDirectory,
    required this.runtimeLabel,
    this.projectSummary = '',
    this.memoryBlock = '',
  });

  final String workspaceName;
  final String rootDirectory;
  final String runtimeLabel;
  final String projectSummary;
  final String memoryBlock;
}

class ContextManager {
  ContextManager({this.approxTokensPerChar = 1 / 4});

  /// Rough chars-per-token inverse used for budgeting. 4 chars ≈ 1 token is the
  /// common heuristic; we store the multiplier.
  final double approxTokensPerChar;

  static const String _baseSystemPrompt = '''
You are AgentFlow, an autonomous coding agent running on the user's device.
You accomplish tasks by calling tools and observing their results, not by
guessing. Follow this loop:
1. Understand the task and inspect the workspace (list_files, read_file, search_code).
2. Form a short plan before making changes.
3. Use tools to act. Prefer read-only tools first.
4. After mutating a file or running a command, verify the result.
5. When the task is done, reply with a concise summary of what you changed and why.

Rules:
- Never invent file contents or command output; always read them with a tool.
- Use absolute paths only when necessary; relative paths are resolved from the workspace root.
- If a tool errors, adapt — read the message, correct the arguments, and retry.
- Ask for confirmation implicitly by proposing changes before applying them.
- Keep responses focused and technical. Do not narrate every step once finished.
''';

  /// Estimates the token cost of a message list.
  int estimateTokens(List<ChatMessage> messages) {
    var chars = 0;
    for (final m in messages) {
      chars += m.content.length;
      for (final c in m.toolCalls) {
        chars += c.name.length + c.arguments.toString().length;
      }
    }
    return (chars * approxTokensPerChar).ceil();
  }

  /// Builds the system prompt for a run, injecting workspace + memory facts.
  String buildSystemPrompt(WorkspaceContext ctx) {
    final buffer = StringBuffer(_baseSystemPrompt)
      ..writeln()
      ..writeln('# Workspace')
      ..writeln('Name: ${ctx.workspaceName}')
      ..writeln('Root: ${ctx.rootDirectory}')
      ..writeln('Runtime: ${ctx.runtimeLabel}');
    if (ctx.projectSummary.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('# Project')
        ..writeln(ctx.projectSummary.trim());
    }
    if (ctx.memoryBlock.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('# Memory')
        ..writeln(ctx.memoryBlock.trim());
    }
    return buffer.toString().trim();
  }

  /// Assembles the [ModelRequest] for one loop iteration.
  ///
  /// [history] excludes the system message; it is prepended here. When the
  /// transcript exceeds the budget, the oldest turns are dropped (keeping any
  /// leading summary) so the model still sees the recent, relevant context.
  ModelRequest build({
    required WorkspaceContext workspace,
    required List<ChatMessage> history,
    required ToolRegistry registry,
    required ModelConfig config,
    String? conversationSummary,
  }) {
    final system = ChatMessage.system(buildSystemPrompt(workspace));
    final messages = <ChatMessage>[system];

    if (conversationSummary != null && conversationSummary.trim().isNotEmpty) {
      messages.add(ChatMessage.system(
        'Summary of earlier conversation:\n${conversationSummary.trim()}',
      ));
    }

    messages.addAll(_fitToBudget(history, config.contextWindow));
    return ModelRequest(
      messages: messages,
      tools: registry.specs,
      config: config,
    );
  }

  /// Drops the oldest messages until the estimated total fits within ~90% of the
  /// model's context window, leaving headroom for the reply and tool schemas.
  List<ChatMessage> _fitToBudget(List<ChatMessage> history, int contextWindow) {
    if (history.isEmpty) return history;
    final budget = (contextWindow * 0.9).round();
    if (estimateTokens(history) <= budget) return List<ChatMessage>.of(history);

    final trimmed = List<ChatMessage>.of(history);
    // Never drop a trailing dangling tool message without its assistant call:
    // trim from the front, but stop before breaking the last exchange.
    while (trimmed.length > 2 && estimateTokens(trimmed) > budget) {
      trimmed.removeAt(0);
      // If we now start on a tool result, drop it too (its call is gone).
      while (trimmed.isNotEmpty && trimmed.first.role == MessageRole.tool) {
        trimmed.removeAt(0);
      }
    }
    return trimmed;
  }
}
