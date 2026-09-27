/// File browser tab (design doc §22).
///
/// A read-only tree over the workspace via the [Runtime] abstraction, so it
/// works identically on desktop (LocalRuntime) and Android (BridgeRuntime).
/// Tapping a folder navigates in; tapping a file opens a viewer. The agent edits
/// files through tools — this screen just lets the user inspect the same tree.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../app/theme.dart';
import '../../runtime/runtime.dart';

/// Files larger than this are not opened in the viewer (avoid OOM on binaries).
const int _maxPreviewBytes = 512 * 1024;

class FilesPage extends ConsumerStatefulWidget {
  const FilesPage({super.key});

  @override
  ConsumerState<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends ConsumerState<FilesPage> {
  /// Path relative to the workspace root; empty string means the root itself.
  String _path = '';
  final List<String> _history = <String>[];

  List<FileEntry> _entries = const <FileEntry>[];
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(currentWorkspaceProvider);
    final runtimeAsync = ref.watch(runtimeProvider);

    // Reset to the root whenever the active workspace changes. The body's
    // auto-load picks up the new runtime on the next frame.
    ref.listen<String?>(activeWorkspaceProvider, (
      String? previous,
      String? next,
    ) {
      if (previous == next) return;
      _path = '';
      _history.clear();
      _entries = const <FileEntry>[];
      _error = null;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(workspace?.name ?? context.l10n.files),
        bottom: workspace == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: _Breadcrumb(path: _path, onCrumb: _navigateTo),
              ),
        actions: <Widget>[
          PopupMenuButton<_CreateKind>(
            tooltip: context.l10n.create,
            enabled: workspace != null,
            onSelected: _createEntry,
            itemBuilder: (context) => <PopupMenuEntry<_CreateKind>>[
              PopupMenuItem(
                value: _CreateKind.file,
                child: ListTile(
                  leading: const Icon(Icons.note_add_outlined),
                  title: Text(context.l10n.newFile),
                ),
              ),
              PopupMenuItem(
                value: _CreateKind.folder,
                child: ListTile(
                  leading: const Icon(Icons.create_new_folder_outlined),
                  title: Text(context.l10n.newFolder),
                ),
              ),
            ],
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: context.l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: workspace == null ? null : () => _load(),
          ),
        ],
      ),
      body: Builder(
        builder: (BuildContext context) {
          if (workspace == null) {
            return _FilesHint(
              icon: Icons.folder_off_outlined,
              message: context.l10n.selectWorkspaceForFiles,
            );
          }
          final runtime = runtimeAsync.value;
          if (runtimeAsync.isLoading || (runtime == null && _entries.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (runtime == null) {
            return _FilesHint(
              icon: Icons.link_off,
              message: context.l10n.runtimeUnavailable,
            );
          }
          // Kick off a load the first time we have a runtime and no entries.
          if (!_loading && _entries.isEmpty && _error == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _load());
          }
          return _buildListing();
        },
      ),
    );
  }

