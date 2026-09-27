import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:agentflow/core/document/document_parser.dart';
import 'package:agentflow/core/document/epub_parser.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a minimal valid EPUB 2 archive with the given chapters.
Uint8List buildTestEpub({
  String title = 'Test Book',
  String author = 'Test Author',
  String language = 'en',
  required List<_Chapter> chapters,
  bool includeNcx = true,
}) {
  final archive = Archive();

  // mimetype must be first and uncompressed.
  final mimeContent = utf8.encode('application/epub+zip');
  archive.addFile(
    ArchiveFile('mimetype', mimeContent.length, mimeContent)..compress = false,
  );

  // META-INF/container.xml
  final containerContent = utf8.encode('''<?xml version="1.0" encoding="UTF-8"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''');
  archive.addFile(ArchiveFile('META-INF/container.xml', containerContent.length, containerContent));

  // Build manifest and spine items.
  final manifestItems = StringBuffer();
  final spineItems = StringBuffer();
  final ncxNavPoints = StringBuffer();

  for (var i = 0; i < chapters.length; i++) {
    final id = 'chapter$i';
    final href = 'chapter$i.xhtml';
    manifestItems.writeln(
      '    <item id="$id" href="$href" media-type="application/xhtml+xml"/>',
    );
    spineItems.writeln('    <itemref idref="$id"/>');

    if (includeNcx) {
      ncxNavPoints.writeln('''
    <navPoint id="nav$i" playOrder="${i + 1}">
      <navLabel><text>${chapters[i].title}</text></navLabel>
      <content src="$href"/>
    </navPoint>''');
    }

    // Chapter XHTML.
    archive.addFile(
      ArchiveFile(
        'OEBPS/$href',
        true,
        utf8.encode('''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>${chapters[i].title}</title></head>
<body>
  <h1>${chapters[i].title}</h1>
  <p>${chapters[i].body}</p>
</body>
</html>'''),
      ),
    );
  }

  if (includeNcx) {
    manifestItems.writeln(
      '    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>',
    );
  }

  // content.opf
  archive.addFile(
    ArchiveFile(
      'OEBPS/content.opf',
      true,
      utf8.encode('''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:creator>$author</dc:creator>
    <dc:language>$language</dc:language>
    <dc:identifier id="uid">test-epub-123</dc:identifier>
  </metadata>
  <manifest>
$manifestItems  </manifest>
  <spine${includeNcx ? ' toc="ncx"' : ''}>
$spineItems  </spine>
</package>'''),
    ),
  );

  // NCX
  if (includeNcx) {
    archive.addFile(
      ArchiveFile(
        'OEBPS/toc.ncx',
        true,
        utf8.encode('''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head><meta name="dtb:uid" content="test-epub-123"/></head>
  <docTitle><text>$title</text></docTitle>
  <navMap>
$ncxNavPoints
  </navMap>
</ncx>'''),
      ),
    );
  }

  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

class _Chapter {
  const _Chapter(this.title, this.body);
  final String title;
  final String body;
}

void main() {
  late Directory tempDir;
  late EpubDocumentParser parser;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('epub-parser-test-');
    parser = EpubDocumentParser();
  });

  tearDown(() => tempDir.delete(recursive: true));

  test('supports .epub extension and mime type', () {
    expect(parser.supports(extension: '.epub', mimeType: ''), isTrue);
    expect(
      parser.supports(extension: '', mimeType: 'application/epub+zip'),
      isTrue,
    );
    expect(parser.supports(extension: '.pdf', mimeType: ''), isFalse);
  });

  test('parses metadata, TOC, and chapter text from a valid EPUB', () async {
    final epubBytes = buildTestEpub(
      title: 'My Book',
      author: 'Jane Doe',
      language: 'en',
      chapters: const <_Chapter>[
        _Chapter('Introduction', 'Welcome to the book.'),
        _Chapter('Chapter One', 'This is the first chapter content.'),
        _Chapter('Conclusion', 'Thank you for reading.'),
      ],
    );

    final epubPath = '${tempDir.path}/test.epub';
    await File(epubPath).writeAsBytes(epubBytes);

    final progress = <DocumentParseProgress>[];
    final result = await parser.parse(
      epubPath,
      onProgress: progress.add,
    );

    expect(result.title, 'My Book');
    expect(result.author, 'Jane Doe');
    expect(result.language, 'en');
    expect(result.sections, hasLength(3));
    expect(result.requiresOcr, isFalse);

    // First chapter.
    expect(result.sections[0].kind, 'chapter');
    expect(result.sections[0].title, 'Introduction');
    expect(result.sections[0].locator, 'OEBPS/chapter0.xhtml');
    expect(result.sections[0].plainText, contains('Welcome to the book'));

    // Second chapter.
    expect(result.sections[1].title, 'Chapter One');
    expect(
      result.sections[1].plainText,
      contains('first chapter content'),
    );

    // Progress callbacks.
    expect(progress, hasLength(3));
    expect(progress.last.fraction, 1.0);
  });

  test('handles EPUB without NCX TOC gracefully', () async {
    final epubBytes = buildTestEpub(
      title: 'No TOC Book',
      chapters: const <_Chapter>[
        _Chapter('Solo Chapter', 'Only chapter here.'),
      ],
      includeNcx: false,
    );

    final epubPath = '${tempDir.path}/no_toc.epub';
    await File(epubPath).writeAsBytes(epubBytes);

    final result = await parser.parse(epubPath);
    expect(result.sections, hasLength(1));
    expect(result.sections[0].plainText, contains('Only chapter here'));
  });

  test('strips HTML tags from XHTML content', () async {
    final archive = Archive();
    archive.addFile(
      ArchiveFile('mimetype', false, utf8.encode('application/epub+zip'))
        ..compress = false,
    );
    archive.addFile(
      ArchiveFile(
        'META-INF/container.xml',
        true,
        utf8.encode('''<?xml version="1.0"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>'''),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'OEBPS/content.opf',
        true,
        utf8.encode('''<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>HTML Test</dc:title>
    <dc:language>en</dc:language>
    <dc:identifier id="uid">test-456</dc:identifier>
  </metadata>
  <manifest>
    <item id="ch0" href="ch0.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ch0"/>
  </spine>
</package>'''),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'OEBPS/ch0.xhtml',
        true,
        utf8.encode('''<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Test</title></head>
<body>
  <h1>Title</h1>
  <p>Some <b>bold</b> and <i>italic</i> text.</p>
  <script>alert('evil');</script>
  <style>.hidden { display: none; }</style>
  <p>Clean paragraph.</p>
</body>
</html>'''),
      ),
    );

    final epubBytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
    final epubPath = '${tempDir.path}/html_test.epub';
    await File(epubPath).writeAsBytes(epubBytes);

    final result = await parser.parse(epubPath);
    final text = result.sections[0].plainText;

    expect(text, contains('bold'));
    expect(text, contains('italic'));
    expect(text, contains('Clean paragraph'));
    expect(text, isNot(contains('alert')));
    expect(text, isNot(contains('.hidden')));
  });

  test('throws on empty EPUB file', () async {
    final epubPath = '${tempDir.path}/empty.epub';
    await File(epubPath).writeAsBytes(const <int>[]);

    expect(
      () => parser.parse(epubPath),
      throwsA(isA<FormatException>()),
    );
  });

  test('throws on invalid ZIP content', () async {
    final epubPath = '${tempDir.path}/bad.epub';
    await File(epubPath).writeAsString('not a zip file');

    expect(() => parser.parse(epubPath), throwsA(anything));
  });
}
