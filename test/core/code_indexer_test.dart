import 'dart:io';

import 'package:agentflow/core/search/code_indexer.dart';
import 'package:agentflow/runtime/local_runtime.dart';
import 'package:agentflow/storage/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late CodeIndexer indexer;
  late Directory workspace;
  late LocalRuntime runtime;

  setUp(() async {
    database = AppDatabase.connect(NativeDatabase.memory());
    indexer = CodeIndexer(db: database);
    workspace = await Directory.systemTemp.createTemp('agentflow-indexer-');
    runtime = LocalRuntime(rootDirectory: workspace.path);

    // Create a workspace record.
    await database.into(database.workspaces).insert(
          WorkspacesCompanion.insert(
            id: 'ws1',
            name: 'Test Workspace',
            rootDirectory: workspace.path,
            createdAt: DateTime.now(),
          ),
        );
  });

  tearDown(() async {
    indexer.dispose();
    await database.close();
    if (workspace.existsSync()) {
      workspace.deleteSync(recursive: true);
    }
  });

  group('CodeIndexer chunking', () {
    test('indexes a small file into a single chunk', () async {
      File(
        '${workspace.path}${Platform.pathSeparator}hello.dart',
      ).writeAsStringSync('void main() {\n  print("hello");\n}\n');

      await indexer.indexWorkspace(
        runtime: runtime,
        workspaceId: 'ws1',
        rootDirectory: workspace.path,
      );

      final chunks = await (database.select(database.codeChunks)
            ..where((t) => t.workspaceId.equals('ws1')))
          .get();

      expect(chunks, hasLength(1));
      expect(chunks.first.filePath, contains('hello.dart'));
      expect(chunks.first.content, contains('void main'));
      expect(chunks.first.languageId, 'dart');
    });

    test('indexes a large file into multiple chunks', () async {
      // Create a file large enough to require multiple chunks (>400 chars).
      final buffer = StringBuffer();
      for (var i = 0; i < 30; i++) {
        buffer.writeln('void function$i() {');
        buffer.writeln('  print("function $i");');
        buffer.writeln('  // some additional padding text here');
        buffer.writeln('  // more lines to make the chunk bigger');
        buffer.writeln('}');
        buffer.writeln();
      }
      File(
        '${workspace.path}${Platform.pathSeparator}large.dart',
      ).writeAsStringSync(buffer.toString());

      await indexer.indexWorkspace(
        runtime: runtime,
        workspaceId: 'ws1',
        rootDirectory: workspace.path,
      );

      final chunks = await (database.select(database.codeChunks)
            ..where((t) => t.workspaceId.equals('ws1')))
          .get();

      expect(chunks.length, greaterThan(1));
      // All chunks should reference the same file.
      expect(
        chunks.every((c) => c.filePath.contains('large.dart')),
        isTrue,
      );
    });

    test('detects language from file extension', () async {
      File(
        '${workspace.path}${Platform.pathSeparator}app.py',
      ).writeAsStringSync('def hello():\n    print("hi")\n');

      File(
        '${workspace.path}${Platform.pathSeparator}index.ts',
      ).writeAsStringSync('export function hello() {\n  return "hi";\n}\n');

      await indexer.indexWorkspace(
        runtime: runtime,
        workspaceId: 'ws1',
        rootDirectory: workspace.path,
      );

      final chunks = await (database.select(database.codeChunks)
            ..where((t) => t.workspaceId.equals('ws1')))
          .get();

      final pyChunk = chunks.firstWhere((c) => c.filePath.contains('app.py'));
      expect(pyChunk.languageId, 'python');

      final tsChunk = chunks.firstWhere((c) => c.filePath.contains('index.ts'));
      expect(tsChunk.languageId, 'typescript');
    });

    test('skips binary files', () async {
      File(
        '${workspace.path}${Platform.pathSeparator}image.png',
      ).writeAsBytesSync(List<int>.filled(100, 0));
      File(
        '${workspace.path}${Platform.pathSeparator}readme.md',
      ).writeAsStringSync('# Hello\n');

      await indexer.indexWorkspace(
        runtime: runtime,
        workspaceId: 'ws1',
        rootDirectory: workspace.path,
      );

      final chunks = await (database.select(database.codeChunks)
            ..where((t) => t.workspaceId.equals('ws1')))
          .get();

      expect(
        chunks.where((c) => c.filePath.contains('.png')),
        isEmpty,
      );
      expect(
        chunks.where((c) => c.filePath.contains('readme.md')),
        hasLength(1),
      );
    });

    test('skips ignored directories', () async {
      Directory(
        '${workspace.path}${Platform.pathSeparator}node_modules',
      ).createSync();
      File(
        '${workspace.path}${Platform.pathSeparator}node_modules${Platform.pathSeparator}lib.js',
      ).writeAsStringSync('module.exports = {};');

      Directory(
        '${workspace.path}${Platform.pathSeparator}src',
      ).createSync();
      File(
        '${workspace.path}${Platform.pathSeparator}src${Platform.pathSeparator}app.js',
      ).writeAsStringSync('function app() { return true; }\n');

      await indexer.indexWorkspace(
        runtime: runtime,
        workspaceId: 'ws1',
        rootDirectory: workspace.path,
      );

      final chunks = await (database.select(database.codeChunks)
            ..where((t) => t.workspaceId.equals('ws1')))
          .get();

      expect(
        chunks.where((c) => c.filePath.contains('node_modules')),
        isEmpty,
      );
      expect(
        chunks.where((c) => c.filePath.contains('app.js')),
        hasLength(1),
      );
    });

    test('incremental update skips unchanged files', () async {
      File(
        '${workspace.path}${Platform.pathSeparator}stable.dart',
      ).writeAsStringSync('void stable() {}\n');

      // Initial index.
      await indexer.indexWorkspace(
        runtime: runtime,
        workspaceId: 'ws1',
        rootDirectory: workspace.path,
      );

      final initialChunks = await (database.select(database.codeChunks)
            ..where((t) => t.workspaceId.equals('ws1')))
          .get();
      expect(initialChunks, hasLength(1));
      final initialMtime = initialChunks.first.mtime;
      final indexedPath = initialChunks.first.filePath;

      // Re-index with same mtime should skip.
      await indexer.indexFile(
        runtime: runtime,
        workspaceId: 'ws1',
        filePath: indexedPath,
        mtime: initialMtime,
      );

      final afterChunks = await (database.select(database.codeChunks)
            ..where((t) => t.workspaceId.equals('ws1')))
          .get();
      expect(afterChunks, hasLength(1));
    });
  });

  group('CodeIndexer workspace indexing', () {
    test('clears old chunks before re-indexing', () async {
      File(
        '${workspace.path}${Platform.pathSeparator}old.dart',
      ).writeAsStringSync('void old() {}\n');

      await indexer.indexWorkspace(
        runtime: runtime,
        workspaceId: 'ws1',
        rootDirectory: workspace.path,
      );

      // Delete the file and re-index.
      File('${workspace.path}${Platform.pathSeparator}old.dart').deleteSync();
      File(
        '${workspace.path}${Platform.pathSeparator}new.dart',
      ).writeAsStringSync('void newFn() {}\n');

      await indexer.indexWorkspace(
        runtime: runtime,
        workspaceId: 'ws1',
        rootDirectory: workspace.path,
      );

      final chunks = await (database.select(database.codeChunks)
            ..where((t) => t.workspaceId.equals('ws1')))
          .get();

      expect(
        chunks.where((c) => c.filePath.contains('old.dart')),
        isEmpty,
      );
      expect(
        chunks.where((c) => c.filePath.contains('new.dart')),
        hasLength(1),
      );
    });
  });
}
