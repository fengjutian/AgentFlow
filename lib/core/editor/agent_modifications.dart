/// Tracks line ranges modified by the agent for gutter markers (DIFF-01/02).
///
/// When the agent writes a file via `write_file` or `apply_patch`, the modified
/// line ranges are recorded here. The editor gutter reads this store to show
/// colored markers indicating agent-modified lines. Markers fade after a
/// configurable timeout or when the user edits those lines (DIFF-04).
library;

import 'package:flutter/foundation.dart';

/// A range of lines modified by the agent.
@immutable
class AgentModifiedRange {
  const AgentModifiedRange({
    required this.path,
    required this.startLine,
    required this.endLine,
    required this.timestamp,
  });

  /// File path (normalized to forward slashes).
  final String path;

  /// 1-based start line (inclusive).
  final int startLine;

  /// 1-based end line (inclusive).
  final int endLine;

  /// When this modification was recorded.
  final DateTime timestamp;

  /// Whether this range is older than [duration].
  bool isOlderThan(Duration duration) =>
      DateTime.now().difference(timestamp) > duration;
}

/// Stores agent modification markers per file.
///
/// Markers automatically expire after [expiryDuration] (default 30 minutes).
class AgentModificationStore extends ChangeNotifier {
  AgentModificationStore({this.expiryDuration = const Duration(minutes: 30)});

  /// How long markers persist before fading.
  final Duration expiryDuration;

  final List<AgentModifiedRange> _ranges = <AgentModifiedRange>[];

  /// All active (non-expired) modification ranges.
  List<AgentModifiedRange> get ranges {
    _pruneExpired();
    return List.unmodifiable(_ranges);
  }

  /// Returns ranges for a specific file path.
  List<AgentModifiedRange> rangesFor(String path) {
    final normalized = path.replaceAll('\\', '/');
    _pruneExpired();
    return _ranges
        .where((r) => r.path == normalized || r.path == path)
        .toList(growable: false);
  }

  /// Records a modification range.
  void record({
    required String path,
    required int startLine,
    required int endLine,
  }) {
    final normalized = path.replaceAll('\\', '/');
    _ranges.add(
      AgentModifiedRange(
        path: normalized,
        startLine: startLine,
        endLine: endLine,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Records multiple ranges from a list of line numbers.
  void recordLines({required String path, required List<int> lines}) {
    if (lines.isEmpty) return;
    final sorted = List<int>.from(lines)..sort();
    // Group consecutive lines into ranges.
    var start = sorted.first;
    var end = sorted.first;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] == end + 1) {
        end = sorted[i];
      } else {
        record(path: path, startLine: start, endLine: end);
        start = sorted[i];
        end = sorted[i];
      }
    }
    record(path: path, startLine: start, endLine: end);
  }

  /// Clears all ranges for a specific path.
  void clearFor(String path) {
    final normalized = path.replaceAll('\\', '/');
    final before = _ranges.length;
    _ranges.removeWhere(
      (r) => r.path == normalized || r.path == path,
    );
    if (_ranges.length != before) notifyListeners();
  }

  /// Clears all ranges.
  void clearAll() {
    if (_ranges.isEmpty) return;
    _ranges.clear();
    notifyListeners();
  }

  /// Removes expired ranges.
  void _pruneExpired() {
    final before = _ranges.length;
    _ranges.removeWhere((r) => r.isOlderThan(expiryDuration));
    if (_ranges.length != before) notifyListeners();
  }
}
