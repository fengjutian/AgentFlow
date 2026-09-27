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
    this.preferTermux = true,
  }) : _channel = channel ?? const MethodChannel('agentflow/runtime');

  /// Channel name shared with the Kotlin `RuntimeManager`.
  static const String channelName = 'agentflow/runtime';

  @override
  final String id;
  final MethodChannel _channel;
  final String rootDirectory;

  /// Whether commands may be routed into Termux.
  ///
  /// The Kotlin side still needs Termux to be installed and its `RUN_COMMAND`
  /// permission granted; when either is missing it runs the on-device shell
  /// instead, so leaving this on is safe on any device.
  final bool preferTermux;

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

  /// What the Android host reports about its shell environment.
  ///
  /// Used by the Settings runtime card to explain why commands run where they
  /// do; not part of the [Runtime] contract because no other runtime has it.
  Future<ShellInfo> shellInfo() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('shellInfo');
    final map = result ?? const <dynamic, dynamic>{};
    return ShellInfo(
      shell: (map['shell'] as String?) ?? '',
      home: (map['home'] as String?) ?? '',
      termuxInstalled: (map['termuxInstalled'] as bool?) ?? false,
      termuxPermission: (map['termuxPermission'] as bool?) ?? false,
      termuxUsable: (map['termuxUsable'] as bool?) ?? false,
    );
  }

  /// Asks Android for the Termux `RUN_COMMAND` runtime permission.
  ///
  /// Resolves once the user answered the dialog. It is only grantable while
  /// Termux is installed, and Termux additionally requires
  /// `allow-external-apps=true` in its own `termux.properties`.
  Future<bool> requestTermuxPermission() async {
    try {
      final granted =
          await _channel.invokeMethod<bool>('requestTermuxPermission');
      return granted ?? false;
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
    OutputCallback? onStdout,
    OutputCallback? onStderr,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'executeCommand',
        <String, dynamic>{
          'command': command,
          'cwd': workingDirectory ?? rootDirectory,
          'timeoutMillis': timeoutMillis,
          'env': ?environment,
          'useTermux': preferTermux,
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
  Future<void> deleteFile(String path) => _channel.invokeMethod<void>(
        'deleteFile',
        <String, dynamic>{'path': _abs(path)},
      );

  @override
  Future<void> createDirectory(String path) => _channel.invokeMethod<void>(
        'createDirectory',
        <String, dynamic>{'path': _abs(path)},
      );

  @override
  Future<void> renameEntry(String path, String newPath) =>
      _channel.invokeMethod<void>(
        'renameEntry',
        <String, dynamic>{'path': _abs(path), 'newPath': _abs(newPath)},
      );

  @override
  Future<void> deleteEntry(String path) => _channel.invokeMethod<void>(
        'deleteEntry',
        <String, dynamic>{'path': _abs(path)},
      );

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

/// Shell environment as reported by the Android host over [BridgeRuntime].
class ShellInfo {
  const ShellInfo({
    required this.shell,
    required this.home,
    required this.termuxInstalled,
    required this.termuxPermission,
    required this.termuxUsable,
  });

  /// Absolute path of the shell used for on-device execution.
  final String shell;

  /// Directory the host treats as home for relative paths.
  final String home;

  final bool termuxInstalled;
  final bool termuxPermission;

  /// True when the next command will actually be handed to Termux.
  final bool termuxUsable;

  /// Short human-readable state, e.g. `usable` or `permission missing`.
  String get termuxState {
    if (termuxUsable) return 'usable';
    if (!termuxInstalled) return 'not installed';
    if (!termuxPermission) return 'permission missing';
    return 'unavailable';
  }
}
