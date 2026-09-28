
# AgentFlow Phase 2 Development Roadmap

This plan covers the next major development phase, organized into 5 priority areas and ~15 implementation sprints. It extends the MVP3/MVP4 plan (Sprints 0-7, all complete).

---

## Phase A: Foundation and Stability (Sprint 8-9)

### A-01 README Rewrite
- Replace the Flutter default template with actual project documentation
- Sections: overview, architecture diagram, feature list, screenshots, build instructions, contribution guide
- Ensure UTF-8 encoding for all Chinese content
- File: `README.md` (currently 18 lines of boilerplate)

### A-02 Build Pipeline
- Pin Flutter version in `.fvmrc` or equivalent
- GitHub Actions workflow: `flutter analyze` + `flutter test` on push/PR
- Add code coverage reporting (lcov)
- Android APK build job (debug + release)
- Lint rule hardening: enable `strict-casts`, `strict-raw-types` in `analysis_options.yaml`

### A-03 Diagnostic Export
- Add a "Copy diagnostics" action in Settings/About
- Collect: Flutter version, Dart version, platform, runtime kind, active providers (labels only, no keys), MCP server count/status, database schema version, memory count
- Format as a shareable text block for bug reports

---

## Phase B: Real-Time Interaction (Sprint 10-12)

### B-01 Model Streaming — SSE Token Output

**Architecture change**: `ModelProvider.generate()` becomes `Stream<ModelChunk>`.

New types in `lib/core/model/model_provider.dart`:
```dart
sealed class ModelChunk {}
class ContentDelta extends ModelChunk { final String text; }
class ToolCallDelta extends ModelChunk { final ToolCall call; }
class FinishChunk extends ModelChunk {
  final FinishReason reason;
  final Map<String, int>? usage;
}
```

**Tasks:**

- **STREAM-01**: Define `ModelChunk` sealed class and `Stream<ModelChunk>` signature
- **STREAM-02**: Update `OpenAiCompatibleProvider` to use `http.Client.send()` + SSE line parsing (`data: {...}` events). Map each SSE chunk to `ContentDelta` or `ToolCallDelta`
- **STREAM-03**: Update `MockModelProvider` to emit synthetic deltas (simulates typing)
- **STREAM-04**: Update `AgentEngine._loop()` — replace `await provider.generate()` with `await for` over the stream. Accumulate content into a buffer, emit `AssistantStreamEvent` for each delta
- **STREAM-05**: Add `AssistantStreamEvent` to `agent_state.dart` — carries incremental text so UI can render token-by-token
- **STREAM-06**: Update `SessionController` to append streaming text to the current assistant message as it arrives (not wait for completion)
- **STREAM-07**: Update chat UI `_AssistantBubble` to rebuild on each stream event (use `ValueListenableBuilder` or similar)
- **STREAM-08**: Update all tests to use `Stream<ModelChunk>` — `agent_engine_test.dart`, `context_manager_test.dart`, etc.
- **STREAM-09**: Add usage accumulation — sum `prompt_tokens`/`completion_tokens` across iterations and persist per-session

**Key constraint**: Non-streaming providers (future Anthropic native, etc.) must be able to wrap a single `ModelResponse` as a one-element stream. Provide a helper `Stream<ModelChunk>.fromResponse(ModelResponse)`.

### B-02 Persistent PTY Terminal

**Current state**: `TerminalPage._run()` calls `runtime.execute()` which is stateless — each command is a fresh process. No persistent shell, no Ctrl+C, no interactive programs.

**Architecture**: New `ShellSession` abstraction alongside `ProcessSession`:
```dart
abstract class ShellSession {
  Stream<String> get stdout;
  Stream<String> get stderr;
  Future<void> writeStdin(String data);
  Future<void> sendSignal(TerminalSignal signal); // ctrlC, ctrlD, ctrlZ
  Future<void> resize(int rows, int cols);
  Future<int> waitForExit();
  Future<void> close();
}
enum TerminalSignal { ctrlC, ctrlD, ctrlZ }
```

**Tasks:**

