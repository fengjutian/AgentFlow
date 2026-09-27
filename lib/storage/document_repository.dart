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
  });

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.documents)..where((table) => table.id.equals(id))).go();

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
