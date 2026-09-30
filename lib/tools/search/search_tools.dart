/// Agent tools for semantic search and RAG context retrieval.
///
/// Provides two tools:
/// - `semantic_search`: Search workspace code and documents with BM25 ranking
/// - `search_context`: Get full content of matching chunks for deeper analysis
library;

import '../../core/message.dart';
import '../../core/search/semantic_search_service.dart';
import '../../storage/database.dart';
import '../agent_tool.dart';
import '../tool_args.dart';

/// Creates the search tools with the given database.
List<AgentTool> searchTools(AppDatabase db) => <AgentTool>[
      SemanticSearchTool(db),
      SearchContextTool(db),
    ];

/// Semantic search tool - returns ranked snippets.
class SemanticSearchTool extends ReadOnlyTool {
  SemanticSearchTool(this._db);

  final AppDatabase _db;
  SemanticSearchService? _service;

  SemanticSearchService get _searchService =>
      _service ??= SemanticSearchService(db: _db);

  @override
  String get name => 'semantic_search';

  @override
  String get description =>
      'Search workspace code and documents using semantic full-text search. '
      'Returns ranked results with file paths, line numbers, and snippets. '
      'Use this to find relevant code or documentation by natural language query.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'query': <String, dynamic>{
            'type': 'string',
            'description': 'Natural language search query.',
          },
          'source': <String, dynamic>{
            'type': 'string',
            'enum': <String>['all', 'code', 'docs'],
            'description': 'Search source: all (default), code only, or docs only.',
          },
          'limit': <String, dynamic>{
            'type': 'integer',
            'minimum': 1,
            'maximum': 50,
            'description': 'Maximum results to return (default: 10).',
          },
        },
        'required': <String>['query'],
      };

  @override
  String describeCall(Map<String, dynamic> arguments) =>
      'semantic_search "${optionalString(arguments, 'query')}"';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final query = requireString(arguments, 'query').trim();
    if (query.isEmpty) {
      throw const ToolExecutionException('Search query cannot be empty.');
    }

    final source = optionalString(arguments, 'source');
    final limit = optionalInt(arguments, 'limit', fallback: 10).clamp(1, 50);
    final workspaceId = context.workspaceId;

    if (workspaceId == null || workspaceId.isEmpty) {
      throw const ToolExecutionException(
        'Semantic search requires an active workspace.',
      );
    }

    final results = await _searchService.searchAll(
      query: query,
      workspaceId: workspaceId,
      limit: limit,
      source: source.isEmpty ? 'all' : source,
    );

    if (results.isEmpty) {
      return ToolResult(
        toolCallId: '',
        name: name,
        content: 'No results found for "$query".',
        data: <String, dynamic>{'results': <Map<String, dynamic>>[]},
      );
    }

    final lines = results.map((r) {
      final prefix = r.source == 'code' ? '[${r.languageId}]' : '[doc]';
      return '$prefix ${r.filePath}:${r.locator}\n${r.snippet}';
    }).join('\n\n');

    return ToolResult(
      toolCallId: '',
      name: name,
      content: clampOutput('${results.length} result(s) for "$query":\n\n$lines'),
      data: <String, dynamic>{
        'results': results.map((r) => r.toJson()).toList(),
        'query': query,
      },
    );
  }
}

/// Search context tool - returns full chunk content for deeper reading.
class SearchContextTool extends ReadOnlyTool {
  SearchContextTool(this._db);

  final AppDatabase _db;
  SemanticSearchService? _service;

  SemanticSearchService get _searchService =>
      _service ??= SemanticSearchService(db: _db);

  @override
  String get name => 'search_context';

  @override
  String get description =>
      'Search and return full content of matching code chunks or document sections. '
      'Use this when you need to understand complete functions or sections, not just snippets.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'query': <String, dynamic>{
            'type': 'string',
            'description': 'Natural language search query.',
          },
          'limit': <String, dynamic>{
            'type': 'integer',
            'minimum': 1,
            'maximum': 5,
            'description': 'Maximum results to return (default: 3).',
          },
        },
        'required': <String>['query'],
      };

  @override
  String describeCall(Map<String, dynamic> arguments) =>
      'search_context "${optionalString(arguments, 'query')}"';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final query = requireString(arguments, 'query').trim();
    if (query.isEmpty) {
      throw const ToolExecutionException('Search query cannot be empty.');
    }

    final limit = optionalInt(arguments, 'limit', fallback: 3).clamp(1, 5);
    final workspaceId = context.workspaceId;

    if (workspaceId == null || workspaceId.isEmpty) {
      throw const ToolExecutionException(
        'Search context requires an active workspace.',
      );
    }

    // Search for code chunks.
    final codeResults = await _searchService.searchCode(
      query: query,
      workspaceId: workspaceId,
      limit: limit,
    );

    if (codeResults.isEmpty) {
      return ToolResult(
        toolCallId: '',
        name: name,
        content: 'No relevant code found for "$query".',
      );
    }

    // Get full content for each result.
    final buffer = StringBuffer();
    for (final result in codeResults) {
      buffer.writeln('=== ${result.filePath} (lines ${result.locator}) ===');
      buffer.writeln(result.snippet);
      buffer.writeln();
    }

    return ToolResult(
      toolCallId: '',
      name: name,
      content: clampOutput(buffer.toString()),
      data: <String, dynamic>{
        'results': codeResults.map((r) => r.toJson()).toList(),
        'query': query,
      },
    );
  }
}
