/// RAG (Retrieval-Augmented Generation) context builder.
///
/// Automatically injects relevant code/document snippets into agent system
/// prompts based on the user's query. This helps the agent understand the
/// codebase context without explicit search tool calls.
///
/// Budget: max 2000 tokens (~8000 chars) of injected context per prompt.
library;

import 'semantic_search_service.dart';

/// Builds RAG context from semantic search results.
class RagContextBuilder {
  RagContextBuilder({
    required this.searchService,
    this.maxTokens = 2000,
    this.maxResults = 3,
  });

  final SemanticSearchService searchService;

  /// Maximum tokens to inject (roughly 4 chars per token).
  final int maxTokens;

  /// Maximum number of results to include.
  final int maxResults;

  /// Builds context snippets for the given query.
  ///
  /// Returns a formatted string ready to be injected into the system prompt,
  /// or empty string if no relevant context found.
  Future<String> buildContext({
    required String query,
    required String workspaceId,
  }) async {
    if (query.trim().isEmpty) return '';

    final results = await searchService.searchAll(
      query: query,
      workspaceId: workspaceId,
      limit: maxResults,
    );

    if (results.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('\n--- Relevant Context from Workspace ---');
    buffer.writeln(
      'The following code snippets and documents may be relevant to the current query:',
    );
    buffer.writeln();

    var charCount = 0;
    final maxChars = maxTokens * 4;

    for (final result in results) {
      final snippet = _formatResult(result);
      if (charCount + snippet.length > maxChars) {
        buffer.writeln('... (context truncated)');
        break;
      }

      buffer.writeln(snippet);
      buffer.writeln();
      charCount += snippet.length;
    }

    buffer.writeln('--- End of Context ---\n');
    return buffer.toString();
  }

  String _formatResult(SearchResult result) {
    final header = result.source == 'code'
        ? '[Code: ${result.filePath} (lines ${result.locator}, ${result.languageId})]'
        : '[Document: ${result.filePath} (${result.locator})]';

    // Truncate long snippets.
    var snippet = result.snippet;
    if (snippet.length > 1000) {
      snippet = '${snippet.substring(0, 1000)}...';
    }

    return '$header\n```\n$snippet\n```';
  }
}
