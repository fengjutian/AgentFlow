/// Unified semantic search service using BM25 over FTS5.
///
/// Searches across both code chunks (indexed by [CodeIndexer]) and document
/// sections (indexed by [DocumentRepository]) with unified scoring and ranking.
library;

import 'dart:async';

import 'package:drift/drift.dart';

import '../../storage/database.dart';

/// A search result from either code or document sources.
class SearchResult {
  const SearchResult({
    required this.source,
    required this.filePath,
    required this.locator,
    required this.snippet,
    required this.score,
    this.languageId = '',
  });

  /// 'code' or 'document'.
  final String source;

  /// File path for code, document title for documents.
  final String filePath;

  /// Line range (e.g., "42-58") or section locator (e.g., "Page 12").
  final String locator;

  /// Matched text with context.
  final String snippet;

  /// BM25 relevance score (lower is better in FTS5 rank).
  final double score;

  /// Language ID for code results.
  final String languageId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'source': source,
        'filePath': filePath,
        'locator': locator,
        'snippet': snippet,
        'score': score,
        'languageId': languageId,
      };
}

/// Service for BM25-ranked semantic search over workspace content.
class SemanticSearchService {
  SemanticSearchService({required this.db});

  final AppDatabase db;

  /// Searches code chunks with BM25 ranking.
  Future<List<SearchResult>> searchCode({
    required String query,
    required String workspaceId,
    int limit = 10,
    String? pathFilter,
    String? languageFilter,
  }) async {
    if (query.trim().isEmpty) return [];

    final results = <SearchResult>[];
    final escaped = _escapeFtsQuery(query);
    if (escaped.isEmpty) return [];

    try {
      final rows = await db.customSelect(
        'SELECT cc.file_path, cc.start_line, cc.end_line, cc.content, '
        'cc.language_id, bm25(code_chunks_fts) AS rank '
        'FROM code_chunks_fts '
        'JOIN code_chunks cc ON cc.id = code_chunks_fts.rowid '
        'WHERE cc.workspace_id = ? '
        '${pathFilter != null && pathFilter.isNotEmpty ? "AND cc.file_path LIKE ? " : ""}'
        '${languageFilter != null && languageFilter.isNotEmpty ? "AND cc.language_id = ? " : ""}'
        'AND code_chunks_fts MATCH ? '
        'ORDER BY rank '
        'LIMIT ?',
        variables: [
          Variable.withString(workspaceId),
          if (pathFilter != null && pathFilter.isNotEmpty)
            Variable.withString('%$pathFilter%'),
          if (languageFilter != null && languageFilter.isNotEmpty)
            Variable.withString(languageFilter),
          Variable.withString(escaped),
          Variable.withInt(limit),
        ],
        readsFrom: {db.codeChunks},
      ).get();

      for (final row in rows) {
        results.add(SearchResult(
          source: 'code',
          filePath: row.read<String>('file_path'),
          locator: '${row.read<int>('start_line')}-${row.read<int>('end_line')}',
          snippet: _extractSnippet(row.read<String>('content'), query),
          score: row.read<double>('rank'),
          languageId: row.read<String>('language_id'),
        ));
      }
    } catch (_) {
      // FTS query failed, return empty.
    }

    return results;
  }

