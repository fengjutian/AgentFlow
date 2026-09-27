import 'dart:io';

import 'package:agentflow/core/document/document.dart';
import 'package:agentflow/core/document/document_parser.dart';
import 'package:agentflow/core/document/document_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryDocumentStore implements DocumentStore {
  final Map<String, AgentDocument> documents = <String, AgentDocument>{};
  final Map<String, List<DocumentSection>> sectionData =
      <String, List<DocumentSection>>{};

  @override
  Future<List<AgentDocument>> forWorkspace(String workspaceId) async =>
      documents.values
          .where((document) => document.workspaceId == workspaceId)
          .toList();

  @override
  Future<AgentDocument?> byId(String id) async => documents[id];

  @override
  Future<AgentDocument?> byHash(String workspaceId, String contentHash) async {
    for (final document in documents.values) {
      if (document.workspaceId == workspaceId &&
          document.contentHash == contentHash) {
        return document;
      }
    }
    return null;
  }

  @override
  Future<List<DocumentSection>> sections(String documentId) async =>
      sectionData[documentId] ?? const <DocumentSection>[];

  @override
  Future<void> upsert(AgentDocument document) async {
    documents[document.id] = document;
  }

  @override
  Future<void> saveParsed(
    AgentDocument document,
    List<DocumentSection> sections,
  ) async {
    documents[document.id] = document;
    sectionData[document.id] = sections;
  }

  @override
  Future<void> delete(String id) async {
    documents.remove(id);
    sectionData.remove(id);
  }

  @override
  Future<List<DocumentSearchHit>> search(
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
}

class _FakeEpubParser implements DocumentParser {
  _FakeEpubParser({this.error, this.requiresOcr = false});

  final Object? error;
  final bool requiresOcr;
  int calls = 0;

  @override
  DocumentType get type => DocumentType.epub;

  @override
  bool supports({required String extension, required String mimeType}) =>
      extension == '.epub' || mimeType == 'application/epub+zip';

  @override
  Future<ParsedDocument> parse(
    String localPath, {
    void Function(DocumentParseProgress progress)? onProgress,
  }) async {
    calls++;
    if (error != null) throw error!;
    onProgress?.call(const DocumentParseProgress(completed: 1, total: 1));
    return ParsedDocument(
      title: 'Example book',
      author: 'AgentFlow',
      requiresOcr: requiresOcr,
      sections: const <ParsedDocumentSection>[
        ParsedDocumentSection(
          index: 0,
          kind: 'chapter',
          title: 'Introduction',
          locator: 'intro.xhtml',
          plainText: 'Hello AgentFlow',
        ),
      ],
    );
  }
}

void main() {
  late Directory temporaryDirectory;
  late File source;
  late _MemoryDocumentStore store;
  var nextId = 0;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'agentflow-document-test-',
    );
    source = File('${temporaryDirectory.path}/book.epub');
    await source.writeAsString('fake epub bytes');
    store = _MemoryDocumentStore();
    nextId = 0;
  });

  tearDown(() => temporaryDirectory.delete(recursive: true));

  DocumentImportService service(_FakeEpubParser parser) =>
      DocumentImportService(
        store: store,
        parsers: DocumentParserRegistry(parsers: <DocumentParser>[parser]),
        documentsDirectory: '${temporaryDirectory.path}/documents',
        idGenerator: () => 'id-${nextId++}',
        clock: () => DateTime.utc(2026),
      );

  test('imports, hashes, parses and stores a supported document', () async {
    final parser = _FakeEpubParser();
    final progress = <double>[];

    final document = await service(parser).import(
      DocumentImportRequest(workspaceId: 'workspace', sourcePath: source.path),
      onProgress: (value) => progress.add(value.fraction),
    );

    expect(document.parseStatus, DocumentParseStatus.ready);
    expect(document.title, 'Example book');
    expect(document.contentHash, hasLength(64));
    expect(await File(document.localPath).exists(), isTrue);
    expect((await store.sections(document.id)).single.locator, 'intro.xhtml');
    expect(progress, <double>[1]);
  });

  test(
    'returns the existing document when the same content is imported',
    () async {
      final parser = _FakeEpubParser();
      final importer = service(parser);

      final first = await importer.import(
        DocumentImportRequest(
          workspaceId: 'workspace',
          sourcePath: source.path,
        ),
      );
      final second = await importer.import(
        DocumentImportRequest(
          workspaceId: 'workspace',
          sourcePath: source.path,
        ),
      );

      expect(second.id, first.id);
      expect(parser.calls, 1);
    },
  );

  test('persists a failed status when parsing throws', () async {
    final parser = _FakeEpubParser(error: const FormatException('broken'));

    await expectLater(
      service(parser).import(
        DocumentImportRequest(
          workspaceId: 'workspace',
          sourcePath: source.path,
        ),
      ),
      throwsFormatException,
    );

    expect(
      store.documents.values.single.parseStatus,
      DocumentParseStatus.failed,
    );
    expect(store.documents.values.single.parseError, contains('broken'));
  });

  test('marks documents without a usable text layer as requiring OCR', () async {
    final document = await service(_FakeEpubParser(requiresOcr: true)).import(
      DocumentImportRequest(
        workspaceId: 'workspace',
        sourcePath: source.path,
      ),
    );

    expect(document.parseStatus, DocumentParseStatus.ocrRequired);
  });

  test('rejects unsupported extensions before copying the source', () async {
    final unsupported = File('${temporaryDirectory.path}/notes.txt');
    await unsupported.writeAsString('notes');

    await expectLater(
      service(_FakeEpubParser()).import(
        DocumentImportRequest(
          workspaceId: 'workspace',
          sourcePath: unsupported.path,
        ),
      ),
      throwsA(isA<UnsupportedDocumentException>()),
    );
    expect(store.documents, isEmpty);
  });
}
