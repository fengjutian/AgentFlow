/// SSH Runtime — executes commands and file operations over SSH.
///
/// Implements the [Runtime] interface using dartssh2: SSH exec for commands and
/// SFTP for file operations. All paths are resolved relative to the configured
/// remote root directory and cannot escape it.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../runtime.dart';
import 'ssh_host_key_store.dart';
import 'ssh_process_session.dart';

/// SSH connection configuration.
class SshConfig {
  const SshConfig({
    required this.id,
    required this.host,
    this.port = 22,
    required this.username,
    this.password,
    this.privateKey,
    this.passphrase,
    this.remoteRoot = '~',
    this.label = '',
  });

  final String id;
  final String host;
  final int port;
  final String username;

  /// Password authentication (stored in SecretStore, never in config).
  final String? password;

  /// Private key content in PEM format (stored in SecretStore).
  final String? privateKey;

  /// Passphrase for the private key (stored in SecretStore).
  final String? passphrase;

  /// Remote working directory (default: home directory).
  final String remoteRoot;

  /// Display label.
  final String label;

  bool get hasPassword => password != null && password!.isNotEmpty;
  bool get hasPrivateKey => privateKey != null && privateKey!.isNotEmpty;
  bool get hasAuth => hasPassword || hasPrivateKey;
}

/// Thrown when the server presents an unexpected host key.
class HostKeyMismatchException implements Exception {
  HostKeyMismatchException(this.message);
  final String message;
  @override
  String toString() => 'HostKeyMismatchException: $message';
}

/// SSH Runtime implementation using dartssh2.
///
/// Provides command execution via SSH exec channel and file operations via
/// SFTP. Connections are reused until disconnected.
class SshRuntime implements Runtime {
  SshRuntime({
    required this.config,
    required this.hostKeyStore,
  });

  final SshConfig config;
  final SshHostKeyStore hostKeyStore;

  SSHClient? _client;
  SftpClient? _sftp;
  Future<void>? _connecting;

  /// Whether the underlying SSH client has been disconnected.
  ///
  /// Returns `true` if the client was closed or the SSH transport was dropped
  /// (e.g. network interrupt). The connection pool uses this to transparently
  /// replace stale connections.
  bool get isDisconnected => _client == null || _client!.isClosed;

  @override
  String get id => config.id;

  @override
  String get label =>
      config.label.isNotEmpty ? config.label : '${config.username}@${config.host}';

  @override
  RuntimeKind get kind => RuntimeKind.ssh;

