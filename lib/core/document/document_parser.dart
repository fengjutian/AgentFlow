library;

import 'document.dart';

class ParsedDocument {
  const ParsedDocument({
    required this.sections,
    this.title = '',
    this.author = '',
    this.language = '',
    this.pageCount = 0,
    this.requiresOcr = false,
  });

  final String title;
  final String author;
  final String language;
  final int pageCount;
  final bool requiresOcr;
  final List<ParsedDocumentSection> sections;
}

class ParsedDocumentSection {
  const ParsedDocumentSection({
    required this.index,
    required this.kind,
    required this.locator,
    required this.plainText,
    this.parentIndex,
    this.title = '',
    this.metadata = const <String, dynamic>{},
  });

  final int index;
  final int? parentIndex;
  final String kind;
  final String title;
  final String locator;
  final String plainText;
  final Map<String, dynamic> metadata;
}

class DocumentParseProgress {
  const DocumentParseProgress({
    required this.completed,
    required this.total,
    this.message = '',
  });

  final int completed;
  final int total;
  final String message;

  double get fraction => total <= 0 ? 0 : (completed / total).clamp(0, 1);
}

abstract class DocumentParser {
  DocumentType get type;

  bool supports({required String extension, required String mimeType});

  Future<ParsedDocument> parse(
    String localPath, {
    void Function(DocumentParseProgress progress)? onProgress,
  });
}

class DocumentParserRegistry {
  DocumentParserRegistry({Iterable<DocumentParser> parsers = const []})
    : _parsers = List<DocumentParser>.of(parsers);

  final List<DocumentParser> _parsers;

  void register(DocumentParser parser) => _parsers.add(parser);

  DocumentParser? find({required String extension, required String mimeType}) {
    final normalizedExtension = extension.toLowerCase();
    final normalizedMimeType = mimeType.toLowerCase();
    for (final parser in _parsers) {
      if (parser.supports(
        extension: normalizedExtension,
        mimeType: normalizedMimeType,
      )) {
        return parser;
      }
    }
    return null;
  }
}

class UnsupportedDocumentException implements Exception {
  const UnsupportedDocumentException(this.message);

  final String message;

  @override
  String toString() => message;
}
