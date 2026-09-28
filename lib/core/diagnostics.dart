/// Diagnostic data collection for bug reports.
///
/// Gathers non-sensitive system information that helps diagnose issues:
/// Flutter/Dart versions, platform, active runtime, provider count,
/// MCP server status, database schema version, and memory entry count.
/// Secrets (API keys, passwords) are never included.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../../core/memory/memory_manager.dart';
import '../../core/mcp/mcp_connection_manager.dart';
import '../../core/model/model_provider.dart';
import '../../storage/database.dart';

/// Collects a diagnostic text block suitable for pasting into a bug report.
Future<String> collectDiagnostics({
  required AppDatabase database,
  required List<ModelConfig> modelConfigs,
  required McpConnectionManager mcpManager,
  required MemoryManager memoryManager,
  required String? activeWorkspaceId,
  required String? activeRuntimeKind,
}) async {
  final buffer = StringBuffer();
  buffer.writeln('=== AgentFlow Diagnostics ===');
  buffer.writeln('Timestamp: ${DateTime.now().toUtc().toIso8601String()}');
  buffer.writeln();

  // Environment
  buffer.writeln('--- Environment ---');
  buffer.writeln('Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
  buffer.writeln('Dart: ${Platform.version}');
  buffer.writeln('Flutter: ${kDebugMode ? 'debug' : 'release'}');
  buffer.writeln();

  // Database
  buffer.writeln('--- Database ---');
  buffer.writeln('Schema version: ${database.schemaVersion}');
  buffer.writeln();

  // Active workspace
  buffer.writeln('--- Workspace ---');
  buffer.writeln('Active workspace: ${activeWorkspaceId ?? '(none)'}');
  buffer.writeln('Runtime: ${activeRuntimeKind ?? '(none)'}');
  buffer.writeln();

  // Model providers
  buffer.writeln('--- Model Providers ---');
  buffer.writeln('Configured: ${modelConfigs.length}');
  for (final config in modelConfigs) {
    final defaultMark = config.isDefault ? ' (default)' : '';
    buffer.writeln('  - ${config.label} [${config.provider}] model=${config.model}$defaultMark');
  }
  buffer.writeln();

  // MCP servers
  final serverStates = mcpManager.connections;
  buffer.writeln('--- MCP Servers ---');
  buffer.writeln('Total: ${serverStates.length}');
  for (final state in serverStates) {
    buffer.writeln('  - ${state.serverName}: status=${state.status}, tools=${state.tools.length}');
  }
  buffer.writeln();

  // Memory
  buffer.writeln('--- Memory ---');
  if (activeWorkspaceId != null) {
    try {
      final entries = await memoryManager.list(activeWorkspaceId);
      buffer.writeln('Entries for active workspace: ${entries.length}');
    } catch (e) {
      buffer.writeln('Entries: error reading ($e)');
    }
  } else {
    buffer.writeln('Entries: (no active workspace)');
  }
  buffer.writeln();
  buffer.writeln('=== End Diagnostics ===');

  return buffer.toString();
}
