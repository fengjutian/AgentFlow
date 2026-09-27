/// Lightweight regex-based syntax highlighter for the code editor.
///
/// Supports a practical subset of languages encountered in coding-agent
/// workspaces. The highlighter is intentionally simple — keyword/string/comment
/// tokenization — rather than a full AST, keeping it fast enough to run on
/// every keystroke for files up to a few thousand lines.
library;

import 'package:flutter/material.dart';

/// Detected programming language, used to select keywords and comment styles.
enum CodeLanguage {
  dart,
  javascript,
  typescript,
  python,
  java,
  kotlin,
  rust,
  go,
  cpp,
  c,
  swift,
  ruby,
  shell,
  yaml,
  json,
  html,
  css,
  sql,
  markdown,
  xml,
  toml,
  unknown,
}

/// Maps a file extension (without the dot) to a [CodeLanguage].
CodeLanguage detectLanguage(String filePath) {
  final ext = filePath.split('.').last.toLowerCase();
  return switch (ext) {
    'dart' => CodeLanguage.dart,
    'js' || 'mjs' || 'cjs' || 'jsx' => CodeLanguage.javascript,
    'ts' || 'tsx' || 'mts' || 'cts' => CodeLanguage.typescript,
    'py' || 'pyw' || 'pyi' => CodeLanguage.python,
    'java' => CodeLanguage.java,
    'kt' || 'kts' => CodeLanguage.kotlin,
    'rs' => CodeLanguage.rust,
    'go' => CodeLanguage.go,
    'cpp' || 'cc' || 'cxx' || 'hpp' || 'hxx' => CodeLanguage.cpp,
    'c' || 'h' => CodeLanguage.c,
    'swift' => CodeLanguage.swift,
    'rb' || 'rake' || 'gemspec' => CodeLanguage.ruby,
    'sh' || 'bash' || 'zsh' || 'fish' => CodeLanguage.shell,
    'yaml' || 'yml' => CodeLanguage.yaml,
    'json' || 'jsonc' => CodeLanguage.json,
    'html' || 'htm' => CodeLanguage.html,
    'css' || 'scss' || 'sass' || 'less' => CodeLanguage.css,
    'sql' => CodeLanguage.sql,
    'md' || 'markdown' => CodeLanguage.markdown,
    'xml' || 'svg' || 'xsl' || 'xslt' => CodeLanguage.xml,
    'toml' => CodeLanguage.toml,
    _ => CodeLanguage.unknown,
  };
}

/// Definition of a language's syntax for the tokenizer.
class _LangDef {
  const _LangDef({
    required this.keywords,
    required this.types,
    this.lineComment = '//',
    this.blockCommentStart = '/*',
    this.blockCommentEnd = '*/',
    this.hashComment = false,
  });

  final Set<String> keywords;
  final Set<String> types;
  final String lineComment;
  final String blockCommentStart;
  final String blockCommentEnd;
  final bool hashComment;
}

