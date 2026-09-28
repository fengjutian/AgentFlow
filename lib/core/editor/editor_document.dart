library;

import '../../runtime/runtime.dart';

enum EditorSaveResult { saved, conflict, verifiedWithChanges }

class EditorDocument {
  EditorDocument({required this.path, required Runtime runtime})
    : _runtime = runtime;

  final String path;
  final Runtime _runtime;

  String _baseline = '';
  String _text = '';
  bool _loaded = false;

  String get text => _text;
  bool get isLoaded => _loaded;
  bool get isDirty => _loaded && _text != _baseline;

  Future<String> load() async {
    final content = await _runtime.readFile(path);
    _baseline = content;
    _text = content;
    _loaded = true;
    return content;
  }

  void update(String value) {
    if (!_loaded) throw StateError('Document must be loaded before editing.');
    _text = value;
  }

  Future<EditorSaveResult> save() async {
    _ensureLoaded();
    final disk = await _runtime.readFile(path);
    if (disk != _baseline) return EditorSaveResult.conflict;
    return _writeAndVerify();
  }

  Future<void> overwrite() async {
    _ensureLoaded();
    await _writeAndVerify();
  }

  Future<String> reload() => load();

  /// Writes content and verifies it was saved correctly.
  /// Returns [EditorSaveResult.saved] if content matches after write,
  /// or [EditorSaveResult.verifiedWithChanges] if the file was written
  /// successfully but external changes were detected (race condition).
  Future<EditorSaveResult> _writeAndVerify() async {
    await _runtime.writeFile(path, _text);
    final verified = await _runtime.readFile(path);
    // Always update baseline to what's on disk after write.
    // This handles the case where another process modified the file
    // between our write and verify (race condition).
    _baseline = verified;
    if (verified != _text) {
      // File was written but something else modified it immediately after.
      // Our write was successful, just accept the disk state.
      return EditorSaveResult.verifiedWithChanges;
    }
    return EditorSaveResult.saved;
  }

  void _ensureLoaded() {
    if (!_loaded) throw StateError('Document is not loaded.');
  }
}
