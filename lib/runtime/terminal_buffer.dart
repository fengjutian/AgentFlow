/// Terminal buffer — a grid of character cells with ANSI attributes.
///
/// Maintains a 2D grid that represents the current screen state. The [AnsiParser]
/// interprets escape sequences from a shell session and updates cursor position,
/// text content, and text attributes. The [TerminalView] widget reads this
/// buffer to render the screen.
library;

import 'dart:ui';

import 'package:flutter/painting.dart' show TextSpan, TextStyle;

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

  /// Builds a list of [TextSpan]s by merging consecutive cells that share the
  /// same visual attributes. This dramatically reduces the number of spans
  /// compared to rendering one span per cell (typically 5-10 vs 80 per row).
  ///
  /// [base] is the monospaced [TextStyle] for the terminal font.
  /// [defaultFg] and [defaultBg] are the fallback colours when a cell has no
  /// explicit attribute set. When [isCursorRow] is true the cell at
  /// [cursorCol] is rendered with inverted colours (block cursor) and the
  /// [cursorVisible] flag controls whether the inversion is applied.
  ///
  /// When [selectionStart] and [selectionEnd] are provided, cells within
  /// that column range receive a highlight background.
  List<TextSpan> buildSpans(
    TextStyle base,
    Color defaultFg,
    Color defaultBg, {
    bool isCursorRow = false,
    int cursorCol = -1,
    bool cursorVisible = true,
    int? selectionStart,
    int? selectionEnd,
  }) {
    _ensureSize();
    final spans = <TextSpan>[];
    var runStart = 0;

    for (var col = 0; col <= cols; col++) {
      if (col == cols) {
        // Flush the final run.
        if (runStart < cols) {
          spans.add(_buildSpan(runStart, col, base, defaultFg, defaultBg,
              isCursorRow: isCursorRow, cursorCol: cursorCol,
              cursorVisible: cursorVisible,
              selectionStart: selectionStart, selectionEnd: selectionEnd));
        }
        break;
      }

      // Check if this cell breaks the current run.
      if (col > runStart && _cellBreaksRun(col, runStart, isCursorRow,
          cursorCol, cursorVisible, selectionStart, selectionEnd)) {
        spans.add(_buildSpan(runStart, col, base, defaultFg, defaultBg,
            isCursorRow: isCursorRow, cursorCol: cursorCol,
            cursorVisible: cursorVisible,
            selectionStart: selectionStart, selectionEnd: selectionEnd));
        runStart = col;
      }
    }
    return spans;
  }

  /// Returns true if cell [col] has different visual attributes from the
  /// cell at [runStart], meaning a new span must begin.
  bool _cellBreaksRun(int col, int runStart, bool isCursorRow, int cursorCol,
      bool cursorVisible, int? selStart, int? selEnd) {
    final a = _cells[col].attributes;
    final b = _cells[runStart].attributes;

    // Cursor cell always breaks the run so it can be styled independently.
    if (isCursorRow && cursorVisible) {
      if (col == cursorCol || runStart == cursorCol) return true;
    }

    // Selection boundary breaks the run.
    if (selStart != null && selEnd != null) {
      final inSelA = col >= selStart && col <= selEnd;
      final inSelB = runStart >= selStart && runStart <= selEnd;
      if (inSelA != inSelB) return true;
    }

    return a.foreground != b.foreground ||
        a.background != b.background ||
        a.bold != b.bold ||
        a.italic != b.italic ||
        a.underline != b.underline ||
        a.inverse != b.inverse;
  }

  TextSpan _buildSpan(int from, int to, TextStyle base, Color defaultFg,
      Color defaultBg, {
    required bool isCursorRow,
    required int cursorCol,
    required bool cursorVisible,
    int? selectionStart,
    int? selectionEnd,
  }) {
    final buf = StringBuffer();
    for (var i = from; i < to; i++) {
      buf.write(_cells[i].char);
    }

    // Use the attributes of the first cell in the run.
    final attrs = _cells[from].attributes;
    Color fg = attrs.foreground ?? defaultFg;
    Color bg = attrs.background ?? defaultBg;

    // Apply cursor inversion.
    if (isCursorRow && cursorVisible && from <= cursorCol && cursorCol < to) {
      final tmp = fg;
      fg = bg;
      bg = tmp;
    }

    // Apply inverse attribute.
    if (attrs.inverse) {
      final tmp = fg;
      fg = bg;
      bg = tmp;
    }

    // Apply selection highlight.
    if (selectionStart != null && selectionEnd != null &&
        from <= selectionEnd && selectionStart < to) {
      bg = const Color(0xFF4488FF).withAlpha(100);
    }

    return TextSpan(
      text: buf.toString(),
      style: base.copyWith(
        color: fg,
        backgroundColor: bg,
        fontWeight: attrs.bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: attrs.italic ? FontStyle.italic : FontStyle.normal,
        decoration: attrs.underline ? TextDecoration.underline : TextDecoration.none,
      ),
    );
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

/// A range of selected cells in the terminal, expressed as absolute row indices
/// (scrollback + grid). [startRow] is always <= [endRow].
class TerminalSelection {
  const TerminalSelection({
    required this.startRow,
    required this.startCol,
    required this.endRow,
    required this.endCol,
  });

  final int startRow;
  final int startCol;
  final int endRow;
  final int endCol;

  /// Returns true if [row]/[col] falls within this selection.
  bool contains(int row, int col) {
    if (row < startRow || row > endRow) return false;
    if (row == startRow && col < startCol) return false;
    if (row == endRow && col > endCol) return false;
    return true;
  }

  /// Normalised copy: ensures start <= end.
  TerminalSelection get normalised {
    if (startRow < endRow || (startRow == endRow && startCol <= endCol)) {
      return this;
    }
    return TerminalSelection(
      startRow: endRow,
      startCol: endCol,
      endRow: startRow,
      endCol: startCol,
    );
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

  // Saved cursor position for \e7/\e8 and \e[s/\e[u.
  int _savedCursorRow = 0;
  int _savedCursorCol = 0;

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
      case AnsiSaveCursor():
        _savedCursorRow = cursorRow;
        _savedCursorCol = cursorCol;
      case AnsiRestoreCursor():
        cursorRow = _savedCursorRow.clamp(0, rows - 1);
        cursorCol = _savedCursorCol.clamp(0, cols - 1);
      case AnsiInsertLines(:final count):
        _insertLines(cursorRow, count);
      case AnsiDeleteLines(:final count):
        _deleteLines(cursorRow, count);
      case AnsiInsertChars(:final count):
        _insertChars(cursorRow, cursorCol, count);
      case AnsiDeleteChars(:final count):
        _deleteChars(cursorRow, cursorCol, count);
      case AnsiScrollRegion():
        // Scroll region is parsed but not yet used for scroll operations.
        // Future: restrict scroll up/down to the specified region.
        break;
      case AnsiScrollUp(:final count):
        for (var i = 0; i < count; i++) {
          _scrollUp();
        }
      case AnsiScrollDown(:final count):
        for (var i = 0; i < count; i++) {
          _scrollDown();
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

  // --- Sprint 6: Line/char insert/delete helpers ---

  void _insertLines(int atRow, int count) {
    for (var i = 0; i < count && atRow < rows; i++) {
      _grid.insert(atRow, TerminalRow(cols));
      if (_grid.length > rows) {
        _grid.removeLast();
      }
    }
  }

  void _deleteLines(int atRow, int count) {
    for (var i = 0; i < count && atRow < _grid.length; i++) {
      _grid.removeAt(atRow);
      _grid.add(TerminalRow(cols));
    }
  }

  void _insertChars(int row, int atCol, int count) {
    if (row >= rows) return;
    final r = _grid[row];
    for (var i = 0; i < count; i++) {
      if (atCol < cols) {
        // Shift cells right.
        for (var c = cols - 1; c > atCol; c--) {
          final src = r.cellAt(c - 1);
          r.setChar(c, src.char, src.attributes);
        }
        r.setChar(atCol, ' ', TerminalAttributes.defaultAttributes);
      }
    }
  }

  void _deleteChars(int row, int atCol, int count) {
    if (row >= rows) return;
    final r = _grid[row];
    for (var i = 0; i < count; i++) {
      if (atCol < cols) {
        // Shift cells left.
        for (var c = atCol; c < cols - 1; c++) {
          final src = r.cellAt(c + 1);
          r.setChar(c, src.char, src.attributes);
        }
        r.setChar(cols - 1, ' ', TerminalAttributes.defaultAttributes);
      }
    }
  }

  void _scrollUp() {
    if (scrollback.length >= maxScrollback) {
      scrollback.removeAt(0);
    }
    scrollback.add(_grid.removeAt(0));
    _grid.add(TerminalRow(cols));
  }

  void _scrollDown() {
    if (_grid.isNotEmpty) {
      _grid.removeLast();
      _grid.insert(0, TerminalRow(cols));
    }
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

  /// Extracts the text content of the given [selection] from scrollback + grid.
  /// Rows are indexed as: scrollback rows first, then grid rows.
  String selectedText(TerminalSelection sel) {
    final s = sel.normalised;
    final buf = StringBuffer();
    for (var row = s.startRow; row <= s.endRow; row++) {
      final r = _rowAtIndex(row);
      if (r == null) continue;
      final startCol = (row == s.startRow) ? s.startCol : 0;
      final endCol = (row == s.endRow) ? s.endCol : cols - 1;
      for (var col = startCol; col <= endCol && col < cols; col++) {
        buf.write(r.cellAt(col).char);
      }
      if (row < s.endRow) buf.write('\n');
    }
    return buf.toString().trimRight();
  }

  /// Returns the [TerminalRow] at the given absolute row index (scrollback + grid).
  TerminalRow? rowAtIndex(int absoluteRow) {
    if (absoluteRow < scrollback.length) return scrollback[absoluteRow];
    final gridIndex = absoluteRow - scrollback.length;
    if (gridIndex >= 0 && gridIndex < _grid.length) return _grid[gridIndex];
    return null;
  }

  TerminalRow? _rowAtIndex(int absoluteRow) => rowAtIndex(absoluteRow);

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