const Map<CodeLanguage, _LangDef> _langDefs = <CodeLanguage, _LangDef>{
  CodeLanguage.dart: _LangDef(
    keywords: <String>{
      'abstract', 'as', 'async', 'await', 'break', 'case', 'catch', 'class',
      'const', 'continue', 'default', 'deferred', 'do', 'dynamic', 'else',
      'enum', 'export', 'extends', 'extension', 'external', 'factory',
      'false', 'final', 'finally', 'for', 'get', 'hide', 'if', 'implements',
      'import', 'in', 'interface', 'is', 'late', 'library', 'mixin', 'new',
      'null', 'on', 'operator', 'part', 'required', 'rethrow', 'return',
      'sealed', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this',
      'throw', 'true', 'try', 'typedef', 'var', 'void', 'when', 'while',
      'with', 'yield',
    },
    types: <String>{
      'int', 'double', 'num', 'String', 'bool', 'List', 'Map', 'Set',
      'Future', 'Stream', 'Iterable', 'Object', 'dynamic', 'Null', 'Never',
      'Function', 'Type', 'Symbol', 'Record',
    },
  ),
  CodeLanguage.javascript: _LangDef(
    keywords: <String>{
      'async', 'await', 'break', 'case', 'catch', 'class', 'const',
      'continue', 'debugger', 'default', 'delete', 'do', 'else', 'export',
      'extends', 'false', 'finally', 'for', 'from', 'function', 'if',
      'import', 'in', 'instanceof', 'let', 'new', 'null', 'of', 'return',
      'static', 'super', 'switch', 'this', 'throw', 'true', 'try',
      'typeof', 'undefined', 'var', 'void', 'while', 'with', 'yield',
    },
    types: <String>{
      'Array', 'Boolean', 'Date', 'Error', 'Function', 'Map', 'Number',
      'Object', 'Promise', 'RegExp', 'Set', 'String', 'Symbol',
    },
  ),
  CodeLanguage.typescript: _LangDef(
    keywords: <String>{
      'abstract', 'as', 'async', 'await', 'break', 'case', 'catch', 'class',
      'const', 'continue', 'debugger', 'declare', 'default', 'delete', 'do',
      'else', 'enum', 'export', 'extends', 'false', 'finally', 'for', 'from',
      'function', 'if', 'implements', 'import', 'in', 'instanceof',
      'interface', 'keyof', 'let', 'module', 'namespace', 'new', 'null',
      'of', 'override', 'private', 'protected', 'public', 'readonly',
      'return', 'static', 'super', 'switch', 'this', 'throw', 'true', 'try',
      'type', 'typeof', 'undefined', 'var', 'void', 'while', 'with', 'yield',
    },
    types: <String>{
      'any', 'boolean', 'bigint', 'never', 'number', 'object', 'string',
      'symbol', 'unknown', 'void', 'Array', 'Map', 'Promise', 'Record',
      'Partial', 'Required', 'Readonly', 'Pick', 'Omit',
    },
  ),
  CodeLanguage.python: _LangDef(
    keywords: <String>{
      'and', 'as', 'assert', 'async', 'await', 'break', 'class', 'continue',
      'def', 'del', 'elif', 'else', 'except', 'False', 'finally', 'for',
      'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'None',
      'nonlocal', 'not', 'or', 'pass', 'raise', 'return', 'True', 'try',
      'while', 'with', 'yield',
    },
    types: <String>{
      'int', 'float', 'str', 'bool', 'list', 'dict', 'tuple', 'set',
      'bytes', 'type', 'object', 'None',
    },
    lineComment: '#',
    hashComment: true,
  ),
  CodeLanguage.java: _LangDef(
    keywords: <String>{
      'abstract', 'assert', 'break', 'case', 'catch', 'class', 'const',
      'continue', 'default', 'do', 'else', 'enum', 'extends', 'false',
      'final', 'finally', 'for', 'if', 'implements', 'import', 'instanceof',
      'interface', 'native', 'new', 'null', 'package', 'private',
      'protected', 'public', 'return', 'static', 'strictfp', 'super',
      'switch', 'synchronized', 'this', 'throw', 'throws', 'transient',
      'true', 'try', 'void', 'volatile', 'while', 'var', 'record',
      'sealed', 'permits', 'yield',
    },
    types: <String>{
      'boolean', 'byte', 'char', 'double', 'float', 'int', 'long', 'short',
      'void', 'String', 'Integer', 'Long', 'Double', 'Float', 'Boolean',
      'Object', 'List', 'Map', 'Set', 'Optional',
    },
  ),
  CodeLanguage.kotlin: _LangDef(
    keywords: <String>{
      'abstract', 'as', 'break', 'by', 'catch', 'class', 'companion',
      'const', 'constructor', 'continue', 'crossinline', 'data', 'do',
      'else', 'enum', 'expect', 'external', 'false', 'final', 'finally',
      'for', 'fun', 'get', 'if', 'import', 'in', 'infix', 'init',
      'inline', 'inner', 'interface', 'internal', 'is', 'lateinit',
      'noinline', 'null', 'object', 'open', 'operator', 'out', 'override',
      'package', 'private', 'protected', 'public', 'reified', 'return',
      'sealed', 'set', 'super', 'suspend', 'tailrec', 'this', 'throw',
      'true', 'try', 'typealias', 'val', 'var', 'vararg', 'when', 'where',
      'while', 'yield',
    },
    types: <String>{
      'Any', 'Boolean', 'Byte', 'Char', 'Double', 'Float', 'Int', 'Long',
      'Nothing', 'Short', 'String', 'Unit', 'List', 'Map', 'Set',
      'MutableList', 'MutableMap', 'MutableSet', 'Pair', 'Triple',
    },
  ),
  CodeLanguage.rust: _LangDef(
    keywords: <String>{
      'as', 'async', 'await', 'break', 'const', 'continue', 'crate', 'dyn',
      'else', 'enum', 'extern', 'false', 'fn', 'for', 'if', 'impl', 'in',
      'let', 'loop', 'match', 'mod', 'move', 'mut', 'pub', 'ref', 'return',
      'self', 'Self', 'static', 'struct', 'super', 'trait', 'true', 'type',
      'unsafe', 'use', 'where', 'while', 'yield',
    },
    types: <String>{
      'bool', 'char', 'f32', 'f64', 'i8', 'i16', 'i32', 'i64', 'i128',
      'isize', 'str', 'u8', 'u16', 'u32', 'u64', 'u128', 'usize',
      'String', 'Vec', 'Option', 'Result', 'Box', 'Rc', 'Arc',
    },
    lineComment: '//',
  ),
  CodeLanguage.go: _LangDef(
    keywords: <String>{
      'break', 'case', 'chan', 'const', 'continue', 'default', 'defer',
      'else', 'fallthrough', 'for', 'func', 'go', 'goto', 'if', 'import',
      'interface', 'map', 'package', 'range', 'return', 'select', 'struct',
      'switch', 'type', 'var', 'true', 'false', 'nil',
    },
    types: <String>{
      'bool', 'byte', 'complex64', 'complex128', 'error', 'float32',
      'float64', 'int', 'int8', 'int16', 'int32', 'int64', 'rune',
      'string', 'uint', 'uint8', 'uint16', 'uint32', 'uint64', 'uintptr',
      'any',
    },
  ),
  CodeLanguage.cpp: _LangDef(
    keywords: <String>{
      'auto', 'break', 'case', 'catch', 'class', 'const', 'constexpr',
      'continue', 'decltype', 'default', 'delete', 'do', 'else', 'enum',
      'explicit', 'export', 'extern', 'false', 'for', 'friend', 'goto',
      'if', 'inline', 'mutable', 'namespace', 'new', 'noexcept', 'null',
      'nullptr', 'operator', 'override', 'private', 'protected', 'public',
      'return', 'sizeof', 'static', 'struct', 'switch', 'template', 'this',
      'throw', 'true', 'try', 'typedef', 'typeid', 'typename', 'union',
      'using', 'virtual', 'void', 'volatile', 'while',
    },
    types: <String>{
      'bool', 'char', 'double', 'float', 'int', 'long', 'short', 'signed',
      'unsigned', 'void', 'wchar_t', 'size_t', 'string', 'vector', 'map',
      'set', 'pair', 'shared_ptr', 'unique_ptr',
    },
  ),
  CodeLanguage.c: _LangDef(
    keywords: <String>{
      'auto', 'break', 'case', 'char', 'const', 'continue', 'default',
      'do', 'else', 'enum', 'extern', 'for', 'goto', 'if', 'inline',
      'register', 'restrict', 'return', 'sizeof', 'static', 'struct',
      'switch', 'typedef', 'union', 'volatile', 'while', '_Bool',
      '_Complex', '_Imaginary',
    },
    types: <String>{
      'bool', 'char', 'double', 'float', 'int', 'long', 'short', 'signed',
      'unsigned', 'void', 'size_t', 'ptrdiff_t', 'FILE',
    },
  ),
  CodeLanguage.swift: _LangDef(
    keywords: <String>{
      'as', 'break', 'case', 'catch', 'class', 'continue', 'default',
      'defer', 'deinit', 'do', 'else', 'enum', 'extension', 'fallthrough',
      'false', 'for', 'func', 'guard', 'if', 'import', 'in', 'init',
      'inout', 'is', 'let', 'nil', 'operator', 'override', 'precedencegroup',
      'private', 'protocol', 'public', 'repeat', 'rethrows', 'return',
      'self', 'Self', 'static', 'struct', 'subscript', 'super', 'switch',
      'throw', 'throws', 'true', 'try', 'typealias', 'var', 'where',
      'while',
    },
    types: <String>{
      'Any', 'AnyObject', 'Bool', 'Character', 'Double', 'Float', 'Int',
      'Int8', 'Int16', 'Int32', 'Int64', 'Optional', 'String', 'UInt',
      'UInt8', 'UInt16', 'UInt32', 'UInt64', 'Void', 'Array', 'Dictionary',
      'Set',
    },
    lineComment: '//',
  ),
  CodeLanguage.ruby: _LangDef(
    keywords: <String>{
      'alias', 'and', 'begin', 'break', 'case', 'class', 'def', 'defined?',
      'do', 'else', 'elsif', 'end', 'ensure', 'false', 'for', 'if', 'in',
      'module', 'next', 'nil', 'not', 'or', 'redo', 'rescue', 'retry',
      'return', 'self', 'super', 'then', 'true', 'undef', 'unless', 'until',
      'when', 'while', 'yield', 'require', 'include', 'extend', 'attr_reader',
      'attr_writer', 'attr_accessor',
    },
    types: <String>{
      'Array', 'Hash', 'String', 'Integer', 'Float', 'Symbol', 'Proc',
      'Lambda', 'Range', 'Regexp', 'NilClass', 'TrueClass', 'FalseClass',
    },
    lineComment: '#',
    hashComment: true,
  ),
  CodeLanguage.shell: _LangDef(
    keywords: <String>{
      'if', 'then', 'else', 'elif', 'fi', 'for', 'while', 'do', 'done',
      'case', 'esac', 'in', 'function', 'select', 'until', 'return',
      'exit', 'break', 'continue', 'shift', 'export', 'source', 'local',
      'readonly', 'declare', 'unset', 'trap', 'eval', 'exec', 'set',
    },
    types: <String>{},
    lineComment: '#',
    hashComment: true,
    blockCommentStart: '',
    blockCommentEnd: '',
  ),
  CodeLanguage.sql: _LangDef(
    keywords: <String>{
      'SELECT', 'FROM', 'WHERE', 'INSERT', 'INTO', 'VALUES', 'UPDATE',
      'SET', 'DELETE', 'CREATE', 'TABLE', 'DROP', 'ALTER', 'ADD', 'INDEX',
      'JOIN', 'INNER', 'LEFT', 'RIGHT', 'OUTER', 'ON', 'AND', 'OR', 'NOT',
      'NULL', 'IS', 'IN', 'BETWEEN', 'LIKE', 'ORDER', 'BY', 'GROUP',
      'HAVING', 'LIMIT', 'OFFSET', 'UNION', 'ALL', 'DISTINCT', 'AS',
      'CASE', 'WHEN', 'THEN', 'ELSE', 'END', 'EXISTS', 'PRIMARY', 'KEY',
      'FOREIGN', 'REFERENCES', 'CONSTRAINT', 'DEFAULT', 'CHECK', 'UNIQUE',
      'CASCADE', 'TRIGGER', 'VIEW', 'BEGIN', 'COMMIT', 'ROLLBACK',
      'TRANSACTION', 'GRANT', 'REVOKE',
      // lowercase variants
      'select', 'from', 'where', 'insert', 'into', 'values', 'update',
      'set', 'delete', 'create', 'table', 'drop', 'alter', 'add', 'index',
      'join', 'inner', 'left', 'right', 'outer', 'on', 'and', 'or', 'not',
      'null', 'is', 'in', 'between', 'like', 'order', 'by', 'group',
      'having', 'limit', 'offset', 'union', 'all', 'distinct', 'as',
      'case', 'when', 'then', 'else', 'end', 'exists', 'primary', 'key',
    },
    types: <String>{
      'INT', 'INTEGER', 'BIGINT', 'SMALLINT', 'TINYINT', 'FLOAT', 'DOUBLE',
      'DECIMAL', 'NUMERIC', 'VARCHAR', 'CHAR', 'TEXT', 'BLOB', 'DATE',
      'TIME', 'DATETIME', 'TIMESTAMP', 'BOOLEAN', 'SERIAL',
    },
    lineComment: '--',
    blockCommentStart: '/*',
    blockCommentEnd: '*/',
  ),
  CodeLanguage.yaml: _LangDef(
    keywords: <String>{'true', 'false', 'null', 'yes', 'no', 'on', 'off'},
    types: <String>{},
    lineComment: '#',
    hashComment: true,
    blockCommentStart: '',
    blockCommentEnd: '',
  ),
  CodeLanguage.json: _LangDef(
    keywords: <String>{'true', 'false', 'null'},
    types: <String>{},
    lineComment: '',
    blockCommentStart: '',
    blockCommentEnd: '',
  ),
  CodeLanguage.html: _LangDef(
    keywords: <String>{},
    types: <String>{},
    lineComment: '',
    blockCommentStart: '<!--',
    blockCommentEnd: '-->',
  ),
  CodeLanguage.css: _LangDef(
    keywords: <String>{
      'important', 'inherit', 'initial', 'unset', 'revert', 'none', 'auto',
      'block', 'inline', 'flex', 'grid', 'absolute', 'relative', 'fixed',
      'sticky', 'static', 'solid', 'dashed', 'dotted', 'hidden', 'visible',
    },
    types: <String>{},
    lineComment: '',
    blockCommentStart: '/*',
    blockCommentEnd: '*/',
  ),
  CodeLanguage.markdown: _LangDef(
    keywords: <String>{},
    types: <String>{},
    lineComment: '',
    blockCommentStart: '',
    blockCommentEnd: '',
  ),
  CodeLanguage.xml: _LangDef(
    keywords: <String>{},
    types: <String>{},
    lineComment: '',
    blockCommentStart: '<!--',
    blockCommentEnd: '-->',
  ),
  CodeLanguage.toml: _LangDef(
    keywords: <String>{'true', 'false'},
    types: <String>{},
    lineComment: '#',
    hashComment: true,
    blockCommentStart: '',
    blockCommentEnd: '',
  ),
};

