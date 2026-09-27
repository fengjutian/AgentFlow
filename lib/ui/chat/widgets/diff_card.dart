/// Diff card (design doc §21).
///
/// Renders a [FileDiff] produced by `write_file` with per-line add/remove
/// coloring and a header summary. This is the "show, don't silently overwrite"
/// surface that distinguishes an agent from a chatbot.
library;

import 'package:flutter/material.dart';

import '../../../core/diff/line_diff.dart';
import '../../../app/theme.dart';

class DiffCard extends StatelessWidget {
  const DiffCard({super.key, required this.diff, this.onUndo});

  final FileDiff diff;
  final Future<String> Function()? onUndo;

  /// Builds a card from a tool result's `data['diff']` payload, or null.
  static DiffCard? fromData(
    Map<String, dynamic>? data, {
    Future<String> Function()? onUndo,
  }) {
    final raw = data?['diff'];
    if (raw is Map) {
      return DiffCard(
        diff: FileDiff.fromJson(raw.cast<String, dynamic>()),
        onUndo: onUndo,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: scheme.surfaceContainerHighest,
            child: Row(
              children: <Widget>[
                Icon(
                  diff.isNewFile
                      ? Icons.note_add_outlined
                      : Icons.difference_outlined,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    diff.path,
                    style: AppTheme.code.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _SummaryChip(diff: diff),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final line in diff.lines) _DiffLineView(line: line),
                ],
              ),
            ),
          ),
          if (onUndo != null) ...<Widget>[
            const Divider(height: 1),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  try {
                    final message = await onUndo!();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(message)));
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.toString())),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Undo'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.diff});
  final FileDiff diff;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (diff.addedCount > 0)
          Text('+${diff.addedCount}',
              style: AppTheme.code.copyWith(color: AppTheme.added)),
        const SizedBox(width: 6),
        if (diff.removedCount > 0)
          Text('−${diff.removedCount}',
              style: AppTheme.code.copyWith(color: AppTheme.removed)),
      ],
    );
  }
}

class _DiffLineView extends StatelessWidget {
  const _DiffLineView({required this.line});
  final DiffLine line;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    switch (line.type) {
      case DiffLineType.added:
        background = AppTheme.added.withValues(alpha: 0.14);
        foreground = AppTheme.added;
      case DiffLineType.removed:
        background = AppTheme.removed.withValues(alpha: 0.14);
        foreground = AppTheme.removed;
      case DiffLineType.context:
        background = Colors.transparent;
        foreground = Theme.of(context).colorScheme.onSurfaceVariant;
    }
    final number = (line.newNumber ?? line.oldNumber ?? 0).toString();
    return Container(
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Text(
              number,
              textAlign: TextAlign.right,
              style: AppTheme.code.copyWith(
                color: foreground.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(line.prefix,
              style: AppTheme.code.copyWith(color: foreground)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              line.content.isEmpty ? ' ' : line.content,
              style: AppTheme.code.copyWith(color: foreground),
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
