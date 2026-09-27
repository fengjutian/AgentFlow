/// SSH process session backed by a dartssh2 exec channel.
///
/// Starts a long-lived command on the remote host via SSH exec and exposes
/// stdin/stdout/stderr as bidirectional streams. Used for stdio MCP servers
/// running on a remote host and streaming terminal sessions.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import '../runtime.dart';

/// A long-lived process running on a remote host via SSH exec.
class SshProcessSession implements ProcessSession {
  SshProcessSession._({
    required this.session,
  });

  final SSHSession session;

  final StreamController<String> _stdoutController =
      StreamController<String>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();
  final Completer<int> _exitCompleter = Completer<int>();
  bool _alive = true;
  StreamSubscription<Uint8List>? _stdoutSub;
  StreamSubscription<Uint8List>? _stderrSub;

  /// Starts a new process on the remote host.
  static Future<SshProcessSession> start(
    ProcessConfig config,
    SSHClient client,
  ) async {
    final command = config.arguments.isEmpty
        ? config.command
        : '${config.command} ${config.arguments.map(_shellQuote).join(' ')}';

    final sshSession = await client.execute(
      command,
      environment: config.environment.isNotEmpty ? config.environment : null,
    );

    final processSession = SshProcessSession._(session: sshSession);
    processSession._listen();
    return processSession;
  }

  void _listen() {
    _stdoutSub = session.stdout.listen(
      (Uint8List data) {
        _stdoutController.add(utf8.decode(data, allowMalformed: true));
      },
      onDone: () {
        _onDone();
      },
      onError: (Object error) {
        _stdoutController.addError(error);
      },
    );

    _stderrSub = session.stderr.listen(
      (Uint8List data) {
        _stderrController.add(utf8.decode(data, allowMalformed: true));
      },
      onDone: () {
        _onDone();
      },
      onError: (Object error) {
        _stderrController.addError(error);
      },
    );

    // Listen for session exit.
    session.done.then((_) {
      _onDone();
    }).catchError((Object error) {
      if (!_exitCompleter.isCompleted) {
        _exitCompleter.complete(-1);
      }
      _alive = false;
    });
  }

  void _onDone() {
    if (_alive) {
      _alive = false;
      final exitCode = session.exitCode ?? -1;
      if (!_exitCompleter.isCompleted) {
        _exitCompleter.complete(exitCode);
      }
      _stdoutController.close();
      _stderrController.close();
    }
  }

  @override
  Stream<String> get stdout => _stdoutController.stream;

  @override
  Stream<String> get stderr => _stderrController.stream;

  @override
  Future<void> writeStdin(String data) async {
    session.stdin.add(utf8.encode(data));
  }

  @override
  Future<int> waitForExit() => _exitCompleter.future;

  @override
  Future<void> terminate() async {
    if (!_alive) return;
    _alive = false;
    session.close();
    if (!_exitCompleter.isCompleted) {
      _exitCompleter.complete(-1);
    }
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    await _stdoutController.close();
    await _stderrController.close();
  }

  @override
  bool get isAlive => _alive;

  static final _needsQuoting = RegExp(r"""[\s"'\\$`!]""");

  static String _shellQuote(String arg) {
    if (arg.contains(_needsQuoting)) {
      return "'${arg.replaceAll("'", "'\\''")}'";
    }
    return arg;
  }
}
