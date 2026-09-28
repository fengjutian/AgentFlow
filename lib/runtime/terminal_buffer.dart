/// Terminal buffer — a grid of character cells with ANSI attributes.
///
/// Maintains a 2D grid that represents the current screen state. The [AnsiParser]
/// interprets escape sequences from a shell session and updates cursor position,
/// text content, and text attributes. The [TerminalView] widget reads this
/// buffer to render the screen.
library;

import 'dart:ui';

import 'ansi_parser.dart';

/// Text attributes applied to subsequent characters.
class TerminalAttributes {
  const TerminalAttributes({
    this.foreground,
    this.background,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.inverse = false,
  });

  final Color? foreground;
  final Color? background;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool inverse;

  static const TerminalAttributes defaultAttributes = TerminalAttributes();

  TerminalAttributes copyWith({
    Color? foreground,
    Color? background,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? inverse,
    bool reset = false,
  }) {
    if (reset) return const TerminalAttributes();
    return TerminalAttributes(
      foreground: foreground ?? this.foreground,
      background: background ?? this.background,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      inverse: inverse ?? this.inverse,
    );
  }
}

/// A single cell in the terminal grid.
class TerminalCell {
  TerminalCell({this.char = ' ', this.attributes = TerminalAttributes.defaultAttributes});

  String char;
  TerminalAttributes attributes;

  void reset() {
    char = ' ';
    attributes = TerminalAttributes.defaultAttributes;
  }
}

/// A row in the terminal grid.
class TerminalRow {
  TerminalRow(this.cols);

  final int cols;
  final List<TerminalCell> _cells = <TerminalCell>[];

  void _ensureSize() {
    while (_cells.length < cols) {
      _cells.add(TerminalCell());
    }
    if (_cells.length > cols) {
      _cells.removeRange(cols, _cells.length);
    }
  }

  TerminalCell cellAt(int col) {
    _ensureSize();
    return _cells[col.clamp(0, cols - 1)];
  }

  void setChar(int col, String ch, TerminalAttributes attrs) {
    _ensureSize();
    final c = col.clamp(0, cols - 1);
    _cells[c].char = ch;
    _cells[c].attributes = attrs;
  }

  void clearFrom(int col) {
    _ensureSize();
    for (var i = col.clamp(0, cols); i < cols; i++) {
      _cells[i].reset();
    }
  }

  void clearTo(int col) {
    _ensureSize();
    for (var i = 0; i <= col.clamp(0, cols - 1); i++) {
      _cells[i].reset();
    }
  }

  void clearAll() {
    _ensureSize();
    for (final cell in _cells) {
      cell.reset();
    }
  }

  /// Returns the text content of this row, trimming trailing spaces.
  String get text {
    _ensureSize();
    final buffer = StringBuffer();
    var lastNonSpace = -1;
    for (var i = 0; i < cols; i++) {
      if (_cells[i].char != ' ') lastNonSpace = i;
      buffer.write(_cells[i].char);
    }
    return lastNonSpace < 0 ? '' : buffer.toString().substring(0, lastNonSpace + 1);
  }

  void resize(int newCols) {
    if (newCols == cols) return;
    // Rebuild cells for new width.
    final oldCells = List<TerminalCell>.of(_cells);
    _cells.clear();
    for (var i = 0; i < newCols; i++) {
      _cells.add(i < oldCells.length ? oldCells[i] : TerminalCell());
    }
  }
}

/// The terminal screen state: a grid of [rows] x [cols] cells plus a cursor
/// position and current text attributes.
class TerminalBuffer {
  TerminalBuffer({this.rows = 24, this.cols = 80})
      : _grid = List<TerminalRow>.generate(rows, (_) => TerminalRow(cols));

  int rows;
  int cols;
  int cursorRow = 0;
  int cursorCol = 0;
  TerminalAttributes currentAttributes = TerminalAttributes.defaultAttributes;

  final List<TerminalRow> _grid;
  final AnsiParser _parser = AnsiParser();

  /// Scrollback lines that have scrolled off the top.
  final List<TerminalRow> scrollback = <TerminalRow>[];

  /// Maximum number of scrollback lines to retain.
  static const int maxScrollback = 10000;

