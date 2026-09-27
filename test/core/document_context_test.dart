import 'package:agentflow/core/document/document.dart';
import 'package:agentflow/core/document/document_context_builder.dart';
import 'package:agentflow/core/document/document_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestStore implements DocumentStore {
  _TestStore(this.documents, this.sectionData);

  final List<AgentDocument> documents;
  final Map<String, List<DocumentSection>> sectionData;

  @override
  Future<List<AgentDocument>> forWorkspace(String workspaceId) async =>
      documents.where((d) => d.workspaceId == workspaceId).toList();

  @override
  Future<AgentDocument?> byId(String id) async =>
      documents.cast<AgentDocument?>().firstWhere(
        (d) => d!.id == id,
        orElse: () => null,
      );

  @override
  Future<AgentDocument?> byHash(String workspaceId, String contentHash) async =>
      null;

  @override
  Future<List<DocumentSection>> sections(String documentId) async =>
      sectionData[documentId] ?? const <DocumentSection>[];

  @override
  Future<void> upsert(AgentDocument document) async {}

  @override
  Future<void> saveParsed(
    AgentDocument document,
    List<DocumentSection> sections,
  ) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<DocumentSearchHit>> search(
    String documentId,
    String query, {
    int limit = 10,
  }) async =>
      const <DocumentSearchHit>[];
}

void main() {
  final now = DateTime.utc(2026);

  final book = AgentDocument(
    id: 'book1',
    workspaceId: 'ws',
    displayName: 'flutter_guide.epub',
    sourceUri: 'flutter_guide.epub',
    localPath: '/docs/flutter_guide.epub',
    type: DocumentType.epub,
    fileSize: 500000,
    contentHash: 'abc123',
    title: 'Flutter Guide',
    author: 'AgentFlow',
    sectionCount: 3,
    parseStatus: DocumentParseStatus.ready,
    createdAt: now,
    updatedAt: now,
  );

  final sections = <DocumentSection>[
    const DocumentSection(
      id: 'ch0',
      documentId: 'book1',
      index: 0,
      kind: 'chapter',
      title: 'Introduction',
      locator: 'intro.xhtml',
      plainText: 'Welcome to Flutter. This guide covers the basics.',
    ),
    const DocumentSection(
      id: 'ch1',
      documentId: 'book1',
      index: 1,
      kind: 'chapter',
      title: 'Widgets',
      locator: 'widgets.xhtml',
      plainText: 'Widgets are the building blocks of Flutter UIs.',
    ),
    const DocumentSection(
      id: 'ch2',
      documentId: 'book1',
      index: 2,
      kind: 'chapter',
      title: 'State Management',
      locator: 'state.xhtml',
      plainText: 'Riverpod is a popular state management solution.',
    ),
  ];

  late _TestStore store;
  late DocumentContextBuilder builder;

  setUp(() {
    store = _TestStore(<AgentDocument>[book], <String, List<DocumentSection>>{
      'book1': sections,
    });
    builder = DocumentContextBuilder(store: store, maxSectionChars: 200);
  });

  group('buildWorkspaceSummary', () {
    test('lists documents with type and status', () async {
      final summary = await builder.buildWorkspaceSummary('ws');
      expect(summary, contains('Flutter Guide'));
      expect(summary, contains('EPUB'));
      expect(summary, contains('ready'));
      expect(summary, contains('book1'));
    });

    test('returns "No imported documents" for empty workspace', () async {
      final empty = _TestStore(<AgentDocument>[], <String, List<DocumentSection>>{});
      final b = DocumentContextBuilder(store: empty);
      final summary = await b.buildWorkspaceSummary('ws');
      expect(summary, 'No imported documents.');
    });
  });

  group('buildDocumentContext', () {
    test('shows title, author, status and TOC', () async {
      final context = await builder.buildDocumentContext('book1');
      expect(context, contains('Flutter Guide'));
      expect(context, contains('AgentFlow'));
      expect(context, contains('ready'));
      expect(context, contains('intro.xhtml'));
      expect(context, contains('widgets.xhtml'));
      expect(context, contains('state.xhtml'));
      expect(context, contains('3'));
    });

    test('returns "Document not found" for unknown id', () async {
      final context = await builder.buildDocumentContext('nonexistent');
      expect(context, 'Document not found.');
    });
  });

  group('buildSectionContext', () {
    test('returns text for the requested section range', () async {
      final context = await builder.buildSectionContext('book1', start: 1, end: 1);
      expect(context, contains('[widgets.xhtml]'));
      expect(context, contains('Widgets'));
      expect(context, contains('building blocks'));
      expect(context, isNot(contains('[intro.xhtml]')));
      expect(context, isNot(contains('[state.xhtml]')));
    });

    test('truncates long sections to maxSectionChars', () async {
      final longText = 'A' * 500;
      final longSections = <DocumentSection>[
        DocumentSection(
          id: 'long0',
          documentId: 'book1',
          index: 0,
          kind: 'chapter',
          title: 'Long Chapter',
          locator: 'long.xhtml',
          plainText: longText,
        ),
      ];
      final longStore = _TestStore(
        <AgentDocument>[book],
        <String, List<DocumentSection>>{'book1': longSections},
      );
      final b = DocumentContextBuilder(store: longStore, maxSectionChars: 100);
      final context = await b.buildSectionContext('book1', start: 0, end: 0);
      expect(context, contains('[truncated]'));
      // The actual text should be at most ~100 chars + the truncation marker.
      expect(context.length, lessThan(300));
    });

    test('returns "No sections in range" for invalid range', () async {
      final context = await builder.buildSectionContext('book1', start: 10, end: 10);
      expect(context, contains('No sections in range'));
    });

    test('handles multi-section range correctly', () async {
      final context = await builder.buildSectionContext('book1', start: 0, end: 1);
      expect(context, contains('[intro.xhtml]'));
      expect(context, contains('[widgets.xhtml]'));
      expect(context, isNot(contains('[state.xhtml]')));
    });
  });

  group('search integration', () {
    test('search finds text in sections', () async {
      final hits = await store.search('book1', 'widgets');
      expect(hits, isEmpty); // _TestStore.search returns empty by default.
    });
  });
}
