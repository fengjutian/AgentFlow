import 'package:agentflow/core/editor/syntax_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectLanguage', () {
    test('identifies common extensions', () {
      expect(detectLanguage('main.dart'), CodeLanguage.dart);
      expect(detectLanguage('app.tsx'), CodeLanguage.typescript);
      expect(detectLanguage('index.js'), CodeLanguage.javascript);
      expect(detectLanguage('script.py'), CodeLanguage.python);
      expect(detectLanguage('Main.java'), CodeLanguage.java);
      expect(detectLanguage('App.kt'), CodeLanguage.kotlin);
      expect(detectLanguage('lib.rs'), CodeLanguage.rust);
      expect(detectLanguage('main.go'), CodeLanguage.go);
      expect(detectLanguage('main.cpp'), CodeLanguage.cpp);
      expect(detectLanguage('main.c'), CodeLanguage.c);
      expect(detectLanguage('App.swift'), CodeLanguage.swift);
      expect(detectLanguage('app.rb'), CodeLanguage.ruby);
      expect(detectLanguage('deploy.sh'), CodeLanguage.shell);
      expect(detectLanguage('config.yaml'), CodeLanguage.yaml);
      expect(detectLanguage('config.yml'), CodeLanguage.yaml);
      expect(detectLanguage('data.json'), CodeLanguage.json);
      expect(detectLanguage('page.html'), CodeLanguage.html);
      expect(detectLanguage('styles.css'), CodeLanguage.css);
      expect(detectLanguage('styles.scss'), CodeLanguage.css);
      expect(detectLanguage('query.sql'), CodeLanguage.sql);
      expect(detectLanguage('README.md'), CodeLanguage.markdown);
      expect(detectLanguage('data.xml'), CodeLanguage.xml);
      expect(detectLanguage('Cargo.toml'), CodeLanguage.toml);
    });

    test('returns unknown for unrecognized extensions', () {
      expect(detectLanguage('file.xyz'), CodeLanguage.unknown);
      expect(detectLanguage('file.bin'), CodeLanguage.unknown);
      expect(detectLanguage('file'), CodeLanguage.unknown);
    });

    test('handles nested paths', () {
      expect(detectLanguage('src/lib/main.dart'), CodeLanguage.dart);
      expect(detectLanguage('/home/user/project/app.tsx'), CodeLanguage.typescript);
    });

    test('is case-insensitive for extensions', () {
      expect(detectLanguage('FILE.DART'), CodeLanguage.dart);
      expect(detectLanguage('FILE.PY'), CodeLanguage.python);
    });
  });

  group('highlightSource', () {
    const base = TextStyle(fontFamily: 'monospace', fontSize: 12);
    const colors = SyntaxColors.light;

    test('returns plain span for unknown language', () {
      final span = highlightSource(
        source: 'hello world',
        baseStyle: base,
        language: CodeLanguage.unknown,
        colors: colors,
      );
      expect(span.text, 'hello world');
      expect(span.children, isNull);
    });

    test('returns plain span for empty source', () {
      final span = highlightSource(
        source: '',
        baseStyle: base,
        language: CodeLanguage.dart,
        colors: colors,
      );
      expect(span.text, '');
    });

    test('highlights Dart keywords', () {
      final span = highlightSource(
        source: 'class Foo extends Bar',
        baseStyle: base,
        language: CodeLanguage.dart,
        colors: colors,
      );
      expect(span.children, isNotNull);
      final texts = span.children!.map((s) => s.toPlainText()).toList();
      expect(texts.join(), 'class Foo extends Bar');
      // 'class' should be a keyword
      final classSpan = span.children!.firstWhere(
        (s) => s.toPlainText() == 'class',
      ) as TextSpan;
      expect(classSpan.style?.color, colors.keyword);
    });

    test('highlights strings', () {
      final span = highlightSource(
        source: 'final x = "hello";',
        baseStyle: base,
        language: CodeLanguage.dart,
        colors: colors,
      );
      final stringSpan = span.children!.firstWhere(
        (s) => s.toPlainText() == '"hello"',
      ) as TextSpan;
      expect(stringSpan.style?.color, colors.string);
    });

    test('highlights line comments', () {
      final span = highlightSource(
        source: '// this is a comment\nvar x = 1;',
        baseStyle: base,
        language: CodeLanguage.dart,
        colors: colors,
      );
      final commentSpan = span.children!.firstWhere(
        (s) => s.toPlainText().contains('// this is a comment'),
      ) as TextSpan;
      expect(commentSpan.style?.color, colors.comment);
      expect(commentSpan.style?.fontStyle, FontStyle.italic);
    });

    test('highlights block comments', () {
      final span = highlightSource(
        source: '/* block\ncomment */ var x;',
        baseStyle: base,
        language: CodeLanguage.dart,
        colors: colors,
      );
      final commentSpan = span.children!.firstWhere(
        (s) => s.toPlainText().contains('/* block\ncomment */'),
      ) as TextSpan;
      expect(commentSpan.style?.color, colors.comment);
    });

    test('highlights numbers', () {
      final span = highlightSource(
        source: 'var n = 42;',
        baseStyle: base,
        language: CodeLanguage.dart,
        colors: colors,
      );
      final numSpan = span.children!.firstWhere(
        (s) => s.toPlainText() == '42',
      ) as TextSpan;
      expect(numSpan.style?.color, colors.number);
    });

    test('highlights annotations', () {
      final span = highlightSource(
        source: '@override void build() {}',
        baseStyle: base,
        language: CodeLanguage.dart,
        colors: colors,
      );
      final annoSpan = span.children!.firstWhere(
        (s) => s.toPlainText() == '@override',
      ) as TextSpan;
      expect(annoSpan.style?.color, colors.annotation);
    });

    test('highlights type names', () {
      final span = highlightSource(
        source: 'String name = "foo";',
        baseStyle: base,
        language: CodeLanguage.dart,
        colors: colors,
      );
      final typeSpan = span.children!.firstWhere(
        (s) => s.toPlainText() == 'String',
      ) as TextSpan;
      expect(typeSpan.style?.color, colors.type);
    });

    test('handles Python hash comments', () {
      final span = highlightSource(
        source: '# python comment\nx = 1',
        baseStyle: base,
        language: CodeLanguage.python,
        colors: colors,
      );
      final commentSpan = span.children!.firstWhere(
        (s) => s.toPlainText().contains('# python comment'),
      ) as TextSpan;
      expect(commentSpan.style?.color, colors.comment);
    });

    test('handles SQL double-dash comments', () {
      final span = highlightSource(
        source: '-- sql comment\nSELECT 1',
        baseStyle: base,
        language: CodeLanguage.sql,
        colors: colors,
      );
      final commentSpan = span.children!.firstWhere(
        (s) => s.toPlainText().contains('-- sql comment'),
      ) as TextSpan;
      expect(commentSpan.style?.color, colors.comment);
    });

    test('handles hex numbers', () {
      final span = highlightSource(
        source: 'var x = 0xFF;',
        baseStyle: base,
        language: CodeLanguage.dart,
        colors: colors,
      );
      final hexSpan = span.children!.firstWhere(
        (s) => s.toPlainText() == '0xFF',
      ) as TextSpan;
      expect(hexSpan.style?.color, colors.number);
    });

    test('handles unclosed block comment', () {
      final span = highlightSource(
        source: '/* unclosed comment',
        baseStyle: base,
        language: CodeLanguage.dart,
        colors: colors,
      );
      // Should not throw and should treat the rest as a comment
      final text = span.children!.map((s) => s.toPlainText()).join();
      expect(text, '/* unclosed comment');
      final commentSpan = span.children!.firstWhere(
        (s) => s.toPlainText().contains('/* unclosed'),
      ) as TextSpan;
      expect(commentSpan.style?.color, colors.comment);
    });

    test('handles escape sequences in strings', () {
      final span = highlightSource(
        source: r'var s = "hello \"world\"";',
        baseStyle: base,
        language: CodeLanguage.dart,
        colors: colors,
      );
      // The entire string including escaped quotes should be one token
      final stringSpans = span.children!.where(
        (s) => (s as TextSpan).style?.color == colors.string,
      );
      expect(stringSpans, isNotEmpty);
    });
  });

  group('SyntaxTextEditingController', () {
    test('returns plain span for unknown language', () {
      final controller = SyntaxTextEditingController(
        text: 'hello',
        language: CodeLanguage.unknown,
      );
      // We can't call buildTextSpan without a BuildContext, but we can
      // verify the controller initializes correctly.
      expect(controller.text, 'hello');
      expect(controller.language, CodeLanguage.unknown);
    });

    test('rebuildHighlight does not throw', () {
      final controller = SyntaxTextEditingController(
        text: 'var x = 1;',
        language: CodeLanguage.dart,
      );
      // Should not throw
      controller.rebuildHighlight();
    });

    test('language can be changed at runtime', () {
      final controller = SyntaxTextEditingController(
        text: 'function foo() {}',
        language: CodeLanguage.javascript,
      );
      controller.language = CodeLanguage.typescript;
      expect(controller.language, CodeLanguage.typescript);
    });
  });
}
