import 'dart:io';

import 'package:agentflow/core/document/document.dart';
import 'package:agentflow/core/document/document_service.dart';
import 'package:agentflow/runtime/local_runtime.dart';
import 'package:agentflow/tools/agent_tool.dart';
import 'package:agentflow/tools/document/document_tools.dart';
import 'package:flutter_test/flutter_test.dart';

class _DocumentStore implements DocumentStore {
  _DocumentStore(this.document, this.sectionData);

  final AgentDocument document;
  final List<DocumentSection> sectionData;

  @override
  Future<List<AgentDocument>> forWorkspace(String workspaceId) async =>
      document.workspaceId == workspaceId
      ? <AgentDocument>[document]
      : <AgentDocument>[];

  @override
  Future<AgentDocument?> byId(String id) async =>
      id == document.id ? document : null;

  @override
  Future<AgentDocument?> byHash(String workspaceId, String contentHash) async =>
      null;

  @override
  Future<List<DocumentSection>> sections(String documentId) async =>
      documentId == document.id ? sectionData : <DocumentSection>[];

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
  }) async {
    final sections = await this.sections(documentId);
    final needle = query.toLowerCase();
    final hits = <DocumentSearchHit>[];
    for (final section in sections) {
      final offset = section.plainText.toLowerCase().indexOf(needle);
      if (offset < 0) continue;
      hits.add(
        DocumentSearchHit(
          index: section.index,
          title: section.title,
          locator: section.locator,
          snippet: section.plainText.substring(
            (offset - 40).clamp(0, section.plainText.length),
            (offset + query.length + 80).clamp(0, section.plainText.length),
          ).trim(),
        ),
      );
      if (hits.length >= limit) break;
    }
    return hits;
  }
}

void main() {
  late Directory root;
  late ToolContext context;
  late List<AgentTool> tools;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('agentflow-doc-tools-');
    final now = DateTime.utc(2026);
    final document = AgentDocument(
      id: 'guide',
      workspaceId: 'workspace',
      displayName: 'guide.epub',
      sourceUri: 'guide.epub',
      localPath: 'guide.epub',
      type: DocumentType.epub,
      fileSize: 100,
      contentHash: 'hash',
      title: 'Agent Guide',
      author: 'AgentFlow',
      sectionCount: 2,
      parseStatus: DocumentParseStatus.ready,
      createdAt: now,
      updatedAt: now,
    );
    final store = _DocumentStore(document, const <DocumentSection>[
      DocumentSection(
        id: 'intro',
        documentId: 'guide',
        index: 0,
        kind: 'chapter',
        title: 'Introduction',
        locator: 'intro.xhtml',
        plainText: 'AgentFlow reads documents and answers questions.',
      ),
      DocumentSection(
        id: 'tools',
        documentId: 'guide',
        index: 1,
        kind: 'chapter',
        title: 'Tools',
        locator: 'tools.xhtml',
        plainText: 'Document tools preserve a source locator.',
      ),
    ]);
    tools = documentTools(store);
    context = ToolContext(
      runtime: LocalRuntime(rootDirectory: root.path),
      workingDirectory: root.path,
      workspaceId: 'workspace',
    );
  });

  tearDown(() => root.delete(recursive: true));

  AgentTool tool(String name) => tools.singleWhere((tool) => tool.name == name);

  test('lists workspace documents with structured metadata', () async {
    final result = await tool(
      'list_documents',
    ).execute(<String, dynamic>{'query': 'guide'}, context);

    expect(result.content, contains('Agent Guide'));
    expect(result.data!['documents'], hasLength(1));
  });

  test('returns document outline with locators', () async {
    final result = await tool(
      'get_document_info',
    ).execute(<String, dynamic>{'document_id': 'guide'}, context);

    expect(result.content, contains('intro.xhtml'));
    expect(result.data!['sections'], hasLength(2));
  });

  test('reads an inclusive section range with source markers', () async {
    final result = await tool('read_document_section').execute(
      <String, dynamic>{'document_id': 'guide', 'start': 1, 'end': 1},
      context,
    );

    expect(result.content, contains('[tools.xhtml]'));
    expect(result.content, isNot(contains('[intro.xhtml]')));
  });

  test('searches case-insensitively and returns source locators', () async {
    final result = await tool('search_document').execute(<String, dynamic>{
      'document_id': 'guide',
      'query': 'SOURCE LOCATOR',
    }, context);

    expect(result.content, contains('[tools.xhtml]'));
    expect(result.data!['matches'], hasLength(1));
  });

  test('does not expose a document from another workspace', () async {
    final otherContext = ToolContext(
      runtime: context.runtime,
      workingDirectory: root.path,
      workspaceId: 'other',
    );

    await expectLater(
      tool(
        'get_document_info',
      ).execute(<String, dynamic>{'document_id': 'guide'}, otherContext),
      throwsA(isA<ToolExecutionException>()),
    );
  });
}