  /// Searches document sections with BM25 ranking.
  Future<List<SearchResult>> searchDocuments({
    required String query,
    required String workspaceId,
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return [];

    final results = <SearchResult>[];
    final escaped = _escapeFtsQuery(query);
    if (escaped.isEmpty) return [];

    try {
      final rows = await db.customSelect(
        'SELECT d.title, ds.title AS section_title, ds.locator, ds.plain_text, '
        'bm25(document_sections_fts) AS rank '
        'FROM document_sections_fts '
        'JOIN document_sections ds ON ds.rowid = document_sections_fts.rowid '
        'JOIN documents d ON d.id = ds.document_id '
        'WHERE d.workspace_id = ? '
        'AND document_sections_fts MATCH ? '
        'ORDER BY rank '
        'LIMIT ?',
        variables: [
          Variable.withString(workspaceId),
          Variable.withString(escaped),
          Variable.withInt(limit),
        ],
        readsFrom: {db.documentSections, db.documents},
      ).get();

      for (final row in rows) {
        final docTitle = row.read<String>('title');
        final sectionTitle = row.read<String>('section_title');
        final title = sectionTitle.isEmpty ? docTitle : '$docTitle: $sectionTitle';

        results.add(SearchResult(
          source: 'document',
          filePath: title,
          locator: row.read<String>('locator'),
          snippet: _extractSnippet(row.read<String>('plain_text'), query),
          score: row.read<double>('rank'),
        ));
      }
    } catch (_) {
      // FTS query failed, return empty.
    }

    return results;
  }

  /// Combined search across both code and documents, returning ranked results.
  Future<List<SearchResult>> searchAll({
    required String query,
    required String workspaceId,
    int limit = 10,
    String source = 'all', // 'all', 'code', 'docs'
  }) async {
    final results = <SearchResult>[];

    if (source == 'all' || source == 'code') {
      results.addAll(await searchCode(
        query: query,
        workspaceId: workspaceId,
        limit: limit,
      ));
    }

    if (source == 'all' || source == 'docs') {
      results.addAll(await searchDocuments(
        query: query,
        workspaceId: workspaceId,
        limit: limit,
      ));
    }

    // Sort by score (lower is better) and take top results.
    results.sort((a, b) => a.score.compareTo(b.score));
    return results.take(limit).toList();
  }

  /// Escapes special FTS5 query characters and wraps in quotes.
  String _escapeFtsQuery(String query) {
    final cleaned = query
        .replaceAll('"', '""')
        .replaceAll('*', '')
        .replaceAll('^', '')
        .trim();
    if (cleaned.isEmpty) return '';
    // Use phrase query for better matching.
    return '"$cleaned"';
  }

  /// Extracts a snippet around the query match.
  String _extractSnippet(String content, String query, {int contextChars = 200}) {
    final lower = content.toLowerCase();
    final queryLower = query.toLowerCase();
    final index = lower.indexOf(queryLower);

    if (index < 0) {
      // No exact match, return beginning of content.
      return content.length > contextChars * 2
          ? '${content.substring(0, contextChars * 2)}...'
          : content;
    }

    final start = (index - contextChars).clamp(0, content.length);
    final end = (index + query.length + contextChars).clamp(start, content.length);

    var snippet = content.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < content.length) snippet = '$snippet...';

    return snippet;
  }

  /// Gets indexing statistics for a workspace.
  Future<IndexingStats> getStats(String workspaceId) async {
    final chunkCount = await (db.selectOnly(db.codeChunks)
          ..addColumns([db.codeChunks.id.count()])
          ..where(db.codeChunks.workspaceId.equals(workspaceId)))
        .getSingleOrNull();

    final fileCount = await db
        .customSelect(
          'SELECT COUNT(DISTINCT file_path) AS count FROM code_chunks '
          'WHERE workspace_id = ?',
          variables: [Variable.withString(workspaceId)],
          readsFrom: {db.codeChunks},
        )
        .getSingle();

    final lastIndexed = await (db.selectOnly(db.codeChunks)
          ..addColumns([db.codeChunks.indexedAt.max()])
          ..where(db.codeChunks.workspaceId.equals(workspaceId)))
        .getSingleOrNull();

    return IndexingStats(
      chunkCount: chunkCount?.read(db.codeChunks.id.count()) ?? 0,
      fileCount: fileCount.read<int>('count'),
      lastIndexed: lastIndexed?.read(db.codeChunks.indexedAt.max()),
    );
  }
}

/// Statistics about the indexing state.
class IndexingStats {
  const IndexingStats({
    required this.chunkCount,
    required this.fileCount,
    this.lastIndexed,
  });

  final int chunkCount;
  final int fileCount;
  final DateTime? lastIndexed;
}
