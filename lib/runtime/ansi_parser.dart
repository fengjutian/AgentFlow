/// Basic ANSI escape sequence parser for terminal rendering.
///
/// Parses a subset of ANSI escape sequences commonly used by shells and
/// terminal applications: SGR (Select Graphic Rendition) for colors and text
/// attributes, cursor movement, and screen clearing. The parser is designed
/// to be fed chunks of output as they arrive from a [ShellSession].
///
/// Supported sequences:
/// - SGR: `\e[<params>m` — foreground/background colors (8/16/256), bold, italic,
///   underline, reverse video, reset
/// - Cursor movement: `\e[<n>A/B/C/D` — up/down/forward/back
/// - Cursor position: `\e[<row>;<col>H` or `\e[<row>;<col>f`
/// - Erase: `\e[<n>J` (clear screen), `\e[<n>K` (clear line)
/// - Save/restore cursor: `\e7` / `\e8`
///
/// Unsupported sequences are silently discarded.
library;

/// A parsed ANSI escape sequence.
sealed class AnsiSequence {
  const AnsiSequence();
}

/// Reset all attributes to default.
class AnsiReset extends AnsiSequence {
  const AnsiReset();
}

/// SGR — set foreground/background color or text attribute.
class AnsiSgr extends AnsiSequence {
  const AnsiSgr(this.params);
  final List<int> params;
}

/// Cursor movement: up, down, forward, back.
class AnsiCursorMove extends AnsiSequence {
  const AnsiCursorMove(this.direction, this.count);
  final CursorDirection direction;
  final int count;
}

enum CursorDirection { up, down, forward, back }

/// Absolute cursor position (1-based row/col).
class AnsiCursorPosition extends AnsiSequence {
  const AnsiCursorPosition(this.row, this.col);
  final int row;
  final int col;
}

/// Erase in display or line.
class AnsiErase extends AnsiSequence {
  const AnsiErase(this.type, this.mode);
  final EraseType type;
  final int mode; // 0=to end, 1=to start, 2=entire
}

enum EraseType { display, line }

/// Plain text between escape sequences.
class AnsiText extends AnsiSequence {
  const AnsiText(this.text);
  final String text;
}

/// Stateful ANSI parser that accumulates partial escape sequences across
/// chunks. Feed output via [feed] and receive parsed sequences.
class AnsiParser {
  final StringBuffer _buffer = StringBuffer();
  _ParserState _state = _ParserState.text;

  /// Parses [chunk] and emits a list of [AnsiSequence]s.
  List<AnsiSequence> feed(String chunk) {
    final results = <AnsiSequence>[];
    for (var i = 0; i < chunk.length; i++) {
      final ch = chunk[i];
      switch (_state) {
        case _ParserState.text:
          if (ch == '\x1b') {
            _flushText(results);
            _state = _ParserState.escape;
          } else {
            _buffer.write(ch);
          }
        case _ParserState.escape:
          if (ch == '[') {
            _state = _ParserState.csi;
            _buffer.clear();
          } else if (ch == '7') {
            // Save cursor — not implemented, discard.
            _state = _ParserState.text;
          } else if (ch == '8') {
            // Restore cursor — not implemented, discard.
            _state = _ParserState.text;
          } else {
            // Unknown escape — discard.
            _state = _ParserState.text;
          }
        case _ParserState.csi:
          if (ch == 'm') {
            results.add(_parseSgr());
            _state = _ParserState.text;
          } else if ('ABCD'.contains(ch)) {
            final dir = switch (ch) {
              'A' => CursorDirection.up,
              'B' => CursorDirection.down,
              'C' => CursorDirection.forward,
              _ => CursorDirection.back,
            };
            final n = _parseInts().firstOrNull ?? 1;
            results.add(AnsiCursorMove(dir, n));
            _state = _ParserState.text;
          } else if (ch == 'H' || ch == 'f') {
            final parts = _parseInts();
            results.add(AnsiCursorPosition(
              parts.isNotEmpty ? parts[0] : 1,
              parts.length > 1 ? parts[1] : 1,
            ));
            _state = _ParserState.text;
          } else if (ch == 'J') {
            results.add(AnsiErase(EraseType.display, _parseInts().firstOrNull ?? 0));
            _state = _ParserState.text;
          } else if (ch == 'K') {
            results.add(AnsiErase(EraseType.line, _parseInts().firstOrNull ?? 0));
            _state = _ParserState.text;
          } else if (_isCsiParamChar(ch)) {
            _buffer.write(ch);
          } else {
            // Unknown CSI final — discard.
            _state = _ParserState.text;
          }
      }
    }
    _flushText(results);
    return results;
  }

  void _flushText(List<AnsiSequence> results) {
    if (_state == _ParserState.text && _buffer.isNotEmpty) {
      results.add(AnsiText(_buffer.toString()));
      _buffer.clear();
    }
  }

  AnsiSgr _parseSgr() {
    return AnsiSgr(_parseInts());
  }

  List<int> _parseInts() {
    final raw = _buffer.toString().trim();
    _buffer.clear();
    if (raw.isEmpty) return <int>[];
    return raw.split(';').map((String s) => int.tryParse(s) ?? 0).toList();
  }

  static bool _isCsiParamChar(String ch) {
    final code = ch.codeUnitAt(0);
    return (code >= 0x30 && code <= 0x3F); // '0'-'9', ';', '?', etc.
  }
}

enum _ParserState { text, escape, csi }
