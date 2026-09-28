/// Terminal tab with persistent interactive shell (design doc §23).
///
/// Connects to a [ShellSession] (local, bridge, or SSH) and renders output in
/// a terminal emulator backed by [TerminalBuffer]. The shell process persists
/// across commands — unlike the previous stateless `runtime.execute()` approach,
/// `cd`, environment variables, and running programs survive between keystrokes.
///
/// Features:
/// - Batched TextSpan rendering (merges same-style cells into single spans)
/// - Debounced rebuilds (coalesces rapid output into one frame)
/// - Cursor blinking (500ms interval)
/// - Scrollback rendering (up to 10,000 lines)
/// - Auto-scroll-to-bottom with scroll-to-bottom FAB
/// - Accurate font measurement via TextPainter
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  // --- Sprint 1.2: Debounced rebuilds ---
  bool _dirty = false;

  // --- Sprint 1.3: Cursor blinking ---
  bool _cursorVisible = true;
  Timer? _cursorTimer;

  // --- Sprint 2: Scrollback ---
  bool _isAtBottom = true;
  static const double _bottomThreshold = 40.0;

  // --- Sprint 3: Font measurement ---
  double _charWidth = 8.0;
  double _charHeight = 16.0;
  bool _fontMeasured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScrollChanged);
    _startCursorTimer();
    _startShell();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cursorTimer?.cancel();
    _outputSub?.cancel();
    _session?.close();
    _scroll.dispose();
    _input.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measureFont();
  }

  @override
  void didChangeMetrics() {
    _updateTerminalSize();
  }

  // --- Sprint 3.1: Measure actual glyph size ---

  void _measureFont() {
    final tp = TextPainter(
      text: const TextSpan(text: 'M', style: AppTheme.code),
      textDirection: TextDirection.ltr,
    )..layout();
    if (tp.width > 0) {
      _charWidth = tp.width;
      _charHeight = tp.height;
      _fontMeasured = true;
    }
  }

  // --- Sprint 1.3: Cursor blinking ---

  void _startCursorTimer() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      if (_session?.isAlive != true) return;
      setState(() => _cursorVisible = !_cursorVisible);
    });
  }

  /// Resets the cursor to visible when output arrives (standard terminal
  /// behaviour: any output restarts the blink cycle).
  void _resetCursorBlink() {
    if (!_cursorVisible) {
      setState(() => _cursorVisible = true);
    }
    _cursorTimer?.cancel();
    _startCursorTimer();
  }

  // --- Sprint 2: Scroll tracking ---

  void _onScrollChanged() {
    if (!_scroll.hasClients) return;
    final atBottom = _scroll.position.pixels >=
        _scroll.position.maxScrollExtent - _bottomThreshold;
    if (atBottom != _isAtBottom) {
      setState(() => _isAtBottom = atBottom);
    }
  }

  void _scrollToBottom() {
    if (!_isAtBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
        setState(() => _isAtBottom = true);
      }
    });
  }

  // --- Shell lifecycle ---

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
          _buffer.feed(chunk);
          _resetCursorBlink();
          // Sprint 1.2: Debounced rebuild — coalesce rapid output into one
          // frame instead of calling setState on every chunk.
          if (!_dirty) {
            _dirty = true;
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _dirty = false;
              setState(() {});
              _scrollToBottom();
            });
          }
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

  // --- Sprint 3.2: Dynamic terminal sizing ---

  void _updateTerminalSize() {
    if (!mounted || _session == null || !_fontMeasured) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final size = renderBox.size;
    final cols = (size.width / _charWidth).floor().clamp(20, 300);
    final rows = (size.height / _charHeight).floor().clamp(5, 100);

    if (rows != _buffer.rows || cols != _buffer.cols) {
      _buffer.resize(rows, cols);
      _session!.resize(rows, cols);
    }
  }

  // --- Input ---

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

  // --- Build ---

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
            onPressed: _session?.isAlive == true
                ? () => _sendSignal(TerminalSignal.ctrlC)
                : null,
          ),
          IconButton(
            tooltip: context.l10n.clear,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => setState(() {
              for (var i = 0; i < _buffer.rows; i++) {
                _buffer.grid[i].clearAll();
              }
              _buffer.scrollback.clear();
            }),
          ),
        ],
      ),
      body: workspace == null
          ? _TerminalHint(message: context.l10n.selectWorkspaceForTerminal)
          : Stack(
              children: <Widget>[
                KeyboardListener(
                  focusNode: _focusNode,
                  autofocus: true,
                  onKeyEvent: _handleKeyEvent,
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _focusNode.requestFocus(),
                          child: _TerminalView(
                            buffer: _buffer,
                            scroll: _scroll,
                            cursorVisible: _cursorVisible,
                          ),
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
                // Sprint 2.3: Scroll-to-bottom FAB.
                if (!_isAtBottom)
                  Positioned(
                    right: 16,
                    bottom: 72,
                    child: FloatingActionButton.small(
                      onPressed: _jumpToBottom,
                      tooltip: context.l10n.scrollToBottom,
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
              ],
            ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

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

/// Renders the [TerminalBuffer] using batched [TextSpan]s via
/// [TerminalRow.buildSpans], with unified scrollback + grid rendering.
class _TerminalView extends StatelessWidget {
  const _TerminalView({
    required this.buffer,
    required this.scroll,
    required this.cursorVisible,
  });

  final TerminalBuffer buffer;
  final ScrollController scroll;
  final bool cursorVisible;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final defaultFg = scheme.onSurface;
    final defaultBg = scheme.surfaceContainerLowest;
    final totalRows = buffer.scrollback.length + buffer.rows;

    return Container(
      color: defaultBg,
      child: ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: totalRows,
        itemBuilder: (BuildContext context, int i) {
          final isScrollback = i < buffer.scrollback.length;
          final row = isScrollback
              ? buffer.scrollback[i]
              : buffer.grid[i - buffer.scrollback.length];
          final gridIndex = isScrollback ? -1 : i - buffer.scrollback.length;

          return RichText(
            text: TextSpan(
              children: row.buildSpans(
                AppTheme.code,
                defaultFg,
                defaultBg,
                isCursorRow: gridIndex == buffer.cursorRow,
                cursorCol: buffer.cursorCol,
                cursorVisible: cursorVisible,
              ),
            ),
          );
        },
      ),
    );
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
