/// Approval prompt (design doc §3.3, §21).
///
/// Shown while a `confirm`/`strong`-risk tool waits for the user. Presents the
/// tool, a human summary and its arguments, with Allow / Always / Deny. The
/// engine is blocked on [ApprovalManager] until one is tapped.
library;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/approval/approval_manager.dart';
import '../../../tools/agent_tool.dart';
import '../../../l10n/l10n.dart';
import 'diff_card.dart';

class ApprovalCard extends StatelessWidget {
  const ApprovalCard({
    super.key,
    required this.request,
    required this.onDecision,
  });

  final ApprovalRequest request;
  final void Function(ApprovalDecision decision) onDecision;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strong = request.risk == ToolRisk.strong;
    final accent = strong ? scheme.error : scheme.tertiary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: accent.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  strong ? Icons.gpp_maybe_outlined : Icons.lock_outline,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strong
                        ? context.l10n.confirmHighRisk
                        : context.l10n.approveAction,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: accent),
                  ),
                ),
                _RiskChip(risk: request.risk),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.summary,
              style: AppTheme.code.copyWith(fontWeight: FontWeight.w600),
            ),
            if (DiffCard.fromData(request.previewData) case final preview?) ...[
              const SizedBox(height: 10),
              preview,
            ],
            if (request.arguments.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'tool: ${request.toolName}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => onDecision(ApprovalDecision.deny),
                  child: Text(
                    request.previewData == null
                        ? context.l10n.deny
                        : context.l10n.reject,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => onDecision(ApprovalDecision.allowAlways),
                  child: Text(
                    request.previewData == null
                        ? context.l10n.alwaysAllow
                        : context.l10n.acceptAll,
                  ),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: () => onDecision(ApprovalDecision.allow),
                  child: Text(
                    request.previewData == null
                        ? context.l10n.allow
                        : context.l10n.accept,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.risk});
  final ToolRisk risk;

  @override
  Widget build(BuildContext context) {
    final label = switch (risk) {
      ToolRisk.auto => context.l10n.riskAuto,
      ToolRisk.confirm => context.l10n.riskConfirm,
      ToolRisk.strong => context.l10n.riskHigh,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
