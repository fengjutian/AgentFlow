library;

import '../../core/document/document.dart';
import '../../core/document/document_service.dart';
import '../../core/message.dart';
import '../agent_tool.dart';
import '../tool_args.dart';

List<AgentTool> documentTools(DocumentStore store) => <AgentTool>[
  ListDocumentsTool(store),
  GetDocumentInfoTool(store),
  ReadDocumentSectionTool(store),
  SearchDocumentTool(store),
];

abstract class _DocumentTool extends ReadOnlyTool {
  _DocumentTool(this.store);

  final DocumentStore store;

  String workspaceId(ToolContext context) {
    final value = context.workspaceId;
    if (value == null || value.isEmpty) {
      throw const ToolExecutionException(
        'Document tools require an active workspace.',
      );
    }
    return value;
  }

  Future<AgentDocument> documentForWorkspace(
    String id,
    ToolContext context,
  ) async {
    final document = await store.byId(id);
    if (document == null || document.workspaceId != workspaceId(context)) {
      throw ToolExecutionException('Document "$id" was not found.');
    }
    return document;
  }
}

class ListDocumentsTool extends _DocumentTool {
  ListDocumentsTool(super.store);

  @override
  String get name => 'list_documents';

  @override
  String get description =>
      'List imported PDF and EPUB documents in the active workspace. '
      'Optionally filter by title/name query or type.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'query': <String, dynamic>{'type': 'string'},
      'type': <String, dynamic>{
        'type': 'string',
        'enum': <String>['pdf', 'epub'],
      },
    },
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final query = optionalString(arguments, 'query').trim().toLowerCase();
    final type = optionalString(arguments, 'type').trim().toLowerCase();
    final all = await store.forWorkspace(workspaceId(context));
    final documents = all.where((document) {
      if (type.isNotEmpty && document.type.name != type) return false;
      if (query.isEmpty) return true;
      return document.displayName.toLowerCase().contains(query) ||
          document.title.toLowerCase().contains(query) ||
          document.author.toLowerCase().contains(query);
    }).toList(growable: false);
    final data = documents.map(_documentSummary).toList(growable: false);
    final lines = documents
        .map(
          (document) =>
              '${document.id}  ${document.type.name.toUpperCase()}  '
              '${document.title.isEmpty ? document.displayName : document.title} '
              '[${document.parseStatus.name}]',
        )
        .join('\n');
    return ToolResult(
      toolCallId: '',
      name: name,
      content: documents.isEmpty ? 'No matching documents.' : lines,
      data: <String, dynamic>{'documents': data},
    );
  }
}

class GetDocumentInfoTool extends _DocumentTool {
  GetDocumentInfoTool(super.store);

  @override
  String get name => 'get_document_info';

  @override
  String get description =>
      'Get metadata and the ordered table of contents for an imported document.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'document_id': <String, dynamic>{'type': 'string'},
    },
    'required': <String>['document_id'],
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final id = requireString(arguments, 'document_id');
    final document = await documentForWorkspace(id, context);
    final sections = await store.sections(id);
    final outline = sections
        .map(
          (section) =>
              '${section.index}: ${section.title.isEmpty ? section.locator : section.title} '
              '(${section.locator})',
        )
        .join('\n');
    return ToolResult(
      toolCallId: '',
      name: name,
      content: clampOutput(
        '${document.title.isEmpty ? document.displayName : document.title}\n'
        'Type: ${document.type.name}\n'
        'Author: ${document.author.isEmpty ? '(unknown)' : document.author}\n'
        'Status: ${document.parseStatus.name}\n'
        'Pages: ${document.pageCount}\n'
        'Sections: ${document.sectionCount}\n\n'
        'Contents:\n$outline',
      ),
      data: <String, dynamic>{
        'document': _documentSummary(document),
        'sections': sections.map(_sectionSummary).toList(growable: false),
      },
    );
  }
}

class ReadDocumentSectionTool extends _DocumentTool {
  ReadDocumentSectionTool(super.store);

  @override
  String get name => 'read_document_section';

