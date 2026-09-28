import 'dart:ui';

import 'package:agentflow/runtime/ansi_parser.dart';
import 'package:agentflow/runtime/terminal_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnsiParser', () {
    test('parses plain text', () {
      final parser = AnsiParser();
      final seqs = parser.feed('hello world');
      expect(seqs, hasLength(1));
      expect(seqs.first, isA<AnsiText>());
      expect((seqs.first as AnsiText).text, 'hello world');
    });

    test('parses SGR color codes', () {
      final parser = AnsiParser();
      final seqs = parser.feed('\x1b[31mred\x1b[0m');
      expect(seqs, hasLength(3));
      expect(seqs[0], isA<AnsiSgr>());
      expect((seqs[0] as AnsiSgr).params, [31]);
      expect(seqs[1], isA<AnsiText>());
      expect((seqs[1] as AnsiText).text, 'red');
      expect(seqs[2], isA<AnsiSgr>());
      expect((seqs[2] as AnsiSgr).params, [0]);
    });

    test('parses cursor movement', () {
      final parser = AnsiParser();
      final seqs = parser.feed('\x1b[5A');
      expect(seqs, hasLength(1));
      expect(seqs.first, isA<AnsiCursorMove>());
      final move = seqs.first as AnsiCursorMove;
      expect(move.direction, CursorDirection.up);
      expect(move.count, 5);
    });

    test('parses cursor position', () {
      final parser = AnsiParser();
      final seqs = parser.feed('\x1b[10;20H');
      expect(seqs, hasLength(1));
      expect(seqs.first, isA<AnsiCursorPosition>());
      final pos = seqs.first as AnsiCursorPosition;
      expect(pos.row, 10);
      expect(pos.col, 20);
    });

    test('parses erase display', () {
      final parser = AnsiParser();
      final seqs = parser.feed('\x1b[2J');
      expect(seqs, hasLength(1));
      expect(seqs.first, isA<AnsiErase>());
      final erase = seqs.first as AnsiErase;
      expect(erase.type, EraseType.display);
      expect(erase.mode, 2);
    });

    test('handles partial escape sequences across chunks', () {
      final parser = AnsiParser();
      final seqs1 = parser.feed('hello\x1b');
      expect(seqs1, hasLength(1));
      expect((seqs1.first as AnsiText).text, 'hello');

      final seqs2 = parser.feed('[31mworld');
      expect(seqs2, hasLength(2));
      expect(seqs2[0], isA<AnsiSgr>());
      expect((seqs2[1] as AnsiText).text, 'world');
    });

    test('parses 256-color SGR', () {
      final parser = AnsiParser();
      final seqs = parser.feed('\x1b[38;5;196m');
      expect(seqs, hasLength(1));
      expect(seqs.first, isA<AnsiSgr>());
      expect((seqs.first as AnsiSgr).params, [38, 5, 196]);
    });
  });

  group('TerminalBuffer', () {
    test('places characters at cursor position', () {
      final buffer = TerminalBuffer(rows: 5, cols: 20);
      buffer.feed('hello');
      expect(buffer.grid[0].text, 'hello');
      expect(buffer.cursorRow, 0);
      expect(buffer.cursorCol, 5);
    });

    test('wraps to next line when reaching end of row', () {
      final buffer = TerminalBuffer(rows: 5, cols: 5);
      buffer.feed('abcdefgh');
      expect(buffer.grid[0].text, 'abcde');
      expect(buffer.grid[1].text, 'fgh');
      expect(buffer.cursorRow, 1);
      expect(buffer.cursorCol, 3);
    });

    test('handles newlines', () {
      final buffer = TerminalBuffer(rows: 5, cols: 20);
      buffer.feed('line1\nline2');
      expect(buffer.grid[0].text, 'line1');
      expect(buffer.grid[1].text, 'line2');
    });

    test('scrolls when exceeding buffer rows', () {
      final buffer = TerminalBuffer(rows: 3, cols: 20);
      buffer.feed('a\nb\nc\nd\ne');
      // 'a' and 'b' should have scrolled into scrollback.
      expect(buffer.scrollback, hasLength(2));
      expect(buffer.scrollback[0].text, 'a');
      expect(buffer.scrollback[1].text, 'b');
      expect(buffer.grid[0].text, 'c');
      expect(buffer.grid[1].text, 'd');
      expect(buffer.grid[2].text, 'e');
    });

    test('applies SGR color attributes', () {
      final buffer = TerminalBuffer(rows: 3, cols: 20);
      buffer.feed('\x1b[31mred\x1b[0m');
      final cell = buffer.grid[0].cellAt(0);
      expect(cell.char, 'r');
      expect(cell.attributes.foreground, isNotNull);
    });

    test('handles cursor movement', () {
      final buffer = TerminalBuffer(rows: 5, cols: 20);
      buffer.feed('hello');
      buffer.feed('\x1b[3D'); // move back 3
      expect(buffer.cursorCol, 2);
      buffer.feed('X');
      expect(buffer.grid[0].text, 'heXlo');
    });

    test('handles cursor position (absolute)', () {
      final buffer = TerminalBuffer(rows: 10, cols: 40);
      buffer.feed('\x1b[5;10H');
      expect(buffer.cursorRow, 4); // 1-based to 0-based
      expect(buffer.cursorCol, 9);
      buffer.feed('X');
      expect(buffer.grid[4].cellAt(9).char, 'X');
      expect(buffer.cursorCol, 10); // cursor advances after placing char
    });

    test('handles erase display (mode 2 = clear all)', () {
      final buffer = TerminalBuffer(rows: 5, cols: 20);
      buffer.feed('hello\nworld');
      buffer.feed('\x1b[2J');
      expect(buffer.grid[0].text, '');
      expect(buffer.grid[1].text, '');
    });

    test('handles erase line (mode 0 = to end)', () {
      final buffer = TerminalBuffer(rows: 5, cols: 20);
      buffer.feed('hello world');
      buffer.feed('\x1b[1;6H'); // move to row 1, col 6
      buffer.feed('\x1b[K'); // erase to end of line
      expect(buffer.grid[0].text, 'hello');
    });

    test('resize preserves content', () {
      final buffer = TerminalBuffer(rows: 5, cols: 20);
      buffer.feed('hello\nworld');
      buffer.resize(5, 10);
      expect(buffer.grid[0].text, 'hello');
      expect(buffer.grid[1].text, 'world');
    });

    test('handles carriage return', () {
      final buffer = TerminalBuffer(rows: 5, cols: 20);
      buffer.feed('hello\rX');
      expect(buffer.grid[0].text, 'Xello');
    });

    test('handles tab character', () {
      final buffer = TerminalBuffer(rows: 5, cols: 40);
      buffer.feed('a\tb');
      // Tab should advance to next 8-column stop.
      expect(buffer.cursorCol, 9);
    });
  });
}
