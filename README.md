# AgentFlow

> Android AI Agent Workspace

AgentFlow is an on-device AI agent workstation for Android. It is not a chatbot — it is a task-oriented agent that reads and edits code, runs commands, operates Git, reads PDF/EPUB documents, and calls MCP tools, all while asking for approval before any risky action.

## Architecture

```text
                    ┌─────────────────────────────────────────┐
                    │              Flutter UI                  │
                    │   Chat │ Files │ Terminal │ Reader │ Settings │
                    └────────────────────┬────────────────────┘
                                         │
                    ┌────────────────────▼────────────────────┐
                    │          Session Controller              │
                    │   (Riverpod state, message persistence) │
                    └────────────────────┬────────────────────┘
                                         │
         ┌───────────────────────────────┼───────────────────────────────┐
         │                               │                               │
┌────────▼────────┐           ┌──────────▼──────────┐           ┌────────▼────────┐
│   Agent Engine  │           │   Context Manager   │           │ Approval Manager │
│ (observe-think- │           │ (budget, trimming,  │           │  (risk gating,   │
│  act-observe    │           │  summary injection) │           │   user prompt)   │
│  loop)          │           │                     │           │                  │
└────────┬────────┘           └─────────────────────┘           └──────────────────┘
         │
         ├──── ModelProvider (OpenAI-compatible, Mock)
         │
         ├──── ToolRegistry
         │       ├── FileTools      (read, write, list, search, rename, delete)
         │       ├── CodeTools      (grep, find)
         │       ├── GitTools       (status, diff, log, branches, add, unstage, commit)
         │       ├── ShellTool      (run_shell)
         │       ├── DocumentTools  (list, info, read, search)
         │       ├── MemoryTools    (remember, recall, forget)
         │       └── MCP Tools      (dynamic, per-server)
         │
         └──── Runtime (abstracted)
                 ├── LocalRuntime      (desktop / Windows / Linux / macOS)
                 ├── BridgeRuntime     (Android Kotlin bridge via MethodChannel)
                 └── SshRuntime        (remote SSH via dartssh2)
```

## Features

### Core Agent
- **Observe-Think-Act loop** with explicit phase tracking (idle → thinking → planning → executing → observing → completed)
- **Tool approval** — read-only tools run automatically; mutating tools require user confirmation
- **Cross-turn conversation summary** — when context window fills, older messages are structurally summarized
- **Agent memory** — `remember`, `recall`, `forget` tools for persistent workspace-scoped notes
- **Error recovery** — transient model errors trigger automatic retry with backoff

### Code and Files
- **File browser** — navigate, create, rename, delete files and folders via the Runtime abstraction
- **Code editor** — syntax highlighting for 22 languages, find/replace, go-to-line, undo/redo
- **Save conflict detection** — warns when the file was modified on disk while editing
- **Binary file and large file protection** — refuses to open files that would cause OOM

### Terminal
- **Interactive shell** — run commands in the workspace root with stdout/stderr streaming
- **Command history** — cycle through previous commands
- **Editor diagnostics** — compile/test errors are parsed and surfaced in the editor

### Git
- **Inspection** — `git status`, `git diff`, `git log`, branch listing
- **Workflow** — `git add`, `git unstage`, `git commit`
- Push is intentionally not exposed (design doc §34)

### Documents
- **PDF/EPUB import** — file picker with hash deduplication and progress reporting
- **Text extraction** — PDF page text, EPUB chapters with TOC navigation
- **Full-text search** — SQLite FTS5 index across all document sections
- **Ask Agent bridge** — send a document section to the chat with context

### MCP (Model Context Protocol)
- **HTTP transport** — Streamable HTTP with JSON-RPC
- **stdio transport** — newline-delimited JSON-RPC over ProcessSession
- **MCP over SSH** — stdio servers running on remote machines
- **Dynamic tool registration** — discovered tools become agent tools automatically
- **Connection management** — heartbeat, auto-reconnect, workspace isolation

### SSH Runtime
- **Password and private key authentication** — secrets stored in Flutter Secure Storage
- **Host key verification** — first-use trust, stored fingerprints, mismatch detection
- **SFTP file operations** — atomic writes via temp file + rename
- **Path traversal protection** — rejects `..` components