  @override
  String get description =>
      'Read a range of pages or chapters from an imported document. '
      'Section indexes are inclusive and come from get_document_info.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'document_id': <String, dynamic>{'type': 'string'},
      'start': <String, dynamic>{'type': 'integer', 'minimum': 0},
      'end': <String, dynamic>{'type': 'integer', 'minimum': 0},
      'max_chars': <String, dynamic>{
        'type': 'integer',
        'minimum': 1000,
        'maximum': 24000,
      },
    },
    'required': <String>['document_id', 'start'],
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final id = requireString(arguments, 'document_id');
    await documentForWorkspace(id, context);
    final start = optionalInt(arguments, 'start', fallback: 0);
    final end = optionalInt(arguments, 'end', fallback: start);
    if (start < 0 || end < start) {
      throw const ToolExecutionException(
        'Section range must satisfy 0 <= start <= end.',
      );
    }
    final maxChars = optionalInt(
      arguments,
      'max_chars',
      fallback: 12000,
    ).clamp(1000, 24000);
    final sections = (await store.sections(id))
        .where((section) => section.index >= start && section.index <= end)
        .toList(growable: false);
    if (sections.isEmpty) {
      throw ToolExecutionException(
        'No document sections exist in range $start..$end.',
      );
    }
    final content = sections
        .map(
          (section) =>
              '[${section.locator}]'
              '${section.title.isEmpty ? '' : ' ${section.title}'}\n'
              '${section.plainText}',
        )
        .join('\n\n');
    return ToolResult(
      toolCallId: '',
      name: name,
      content: clampOutput(content, maxChars: maxChars),
      data: <String, dynamic>{
        'documentId': id,
        'start': start,
        'end': end,
        'locators': sections.map((section) => section.locator).toList(),
        'truncated': content.length > maxChars,
      },
    );
  }
}

class SearchDocumentTool extends _DocumentTool {
  SearchDocumentTool(super.store);

  @override
  String get name => 'search_document';

  @override
  String get description =>
      'Search the extracted text of an imported document and return matching '
      'snippets with page or chapter locators.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'document_id': <String, dynamic>{'type': 'string'},
      'query': <String, dynamic>{'type': 'string'},
      'limit': <String, dynamic>{
        'type': 'integer',
        'minimum': 1,
        'maximum': 50,
      },
    },
    'required': <String>['document_id', 'query'],
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final id = requireString(arguments, 'document_id');
    await documentForWorkspace(id, context);
    final query = requireString(arguments, 'query').trim();
    if (query.isEmpty) {
      throw const ToolExecutionException('Search query cannot be empty.');
    }
    final limit = optionalInt(arguments, 'limit', fallback: 10).clamp(1, 50);
    final needle = query.toLowerCase();
    final matches = <Map<String, dynamic>>[];
    for (final section in await store.sections(id)) {
      final lower = section.plainText.toLowerCase();
      final offset = lower.indexOf(needle);
      if (offset < 0) continue;
      final start = (offset - 100).clamp(0, section.plainText.length);
      final end = (offset + query.length + 180).clamp(
        start,
        section.plainText.length,
      );
      matches.add(<String, dynamic>{
        'index': section.index,
        'title': section.title,
        'locator': section.locator,
        'snippet': section.plainText.substring(start, end).trim(),
      });
      if (matches.length >= limit) break;
    }
    final content = matches
        .map(
          (match) =>
              '[${match['locator']}] ${match['title']}\n${match['snippet']}',
        )
        .join('\n\n');
    return ToolResult(
      toolCallId: '',
      name: name,
      content: matches.isEmpty ? 'No matches for "$query".' : content,
      data: <String, dynamic>{
        'documentId': id,
        'query': query,
        'matches': matches,
      },
    );
  }
}

Map<String, dynamic> _documentSummary(AgentDocument document) =>
    <String, dynamic>{
      'id': document.id,
      'name': document.displayName,
      'title': document.title,
      'author': document.author,
      'type': document.type.name,
      'status': document.parseStatus.name,
      'pages': document.pageCount,
      'sections': document.sectionCount,
    };

Map<String, dynamic> _sectionSummary(DocumentSection section) =>
    <String, dynamic>{
      'index': section.index,
      'kind': section.kind,
      'title': section.title,
      'locator': section.locator,
      'characters': section.charCount,
    };

