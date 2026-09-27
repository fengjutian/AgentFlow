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

/// Result of [ContextManager.build]: the assembled request plus any structural
/// summary produced when older messages were trimmed to fit the budget.
class ContextBuildResult {
  const ContextBuildResult({required this.request, this.droppedSummary});

  final ModelRequest request;

  /// Non-null when messages were dropped. The engine merges this into the
  /// running `conversationSummary` so earlier context is not silently lost.
  final String? droppedSummary;
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
  /// Returns a [ContextBuildResult] containing the request and an optional
  /// structural summary of any messages that were trimmed.
  ContextBuildResult build({
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

    final fitResult = _fitToBudget(history, config.contextWindow);
    messages.addAll(fitResult.messages);

    // Merge any pre-existing summary with the freshly generated one.
    String? mergedSummary = conversationSummary;
    if (fitResult.droppedSummary != null) {
      mergedSummary = mergedSummary == null || mergedSummary.isEmpty
          ? fitResult.droppedSummary
          : '$mergedSummary\n\n${fitResult.droppedSummary}';
    }

    return ContextBuildResult(
      request: ModelRequest(
        messages: messages,
        tools: registry.specs,
        config: config,
      ),
      droppedSummary: mergedSummary,
    );
  }

  /// Drops the oldest messages until the estimated total fits within ~90% of the
  /// model's context window, leaving headroom for the reply and tool schemas.
  /// Returns the trimmed messages and a structural summary of what was dropped.
  _FitResult _fitToBudget(List<ChatMessage> history, int contextWindow) {
    if (history.isEmpty) return _FitResult(messages: history);
    final budget = (contextWindow * 0.9).round();
    if (estimateTokens(history) <= budget) {
      return _FitResult(messages: List<ChatMessage>.of(history));
    }

    final trimmed = List<ChatMessage>.of(history);
    final dropped = <ChatMessage>[];
    // Never drop a trailing dangling tool message without its assistant call:
    // trim from the front, but stop before breaking the last exchange.
    while (trimmed.length > 2 && estimateTokens(trimmed) > budget) {
      dropped.add(trimmed.removeAt(0));
      // If we now start on a tool result, drop it too (its call is gone).
      while (trimmed.isNotEmpty && trimmed.first.role == MessageRole.tool) {
        dropped.add(trimmed.removeAt(0));
      }
    }
    return _FitResult(
      messages: trimmed,
      droppedSummary: _summarizeDropped(dropped),
    );
  }

  /// Produces a compact structural summary of messages that were trimmed from
  /// the context, so the model retains awareness of earlier work.
  String? _summarizeDropped(List<ChatMessage> dropped) {
    if (dropped.isEmpty) return null;
    final lines = <String>[];
    for (final msg in dropped) {
      switch (msg.role) {
        case MessageRole.user:
          final preview = msg.content.length > 200
              ? '${msg.content.substring(0, 200)}…'
              : msg.content;
          lines.add('User asked: $preview');
        case MessageRole.assistant:
          if (msg.content.isNotEmpty) {
            final preview = msg.content.length > 200
                ? '${msg.content.substring(0, 200)}…'
                : msg.content;
            lines.add('Assistant: $preview');
          }
          for (final call in msg.toolCalls) {
            final argKeys = call.arguments.keys.join(', ');
            lines.add('Called ${call.name}($argKeys)');
          }
        case MessageRole.tool:
          final preview = msg.content.length > 150
              ? '${msg.content.substring(0, 150)}…'
              : msg.content;
          lines.add('${msg.name ?? 'tool'} result: $preview');
        case MessageRole.system:
          break; // skip system messages in summary
      }
    }
    if (lines.isEmpty) return null;
    return 'Earlier conversation (trimmed for context budget):\n'
        '${lines.join('\n')}';
  }
}

class _FitResult {
  const _FitResult({required this.messages, this.droppedSummary});
  final List<ChatMessage> messages;
  final String? droppedSummary;
}
