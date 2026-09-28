/// Agent Activity panel (design doc §20, §3.2).
///
/// The signature AgentFlow UI: a live checklist of what the agent is doing —
/// completed steps (✓), the running step (● with spinner), pending steps (○) and
/// failures (!). This replaces the opaque "AI is thinking…" spinner.
library;

import 'package:flutter/material.dart';

import '../../../core/agent/agent_state.dart';
import '../../../l10n/l10n.dart';

class ActivityPanel extends StatelessWidget {
  const ActivityPanel({super.key, required this.items, required this.phase});

  final List<ActivityItem> items;
  final AgentPhase phase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (items.isEmpty && phase == AgentPhase.idle) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.bolt, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  context.l10n.agentActivity,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: scheme.primary),
                ),
                const Spacer(),
                _PhaseBadge(phase: phase),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  phase == AgentPhase.thinking
                      ? '${context.l10n.phaseThinking}…'
                      : _phaseLabel(context, phase),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              for (final item in items)
                _ActivityRow(key: ValueKey<String>(item.id), item: item),
          ],
        ),
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.phase});
  final AgentPhase phase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final busy = !phase.isTerminal && phase != AgentPhase.idle;
    return Row(
      children: <Widget>[
        if (busy) ...<Widget>[
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          _phaseLabel(context, phase),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({super.key, required this.item});
  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color) = switch (item.status) {
      ActivityStatus.done => (Icons.check_circle, Colors.green.shade600),
      ActivityStatus.running => (Icons.radio_button_checked, scheme.primary),
      ActivityStatus.error => (Icons.error, scheme.error),
      ActivityStatus.skipped => (Icons.remove_circle_outline, scheme.outline),
      ActivityStatus.pending => (Icons.radio_button_unchecked, scheme.outline),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          item.status == ActivityStatus.running
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: item.status == ActivityStatus.pending
                        ? scheme.outline
                        : scheme.onSurface,
                  ),
                ),
                if (item.detail != null && item.detail!.isNotEmpty)
                  Text(
                    item.detail!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _phaseLabel(BuildContext context, AgentPhase phase) => switch (phase) {
  AgentPhase.idle => context.l10n.phaseIdle,
  AgentPhase.thinking => context.l10n.phaseThinking,
  AgentPhase.planning => context.l10n.phasePlanning,
  AgentPhase.waitingApproval => context.l10n.phaseWaitingApproval,
  AgentPhase.executing => context.l10n.phaseExecuting,
  AgentPhase.observing => context.l10n.phaseObserving,
  AgentPhase.recovering => context.l10n.phaseRecovering,
  AgentPhase.completed => context.l10n.phaseCompleted,
  AgentPhase.error => context.l10n.phaseError,
  AgentPhase.cancelled => context.l10n.phaseCancelled,
};
