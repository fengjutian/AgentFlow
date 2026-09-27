import 'package:agentflow/app/providers.dart';
import 'package:agentflow/core/message.dart';
import 'package:agentflow/data/models.dart';
import 'package:agentflow/tools/agent_tool.dart';
import 'package:agentflow/tools/tool_registry.dart';
import 'package:flutter_test/flutter_test.dart';

class _DynamicTool extends ReadOnlyTool {
  @override
  String get name => 'mcp_example_lookup';

  @override
  String get description => 'A dynamically discovered test tool.';

  @override
  Map<String, dynamic> get inputSchema => const <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{},
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async => const ToolResult(
    toolCallId: 'test',
    name: 'mcp_example_lookup',
    content: 'ok',
  );
}

class _DynamicToolWithName extends ReadOnlyTool {
  _DynamicToolWithName(this.name);

  @override
  final String name;

  @override
  String get description => 'A test tool with a specific name.';

  @override
  Map<String, dynamic> get inputSchema => const <String, dynamic>{
    'type': 'object',
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async => ToolResult(toolCallId: 'test', name: name, content: 'ok');
}

class _BuiltinTool extends AgentTool {
  _BuiltinTool(this.name);

  @override
  final String name;

  @override
  String get description => 'A built-in tool.';

  @override
  Map<String, dynamic> get inputSchema => const <String, dynamic>{
    'type': 'object',
  };

  @override
  ToolRisk get risk => ToolRisk.auto;

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async => ToolResult(toolCallId: 'test', name: name, content: 'ok');
}

void main() {
  final workspace = Workspace(
    id: 'workspace',
    name: 'Workspace',
    rootDirectory: '.',
    createdAt: DateTime.utc(2026),
    settings: <String, dynamic>{
      'disabledTools': <String>['read_file'],
    },
  );

  test('copy preserves dynamic tools and disabled state independently', () {
    final base = ToolRegistry(tools: <AgentTool>[_DynamicTool()]);
    base.setEnabled('mcp_example_lookup', false);

    final copied = base.copy();
    expect(copied.registeredNames, contains('mcp_example_lookup'));
    expect(copied.isEnabled('mcp_example_lookup'), isFalse);

    copied.setEnabled('mcp_example_lookup', true);
    expect(copied.isEnabled('mcp_example_lookup'), isTrue);
    expect(base.isEnabled('mcp_example_lookup'), isFalse);
  });

  test('workspace registry retains dynamically registered tools', () {
    final base = ToolRegistry(tools: <AgentTool>[_DynamicTool()]);
    final registry = registryForWorkspace(workspace, base);

    expect(registry.lookup('mcp_example_lookup'), isNotNull);
  });

  group('registerSafe', () {
    test('registers MCP tool when no name collision', () {
      final registry = ToolRegistry();
      final tool = _DynamicTool(); // name = 'mcp_example_lookup'
      expect(registry.registerSafe(tool), isTrue);
      expect(registry.lookup('mcp_example_lookup'), isNotNull);
    });

    test('rejects MCP tool that would shadow a built-in tool', () {
      final builtin = _BuiltinTool('read_file');
      final registry = ToolRegistry(tools: [builtin]);

      // An MCP tool with the exact same name would be rejected.
      final mcpTool = _DynamicToolWithName('read_file');
      expect(registry.registerSafe(mcpTool), isFalse);

      // The original built-in tool remains.
      expect(registry.lookup('read_file'), isA<_BuiltinTool>());
    });

    test('allows MCP tool to replace another MCP tool with same name', () {
      final registry = ToolRegistry();
      final mcp1 = _DynamicToolWithName('mcp_srv1_read');
      final mcp2 = _DynamicToolWithName('mcp_srv1_read');

      expect(registry.registerSafe(mcp1), isTrue);
      expect(registry.registerSafe(mcp2), isTrue); // Replaces existing MCP tool.
    });

    test('registerSafe allows non-MCP tool registration on empty registry', () {
      final registry = ToolRegistry();
      final tool = _BuiltinTool('custom_tool');
      expect(registry.registerSafe(tool), isTrue);
      expect(registry.lookup('custom_tool'), isNotNull);
    });
  });
}