### Settings
- **Model providers** — MiniMax, DeepSeek, Qwen, Kimi, OpenAI, OpenAI-compatible, Local, Mock
- **Runtime configuration** — Local, SSH with full credential management
- **MCP server management** — add, edit, connect, disconnect, refresh tools, delete

### Internationalization
- **English** and **中文 (Chinese)** fully supported
- 200+ localized strings across all UI surfaces

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x / Dart 3.12+ |
| State management | Riverpod 3.x |
| Database | Drift (SQLite) |
| Secrets | flutter_secure_storage |
| SSH | dartssh2 |
| HTTP | package:http |
| PDF | syncfusion_flutter_pdf |
| EPUB | archive + xml |
| Routing | go_router |
| Testing | flutter_test |

## Project Structure

```text
lib/
├── app/                  # Application shell, providers, router, theme
├── core/
│   ├── agent/           # AgentEngine, AgentState, event stream
│   ├── approval/        # ApprovalManager, risk gating
│   ├── context/         # ContextManager, budget trimming, summary
│   ├── diff/            # Line diff algorithm
│   ├── document/        # Document model, parsers (PDF, EPUB)
│   ├── editor/          # EditorDocument, syntax highlighter, search
│   ├── mcp/             # JSON-RPC, MCP client, connection manager
│   ├── memory/          # MemoryManager
│   └── model/           # ModelProvider abstraction, OpenAI-compatible
├── data/                # Data models (workspace, session, config)
├── l10n/                # ARB files for i18n (English + Chinese)
├── runtime/
│   ├── ssh/             # SshRuntime, connection pool, host key store
│   ├── bridge_*.dart    # Android MethodChannel runtime
│   └── local_*.dart     # Desktop dart:io runtime
├── storage/             # Drift database, repositories
├── tools/               # AgentTool implementations
│   ├── code/            # Code search tools
│   ├── document/        # Document query tools
│   ├── filesystem/      # File operation tools
│   ├── git/             # Git CLI tools
│   ├── mcp/             # MCP tool adapter
│   ├── memory/          # Memory tools
│   └── shell/           # Shell execution tool
├── ui/
│   ├── chat/            # Chat page, message views, approval card, diff card
│   ├── editor/          # Code editor page
│   ├── files/           # File browser page
│   ├── reader/          # Document library and reader
│   ├── settings/        # Settings (providers, SSH, MCP, about)
│   ├── terminal/        # Terminal page
│   └── workspace/       # Workspace picker and management
└── main.dart            # Entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (3.x with Dart 3.12+)
- Android SDK (for Android builds)
- Git

### Setup

```bash
# Clone the repository
git clone https://github.com/your-org/AgentFlow.git
cd AgentFlow

# Install dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Run code generation (Drift)
dart run build_runner build --delete-conflicting-outputs
```

### Run

```bash
# Desktop (Windows/macOS/Linux)
flutter run -d windows   # or -d macos / -d linux

# Android device or emulator
flutter run -d android
```

### Test

```bash
# Run all tests
flutter test

# Analyze
dart analyze lib test
```

### Build

```bash
# Android APK (debug)
flutter build apk --debug

# Android APK (release)
flutter build apk --release

# Windows
flutter build windows
```

## Development

### Running Tests

```bash
# Unit tests
flutter test test/core/
flutter test test/storage/
flutter test test/tools/

# Widget tests
flutter test test/widget_test.dart
```

### Code Generation

Drift database code must be regenerated after schema changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Localization files must be regenerated after editing ARB files:

```bash
flutter gen-l10n
```

### Adding a Model Provider

1. Add a preset entry in `lib/core/model/provider_catalog.dart`
2. Users can also add custom OpenAI-compatible providers via Settings

### Adding an Agent Tool

1. Create a class extending `AgentTool` in `lib/tools/`
2. Register it in `lib/tools/default_tools.dart`
3. The tool becomes available to the agent automatically

## Documentation

- [Product Requirements (PRD)](docs/REQUIREMENTS.md) — product goals, user scenarios, non-goals
- [MVP3/MVP4 Development Plan](docs/MVP3_MVP4_DEVELOPMENT_PLAN.md) — Sprint 0-7 implementation tasks
- [Code Editor Plan](docs/CODE_EDITOR_PLAN.md) — editor design and phases

## License

This project is proprietary. See LICENSE file for details.
