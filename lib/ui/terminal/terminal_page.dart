/// Terminal tab with persistent interactive shell (design doc §23).
///
/// Connects to a [ShellSession] (local, bridge, or SSH) and renders output in
/// a terminal emulator backed by [TerminalBuffer]. The shell process persists
/// across commands — unlike the previous stateless `runtime.execute()` approach,
/// `cd`, environment variables, and running programs survive between keystrokes.
///
/// Special keys (Ctrl+C, Ctrl+D) are forwarded via [ShellSession.sendSignal].
/// Terminal dimensions are reported via [ShellSession.resize] on layout changes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../app/theme.dart';
import '../../runtime/local_shell_session.dart';
import '../../runtime/shell_session.dart';
import '../../runtime/terminal_buffer.dart';

class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key});

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage>
    with WidgetsBindingObserver {
  ShellSession? _session;
  StreamSubscription<String>? _outputSub;
  final TerminalBuffer _buffer = TerminalBuffer();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startShell();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _outputSub?.cancel();
    _session?.close();
    _scroll.dispose();
    _input.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Terminal resized — update buffer and notify shell.
    _updateTerminalSize();
  }

  Future<void> _startShell() async {
    final workspace = ref.read(currentWorkspaceProvider);
    if (workspace == null) return;

    try {
      final session = await LocalShellSession.start(
        initialRows: 24,
        initialCols: 80,
        workingDirectory: workspace.rootDirectory,
      );
      if (!mounted) {
        await session.close();
        return;
      }
      _session = session;

      _outputSub = session.output.listen(
        (String chunk) {
          if (!mounted) return;
          setState(() {
            _buffer.feed(chunk);
          });
          _scrollToBottom();
        },
        onDone: _onShellExit,
        onError: (Object e) {
          if (!mounted) return;
          setState(() {
            _buffer.feed('\r\n[Shell error: $e]\r\n');
          });
        },
      );

      // Wait a frame for layout, then report the actual terminal size.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateTerminalSize();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buffer.feed('[Failed to start shell: $e]\r\n');
      });
    }
  }

  void _onShellExit() {
    if (!mounted) return;
    setState(() {
      _buffer.feed('\r\n[Shell exited]\r\n');
    });
  }

  void _updateTerminalSize() {
    if (!mounted || _session == null) return;
    // Estimate terminal dimensions from the available space and font metrics.
    final context = this.context;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final size = renderBox.size;
    // Approximate cell dimensions from the code font.
    const charWidth = 8.0;
    const charHeight = 16.0;
    final cols = (size.width / charWidth).floor().clamp(20, 300);
    final rows = (size.height / charHeight).floor().clamp(5, 100);

    if (rows != _buffer.rows || cols != _buffer.cols) {
      _buffer.resize(rows, cols);
      _session!.resize(rows, cols);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _sendInput(String text) {
    final session = _session;
    if (session == null || !session.isAlive) return;
    session.writeStdin('$text\n');
    _input.clear();
  }

  void _sendSignal(TerminalSignal signal) {
    _session?.sendSignal(signal);
  }

  void _sendRawKey(String key) {
    _session?.writeStdin(key);
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(currentWorkspaceProvider);

    ref.listen<String?>(activeWorkspaceProvider, (
      String? previous,
      String? next,
    ) {
      if (previous == next) return;
      _session?.close();
      _session = null;
      setState(() {
        _buffer.feed('[Workspace changed, restarting shell...]\r\n');
      });
      _startShell();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          workspace == null
              ? context.l10n.terminal
              : '${context.l10n.terminal} · ${workspace.name}',
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Ctrl+C',
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed:
                _session?.isAlive == true ? () => _sendSignal(TerminalSignal.ctrlC) : null,
          ),
          IconButton(
            tooltip: context.l10n.clear,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => setState(() {
              for (var i = 0; i < _buffer.rows; i++) {
                _buffer.grid[i].clearAll();
              }
            }),
          ),
        ],
      ),
      body: workspace == null
          ? _TerminalHint(message: context.l10n.selectWorkspaceForTerminal)
          : KeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: _handleKeyEvent,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: _TerminalView(buffer: _buffer, scroll: _scroll),
                    ),
                  ),
                  _PromptBar(
                    controller: _input,
                    onSubmit: _sendInput,
                    onTab: () => _sendRawKey('\t'),
                  ),
                ],
              ),
            ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    // Handle special keys.
    if (key == LogicalKeyboardKey.arrowUp) {
      _sendRawKey('\x1b[A');
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _sendRawKey('\x1b[B');
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _sendRawKey('\x1b[C');
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _sendRawKey('\x1b[D');
    } else if (key == LogicalKeyboardKey.home) {
      _sendRawKey('\x1b[H');
    } else if (key == LogicalKeyboardKey.end) {
      _sendRawKey('\x1b[F');
    } else if (key == LogicalKeyboardKey.delete) {
      _sendRawKey('\x1b[3~');
    } else if (key == LogicalKeyboardKey.pageUp) {
      _sendRawKey('\x1b[5~');
    } else if (key == LogicalKeyboardKey.pageDown) {
      _sendRawKey('\x1b[6~');
    }
  }
}

/// Renders the [TerminalBuffer] grid using monospaced text spans with ANSI
/// colors applied as [TextStyle] attributes.
class _TerminalView extends StatelessWidget {
  const _TerminalView({required this.buffer, required this.scroll});

  final TerminalBuffer buffer;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final defaultFg = scheme.onSurface;
    final defaultBg = scheme.surfaceContainerLowest;

    return Container(
      color: defaultBg,
      child: ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: buffer.rows,
        itemBuilder: (BuildContext context, int i) {
          final row = buffer.grid[i];
          return RichText(
            text: _buildRowSpan(row, defaultFg, defaultBg,
                isCursorRow: i == buffer.cursorRow,
                cursorCol: buffer.cursorCol),
          );
        },
      ),
    );
  }

  TextSpan _buildRowSpan(
    TerminalRow row,
    Color defaultFg,
    Color defaultBg, {
    required bool isCursorRow,
    required int cursorCol,
  }) {
    final spans = <TextSpan>[];
    for (var col = 0; col < buffer.cols; col++) {
      final cell = row.cellAt(col);
      final isCursor = isCursorRow && col == cursorCol;
      final attrs = cell.attributes;

      Color fg = attrs.foreground ?? defaultFg;
      Color bg = attrs.background ?? defaultBg;
      if (attrs.inverse || isCursor) {
        final tmp = fg;
        fg = bg;
        bg = tmp;
      }

      spans.add(TextSpan(
        text: cell.char,
        style: AppTheme.code.copyWith(
          color: fg,
          backgroundColor: bg,
          fontWeight: attrs.bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: attrs.italic ? FontStyle.italic : FontStyle.normal,
          decoration: attrs.underline
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      ));
    }
    return TextSpan(children: spans);
  }
}

class _PromptBar extends StatelessWidget {
  const _PromptBar({
    required this.controller,
    required this.onSubmit,
    required this.onTab,
  });

  final TextEditingController controller;
  final void Function(String) onSubmit;
  final VoidCallback onTab;

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
              '>',
              style: AppTheme.code.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTheme.code,
                textInputAction: TextInputAction.send,
                onSubmitted: onSubmit,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: context.l10n.commandHint,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Tab',
              icon: const Icon(Icons.keyboard_tab, size: 20),
              onPressed: onTab,
            ),
            IconButton.filled(
              tooltip: context.l10n.run,
              icon: const Icon(Icons.play_arrow),
              onPressed: () => onSubmit(controller.text),
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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
