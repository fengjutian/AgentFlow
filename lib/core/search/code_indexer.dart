/// Background code indexer for BM25 semantic search.
///
/// Chunks workspace source files into searchable segments and populates the
/// FTS5 virtual table `code_chunks_fts` for BM25-ranked retrieval.
///
/// Chunking strategy:
/// - Split by function/class boundaries (regex-based heuristics)
/// - Fallback: split by blank-line paragraphs (~200-500 chars per chunk)
/// - 2-line overlap between adjacent chunks for context continuity
///
/// Indexing is incremental: only re-index files whose mtime has changed.
library;

import 'dart:async';

import 'package:drift/drift.dart';

import '../../runtime/runtime.dart';
import '../../storage/database.dart';

/// Directories to skip during indexing.
const _ignoredDirs = <String>{
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
  '.vscode',
  '.android',
  '.ios',
};

/// Binary file extensions to skip.
const _binaryExtensions = <String>{
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
  '.o',
  '.a',
  '.dylib',
};

/// Maps file extensions to language IDs.
const _extensionToLanguage = <String, String>{
  '.dart': 'dart',
  '.py': 'python',
  '.js': 'javascript',
  '.jsx': 'javascript',
  '.ts': 'typescript',
  '.tsx': 'typescript',
  '.java': 'java',
  '.kt': 'kotlin',
  '.kts': 'kotlin',
  '.go': 'go',
  '.rs': 'rust',
  '.c': 'c',
  '.h': 'c',
  '.cpp': 'cpp',
  '.cc': 'cpp',
  '.hpp': 'cpp',
  '.cs': 'csharp',
  '.rb': 'ruby',
  '.php': 'php',
  '.swift': 'swift',
  '.m': 'objc',
  '.mm': 'objc',
  '.sh': 'shell',
  '.bash': 'shell',
  '.zsh': 'shell',
  '.html': 'html',
  '.htm': 'html',
  '.css': 'css',
  '.scss': 'scss',
  '.json': 'json',
  '.xml': 'xml',
  '.yaml': 'yaml',
  '.yml': 'yaml',
  '.md': 'markdown',
  '.sql': 'sql',
  '.lua': 'lua',
  '.r': 'r',
  '.scala': 'scala',
  '.groovy': 'groovy',
};

/// Maximum file size to index (512 KB).
const _maxFileSizeBytes = 512 * 1024;

/// Target chunk size in characters.
const _targetChunkSize = 400;

/// Overlap lines between adjacent chunks.
const _overlapLines = 2;

/// Regex patterns for detecting function/class boundaries.
final _functionPatterns = [
  // Dart/Java/C-style: type name(...) {
  RegExp(r'^\s*(?:(?:public|private|protected|static|final|abstract|async|override)\s+)*[\w<>,?\[\]\s]+\s+\w+\s*\([^)]*\)\s*(?:async\s*)?[{]'),
  // Python: def name(...):
  RegExp(r'^\s*(?:async\s+)?def\s+\w+\s*\([^)]*\)\s*(?:->.*?)?:'),
  // JavaScript/TypeScript: function name() or const name = (...) =>
  RegExp(r'^\s*(?:export\s+)?(?:async\s+)?function\s+\w+|(?:const|let|var)\s+\w+\s*=\s*(?:async\s+)?(?:\([^)]*\)|[^=])\s*=>'),
  // Class declarations
  RegExp(r'^\s*(?:(?:public|private|protected|abstract|sealed|final|base|interface)\s+)*class\s+\w+'),
  // Enum declarations
  RegExp(r'^\s*enum\s+\w+'),
];

/// A chunk of code extracted from a file.
class CodeChunk {
  const CodeChunk({
    required this.filePath,
    required this.chunkIndex,
    required this.startLine,
    required this.endLine,
    required this.content,
    required this.languageId,
  });

  final String filePath;
  final int chunkIndex;
  final int startLine;
  final int endLine;
  final String content;
  final String languageId;
}

/// Indexes workspace source files into searchable chunks.
class CodeIndexer {
  CodeIndexer({required this.db});

  final AppDatabase db;

  Timer? _debounceTimer;

  /// Indexes all files in the workspace root.
  Future<void> indexWorkspace({
    required Runtime runtime,
    required String workspaceId,
    required String rootDirectory,
  }) async {
    // Clear old chunks for this workspace.
    await (db.delete(db.codeChunks)
          ..where((t) => t.workspaceId.equals(workspaceId)))
        .go();

    // Walk the directory tree and index files.
    await _walkDirectory(
      runtime: runtime,
      workspaceId: workspaceId,
      directory: rootDirectory,
    );

    // Rebuild FTS index.
    await _rebuildFtsIndex();
  }

