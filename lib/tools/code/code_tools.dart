/// Code tool: search_code.
///
/// Recursive content search across the workspace, implemented on top of the
/// [Runtime] file API so it works identically for local, Termux and (future)
/// remote runtimes. Common dependency/build directories are skipped and large or
/// binary files are ignored.
///
/// Note: the design doc lists ripgrep as the eventual backend for very large
/// repos. This walker is the portable MVP implementation; swapping in an
/// `rg --json` backend only changes [SearchCodeTool.execute].
library;

import '../../core/message.dart';
import '../../runtime/runtime.dart';
import '../agent_tool.dart';
import '../tool_args.dart';

class SearchCodeTool extends ReadOnlyTool {
  SearchCodeTool({this.maxFileSizeBytes = 512 * 1024, this.maxResults = 100});

  final int maxFileSizeBytes;
  final int maxResults;

  static const Set<String> _ignoredDirs = <String>{
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

  static const Set<String> _binaryExtensions = <String>{
    '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico', '.pdf', '.zip', '.gz',
    '.tar', '.jar', '.apk', '.so', '.dll', '.exe', '.woff', '.woff2', '.ttf',
    '.mp3', '.mp4', '.mov', '.class', '.lock',
  };

  @override
  String get name => 'search_code';

  @override
  String get description =>
      'Search file contents across the workspace using a regular expression. '
      'Returns matching lines as "path:line: text". Scope with an optional path '
      'and fileGlob (e.g. "*.dart"). Skips .git, node_modules, build and binary '
      'files. Use it to locate symbols, usages or config before reading files.';

  @override
  Map<String, dynamic> get inputSchema => <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'pattern': <String, dynamic>{
            'type': 'string',
            'description': 'Regular expression to search for.',
          },
          'path': <String, dynamic>{
            'type': 'string',
            'description': 'Optional subdirectory to scope the search.',
          },
          'fileGlob': <String, dynamic>{
            'type': 'string',
            'description': 'Optional extension filter, e.g. "*.dart" or "dart".',
          },
          'ignoreCase': <String, dynamic>{'type': 'boolean'},
          'maxResults': <String, dynamic>{'type': 'integer'},
        },
        'required': <String>['pattern'],
      };

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
    final ignoreCase = optionalBool(arguments, 'ignoreCase', fallback: true);
    final limit = optionalInt(arguments, 'maxResults', fallback: maxResults);
    final glob = _normalizeGlob(optionalString(arguments, 'fileGlob'));

    final RegExp regex;
    try {
      regex = RegExp(pattern, caseSensitive: !ignoreCase);
    } on FormatException catch (e) {
      throw ToolExecutionException('Invalid regular expression: ${e.message}');
    }

    final matches = <String>[];
    await _walk(
      runtime: context.runtime,
      dir: root,
      regex: regex,
      glob: glob,
      limit: limit,
      matches: matches,
    );

    final content = matches.isEmpty
        ? 'No matches for /$pattern/ under $root.'
        : '${matches.length} match(es):\n${matches.join('\n')}';
    return ToolResult(
      toolCallId: '',
      name: name,
      content: clampOutput(content),
      data: <String, dynamic>{'pattern': pattern, 'count': matches.length},
    );
  }

  Future<void> _walk({
    required Runtime runtime,
    required String dir,
    required RegExp regex,
    required String? glob,
    required int limit,
    required List<String> matches,
  }) async {
    if (matches.length >= limit) return;
    final List<FileEntry> entries;
    try {
      entries = await runtime.listFiles(dir);
    } catch (_) {
      return;
    }
    for (final entry in entries) {
      if (matches.length >= limit) return;
      if (entry.isDirectory) {
        if (_ignoredDirs.contains(entry.name)) continue;
        await _walk(
          runtime: runtime,
          dir: entry.path,
          regex: regex,
          glob: glob,
          limit: limit,
          matches: matches,
        );
      } else {
        if (glob != null && !_matchesGlob(entry.name, glob)) continue;
        if (_isBinary(entry.name)) continue;
        if (entry.size > maxFileSizeBytes) continue;
        await _searchFile(runtime, entry.path, regex, limit, matches);
      }
    }
  }

  Future<void> _searchFile(
    Runtime runtime,
    String path,
    RegExp regex,
    int limit,
    List<String> matches,
  ) async {
    String content;
    try {
      content = await runtime.readFile(path);
    } catch (_) {
      return; // unreadable / binary — skip silently
    }
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (matches.length >= limit) return;
      if (regex.hasMatch(lines[i])) {
        final text = lines[i].trim();
        matches.add('$path:${i + 1}: ${text.length > 240 ? '${text.substring(0, 240)}…' : text}');
      }
    }
  }

  bool _isBinary(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return false;
    return _binaryExtensions.contains(name.substring(dot).toLowerCase());
  }

  String? _normalizeGlob(String glob) {
    if (glob.trim().isEmpty) return null;
    var g = glob.trim().toLowerCase();
    if (g.startsWith('*.')) g = g.substring(1); // ".dart"
    if (!g.startsWith('.')) g = '.$g';
    return g;
  }

  bool _matchesGlob(String fileName, String normalizedExt) =>
      fileName.toLowerCase().endsWith(normalizedExt);
}

List<AgentTool> codeTools() => <AgentTool>[SearchCodeTool()];
