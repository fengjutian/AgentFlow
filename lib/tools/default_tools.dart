/// Assembles the default tool set into a [ToolRegistry].
///
/// A single place decides which capabilities the agent has, so tests and the app
/// share the exact same wiring. Disabling a tool (Settings → Tools) mutates the
/// returned registry via [ToolRegistry.setEnabled].
library;

import 'agent_tool.dart';
import 'tool_registry.dart';
import 'code/code_tools.dart';
import 'filesystem/file_tools.dart';
import 'git/git_tools.dart';
import 'memory/memory_tools.dart';
import 'shell/shell_tool.dart';
import '../core/memory/memory_manager.dart';

/// All tools AgentFlow ships in the MVP.
List<AgentTool> allTools({MemoryManager? memoryManager}) => <AgentTool>[
      ...fileTools(),
      ...codeTools(),
      ...gitTools(),
      ...shellTools(),
      if (memoryManager != null) ...memoryTools(memoryManager),
    ];

/// A registry pre-populated with [allTools].
ToolRegistry defaultToolRegistry({MemoryManager? memoryManager}) =>
    ToolRegistry(tools: allTools(memoryManager: memoryManager));
