/// EPUB 2/3 parser: container, OPF, spine, NCX/NAV, XHTML text extraction.
///
/// Each spine item becomes a [ParsedDocumentSection] with `kind: 'chapter'`
/// and `locator: '<href>'`. When an NCX or NAV TOC is available the section
/// title comes from the TOC label; otherwise the XHTML `<title>` or `<h1>` is
/// used. The parser handles EPUB 2 (NCX) and EPUB 3 (NAV document) table of
/// contents.
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'document.dart';
import 'document_parser.dart';

class EpubDocumentParser implements DocumentParser {
  @override
  DocumentType get type => DocumentType.epub;

  @override
  bool supports({required String extension, required String mimeType}) {
    return extension == '.epub' || mimeType == 'application/epub+zip';
  }

  @override
  Future<ParsedDocument> parse(
    String localPath, {
    void Function(DocumentParseProgress progress)? onProgress,
  }) async {
    final bytes = await File(localPath).readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('EPUB file is empty.');
    }

    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Locate OPF via container.xml.
    final opfPath = _findOpfPath(archive);
    final opfContent = _readEntryAsText(archive, opfPath);
    if (opfContent == null) {
      throw FormatException('Cannot read OPF at $opfPath.');
    }
    final opfDocument = XmlDocument.parse(opfContent);
    final opfDir = _directoryPart(opfPath);

    // 2. Metadata.
    final title = _metadataText(opfDocument, 'title');
    final author = _metadataText(opfDocument, 'creator');
    final language = _metadataText(opfDocument, 'language');

    // 3. Manifest: id → (href, mediaType).
    final manifest = _parseManifest(opfDocument, opfDir);

    // 4. Spine order.
    final spineIds = _parseSpine(opfDocument);
    if (spineIds.isEmpty) {
      throw const FormatException('EPUB spine is empty.');
    }

    // 5. TOC (NCX or NAV) for section titles.
    final tocTitles = _parseToc(archive, opfDocument, manifest, opfDir);

    // 6. Extract text from each spine item.
    final sections = <ParsedDocumentSection>[];
    for (var i = 0; i < spineIds.length; i++) {
      final manifestId = spineIds[i];
      final entry = manifest[manifestId];
      if (entry == null) continue;

      final xhtmlBytes = _readEntryBytes(archive, entry.href);
      final plainText = xhtmlBytes != null
          ? _stripHtml(utf8.decode(xhtmlBytes, allowMalformed: true))
          : '';

      sections.add(
        ParsedDocumentSection(
          index: sections.length,
          kind: 'chapter',
          locator: entry.href,
          plainText: plainText,
          title: tocTitles[entry.href] ?? '',
          metadata: <String, dynamic>{
            'mediaType': entry.mediaType,
            'manifestId': manifestId,
          },
        ),
      );

      onProgress?.call(
        DocumentParseProgress(
          completed: i + 1,
          total: spineIds.length,
          message: 'Parsed chapter ${i + 1} of ${spineIds.length}',
        ),
      );
    }

    return ParsedDocument(
      title: title,
      author: author,
      language: language,
      pageCount: sections.length,
      sections: sections,
    );
  }
}

// ---------------------------------------------------------------------------
// OPF / container helpers
// ---------------------------------------------------------------------------

String _findOpfPath(Archive archive) {
  final containerEntry = _findEntry(archive, 'META-INF/container.xml');
  if (containerEntry == null) {
    throw const FormatException('Missing META-INF/container.xml.');
  }
  final containerXml = XmlDocument.parse(
    utf8.decode(containerEntry.content as List<int>, allowMalformed: true),
  );
  // Look for rootfile with media-type application/oebps-package+xml
  for (final rootfile in containerXml.findAllElements('rootfile')) {
    final fullPath = rootfile.getAttribute('full-path');
    if (fullPath != null && fullPath.isNotEmpty) return fullPath;
  }
  throw const FormatException('No rootfile in container.xml.');
}

Map<String, _ManifestEntry> _parseManifest(XmlDocument opf, String opfDir) {
  final manifest = <String, _ManifestEntry>{};
  for (final item in opf.findAllElements('item')) {
    final id = item.getAttribute('id');
    final href = item.getAttribute('href');
    final mediaType = item.getAttribute('media-type') ?? '';
    if (id == null || href == null) continue;
    manifest[id] = _ManifestEntry(
      href: _resolveHref(opfDir, href),
      mediaType: mediaType,
    );
  }
  return manifest;
}

List<String> _parseSpine(XmlDocument opf) {
  final spineIds = <String>[];
  for (final itemref in opf.findAllElements('itemref')) {
    final idref = itemref.getAttribute('idref');
    if (idref != null && idref.isNotEmpty) spineIds.add(idref);
  }
  return spineIds;
}

// ---------------------------------------------------------------------------
// TOC: NCX (EPUB 2) and NAV (EPUB 3)
// ---------------------------------------------------------------------------

Map<String, String> _parseToc(
  Archive archive,
  XmlDocument opf,
  Map<String, _ManifestEntry> manifest,
  String opfDir,
) {
  final toc = <String, String>{};

  // Try NCX first (EPUB 2).
  final ncxId = _findNcxManifestId(opf);
  if (ncxId != null) {
    final ncxEntry = manifest[ncxId];
    if (ncxEntry != null) {
      final ncxBytes = _readEntryBytes(archive, ncxEntry.href);
      if (ncxBytes != null) {
        _parseNcxToc(utf8.decode(ncxBytes, allowMalformed: true), toc, opfDir);
      }
    }
  }

  // Try NAV document (EPUB 3).
  final navId = _findNavManifestId(opf);
  if (navId != null) {
    final navEntry = manifest[navId];
    if (navEntry != null) {
      final navBytes = _readEntryBytes(archive, navEntry.href);
      if (navBytes != null) {
        _parseNavToc(utf8.decode(navBytes, allowMalformed: true), toc, opfDir);
      }
    }
  }

  return toc;
}

