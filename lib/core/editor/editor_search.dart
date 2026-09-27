library;

class EditorMatch {
  const EditorMatch(this.start, this.end);

  final int start;
  final int end;
}

List<EditorMatch> findEditorMatches(
  String text,
  String query, {
  bool caseSensitive = false,
}) {
  if (query.isEmpty) return const <EditorMatch>[];
  final expression = RegExp(RegExp.escape(query), caseSensitive: caseSensitive);
  return expression
      .allMatches(text)
      .map((match) => EditorMatch(match.start, match.end))
      .toList(growable: false);
}

int nextEditorMatchIndex(
  List<EditorMatch> matches,
  int offset, {
  bool backwards = false,
}) {
  if (matches.isEmpty) return -1;
  if (backwards) {
    for (var index = matches.length - 1; index >= 0; index--) {
      if (matches[index].start < offset) return index;
    }
    return matches.length - 1;
  }
  final index = matches.indexWhere((match) => match.start >= offset);
  return index < 0 ? 0 : index;
}

int? offsetForEditorLine(String text, int line) {
  if (line < 1) return null;
  if (line == 1) return 0;
  var currentLine = 1;
  for (var index = 0; index < text.length; index++) {
    if (text.codeUnitAt(index) != 10) continue;
    currentLine++;
    if (currentLine == line) return index + 1;
  }
  return null;
}

String replaceAllEditorMatches(
  String text,
  String query,
  String replacement, {
  bool caseSensitive = false,
}) {
  if (query.isEmpty) return text;
  return text.replaceAll(
    RegExp(RegExp.escape(query), caseSensitive: caseSensitive),
    replacement,
  );
}
