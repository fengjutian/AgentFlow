/// Registry of available [AgentTool]s.
///
/// The engine asks the registry for the tool specs to advertise to the model and
/// for the concrete tool to run. Tools can be enabled/disabled per workspace
/// (e.g. turn off `run_shell`), which is why lookups go through [enabledTools].
library;

import 'agent_tool.dart';
import '../core/model/model_provider.dart';

class ToolRegistry {
  ToolRegistry({List<AgentTool> tools = const <AgentTool>[]}) {
    registerAll(tools);
  }

  final Map<String, AgentTool> _tools = <String, AgentTool>{};
  final Set<String> _disabled = <String>{};

  /// Creates an independent registry with the same tools and enablement state.
  ///
  /// Workspace-specific registries must copy the composed base registry rather
  /// than rebuilding only the built-in tools, otherwise dynamically discovered
  /// tools (for example MCP tools) disappear before an agent run starts.
  ToolRegistry copy() {
    final registry = ToolRegistry(tools: _tools.values.toList(growable: false));
    registry._disabled.addAll(_disabled);
    return registry;
  }

  void register(AgentTool tool) {
    _tools[tool.name] = tool;
  }

  void registerAll(Iterable<AgentTool> tools) {
    for (final tool in tools) {
      register(tool);
    }
  }

  /// Removes a tool from the registry (e.g. when an MCP server disconnects).
  void unregister(String name) {
    _tools.remove(name);
    _disabled.remove(name);
  }

  void setEnabled(String name, bool enabled) {
    if (enabled) {
      _disabled.remove(name);
    } else {
      _disabled.add(name);
    }
  }

  bool isEnabled(String name) =>
      _tools.containsKey(name) && !_disabled.contains(name);

  AgentTool? lookup(String name) {
    final tool = _tools[name];
    if (tool == null || _disabled.contains(name)) return null;
    return tool;
  }

  List<AgentTool> get enabledTools => _tools.values
      .where((AgentTool t) => !_disabled.contains(t.name))
      .toList(growable: false);

  /// Specs advertised to the model, ordered by name for stable prompts.
  List<ToolSpec> get specs {
    final list = enabledTools.map((AgentTool t) => t.spec).toList();
    list.sort((ToolSpec a, ToolSpec b) => a.name.compareTo(b.name));
    return list;
  }

  List<String> get names {
    final list = enabledTools.map((AgentTool t) => t.name).toList();
    list.sort();
    return list;
  }

  /// Names of every registered tool, including disabled tools.
  List<String> get registeredNames {
    final list = _tools.keys.toList();
    list.sort();
    return list;
  }
}
