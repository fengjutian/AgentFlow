/// Terminal card (design doc §22).
///
/// Renders a `run_shell` result as a mini terminal: the command line, combined
/// output and an exit-code badge, so the user sees exactly what ran.
library;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class TerminalCard extends StatelessWidget {
  const TerminalCard({
    super.key,
    required this.command,
    required this.output,
    required this.exitCode,
    this.timedOut = false,
  });

  final String command;
  final String output;
  final int exitCode;
  final bool timedOut;

  /// Builds from a tool result's `data` payload (run_shell), or null.
  static TerminalCard? fromData(Map<String, dynamic>? data) {
    if (data == null || data['exitCode'] == null) return null;
    final stdout = (data['stdout'] as String?) ?? '';
    final stderr = (data['stderr'] as String?) ?? '';
    final combined = <String>[
      if (stdout.trim().isNotEmpty) stdout.trimRight(),
      if (stderr.trim().isNotEmpty) stderr.trimRight(),
    ].join('\n');
    return TerminalCard(
      command: (data['command'] as String?) ?? '',
      output: combined,
      exitCode: (data['exitCode'] as num).toInt(),
      timedOut: (data['timedOut'] as bool?) ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ok = exitCode == 0 && !timedOut;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: <Widget>[
                const Icon(Icons.terminal, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '\$ $command',
                    style: AppTheme.code.copyWith(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _ExitBadge(ok: ok, exitCode: exitCode, timedOut: timedOut),
              ],
            ),
          ),
          if (output.trim().isNotEmpty) ...<Widget>[
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  output,
                  style: AppTheme.code.copyWith(color: Colors.white70),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExitBadge extends StatelessWidget {
  const _ExitBadge({
    required this.ok,
    required this.exitCode,
    required this.timedOut,
  });
  final bool ok;
  final int exitCode;
  final bool timedOut;

  @override
  Widget build(BuildContext context) {
    final color = ok ? Colors.greenAccent : Colors.redAccent;
    final label = timedOut ? 'timeout' : 'exit $exitCode';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: AppTheme.code.copyWith(color: color)),
    );
  }
}
