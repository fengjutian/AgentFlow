import 'package:agentflow/app/providers.dart';
import 'package:agentflow/core/message.dart';
import 'package:agentflow/data/models.dart';
import 'package:agentflow/runtime/runtime.dart';
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
  ) async =>
      const ToolResult(
        toolCallId: 'test',
        name: 'mcp_example_lookup',
        content: 'ok',
      );
}

void main() {
  const workspace = Workspace(
    id: 'workspace',
    name: 'Workspace',
    rootDirectory: '.',
    createdAt: _createdAt,
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
}

const DateTime _createdAt = DateTime.utc(2026);
