/// Language server settings — configure LSP servers per language.
///
/// Lists all languages with default presets and allows the user to override
/// the command, arguments, and environment for each.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/lsp/lsp_client_manager.dart';
import '../../core/lsp/lsp_config.dart';

/// The LSP settings tab body.
class LspSettingsTab extends ConsumerStatefulWidget {
  const LspSettingsTab({super.key});

  @override
  ConsumerState<LspSettingsTab> createState() => _LspSettingsTabState();
}

class _LspSettingsTabState extends ConsumerState<LspSettingsTab> {
  /// Languages to show in the settings list.
  static const _languages = <String>[
    'dart',
    'python',
    'typescript',
    'javascript',
    'rust',
    'go',
    'java',
    'kotlin',
    'cpp',
    'c',
    'lua',
    'yaml',
    'json',
    'html',
    'css',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final manager = ref.watch(lspClientManagerProvider);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: _languages.length,
      itemBuilder: (context, index) {
        final lang = _languages[index];
        final preset = lspDefaultPresets[lang];
        final isActive = manager.hasClient(lang);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              child: Icon(
                isActive
                    ? Icons.check_circle
                    : Icons.code_outlined,
                size: 20,
                color: isActive
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            title: Text(
              lang[0].toUpperCase() + lang.substring(1),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: preset != null
                ? Text(
                    '${preset.command} ${preset.arguments.join(' ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: scheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    'No default server configured',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.outline,
                        ),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  IconButton(
                    tooltip: 'Stop server',
                    onPressed: () => _stopServer(manager, lang),
                    icon: Icon(Icons.stop, color: scheme.error),
                  ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => _editConfig(lang, preset),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _stopServer(LspClientManager manager, String languageId) {
    unawaited(manager.shutdown(languageId));
    if (mounted) setState(() {});
  }

  void _editConfig(String languageId, LspServerConfig? preset) {
    final commandController = TextEditingController(
      text: preset?.command ?? '',
    );
    final argsController = TextEditingController(
      text: preset?.arguments.join(' ') ?? '',
    );

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$languageId Language Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: commandController,
              decoration: const InputDecoration(
                labelText: 'Command',
                hintText: 'e.g., dart, pyright-langserver',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: argsController,
              decoration: const InputDecoration(
                labelText: 'Arguments',
                hintText: 'e.g., language-server --stdio',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final manager = ref.read(lspClientManagerProvider);
              final command = commandController.text.trim();
              final args = argsController.text
                  .split(RegExp(r'\s+'))
                  .where((s) => s.isNotEmpty)
                  .toList();

              if (command.isNotEmpty) {
                manager.setConfigOverride(
                  languageId,
                  LspServerConfig(
                    languageId: languageId,
                    command: command,
                    arguments: args,
                  ),
                );
              } else {
                manager.clearConfigOverride(languageId);
              }

              Navigator.pop(context);
              if (mounted) setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
