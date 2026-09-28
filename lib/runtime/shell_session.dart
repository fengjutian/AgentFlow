/// Persistent interactive shell session with PTY support.
///
/// Unlike [ProcessSession], which runs a single long-lived command, a
/// [ShellSession] is an interactive terminal shell: stdin/stdout are connected
/// to a real shell process (bash, sh, PowerShell), the user can send special
/// signals (Ctrl+C, Ctrl+D, Ctrl+Z), and the terminal dimensions can be
/// resized so full-screen programs (vim, htop, nano) work correctly.
///
/// Implementations: [LocalShellSession], [BridgeShellSession], [SshShellSession].
library;

/// Signals that can be sent to the running shell process.
enum TerminalSignal {
  /// SIGINT — interrupt the current foreground process.
  ctrlC,

  /// EOF — close stdin (often exits the shell).
  ctrlD,

  /// SIGTSTP — suspend the current foreground process.
  ctrlZ,
}

/// An interactive shell session with PTY capabilities.
///
/// The session owns a single shell process. Output from that process arrives
/// on [output] as raw bytes (including ANSI escape sequences) that the
/// terminal widget can parse and render. Keyboard input is forwarded via
/// [writeStdin]. Special keys (Ctrl+C, etc.) are sent via [sendSignal].
///
/// Callers own the lifecycle: call [close] when the terminal tab is disposed
/// or the user logs out.
abstract class ShellSession {
  /// Raw output from the shell, including ANSI escape sequences.
  ///
  /// Consumers (the terminal widget or an ANSI parser) receive each chunk
  /// as it arrives and are responsible for rendering or buffering it.
  Stream<String> get output;

  /// Sends text to the shell's stdin.
  ///
  /// Unlike [ProcessSession.writeStdin], this typically includes individual
  /// keystrokes rather than full lines — the shell's line editor handles
  /// echoing and editing.
  Future<void> writeStdin(String data);

  /// Sends a terminal signal (Ctrl+C, Ctrl+D, Ctrl+Z) to the shell process.
  Future<void> sendSignal(TerminalSignal signal);

  /// Notifies the shell of a terminal resize.
  ///
  /// Implementations backed by a real PTY forward this to the kernel so
  /// that programs like `vim` and `htop` redraw at the new dimensions.
  Future<void> resize(int rows, int cols);

  /// Waits for the shell process to exit and returns its exit code.
  Future<int> waitForExit();

  /// Terminates the shell process and releases resources.
  Future<void> close();

  /// Whether the shell process is still running.
  bool get isAlive;
}
