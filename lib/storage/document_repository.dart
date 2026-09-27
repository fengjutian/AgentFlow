library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/document/document.dart';
import '../core/document/document_service.dart';
import 'database.dart';

class DriftDocumentStore implements DocumentStore {
  DriftDocumentStore(this._db);

  final AppDatabase _db;

  @override
  Future<List<AgentDocument>> forWorkspace(String workspaceId) async {
    final rows =
        await (_db.select(_db.documents)
              ..where((table) => table.workspaceId.equals(workspaceId))
              ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]))
            .get();
    return rows.map(_documentFromRow).toList(growable: false);
  }

  @override
  Future<AgentDocument?> byId(String id) async {
    final row = await (_db.select(
      _db.documents,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _documentFromRow(row);
  }

  @override
  Future<AgentDocument?> byHash(String workspaceId, String contentHash) async {
    final row =
        await (_db.select(_db.documents)..where(
              (table) =>
                  table.workspaceId.equals(workspaceId) &
                  table.contentHash.equals(contentHash),
            ))
            .getSingleOrNull();
    return row == null ? null : _documentFromRow(row);
  }

  @override
  Future<List<DocumentSection>> sections(String documentId) async {
    final rows =
        await (_db.select(_db.documentSections)
              ..where((table) => table.documentId.equals(documentId))
              ..orderBy([(table) => OrderingTerm.asc(table.sectionIndex)]))
            .get();
    return rows.map(_sectionFromRow).toList(growable: false);
  }

  @override
  Future<void> upsert(AgentDocument document) => _db
      .into(_db.documents)
      .insert(_documentToCompanion(document), mode: InsertMode.insertOrReplace);

  @override
  Future<void> saveParsed(
    AgentDocument document,
    List<DocumentSection> sections,
  ) => _db.transaction(() async {
    await upsert(document);
    await (_db.delete(
      _db.documentSections,
    )..where((table) => table.documentId.equals(document.id))).go();
    if (sections.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(
          _db.documentSections,
          sections.map(_sectionToCompanion).toList(growable: false),
        );
      });
    }
    // Populate FTS index for this document.
    await _reindexFts(document.id, sections);
  });

  @override
  Future<void> delete(String id) => _db.transaction(() async {
    // Remove FTS entries first.
    await _removeFtsEntries(id);
    // Keep cleanup deterministic even when a SQLite connection has foreign-key
    // enforcement disabled (as some in-memory/test connections do).
    await (_db.delete(
      _db.documentSections,
    )..where((table) => table.documentId.equals(id))).go();
    await (_db.delete(
      _db.documents,
    )..where((table) => table.id.equals(id))).go();
  });

  @override
  Future<List<DocumentSearchHit>> search(
    String documentId,
    String query, {
    int limit = 10,
  }) async {
    // Try FTS5 first; fall back to in-memory substring search.
    if (await _ftsAvailable()) {
      return _ftsSearch(documentId, query, limit: limit);
    }
    return _substringSearch(documentId, query, limit: limit);
  }

  // ---------------------------------------------------------------------------
  // FTS helpers
  // ---------------------------------------------------------------------------

  bool? _ftsAvailableCache;

  Future<bool> _ftsAvailable() async {
    if (_ftsAvailableCache != null) return _ftsAvailableCache!;
    try {
      await _db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name='document_sections_fts'",
            readsFrom: const <ResultSetImplementation<dynamic, dynamic>>{},
          )
          .get()
          .then((rows) => _ftsAvailableCache = rows.isNotEmpty);
    } catch (_) {
      _ftsAvailableCache = false;
    }
    return _ftsAvailableCache!;
  }

  Future<void> _reindexFts(
    String documentId,
    List<DocumentSection> sections,
  ) async {
    if (!await _ftsAvailable()) return;
    // Delete old FTS entries for this document.
    await _removeFtsEntries(documentId);
    // Insert new entries using the content= rebuild command per section.
    for (final section in sections) {
      await _db.customStatement(
        "INSERT INTO document_sections_fts(document_sections_fts, rowid, "
        'plain_text) VALUES(\'rebuild\', '
        "(SELECT rowid FROM document_sections WHERE id = "
        "'${_escapeSql(section.id)}'), "
        "'${_escapeSql(section.plainText)}')",
      );
    }
  }

  Future<void> _removeFtsEntries(String documentId) async {
    if (!await _ftsAvailable()) return;
    try {
      await _db.customStatement(
        "DELETE FROM document_sections_fts WHERE rowid IN ("
        'SELECT ds.rowid FROM document_sections ds WHERE ds.id = '
        "'${_escapeSql(documentId)}')",
      );
    } catch (_) {
      // FTS table may not exist or section may have no entries.
    }
  }

  Future<List<DocumentSearchHit>> _ftsSearch(
    String documentId,
    String query, {
    int limit = 10,
  }) async {
    final escaped = _escapeSql(query).replaceAll('"', '""');
    final rows = await _db
        .customSelect(
          'SELECT ds.section_index, ds.title, ds.locator, '
          "snippet(document_sections_fts, 0, '<b>', '</b>', '...', 32) "
          'AS snippet '
          'FROM document_sections_fts fts '
          'JOIN document_sections ds ON ds.rowid = fts.rowid '
          "WHERE ds.document_id = '${_escapeSql(documentId)}' "
          'AND document_sections_fts MATCH \'\"$escaped\"\' '
          'ORDER BY rank '
          'LIMIT $limit',
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _db.documentSections,
          },
        )
        .get();
    return rows
        .map(
          (row) => DocumentSearchHit(
            index: row.read<int>('section_index'),
            title: row.read<String>('title'),
            locator: row.read<String>('locator'),
            snippet: row.read<String>('snippet'),
          ),
        )
        .toList(growable: false);
  }

  Future<List<DocumentSearchHit>> _substringSearch(
    String documentId,
    String query, {
    int limit = 10,
  }) async {
    final sections = await this.sections(documentId);
    final needle = query.toLowerCase();
    final hits = <DocumentSearchHit>[];
    for (final section in sections) {
      final lower = section.plainText.toLowerCase();
      final offset = lower.indexOf(needle);
      if (offset < 0) continue;
      final start = (offset - 100).clamp(0, section.plainText.length);
      final end = (offset + query.length + 180).clamp(
        start,
        section.plainText.length,
      );
      hits.add(
        DocumentSearchHit(
          index: section.index,
          title: section.title,
          locator: section.locator,
          snippet: section.plainText.substring(start, end).trim(),
        ),
      );
      if (hits.length >= limit) break;
    }
    return hits;
  }

  DocumentsCompanion _documentToCompanion(AgentDocument document) =>
      DocumentsCompanion.insert(
        id: document.id,
        workspaceId: document.workspaceId,
        displayName: document.displayName,
        sourceUri: document.sourceUri,
        localPath: document.localPath,
        type: document.type.name,
        mimeType: Value(document.mimeType),
        fileSize: Value(document.fileSize),
        contentHash: Value(document.contentHash),
        title: Value(document.title),
        author: Value(document.author),
        language: Value(document.language),
        pageCount: Value(document.pageCount),
        sectionCount: Value(document.sectionCount),
        parseStatus: Value(document.parseStatus.name),
        parseError: Value(document.parseError),
        createdAt: document.createdAt,
        updatedAt: document.updatedAt,
      );

  DocumentSectionsCompanion _sectionToCompanion(DocumentSection section) =>
      DocumentSectionsCompanion.insert(
        id: section.id,
        documentId: section.documentId,
        sectionIndex: section.index,
        parentSectionId: Value(section.parentSectionId),
        kind: section.kind,
        title: Value(section.title),
        locator: section.locator,
        plainText: Value(section.plainText),
        charCount: Value(section.charCount),
        metadataJson: Value(jsonEncode(section.metadata)),
      );

  AgentDocument _documentFromRow(DocumentRow row) => AgentDocument(
    id: row.id,
    workspaceId: row.workspaceId,
    displayName: row.displayName,
    sourceUri: row.sourceUri,
    localPath: row.localPath,
    type: DocumentType.values.byName(row.type),
    mimeType: row.mimeType,
    fileSize: row.fileSize,
    contentHash: row.contentHash,
    title: row.title,
    author: row.author,
    language: row.language,
    pageCount: row.pageCount,
    sectionCount: row.sectionCount,
    parseStatus: DocumentParseStatus.values.byName(row.parseStatus),
    parseError: row.parseError,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  DocumentSection _sectionFromRow(DocumentSectionRow row) => DocumentSection(
    id: row.id,
    documentId: row.documentId,
    index: row.sectionIndex,
    parentSectionId: row.parentSectionId,
    kind: row.kind,
    title: row.title,
    locator: row.locator,
    plainText: row.plainText,
    metadata: _decodeMetadata(row.metadataJson),
  );
}

Map<String, dynamic> _decodeMetadata(String source) {
  try {
    final value = jsonDecode(source);
    if (value is Map) return value.cast<String, dynamic>();
  } catch (_) {
    // Corrupt optional metadata should not hide the document text.
  }
  return <String, dynamic>{};
}

/// Escapes single quotes for safe SQL string interpolation.
String _escapeSql(String value) => value.replaceAll("'", "''");
