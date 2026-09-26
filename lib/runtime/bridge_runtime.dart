/// Kotlin/Termux-backed runtime reached over a [MethodChannel].
///
/// Mirrors the same [Runtime] contract as [LocalRuntime] but forwards every call
/// to the Android host, which decides whether to run it in Termux, a PTY or
/// plain Android APIs. The Agent Core cannot tell the difference — that is the
/// whole point of the abstraction.
library;

import 'package:flutter/services.dart';

import 'runtime.dart';

class BridgeRuntime implements Runtime {
  BridgeRuntime({
    required this.rootDirectory,
    MethodChannel? channel,
    this.id = 'termux',
  }) : _channel = channel ?? const MethodChannel('agentflow/runtime');

  /// Channel name shared with the Kotlin `RuntimeManager`.
  static const String channelName = 'agentflow/runtime';

  final String id;
  final MethodChannel _channel;
  final String rootDirectory;

  @override
  String get label => 'Termux';

  @override
  RuntimeKind get kind => RuntimeKind.termux;

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<CommandResult> execute(
    String command, {
    String? workingDirectory,
    int timeoutMillis = 60000,
    Map<String, String>? environment,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'executeCommand',
        <String, dynamic>{
          'command': command,
          'cwd': workingDirectory ?? rootDirectory,
          'timeoutMillis': timeoutMillis,
          if (environment != null) 'env': environment,
        },
      );
      final map = result ?? const <dynamic, dynamic>{};
      return CommandResult(
        exitCode: (map['exitCode'] as num?)?.toInt() ?? -1,
        stdout: (map['stdout'] as String?) ?? '',
        stderr: (map['stderr'] as String?) ?? '',
        command: command,
        workingDirectory: workingDirectory ?? rootDirectory,
        timedOut: (map['timedOut'] as bool?) ?? false,
      );
    } on PlatformException catch (e) {
      return CommandResult(
        exitCode: -1,
        stdout: '',
        stderr: 'Bridge error: ${e.message}',
        command: command,
        workingDirectory: workingDirectory ?? rootDirectory,
      );
    }
  }

  @override
  Future<String> readFile(String path) async {
    final content = await _channel.invokeMethod<String>(
      'readFile',
      <String, dynamic>{'path': _abs(path)},
    );
    return content ?? '';
  }

  @override
  Future<void> writeFile(String path, String content) async {
    await _channel.invokeMethod<void>(
      'writeFile',
      <String, dynamic>{'path': _abs(path), 'content': content},
    );
  }

  @override
  Future<bool> fileExists(String path) async {
    final exists = await _channel.invokeMethod<bool>(
      'fileExists',
      <String, dynamic>{'path': _abs(path)},
    );
    return exists ?? false;
  }

  @override
  Future<List<FileEntry>> listFiles(String path) async {
    final result = await _channel.invokeMethod<List<dynamic>>(
      'listFiles',
      <String, dynamic>{'path': _abs(path)},
    );
    if (result == null) return const <FileEntry>[];
    return result.map((dynamic raw) {
      final map = (raw as Map).cast<dynamic, dynamic>();
      return FileEntry(
        name: (map['name'] as String?) ?? '',
        path: (map['path'] as String?) ?? '',
        isDirectory: (map['type'] as String?) == 'directory',
        size: (map['size'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  String _abs(String path) =>
      path.startsWith('/') ? path : '$rootDirectory/$path';
}
