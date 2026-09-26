/// Long-term memory (design doc §17).
///
/// MVP keeps this deliberately small: a workspace-scoped list of durable notes
/// the agent can read into context and append to. The interface is what matters —
/// a future vector store / RAG implementation slots in behind [MemoryManager]
/// without touching the engine.
library;

/// One durable note remembered about a workspace.
class MemoryEntry {
  const MemoryEntry({
    required this.id,
    required this.content,
    required this.createdAt,
    this.tags = const <String>[],
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final List<String> tags;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'tags': tags,
      };
}

/// Persistence port implemented by the storage layer.
abstract class MemoryStore {
  Future<List<MemoryEntry>> load(String workspaceId);
  Future<void> save(String workspaceId, MemoryEntry entry);
  Future<void> delete(String workspaceId, String id);
}

/// In-memory [MemoryStore] used before persistence is wired or in tests.
class InMemoryMemoryStore implements MemoryStore {
  final Map<String, List<MemoryEntry>> _data = <String, List<MemoryEntry>>{};

  @override
  Future<List<MemoryEntry>> load(String workspaceId) async =>
      List<MemoryEntry>.unmodifiable(_data[workspaceId] ?? <MemoryEntry>[]);

  @override
  Future<void> save(String workspaceId, MemoryEntry entry) async {
    final list = _data.putIfAbsent(workspaceId, () => <MemoryEntry>[]);
    list.removeWhere((MemoryEntry e) => e.id == entry.id);
    list.add(entry);
  }

  @override
  Future<void> delete(String workspaceId, String id) async {
    _data[workspaceId]?.removeWhere((MemoryEntry e) => e.id == id);
  }
}

class MemoryManager {
  MemoryManager({required MemoryStore store}) : _store = store;

  final MemoryStore _store;
  final Map<String, List<MemoryEntry>> _cache = <String, List<MemoryEntry>>{};

  Future<List<MemoryEntry>> entries(String workspaceId) async {
    final cached = _cache[workspaceId];
    if (cached != null) return cached;
    final loaded = await _store.load(workspaceId);
    _cache[workspaceId] = loaded;
    return loaded;
  }

  Future<void> remember(String workspaceId, MemoryEntry entry) async {
    await _store.save(workspaceId, entry);
    final list = _cache.putIfAbsent(workspaceId, () => <MemoryEntry>[]);
    list.removeWhere((MemoryEntry e) => e.id == entry.id);
    list.add(entry);
  }

  Future<void> forget(String workspaceId, String id) async {
    await _store.delete(workspaceId, id);
    _cache[workspaceId]?.removeWhere((MemoryEntry e) => e.id == id);
  }

  /// Renders remembered notes as a context block, capped to the most recent
  /// [limit] entries so memory never crowds out the task.
  Future<String> renderContextBlock(String workspaceId, {int limit = 20}) async {
    final all = await entries(workspaceId);
    if (all.isEmpty) return '';
    final recent = all.length > limit ? all.sublist(all.length - limit) : all;
    final buffer = StringBuffer('Relevant long-term memory:\n');
    for (final entry in recent) {
      buffer.writeln('- ${entry.content}');
    }
    return buffer.toString().trim();
  }
}