  /// Indexes a single file (for incremental updates).
  Future<void> indexFile({
    required Runtime runtime,
    required String workspaceId,
    required String filePath,
    int? mtime,
  }) async {
    // Check if file needs re-indexing.
    final existingChunks = await (db.select(db.codeChunks)
          ..where((t) =>
              t.workspaceId.equals(workspaceId) &
              t.filePath.equals(filePath)))
        .get();

    if (existingChunks.isNotEmpty && mtime != null) {
      final indexedMtime = existingChunks.first.mtime;
      if (indexedMtime >= mtime) {
        return; // File hasn't changed.
      }
    }

    // Remove old chunks.
    await (db.delete(db.codeChunks)
          ..where((t) =>
              t.workspaceId.equals(workspaceId) &
              t.filePath.equals(filePath)))
        .go();

    // Read and chunk the file.
    try {
      final content = await runtime.readFile(filePath);
      if (content.isEmpty) return;

      final languageId = _detectLanguage(filePath);
      final chunks = _chunkContent(content, languageId);
      final now = DateTime.now();

      for (var i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        await db.into(db.codeChunks).insert(
              CodeChunksCompanion.insert(
                workspaceId: workspaceId,
                filePath: filePath,
                chunkIndex: i,
                startLine: chunk.startLine,
                endLine: chunk.endLine,
                content: chunk.content,
                languageId: Value(languageId),
                mtime: Value(mtime ?? now.millisecondsSinceEpoch ~/ 1000),
                indexedAt: now,
              ),
            );
      }

      await _rebuildFtsIndex();
    } catch (_) {
      // File read failed, skip.
    }
  }

  /// Debounced index update (call after file save).
  void scheduleIndexUpdate({
    required Runtime runtime,
    required String workspaceId,
    required String filePath,
    int? mtime,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      indexFile(
        runtime: runtime,
        workspaceId: workspaceId,
        filePath: filePath,
        mtime: mtime,
      );
    });
  }

  Future<void> _walkDirectory({
    required Runtime runtime,
    required String workspaceId,
    required String directory,
  }) async {
    final List<FileEntry> entries;
    try {
      entries = await runtime.listFiles(directory);
    } catch (_) {
      return;
    }

    for (final entry in entries) {
      if (entry.isDirectory) {
        if (!_ignoredDirs.contains(entry.name) && !entry.name.startsWith('.')) {
          await _walkDirectory(
            runtime: runtime,
            workspaceId: workspaceId,
            directory: entry.path,
          );
        }
      } else {
        if (_isBinary(entry.name)) continue;
        if (entry.size > _maxFileSizeBytes) continue;

        await indexFile(
          runtime: runtime,
          workspaceId: workspaceId,
          filePath: entry.path,
        );
      }
    }
  }

  String _detectLanguage(String filePath) {
    final dot = filePath.lastIndexOf('.');
    if (dot < 0) return '';
    final ext = filePath.substring(dot).toLowerCase();
    return _extensionToLanguage[ext] ?? '';
  }

  bool _isBinary(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return false;
    return _binaryExtensions.contains(name.substring(dot).toLowerCase());
  }

  List<CodeChunk> _chunkContent(String content, String languageId) {
    final lines = content.split('\n');
    if (lines.isEmpty) return [];

    final chunks = <CodeChunk>[];
    var currentChunkStart = 0;
    var currentChunkLines = <String>[];
    var chunkIndex = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      currentChunkLines.add(line);

      // Check if we should start a new chunk.
      final chunkContent = currentChunkLines.join('\n');
      final isBoundary = _isFunctionBoundary(line);
      final isLarge = chunkContent.length >= _targetChunkSize;
      final isBlank = line.trim().isEmpty && currentChunkLines.length > 10;

      if ((isLarge || (isBoundary && currentChunkLines.length > 5) || isBlank) &&
          currentChunkLines.length > 3) {
        chunks.add(CodeChunk(
          filePath: '',
          chunkIndex: chunkIndex++,
          startLine: currentChunkStart + 1,
          endLine: i + 1,
          content: chunkContent,
          languageId: languageId,
        ));

        // Start new chunk with overlap.
        final overlapStart = (currentChunkLines.length - _overlapLines).clamp(0, currentChunkLines.length);
        currentChunkLines = currentChunkLines.sublist(overlapStart);
        currentChunkStart = i + 1 - _overlapLines;
      }
    }

    // Add remaining lines.
    if (currentChunkLines.isNotEmpty) {
      chunks.add(CodeChunk(
        filePath: '',
        chunkIndex: chunkIndex,
        startLine: currentChunkStart + 1,
        endLine: lines.length,
        content: currentChunkLines.join('\n'),
        languageId: languageId,
      ));
    }

    return chunks;
  }

  bool _isFunctionBoundary(String line) {
    for (final pattern in _functionPatterns) {
      if (pattern.hasMatch(line)) return true;
    }
    return false;
  }

  Future<void> _rebuildFtsIndex() async {
    try {
      await db.customStatement(
        "INSERT INTO code_chunks_fts(code_chunks_fts) VALUES('rebuild')",
      );
    } catch (_) {
      // FTS table may not exist or may not support rebuild.
    }
  }

  /// Disposes resources.
  void dispose() {
    _debounceTimer?.cancel();
  }
}
