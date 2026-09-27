/// MCP tool adapter — wraps MCP tools as AgentTools for the ToolRegistry.
///
/// Each MCP tool is registered with the naming convention
/// `mcp_<serverId>_<toolName>` to avoid collisions with built-in tools.
/// Tool risk defaults to `confirm` since MCP tools are external.
library;

import '../../core/mcp/mcp_client.dart';
import '../../core/message.dart';
import '../agent_tool.dart';
import '../tool_args.dart';

/// Creates AgentTool wrappers for a list of MCP tools from a specific server.
List<AgentTool> mcpTools(
  String serverId,
  String serverName,
  List<McpTool> tools,
  McpHttpClient client,
) {
  return tools
      .map((tool) => McpToolAdapter(
            serverId: serverId,
            serverName: serverName,
            mcpTool: tool,
            client: client,
          ))
      .toList(growable: false);
}

/// An MCP tool exposed as an AgentTool.
class McpToolAdapter extends AgentTool {
  McpToolAdapter({
    required this.serverId,
    required this.serverName,
    required this.mcpTool,
    required this.client,
  });

  final String serverId;
  final String serverName;
  final McpTool mcpTool;
  final McpHttpClient client;

  @override
  String get name => 'mcp_${_sanitize(serverId)}_${_sanitize(mcpTool.name)}';

  @override
  String get description =>
      '[MCP:$serverName] ${mcpTool.description.isEmpty ? mcpTool.name : mcpTool.description}';

  @override
  Map<String, dynamic> get inputSchema => mcpTool.inputSchema.isEmpty
      ? <String, dynamic>{'type': 'object'}
      : mcpTool.inputSchema;

  @override
  ToolRisk get risk => ToolRisk.confirm;

  @override
  String describeCall(Map<String, dynamic> arguments) =>
      'mcp:$serverName/${mcpTool.name}';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolContext context,
  ) async {
    try {
      final result = await client.callTool(mcpTool.name, arguments);
      final text = result.text;
      return ToolResult(
        toolCallId: '',
        name: name,
        content: clampOutput(text.isEmpty ? '(no content)' : text),
        data: <String, dynamic>{
          'server': serverName,
          'tool': mcpTool.name,
          'isError': result.isError,
          'contentTypes': result.content.map((c) => c.type).toList(),
        },
        isError: result.isError,
      );
    } catch (e) {
      throw ToolExecutionException('MCP tool call failed: $e');
    }
  }
}

/// Sanitizes a name for use in tool identifiers (alphanumeric + underscore).
String _sanitize(String input) =>
    input.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