/// Color palette for syntax tokens. Kept in one place so light/dark themes
/// can be adjusted without hunting through the tokenizer.
class SyntaxColors {
  const SyntaxColors({
    required this.keyword,
    required this.type,
    required this.string,
    required this.comment,
    required this.number,
    required this.annotation,
  });

  final Color keyword;
  final Color type;
  final Color string;
  final Color comment;
  final Color number;
  final Color annotation;

  /// A reasonable default that works on both light and dark backgrounds with
  /// slight transparency adjustments.
  static const SyntaxColors light = SyntaxColors(
    keyword: Color(0xFF7B2FBE),
    type: Color(0xFF1A7F9E),
    string: Color(0xFF2E7D32),
    comment: Color(0xFF8E8E8E),
    number: Color(0xFF1565C0),
    annotation: Color(0xFFE65100),
  );

  static const SyntaxColors dark = SyntaxColors(
    keyword: Color(0xFFC792EA),
    type: Color(0xFF82AAFF),
    string: Color(0xFFC3E88D),
    comment: Color(0xFF6A6A6A),
    number: Color(0xFFF78C6C),
    annotation: Color(0xFFFFCB6B),
  );
}

/// Produces a [TextSpan] tree with syntax coloring applied to [source].
///
/// The base style is taken from [baseStyle]; token-specific colors are applied
/// on top. This is intended to be used from a `TextEditingController`'s
/// `buildTextSpan` override.
TextSpan highlightSource({
  required String source,
  required TextStyle baseStyle,
  required CodeLanguage language,
  required SyntaxColors colors,
}) {
  final langDef = _langDefs[language];
  if (langDef == null || source.isEmpty) {
    return TextSpan(text: source, style: baseStyle);
  }
  return _tokenize(source, baseStyle, langDef, colors);
}

