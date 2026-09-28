library;

import '../../runtime/runtime.dart';

typedef DirectoryLister = Future<List<FileEntry>> Function(String path);

class EditorFileIndex {
  EditorFileIndex(this._listFiles);

  final DirectoryLister _listFiles;

  static const Set<String> defaultIgnoredDirectories = <String>{
    '.git',
    '.dart_tool',
    '.idea',
    'build',
    'node_modules',
  };

  Future<List<FileEntry>> scan({
    int limit = 3000,
    Set<String> ignoredDirectories = defaultIgnoredDirectories,
  }) async {
    final files = <FileEntry>[];
    final pending = <String>[''];
    while (pending.isNotEmpty && files.length < limit) {
      final directory = pending.removeLast();
      List<FileEntry> entries;
      try {
        entries = await _listFiles(directory);
      } catch (_) {
        continue;
      }
      for (final entry in entries) {
        if (entry.isDirectory) {
          if (!ignoredDirectories.contains(entry.name)) {
            pending.add(entry.path);
          }
        } else {
          files.add(entry);
          if (files.length >= limit) break;
        }
      }
    }
    files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    return files;
  }
}
