library;

import '../../runtime/runtime.dart';

enum EditorSaveResult { saved, conflict }

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
    await _writeAndVerify();
    return EditorSaveResult.saved;
  }

  Future<void> overwrite() async {
    _ensureLoaded();
    await _writeAndVerify();
  }

  Future<String> reload() => load();

  Future<void> _writeAndVerify() async {
    await _runtime.writeFile(path, _text);
    final verified = await _runtime.readFile(path);
    if (verified != _text) {
      throw StateError('Saved content could not be verified.');
    }
    _baseline = verified;
  }

  void _ensureLoaded() {
    if (!_loaded) throw StateError('Document is not loaded.');
  }
}
