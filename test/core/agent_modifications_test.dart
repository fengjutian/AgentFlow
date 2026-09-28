import 'package:agentflow/core/editor/agent_modifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentModificationStore', () {
    test('record adds a range', () {
      final store = AgentModificationStore();
      store.record(path: 'lib/main.dart', startLine: 10, endLine: 20);

      final ranges = store.rangesFor('lib/main.dart');
      expect(ranges, hasLength(1));
      expect(ranges.first.startLine, 10);
      expect(ranges.first.endLine, 20);
    });

    test('recordLines groups consecutive lines into ranges', () {
      final store = AgentModificationStore();
      store.recordLines(path: 'lib/main.dart', lines: [1, 2, 3, 5, 6, 10]);

      final ranges = store.rangesFor('lib/main.dart');
      expect(ranges, hasLength(3));
      expect(ranges[0].startLine, 1);
      expect(ranges[0].endLine, 3);
      expect(ranges[1].startLine, 5);
      expect(ranges[1].endLine, 6);
      expect(ranges[2].startLine, 10);
      expect(ranges[2].endLine, 10);
    });

    test('rangesFor returns empty list for unknown path', () {
      final store = AgentModificationStore();
      store.record(path: 'lib/main.dart', startLine: 1, endLine: 5);

      expect(store.rangesFor('lib/other.dart'), isEmpty);
    });

    test('rangesFor handles path normalization', () {
      final store = AgentModificationStore();
      store.record(path: 'lib/main.dart', startLine: 1, endLine: 5);

      // Should find with backslash path.
      final ranges = store.rangesFor('lib\\main.dart');
      expect(ranges, hasLength(1));
    });

    test('clearFor removes ranges for specific path', () {
      final store = AgentModificationStore();
      store.record(path: 'lib/main.dart', startLine: 1, endLine: 5);
      store.record(path: 'lib/other.dart', startLine: 10, endLine: 15);

      store.clearFor('lib/main.dart');

      expect(store.rangesFor('lib/main.dart'), isEmpty);
      expect(store.rangesFor('lib/other.dart'), hasLength(1));
    });

    test('clearAll removes all ranges', () {
      final store = AgentModificationStore();
      store.record(path: 'lib/main.dart', startLine: 1, endLine: 5);
      store.record(path: 'lib/other.dart', startLine: 10, endLine: 15);

      store.clearAll();

      expect(store.ranges, isEmpty);
    });

    test('expired ranges are pruned', () {
      // Use a very short expiry for testing.
      final store = AgentModificationStore(
        expiryDuration: const Duration(milliseconds: 1),
      );
      store.record(path: 'lib/main.dart', startLine: 1, endLine: 5);

      // Wait for expiry.
      return Future<void>.delayed(const Duration(milliseconds: 10), () {
        expect(store.rangesFor('lib/main.dart'), isEmpty);
      });
    });

    test('recordLines with empty list does nothing', () {
      final store = AgentModificationStore();
      store.recordLines(path: 'lib/main.dart', lines: []);

      expect(store.ranges, isEmpty);
    });

    test('notifyListeners is called on record', () {
      final store = AgentModificationStore();
      var notified = 0;
      store.addListener(() => notified++);

      store.record(path: 'lib/main.dart', startLine: 1, endLine: 5);

      expect(notified, 1);
    });

    test('notifyListeners is called on clearFor', () {
      final store = AgentModificationStore();
      store.record(path: 'lib/main.dart', startLine: 1, endLine: 5);

      var notified = 0;
      store.addListener(() => notified++);

      store.clearFor('lib/main.dart');

      expect(notified, 1);
    });

    test('notifyListeners is not called when clearing empty path', () {
      final store = AgentModificationStore();

      var notified = 0;
      store.addListener(() => notified++);

      store.clearFor('lib/nonexistent.dart');

      expect(notified, 0);
    });
  });

  group('AgentModifiedRange', () {
    test('isOlderThan returns false for fresh range', () {
      final range = AgentModifiedRange(
        path: 'lib/main.dart',
        startLine: 1,
        endLine: 5,
        timestamp: DateTime.now(),
      );

      expect(range.isOlderThan(const Duration(minutes: 30)), isFalse);
    });

    test('isOlderThan returns true for old range', () {
      final range = AgentModifiedRange(
        path: 'lib/main.dart',
        startLine: 1,
        endLine: 5,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(range.isOlderThan(const Duration(minutes: 30)), isTrue);
    });
  });
}
