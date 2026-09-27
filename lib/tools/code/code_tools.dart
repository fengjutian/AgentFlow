/// Portable code-search tools for local, Termux and future SSH runtimes.
library;

import '../../core/message.dart';
import '../../runtime/runtime.dart';
import '../agent_tool.dart';
import '../tool_args.dart';

class CodeSearchHit {
  const CodeSearchHit(this.path, this.line, this.text);
  final String path;
  final int line;
  final String text;

  String get display => '$path:$line: $text';
  Map<String, dynamic> toJson() => <String, dynamic>{
    'path': path,
    'line': line,
    'text': text,
  };
}

class CodeSearchService {
  const CodeSearchService({this.maxFileSizeBytes = 512 * 1024});
  final int maxFileSizeBytes;

  static const _ignoredDirs = <String>{
    '.git',
    '.dart_tool',
    '.idea',
    'node_modules',
    'build',
    'dist',
    '.gradle',
    'Pods',
    '.next',
    'out',
    'target',
    '.venv',
    '__pycache__',
  };
  static const _binaryExtensions = <String>{
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
    '.ico',
    '.pdf',
    '.zip',
    '.gz',
    '.tar',
    '.jar',
    '.apk',
    '.so',
    '.dll',
    '.exe',
    '.woff',
    '.woff2',
    '.ttf',
    '.mp3',
    '.mp4',
    '.mov',
    '.class',
    '.lock',
  };

  Future<List<CodeSearchHit>> search({
    required Runtime runtime,
    required String root,
    required RegExp regex,
    String fileGlob = '',
    int limit = 100,
  }) async {
    final hits = <CodeSearchHit>[];
    await _walk(
      runtime,
      root,
      regex,
      _normalizeGlob(fileGlob),
      limit.clamp(1, 1000),
      hits,
    );
    return hits;
  }

  Future<void> _walk(
    Runtime runtime,
    String directory,
    RegExp regex,
    String? extension,
    int limit,
    List<CodeSearchHit> hits,
  ) async {
    if (hits.length >= limit) return;
    final List<FileEntry> entries;
    try {
      entries = await runtime.listFiles(directory);
    } catch (_) {
      return;
    }
    for (final entry in entries) {
      if (hits.length >= limit) return;
      if (entry.isDirectory) {
        if (!_ignoredDirs.contains(entry.name)) {
          await _walk(runtime, entry.path, regex, extension, limit, hits);
        }
        continue;
      }
      if (extension != null && !entry.name.toLowerCase().endsWith(extension)) {
        continue;
      }
      if (_isBinary(entry.name) || entry.size > maxFileSizeBytes) continue;
      await _searchFile(runtime, entry.path, regex, limit, hits);
    }
  }

  Future<void> _searchFile(
    Runtime runtime,
    String path,
    RegExp regex,
    int limit,
    List<CodeSearchHit> hits,
  ) async {
    final String content;
    try {
      content = await runtime.readFile(path);
    } catch (_) {
      return;
    }
    final lines = content.split('\n');
    for (var index = 0; index < lines.length && hits.length < limit; index++) {
      if (!regex.hasMatch(lines[index])) continue;
      final text = lines[index].trim();
      hits.add(
        CodeSearchHit(
          path,
          index + 1,
          text.length > 240 ? '${text.substring(0, 240)}…' : text,
        ),
      );
    }
  }

  bool _isBinary(String name) {
    final dot = name.lastIndexOf('.');
    return dot >= 0 &&
        _binaryExtensions.contains(name.substring(dot).toLowerCase());
  }

  String? _normalizeGlob(String glob) {
    if (glob.trim().isEmpty) return null;
    var value = glob.trim().toLowerCase();
    if (value.startsWith('*.')) value = value.substring(1);
    if (!value.startsWith('.')) value = '.$value';
    return value;
  }
}

abstract class _CodeSearchTool extends ReadOnlyTool {
  _CodeSearchTool({CodeSearchService? searchService})
    : searchService = searchService ?? const CodeSearchService();
  final CodeSearchService searchService;

  RegExp compile(String pattern, {bool caseSensitive = true}) {
    try {
      return RegExp(pattern, caseSensitive: caseSensitive, multiLine: true);
    } on FormatException catch (error) {
      throw ToolExecutionException(
        'Invalid regular expression: ${error.message}',
      );
    }
  }

  ToolResult render(
    String toolName,
    String emptyMessage,
    List<CodeSearchHit> hits,
    Map<String, dynamic> metadata,
  ) {
    final content = hits.isEmpty
        ? emptyMessage
        : '${hits.length} match(es):\n${hits.map((hit) => hit.display).join('\n')}';
    return ToolResult(
      toolCallId: '',
      name: toolName,
      content: clampOutput(content),
      data: <String, dynamic>{
        ...metadata,
        'count': hits.length,
        'matches': hits.map((hit) => hit.toJson()).toList(growable: false),
      },
    );
  }
}

