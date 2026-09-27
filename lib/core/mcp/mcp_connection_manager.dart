/// MCP connection manager — manages MCP server connections per workspace.
///
/// Maintains a pool of [McpHttpClient] instances, handles initialization, tool
/// discovery, reconnects on failure. When a server is connected its tools are
/// registered in the workspace's [ToolRegistry].
library;

import 'dart:async';

import 'mcp_client.dart';
import 'mcp_stdio_client.dart';
import '../../runtime/runtime.dart';
import '../../storage/mcp_server_repository.dart';
import '../../tools/mcp/mcp_tool_adapter.dart';
import '../../tools/tool_registry.dart';

/// Status of a single MCP server connection.
enum McpConnectionStatus { disconnected, connecting, connected, error }

/// Live state of a single MCP server connection.
class McpConnectionState {
  McpConnectionState({
    required this.config,
    this.status = McpConnectionStatus.disconnected,
    this.tools = const <McpTool>[],
    this.error,
  });

  final McpServerConfig config;
  McpConnectionStatus status;
  List<McpTool> tools;
  String? error;
  McpHttpClient? client;
  McpStdioClient? stdioClient;
  ProcessSession? processSession;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
}

/// Resolves a [Runtime] for a given runtime config ID.
typedef RuntimeResolver = Future<Runtime> Function(String runtimeConfigId);

/// Manages all MCP connections for a workspace.
///
/// Provides heartbeat monitoring, automatic reconnection with exponential
/// backoff, and workspace isolation.
class McpConnectionManager {
  McpConnectionManager({
    required this.repository,
    required this.registry,
    this.runtimeResolver,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.maxReconnectDelay = const Duration(minutes: 5),
    this.maxConnections = 10,
  });

  final McpServerRepository repository;
  final ToolRegistry registry;

  /// Resolves a Runtime for stdio MCP servers that specify a runtimeConfigId.
  final RuntimeResolver? runtimeResolver;

  final Duration heartbeatInterval;
  final Duration maxReconnectDelay;

  /// Maximum number of simultaneous MCP connections.
  final int maxConnections;

  final Map<String, McpConnectionState> _connections = {};

  /// All known server states.
  List<McpConnectionState> get connections => _connections.values.toList();

  /// Returns the state for a specific server.
  McpConnectionState? stateFor(String serverId) => _connections[serverId];

  /// Loads and optionally connects to all MCP servers for a workspace.
  Future<void> loadWorkspace(String workspaceId, {bool autoConnect = true}) async {
    // Disconnect any existing connections for this workspace.
    await disconnectAll();

    final configs = await repository.forWorkspace(workspaceId);
    for (final config in configs) {
      _connections[config.id] = McpConnectionState(config: config);
      if (autoConnect && config.enabled && config.autoConnect) {
        // Fire-and-forget; the state object is updated as it progresses.
        _connectServer(config.id);
      }
    }
  }

  /// Connects to a specific server.
  Future<void> connect(String serverId) async {
    await _connectServer(serverId);
  }

  /// Disconnects from a specific server.
  Future<void> disconnect(String serverId) async {
    final state = _connections[serverId];
    if (state == null) return;
    state._heartbeatTimer?.cancel();
    state._heartbeatTimer = null;
    state.client?.close();
    state.client = null;
    await state.stdioClient?.close();
    state.stdioClient = null;
    state.processSession = null;
    state.status = McpConnectionStatus.disconnected;
    state.tools = <McpTool>[];
    state._reconnectAttempts = 0;
    _unregisterTools(serverId);
  }

  /// Disconnects from all servers.
  Future<void> disconnectAll() async {
    for (final id in _connections.keys.toList()) {
      await disconnect(id);
    }
    _connections.clear();
  }

  /// Reconnects to a specific server.
  Future<void> reconnect(String serverId) async {
    await disconnect(serverId);
    await _connectServer(serverId);
  }

  /// Discovers tools from a connected server.
  Future<List<McpTool>> refreshTools(String serverId) async {
    final state = _connections[serverId];
    if (state == null || state.client == null) {
      throw StateError('Server $serverId is not connected.');
    }
    final tools = await state.client!.listTools();
    state.tools = tools;
    _registerTools(state);
    return tools;
  }

  /// Called when a server config changes — reconnects if needed.
  Future<void> onConfigChanged(String serverId) async {
    final wasConnected =
        _connections[serverId]?.status == McpConnectionStatus.connected;
    await disconnect(serverId);
    // Reload config from repository.
    final config = await repository.byId(serverId);
    if (config == null) {
      _connections.remove(serverId);
      return;
    }
    _connections[serverId] = McpConnectionState(config: config);
    if (wasConnected && config.enabled) {
      await _connectServer(serverId);
    }
  }

