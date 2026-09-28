/// Bridge shell session that delegates to a Kotlin-managed PTY on Android.
///
/// The Kotlin side allocates a real PTY (via `posix_openpt` / `openpty`) so
/// that full-screen programs (vim, htop, nano) work correctly. Communication
/// protocol mirrors [BridgeProcessSession] but adds PTY-specific methods:
/// `resizeShell` and `sendSignal`.
library;

import 'dart:async';

import 'package:flutter/services.dart';

import 'shell_session.dart';

/// Event channel prefix for shell output streaming.
const String _eventChannelPrefix = 'agentflow/shell_events';

/// An interactive shell session running on the Android host via the Kotlin
/// bridge, backed by a real PTY.
///
/// Communication protocol:
/// - `startShell` MethodChannel call creates the PTY and shell process
/// - EventChannel streams `output` and `exit` events
/// - `writeStdin` sends keystrokes to the shell
/// - `resizeShell` updates PTY dimensions (SIGWINCH)
/// - `sendSignal` sends Ctrl+C / Ctrl+D / Ctrl+Z
/// - `closeShell` terminates the process
class BridgeShellSession implements ShellSession {
  BridgeShellSession._({
    required this.sessionId,
    required this.channel,
    required this.eventChannel,
  });

  final String sessionId;
  final MethodChannel channel;
  final EventChannel eventChannel;

  StreamSubscription<dynamic>? _eventSub;
  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  final Completer<int> _exitCompleter = Completer<int>();
  bool _alive = true;

  /// Starts a new shell session on the Android host.
  static Future<BridgeShellSession> start({
    required int rows,
    required int cols,
    String? workingDirectory,
    MethodChannel? processChannel,
  }) async {
    final channel =
        processChannel ?? const MethodChannel('agentflow/runtime');
    final result = await channel.invokeMethod<Map<dynamic, dynamic>>(
      'startShell',
      <String, dynamic>{
        'rows': rows,
        'cols': cols,
        ?'cwd': workingDirectory,
      },
    );
    final map = result ?? const <dynamic, dynamic>{};
    final sessionId = (map['sessionId'] as String?) ?? '';
    if (sessionId.isEmpty) {
      throw StateError('Android host did not return a shell session ID.');
    }

    final eventChannel = EventChannel('$_eventChannelPrefix/$sessionId');
    final session = BridgeShellSession._(
      sessionId: sessionId,
      channel: channel,
      eventChannel: eventChannel,
    );
    session._listen();
    return session;
  }

  void _listen() {
    _eventSub = eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is! Map) return;
        final type = event['type'] as String?;
        switch (type) {
          case 'output':
            final data = event['data'] as String? ?? '';
            _outputController.add(data);
          case 'exit':
            final code = (event['exitCode'] as num?)?.toInt() ?? -1;
            _alive = false;
            if (!_exitCompleter.isCompleted) _exitCompleter.complete(code);
            if (!_outputController.isClosed) _outputController.close();
        }
      },
      onError: (Object error) {
        _alive = false;
        if (!_exitCompleter.isCompleted) _exitCompleter.complete(-1);
        _outputController.addError(error);
      },
      cancelOnError: true,
    );
  }

  @override
  Stream<String> get output => _outputController.stream;

  @override
  Future<void> writeStdin(String data) async {
    await channel.invokeMethod<void>(
      'writeStdin',
      <String, dynamic>{'sessionId': sessionId, 'data': data},
    );
  }

  @override
  Future<void> sendSignal(TerminalSignal signal) async {
    final name = switch (signal) {
      TerminalSignal.ctrlC => 'SIGINT',
      TerminalSignal.ctrlD => 'EOF',
      TerminalSignal.ctrlZ => 'SIGTSTP',
    };
    await channel.invokeMethod<void>(
      'sendSignal',
      <String, dynamic>{'sessionId': sessionId, 'signal': name},
    );
  }

  @override
  Future<void> resize(int rows, int cols) async {
    await channel.invokeMethod<void>(
      'resizeShell',
      <String, dynamic>{
        'sessionId': sessionId,
        'rows': rows,
        'cols': cols,
      },
    );
  }

  @override
  Future<int> waitForExit() => _exitCompleter.future;

  @override
  Future<void> close() async {
    if (!_alive) return;
    _alive = false;
    await channel.invokeMethod<void>(
      'closeShell',
      <String, dynamic>{'sessionId': sessionId},
    );
    if (!_exitCompleter.isCompleted) _exitCompleter.complete(-1);
    await _eventSub?.cancel();
    if (!_outputController.isClosed) await _outputController.close();
  }

  @override
  bool get isAlive => _alive;
}
