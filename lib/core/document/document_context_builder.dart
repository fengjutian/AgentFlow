/// Builds compact document context for the Agent prompt.
///
/// When the Agent is working with documents it needs a summary of available
/// documents and their structure without flooding the context window. This
/// builder assembles:
///
/// - A document list with title, type, status and size.
/// - A table of contents for the active document.
/// - The text of a specific section, truncated to a configurable limit.
///
/// The Agent can call `buildWorkspaceSummary` to get an overview, then use
/// `buildSectionContext` for deeper reads.
library;

import 'document.dart';
import 'document_service.dart';

class DocumentContextBuilder {
  DocumentContextBuilder({required this.store, this.maxSectionChars = 8000});

  final DocumentStore store;
  final int maxSectionChars;

  /// Returns a compact listing of all documents in [workspaceId].
  Future<String> buildWorkspaceSummary(String workspaceId) async {
    final documents = await store.forWorkspace(workspaceId);
    if (documents.isEmpty) return 'No imported documents.';
    final lines = documents.map((document) {
      final label = document.title.isEmpty
          ? document.displayName
          : document.title;
      final pages = document.pageCount > 0
          ? '${document.pageCount} pages'
          : '${document.sectionCount} sections';
      return '- ${document.id}: $label '
          '(${document.type.name.toUpperCase()}, $pages, '
          '${document.parseStatus.name})';
    });
    return 'Documents:\n${lines.join('\n')}';
  }

  /// Returns the table of contents and metadata for [documentId].
  Future<String> buildDocumentContext(String documentId) async {
    final document = await store.byId(documentId);
    if (document == null) return 'Document not found.';
    final sections = await store.sections(documentId);
    final title = document.title.isEmpty
        ? document.displayName
        : document.title;
    final buffer = StringBuffer()
      ..writeln('$title (${document.type.name.toUpperCase()})')
      ..writeln('Author: ${document.author.isEmpty ? '(unknown)' : document.author}')
      ..writeln('Status: ${document.parseStatus.name}')
      ..writeln('Sections: ${sections.length}')
      ..writeln();
    for (final section in sections) {
      final label = section.title.isEmpty ? section.locator : section.title;
      buffer.writeln('  ${section.index}: $label (${section.locator})');
    }
    return buffer.toString();
  }

  /// Returns the text of sections in the range `[start, end]` (inclusive),
  /// truncated to [maxSectionChars].
  Future<String> buildSectionContext(
    String documentId, {
    int start = 0,
    int end = 0,
  }) async {
    final sections = (await store.sections(documentId))
        .where((section) => section.index >= start && section.index <= end)
        .toList(growable: false);
    if (sections.isEmpty) return 'No sections in range $start..$end.';
    final buffer = StringBuffer();
    var remaining = maxSectionChars;
    for (final section in sections) {
      if (remaining <= 0) {
        buffer.writeln('\n... [truncated] ...');
        break;
      }
      buffer
        ..writeln('[${section.locator}] ${section.title}')
        ..writeln();
      final text = section.plainText;
      if (text.length <= remaining) {
        buffer.writeln(text);
        remaining -= text.length;
      } else {
        buffer.writeln(text.substring(0, remaining));
        buffer.writeln('... [truncated] ...');
        remaining = 0;
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }
}
