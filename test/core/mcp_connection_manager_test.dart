import 'package:agentflow/core/message.dart';
import 'package:agentflow/core/mcp/mcp_connection_manager.dart';
import 'package:agentflow/storage/mcp_server_repository.dart';
import 'package:agentflow/tools/agent_tool.dart';
import 'package:agentflow/tools/tool_registry.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMcpServerRepository implements McpServerRepository {
  _FakeMcpServerRepository(this._configs);

  final List<McpServerConfig> _configs;

  @override
  Future<List<McpServerConfig>> forWorkspace(String workspaceId) async =>
      _configs.where((c) => c.workspaceId == workspaceId).toList();

  @override
  Future<McpServerConfig?> byId(String id) async =>
      _configs.cast<McpServerConfig?>().firstWhere(
        (c) => c!.id == id,
        orElse: () => null,
      );

  @override
  Future<void> upsert(McpServerConfig config) async {}

  @override
  Future<void> delete(String id) async {}
}

class _DummyTool extends ReadOnlyTool {
  _DummyTool(this.name);

  @override
  final String name;

  @override
  String get description => 'dummy tool for testing';

  @override
  Map<String, dynamic> get inputSchema => const <String, dynamic>{
        'type': 'object',
      };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    return ToolResult(toolCallId: '', name: name, content: 'ok');
  }
}

