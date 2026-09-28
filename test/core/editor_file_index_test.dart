import 'package:agentflow/core/editor/editor_file_index.dart';
import 'package:agentflow/runtime/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('indexes nested files and skips generated directories', () async {
    final tree = <String, List<FileEntry>>{
      '': const <FileEntry>[
        FileEntry(name: 'lib', path: 'lib', isDirectory: true),
        FileEntry(name: '.git', path: '.git', isDirectory: true),
        FileEntry(name: 'README.md', path: 'README.md', isDirectory: false),
      ],
      'lib': const <FileEntry>[
        FileEntry(name: 'main.dart', path: 'lib/main.dart', isDirectory: false),
      ],
      '.git': const <FileEntry>[
        FileEntry(name: 'config', path: '.git/config', isDirectory: false),
      ],
    };

    final files = await EditorFileIndex(
      (path) async => tree[path] ?? const <FileEntry>[],
    ).scan();

    expect(files.map((entry) => entry.path), <String>['lib/main.dart', 'README.md']);
  });

  test('honours result limit', () async {
    final files = await EditorFileIndex(
      (_) async => List<FileEntry>.generate(
        10,
        (index) => FileEntry(
          name: '$index.txt',
          path: '$index.txt',
          isDirectory: false,
        ),
      ),
    ).scan(limit: 3);

    expect(files, hasLength(3));
  });
}