  List<TerminalRow> get grid => _grid;

  /// Feeds raw output from the shell into the buffer, parsing ANSI sequences
  /// and updating the grid.
  void feed(String chunk) {
    final sequences = _parser.feed(chunk);
    for (final seq in sequences) {
      _apply(seq);
    }
  }

  void _apply(AnsiSequence seq) {
    switch (seq) {
      case AnsiText(:final text):
        for (var i = 0; i < text.length; i++) {
          final ch = text[i];
          if (ch == '\n') {
            _newline();
          } else if (ch == '\r') {
            cursorCol = 0;
          } else if (ch == '\b') {
            if (cursorCol > 0) cursorCol--;
          } else if (ch == '\t') {
            cursorCol = ((cursorCol ~/ 8) + 1) * 8;
            if (cursorCol >= cols) _newline();
          } else {
            _putChar(ch);
          }
        }
      case AnsiSgr(:final params):
        _applySgr(params);
      case AnsiReset():
        currentAttributes = TerminalAttributes.defaultAttributes;
      case AnsiCursorMove(:final direction, :final count):
        switch (direction) {
          case CursorDirection.up:
            cursorRow = (cursorRow - count).clamp(0, rows - 1);
          case CursorDirection.down:
            cursorRow = (cursorRow + count).clamp(0, rows - 1);
          case CursorDirection.forward:
            cursorCol = (cursorCol + count).clamp(0, cols - 1);
          case CursorDirection.back:
            cursorCol = (cursorCol - count).clamp(0, cols - 1);
        }
      case AnsiCursorPosition(:final row, :final col):
        cursorRow = (row - 1).clamp(0, rows - 1);
        cursorCol = (col - 1).clamp(0, cols - 1);
      case AnsiErase(:final type, :final mode):
        switch (type) {
          case EraseType.display:
            if (mode == 2) {
              for (final row in _grid) {
                row.clearAll();
              }
            } else if (mode == 0) {
              _grid[cursorRow].clearFrom(cursorCol);
              for (var i = cursorRow + 1; i < rows; i++) {
                _grid[i].clearAll();
              }
            } else if (mode == 1) {
              for (var i = 0; i < cursorRow; i++) {
                _grid[i].clearAll();
              }
              _grid[cursorRow].clearTo(cursorCol);
            }
          case EraseType.line:
            if (mode == 0) {
              _grid[cursorRow].clearFrom(cursorCol);
            } else if (mode == 1) {
              _grid[cursorRow].clearTo(cursorCol);
            } else if (mode == 2) {
              _grid[cursorRow].clearAll();
            }
        }
    }
  }

  void _putChar(String ch) {
    if (cursorCol >= cols) {
      _newline();
    }
    _grid[cursorRow].setChar(cursorCol, ch, currentAttributes);
    cursorCol++;
  }

  void _newline() {
    if (cursorRow < rows - 1) {
      cursorRow++;
    } else {
      // Scroll up: move top row to scrollback, shift rows up.
      if (scrollback.length >= maxScrollback) {
        scrollback.removeAt(0);
      }
      scrollback.add(_grid.removeAt(0));
      _grid.add(TerminalRow(cols));
    }
    cursorCol = 0;
  }