  Widget _buildListing() {
    if (_error != null) {
      return _FilesHint(
        icon: Icons.error_outline,
        message: _error!,
        action: TextButton(onPressed: _load, child: Text(context.l10n.retry)),
      );
    }
    if (_loading && _entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return _FilesHint(
        icon: Icons.folder_open,
        message: context.l10n.emptyFolder,
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _entries.length + 1, // +1 for the ".." row when not at root.
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            if (_path.isEmpty) {
              return const SizedBox.shrink();
            }
            return ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('..'),
              subtitle: Text(context.l10n.parentFolder),
              onTap: _navigateUp,
            );
          }
          final entry = _entries[index - 1];
          return _FileTile(
            entry: entry,
            onTap: () =>
                entry.isDirectory ? _navigateInto(entry) : _openFile(entry),
            onEdit: entry.isDirectory ? null : () => _openFile(entry),
            onRename: () => _renameEntry(entry),
            onDelete: () => _deleteEntry(entry),
          );
        },
      ),
    );
  }

  Future<void> _load() async {
    final runtime = ref.read(runtimeProvider).value;
    if (runtime == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await runtime.listFiles(_path);
      final sorted = <FileEntry>[...entries]
        ..sort((FileEntry a, FileEntry b) {
          if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      if (!mounted) return;
      setState(() {
        _entries = sorted;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _entries = const <FileEntry>[];
        _loading = false;
        _error = 'Cannot list folder: $e';
      });
    }
  }

  void _navigateInto(FileEntry entry) {
    _history.add(_path);
    _path = entry.path;
    _entries = const <FileEntry>[];
    _load();
  }

  void _navigateUp() {
    if (_history.isEmpty) {
      _path = '';
    } else {
      _path = _history.removeLast();
    }
    _entries = const <FileEntry>[];
    _load();
  }

  /// Jumps to a prefix of the current path tapped in the breadcrumb.
  void _navigateTo(String path) {
    if (path == _path) return;
    _history.add(_path);
    _path = path;
    _entries = const <FileEntry>[];
    _load();
  }

  Future<void> _openFile(FileEntry entry) async {
    if (entry.size > _maxPreviewBytes) {
      _snack(
        '${entry.name} is too large to preview '
        '(${_humanSize(entry.size)}).',
      );
      return;
    }
    await context.pushNamed<void>(
      'editor',
      queryParameters: <String, String>{'path': entry.path, 'name': entry.name},
    );
    if (mounted) await _load();
  }

  Future<void> _createEntry(_CreateKind kind) async {
    final name = await _askForName(
      title: kind == _CreateKind.file
          ? context.l10n.newFile
          : context.l10n.newFolder,
    );
    if (!mounted || name == null) return;
    final runtime = ref.read(runtimeProvider).value;
    if (runtime == null) return;
    final path = _childPath(name);
    final entryAlreadyExists = context.l10n.entryAlreadyExists;
    try {
      if (kind == _CreateKind.folder) {
        await runtime.createDirectory(path);
      } else {
        if (await runtime.fileExists(path)) {
          throw StateError(entryAlreadyExists);
        }
        await runtime.writeFile(path, '');
      }
      await _load();
      if (kind == _CreateKind.file && mounted) {
        await _openFile(FileEntry(name: name, path: path, isDirectory: false));
      }
    } catch (error) {
      if (mounted) _snack(context.l10n.fileOperationFailed(error));
    }
  }

  Future<void> _renameEntry(FileEntry entry) async {
    final name = await _askForName(
      title: context.l10n.rename,
      initialValue: entry.name,
    );
    if (!mounted || name == null || name == entry.name) return;
    final runtime = ref.read(runtimeProvider).value;
    if (runtime == null) return;
    try {
      await runtime.renameEntry(entry.path, _childPath(name));
      await _load();
    } catch (error) {
      if (mounted) _snack(context.l10n.fileOperationFailed(error));
    }
  }

  Future<void> _deleteEntry(FileEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteEntryTitle(entry.name)),
        content: Text(
          entry.isDirectory
              ? context.l10n.deleteFolderDescription
              : context.l10n.deleteFileDescription,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final runtime = ref.read(runtimeProvider).value;
    if (runtime == null) return;
    try {
      await runtime.deleteEntry(entry.path);
      await _load();
    } catch (error) {
      if (mounted) _snack(context.l10n.fileOperationFailed(error));
    }
  }

  Future<String?> _askForName({
    required String title,
    String initialValue = '',
  }) async {
    var value = initialValue;
    String? errorText;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: TextFormField(
            initialValue: initialValue,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.l10n.name,
              errorText: errorText,
            ),
            onChanged: (newValue) => value = newValue,
            onFieldSubmitted: (submittedValue) {
              value = submittedValue;
              final error = _nameError(submittedValue);
              if (error == null) {
                Navigator.pop(context, submittedValue.trim());
              }
              if (error != null) setDialogState(() => errorText = error);
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final error = _nameError(value);
                if (error == null) {
                  Navigator.pop(context, value.trim());
                } else {
                  setDialogState(() => errorText = error);
                }
              },
              child: Text(context.l10n.create),
            ),
          ],
        ),
      ),
    );
  }

  String? _nameError(String value) {
    final name = value.trim();
    if (name.isEmpty) return context.l10n.requiredField;
    if (name == '.' ||
        name == '..' ||
        name.contains('/') ||
        name.contains('\\')) {
      return context.l10n.invalidFileName;
    }
    return null;
  }

  String _childPath(String name) => _path.isEmpty ? name : '$_path/$name';

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.entry,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    this.onEdit,
  });

  final FileEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        entry.isDirectory ? Icons.folder : _iconFor(entry.name),
        color: entry.isDirectory ? scheme.primary : scheme.outline,
      ),
      title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: entry.isDirectory
          ? null
          : Text(
              _humanSize(entry.size),
              style: Theme.of(context).textTheme.bodySmall,
            ),
      trailing: PopupMenuButton<_EntryAction>(
        onSelected: (action) {
          switch (action) {
            case _EntryAction.edit:
              onEdit?.call();
              return;
            case _EntryAction.rename:
              onRename();
              return;
            case _EntryAction.delete:
              onDelete();
              return;
          }
        },
        itemBuilder: (context) => <PopupMenuEntry<_EntryAction>>[
          if (onEdit != null)
            PopupMenuItem(
              value: _EntryAction.edit,
              child: Text(context.l10n.edit),
            ),
          PopupMenuItem(
            value: _EntryAction.rename,
            child: Text(context.l10n.rename),
          ),
          PopupMenuItem(
            value: _EntryAction.delete,
            child: Text(context.l10n.delete),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  static IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.dart')) return Icons.code;
    if (lower.endsWith('.md') || lower.endsWith('.txt')) {
      return Icons.description_outlined;
    }
    if (lower.endsWith('.json') ||
        lower.endsWith('.yaml') ||
        lower.endsWith('.yml') ||
        lower.endsWith('.toml')) {
      return Icons.data_object;
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return Icons.image_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}

enum _CreateKind { file, folder }

enum _EntryAction { edit, rename, delete }

/// Clickable path breadcrumb, e.g. `root / lib / ui`.
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.path, required this.onCrumb});

  final String path;
  final void Function(String path) onCrumb;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final segments = path.isEmpty
        ? const <String>[]
        : path.split(RegExp(r'[\\/]'));
    final crumbs = <Widget>[
      _Crumb(label: 'root', isLast: segments.isEmpty, onTap: () => onCrumb('')),
    ];
    var acc = '';
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      acc = acc.isEmpty ? seg : '$acc/$seg';
      final target = acc;
      crumbs.add(Text('/', style: TextStyle(color: scheme.outline)));
      crumbs.add(
        _Crumb(
          label: seg,
          isLast: i == segments.length - 1,
          onTap: () => onCrumb(target),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: crumbs),
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.label,
    required this.isLast,
    required this.onTap,
  });

  final String label;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: isLast ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: AppTheme.code.copyWith(
            color: isLast ? scheme.onSurface : scheme.primary,
            fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _FilesHint extends StatelessWidget {
  const _FilesHint({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.outline),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

String _humanSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
