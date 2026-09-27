/// PDF text extraction using Syncfusion's pure-Dart PDF engine.
///
/// Each page becomes one [ParsedDocumentSection] with `kind: 'page'` and
/// `locator: 'page:<n>'`. Pages that yield only whitespace are still included
/// so the Agent can report "page N has no extractable text". When every page
/// is blank the document is flagged `requiresOcr`.
library;

import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'document.dart';
import 'document_parser.dart';

class PdfDocumentParser implements DocumentParser {
  @override
  DocumentType get type => DocumentType.pdf;

  @override
  bool supports({required String extension, required String mimeType}) {
    return extension == '.pdf' ||
        mimeType == 'application/pdf' ||
        mimeType.endsWith('/pdf');
  }

  @override
  Future<ParsedDocument> parse(
    String localPath, {
    void Function(DocumentParseProgress progress)? onProgress,
  }) async {
    final bytes = await File(localPath).readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('PDF file is empty.');
    }

    final document = PdfDocument(inputBytes: bytes);
    try {
      final info = document.documentInformation;
      final pageCount = document.pages.count;
      final extractor = PdfTextExtractor(document);
      final sections = <ParsedDocumentSection>[];
      var hasText = false;

      for (var i = 0; i < pageCount; i++) {
        final text = _safeExtractPage(extractor, i);
        if (text.trim().isNotEmpty) hasText = true;
        sections.add(
          ParsedDocumentSection(
            index: i,
            kind: 'page',
            locator: 'page:${i + 1}',
            plainText: text,
            title: 'Page ${i + 1}',
            metadata: <String, dynamic>{'pageNumber': i + 1},
          ),
        );
        onProgress?.call(
          DocumentParseProgress(
            completed: i + 1,
            total: pageCount,
            message: 'Extracted page ${i + 1} of $pageCount',
          ),
        );
      }

      return ParsedDocument(
        title: info.title,
        author: info.author,
        pageCount: pageCount,
        requiresOcr: !hasText && pageCount > 0,
        sections: sections,
      );
    } finally {
      document.dispose();
    }
  }

  /// Extracts text from a single page, returning empty string on failure
  /// rather than throwing — a corrupt page should not block the whole document.
  String _safeExtractPage(PdfTextExtractor extractor, int pageIndex) {
    try {
      return extractor.extractText(
        startPageIndex: pageIndex,
        endPageIndex: pageIndex,
      );
    } catch (_) {
      return '';
    }
  }
}