  /// Called when a server is deleted.
  Future<void> onServerDeleted(String serverId) async {
    await disconnect(serverId);
    _connections.remove(serverId);
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _connectServer(String serverId) async {
    final state = _connections[serverId];
    if (state == null) return;

    // Connection limit check.
    final activeCount = _connections.values
        .where((s) => s.status == McpConnectionStatus.connected)
        .length;
    if (activeCount >= maxConnections) {
      state.status = McpConnectionStatus.error;
      state.error = 'Maximum connection limit ($maxConnections) reached.';
      return;
    }

    if (state.config.transport == 'stdio') {
      await _connectStdio(state);
    } else if (state.config.transport == 'http') {
      await _connectHttp(state);
    } else {
      state.status = McpConnectionStatus.error;
      state.error = 'Unknown transport: ${state.config.transport}';
      return;
    }
  }

  Future<void> _connectHttp(McpConnectionState state) async {
    // HTTPS-only enforcement: reject plain HTTP unless explicitly allowed.
    final uri = Uri.tryParse(state.config.endpoint);
    if (uri != null && uri.scheme == 'http') {
      state.status = McpConnectionStatus.error;
      state.error = 'HTTP endpoints are not allowed. Use HTTPS for security.';
      return;
    }

    state.status = McpConnectionStatus.connecting;
    state.error = null;

    try {
      final client = McpHttpClient(
        endpoint: state.config.endpoint,
        headers: state.config.headers,
        timeout: Duration(milliseconds: state.config.connectionTimeoutMs),
      );

      await client.initialize();
      state.client = client;
      state.status = McpConnectionStatus.connected;
      state._reconnectAttempts = 0;

      // Discover tools.
      final tools = await client.listTools();
      state.tools = tools;
      _registerTools(state);

      // Start heartbeat monitoring.
      _startHeartbeat(state.config.id);
    } catch (e) {
      state.status = McpConnectionStatus.error;
      state.error = e.toString();
      _unregisterTools(state.config.id);
      // Schedule auto-reconnect with backoff.
      _scheduleReconnect(state.config.id);
    }
  }

  Future<void> _connectStdio(McpConnectionState state) async {
    state.status = McpConnectionStatus.connecting;
    state.error = null;

    try {
      // Resolve the runtime for this stdio server.
      Runtime runtime;
      if (state.config.runtimeConfigId != null && runtimeResolver != null) {
        runtime = await runtimeResolver!(state.config.runtimeConfigId!);
      } else {
        // Fallback: no specific runtime configured — cannot start stdio.
        throw StateError(
          'Stdio MCP server "${state.config.name}" requires a runtime config. '
          'Set runtimeConfigId or provide a runtimeResolver.',
        );
      }

      // Start the MCP server process.
      final processConfig = ProcessConfig(
        command: state.config.command,
        arguments: state.config.arguments,
        environment: state.config.environment,
      );
      final session = await runtime.startProcess(processConfig);
      state.processSession = session;

      // Create the stdio client.
      final stdioClient = McpStdioClient(
        session: session,
        timeout: Duration(milliseconds: state.config.toolTimeoutMs),
      );

      await stdioClient.initialize();
      state.stdioClient = stdioClient;
      state.status = McpConnectionStatus.connected;
      state._reconnectAttempts = 0;

      // Discover tools.
      final tools = await stdioClient.listTools();
      state.tools = tools;
      _registerTools(state);

      // Monitor process exit.
      session.waitForExit().then((_) {
        if (state.status == McpConnectionStatus.connected) {
          state.status = McpConnectionStatus.error;
          state.error = 'MCP server process exited.';
          state.stdioClient = null;
          state.processSession = null;
          _unregisterTools(state.config.id);
          _scheduleReconnect(state.config.id);
        }
      });
    } catch (e) {
      state.status = McpConnectionStatus.error;
      state.error = e.toString();
      _unregisterTools(state.config.id);
      _scheduleReconnect(state.config.id);
    }
  }

  void _startHeartbeat(String serverId) {
    final state = _connections[serverId];
    if (state == null) return;
    state._heartbeatTimer?.cancel();
    state._heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      _ping(serverId);
    });
  }

  Future<void> _ping(String serverId) async {
    final state = _connections[serverId];
    if (state == null || state.client == null) return;
    try {
      // Use tools/list as a heartbeat probe — lightweight and verifies the
      // connection is still alive.
      await state.client!.listTools();
      state._reconnectAttempts = 0;
    } catch (e) {
      // Connection lost — stop heartbeat and trigger reconnect.
      state._heartbeatTimer?.cancel();
      state._heartbeatTimer = null;
      state.status = McpConnectionStatus.error;
      state.error = 'Connection lost: $e';
      state.client?.close();
      state.client = null;
      _unregisterTools(serverId);
      _scheduleReconnect(serverId);
    }
  }

  void _scheduleReconnect(String serverId) {
    final state = _connections[serverId];
    if (state == null || !state.config.autoConnect) return;

    state._reconnectAttempts++;
    // Exponential backoff: 1s, 2s, 4s, 8s … capped at maxReconnectDelay.
    final delay = Duration(
      seconds: (1 << (state._reconnectAttempts - 1)).clamp(1, maxReconnectDelay.inSeconds),
    );

    Timer(delay, () {
      if (_connections[serverId] == state &&
          state.status != McpConnectionStatus.connected) {
        _connectServer(serverId);
      }
    });
  }

  void _registerTools(McpConnectionState state) {
    _unregisterTools(state.config.id);

    // Pick the right callTool function based on transport.
    final McpCallTool callTool;
    if (state.stdioClient != null) {
      final stdioClient = state.stdioClient!;
      callTool = stdioClient.callTool;
    } else if (state.client != null) {
      final httpClient = state.client!;
      callTool = httpClient.callTool;
    } else {
      return; // No client available.
    }

    final adapters = mcpTools(
      state.config.id,
      state.config.name,
      state.tools,
      callTool,
    );
    for (final adapter in adapters) {
      registry.register(adapter);
    }
  }

  void _unregisterTools(String serverId) {
    final prefix = 'mcp_${_sanitize(serverId)}_';
    for (final name in registry.registeredNames) {
      if (name.startsWith(prefix)) {
        registry.unregister(name);
      }
    }
  }
}

String _sanitize(String input) =>
    input.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
