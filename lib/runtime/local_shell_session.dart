/// Local interactive shell session using `dart:io` [Process].
///
/// Starts a persistent shell process (bash on Linux/macOS, cmd.exe on Windows)
/// with `runInShell: true` so the user gets a real interactive shell with line
/// editing, job control and environment variables. Output arrives as raw text
/// that may include ANSI escape sequences.
///
/// True PTY allocation (required for full-screen programs like vim) is not
/// available through `dart:io`; this implementation uses
/// [ProcessStartMode.normal] with stdin/stdout pipes. For a richer terminal
/// experience on Android, use [BridgeShellSession] which delegates to a
/// Kotlin-managed PTY.
library;

import 'dart:async';
import 'dart:io';

import 'shell_session.dart';

/// A persistent local shell process with bidirectional stdin/stdout.
class LocalShellSession implements ShellSession {
  LocalShellSession._(this._process);

  final Process _process;
  bool _alive = true;
  int _rows = 24;
  int _cols = 80;

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  StreamSubscription<List<int>>? _stdoutSub;
  StreamSubscription<List<int>>? _stderrSub;

  /// Starts a new interactive shell.
  ///
  /// [initialRows] and [initialCols] set the terminal size reported via
  /// environment variables (LINES and COLUMNS). True PTY allocation requires
  /// native code and is not available in `dart:io`.
  static Future<LocalShellSession> start({
    int initialRows = 24,
    int initialCols = 80,
    String? workingDirectory,
  }) async {
    final isWindows = Platform.isWindows;
    final command = isWindows ? 'cmd.exe' : (Platform.environment['SHELL'] ?? 'sh');
    final arguments = isWindows ? <String>[] : <String>[];

    final env = <String, String>{
      'TERM': 'xterm-256color',
      'LINES': '$initialRows',
      'COLUMNS': '$initialCols',
    };

    final process = await Process.start(
      command,
      arguments,
      workingDirectory: workingDirectory,
      environment: env,
      runInShell: false,
    );

    final session = LocalShellSession._(process)
      .._rows = initialRows
      .._cols = initialCols;
    session._listen();
    return session;
  }

  void _listen() {
    _stdoutSub = _process.stdout.listen(
      (List<int> data) {
        _outputController.add(const SystemEncoding().decoder.convert(data));
      },
      onDone: _onExit,
      onError: (Object _) => _onExit(),
    );
    _stderrSub = _process.stderr.listen(
      (List<int> data) {
        _outputController.add(const SystemEncoding().decoder.convert(data));
      },
      onDone: _onExit,
      onError: (Object _) => _onExit(),
    );
    unawaited(_process.exitCode.then((_) => _onExit()));
  }

  void _onExit() {
    if (!_alive) return;
    _alive = false;
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    if (!_outputController.isClosed) _outputController.close();
  }

  @override
  Stream<String> get output => _outputController.stream;

  @override
  Future<void> writeStdin(String data) async {
    _process.stdin.write(data);
    await _process.stdin.flush();
  }

  @override
  Future<void> sendSignal(TerminalSignal signal) async {
    if (!_alive) return;
    switch (signal) {
      case TerminalSignal.ctrlC:
        // Send ETX (0x03) — the ASCII control character for Ctrl+C.
        _process.stdin.add(<int>[0x03]);
        await _process.stdin.flush();
      case TerminalSignal.ctrlD:
        // Send EOT (0x04) — signals EOF.
        _process.stdin.add(<int>[0x04]);
        await _process.stdin.flush();
      case TerminalSignal.ctrlZ:
        // Send SUB (0x1A) — the ASCII control character for Ctrl+Z.
        _process.stdin.add(<int>[0x1A]);
        await _process.stdin.flush();
    }
  }

  @override
  Future<void> resize(int rows, int cols) async {
    _rows = rows;
    _cols = cols;
    // Without a real PTY we cannot send SIGWINCH to the shell.
    // Programs that read $LINES / $COLUMNS at startup will use the initial
    // values; interactive programs like vim won't respond to resize.
  }

  /// The terminal dimensions last passed to [resize].
  int get rows => _rows;
  int get cols => _cols;

  @override
  Future<int> waitForExit() => _process.exitCode;

  @override
  Future<void> close() async {
    if (!_alive) return;
    _alive = false;
    _process.kill();
    await _process.exitCode.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        _process.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    if (!_outputController.isClosed) await _outputController.close();
  }

  @override
  bool get isAlive => _alive;
}
