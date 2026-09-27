/// Terminal tab (design doc §23).
///
/// A minimal interactive shell over the [Runtime] abstraction. Commands run in
/// the workspace root (or a `cd`-selected subfolder) and their output streams
/// into a scrollback. This is the human-facing counterpart to the agent's
/// `run_shell` tool: same runtime, same working directory semantics.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../app/theme.dart';
import '../../runtime/runtime.dart';

/// One rendered row in the scrollback.
enum _LineKind { command, stdout, stderr, info }

class _Line {
  const _Line(this.kind, this.text);
  final _LineKind kind;
  final String text;
}

class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key});

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<String> _history = <String>[];
  final List<_Line> _lines = <_Line>[];

  /// Working directory relative to the workspace root ('' == root).
  String _cwd = '';
  bool _running = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(currentWorkspaceProvider);
    final runtimeAsync = ref.watch(runtimeProvider);

    ref.listen<String?>(activeWorkspaceProvider, (
      String? previous,
      String? next,
    ) {
      if (previous == next) return;
      setState(() {
        _cwd = '';
        _lines.clear();
      });
    });

    final runtime = runtimeAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          workspace == null
              ? context.l10n.terminal
              : '${context.l10n.terminal} · ${workspace.name}',
        ),
        actions: <Widget>[
          IconButton(
            tooltip: context.l10n.clear,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _lines.isEmpty ? null : () => setState(_lines.clear),
          ),
        ],
      ),
      body: workspace == null
          ? _TerminalHint(message: context.l10n.selectWorkspaceForTerminal)
          : runtime == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Expanded(
                  child: _Scrollback(lines: _lines, controller: _scroll),
                ),
                _Prompt(
                  cwd: _cwd,
                  controller: _input,
                  running: _running,
                  onSubmit: () => _run(runtime),
                  onHistory: _cycleHistory,
                ),
              ],
            ),
    );
  }

  void _append(_LineKind kind, String text) {
    if (text.isEmpty) return;
    setState(() {
      for (final line in text.split('\n')) {
        _lines.add(_Line(kind, line));
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _run(Runtime runtime) async {
    final command = _input.text.trim();
    if (command.isEmpty || _running) return;
    _input.clear();
    setState(() {
      _history.add(command);
      _lines.add(_Line(_LineKind.command, '\$ $command'));
    });
    _scrollToBottom();

    // Handle `cd` locally: each execute() is stateless across calls.
    if (command == 'cd' || command.startsWith('cd ')) {
      setState(() => _cwd = _resolveCd(command.substring(2).trim()));
      _scrollToBottom();
      return;
    }
    if (command == 'clear' || command == 'cls') {
      setState(_lines.clear);
      return;
    }

    setState(() => _running = true);
    try {
      final result = await runtime.execute(
        command,
        workingDirectory: _cwd.isEmpty ? null : _cwd,
        timeoutMillis: 120000,
      );
      if (result.stdout.trim().isNotEmpty) {
        _append(_LineKind.stdout, result.stdout.trimRight());
      }
      if (result.stderr.trim().isNotEmpty) {
        _append(_LineKind.stderr, result.stderr.trimRight());
      }
      if (result.timedOut) {
        _append(_LineKind.info, '(timed out)');
      } else if (result.exitCode != 0) {
        _append(_LineKind.info, '(exit ${result.exitCode})');
      }
    } catch (e) {
      _append(_LineKind.stderr, 'Error: $e');
    } finally {
      if (mounted) setState(() => _running = false);
      _scrollToBottom();
    }
  }

  /// Resolves a `cd` argument against the current relative working directory.
  String _resolveCd(String arg) {
    if (arg.isEmpty) return ''; // `cd` alone → workspace root.
    if (arg == '.') return _cwd;
    final absolute =
        arg.startsWith('/') ||
        (arg.length > 1 && arg[1] == ':'); // Windows drive letter.
    if (absolute) return arg;

    final segments = _cwd.isEmpty
        ? <String>[]
        : _cwd
              .split(RegExp(r'[\\/]'))
              .where((String s) => s.isNotEmpty)
              .toList();
    for (final part in arg.split(RegExp(r'[\\/]'))) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (segments.isNotEmpty) segments.removeLast();
      } else {
        segments.add(part);
      }
    }
    return segments.join('/');
  }

  /// Cycles the input through previous commands (used by the history button).
  void _cycleHistory() {
    if (_history.isEmpty) return;
    final last = _history.last;
    setState(() => _input.text = last);
    _input.selection = TextSelection.collapsed(offset: _input.text.length);
  }
}

class _Scrollback extends StatelessWidget {
  const _Scrollback({required this.lines, required this.controller});

  final List<_Line> lines;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (lines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Type a command below.\nTry: ls, pwd, git status, cat README.md',
            textAlign: TextAlign.center,
            style: AppTheme.code.copyWith(color: scheme.outline),
          ),
        ),
      );
    }
    return Container(
      color: scheme.surfaceContainerLowest,
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: lines.length,
        itemBuilder: (BuildContext context, int i) {
          final line = lines[i];
          return SelectableText(
            line.text.isEmpty ? ' ' : line.text,
            style: AppTheme.code.copyWith(color: _colorFor(scheme, line.kind)),
          );
        },
      ),
    );
  }

  Color _colorFor(ColorScheme scheme, _LineKind kind) => switch (kind) {
    _LineKind.command => scheme.primary,
    _LineKind.stderr => scheme.error,
    _LineKind.info => scheme.outline,
    _LineKind.stdout => scheme.onSurface,
  };
}

class _Prompt extends StatelessWidget {
  const _Prompt({
    required this.cwd,
    required this.controller,
    required this.running,
    required this.onSubmit,
    required this.onHistory,
  });

  final String cwd;
  final TextEditingController controller;
  final bool running;
  final VoidCallback onSubmit;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          children: <Widget>[
            Text(
              cwd.isEmpty ? '~\$' : '$cwd\$',
              style: AppTheme.code.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !running,
                style: AppTheme.code,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: context.l10n.commandHint,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            IconButton(
              tooltip: context.l10n.lastCommand,
              icon: const Icon(Icons.history, size: 20),
              onPressed: running ? null : onHistory,
            ),
            running
                ? const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(),
                    ),
                  )
                : IconButton.filled(
                    tooltip: context.l10n.run,
                    icon: const Icon(Icons.play_arrow),
                    onPressed: onSubmit,
                  ),
          ],
        ),
      ),
    );
  }
}

class _TerminalHint extends StatelessWidget {
  const _TerminalHint({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.terminal, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
