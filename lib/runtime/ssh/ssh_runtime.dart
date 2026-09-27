/// SSH Runtime — executes commands and file operations over SSH.
///
/// Implements the [Runtime] interface using SSH exec for commands and SFTP for
/// file operations. All paths are resolved relative to the configured remote
/// root directory and cannot escape it.
///
/// This implementation requires the `dartssh2` package. If not available,
/// operations throw [UnsupportedError] with installation instructions.
library;

import '../runtime.dart';
import 'ssh_host_key_store.dart';

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

  /// Private key content (stored in SecretStore, never in config).
  final String? privateKey;

  /// Passphrase for the private key (stored in SecretStore).
  final String? passphrase;

  /// Remote working directory (default: home directory).
  final String remoteRoot;

  /// Display label.
  final String label;

  /// Whether password authentication is configured.
  bool get hasPassword => password != null && password!.isNotEmpty;

  /// Whether private key authentication is configured.
  bool get hasPrivateKey => privateKey != null && privateKey!.isNotEmpty;

  /// Whether any authentication method is available.
  bool get hasAuth => hasPassword || hasPrivateKey;
}

/// SSH Runtime implementation.
///
/// Provides command execution via SSH exec channel and file operations via
/// SFTP. Connections are pooled and reused for efficiency.
class SshRuntime implements Runtime {
  SshRuntime({
    required this.config,
    required this.hostKeyStore,
  });

  final SshConfig config;
  final SshHostKeyStore hostKeyStore;

  @override
  String get id => config.id;

  @override
  String get label => config.label.isNotEmpty
      ? config.label
      : '${config.username}@${config.host}';

  @override
  RuntimeKind get kind => RuntimeKind.ssh;

  @override
  Future<bool> isAvailable() async {
    // TODO: Implement actual SSH connection test.
    // This requires dartssh2 package.
    return config.hasAuth;
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
    throw UnsupportedError(
      'SSH execution requires dartssh2 package. '
      'Add `dartssh2: ^2.x.x` to pubspec.yaml to enable SSH support.',
    );
  }

  @override
  Future<String> readFile(String path) async {
    throw UnsupportedError('SSH SFTP requires dartssh2 package.');
  }

  @override
  Future<void> writeFile(String path, String content) async {
    throw UnsupportedError('SSH SFTP requires dartssh2 package.');
  }

  @override
  Future<void> deleteFile(String path) async {
    throw UnsupportedError('SSH SFTP requires dartssh2 package.');
  }

  @override
  Future<void> createDirectory(String path) async {
    throw UnsupportedError('SSH SFTP requires dartssh2 package.');
  }

  @override
  Future<void> renameEntry(String path, String newPath) async {
    throw UnsupportedError('SSH SFTP requires dartssh2 package.');
  }

  @override
  Future<void> deleteEntry(String path) async {
    throw UnsupportedError('SSH SFTP requires dartssh2 package.');
  }

  @override
  Future<bool> fileExists(String path) async {
    throw UnsupportedError('SSH SFTP requires dartssh2 package.');
  }

  @override
  Future<List<FileEntry>> listFiles(String path) async {
    throw UnsupportedError('SSH SFTP requires dartssh2 package.');
  }

  /// Tests the SSH connection and returns the host key fingerprint for
  /// user confirmation on first connection.
  Future<SshHostKey> testConnection() async {
    throw UnsupportedError(
      'SSH connection test requires dartssh2 package. '
      'Add `dartssh2: ^2.x.x` to pubspec.yaml to enable SSH support.',
    );
  }

  /// Resolves a relative path against the remote root, preventing escape.
  String resolvePath(String path) {
    if (path.startsWith('/')) {
      // Absolute path — check it's within remote root.
      if (!path.startsWith(config.remoteRoot)) {
        throw ArgumentError('Path escapes remote root: $path');
      }
      return path;
    }
    // Relative path — join with remote root.
    final root = config.remoteRoot.endsWith('/')
        ? config.remoteRoot
        : '${config.remoteRoot}/';
    return '$root$path';
  }
}

/// SSH connection pool for reusing authenticated connections.
class SshConnectionPool {
  SshConnectionPool({this.maxIdle = 3, this.idleTimeout = const Duration(minutes: 5)});

  final int maxIdle;
  final Duration idleTimeout;

  final Map<String, _PooledConnection> _connections = {};

  /// Gets or creates a connection for the given config.
  Future<void> getConnection(SshConfig config) async {
    final key = '${config.host}:${config.port}';
    final existing = _connections[key];
    if (existing != null && !existing.isExpired(idleTimeout)) {
      existing.lastUsed = DateTime.now();
      return;
    }
    // TODO: Create actual SSH connection with dartssh2.
    throw UnsupportedError('SSH connection pool requires dartssh2 package.');
  }

  /// Releases a connection back to the pool.
  void release(SshConfig config) {
    final key = '${config.host}:${config.port}';
    final conn = _connections[key];
    if (conn != null) {
      conn.lastUsed = DateTime.now();
    }
    // Trim pool if over capacity.
    if (_connections.length > maxIdle) {
      _evictOldest();
    }
  }

  /// Closes all pooled connections.
  void closeAll() {
    for (final conn in _connections.values) {
      conn.close();
    }
    _connections.clear();
  }

  void _evictOldest() {
    if (_connections.isEmpty) return;
    final oldest = _connections.entries
        .reduce((a, b) => a.value.lastUsed.isBefore(b.value.lastUsed) ? a : b);
    oldest.value.close();
    _connections.remove(oldest.key);
  }
}

class _PooledConnection {
  _PooledConnection() : lastUsed = DateTime.now();

  DateTime lastUsed;

  bool isExpired(Duration timeout) =>
      DateTime.now().difference(lastUsed) > timeout;

  void close() {
    // TODO: Close actual SSH connection.
  }
}