- **TERM-01**: Define `ShellSession` interface in `lib/runtime/`
- **TERM-02**: Implement `LocalShellSession` using `dart:io` `Process.start('bash', ...)` with persistent process + PTY (via `ProcessStartMode.inheritStdio` or platform-specific PTY allocation)
- **TERM-03**: Implement `BridgeShellSession` using Android MethodChannel/EventChannel — shell process managed by Kotlin side
- **TERM-04**: Implement `SshShellSession` using `dartssh2` SSH channel with PTY request (`channel.requestPty()`)
- **TERM-05**: Basic ANSI escape sequence parser for terminal colors/cursor (subset: SGR colors, cursor movement, clear screen). Render in a custom `TerminalView` widget instead of `SelectableText` lines
- **TERM-06**: Rewrite `TerminalPage` to use `ShellSession` — connect stdin/stdout streams, handle keyboard input (including special keys), display terminal buffer
- **TERM-07**: Terminal resize on orientation change / keyboard show
- **TERM-08**: Shell persistence — reconnect to existing shell session when switching tabs or after brief app background

---

## Phase C: Editor Enhancement (Sprint 13-15)

### C-01 Multi-Tab and Recent Files

- **TAB-01**: `EditorTabController` — manages open tabs list, active tab, dirty state per tab. Riverpod provider
- **TAB-02**: Tab bar UI — horizontal scrollable, close buttons, dirty indicators. Tap to switch, long-press to close others
- **TAB-03**: "Open in editor" action from file browser opens a new tab (or focuses existing)
- **TAB-04**: `RecentFilesStore` — persist last 20 opened file paths per workspace in Drift. Show in empty tab state
- **TAB-05**: Auto-save drafts for all open tabs on app pause (extend existing `WidgetsBindingObserver`)

### C-02 Diagnostic Jump-To

**Current state**: `editor_diagnostics.dart` already parses compile/test errors from terminal output. Need click-to-navigate.

- **DIAG-01**: Diagnostic list panel in editor (bottom drawer or sidebar) showing parsed errors/warnings with file:line:col
- **DIAG-02**: Tapping a diagnostic opens the file at the exact line/column (scroll + highlight)
- **DIAG-03**: Inline gutter markers (red/yellow dots) for lines with diagnostics
- **DIAG-04**: Auto-detect new diagnostics after save (re-run parser on save result)

### C-03 Agent Modification Markers

- **DIFF-01**: Track which lines were modified by `write_file` tool calls — store as a list of `(path, lineRanges, timestamp)` in a provider
- **DIFF-02**: Editor gutter shows colored markers (green = added, red = removed) for agent-modified ranges
- **DIFF-03**: "Review agent changes" action opens an inline diff view for each modified range
- **DIFF-04**: Markers fade/clear after the user edits those lines or after a configurable time

### C-04 LSP Foundation (Future — large)

This is a significant undertaking. High-level tasks:

- **LSP-01**: LSP client protocol implementation (JSON-RPC over stdio, initialize handshake, document sync)
- **LSP-02**: Language server lifecycle management — start/stop servers per language per workspace
- **LSP-03**: Completion provider — request completions from LSP, show in a popup overlay
- **LSP-04**: Go-to-definition — Ctrl+click or long-press on a symbol
- **LSP-05**: Diagnostics from LSP — real-time error/warning markers
- **LSP-06**: Settings UI for configuring language server paths per language

Note: LSP requires a running language server process, which means it depends on the PTY infrastructure from Phase B for non-local runtimes. On Android, language servers may need to run on the remote machine.

---

## Phase D: Production Validation (Sprint 16-17)

### D-01 Android End-to-End

- **E2E-01**: Build and deploy debug APK to a real Android device via adb
- **E2E-02**: Validate: workspace creation, file browsing, agent loop with mock provider, terminal commands
- **E2E-03**: Validate: Kotlin Bridge runtime — shell commands, file read/write, process sessions
- **E2E-04**: Validate: Termux fallback — commands via RUN_COMMAND intent
- **E2E-05**: Validate: PDF/EPUB import via file picker, reader navigation, Ask Agent bridge

### D-02 SSH End-to-End

- **E2E-06**: Configure a real SSH server (local VM or cloud instance)
- **E2E-07**: Walk through: add SSH config, confirm host key, test connection
- **E2E-08**: Bind workspace to SSH runtime, browse remote files, run agent tools
- **E2E-09**: Validate stdio MCP over SSH — start MCP server remotely, discover tools, call tools
- **E2E-10**: Validate reconnection after network interruption

