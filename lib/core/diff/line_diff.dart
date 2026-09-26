/// Self-developed line diff (design doc §21, "自研 Diff UI").
///
/// Produces an LCS-based edit script between two versions of a file plus a
/// unified-patch rendering. The engine uses it to show what `write_file` will
/// change before applying it, and the Diff UI renders accept/reject from the same
/// [FileDiff] model.
library;

enum DiffLineType { context, added, removed }

/// One row of a diff, with optional 1-based line numbers in each version.
class DiffLine {
  const DiffLine({
    required this.type,
    required this.content,
    this.oldNumber,
    this.newNumber,
  });

  final DiffLineType type;
  final String content;
  final int? oldNumber;
  final int? newNumber;

  String get prefix => switch (type) {
        DiffLineType.added => '+',
        DiffLineType.removed => '-',
        DiffLineType.context => ' ',
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'content': content,
        'oldNumber': oldNumber,
        'newNumber': newNumber,
      };

  factory DiffLine.fromJson(Map<String, dynamic> json) => DiffLine(
        type: DiffLineType.values.firstWhere(
          (DiffLineType t) => t.name == json['type'],
          orElse: () => DiffLineType.context,
        ),
        content: (json['content'] ?? '') as String,
        oldNumber: (json['oldNumber'] as num?)?.toInt(),
        newNumber: (json['newNumber'] as num?)?.toInt(),
      );
}

/// A full file-level diff.
class FileDiff {
  const FileDiff({
    required this.path,
    required this.lines,
    this.isNewFile = false,
    this.isDeleted = false,
  });

  final String path;
  final List<DiffLine> lines;
  final bool isNewFile;
  final bool isDeleted;

  int get addedCount =>
      lines.where((DiffLine l) => l.type == DiffLineType.added).length;
  int get removedCount =>
      lines.where((DiffLine l) => l.type == DiffLineType.removed).length;

  bool get isEmpty => addedCount == 0 && removedCount == 0;

  /// GitHub-style "+N −M" summary.
  String get summary => '+$addedCount −$removedCount';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'path': path,
        'isNewFile': isNewFile,
        'isDeleted': isDeleted,
        'added': addedCount,
        'removed': removedCount,
        'lines': lines.map((DiffLine l) => l.toJson()).toList(),
      };

  factory FileDiff.fromJson(Map<String, dynamic> json) => FileDiff(
        path: (json['path'] ?? '') as String,
        isNewFile: (json['isNewFile'] ?? false) as bool,
        isDeleted: (json['isDeleted'] ?? false) as bool,
        lines: ((json['lines'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) =>
                DiffLine.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  /// Unified-diff rendering, suitable for a terminal or `git apply`.
  String toUnifiedPatch() {
    final buffer = StringBuffer();
    final headerOld = isNewFile ? '/dev/null' : 'a/$path';
    final headerNew = isDeleted ? '/dev/null' : 'b/$path';
    buffer
      ..writeln('--- $headerOld')
      ..writeln('+++ $headerNew');
    for (final line in lines) {
      buffer.writeln('${line.prefix}${line.content}');
    }
    return buffer.toString();
  }
}

/// Computes an LCS-based line diff between [oldText] and [newText].
List<DiffLine> computeLineDiff(String oldText, String newText) {
  final a = _splitLines(oldText);
  final b = _splitLines(newText);
  final n = a.length;
  final m = b.length;

  // lcs[i][j] = length of LCS of a[i:] and b[j:].
  final lcs = List<List<int>>.generate(
    n + 1,
    (_) => List<int>.filled(m + 1, 0),
  );
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      lcs[i][j] = a[i] == b[j]
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }

  final result = <DiffLine>[];
  var i = 0;
  var j = 0;
  var oldNo = 0;
  var newNo = 0;
  while (i < n && j < m) {
    if (a[i] == b[j]) {
      oldNo++;
      newNo++;
      result.add(DiffLine(
        type: DiffLineType.context,
        content: a[i],
        oldNumber: oldNo,
        newNumber: newNo,
      ));
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      oldNo++;
      result.add(DiffLine(
        type: DiffLineType.removed,
        content: a[i],
        oldNumber: oldNo,
      ));
      i++;
    } else {
      newNo++;
      result.add(DiffLine(
        type: DiffLineType.added,
        content: b[j],
        newNumber: newNo,
      ));
      j++;
    }
  }
  while (i < n) {
    oldNo++;
    result.add(DiffLine(
      type: DiffLineType.removed,
      content: a[i],
      oldNumber: oldNo,
    ));
    i++;
  }
  while (j < m) {
    newNo++;
    result.add(DiffLine(
      type: DiffLineType.added,
      content: b[j],
      newNumber: newNo,
    ));
    j++;
  }
  return result;
}

/// Builds a [FileDiff] for a file write, detecting new-file and delete cases.
FileDiff buildFileDiff({
  required String path,
  required String oldText,
  required String newText,
}) {
  final isNew = oldText.isEmpty && newText.isNotEmpty;
  final isDeleted = oldText.isNotEmpty && newText.isEmpty;
  return FileDiff(
    path: path,
    lines: computeLineDiff(oldText, newText),
    isNewFile: isNew,
    isDeleted: isDeleted,
  );
}

/// Splits text into lines without trailing empty artifacts, while preserving
/// genuinely blank lines in the middle.
List<String> _splitLines(String text) {
  if (text.isEmpty) return const <String>[];
  // Normalize CRLF, then split. A single trailing newline should not create a
  // phantom empty last line.
  final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final lines = normalized.split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines;
}

