/// Bridge process session backed by MethodChannel/EventChannel.
///
/// Starts a long-lived process on the Android host via the Kotlin
/// `RuntimeManager` and streams stdout/stderr over an EventChannel. Stdin
/// writes are forwarded via MethodChannel calls.
///
/// The Kotlin side manages the actual Process lifecycle and relays exit codes.
library;

import 'dart:async';

import 'package:flutter/services.dart';

import 'runtime.dart';

/// Channel names for process management.
const String _eventChannelPrefix = 'agentflow/process_events';

/// A long-lived process running on the Android host via the Kotlin bridge.
///
/// Communication protocol:
/// - `startProcess` MethodChannel call to create the process
/// - EventChannel streams `stdout`, `stderr`, and `exit` events
/// - `writeStdin` MethodChannel call to send data
/// - `terminateProcess` MethodChannel call to kill the process
class BridgeProcessSession implements ProcessSession {
  BridgeProcessSession._({
    required this.sessionId,
    required this.channel,
    required this.eventChannel,
  });

  final String sessionId;
  final MethodChannel channel;
  final EventChannel eventChannel;

  StreamSubscription<dynamic>? _eventSub;
  final StreamController<String> _stdoutController =
      StreamController<String>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();
  final Completer<int> _exitCompleter = Completer<int>();
  bool _alive = true;

  /// Starts a new process on the Android host.
  static Future<BridgeProcessSession> start(
    ProcessConfig config,
    String rootDirectory, {
    MethodChannel? processChannel,
  }) async {
    final channel =
        processChannel ?? const MethodChannel('agentflow/runtime');
    final result = await channel.invokeMethod<Map<dynamic, dynamic>>(
      'startProcess',
      <String, dynamic>{
        'command': config.command,
        'arguments': config.arguments,
        'cwd': config.workingDirectory ?? rootDirectory,
        'env': config.environment,
      },
    );
    final map = result ?? const <dynamic, dynamic>{};
    final sessionId = (map['sessionId'] as String?) ?? '';
    if (sessionId.isEmpty) {
      throw StateError('Android host did not return a session ID.');
    }

    final eventChannel = EventChannel('$_eventChannelPrefix/$sessionId');
    final session = BridgeProcessSession._(
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
          case 'stdout':
            final data = event['data'] as String? ?? '';
            _stdoutController.add(data);
          case 'stderr':
            final data = event['data'] as String? ?? '';
            _stderrController.add(data);
          case 'exit':
            final code = (event['exitCode'] as num?)?.toInt() ?? -1;
            _alive = false;
            if (!_exitCompleter.isCompleted) {
              _exitCompleter.complete(code);
            }
            if (!_stdoutController.isClosed) _stdoutController.close();
            if (!_stderrController.isClosed) _stderrController.close();
        }
      },
      onError: (Object error) {
        _alive = false;
        if (!_exitCompleter.isCompleted) {
          _exitCompleter.complete(-1);
        }
        _stdoutController.addError(error);
      },
      cancelOnError: true,
    );
  }

  @override
  Stream<String> get stdout => _stdoutController.stream;

  @override
  Stream<String> get stderr => _stderrController.stream;

  @override
  Future<void> writeStdin(String data) async {
    await channel.invokeMethod<void>(
      'writeStdin',
      <String, dynamic>{'sessionId': sessionId, 'data': data},
    );
  }

  @override
  Future<int> waitForExit() => _exitCompleter.future;

  @override
  Future<void> terminate() async {
    if (!_alive) return;
    _alive = false;
    await channel.invokeMethod<void>(
      'terminateProcess',
      <String, dynamic>{'sessionId': sessionId},
    );
    // If the exit event hasn't arrived yet, complete it.
    if (!_exitCompleter.isCompleted) {
      _exitCompleter.complete(-1);
    }
    await _eventSub?.cancel();
    // Guard against double-close: the exit event handler may have
    // already closed these controllers.
    if (!_stdoutController.isClosed) await _stdoutController.close();
    if (!_stderrController.isClosed) await _stderrController.close();
  }

  @override
  bool get isAlive => _alive;
}
