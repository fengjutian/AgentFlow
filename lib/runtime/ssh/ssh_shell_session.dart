/// SSH shell session backed by a dartssh2 interactive shell channel.
///
/// Opens an SSH shell (channel type `session` → `shell`) with a PTY request
/// so that full-screen programs work over the network. The channel's stdout
/// and stdin are wired to [output] and [writeStdin]; signals are forwarded as
/// SSH signal requests; resize triggers a `window-change` channel request.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import '../shell_session.dart';

/// An interactive shell session running on a remote host via SSH.
///
/// The SSH server allocates a PTY for the channel, so full-screen programs
/// (vim, htop, top) work correctly. Window-change requests from [resize]
/// are forwarded to the server.
class SshShellSession implements ShellSession {
  SshShellSession._({
    required this.shell,
    required this.client,
  });

  final SSHSession shell;
  final SSHClient client;

  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  final Completer<int> _exitCompleter = Completer<int>();
  bool _alive = true;
  StreamSubscription<Uint8List>? _stdoutSub;

  /// Starts an interactive shell on the remote host.
  static Future<SshShellSession> start({
    required SSHClient client,
    required int rows,
    required int cols,
  }) async {
    final shell = await client.shell(
      pty: SSHPtyConfig(
        type: 'xterm-256color',
        width: cols,
        height: rows,
      ),
    );

    final session = SshShellSession._(shell: shell, client: client);
    session._listen();
    return session;
  }

  void _listen() {
    _stdoutSub = shell.stdout.listen(
      (Uint8List data) {
        _outputController.add(utf8.decode(data, allowMalformed: true));
      },
      onDone: _onDone,
      onError: (Object _) => _onDone(),
    );

    // Listen for shell exit.
    shell.done.then((_) => _onDone()).catchError((Object _) => _onDone());
  }

  void _onDone() {
    if (!_alive) return;
    _alive = false;
    final exitCode = shell.exitCode ?? -1;
    if (!_exitCompleter.isCompleted) _exitCompleter.complete(exitCode);
    _stdoutSub?.cancel();
    if (!_outputController.isClosed) _outputController.close();
  }

  @override
  Stream<String> get output => _outputController.stream;

  @override
  Future<void> writeStdin(String data) async {
    shell.stdin.add(utf8.encode(data));
  }

  @override
  Future<void> sendSignal(TerminalSignal signal) async {
    if (!_alive) return;
    switch (signal) {
      case TerminalSignal.ctrlC:
        shell.stdin.add(Uint8List.fromList(<int>[0x03]));
      case TerminalSignal.ctrlD:
        shell.stdin.add(Uint8List.fromList(<int>[0x04]));
      case TerminalSignal.ctrlZ:
        shell.stdin.add(Uint8List.fromList(<int>[0x1A]));
    }
  }

  @override
  Future<void> resize(int rows, int cols) async {
    if (!_alive) return;
    try {
      shell.resizeTerminal(cols, rows);
    } catch (_) {
      // Some SSH servers do not support window-change requests.
    }
  }

  @override
  Future<int> waitForExit() => _exitCompleter.future;

  @override
  Future<void> close() async {
    if (!_alive) return;
    _alive = false;
    shell.close();
    if (!_exitCompleter.isCompleted) _exitCompleter.complete(-1);
    await _stdoutSub?.cancel();
    if (!_outputController.isClosed) await _outputController.close();
  }

  @override
  bool get isAlive => _alive;
}
