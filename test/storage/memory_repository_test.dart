import 'package:agentflow/core/memory/memory_manager.dart';
import 'package:agentflow/storage/database.dart';
import 'package:agentflow/storage/repositories.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftMemoryStore store;

  setUp(() {
    db = AppDatabase.connect(NativeDatabase.memory());
    store = DriftMemoryStore(db);
  });

  tearDown(() => db.close());

  group('DriftMemoryStore', () {
    test('load returns empty list for new workspace', () async {
      final entries = await store.load('ws1');
      expect(entries, isEmpty);
    });

    test('save and load persists a memory entry', () async {
      final entry = MemoryEntry(
        id: 'mem1',
        content: 'Remember this fact',
        createdAt: DateTime.utc(2026, 1, 15),
        tags: ['fact', 'important'],
      );

      await store.save('ws1', entry);

      final loaded = await store.load('ws1');
      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'mem1');
      expect(loaded.first.content, 'Remember this fact');
      // SQLite stores DateTime as epoch seconds, so compare by milliseconds
      expect(
        loaded.first.createdAt.millisecondsSinceEpoch,
        DateTime.utc(2026, 1, 15).millisecondsSinceEpoch,
      );
      expect(loaded.first.tags, ['fact', 'important']);
    });

    test('save replaces existing entry with same id', () async {
      final entry1 = MemoryEntry(
        id: 'mem1',
        content: 'Original content',
        createdAt: DateTime.utc(2026, 1, 15),
      );
      final entry2 = MemoryEntry(
        id: 'mem1',
        content: 'Updated content',
        createdAt: DateTime.utc(2026, 1, 16),
        tags: ['updated'],
      );

      await store.save('ws1', entry1);
      await store.save('ws1', entry2);

      final loaded = await store.load('ws1');
      expect(loaded, hasLength(1));
      expect(loaded.first.content, 'Updated content');
      expect(loaded.first.tags, ['updated']);
    });

    test('load returns entries ordered by createdAt ascending', () async {
      await store.save('ws1', MemoryEntry(
        id: 'mem3',
        content: 'Third',
        createdAt: DateTime.utc(2026, 1, 17),
      ));
      await store.save('ws1', MemoryEntry(
        id: 'mem1',
        content: 'First',
        createdAt: DateTime.utc(2026, 1, 15),
      ));
      await store.save('ws1', MemoryEntry(
        id: 'mem2',
        content: 'Second',
        createdAt: DateTime.utc(2026, 1, 16),
      ));

      final loaded = await store.load('ws1');
      expect(loaded, hasLength(3));
      expect(loaded.map((e) => e.id).toList(), ['mem1', 'mem2', 'mem3']);
    });

    test('load isolates entries by workspace', () async {
      await store.save('ws1', MemoryEntry(
        id: 'mem1',
        content: 'WS1 entry',
        createdAt: DateTime.utc(2026, 1, 15),
      ));
      await store.save('ws2', MemoryEntry(
        id: 'mem2',
        content: 'WS2 entry',
        createdAt: DateTime.utc(2026, 1, 15),
      ));

      final ws1Entries = await store.load('ws1');
      final ws2Entries = await store.load('ws2');

      expect(ws1Entries, hasLength(1));
      expect(ws1Entries.first.content, 'WS1 entry');
      expect(ws2Entries, hasLength(1));
      expect(ws2Entries.first.content, 'WS2 entry');
    });

    test('delete removes a specific entry', () async {
      await store.save('ws1', MemoryEntry(
        id: 'mem1',
        content: 'First',
        createdAt: DateTime.utc(2026, 1, 15),
      ));
      await store.save('ws1', MemoryEntry(
        id: 'mem2',
        content: 'Second',
        createdAt: DateTime.utc(2026, 1, 16),
      ));

      await store.delete('ws1', 'mem1');

      final loaded = await store.load('ws1');
      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'mem2');
    });

    test('delete does not affect other workspaces', () async {
      await store.save('ws1', MemoryEntry(
        id: 'mem1',
        content: 'WS1 entry',
        createdAt: DateTime.utc(2026, 1, 15),
      ));
      await store.save('ws2', MemoryEntry(
        id: 'mem1',
        content: 'WS2 entry with same id',
        createdAt: DateTime.utc(2026, 1, 15),
      ));

      await store.delete('ws1', 'mem1');

      expect(await store.load('ws1'), isEmpty);
      expect(await store.load('ws2'), hasLength(1));
    });

    test('delete non-existent entry does not throw', () async {
      await store.save('ws1', MemoryEntry(
        id: 'mem1',
        content: 'Entry',
        createdAt: DateTime.utc(2026, 1, 15),
      ));

      // Should not throw
      await store.delete('ws1', 'nonexistent');

      expect(await store.load('ws1'), hasLength(1));
    });

    test('entry with empty tags persists correctly', () async {
      final entry = MemoryEntry(
        id: 'mem1',
        content: 'No tags',
        createdAt: DateTime.utc(2026, 1, 15),
      );

      await store.save('ws1', entry);

      final loaded = await store.load('ws1');
      expect(loaded.first.tags, isEmpty);
    });

    test('entry with many tags persists correctly', () async {
      final entry = MemoryEntry(
        id: 'mem1',
        content: 'Many tags',
        createdAt: DateTime.utc(2026, 1, 15),
        tags: ['tag1', 'tag2', 'tag3', 'tag4', 'tag5'],
      );

      await store.save('ws1', entry);

      final loaded = await store.load('ws1');
      expect(loaded.first.tags, hasLength(5));
      expect(loaded.first.tags, containsAll(['tag1', 'tag2', 'tag3', 'tag4', 'tag5']));
    });
  });
}