class SearchCodeTool extends _CodeSearchTool {
  SearchCodeTool({super.searchService, this.maxResults = 100});
  final int maxResults;

  @override
  String get name => 'search_code';
  @override
  String get description =>
      'Search source contents with a regular expression. Returns paths, line '
      'numbers and matching text. Supports path and extension filters.';
  @override
  Map<String, dynamic> get inputSchema => _schema('pattern');
  @override
  String describeCall(Map<String, dynamic> arguments) =>
      'search_code "${optionalString(arguments, 'pattern')}"';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final pattern = requireString(arguments, 'pattern');
    final root = optionalString(arguments, 'path', fallback: '.');
    final hits = await searchService.search(
      runtime: context.runtime,
      root: root,
      regex: compile(
        pattern,
        caseSensitive: !optionalBool(arguments, 'ignoreCase', fallback: true),
      ),
      fileGlob: optionalString(arguments, 'fileGlob'),
      limit: optionalInt(arguments, 'maxResults', fallback: maxResults),
    );
    return render(
      name,
      'No matches for /$pattern/ under $root.',
      hits,
      <String, dynamic>{'pattern': pattern},
    );
  }
}

class FindSymbolTool extends _CodeSearchTool {
  FindSymbolTool({super.searchService});
  @override
  String get name => 'find_symbol';
  @override
  String get description =>
      'Find likely declarations of a class, function, method, type or variable '
      'by exact symbol name across common programming languages.';
  @override
  Map<String, dynamic> get inputSchema => _schema('symbol');
  @override
  String describeCall(Map<String, dynamic> arguments) =>
      'find_symbol ${optionalString(arguments, 'symbol')}';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final symbol = requireString(arguments, 'symbol').trim();
    final escaped = RegExp.escape(symbol);
    final declaration =
        r'^\s*(?:(?:(?:abstract|sealed|final|base|interface)\s+)?'
        r'(?:class|enum|mixin|extension|typedef|struct|trait|type|def|fun|fn|func)\s+'
        '$escaped\\b|(?:const|final|var|let)\\s+$escaped\\b|'
        r'(?:[A-Za-z_][\w<>,?.\[\] ]*\s+)'
        '$escaped\\s*\\()';
    final root = optionalString(arguments, 'path', fallback: '.');
    final hits = await searchService.search(
      runtime: context.runtime,
      root: root,
      regex: compile(declaration),
      fileGlob: optionalString(arguments, 'fileGlob'),
      limit: optionalInt(arguments, 'maxResults', fallback: 50),
    );
    return render(
      name,
      'No declaration found for "$symbol" under $root.',
      hits,
      <String, dynamic>{'symbol': symbol},
    );
  }
}

class FindReferencesTool extends _CodeSearchTool {
  FindReferencesTool({super.searchService});
  @override
  String get name => 'find_references';
  @override
  String get description =>
      'Find lexical references to an exact identifier. Results may include '
      'declarations until AST indexing is available.';
  @override
  Map<String, dynamic> get inputSchema => _schema('symbol');
  @override
  String describeCall(Map<String, dynamic> arguments) =>
      'find_references ${optionalString(arguments, 'symbol')}';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    final symbol = requireString(arguments, 'symbol').trim();
    final root = optionalString(arguments, 'path', fallback: '.');
    final hits = await searchService.search(
      runtime: context.runtime,
      root: root,
      regex: compile('\\b${RegExp.escape(symbol)}\\b'),
      fileGlob: optionalString(arguments, 'fileGlob'),
      limit: optionalInt(arguments, 'maxResults', fallback: 100),
    );
    return render(
      name,
      'No references found for "$symbol" under $root.',
      hits,
      <String, dynamic>{'symbol': symbol},
    );
  }
}

Map<String, dynamic> _schema(String requiredName) => <String, dynamic>{
  'type': 'object',
  'properties': <String, dynamic>{
    requiredName: <String, dynamic>{'type': 'string'},
    'path': <String, dynamic>{'type': 'string'},
    'fileGlob': <String, dynamic>{'type': 'string'},
    'ignoreCase': <String, dynamic>{'type': 'boolean'},
    'maxResults': <String, dynamic>{'type': 'integer'},
  },
  'required': <String>[requiredName],
};

List<AgentTool> codeTools() => <AgentTool>[
  SearchCodeTool(),
  FindSymbolTool(),
  FindReferencesTool(),
];
