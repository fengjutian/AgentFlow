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

/// A long-lived bidirectional process session.
///
/// Unlike [Runtime.execute], which runs a command to completion and returns
/// the captured output, a [ProcessSession] keeps stdin open for writing while
/// exposing stdout and stderr as asynchronous streams. This is required for
/// interactive protocols such as stdio MCP and streaming terminal output.
///
/// Implementations: [LocalProcessSession], [BridgeProcessSession],
/// [SshProcessSession].
abstract class ProcessSession {
  /// Stream of stdout chunks as they arrive.
  Stream<String> get stdout;

  /// Stream of stderr chunks as they arrive.
  Stream<String> get stderr;

  /// Writes data to the process's stdin.
  ///
  /// The data is written as-is; callers are responsible for adding newlines
  /// if the protocol requires them.
  Future<void> writeStdin(String data);

  /// Waits for the process to exit and returns its exit code.
  Future<int> waitForExit();

  /// Sends a termination signal to the process.
  Future<void> terminate();

  /// Whether the process has already exited.
  bool get isAlive;
}

/// Configuration for starting a long-lived process.
class ProcessConfig {
  const ProcessConfig({
    required this.command,
    this.arguments = const <String>[],
    this.workingDirectory,
    this.environment = const <String, String>{},
  });

  final String command;
  final List<String> arguments;
  final String? workingDirectory;
  final Map<String, String> environment;
}

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

  /// Starts a long-lived process with bidirectional stdin/stdout.
  ///
  /// Used for stdio MCP servers and streaming terminal sessions. The caller
  /// owns the returned [ProcessSession] and must call [ProcessSession.terminate]
  /// when done.
  Future<ProcessSession> startProcess(ProcessConfig config);

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
