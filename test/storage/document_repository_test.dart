import 'package:agentflow/core/document/document.dart';
import 'package:agentflow/data/models.dart';
import 'package:agentflow/storage/database.dart';
import 'package:agentflow/storage/document_repository.dart';
import 'package:agentflow/storage/repositories.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftDocumentStore documents;

  setUp(() async {
    database = AppDatabase.connect(NativeDatabase.memory());
    documents = DriftDocumentStore(database);
    await WorkspaceRepository(database).upsert(
      Workspace(
        id: 'workspace',
        name: 'Workspace',
        rootDirectory: '.',
        createdAt: DateTime.utc(2026),
      ),
    );
  });

  tearDown(() => database.close());

  test('persists a parsed document and ordered sections atomically', () async {
    final now = DateTime.utc(2026);
    final document = AgentDocument(
      id: 'document',
      workspaceId: 'workspace',
      displayName: 'Guide.epub',
      sourceUri: '/source/Guide.epub',
      localPath: '/cache/document.epub',
      type: DocumentType.epub,
      fileSize: 42,
      contentHash: 'hash',
      title: 'Guide',
      sectionCount: 2,
      parseStatus: DocumentParseStatus.ready,
      createdAt: now,
      updatedAt: now,
    );

    await documents.saveParsed(document, const <DocumentSection>[
      DocumentSection(
        id: 'section-2',
        documentId: 'document',
        index: 2,
        kind: 'chapter',
        locator: 'chapter-2.xhtml',
        plainText: 'Second',
      ),
      DocumentSection(
        id: 'section-1',
        documentId: 'document',
        index: 1,
        kind: 'chapter',
        locator: 'chapter-1.xhtml',
        plainText: 'First',
        metadata: <String, dynamic>{'level': 1},
      ),
    ]);

    expect((await documents.byId('document'))!.title, 'Guide');
    expect((await documents.byHash('workspace', 'hash'))!.id, 'document');
    final sections = await documents.sections('document');
    expect(sections.map((section) => section.index), <int>[1, 2]);
    expect(sections.first.metadata['level'], 1);
  });

  test('deleting a document cascades to its sections', () async {
    final now = DateTime.utc(2026);
    final document = AgentDocument(
      id: 'document',
      workspaceId: 'workspace',
      displayName: 'Guide.pdf',
      sourceUri: '/source/Guide.pdf',
      localPath: '/cache/document.pdf',
      type: DocumentType.pdf,
      fileSize: 42,
      contentHash: 'hash',
      createdAt: now,
      updatedAt: now,
    );
    await documents.saveParsed(document, const <DocumentSection>[
      DocumentSection(
        id: 'page-1',
        documentId: 'document',
        index: 1,
        kind: 'page',
        locator: 'page:1',
        plainText: 'Page one',
      ),
    ]);

    await documents.delete('document');

    expect(await documents.byId('document'), isNull);
    expect(await documents.sections('document'), isEmpty);
  });
}
