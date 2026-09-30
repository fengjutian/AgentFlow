import 'dart:io';

import 'package:agentflow/core/search/code_indexer.dart';
import 'package:agentflow/core/search/rag_context_builder.dart';
import 'package:agentflow/core/search/semantic_search_service.dart';
import 'package:agentflow/runtime/local_runtime.dart';
import 'package:agentflow/storage/database.dart';
import 'package:agentflow/tools/agent_tool.dart';
import 'package:agentflow/tools/search/search_tools.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late CodeIndexer indexer;
  late SemanticSearchService searchService;
  late Directory workspace;
  late LocalRuntime runtime;

  setUp(() async {
    database = AppDatabase.connect(NativeDatabase.memory());
    indexer = CodeIndexer(db: database);
    searchService = SemanticSearchService(db: database);
    workspace = await Directory.systemTemp.createTemp('agentflow-search-');
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

  Future<void> indexTestFiles() async {
    File(
      '${workspace.path}${Platform.pathSeparator}auth.dart',
    ).writeAsStringSync(
      '/// Authentication middleware for handling user sessions.\n'
      'class AuthMiddleware {\n'
      '  /// Validates the user token and returns the session.\n'
      '  Future<Session> validateToken(String token) async {\n'
      '    if (token.isEmpty) throw AuthException("empty token");\n'
      '    return Session.fromToken(token);\n'
      '  }\n'
      '}\n',
    );
    File(
      '${workspace.path}${Platform.pathSeparator}database.dart',
    ).writeAsStringSync(
      '/// Database connection and query layer.\n'
      'class DatabaseService {\n'
      '  Future<void> connect(String url) async {\n'
      '    // connect to database\n'
      '  }\n'
      '  Future<List<Map>> query(String sql) async {\n'
      '    return [];\n'
      '  }\n'
      '}\n',
    );
    File(
      '${workspace.path}${Platform.pathSeparator}readme.md',
    ).writeAsStringSync(
      '# My Project\n\n'
      'This project uses authentication middleware for securing APIs.\n'
      'The database layer handles persistence and queries.\n',
    );

    await indexer.indexWorkspace(
      runtime: runtime,
      workspaceId: 'ws1',
      rootDirectory: workspace.path,
    );
  }

  group('SemanticSearchService', () {
    test('searchCode finds relevant chunks', () async {
      await indexTestFiles();

      final results = await searchService.searchCode(
        query: 'authentication',
        workspaceId: 'ws1',
      );

      expect(results, isNotEmpty);
      expect(results.any((r) => r.source == 'code'), isTrue);
      // At least one result should reference the auth file.
      expect(
        results.any((r) => r.filePath.contains('auth')),
        isTrue,
      );
    });

    test('searchCode returns empty for no matches', () async {
      await indexTestFiles();

      final results = await searchService.searchCode(
        query: 'zzz_nonexistent_term_zzz',
        workspaceId: 'ws1',
      );

      expect(results, isEmpty);
    });

    test('searchCode returns empty for empty query', () async {
      final results = await searchService.searchCode(
        query: '',
        workspaceId: 'ws1',
      );

      expect(results, isEmpty);
    });

    test('searchCode respects limit', () async {
      await indexTestFiles();

      final results = await searchService.searchCode(
        query: 'database',
        workspaceId: 'ws1',
        limit: 1,
      );

      expect(results.length, lessThanOrEqualTo(1));
    });

    test('getStats returns correct counts', () async {
      await indexTestFiles();

      final stats = await searchService.getStats('ws1');

      expect(stats.chunkCount, greaterThan(0));
      expect(stats.fileCount, greaterThan(0));
      expect(stats.lastIndexed, isNotNull);
    });

    test('getStats returns zeros for empty workspace', () async {
      final stats = await searchService.getStats('ws1');

      expect(stats.chunkCount, 0);
      expect(stats.fileCount, 0);
      expect(stats.lastIndexed, isNull);
    });
  });

  group('SemanticSearchTool', () {
    test('returns results for a valid query', () async {
      await indexTestFiles();

      final tool = SemanticSearchTool(database);
      final ctx = ToolContext(
        runtime: runtime,
        workingDirectory: workspace.path,
        workspaceId: 'ws1',
      );

      final result = await tool.execute(<String, dynamic>{
        'query': 'authentication',
      }, ctx);

      expect(result.isError, isFalse);
      expect(result.data!['results'], isNotEmpty);
    });

    test('throws on empty query', () async {
      final tool = SemanticSearchTool(database);
      final ctx = ToolContext(
        runtime: runtime,
        workingDirectory: workspace.path,
        workspaceId: 'ws1',
      );

      expect(
        () => tool.execute(<String, dynamic>{'query': ''}, ctx),
        throwsA(isA<ToolExecutionException>()),
      );
    });

    test('throws when no workspace is set', () async {
      final tool = SemanticSearchTool(database);
      final ctx = ToolContext(
        runtime: runtime,
        workingDirectory: workspace.path,
      );

      expect(
        () => tool.execute(<String, dynamic>{'query': 'test'}, ctx),
        throwsA(isA<ToolExecutionException>()),
      );
    });

    test('reports no results cleanly', () async {
      await indexTestFiles();

      final tool = SemanticSearchTool(database);
      final ctx = ToolContext(
        runtime: runtime,
        workingDirectory: workspace.path,
        workspaceId: 'ws1',
      );

      final result = await tool.execute(<String, dynamic>{
        'query': 'zzz_nonexistent_zzz',
      }, ctx);

      expect(result.isError, isFalse);
      expect(result.content, contains('No results'));
    });
  });

  group('SearchContextTool', () {
    test('returns full content for matching chunks', () async {
      await indexTestFiles();

      final tool = SearchContextTool(database);
      final ctx = ToolContext(
        runtime: runtime,
        workingDirectory: workspace.path,
        workspaceId: 'ws1',
      );

      final result = await tool.execute(<String, dynamic>{
        'query': 'authentication',
      }, ctx);

      expect(result.isError, isFalse);
      expect(result.content, contains('auth'));
    });
  });

  group('RagContextBuilder', () {
    test('builds context from search results', () async {
      await indexTestFiles();

      final builder = RagContextBuilder(
        searchService: searchService,
        maxTokens: 2000,
        maxResults: 3,
      );

      final context = await builder.buildContext(
        query: 'authentication middleware',
        workspaceId: 'ws1',
      );

      expect(context, contains('Relevant Context'));
      expect(context, contains('auth'));
    });

    test('returns empty for no matches', () async {
      await indexTestFiles();

      final builder = RagContextBuilder(
        searchService: searchService,
        maxResults: 3,
      );

      final context = await builder.buildContext(
        query: 'zzz_nonexistent_zzz',
        workspaceId: 'ws1',
      );

      expect(context, isEmpty);
    });

    test('returns empty for empty query', () async {
      final builder = RagContextBuilder(
        searchService: searchService,
      );

      final context = await builder.buildContext(
        query: '',
        workspaceId: 'ws1',
      );

      expect(context, isEmpty);
    });

    test('respects maxTokens budget', () async {
      await indexTestFiles();

      // Very small budget should truncate.
      final builder = RagContextBuilder(
        searchService: searchService,
        maxTokens: 10, // ~40 chars
        maxResults: 3,
      );

      final context = await builder.buildContext(
        query: 'authentication',
        workspaceId: 'ws1',
      );

      // Context should either be truncated or empty given the tiny budget.
      if (context.isNotEmpty) {
        expect(context.length, lessThan(500));
      }
    });
  });

  group('SearchResult model', () {
    test('toJson serializes all fields', () {
      const result = SearchResult(
        source: 'code',
        filePath: 'lib/auth.dart',
        locator: '10-25',
        snippet: 'authentication middleware',
        score: -1.5,
        languageId: 'dart',
      );

      final json = result.toJson();
      expect(json['source'], 'code');
      expect(json['filePath'], 'lib/auth.dart');
      expect(json['locator'], '10-25');
      expect(json['snippet'], 'authentication middleware');
      expect(json['score'], -1.5);
      expect(json['languageId'], 'dart');
    });
  });
}
