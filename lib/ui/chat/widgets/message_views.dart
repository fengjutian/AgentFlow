/// Message rendering for the chat transcript.
///
/// Maps each [TranscriptMessage] to the right surface: user/assistant bubbles,
/// and for tool observations a Diff card, a Terminal card, or a generic
/// collapsible result card. This is where "the agent shows its work" happens.
library;

import 'package:flutter/material.dart';

import '../../../core/message.dart';
import '../../../app/theme.dart';
import '../../../data/models.dart';
import '../../../tools/filesystem/file_tools.dart';
import '../../../l10n/l10n.dart';
import 'diff_card.dart';
import 'terminal_card.dart';

class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.message});

  final TranscriptMessage message;

  @override
  Widget build(BuildContext context) {
    switch (message.role) {
      case MessageRole.user:
        return _UserBubble(text: message.content);
      case MessageRole.assistant:
        if (message.content.trim().isEmpty) {
          return _ToolCallIntent(calls: message.toolCalls);
        }
        return _AssistantBubble(text: message.content);
      case MessageRole.tool:
        return ToolResultView(message: message);
      case MessageRole.system:
        return const SizedBox.shrink();
    }
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: SelectableText(
          text,
          style: TextStyle(color: scheme.onPrimary, height: 1.35),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: SelectableText(text, style: const TextStyle(height: 1.4)),
      ),
    );
  }
}

/// Shown when an assistant turn only requested tools (no prose).
class _ToolCallIntent extends StatelessWidget {
  const _ToolCallIntent({required this.calls});
  final List<ToolCall> calls;

  @override
  Widget build(BuildContext context) {
    if (calls.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      child: Row(
        children: <Widget>[
          Icon(Icons.psychology_outlined, size: 14, color: scheme.outline),
          const SizedBox(width: 6),
          Text(
            context.l10n.callingTools(
              calls.map((ToolCall c) => c.name).join(', '),
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

/// Renders a tool observation with the richest applicable card.
class ToolResultView extends StatelessWidget {
  const ToolResultView({super.key, required this.message});
  final TranscriptMessage message;

  @override
  Widget build(BuildContext context) {
    final data = message.data;
    final transactionId = data?['transactionId'] as String?;
    final diff = DiffCard.fromData(
      data,
      onUndo: transactionId == null
          ? null
          : () => fileChangeJournal.undo(transactionId),
    );
    if (diff != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (message.content.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            diff,
          ],
        ),
      );
    }
    final terminal = TerminalCard.fromData(data);
    if (terminal != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: terminal,
      );
    }
    return _GenericToolCard(message: message);
  }
}

class _GenericToolCard extends StatelessWidget {
  const _GenericToolCard({required this.message});
  final TranscriptMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final denied = message.data?['denied'] == true;
    final accent = denied
        ? scheme.outline
        : (message.isError ? scheme.error : scheme.primary);
    final icon = denied
        ? Icons.block
        : (message.isError
              ? Icons.warning_amber_rounded
              : Icons.build_outlined);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: Card(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(icon, size: 18, color: accent),
            title: Text(
              message.name ?? 'tool',
              style: AppTheme.code.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              denied ? context.l10n.deniedByUser : _firstLine(message.content),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(
                    message.content.isEmpty ? context.l10n.noOutput : message.content,
                    style: AppTheme.code,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _firstLine(String text) {
    for (final line in text.split('\n')) {
      if (line.trim().isNotEmpty) {
        return line.length > 80 ? '${line.substring(0, 80)}…' : line;
      }
    }
    return 'done';
  }
}
