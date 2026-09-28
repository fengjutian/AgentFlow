library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/editor/editor_workspace.dart';
import '../../l10n/l10n.dart';
import 'editor_page.dart';

class EditorWorkspacePage extends ConsumerStatefulWidget {
  const EditorWorkspacePage({
    super.key,
    required this.path,
    required this.name,
    this.line = 1,
    this.column = 1,
  });

  final String path;
  final String name;
  final int line;
  final int column;

  @override
  ConsumerState<EditorWorkspacePage> createState() =>
      _EditorWorkspacePageState();
}

class _EditorWorkspacePageState extends ConsumerState<EditorWorkspacePage> {
  late final EditorWorkspaceController _controller;

  @override
  void initState() {
    super.initState();
    final workspace = ref.read(currentWorkspaceProvider);
    final rawRecent = workspace?.settings['recentFiles'];
    final recent = rawRecent is List
        ? rawRecent
            .whereType<String>()
            .map((path) => EditorTab(path: path, name: _basename(path)))
            .toList(growable: false)
        : const <EditorTab>[];
    _controller = EditorWorkspaceController(recentFiles: recent);
    final rawOpenFiles = workspace?.settings['openEditorFiles'];
    if (rawOpenFiles is List) {
      for (final path in rawOpenFiles.whereType<String>()) {
        if (path != widget.path) {
          _controller.open(EditorLocation(path: path));
        }
      }
    }
    _controller.open(
      EditorLocation(
        path: widget.path,
        line: widget.line,
        column: widget.column,
      ),
      name: widget.name,
    );
    unawaited(_persistEditorState());
  }

  void _open(
    EditorLocation location, {
    String? name,
    bool persist = false,
  }) {
    _controller.open(location, name: name);
    if (mounted) setState(() {});
    if (persist) unawaited(_persistEditorState());
  }

  Future<void> _persistEditorState() async {
    final workspace = ref.read(currentWorkspaceProvider);
    if (workspace == null) return;
    final settings = <String, dynamic>{...workspace.settings};
    settings['recentFiles'] = _controller.state.recentFiles
        .map((tab) => tab.path)
        .toList(growable: false);
    settings['openEditorFiles'] = _controller.state.tabs
        .map((tab) => tab.path)
        .toList(growable: false);
    await ref
        .read(workspaceRepositoryProvider)
        .upsert(workspace.copyWith(settings: settings));
    ref.invalidate(workspaceListProvider);
  }

  void _close(int index) {
    _controller.close(index);
    unawaited(_persistEditorState());
    if (_controller.state.tabs.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {});
  }

  void _showDiagnostics() {
    final diagnostics = ref.read(editorDiagnosticsProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: diagnostics.isEmpty
            ? Center(child: Text(_label(context, 'noDiagnostics')))
            : ListView.builder(
                itemCount: diagnostics.length,
                itemBuilder: (context, index) {
                  final diagnostic = diagnostics[index];
                  return ListTile(
                    leading: Icon(_diagnosticIcon(diagnostic.severity)),
                    title: Text(diagnostic.message),
                    subtitle: Text(
                      '${diagnostic.location.path}:'
                      '${diagnostic.location.line}:'
                      '${diagnostic.location.column}',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _open(diagnostic.location, persist: true);
                    },
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final diagnostics = ref.watch(editorDiagnosticsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_label(context, 'openFiles')),
        actions: <Widget>[
          PopupMenuButton<String>(
            tooltip: _label(context, 'recentFiles'),
            icon: const Icon(Icons.history),
            onSelected: (path) => _open(
              EditorLocation(path: path),
              persist: true,
            ),
            itemBuilder: (context) => state.recentFiles
                .map(
                  (tab) => PopupMenuItem<String>(
                    value: tab.path,
                    child: ListTile(
                      dense: true,
                      title: Text(tab.name),
                      subtitle: Text(
                        tab.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          Badge(
            isLabelVisible: diagnostics.isNotEmpty,
            label: Text('${diagnostics.length}'),
            child: IconButton(
              tooltip: _label(context, 'diagnostics'),
              onPressed: _showDiagnostics,
              icon: const Icon(Icons.rule_folder_outlined),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.tabs.length,
              itemBuilder: (context, index) {
                final tab = state.tabs[index];
                final selected = index == state.activeIndex;
                return Material(
                  color: selected
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _controller.activate(index)),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: <Widget>[
                          Text(tab.name),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: context.l10n.close,
                            onPressed: () => _close(index),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: state.activeIndex,
        children: state.tabs
            .map(
              (tab) => EditorPage(
                key: ValueKey(tab.path),
                path: tab.path,
                name: tab.name,
                initialLine: tab.location?.line ?? 1,
                initialColumn: tab.location?.column ?? 1,
                embedded: true,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

String _basename(String path) {
  final segments = path.split(RegExp(r'[/\\]'));
  return segments.isEmpty ? path : segments.last;
}

IconData _diagnosticIcon(DiagnosticSeverity severity) => switch (severity) {
      DiagnosticSeverity.error => Icons.error_outline,
      DiagnosticSeverity.warning => Icons.warning_amber_outlined,
      DiagnosticSeverity.information => Icons.info_outline,
    };

String _label(BuildContext context, String key) {
  final zh = Localizations.localeOf(context).languageCode == 'zh';
  return switch (key) {
    'openFiles' => zh ? '打开的文件' : 'Open files',
    'recentFiles' => zh ? '最近文件' : 'Recent files',
    'diagnostics' => zh ? '诊断' : 'Diagnostics',
    'noDiagnostics' => zh ? '暂无诊断' : 'No diagnostics',
    _ => key,
  };
}