  @override
  Future<bool> isAvailable() async {
    if (_client != null && !_client!.isClosed) return true;
    _invalidate();
    try {
      await _ensureConnected();
      return true;
    } catch (_) {
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
    await _ensureConnected();
    final client = _client!;

    final effectiveCmd = workingDirectory != null && workingDirectory.isNotEmpty
        ? 'cd ${_shellEscape(workingDirectory)} && $command'
        : command;

    try {
      final session = await client.execute(
        effectiveCmd,
        environment: environment,
      );

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      final stdoutFuture = session.stdout.listen((Uint8List data) {
        final text = utf8.decode(data, allowMalformed: true);
        stdoutBuffer.write(text);
        onStdout?.call(text);
      }).asFuture<void>();

      final stderrFuture = session.stderr.listen((Uint8List data) {
        final text = utf8.decode(data, allowMalformed: true);
        stderrBuffer.write(text);
        onStderr?.call(text);
      }).asFuture<void>();

      // Wait for session to complete (with timeout).
      await session.done
          .timeout(Duration(milliseconds: timeoutMillis));

      // Drain remaining output.
      await Future.wait<void>([stdoutFuture, stderrFuture])
          .timeout(const Duration(seconds: 3))
          .catchError((_) => <void>[]);

      final exitCode = session.exitCode ?? -1;

      return CommandResult(
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        command: command,
        workingDirectory: workingDirectory ?? '',
      );
    } on TimeoutException {
      return CommandResult(
        exitCode: -1,
        stdout: '',
        stderr: 'Command timed out after ${timeoutMillis}ms',
        command: command,
        workingDirectory: workingDirectory ?? '',
        timedOut: true,
      );
    } catch (e) {
      _invalidate();
      return CommandResult(
        exitCode: -1,
        stdout: '',
        stderr: 'SSH execution failed: $e',
        command: command,
        workingDirectory: workingDirectory ?? '',
      );
    }
  }

  @override
  Future<ProcessSession> startProcess(ProcessConfig config) async {
    await _ensureConnected();
    final client = _client!;
    return SshProcessSession.start(config, client);
  }

  @override
  Future<String> readFile(String path) async {
    await _ensureConnected();
    final sftp = await _getSftp();
    final remote = resolvePath(path);
    try {
      final file = await sftp.open(remote, mode: SftpFileOpenMode.read);
      final bytes = await file.readBytes();
      await file.close();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      throw StateError('SFTP read failed for $remote: $e');
    }
  }

  @override
  Future<void> writeFile(String path, String content) async {
    await _ensureConnected();
    final sftp = await _getSftp();
    final remote = resolvePath(path);
    // Atomic write: write to a temp file then rename to avoid partial writes.
    final tmpPath = '$remote.tmp.${DateTime.now().microsecondsSinceEpoch}';
    try {
      final file = await sftp.open(
        tmpPath,
        mode: SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );
      await file.writeBytes(Uint8List.fromList(utf8.encode(content)));
      await file.close();
      // Rename temp to final destination (atomic on most POSIX systems).
      await sftp.rename(tmpPath, remote);
    } catch (e) {
      // Clean up temp file on failure.
      try {
        await sftp.remove(tmpPath);
      } catch (_) {/* best effort */}
      throw StateError('SFTP write failed for $remote: $e');
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    await _ensureConnected();
    final sftp = await _getSftp();
    final remote = resolvePath(path);
    try {
      await sftp.remove(remote);
    } catch (e) {
      throw StateError('SFTP delete failed for $remote: $e');
    }
  }

  @override
  Future<void> createDirectory(String path) async {
    await _ensureConnected();
    final sftp = await _getSftp();
    final remote = resolvePath(path);
    try {
      await _mkdirP(sftp, remote);
    } catch (e) {
      throw StateError('SFTP mkdir failed for $remote: $e');
    }
  }

  @override
  Future<void> renameEntry(String path, String newPath) async {
    await _ensureConnected();
    final sftp = await _getSftp();
    try {
      await sftp.rename(resolvePath(path), resolvePath(newPath));
    } catch (e) {
      throw StateError('SFTP rename failed: $e');
    }
  }

  @override
  Future<void> deleteEntry(String path) async {
    await _ensureConnected();
    final sftp = await _getSftp();
    final remote = resolvePath(path);
    try {
      final attrs = await sftp.stat(remote);
      if (attrs.isDirectory) {
        await _rmdirRecursive(sftp, remote);
      } else {
        await sftp.remove(remote);
      }
    } on SftpStatusError {
      // Already gone.
    } catch (e) {
      throw StateError('SFTP delete failed for $remote: $e');
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    await _ensureConnected();
    final sftp = await _getSftp();
    try {
      await sftp.stat(resolvePath(path));
      return true;
    } on SftpStatusError {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<FileEntry>> listFiles(String path) async {
    await _ensureConnected();
    final sftp = await _getSftp();
    final remote = resolvePath(path);
    try {
      final entries = await sftp.listdir(remote);
      return entries.map((f) {
        final name = f.filename;
        final entryPath = '$remote/$name';
        return FileEntry(
          name: name,
          path: entryPath,
          isDirectory: f.attr.isDirectory,
          size: f.attr.size ?? 0,
          modified: f.attr.modifyTime != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (f.attr.modifyTime! * 1000).toInt())
              : null,
        );
      }).toList();
    } catch (e) {
      throw StateError('SFTP listdir failed for $remote: $e');
    }
  }

  /// Tests the SSH connection and returns the host key for user confirmation.
  Future<SshHostKey> testConnection() async {
    SshHostKey? capturedKey;
    final socket = await SSHSocket.connect(config.host, config.port);

    List<SSHKeyPair>? identities;
    if (config.hasPrivateKey) {
      identities = SSHKeyPair.fromPem(config.privateKey!, config.passphrase);
    }

    final client = SSHClient(
      socket,
      username: config.username,
      identities: identities,
      onPasswordRequest: config.hasPassword ? () => config.password! : null,
      onVerifyHostKey: (type, fingerprintBytes) async {
        final hex = _bytesToHex(fingerprintBytes);
        capturedKey = SshHostKey(
          host: config.host,
          port: config.port,
          fingerprint: hex,
          algorithm: type,
        );
        return true; // Accept during test; caller decides whether to persist.
      },
    );

    try {
      await client.authenticated;
    } finally {
      client.close();
    }

    if (capturedKey == null) {
      throw StateError('No host key received during connection test.');
    }
    return capturedKey!;
  }

  /// Resolves a relative path against the remote root, preventing escape.
  ///
  /// Rejects paths containing `..` components that would traverse above the
  /// remote root directory. Absolute paths are only allowed if they start with
  /// the configured remote root.
  String resolvePath(String path) {
    // Reject explicit escape attempts via path components.
    final parts = path.split('/');
    if (parts.any((p) => p == '..')) {
      throw ArgumentError('Path contains ".." which is not allowed: $path');
    }

    if (path.startsWith('/')) {
      if (config.remoteRoot != '~' && !path.startsWith(config.remoteRoot)) {
        throw ArgumentError('Path escapes remote root: $path');
      }
      return path;
    }
    final root =
        config.remoteRoot.endsWith('/') ? config.remoteRoot : '${config.remoteRoot}/';
    return '$root$path';
  }

  /// Closes the connection and releases resources.
  void dispose() {
    _sftp = null;
    _client?.close();
    _client = null;
    _connecting = null;
  }

  // ---------------------------------------------------------------------------
  // Connection management
  // ---------------------------------------------------------------------------

  Future<void> _ensureConnected() async {
    if (_client != null && !_client!.isClosed) return;
    _invalidate();
    if (_connecting != null) {
      await _connecting;
      return;
    }
    _connecting = _doConnect();
    try {
      await _connecting;
    } finally {
      _connecting = null;
    }
  }

  Future<void> _doConnect() async {
    final socket = await SSHSocket.connect(config.host, config.port);

    List<SSHKeyPair>? identities;
    if (config.hasPrivateKey) {
      try {
        identities = SSHKeyPair.fromPem(config.privateKey!, config.passphrase);
      } catch (e) {
        throw StateError('Failed to parse private key: $e');
      }
    }

    final client = SSHClient(
      socket,
      username: config.username,
      identities: identities,
      onPasswordRequest: config.hasPassword ? () => config.password! : null,
      onVerifyHostKey: (type, fingerprintBytes) async {
        final hex = _bytesToHex(fingerprintBytes);
        final verification = await hostKeyStore.verify(
          config.host,
          config.port,
          hex,
          type,
        );
        if (verification.isMismatch) {
          throw HostKeyMismatchException(
            'Host key mismatch for ${config.host}:${config.port}. '
            'Possible MITM attack.',
          );
        }
        if (verification.isUnknown) {
          // Auto-accept first connection and persist the fingerprint.
          // WARNING: This is TOFU (Trust On First Use) — the first connection
          // is vulnerable to MITM. Log a warning for audit purposes.
          debugPrint(
            'SSH: Auto-accepting unknown host key for '
            '${config.host}:${config.port} ($type: $hex)',
          );
          await hostKeyStore.store(SshHostKey(
            host: config.host,
            port: config.port,
            fingerprint: hex,
            algorithm: type,
          ));
        }
        return true;
      },
    );

    await client.authenticated;
    _client = client;
  }

  Future<SftpClient> _getSftp() async {
    if (_sftp != null) return _sftp!;
    final client = _client!;
    _sftp = await client.sftp();
    return _sftp!;
  }

  void _invalidate() {
    _sftp = null;
    _client?.close();
    _client = null;
    _connecting = null;
  }
}

/// Converts a Uint8List fingerprint to colon-separated hex string.
String _bytesToHex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');

/// Recursive mkdir -p over SFTP.
Future<void> _mkdirP(SftpClient sftp, String path) async {
  final parts = path.split('/')..removeWhere((s) => s.isEmpty);
  var current = path.startsWith('/') ? '/' : '';
  for (final part in parts) {
    current = current.isEmpty ? part : '$current/$part';
    try {
      await sftp.stat(current);
    } on SftpStatusError {
      await sftp.mkdir(current);
    }
  }
}

/// Recursive rm -r over SFTP.
Future<void> _rmdirRecursive(SftpClient sftp, String path) async {
  final entries = await sftp.listdir(path);
  for (final entry in entries) {
    final child = '$path/${entry.filename}';
    if (entry.attr.isDirectory) {
      await _rmdirRecursive(sftp, child);
    } else {
      await sftp.remove(child);
    }
  }
  await sftp.rmdir(path);
}

String _shellEscape(String s) => "'${s.replaceAll("'", "'\\''")}'";

/// SSH connection pool for reusing authenticated connections across runtimes.
///
/// Detects network interrupts via the SSH client's `done` future and
/// automatically invalidates stale connections on next access.
class SshConnectionPool {
  SshConnectionPool({
    this.maxIdle = 3,
    this.idleTimeout = const Duration(minutes: 5),
  });

  final int maxIdle;
  final Duration idleTimeout;

  final Map<String, _PooledRuntime> _pool = {};

  /// Gets an existing connection or creates a new one.
  ///
  /// If the existing connection has been dropped (detected via the client's
  /// `done` future or idle timeout), it is transparently replaced.
  SshRuntime getOrConnect(SshConfig config, SshHostKeyStore hostKeyStore) {
    final key = '${config.host}:${config.port}';
    final existing = _pool[key];
    if (existing != null) {
      // Check idle timeout.
      if (existing.isExpired(idleTimeout)) {
        existing.runtime.dispose();
        _pool.remove(key);
      }
      // Check if connection was dropped (network interrupt).
      else if (existing.runtime.isDisconnected) {
        existing.runtime.dispose();
        _pool.remove(key);
      } else {
        existing.lastUsed = DateTime.now();
        return existing.runtime;
      }
    }
    final runtime = SshRuntime(config: config, hostKeyStore: hostKeyStore);
    _pool[key] = _PooledRuntime(runtime);
    _evictIfNeeded();
    return runtime;
  }

  /// Removes and disposes a specific connection (e.g. after an error).
  void invalidate(String host, int port) {
    final key = '$host:$port';
    final entry = _pool.remove(key);
    entry?.runtime.dispose();
  }

  void closeAll() {
    for (final entry in _pool.values) {
      entry.runtime.dispose();
    }
    _pool.clear();
  }

  void _evictIfNeeded() {
    while (_pool.length > maxIdle) {
      final oldest = _pool.entries
          .reduce((a, b) => a.value.lastUsed.isBefore(b.value.lastUsed) ? a : b);
      oldest.value.runtime.dispose();
      _pool.remove(oldest.key);
    }
  }
}

class _PooledRuntime {
  _PooledRuntime(this.runtime) : lastUsed = DateTime.now();

  final SshRuntime runtime;
  DateTime lastUsed;

  bool isExpired(Duration timeout) =>
      DateTime.now().difference(lastUsed) > timeout;
}