  void _applySgr(List<int> params) {
    if (params.isEmpty) {
      currentAttributes = TerminalAttributes.defaultAttributes;
      return;
    }
    var i = 0;
    while (i < params.length) {
      final p = params[i];
      switch (p) {
        case 0:
          currentAttributes = TerminalAttributes.defaultAttributes;
        case 1:
          currentAttributes = currentAttributes.copyWith(bold: true);
        case 3:
          currentAttributes = currentAttributes.copyWith(italic: true);
        case 4:
          currentAttributes = currentAttributes.copyWith(underline: true);
        case 7:
          currentAttributes = currentAttributes.copyWith(inverse: true);
        case 22:
          currentAttributes = currentAttributes.copyWith(bold: false);
        case 23:
          currentAttributes = currentAttributes.copyWith(italic: false);
        case 24:
          currentAttributes = currentAttributes.copyWith(underline: false);
        case 27:
          currentAttributes = currentAttributes.copyWith(inverse: false);
        case >= 30 && <= 37:
          currentAttributes = currentAttributes.copyWith(
            foreground: _ansi16Color(p - 30),
          );
        case 38:
          // 256-color or true-color foreground.
          if (i + 1 < params.length && params[i + 1] == 5 && i + 2 < params.length) {
            currentAttributes = currentAttributes.copyWith(
              foreground: _ansi256Color(params[i + 2]),
            );
            i += 2;
          } else if (i + 1 < params.length && params[i + 1] == 2 && i + 4 < params.length) {
            currentAttributes = currentAttributes.copyWith(
              foreground: Color.fromARGB(255, params[i + 2], params[i + 3], params[i + 4]),
            );
            i += 4;
          }
        case 39:
          currentAttributes = currentAttributes.copyWith(foreground: null);
        case >= 40 && <= 47:
          currentAttributes = currentAttributes.copyWith(
            background: _ansi16Color(p - 40),
          );
        case 48:
          if (i + 1 < params.length && params[i + 1] == 5 && i + 2 < params.length) {
            currentAttributes = currentAttributes.copyWith(
              background: _ansi256Color(params[i + 2]),
            );
            i += 2;
          } else if (i + 1 < params.length && params[i + 1] == 2 && i + 4 < params.length) {
            currentAttributes = currentAttributes.copyWith(
              background: Color.fromARGB(255, params[i + 2], params[i + 3], params[i + 4]),
            );
            i += 4;
          }
        case 49:
          currentAttributes = currentAttributes.copyWith(background: null);
        case >= 90 && <= 97:
          currentAttributes = currentAttributes.copyWith(
            foreground: _ansi16Color(p - 90 + 8),
          );
        case >= 100 && <= 107:
          currentAttributes = currentAttributes.copyWith(
            background: _ansi16Color(p - 100 + 8),
          );
      }
      i++;
    }
  }

  /// Resizes the terminal buffer. Content above the new row count is moved
  /// to scrollback; content is clipped or padded for width changes.
  void resize(int newRows, int newCols) {
    // Adjust column width.
    for (final row in _grid) {
      row.resize(newCols);
    }
    // Adjust row count.
    while (_grid.length > newRows) {
      if (scrollback.length >= maxScrollback) scrollback.removeAt(0);
      scrollback.add(_grid.removeAt(0));
    }
    while (_grid.length < newRows) {
      _grid.add(TerminalRow(newCols));
    }
    rows = newRows;
    cols = newCols;
    cursorRow = cursorRow.clamp(0, rows - 1);
    cursorCol = cursorCol.clamp(0, cols - 1);
  }

  /// Standard 16 ANSI colors.
  static Color _ansi16Color(int index) {
    const colors = <Color>[
      Color(0xFF000000), // black
      Color(0xFFCC0000), // red
      Color(0xFF00CC00), // green
      Color(0xFFCCCC00), // yellow
      Color(0xFF0000CC), // blue
      Color(0xFFCC00CC), // magenta
      Color(0xFF00CCCC), // cyan
      Color(0xFFCCCCCC), // white
      Color(0xFF666666), // bright black (gray)
      Color(0xFFFF0000), // bright red
      Color(0xFF00FF00), // bright green
      Color(0xFFFFFF00), // bright yellow
      Color(0xFF0000FF), // bright blue
      Color(0xFFFF00FF), // bright magenta
      Color(0xFF00FFFF), // bright cyan
      Color(0xFFFFFFFF), // bright white
    ];
    return colors[index.clamp(0, colors.length - 1)];
  }

  /// 256-color palette: 16 standard + 216 RGB cube + 24 grayscale.
  static Color _ansi256Color(int index) {
    if (index < 16) return _ansi16Color(index);
    if (index < 232) {
      final n = index - 16;
      final r = (n ~/ 36) * 51;
      final g = ((n % 36) ~/ 6) * 51;
      final b = (n % 6) * 51;
      return Color.fromARGB(255, r, g, b);
    }
    // Grayscale ramp.
    final v = 8 + (index - 232) * 10;
    return Color.fromARGB(255, v, v, v);
  }
}
