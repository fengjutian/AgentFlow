/// Local, on-device runtime backed by `dart:io`.
///
/// Used for desktop development, automated tests, and as the Android fallback
/// when the Kotlin/Termux bridge is unavailable. Everything is resolved relative
/// to [rootDirectory] so a workspace cannot wander outside its own tree by
/// accident.
library;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'runtime.dart';

class LocalRuntime implements Runtime {
  LocalRuntime({required String rootDirectory, this.id = 'local'})
      : _root = p.normalize(p.absolute(rootDirectory));

  @override
  final String id;
  final String _root;

  /// Absolute path of the workspace root this runtime is pinned to.
  String get rootDirectory => _root;

  @override
  String get label => 'Local (${p.basename(_root)})';

  @override
  RuntimeKind get kind => RuntimeKind.local;

  /// Resolves [target] to an absolute path inside [_root].
  ///
  /// Relative paths are joined onto the root; absolute paths are used as-is but
  /// normalized. This keeps the agent from escaping the workspace via `../`.
  String resolve(String target) {
    if (target.isEmpty) return _root;
    final absolute = p.isAbsolute(target) ? target : p.join(_root, target);
    final normalized = p.normalize(absolute);
    if (!isInsideRoot(normalized)) {
      throw FileSystemException('Path is outside the workspace', normalized);
    }
    return normalized;
  }

  bool isInsideRoot(String absolutePath) {
    final relative = p.relative(absolutePath, from: _root);
    return !relative.startsWith('..') && !p.isAbsolute(relative);
  }

  @override
  Future<bool> isAvailable() async => Directory(_root).existsSync();

  @override
  Future<CommandResult> execute(
    String command, {
    String? workingDirectory,
    int timeoutMillis = 60000,
    Map<String, String>? environment,
    OutputCallback? onStdout,
    OutputCallback? onStderr,
  }) async {
    final cwd = workingDirectory == null ? _root : resolve(workingDirectory);
    final dir = Directory(cwd);
    if (!dir.existsSync()) {
      return CommandResult(
        exitCode: 127,
        stdout: '',
        stderr: 'Working directory does not exist: $cwd',
        command: command,
        workingDirectory: cwd,
      );
    }

    // Run through a shell so pipelines/redirects behave as users expect.
    final shell = Platform.isWindows ? 'cmd.exe' : '/bin/sh';
    final shellArgs =
        Platform.isWindows ? <String>['/c', command] : <String>['-c', command];

    try {
      final process = await Process.start(
        shell,
        shellArgs,
        workingDirectory: cwd,
        environment: environment,
        runInShell: false,
      );

      final stdoutFuture = process.stdout
          .transform(const SystemEncoding().decoder)
          .map((String chunk) {
            onStdout?.call(chunk);
            return chunk;
          })
          .join();
      final stderrFuture = process.stderr
          .transform(const SystemEncoding().decoder)
          .map((String chunk) {
            onStderr?.call(chunk);
            return chunk;
          })
          .join();

      late final int exitCode;
      var timedOut = false;
      try {
        exitCode = await process.exitCode.timeout(
          Duration(milliseconds: timeoutMillis),
        );
      } on TimeoutException {
        timedOut = true;
        process.kill();
        exitCode = await process.exitCode;
      }
      final out = await stdoutFuture;
      final err = await stderrFuture;
      return CommandResult(
        exitCode: timedOut ? 124 : exitCode,
        stdout: out,
        stderr: err,
        command: command,
        workingDirectory: cwd,
        timedOut: timedOut,
      );
    } on ProcessException catch (e) {
      return CommandResult(
        exitCode: 127,
        stdout: '',
        stderr: 'Failed to start command: ${e.message}',
        command: command,
        workingDirectory: cwd,
      );
    }
  }

  @override
  Future<String> readFile(String path) async {
    final file = File(resolve(path));
    if (!file.existsSync()) {
      throw FileSystemException('File not found', file.path);
    }
    return file.readAsString();
  }

  @override
  Future<void> writeFile(String path, String content) async {
    final file = File(resolve(path));
    file.parent.createSync(recursive: true);
    await file.writeAsString(content, flush: true);
  }

  @override
  Future<void> deleteFile(String path) async {
    final file = File(resolve(path));
    if (file.existsSync()) await file.delete();
  }

  @override
  Future<void> createDirectory(String path) async {
    await Directory(resolve(path)).create(recursive: true);
  }

  @override
  Future<void> renameEntry(String path, String newPath) async {
    final source = FileSystemEntity.typeSync(resolve(path), followLinks: false);
    final destination = resolve(newPath);
    if (source == FileSystemEntityType.notFound) {
      throw FileSystemException('Entry not found', resolve(path));
    }
    if (FileSystemEntity.typeSync(destination, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw FileSystemException('Destination already exists', destination);
    }
    await Directory(p.dirname(destination)).create(recursive: true);
    if (source == FileSystemEntityType.directory) {
      await Directory(resolve(path)).rename(destination);
    } else {
      await File(resolve(path)).rename(destination);
    }
  }

  @override
  Future<void> deleteEntry(String path) async {
    final resolved = resolve(path);
    if (resolved == _root) {
      throw FileSystemException('Cannot delete the workspace root', resolved);
    }
    final type = FileSystemEntity.typeSync(resolved, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      await Directory(resolved).delete(recursive: true);
    } else if (type != FileSystemEntityType.notFound) {
      await File(resolved).delete();
    }
  }

  @override
  Future<bool> fileExists(String path) async => File(resolve(path)).existsSync();

  @override
  Future<List<FileEntry>> listFiles(String path) async {
    final dir = Directory(resolve(path));
    if (!dir.existsSync()) {
      throw FileSystemException('Directory not found', dir.path);
    }
    final entries = <FileEntry>[];
    await for (final entity in dir.list(followLinks: false)) {
      final stat = entity.statSync();
      entries.add(FileEntry(
        name: p.basename(entity.path),
        path: p.relative(entity.path, from: _root),
        isDirectory: entity is Directory,
        size: stat.size,
        modified: stat.modified,
      ));
    }
    entries.sort((FileEntry a, FileEntry b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }
}
