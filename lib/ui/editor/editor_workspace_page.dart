library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/editor/editor_file_index.dart';
import '../../core/editor/editor_workspace.dart';
import '../../l10n/l10n.dart';
import '../../runtime/runtime.dart';
import '../search/search_page.dart';
import 'editor_page.dart';
import 'git_panel.dart';

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
            ? Center(child: Text(context.l10n.noDiagnostics))
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

  Future<void> _showQuickOpen() async {
    final runtime = await ref.read(runtimeProvider.future);
    if (!mounted || runtime == null) return;
    final entry = await showDialog<FileEntry>(
      context: context,
      builder: (context) => _QuickOpenDialog(
        files: EditorFileIndex(runtime.listFiles).scan(),
      ),
    );
    if (!mounted || entry == null) return;
    _open(
      EditorLocation(path: entry.path),
      name: entry.name,
      persist: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final diagnostics = ref.watch(editorDiagnosticsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.openFiles),
        actions: <Widget>[
          IconButton(
            tooltip: context.l10n.quickOpen,
            onPressed: _showQuickOpen,
            icon: const Icon(Icons.find_in_page_outlined),
          ),
          IconButton(
            tooltip: context.l10n.search,
            onPressed: () => showSearchPage(context),
            icon: const Icon(Icons.travel_explore_outlined),
          ),
          IconButton(
            tooltip: context.l10n.gitStatus,
            onPressed: () => showGitPanel(context),
            icon: const Icon(Icons.source_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: context.l10n.recentFiles,
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
              tooltip: context.l10n.diagnostics,
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

class _QuickOpenDialog extends StatefulWidget {
  const _QuickOpenDialog({required this.files});

  final Future<List<FileEntry>> files;

  @override
  State<_QuickOpenDialog> createState() => _QuickOpenDialogState();
}

class _QuickOpenDialogState extends State<_QuickOpenDialog> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.quickOpen),
      content: SizedBox(
        width: 560,
        height: 480,
        child: Column(
          children: <Widget>[
            TextField(
              controller: _query,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: context.l10n.searchFiles,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<FileEntry>>(
                future: widget.files,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('${snapshot.error}'));
                  }
                  final query = _query.text.trim().toLowerCase();
                  final matches = (snapshot.data ?? const <FileEntry>[])
                      .where(
                        (entry) => query.isEmpty ||
                            entry.path.toLowerCase().contains(query),
                      )
                      .take(200)
                      .toList(growable: false);
                  if (matches.isEmpty) {
                    return Center(child: Text(context.l10n.noFiles));
                  }
                  return ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final entry = matches[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(entry.name),
                        subtitle: Text(
                          entry.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.pop(context, entry),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
      ],
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
