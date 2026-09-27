import 'package:agentflow/core/editor/editor_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finds literal matches case-insensitively by default', () {
    final matches = findEditorMatches('One one (one)', 'one');

    expect(matches.map((match) => match.start), <int>[0, 4, 9]);
    expect(matches.map((match) => match.end), <int>[3, 7, 12]);
  });

  test('find treats regular expression characters literally', () {
    final matches = findEditorMatches('a.b ab a.b', 'a.b');
    expect(matches.map((match) => match.start), <int>[0, 7]);
  });

  test('next match wraps in both directions', () {
    final matches = findEditorMatches('x x x', 'x');

    expect(nextEditorMatchIndex(matches, 1), 1);
    expect(nextEditorMatchIndex(matches, 5), 0);
    expect(nextEditorMatchIndex(matches, 4, backwards: true), 1);
    expect(nextEditorMatchIndex(matches, 0, backwards: true), 2);
  });

  test('resolves one-based line numbers to offsets', () {
    const text = 'first\nsecond\nthird';
    expect(offsetForEditorLine(text, 1), 0);
    expect(offsetForEditorLine(text, 2), 6);
    expect(offsetForEditorLine(text, 3), 13);
    expect(offsetForEditorLine(text, 4), isNull);
    expect(offsetForEditorLine(text, 0), isNull);
  });

  test('replaces all literal matches', () {
    expect(replaceAllEditorMatches('Foo f.o foo', 'foo', 'bar'), 'bar f.o bar');
  });
}
