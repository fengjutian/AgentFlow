/// Workspace selection & creation (design doc §18).
///
/// A workspace binds a name to a directory the agent operates on. Creating one
/// is intentionally simple for the MVP: name + path. On desktop the path is a
/// normal folder; on Android it is a path the Kotlin runtime / Termux can reach.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../app/providers.dart';
import '../../storage/repositories.dart';
import '../../l10n/l10n.dart';

/// Opens a bottom sheet to pick or create a workspace.
Future<void> showWorkspacePicker(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => const _WorkspaceSheet(),
  );
}

class _WorkspaceSheet extends ConsumerWidget {
  const _WorkspaceSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaces = ref.watch(workspaceListProvider);
    final activeId = ref.watch(activeWorkspaceProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(context.l10n.workspaces,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            workspaces.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object e, _) => Text(context.l10n.failedToLoad(e)),
              data: (List<Workspace> list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(context.l10n.noWorkspaces),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (BuildContext context, int i) {
                      final w = list[i];
                      final selected = w.id == activeId;
                      return ListTile(
                        leading: Icon(
                          selected
                              ? Icons.folder_special
                              : Icons.folder_outlined,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        title: Text(w.name),
                        subtitle: Text(
                          w.rootDirectory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (String value) async {
                            if (value == 'delete') {
                              await _confirmDelete(context, ref, w);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                                value: 'delete', child: Text(context.l10n.delete)),
                          ],
                        ),
                        selected: selected,
                        onTap: () {
                          ref.read(activeWorkspaceProvider.notifier).select(w.id);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                final created = await showDialog<Workspace>(
                  context: context,
                  builder: (BuildContext context) => const CreateWorkspaceDialog(),
                );
                if (created != null && context.mounted) {
                  ref.read(activeWorkspaceProvider.notifier).select(created.id);
                  ref.invalidate(workspaceListProvider);
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.create_new_folder_outlined),
              label: Text(context.l10n.newWorkspace),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Workspace w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(context.l10n.deleteWorkspaceTitle(w.name)),
        content: Text(context.l10n.deleteWorkspaceDescription),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.delete)),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(workspaceRepositoryProvider).delete(w.id);
      if (ref.read(activeWorkspaceProvider) == w.id) {
        ref.read(activeWorkspaceProvider.notifier).select(null);
      }
      ref.invalidate(workspaceListProvider);
    }
  }
}

/// Dialog to create a workspace from a name + directory path.
class CreateWorkspaceDialog extends ConsumerStatefulWidget {
  const CreateWorkspaceDialog({super.key});

  @override
  ConsumerState<CreateWorkspaceDialog> createState() =>
      _CreateWorkspaceDialogState();
}

class _CreateWorkspaceDialogState extends ConsumerState<CreateWorkspaceDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _path = TextEditingController(
      text: Directory.current.path);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _path.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final path = _path.text.trim();
    if (name.isEmpty || path.isEmpty) {
      setState(() => _error = context.l10n.workspaceRequiredFields);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final dir = Directory(path);
      final exists = dir.existsSync();
      final workspace = Workspace(
        id: newId(),
        name: name,
        rootDirectory: exists ? dir.absolute.path : path,
        createdAt: DateTime.now(),
      );
      await ref.read<WorkspaceRepository>(workspaceRepositoryProvider)
          .upsert(workspace);
      if (!mounted) return;
      Navigator.of(context).pop(workspace);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.newWorkspace),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.l10n.workspaceName,
              hintText: 'My Project',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _path,
            decoration: InputDecoration(
              labelText: context.l10n.workspacePath,
              hintText: '/path/to/project',
              helperText: context.l10n.workspacePathHelper,
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(context.l10n.cancel)),
        FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator())
                : Text(context.l10n.create)),
      ],
    );
  }
}

/// AppBar-friendly button showing the active workspace; opens the picker.
class WorkspacePickerButton extends ConsumerWidget {
  const WorkspacePickerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(currentWorkspaceProvider);
    return TextButton.icon(
      onPressed: () => showWorkspacePicker(context),
      icon: const Icon(Icons.folder_open, size: 18),
      label: Text(
        workspace?.name ?? context.l10n.selectWorkspace,
        overflow: TextOverflow.ellipsis,
      ),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
