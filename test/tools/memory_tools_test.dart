import 'dart:io';

import 'package:agentflow/core/memory/memory_manager.dart';
import 'package:agentflow/runtime/local_runtime.dart';
import 'package:agentflow/tools/agent_tool.dart';
import 'package:agentflow/tools/memory/memory_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryManager manager;
  late List<AgentTool> tools;
  late ToolContext ctx;
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('agentflow_mem_test');
    final runtime = LocalRuntime(rootDirectory: tmp.path);
    manager = MemoryManager(store: InMemoryMemoryStore());
    tools = memoryTools(manager);
    ctx = ToolContext(
      runtime: runtime,
      workingDirectory: tmp.path,
      workspaceId: 'ws1',
    );
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('remember', () {
    test('saves a memory entry with content and tags', () async {
      final tool = tools.firstWhere((t) => t.name == 'remember');
      final result = await tool.execute(
        <String, dynamic>{
          'content': 'The project uses PostgreSQL 15',
          'tags': <String>['database', 'config'],
        },
        ctx,
      );

      expect(result.isError, isFalse);
      expect(result.content, contains('Saved memory'));
      expect(result.content, contains('PostgreSQL 15'));
      expect(result.data?['id'], isNotNull);

      // Verify it was persisted.
      final entries = await manager.entries('ws1');
      expect(entries, hasLength(1));
      expect(entries.first.content, 'The project uses PostgreSQL 15');
      expect(entries.first.tags, ['database', 'config']);
    });

    test('saves without tags when not provided', () async {
      final tool = tools.firstWhere((t) => t.name == 'remember');
      final result = await tool.execute(
        <String, dynamic>{'content': 'Deploy at midnight'},
        ctx,
      );

      expect(result.isError, isFalse);
      final entries = await manager.entries('ws1');
      expect(entries, hasLength(1));
      expect(entries.first.tags, isEmpty);
    });

    test('throws without workspace', () async {
      final tool = tools.firstWhere((t) => t.name == 'remember');
      final noWsCtx = ToolContext(
        runtime: ctx.runtime,
        workingDirectory: tmp.path,
      );
      expect(
        () => tool.execute(<String, dynamic>{'content': 'test'}, noWsCtx),
        throwsA(isA<ToolExecutionException>()),
      );
    });

    test('throws without content', () async {
      final tool = tools.firstWhere((t) => t.name == 'remember');
      expect(
        () => tool.execute(<String, dynamic>{}, ctx),
        throwsA(isA<ToolExecutionException>()),
      );
    });
  });

  group('recall', () {
    setUp(() async {
      await manager.remember('ws1', MemoryEntry(
        id: 'm1', content: 'Uses PostgreSQL 15', createdAt: DateTime.now(),
        tags: <String>['database'],
      ));
      await manager.remember('ws1', MemoryEntry(
        id: 'm2', content: 'API runs on port 3000', createdAt: DateTime.now(),
        tags: <String>['config'],
      ));
      await manager.remember('ws1', MemoryEntry(
        id: 'm3', content: 'Deploy to production on Fridays',
        createdAt: DateTime.now(),
        tags: <String>['deploy', 'schedule'],
      ));
    });

    test('lists all memories', () async {
      final tool = tools.firstWhere((t) => t.name == 'recall');
      final result = await tool.execute(<String, dynamic>{}, ctx);

      expect(result.isError, isFalse);
      expect(result.content, contains('3 memories'));
      expect(result.content, contains('[m1]'));
      expect(result.content, contains('[m2]'));
      expect(result.content, contains('[m3]'));
    });

    test('filters by tag', () async {
      final tool = tools.firstWhere((t) => t.name == 'recall');
      final result = await tool.execute(
        <String, dynamic>{'tag': 'database'},
        ctx,
      );

      expect(result.isError, isFalse);
      expect(result.content, contains('1 memories'));
      expect(result.content, contains('PostgreSQL'));
      expect(result.content, isNot(contains('port 3000')));
    });

    test('filters by keyword query', () async {
      final tool = tools.firstWhere((t) => t.name == 'recall');
      final result = await tool.execute(
        <String, dynamic>{'query': 'port'},
        ctx,
      );

      expect(result.isError, isFalse);
      expect(result.content, contains('port 3000'));
      expect(result.content, isNot(contains('PostgreSQL')));
    });

    test('respects limit', () async {
      final tool = tools.firstWhere((t) => t.name == 'recall');
      final result = await tool.execute(
        <String, dynamic>{'limit': 2},
        ctx,
      );

      expect(result.isError, isFalse);
      expect(result.content, contains('2 memories'));
    });

    test('returns empty message when no matches', () async {
      final tool = tools.firstWhere((t) => t.name == 'recall');
      final result = await tool.execute(
        <String, dynamic>{'tag': 'nonexistent'},
        ctx,
      );

      expect(result.isError, isFalse);
      expect(result.content, contains('No memories found'));
    });
  });

  group('forget', () {
    test('deletes a memory by id', () async {
      await manager.remember('ws1', MemoryEntry(
        id: 'm1', content: 'Will be deleted', createdAt: DateTime.now(),
      ));
      expect(await manager.entries('ws1'), hasLength(1));

      final tool = tools.firstWhere((t) => t.name == 'forget');
      final result = await tool.execute(
        <String, dynamic>{'id': 'm1'},
        ctx,
      );

      expect(result.isError, isFalse);
      expect(result.content, contains('deleted'));
      expect(await manager.entries('ws1'), isEmpty);
    });

    test('requires id argument', () async {
      final tool = tools.firstWhere((t) => t.name == 'forget');
      expect(
        () => tool.execute(<String, dynamic>{}, ctx),
        throwsA(isA<ToolExecutionException>()),
      );
    });

    test('requires workspace', () async {
      final tool = tools.firstWhere((t) => t.name == 'forget');
      final noWsCtx = ToolContext(
        runtime: ctx.runtime,
        workingDirectory: tmp.path,
      );
      expect(
        () => tool.execute(<String, dynamic>{'id': 'm1'}, noWsCtx),
        throwsA(isA<ToolExecutionException>()),
      );
    });
  });

  group('describeCall', () {
    test('remember shows truncated content', () {
      final tool = tools.firstWhere((t) => t.name == 'remember');
      final label = tool.describeCall(<String, dynamic>{
        'content': 'A very long fact about the project that should be truncated when displayed',
      });
      expect(label, startsWith('remember "'));
    });

    test('recall shows tag filter', () {
      final tool = tools.firstWhere((t) => t.name == 'recall');
      expect(
        tool.describeCall(<String, dynamic>{'tag': 'config'}),
        contains('tag=config'),
      );
    });

    test('forget shows id', () {
      final tool = tools.firstWhere((t) => t.name == 'forget');
      expect(
        tool.describeCall(<String, dynamic>{'id': 'm42'}),
        contains('m42'),
      );
    });
  });

  test('workspace isolation — tools only see own workspace memories', () async {
    await manager.remember('ws1', MemoryEntry(
      id: 'm1', content: 'WS1 memory', createdAt: DateTime.now(),
    ));
    await manager.remember('ws2', MemoryEntry(
      id: 'm2', content: 'WS2 memory', createdAt: DateTime.now(),
    ));

    final recall = tools.firstWhere((t) => t.name == 'recall');
    final ws1Ctx = ToolContext(
      runtime: ctx.runtime,
      workingDirectory: tmp.path,
      workspaceId: 'ws1',
    );
    final ws2Ctx = ToolContext(
      runtime: ctx.runtime,
      workingDirectory: tmp.path,
      workspaceId: 'ws2',
    );

    final r1 = await recall.execute(<String, dynamic>{}, ws1Ctx);
    expect(r1.content, contains('WS1 memory'));
    expect(r1.content, isNot(contains('WS2 memory')));

    final r2 = await recall.execute(<String, dynamic>{}, ws2Ctx);
    expect(r2.content, contains('WS2 memory'));
    expect(r2.content, isNot(contains('WS1 memory')));
  });
}