// ---------------------------------------------------------------------------
// Tokenizer
// ---------------------------------------------------------------------------

enum _TokenType { plain, keyword, type, string, comment, number, annotation }

TextSpan _tokenize(
  String source,
  TextStyle base,
  _LangDef lang,
  SyntaxColors colors,
) {
  final spans = <TextSpan>[];
  var i = 0;
  final len = source.length;

  Color colorFor(_TokenType t) => switch (t) {
        _TokenType.keyword => colors.keyword,
        _TokenType.type => colors.type,
        _TokenType.string => colors.string,
        _TokenType.comment => colors.comment,
        _TokenType.number => colors.number,
        _TokenType.annotation => colors.annotation,
        _TokenType.plain => base.color ?? const Color(0xFF000000),
      };

  void emit(String text, _TokenType type) {
    if (text.isEmpty) return;
    spans.add(TextSpan(
      text: text,
      style: base.copyWith(
        color: colorFor(type),
        fontStyle: type == _TokenType.comment ? FontStyle.italic : null,
      ),
    ));
  }

  while (i < len) {
    // Block comment
    if (lang.blockCommentStart.isNotEmpty &&
        source.startsWith(lang.blockCommentStart, i)) {
      final end = source.indexOf(lang.blockCommentEnd, i + lang.blockCommentStart.length);
      if (end == -1) {
        emit(source.substring(i), _TokenType.comment);
        break;
      }
      final closeEnd = end + lang.blockCommentEnd.length;
      emit(source.substring(i, closeEnd), _TokenType.comment);
      i = closeEnd;
      continue;
    }

    // Line comment
    if (lang.lineComment.isNotEmpty && source.startsWith(lang.lineComment, i)) {
      final nl = source.indexOf('\n', i);
      if (nl == -1) {
        emit(source.substring(i), _TokenType.comment);
        break;
      }
      emit(source.substring(i, nl), _TokenType.comment);
      i = nl; // newline handled below as plain
      continue;
    }

    // Strings (single or double quoted, with basic escape handling)
    if (source[i] == '"' || source[i] == "'") {
      final quote = source[i];
      var j = i + 1;
      while (j < len && source[j] != quote) {
        if (source[j] == '\\' && j + 1 < len) j++; // skip escaped char
        j++;
      }
      if (j < len) j++; // include closing quote
      emit(source.substring(i, j), _TokenType.string);
      i = j;
      continue;
    }

    // Backtick strings (template literals, markdown code)
    if (source[i] == '`') {
      var j = i + 1;
      while (j < len && source[j] != '`') {
        if (source[j] == '\\' && j + 1 < len) j++;
        j++;
      }
      if (j < len) j++;
      emit(source.substring(i, j), _TokenType.string);
      i = j;
      continue;
    }

    // Annotations / decorators (@override, @Deprecated, etc.)
    if (source[i] == '@' && i + 1 < len && _isIdentStart(source[i + 1])) {
      var j = i + 1;
      while (j < len && _isIdentPart(source[j])) {
        j++;
      }
      emit(source.substring(i, j), _TokenType.annotation);
      i = j;
      continue;
    }

    // Numbers (int, float, hex)
    if (_isDigit(source[i]) ||
        (source[i] == '.' && i + 1 < len && _isDigit(source[i + 1]))) {
      var j = i;
      if (source[j] == '0' && j + 1 < len && (source[j + 1] == 'x' || source[j + 1] == 'X')) {
        j += 2;
        while (j < len && _isHexDigit(source[j])) {
          j++;
        }
      } else {
        while (j < len && (_isDigit(source[j]) || source[j] == '.')) {
          j++;
        }
        // Handle exponent
        if (j < len && (source[j] == 'e' || source[j] == 'E')) {
          j++;
          if (j < len && (source[j] == '+' || source[j] == '-')) j++;
          while (j < len && _isDigit(source[j])) {
            j++;
          }
        }
      }
      // Suffix (e.g., 42L, 3.14f)
      if (j < len && _isIdentStart(source[j])) {
        j++;
      }
      emit(source.substring(i, j), _TokenType.number);
      i = j;
      continue;
    }

    // Identifiers and keywords
    if (_isIdentStart(source[i])) {
      var j = i;
      while (j < len && _isIdentPart(source[j])) {
        j++;
      }
      final word = source.substring(i, j);
      if (lang.keywords.contains(word)) {
        emit(word, _TokenType.keyword);
      } else if (lang.types.contains(word)) {
        emit(word, _TokenType.type);
      } else {
        emit(word, _TokenType.plain);
      }
      i = j;
      continue;
    }

    // Everything else (operators, whitespace, punctuation)
    emit(source[i], _TokenType.plain);
    i++;
  }

  return TextSpan(children: spans, style: base);
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
bool _isHexDigit(String c) {
  final code = c.codeUnitAt(0);
  return (code >= 48 && code <= 57) ||
      (code >= 65 && code <= 70) ||
      (code >= 97 && code <= 102);
}

bool _isIdentStart(String c) {
  final code = c.codeUnitAt(0);
  return (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      c == '_' ||
      c == '\$';
}

bool _isIdentPart(String c) => _isIdentStart(c) || _isDigit(c);

/// A [TextEditingController] that applies syntax highlighting via
/// [buildTextSpan]. Update [language] and [colors] when the file or theme
/// changes, then call [rebuildHighlight] (or simply set [text]) to refresh.
class SyntaxTextEditingController extends TextEditingController {
  SyntaxTextEditingController({
    super.text,
    this.language = CodeLanguage.unknown,
    this.colors = SyntaxColors.light,
    this.baseStyle = const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
  });

  CodeLanguage language;
  SyntaxColors colors;
  TextStyle baseStyle;

  /// Forces a rebuild of the text span (e.g. when the theme changes).
  void rebuildHighlight() => notifyListeners();

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final mergedBase = baseStyle.merge(style);
    if (language == CodeLanguage.unknown || text.isEmpty) {
      return TextSpan(text: text, style: mergedBase);
    }
    return highlightSource(
      source: text,
      baseStyle: mergedBase,
      language: language,
      colors: colors,
    );
  }
}
