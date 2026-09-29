/// Manages LSP client instances — one per language per workspace.
///
/// Lazily starts language servers when files are opened, routes document
/// sync events, enforces resource limits, and exposes a unified diagnostics
/// stream for the editor.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../runtime/runtime.dart';
import 'lsp_client.dart';
import 'lsp_config.dart';

/// Per-client bookkeeping.
class _ClientEntry {
  _ClientEntry(this.client, this.languageId, this.config);

  final LspClient client;
  final String languageId;
  final LspServerConfig config;
  DateTime lastUsed = DateTime.now();
  StreamSubscription<LspNotification>? notificationSub;
}

/// Manages multiple [LspClient] instances for a workspace.
///
/// Usage:
/// ```dart
/// final manager = LspClientManager();
/// manager.setRuntime(runtime, rootDirectory: '/project');
///
/// // When a file is opened in the editor:
/// await manager.notifyDidOpen('file:///project/main.dart', 'dart', content);
///
/// // Request completions:
/// final result = await manager.completion('file:///project/main.dart', 10, 5);
///
/// // Listen for diagnostics:
/// manager.diagnostics.listen((event) { ... });
///
/// // Clean up:
/// await manager.shutdownAll();
/// ```
class LspClientManager {
  LspClientManager({
    this.maxConcurrentServers = 4,
    this.idleTimeout = const Duration(minutes: 5),
  });

  /// Maximum number of concurrent language server processes.
  final int maxConcurrentServers;

  /// How long an idle server is kept alive before being shut down.
  final Duration idleTimeout;

  Runtime? _runtime;
  String? _rootDirectory;
  String? _rootUri;

  /// Map of languageId -> client entry.
  final Map<String, _ClientEntry> _clients = {};

  /// Custom config overrides per languageId.
  final Map<String, LspServerConfig> _configOverrides = {};

  /// Timer for idle server cleanup.
  Timer? _idleTimer;

  final StreamController<LspDiagnosticsEvent> _diagnosticsController =
      StreamController<LspDiagnosticsEvent>.broadcast();

  /// Broadcast stream of diagnostics from all connected servers.
  Stream<LspDiagnosticsEvent> get diagnostics =>
      _diagnosticsController.stream;

  /// The set of currently active language IDs.
  Set<String> get activeLanguages => _clients.keys.toSet();

  /// Whether a client is active for the given language.
  bool hasClient(String languageId) => _clients.containsKey(languageId);

  /// Returns the client for a language, or null if not started.
  LspClient? clientFor(String languageId) => _clients[languageId]?.client;

  // -------------------------------------------------------------------------
  // Configuration
  // -------------------------------------------------------------------------

  /// Sets the runtime and root directory for launching servers.
  void setRuntime(Runtime runtime, {required String rootDirectory}) {
    _runtime = runtime;
    _rootDirectory = rootDirectory;
    _rootUri = Uri.directory(rootDirectory).toString();
  }

  /// Registers a custom LSP server config for a language.
  void setConfigOverride(String languageId, LspServerConfig config) {
    _configOverrides[languageId] = config;
  }

  /// Removes a config override, reverting to defaults.
  void clearConfigOverride(String languageId) {
    _configOverrides.remove(languageId);
  }

  // -------------------------------------------------------------------------
  // Client lifecycle
  // -------------------------------------------------------------------------

  /// Gets or creates an LSP client for the given language.
  ///
  /// Starts the language server process if not already running. Returns null
  /// if the runtime is not set or the server fails to start.
  Future<LspClient?> getOrCreate(String languageId) async {
    final existing = _clients[languageId];
    if (existing != null && existing.client.isInitialized) {
      existing.lastUsed = DateTime.now();
      return existing.client;
    }

    final runtime = _runtime;
    if (runtime == null) return null;

    // Check resource limits — evict oldest idle server if at capacity.
    if (_clients.length >= maxConcurrentServers) {
      await _evictIdlest();
    }

    final config = _configOverrides[languageId] ??
        lspDefaultPresets[languageId];
    if (config == null) return null;

    final finalConfig = config.copyWith(rootUri: _rootUri);

    try {
      final processSession = await runtime.startProcess(ProcessConfig(
        command: finalConfig.command,
        arguments: finalConfig.arguments,
        workingDirectory: _rootDirectory,
        environment: finalConfig.environment,
      ));

      final client = LspClient(session: processSession);
      final entry = _ClientEntry(client, languageId, finalConfig);

      // Subscribe to notifications.
      entry.notificationSub = client.notifications.listen((notification) {
        _handleNotification(languageId, notification);
      });

      // Perform initialize handshake.
      await client.initialize(
        rootUri: _rootUri,
        workspaceRoot: _rootDirectory,
      );

      _clients[languageId] = entry;
      _startIdleTimer();

      return client;
    } catch (e) {
      debugPrint('LSP: Failed to start $languageId server: $e');
      return null;
    }
  }

