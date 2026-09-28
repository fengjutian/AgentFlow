library;

import 'package:path/path.dart' as p;

enum DiagnosticSeverity { error, warning, information }

class EditorLocation {
  const EditorLocation({required this.path, this.line = 1, this.column = 1});

  final String path;
  final int line;
  final int column;
}

class EditorTab {
  const EditorTab({required this.path, required this.name, this.location});

  final String path;
  final String name;
  final EditorLocation? location;

  EditorTab copyWith({EditorLocation? location}) => EditorTab(
        path: path,
        name: name,
        location: location ?? this.location,
      );
}

class EditorDiagnostic {
  const EditorDiagnostic({
    required this.message,
    required this.location,
    this.severity = DiagnosticSeverity.error,
    this.source,
  });

  final String message;
  final EditorLocation location;
  final DiagnosticSeverity severity;
  final String? source;
}

class EditorWorkspaceState {
  const EditorWorkspaceState({
    this.tabs = const <EditorTab>[],
    this.activeIndex = -1,
    this.recentFiles = const <EditorTab>[],
    this.diagnostics = const <EditorDiagnostic>[],
  });

  final List<EditorTab> tabs;
  final int activeIndex;
  final List<EditorTab> recentFiles;
  final List<EditorDiagnostic> diagnostics;

  EditorTab? get activeTab =>
      activeIndex >= 0 && activeIndex < tabs.length ? tabs[activeIndex] : null;
}

class EditorWorkspaceController {
  EditorWorkspaceController({List<EditorTab> recentFiles = const <EditorTab>[]})
      : state = EditorWorkspaceState(recentFiles: List.unmodifiable(recentFiles));

  static const int maxRecentFiles = 12;

  EditorWorkspaceState state;

  void open(EditorLocation location, {String? name}) {
    final normalized = p.posix.normalize(location.path.replaceAll('\\', '/'));
    final index = state.tabs.indexWhere((tab) => tab.path == normalized);
    final tab = EditorTab(
      path: normalized,
      name: name ?? p.basename(normalized),
      location: EditorLocation(
        path: normalized,
        line: location.line < 1 ? 1 : location.line,
        column: location.column < 1 ? 1 : location.column,
      ),
    );
    final tabs = <EditorTab>[...state.tabs];
    final activeIndex = index < 0 ? tabs.length : index;
    if (index < 0) {
      tabs.add(tab);
    } else {
      tabs[index] = tab;
    }
    final recent = <EditorTab>[
      tab,
      ...state.recentFiles.where((item) => item.path != normalized),
    ].take(maxRecentFiles).toList(growable: false);
    state = EditorWorkspaceState(
      tabs: List.unmodifiable(tabs),
      activeIndex: activeIndex,
      recentFiles: List.unmodifiable(recent),
      diagnostics: state.diagnostics,
    );
  }

  void activate(int index) {
    if (index < 0 || index >= state.tabs.length) return;
    state = EditorWorkspaceState(
      tabs: state.tabs,
      activeIndex: index,
      recentFiles: state.recentFiles,
      diagnostics: state.diagnostics,
    );
  }

  void close(int index) {
    if (index < 0 || index >= state.tabs.length) return;
    final tabs = <EditorTab>[...state.tabs]..removeAt(index);
    var active = state.activeIndex;
    if (tabs.isEmpty) {
      active = -1;
    } else if (index < active) {
      active--;
    } else if (active >= tabs.length) {
      active = tabs.length - 1;
    }
    state = EditorWorkspaceState(
      tabs: List.unmodifiable(tabs),
      activeIndex: active,
      recentFiles: state.recentFiles,
      diagnostics: state.diagnostics,
    );
  }

  void setDiagnostics(List<EditorDiagnostic> diagnostics) {
    state = EditorWorkspaceState(
      tabs: state.tabs,
      activeIndex: state.activeIndex,
      recentFiles: state.recentFiles,
      diagnostics: List.unmodifiable(diagnostics),
    );
  }
}
