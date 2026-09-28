/// Repository for MCP server configurations.
///
/// Persists MCP server connection settings (endpoint, transport, headers) in
/// the database. Sensitive headers (Authorization, Cookie) are stored in
/// SecretStore and merged at connection time.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../storage/database.dart';
import '../storage/secret_store.dart';

/// An MCP server configuration.
class McpServerConfig {
  const McpServerConfig({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.transport,
    this.endpoint = '',
    this.command = '',
    this.arguments = const <String>[],
    this.environment = const <String, String>{},
    this.headers = const <String, String>{},
    this.runtimeConfigId,
    this.enabled = true,
    this.autoConnect = true,
    this.connectionTimeoutMs = 10000,
    this.toolTimeoutMs = 60000,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String workspaceId;
  final String name;

  /// `http` or `stdio`.
  final String transport;
  final String endpoint;
  final String command;
  final List<String> arguments;
  final Map<String, String> environment;

  /// Headers including sensitive values like Authorization and API keys.
  /// All headers are stored in SecretStore (not the database) for security.
  /// This map is populated from SecretStore when reading configs.
  final Map<String, String> headers;

  /// Optional runtime config ID for stdio transport.
  final String? runtimeConfigId;

  final bool enabled;
  final bool autoConnect;
  final int connectionTimeoutMs;
  final int toolTimeoutMs;
  final DateTime createdAt;
  final DateTime updatedAt;

  McpServerConfig copyWith({
    String? name,
    String? transport,
    String? endpoint,
    String? command,
    List<String>? arguments,
    Map<String, String>? environment,
    Map<String, String>? headers,
    bool? enabled,
    bool? autoConnect,
    int? connectionTimeoutMs,
    int? toolTimeoutMs,
    DateTime? updatedAt,
  }) =>
      McpServerConfig(
        id: id,
        workspaceId: workspaceId,
        name: name ?? this.name,
        transport: transport ?? this.transport,
        endpoint: endpoint ?? this.endpoint,
        command: command ?? this.command,
        arguments: arguments ?? this.arguments,
        environment: environment ?? this.environment,
        headers: headers ?? this.headers,
        runtimeConfigId: runtimeConfigId,
        enabled: enabled ?? this.enabled,
        autoConnect: autoConnect ?? this.autoConnect,
        connectionTimeoutMs: connectionTimeoutMs ?? this.connectionTimeoutMs,
        toolTimeoutMs: toolTimeoutMs ?? this.toolTimeoutMs,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// CRUD for MCP server configurations with secret header management.
class McpServerRepository {
  McpServerRepository(this._db, this._secrets);

  final AppDatabase _db;
  final SecretStore _secrets;

  String _secretKey(String id) => 'mcp-server/$id/headers';

  Future<List<McpServerConfig>> forWorkspace(String workspaceId) async {
    final rows = await (_db.select(_db.mcpServers)
          ..where((table) => table.workspaceId.equals(workspaceId))
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .get();
    final configs = <McpServerConfig>[];
    for (final row in rows) {
      final secretHeaders = await _readSecretHeaders(row.id);
      configs.add(_toDomain(row, secretHeaders));
    }
    return configs;
  }

  Future<McpServerConfig?> byId(String id) async {
    final row = await (_db.select(_db.mcpServers)
          ..where((table) => table.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    final secretHeaders = await _readSecretHeaders(row.id);
    return _toDomain(row, secretHeaders);
  }

  Future<void> upsert(McpServerConfig config) async {
    await _secrets.write(_secretKey(config.id), jsonEncode(config.headers));
    await _db.into(_db.mcpServers).insert(
          _toRow(config),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> delete(String id) async {
    await _secrets.delete(_secretKey(id));
    await (_db.delete(_db.mcpServers)..where((t) => t.id.equals(id))).go();
  }

  Future<Map<String, String>> _readSecretHeaders(String id) async {
    final raw = await _secrets.read(_secretKey(id));
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, String>();
    } catch (_) {}
    return <String, String>{};
  }

  McpServersCompanion _toRow(McpServerConfig c) => McpServersCompanion.insert(
        id: c.id,
        workspaceId: c.workspaceId,
        name: c.name,
        transport: c.transport,
        endpoint: Value(c.endpoint),
        command: Value(c.command),
        argumentsJson: Value(jsonEncode(c.arguments)),
        environmentJson: Value(jsonEncode(c.environment)),
        headersJson: Value(jsonEncode(<String, String>{})),
        runtimeConfigId: Value(c.runtimeConfigId),
        enabled: Value(c.enabled),
        autoConnect: Value(c.autoConnect),
        connectionTimeoutMs: Value(c.connectionTimeoutMs),
        toolTimeoutMs: Value(c.toolTimeoutMs),
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      );

  McpServerConfig _toDomain(
    McpServerRow row,
    Map<String, String> secretHeaders,
  ) =>
      McpServerConfig(
        id: row.id,
        workspaceId: row.workspaceId,
        name: row.name,
        transport: row.transport,
        endpoint: row.endpoint,
        command: row.command,
        arguments: _decodeList(row.argumentsJson),
        environment: _decodeStringMap(row.environmentJson),
        headers: secretHeaders,
        runtimeConfigId: row.runtimeConfigId,
        enabled: row.enabled,
        autoConnect: row.autoConnect,
        connectionTimeoutMs: row.connectionTimeoutMs,
        toolTimeoutMs: row.toolTimeoutMs,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}

List<String> _decodeList(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is List) return decoded.cast<String>();
  } catch (_) {}
  return <String>[];
}

Map<String, String> _decodeStringMap(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map) return decoded.cast<String, String>();
  } catch (_) {}
  return <String, String>{};
}
