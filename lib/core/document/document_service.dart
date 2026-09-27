library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'document.dart';
import 'document_parser.dart';

abstract class DocumentStore {
  Future<List<AgentDocument>> forWorkspace(String workspaceId);
  Future<AgentDocument?> byId(String id);
  Future<AgentDocument?> byHash(String workspaceId, String contentHash);
  Future<List<DocumentSection>> sections(String documentId);
  Future<void> upsert(AgentDocument document);
  Future<void> saveParsed(
    AgentDocument document,
    List<DocumentSection> sections,
  );
  Future<void> delete(String id);

  /// Full-text search across document sections. Returns matching sections with
  /// snippets. Falls back to substring matching when FTS is unavailable.
  Future<List<DocumentSearchHit>> search(
    String documentId,
    String query, {
    int limit = 10,
  });
}

class DocumentSearchHit {
  const DocumentSearchHit({
    required this.index,
    required this.title,
    required this.locator,
    required this.snippet,
  });

  final int index;
  final String title;
  final String locator;
  final String snippet;
}

typedef DocumentIdGenerator = String Function();
typedef DocumentClock = DateTime Function();

class DocumentImportRequest {
  const DocumentImportRequest({
    required this.workspaceId,
    required this.sourcePath,
    this.sourceUri,
    this.displayName,
    this.mimeType = '',
  });

  final String workspaceId;
  final String sourcePath;
  final String? sourceUri;
  final String? displayName;
  final String mimeType;
}

class DocumentImportService {
  DocumentImportService({
    required DocumentStore store,
    required DocumentParserRegistry parsers,
    required String documentsDirectory,
    required DocumentIdGenerator idGenerator,
    DocumentClock? clock,
  }) : _store = store,
       _parsers = parsers,
       _documentsDirectory = documentsDirectory,
       _idGenerator = idGenerator,
       _clock = clock ?? DateTime.now;

  final DocumentStore _store;
  final DocumentParserRegistry _parsers;
  final String _documentsDirectory;
  final DocumentIdGenerator _idGenerator;
  final DocumentClock _clock;

  Future<AgentDocument> import(
    DocumentImportRequest request, {
    void Function(DocumentParseProgress progress)? onProgress,
  }) async {
    final source = File(request.sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Document does not exist', request.sourcePath);
    }

    final extension = p.extension(request.sourcePath).toLowerCase();
    final parser = _parsers.find(
      extension: extension,
      mimeType: request.mimeType,
    );
    if (parser == null) {
      throw UnsupportedDocumentException(
        'No parser supports ${extension.isEmpty ? request.mimeType : extension}.',
      );
    }

    final bytes = await source.readAsBytes();
    final contentHash = sha256.convert(bytes).toString();
    final duplicate = await _store.byHash(request.workspaceId, contentHash);
    if (duplicate != null) return duplicate;

    final id = _idGenerator();
    final now = _clock();
    final targetDirectory = Directory(
      p.join(_documentsDirectory, request.workspaceId),
    );
    await targetDirectory.create(recursive: true);
    final targetPath = p.join(targetDirectory.path, '$id$extension');
    await File(targetPath).writeAsBytes(bytes, flush: true);

    var document = AgentDocument(
      id: id,
      workspaceId: request.workspaceId,
      displayName: request.displayName ?? p.basename(request.sourcePath),
      sourceUri: request.sourceUri ?? request.sourcePath,
      localPath: targetPath,
      type: parser.type,
      mimeType: request.mimeType,
      fileSize: bytes.length,
      contentHash: contentHash,
      createdAt: now,
      updatedAt: now,
      parseStatus: DocumentParseStatus.parsing,
    );
    await _store.upsert(document);

    try {
      final parsed = await parser.parse(targetPath, onProgress: onProgress);
      final sectionIds = <int, String>{};
      for (final section in parsed.sections) {
        sectionIds[section.index] = _idGenerator();
      }
      final sections = parsed.sections
          .map(
            (section) => DocumentSection(
              id: sectionIds[section.index]!,
              documentId: id,
              index: section.index,
              parentSectionId: section.parentIndex == null
                  ? null
                  : sectionIds[section.parentIndex],
              kind: section.kind,
              title: section.title,
              locator: section.locator,
              plainText: section.plainText,
              metadata: section.metadata,
            ),
          )
          .toList(growable: false);
      document = document.copyWith(
        title: parsed.title,
        author: parsed.author,
        language: parsed.language,
        pageCount: parsed.pageCount,
        sectionCount: sections.length,
        parseStatus: parsed.requiresOcr
            ? DocumentParseStatus.ocrRequired
            : DocumentParseStatus.ready,
        clearParseError: true,
        updatedAt: _clock(),
      );
      await _store.saveParsed(document, sections);
      return document;
    } catch (error) {
      document = document.copyWith(
        parseStatus: DocumentParseStatus.failed,
        parseError: error.toString(),
        updatedAt: _clock(),
      );
      await _store.upsert(document);
      rethrow;
    }
  }
}
