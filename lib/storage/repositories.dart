/// Repository layer over the Drift database.
///
/// The rest of the app talks to these repositories, never to Drift rows, so the
/// persistence engine could be swapped (or faked in tests) without ripple. Each
/// repository maps between generated `*Row` classes and the domain models in
/// `lib/data/models.dart`.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/memory/memory_manager.dart';
import '../core/message.dart';
import '../core/model/model_provider.dart';
import '../data/models.dart';
import 'database.dart';

/// CRUD for workspaces.
class WorkspaceRepository {
  WorkspaceRepository(this._db);
  final AppDatabase _db;

  Future<List<Workspace>> all() async {
    final rows = await (_db.select(_db.workspaces)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<Workspace?> byId(String id) async {
    final row = await (_db.select(_db.workspaces)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> upsert(Workspace w) => _db.into(_db.workspaces).insert(
        WorkspacesCompanion.insert(
          id: w.id,
          name: w.name,
          rootDirectory: w.rootDirectory,
          createdAt: w.createdAt,
          runtimeId: Value(w.runtimeId),
          settingsJson: Value(jsonEncode(w.settings)),
        ),
        mode: InsertMode.insertOrReplace,
      );

  Future<void> delete(String id) =>
      (_db.delete(_db.workspaces)..where((t) => t.id.equals(id))).go();

  Workspace _toDomain(WorkspaceRow row) => Workspace(
        id: row.id,
        name: row.name,
        rootDirectory: row.rootDirectory,
        createdAt: row.createdAt,
        runtimeId: row.runtimeId,
        settings: _decodeMap(row.settingsJson),
      );
}

/// CRUD for sessions and their transcripts.
class SessionRepository {
  SessionRepository(this._db);
  final AppDatabase _db;

  Future<List<Session>> forWorkspace(String workspaceId) async {
    final rows = await (_db.select(_db.sessions)
          ..where((t) => t.workspaceId.equals(workspaceId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map(_sessionFromRow).toList();
  }

  Future<Session?> byId(String id) async {
    final row = await (_db.select(_db.sessions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _sessionFromRow(row);
  }

  Future<void> upsert(Session s) => _db.into(_db.sessions).insert(
        SessionsCompanion.insert(
          id: s.id,
          workspaceId: s.workspaceId,
          createdAt: s.createdAt,
          updatedAt: s.updatedAt,
          title: Value(s.title),
          status: Value(s.status),
        ),
        mode: InsertMode.insertOrReplace,
      );

  Future<void> touch(String id, {String? title, String? status}) async {
    await (_db.update(_db.sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(
        updatedAt: Value(DateTime.now()),
        title: title == null ? const Value.absent() : Value(title),
        status: status == null ? const Value.absent() : Value(status),
      ),
    );
  }

  Future<void> delete(String id) =>
      (_db.delete(_db.sessions)..where((t) => t.id.equals(id))).go();

  Future<List<TranscriptMessage>> loadMessages(String sessionId) async {
    final rows = await (_db.select(_db.messages)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
    return rows.map(_messageFromRow).toList();
  }

  /// Appends a message, assigning the next sequence number.
  Future<void> appendMessage(String sessionId, TranscriptMessage m) async {
    final countRow = await (_db.selectOnly(_db.messages)
          ..addColumns(<Expression<int>>[_db.messages.id.count()])
          ..where(_db.messages.sessionId.equals(sessionId)))
        .getSingle();
    final count = countRow.read(_db.messages.id.count()) ?? 0;
    await _db.into(_db.messages).insert(MessagesCompanion.insert(
      sessionId: sessionId,
      seq: count,
      role: m.role.name,
      createdAt: m.createdAt,
      content: Value(m.content),
      toolCallsJson: Value(
        m.toolCalls.isEmpty ? null : jsonEncode(m.toolCallsToJson()),
      ),
      toolCallId: Value(m.toolCallId),
      name: Value(m.name),
      isError: Value(m.isError),
      dataJson: Value(m.data == null ? null : jsonEncode(m.data)),
    ));
    await touch(sessionId);
  }

  Future<void> clearMessages(String sessionId) =>
      (_db.delete(_db.messages)..where((t) => t.sessionId.equals(sessionId)))
          .go();

  Session _sessionFromRow(SessionRow row) => Session(
        id: row.id,
        workspaceId: row.workspaceId,
        title: row.title,
        status: row.status,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  TranscriptMessage _messageFromRow(MessageRow row) => TranscriptMessage(
        role: MessageRole.values.firstWhere(
          (MessageRole r) => r.name == row.role,
          orElse: () => MessageRole.user,
        ),
        content: row.content,
        toolCalls: row.toolCallsJson == null
            ? const <ToolCall>[]
            : TranscriptMessage.toolCallsFromJson(
                jsonDecode(row.toolCallsJson!) as List<dynamic>),
        toolCallId: row.toolCallId,
        name: row.name,
        isError: row.isError,
        data: row.dataJson == null
            ? null
            : _decodeMap(row.dataJson!),
        createdAt: row.createdAt,
      );
}

/// Persists model provider configurations (Settings).
class ProviderRepository {
  ProviderRepository(this._db);
  final AppDatabase _db;

  Future<List<ModelConfig>> all() async {
    final rows = await _db.select(_db.providerConfigs).get();
    final list = rows.map(_toDomain).toList();
    list.sort((ModelConfig a, ModelConfig b) => a.label.compareTo(b.label));
    return list;
  }

  Future<ModelConfig?> defaultConfig() async {
    final all = await this.all();
    if (all.isEmpty) return null;
    return all.firstWhere(
      (ModelConfig c) => c.isDefault,
      orElse: () => all.first,
    );
  }

  Future<void> upsert(ModelConfig config) =>
      _db.into(_db.providerConfigs).insert(
            _toRow(config),
            mode: InsertMode.insertOrReplace,
          );

  Future<void> delete(String id) =>
      (_db.delete(_db.providerConfigs)..where((t) => t.id.equals(id))).go();

  /// Marks [id] as the default, clearing the flag on all others.
  Future<void> setDefault(String id) async {
    await _db.transaction(() async {
      await _db.update(_db.providerConfigs)
          .write(const ProviderConfigsCompanion(isDefault: Value(false)));
      await (_db.update(_db.providerConfigs)..where((t) => t.id.equals(id)))
          .write(const ProviderConfigsCompanion(isDefault: Value(true)));
    });
  }

  ProviderConfigsCompanion _toRow(ModelConfig c) => ProviderConfigsCompanion.insert(
        id: c.id,
        label: c.label,
        provider: c.provider,
        model: c.model,
        baseUrl: c.baseUrl,
        apiKey: Value(c.apiKey),
        temperature: Value(c.temperature),
        maxTokens: Value(c.maxTokens),
        contextWindow: Value(c.contextWindow),
        isDefault: Value(c.isDefault),
      );

  ModelConfig _toDomain(ProviderRow row) => ModelConfig(
        id: row.id,
        label: row.label,
        provider: row.provider,
        model: row.model,
        baseUrl: row.baseUrl,
        apiKey: row.apiKey,
        temperature: row.temperature,
        maxTokens: row.maxTokens,
        contextWindow: row.contextWindow,
        isDefault: row.isDefault,
      );
}

/// Drift-backed [MemoryStore] for long-term workspace memory.
class DriftMemoryStore implements MemoryStore {
  DriftMemoryStore(this._db);
  final AppDatabase _db;

  @override
  Future<List<MemoryEntry>> load(String workspaceId) async {
    final rows = await (_db.select(_db.memoryNotes)
          ..where((t) => t.workspaceId.equals(workspaceId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows
        .map((MemoryRow r) => MemoryEntry(
              id: r.id,
              content: r.content,
              createdAt: r.createdAt,
              tags: (jsonDecode(r.tagsJson) as List<dynamic>).cast<String>(),
            ))
        .toList();
  }

  @override
  Future<void> save(String workspaceId, MemoryEntry entry) =>
      _db.into(_db.memoryNotes).insert(
            MemoryNotesCompanion.insert(
              id: entry.id,
              workspaceId: workspaceId,
              content: entry.content,
              createdAt: entry.createdAt,
              tagsJson: Value(jsonEncode(entry.tags)),
            ),
            mode: InsertMode.insertOrReplace,
          );

  @override
  Future<void> delete(String workspaceId, String id) =>
      (_db.delete(_db.memoryNotes)..where((t) => t.id.equals(id))).go();
}

Map<String, dynamic> _decodeMap(String? source) {
  if (source == null || source.isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (_) {
    // Corrupt settings should not crash the app.
  }
  return <String, dynamic>{};
}