  /// Shuts down and removes the client for a specific language.
  Future<void> shutdown(String languageId) async {
    final entry = _clients.remove(languageId);
    if (entry == null) return;
    await entry.notificationSub?.cancel();
    await entry.client.shutdown();
    await entry.client.close();
  }

  /// Shuts down all language server instances.
  Future<void> shutdownAll() async {
    for (final entry in _clients.values) {
      await entry.notificationSub?.cancel();
      try {
        await entry.client.shutdown();
      } catch (_) {}
      try {
        await entry.client.close();
      } catch (_) {}
    }
    _clients.clear();
    _idleTimer?.cancel();
    _idleTimer = null;
    await _diagnosticsController.close();
  }

  // -------------------------------------------------------------------------
  // Document sync (fan-out to correct client)
  // -------------------------------------------------------------------------

  /// Notifies the appropriate server that a document was opened.
  Future<void> notifyDidOpen(
    String uri,
    String languageId,
    String text,
  ) async {
    final client = await getOrCreate(languageId);
    if (client == null) return;
    await client.didOpen(uri, languageId, text);
  }

  /// Notifies the appropriate server that a document changed.
  Future<void> notifyDidChange(
    String uri,
    String languageId,
    String text, {
    int version = 2,
  }) async {
    final client = clientFor(languageId);
    if (client == null) return;
    _clients[languageId]?.lastUsed = DateTime.now();
    await client.didChange(uri, text, version: version);
  }

  /// Notifies the appropriate server that a document was saved.
  Future<void> notifyDidSave(String uri, String languageId) async {
    final client = clientFor(languageId);
    if (client == null) return;
    _clients[languageId]?.lastUsed = DateTime.now();
    await client.didSave(uri);
  }

  /// Notifies the appropriate server that a document was closed.
  Future<void> notifyDidClose(String uri, String languageId) async {
    final client = clientFor(languageId);
    if (client == null) return;
    await client.didClose(uri);
  }

  // -------------------------------------------------------------------------
  // Code intelligence (delegated to correct client)
  // -------------------------------------------------------------------------

  /// Requests completions at the given position.
  Future<LspCompletionResult?> completion(
    String uri,
    String languageId,
    int line,
    int character,
  ) async {
    final client = clientFor(languageId);
    if (client == null) return null;
    _clients[languageId]?.lastUsed = DateTime.now();
    try {
      return await client.completion(uri, line, character);
    } catch (e) {
      debugPrint('LSP: completion error for $languageId: $e');
      return null;
    }
  }

  /// Requests go-to-definition at the given position.
  Future<List<LspLocation>> definition(
    String uri,
    String languageId,
    int line,
    int character,
  ) async {
    final client = clientFor(languageId);
    if (client == null) return const <LspLocation>[];
    _clients[languageId]?.lastUsed = DateTime.now();
    try {
      return await client.definition(uri, line, character);
    } catch (e) {
      debugPrint('LSP: definition error for $languageId: $e');
      return const <LspLocation>[];
    }
  }

  /// Requests hover information at the given position.
  Future<LspHoverResult?> hover(
    String uri,
    String languageId,
    int line,
    int character,
  ) async {
    final client = clientFor(languageId);
    if (client == null) return null;
    _clients[languageId]?.lastUsed = DateTime.now();
    try {
      return await client.hover(uri, line, character);
    } catch (e) {
      debugPrint('LSP: hover error for $languageId: $e');
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Internal
  // -------------------------------------------------------------------------

  void _handleNotification(String languageId, LspNotification notification) {
    if (notification.method == 'textDocument/publishDiagnostics') {
      final params = notification.params;
      final uri = params['uri'] as String? ?? '';
      final rawDiagnostics = params['diagnostics'] as List<dynamic>? ?? [];
      final diagnostics = rawDiagnostics
          .map((e) => LspDiagnostic.fromJson(e as Map<String, dynamic>))
          .toList();
      _diagnosticsController.add(LspDiagnosticsEvent(uri, diagnostics));
    }
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _pruneIdle(),
    );
  }

  Future<void> _pruneIdle() async {
    final now = DateTime.now();
    final toRemove = <String>[];
    for (final entry in _clients.entries) {
      if (now.difference(entry.value.lastUsed) > idleTimeout) {
        toRemove.add(entry.key);
      }
    }
    for (final lang in toRemove) {
      await shutdown(lang);
    }
    if (_clients.isEmpty) {
      _idleTimer?.cancel();
      _idleTimer = null;
    }
  }

  Future<void> _evictIdlest() async {
    if (_clients.isEmpty) return;
    var idlest = _clients.entries.first;
    for (final entry in _clients.entries) {
      if (entry.value.lastUsed.isBefore(idlest.value.lastUsed)) {
        idlest = entry;
      }
    }
    await shutdown(idlest.key);
  }
}
