/// MCP connection manager — manages MCP server connections per workspace.
///
/// Maintains a pool of [McpHttpClient] instances, handles initialization, tool
/// discovery, and reconnects on failure. When a server is connected its tools
/// are registered in the workspace's [ToolRegistry].
library;

import 'dart:async';

import 'mcp_client.dart';
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
}

/// Manages all MCP connections for a workspace.
class McpConnectionManager {
  McpConnectionManager({
    required this.repository,
    required this.registry,
  });

  final McpServerRepository repository;
  final ToolRegistry registry;

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
    state.client?.close();
    state.client = null;
    state.status = McpConnectionStatus.disconnected;
    state.tools = <McpTool>[];
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
    final wasConnected = _connections[serverId]?.status == McpConnectionStatus.connected;
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
    if (state.config.transport != 'http') {
      state.status = McpConnectionStatus.error;
      state.error = 'Only HTTP transport is supported.';
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

      // Discover tools.
      final tools = await client.listTools();
      state.tools = tools;
      _registerTools(state);
    } catch (e) {
      state.status = McpConnectionStatus.error;
      state.error = e.toString();
    }
  }

  void _registerTools(McpConnectionState state) {
    _unregisterTools(state.config.id);
    final adapters = mcpTools(
      state.config.id,
      state.config.name,
      state.tools,
      state.client!,
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
