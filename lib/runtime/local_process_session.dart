/// Local process session backed by `dart:io` [Process].
///
/// Provides bidirectional stdin/stdout streaming for long-lived processes
/// started by [LocalRuntime.startProcess]. Used for stdio MCP servers and
/// streaming terminal sessions on the local machine.
library;

import 'dart:async';
import 'dart:io';

import 'runtime.dart';

/// A long-lived local process with streaming stdin/stdout/stderr.
class LocalProcessSession implements ProcessSession {
  LocalProcessSession._(this._process);

  final Process _process;
  bool _terminated = false;

  /// Starts a new local process.
  static Future<LocalProcessSession> start(ProcessConfig config) async {
    final process = await Process.start(
      config.command,
      config.arguments,
      workingDirectory: config.workingDirectory,
      environment: config.environment.isNotEmpty ? config.environment : null,
      runInShell: false,
    );
    return LocalProcessSession._(process);
  }

  @override
  Stream<String> get stdout =>
      _process.stdout.transform(const SystemEncoding().decoder);

  @override
  Stream<String> get stderr =>
      _process.stderr.transform(const SystemEncoding().decoder);

  @override
  Future<void> writeStdin(String data) async {
    _process.stdin.write(data);
    await _process.stdin.flush();
  }

  @override
  Future<int> waitForExit() => _process.exitCode;

  @override
  Future<void> terminate() async {
    if (_terminated) return;
    _terminated = true;
    _process.kill();
    // Give the process a moment to exit cleanly.
    await _process.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _process.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
  }

  @override
  bool get isAlive => !_terminated;
}
