/// Runtime abstraction.
///
/// The Agent Core must never depend on Termux, SSH or Docker directly. Tools
/// operate against a [Runtime]; swapping `LocalRuntime` for `BridgeRuntime`
/// (Kotlin/Termux) or a future `SshRuntime` requires no changes above this line.
library;

/// Receives a chunk of output while a command is still running.
typedef OutputCallback = void Function(String chunk);

/// Result of running a shell command through a [Runtime].
class CommandResult {
  const CommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.command = '',
    this.workingDirectory = '',
    this.timedOut = false,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final String command;
  final String workingDirectory;

  /// True when the command was killed after exceeding its timeout.
  final bool timedOut;

  bool get success => exitCode == 0 && !timedOut;

  /// Combined, UI-friendly rendering used by the Terminal panel and tool output.
  String get combinedOutput {
    final buffer = StringBuffer();
    if (stdout.trim().isNotEmpty) buffer.writeln(stdout.trimRight());
    if (stderr.trim().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(stderr.trimRight());
    }
    return buffer.toString();
  }
}

/// A single directory entry returned by [Runtime.listFiles].
class FileEntry {
  const FileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size = 0,
    this.modified,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime? modified;

  String get type => isDirectory ? 'directory' : 'file';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'path': path,
        'type': type,
        'size': size,
        if (modified != null) 'modified': modified!.toIso8601String(),
      };
}

/// Where a runtime executes. Surfaced in Settings so the user knows whether a
/// command runs on-device, in Termux or on a remote host.
enum RuntimeKind { local, termux, ssh, docker }

/// Filesystem + process capabilities available to tools.
abstract class Runtime {
  /// Stable id, persisted alongside workspaces.
  String get id;

  String get label;

  RuntimeKind get kind;

  /// Whether this runtime can actually be reached right now.
  Future<bool> isAvailable();

  /// Runs [command] in [workingDirectory], capturing stdout/stderr/exit code.
  ///
  /// [timeoutMillis] guards against runaway processes; on expiry the result has
  /// [CommandResult.timedOut] set and whatever output was produced.
  Future<CommandResult> execute(
    String command, {
    String? workingDirectory,
    int timeoutMillis = 60000,
    Map<String, String>? environment,
    OutputCallback? onStdout,
    OutputCallback? onStderr,
  });

  Future<String> readFile(String path);

  Future<void> writeFile(String path, String content);

  Future<void> deleteFile(String path);

  /// Creates a directory and any missing parent directories.
  Future<void> createDirectory(String path);

  /// Renames or moves a file or directory within the workspace.
  Future<void> renameEntry(String path, String newPath);

  /// Deletes a file or directory. Non-empty directories are removed recursively.
  Future<void> deleteEntry(String path);

  Future<bool> fileExists(String path);

  Future<List<FileEntry>> listFiles(String path);
}
