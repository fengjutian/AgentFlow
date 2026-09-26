import 'package:agentflow/core/diff/line_diff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeLineDiff', () {
    test('classifies context, removed and added lines', () {
      final diff = computeLineDiff('a\nb\nc', 'a\nB\nc');
      expect(
        diff.map((DiffLine l) => l.type).toList(),
        <DiffLineType>[
          DiffLineType.context,
          DiffLineType.removed,
          DiffLineType.added,
          DiffLineType.context,
        ],
      );
      expect(diff.map((DiffLine l) => l.content).toList(),
          <String>['a', 'b', 'B', 'c']);
    });

    test('identical text yields only context lines', () {
      final diff = computeLineDiff('x\ny', 'x\ny');
      expect(diff.length, 2);
      expect(diff.every((DiffLine l) => l.type == DiffLineType.context), isTrue);
    });

    test('empty old text is all additions', () {
      final diff = computeLineDiff('', 'one\ntwo');
      expect(diff.length, 2);
      expect(diff.every((DiffLine l) => l.type == DiffLineType.added), isTrue);
    });

    test('a trailing newline does not create a phantom empty line', () {
      final diff = computeLineDiff('a\n', 'a\n');
      expect(diff.length, 1);
      expect(diff.single.content, 'a');
    });

    test('assigns 1-based line numbers per side', () {
      final diff = computeLineDiff('a\nb', 'a\nc');
      final context = diff.firstWhere((DiffLine l) => l.content == 'a');
      expect(context.oldNumber, 1);
      expect(context.newNumber, 1);
      final removed = diff.firstWhere((DiffLine l) => l.type == DiffLineType.removed);
      expect(removed.oldNumber, 2);
      expect(removed.newNumber, isNull);
    });
  });

  group('buildFileDiff', () {
    test('detects a new file', () {
      final d = buildFileDiff(path: 'a.txt', oldText: '', newText: 'hi');
      expect(d.isNewFile, isTrue);
      expect(d.addedCount, 1);
      expect(d.removedCount, 0);
    });

    test('detects a deletion', () {
      final d = buildFileDiff(path: 'a.txt', oldText: 'hi', newText: '');
      expect(d.isDeleted, isTrue);
      expect(d.removedCount, 1);
      expect(d.addedCount, 0);
    });

    test('reports no change as empty', () {
      final d = buildFileDiff(path: 'a.txt', oldText: 'same', newText: 'same');
      expect(d.isEmpty, isTrue);
    });

    test('summary and JSON round-trip preserve counts', () {
      final d = buildFileDiff(path: 'f.dart', oldText: 'a\nb', newText: 'a\nc');
      expect(d.summary, '+1 \u22121');
      final round = FileDiff.fromJson(d.toJson());
      expect(round.path, d.path);
      expect(round.addedCount, d.addedCount);
      expect(round.removedCount, d.removedCount);
      expect(round.lines.length, d.lines.length);
    });

    test('unified patch renders headers and prefixes', () {
      final d = buildFileDiff(path: 'f.txt', oldText: 'a', newText: 'b');
      final patch = d.toUnifiedPatch();
      expect(patch, contains('--- a/f.txt'));
      expect(patch, contains('+++ b/f.txt'));
      expect(patch, contains('-a'));
      expect(patch, contains('+b'));
    });
  });
}