### D-03 MCP Compatibility Testing

- **E2E-11**: Test with `@modelcontextprotocol/server-filesystem` (Node.js stdio server)
- **E2E-12**: Test with `@modelcontextprotocol/server-github` (HTTP server)
- **E2E-13**: Test concurrent tool calls from multiple sessions
- **E2E-14**: Validate tool list refresh on server-side changes
- **E2E-15**: Stress test: large tool responses, connection limits, timeout handling

### D-04 MCP Production Hardening

- **HARD-01**: Heartbeat tuning — adaptive intervals based on server responsiveness
- **HARD-02**: Backoff strategy for reconnection (exponential with jitter)
- **HARD-03**: Response size limits — truncate or paginate large tool results
- **HARD-04**: Connection pooling — share transport across workspace sessions
- **HARD-05**: Tool call timeout — per-tool configurable, default 30s

---

## Phase E: Extensions (Sprint 18+)

### E-01 OCR for Scanned PDFs

- Add `tesseract` or Android ML Kit OCR dependency
- Detect `ocrRequired` pages (no text layer) during import
- Queue OCR jobs, persist results to `document_sections`
- Show OCR progress in documents page
- Mark OCR quality confidence per section

### E-02 Vector Search and RAG

- Embedding generation — call model API or use on-device model (e.g., `sentence-transformers` via FFI or HTTP)
- Vector store — SQLite vector extension (`sqlite-vss`) or in-memory HNSW
- Index document sections on import completion
- Retrieval tool: `search_knowledge` — semantic similarity search across all documents
- Context builder: inject retrieved chunks into agent context with source attribution

### E-03 Voice Input

- Android SpeechRecognizer integration
- Voice button in chat input bar — tap to record, release to transcribe
- Transcribed text fills the input field for review before send
- Settings: language selection, confidence threshold

### E-04 Camera and Image Context

- Android camera intent integration
- Photo picker for existing images
- Image preview in chat input
- Send image as part of agent request (multimodal model support required)
- Image description tool for non-multimodal providers (call a vision API separately)

### E-05 Additional Model Providers

- Anthropic native provider (Messages API with tool_use)
- Google Gemini native provider (Generative Language API)
- Provider capability detection (streaming, vision, tool calling)
- Model list sync — fetch available models from provider API

### E-06 Docker Runtime

- `DockerRuntime` implementing `Runtime` via Docker CLI or API
- Container lifecycle: create, start, exec, stop, remove
- File operations via `docker cp` or volume mounts
- Settings: image selection, container name, port mappings

### E-07 Git Push and Remote Operations

- `git_push` tool (strong risk, always requires approval)
- `git_pull` tool with conflict detection
- `git_fetch` tool
- Branch create/switch/merge UI in files sidebar or dedicated git panel
- Conflict resolution: show conflicted files, inline diff, accept theirs/ours/edit

---

## Milestone Summary

| Sprint | Deliverables |
|--------|-------------|
| 8 | README rewrite, build pipeline, diagnostic export |
| 9 | Lint hardening, CI workflow, code coverage |
| 10 | Streaming model chunks, SSE parser, engine integration |
| 11 | Streaming UI, usage tracking, mock provider streaming |
| 12 | Shell session abstraction, local PTY, terminal rewrite |
| 13 | Bridge + SSH shell sessions, ANSI parser, terminal resize |
| 14 | Editor multi-tab, recent files, draft persistence |
| 15 | Diagnostic jump-to, agent diff markers, gutter decorations |
| 16 | Android device validation, SSH E2E, MCP compatibility |
| 17 | MCP hardening, connection resilience, stress testing |
| 18+ | OCR, RAG, voice, camera, additional providers, Docker, git push |

---

## Assumptions

- LSP (C-04) is deferred until PTY infrastructure (B-02) is stable, since language servers need persistent processes
- Voice/Camera (E-03, E-04) require multimodal model support in the provider layer first
- Docker Runtime (E-06) assumes the host has Docker CLI installed; Android deployment would use Docker over SSH
- Git push (E-07) keeps the design doc's "always confirm" policy — no automatic push
- Phase D (validation) may reveal issues that create additional hardening tasks
