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

  void register(AgentTool tool) {
    _tools[tool.name] = tool;
  }

  void registerAll(Iterable<AgentTool> tools) {
    for (final tool in tools) {
      register(tool);
    }
  }

  void setEnabled(String name, bool enabled) {
    if (enabled) {
      _disabled.remove(name);
    } else {
      _disabled.add(name);
    }
  }

  bool isEnabled(String name) => _tools.containsKey(name) && !_disabled.contains(name);

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
}