void main() {
  final now = DateTime.utc(2026);

  McpServerConfig serverConfig({
    String id = 'srv1',
    String workspaceId = 'ws',
    String name = 'Test Server',
    String transport = 'http',
    String endpoint = 'https://example.com/mcp',
    bool enabled = true,
    bool autoConnect = false,
  }) =>
      McpServerConfig(
        id: id,
        workspaceId: workspaceId,
        name: name,
        transport: transport,
        endpoint: endpoint,
        enabled: enabled,
        autoConnect: autoConnect,
        connectionTimeoutMs: 5000,
        toolTimeoutMs: 30000,
        createdAt: now,
        updatedAt: now,
      );

  group('McpConnectionManager', () {
    test('loadWorkspace registers configs without auto-connecting', () async {
      final repo = _FakeMcpServerRepository([
        serverConfig(id: 'srv1', autoConnect: false),
        serverConfig(id: 'srv2', autoConnect: false),
      ]);
      final registry = ToolRegistry();
      final manager = McpConnectionManager(
        repository: repo,
        registry: registry,
      );

      await manager.loadWorkspace('ws', autoConnect: false);

      expect(manager.connections, hasLength(2));
      expect(manager.connections[0].status, McpConnectionStatus.disconnected);
      expect(manager.connections[1].status, McpConnectionStatus.disconnected);
    });

    test('disconnect removes tools from registry', () async {
      final repo = _FakeMcpServerRepository([
        serverConfig(id: 'srv1'),
      ]);
      final registry = ToolRegistry();
      // Manually add a tool to simulate registration.
      registry.register(_DummyTool('mcp_srv1_test'));
      expect(registry.registeredNames, contains('mcp_srv1_test'));

      final manager = McpConnectionManager(
        repository: repo,
        registry: registry,
      );

      await manager.loadWorkspace('ws', autoConnect: false);
      await manager.disconnect('srv1');

      expect(registry.registeredNames, isNot(contains('mcp_srv1_test')));
    });

    test('disconnectAll clears all connections', () async {
      final repo = _FakeMcpServerRepository([
        serverConfig(id: 'srv1'),
        serverConfig(id: 'srv2'),
      ]);
      final registry = ToolRegistry();
      final manager = McpConnectionManager(
        repository: repo,
        registry: registry,
      );

      await manager.loadWorkspace('ws', autoConnect: false);
      expect(manager.connections, hasLength(2));

      await manager.disconnectAll();
      expect(manager.connections, isEmpty);
    });

    test('onServerDeleted removes the connection state', () async {
      final repo = _FakeMcpServerRepository([
        serverConfig(id: 'srv1'),
      ]);
      final registry = ToolRegistry();
      final manager = McpConnectionManager(
        repository: repo,
        registry: registry,
      );

      await manager.loadWorkspace('ws', autoConnect: false);
      expect(manager.stateFor('srv1'), isNotNull);

      await manager.onServerDeleted('srv1');
      expect(manager.stateFor('srv1'), isNull);
    });

    test('HTTP transport rejects plain HTTP endpoints', () async {
      final repo = _FakeMcpServerRepository([
        serverConfig(
          id: 'srv1',
          endpoint: 'http://insecure.example.com/mcp',
        ),
      ]);
      final registry = ToolRegistry();
      final manager = McpConnectionManager(
        repository: repo,
        registry: registry,
      );

      await manager.loadWorkspace('ws', autoConnect: false);
      await manager.connect('srv1');

      final state = manager.stateFor('srv1');
      expect(state!.status, McpConnectionStatus.error);
      expect(state.error, contains('HTTPS'));
    });

    test('unknown transport is rejected', () async {
      final repo = _FakeMcpServerRepository([
        serverConfig(id: 'srv1', transport: 'websocket'),
      ]);
      final registry = ToolRegistry();
      final manager = McpConnectionManager(
        repository: repo,
        registry: registry,
      );

      await manager.loadWorkspace('ws', autoConnect: false);
      await manager.connect('srv1');

      final state = manager.stateFor('srv1');
      expect(state!.status, McpConnectionStatus.error);
      expect(state.error, contains('Unknown transport'));
    });

    test('connection limit is enforced', () async {
      final repo = _FakeMcpServerRepository([
        serverConfig(id: 'srv1'),
        serverConfig(id: 'srv2'),
        serverConfig(id: 'srv3'),
      ]);
      final registry = ToolRegistry();
      final manager = McpConnectionManager(
        repository: repo,
        registry: registry,
        maxConnections: 2,
      );

      await manager.loadWorkspace('ws', autoConnect: false);

      // Simulate two connected servers.
      manager.stateFor('srv1')!.status = McpConnectionStatus.connected;
      manager.stateFor('srv2')!.status = McpConnectionStatus.connected;

      // Third should fail with limit error.
      await manager.connect('srv3');
      final state3 = manager.stateFor('srv3');
      expect(state3!.status, McpConnectionStatus.error);
      expect(state3.error, contains('Maximum connection limit'));
    });

    test('stateFor returns null for unknown server', () async {
      final repo = _FakeMcpServerRepository([]);
      final registry = ToolRegistry();
      final manager = McpConnectionManager(
        repository: repo,
        registry: registry,
      );

      await manager.loadWorkspace('ws', autoConnect: false);
      expect(manager.stateFor('nonexistent'), isNull);
    });

    test('onConfigChanged reloads config from repository', () async {
      final repo = _FakeMcpServerRepository([
        serverConfig(id: 'srv1', name: 'Original'),
      ]);
      final registry = ToolRegistry();
      final manager = McpConnectionManager(
        repository: repo,
        registry: registry,
      );

      await manager.loadWorkspace('ws', autoConnect: false);
      expect(manager.stateFor('srv1')!.config.name, 'Original');

      // Update the repository.
      repo._configs[0] = serverConfig(id: 'srv1', name: 'Updated');
      await manager.onConfigChanged('srv1');

      expect(manager.stateFor('srv1')!.config.name, 'Updated');
    });
  });

  group('testConnection', () {
    test('returns failure for HTTP server with invalid endpoint', () async {
      final repo = _FakeMcpServerRepository([]);
      final registry = ToolRegistry();
      final manager = McpConnectionManager(
        repository: repo,
        registry: registry,
      );

      final config = McpServerConfig(
        id: 'test',
        workspaceId: 'ws',
        name: 'Test',
        transport: 'http',
        endpoint: 'http://localhost:1', // unreachable port
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        connectionTimeoutMs: 500,
      );

      final (success, toolCount, error) = await manager.testConnection(config);
      expect(success, false);
      expect(toolCount, 0);
      expect(error, isNotNull);
    });

    test('returns failure for stdio server without runtime resolver', () async {
      final repo = _FakeMcpServerRepository([]);
      final registry = ToolRegistry();
      final manager = McpConnectionManager(
        repository: repo,
        registry: registry,
        // No runtimeResolver provided.
      );

      final config = McpServerConfig(
        id: 'test',
        workspaceId: 'ws',
        name: 'Test',
        transport: 'stdio',
        command: 'echo',
        runtimeConfigId: 'some-runtime',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final (success, toolCount, error) = await manager.testConnection(config);
      expect(success, false);
      expect(toolCount, 0);
      expect(error, contains('runtime'));
    });

    test('returns failure for stdio server without runtimeConfigId', () async {
      final repo = _FakeMcpServerRepository([]);
      final registry = ToolRegistry();
      final manager = McpConnectionManager(
        repository: repo,
        registry: registry,
      );

      final config = McpServerConfig(
        id: 'test',
        workspaceId: 'ws',
        name: 'Test',
        transport: 'stdio',
        command: 'echo',
        // No runtimeConfigId
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final (success, toolCount, error) = await manager.testConnection(config);
      expect(success, false);
      expect(error, contains('runtime config'));
    });
  });
}