String? _findNcxManifestId(XmlDocument opf) {
  // Look for spine toc attribute.
  for (final spine in opf.findAllElements('spine')) {
    final toc = spine.getAttribute('toc');
    if (toc != null && toc.isNotEmpty) return toc;
  }
  // Fallback: look for manifest item with NCX media type.
  for (final item in opf.findAllElements('item')) {
    if (item.getAttribute('media-type') == 'application/x-dtbncx+xml') {
      return item.getAttribute('id');
    }
  }
  return null;
}

String? _findNavManifestId(XmlDocument opf) {
  for (final item in opf.findAllElements('item')) {
    final properties = item.getAttribute('properties') ?? '';
    if (properties.split(' ').contains('nav')) {
      return item.getAttribute('id');
    }
  }
  return null;
}

void _parseNcxToc(String ncxContent, Map<String, String> toc, String opfDir) {
  final doc = XmlDocument.parse(ncxContent);
  for (final navPoint in doc.findAllElements('navPoint')) {
    final label = navPoint
            .findAllElements('navLabel')
            .firstOrNull
            ?.findAllElements('text')
            .firstOrNull
            ?.innerText
            .trim() ??
        '';
    final src = navPoint
        .findAllElements('content')
        .firstOrNull
        ?.getAttribute('src');
    if (src != null && src.isNotEmpty && label.isNotEmpty) {
      // Strip fragment identifier for href matching.
      final href = _resolveHref(opfDir, src.split('#').first);
      toc[href] = label;
    }
  }
}

void _parseNavToc(String navContent, Map<String, String> toc, String opfDir) {
  final doc = XmlDocument.parse(navContent);
  // EPUB 3 NAV uses <nav epub:type="toc"> with <a> links.
  for (final nav in doc.findAllElements('nav')) {
    final epubType = nav.getAttribute('epub:type') ??
        nav.getAttribute('type') ??
        '';
    if (!epubType.contains('toc')) continue;
    for (final anchor in nav.findAllElements('a')) {
      final label = anchor.innerText.trim();
      final href = anchor.getAttribute('href');
      if (href != null && href.isNotEmpty && label.isNotEmpty) {
        final resolved = _resolveHref(opfDir, href.split('#').first);
        toc[resolved] = label;
      }
    }
  }
}

// ---------------------------------------------------------------------------
// XHTML text extraction
// ---------------------------------------------------------------------------

/// Strips HTML/XML tags, decodes entities and collapses whitespace to produce
/// readable plain text from XHTML content.
String _stripHtml(String xhtml) {
  try {
    final doc = XmlDocument.parse(xhtml);
    // Remove script and style elements entirely.
    for (final tag in ['script', 'style']) {
      for (final element in doc.findAllElements(tag).toList()) {
        element.remove();
      }
    }
    final body =
        doc.findAllElements('body').firstOrNull ?? doc.rootElement;
    return _collapseWhitespace(body.innerText);
  } catch (_) {
    // Fallback: regex-based tag stripping for malformed XHTML.
    final stripped = xhtml
        .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ');
    return _collapseWhitespace(_decodeEntities(stripped));
  }
}

String _collapseWhitespace(String text) {
  return text
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

String _decodeEntities(String text) {
  return text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#160;', ' ')
      .replaceAll('&nbsp;', ' ');
}

// ---------------------------------------------------------------------------
// Archive helpers
// ---------------------------------------------------------------------------

ArchiveFile? _findEntry(Archive archive, String path) {
  final normalized = path.replaceAll('\\', '/');
  for (final file in archive) {
    if (file.isFile && file.name.replaceAll('\\', '/') == normalized) {
      return file;
    }
  }
  return null;
}

String? _readEntryAsText(Archive archive, String path) {
  final entry = _findEntry(archive, path);
  if (entry == null) return null;
  return utf8.decode(entry.content as List<int>, allowMalformed: true);
}

List<int>? _readEntryBytes(Archive archive, String path) {
  final entry = _findEntry(archive, path);
  if (entry == null) return null;
  return entry.content as List<int>;
}

/// Returns the directory part of a ZIP path, e.g. `OEBPS/content.opf` → `OEBPS/`.
String _directoryPart(String path) {
  final slash = path.lastIndexOf('/');
  return slash >= 0 ? path.substring(0, slash + 1) : '';
}

/// Resolves a relative href against the OPF directory.
String _resolveHref(String opfDir, String href) {
  if (href.startsWith('/')) return href.substring(1);
  return '$opfDir$href';
}

/// Simple manifest entry holder.
class _ManifestEntry {
  const _ManifestEntry({required this.href, required this.mediaType});
  final String href;
  final String mediaType;
}

// ---------------------------------------------------------------------------
// Metadata helper
// ---------------------------------------------------------------------------

/// Extracts text from the first matching `<dc:tag>` in OPF metadata, searching
/// both namespaced and local-name forms for robustness.
String _metadataText(XmlDocument opf, String tag) {
  // Try standard dc: prefix.
  for (final element in opf.findAllElements('dc:$tag')) {
    final text = element.innerText.trim();
    if (text.isNotEmpty) return text;
  }
  // Try Dublin Core namespace directly.
  for (final element in opf.findAllElements(tag)) {
    if (element.name.namespaceUri == 'http://purl.org/dc/elements/1.1/' ||
        element.name.local == tag) {
      final text = element.innerText.trim();
      if (text.isNotEmpty) return text;
    }
  }
  return '';
}
