/// MCP server settings tab — add, edit, connect, and delete MCP servers.
///
/// Each MCP server config specifies an endpoint (HTTP) or command (stdio) and
/// optional auth headers. Connected servers show their discovered tools.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../storage/mcp_server_repository.dart';

/// MCP servers provider for the active workspace.
final FutureProvider<List<McpServerConfig>> mcpServersProvider =
    FutureProvider<List<McpServerConfig>>((ref) async {
  final workspaceId = ref.watch(activeWorkspaceProvider);
  if (workspaceId == null) return <McpServerConfig>[];
  return ref.watch(mcpServerRepositoryProvider).forWorkspace(workspaceId);
});

/// The MCP settings tab body.
class McpSettingsTab extends ConsumerWidget {
  const McpSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceProvider);
    if (workspaceId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Select a workspace first.'),
        ),
      );
    }
    final serversAsync = ref.watch(mcpServersProvider);
    return serversAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (servers) {
        if (servers.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.extension_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'No MCP servers configured.',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add an MCP server to extend the agent with external tools.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: servers.length,
          itemBuilder: (context, i) {
            final server = servers[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  server.enabled ? Icons.extension : Icons.extension_outlined,
                  color: server.enabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                title: Text(server.name),
                subtitle: Text(
                  '${server.transport.toUpperCase()} · ${server.endpoint}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _editServer(context, ref, server, workspaceId);
                    } else if (value == 'delete') {
                      await _deleteServer(context, ref, server);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editServer(
    BuildContext context,
    WidgetRef ref,
    McpServerConfig? existing,
    String workspaceId,
  ) async {
    final result = await showDialog<McpServerConfig>(
      context: context,
      builder: (_) => McpServerDialog(existing: existing, workspaceId: workspaceId),
    );
    if (result == null) return;
    await ref.read(mcpServerRepositoryProvider).upsert(result);
    ref.invalidate(mcpServersProvider);
  }

  Future<void> _deleteServer(
    BuildContext context,
    WidgetRef ref,
    McpServerConfig server,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${server.name}"?'),
        content: const Text('This MCP server will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(mcpServerRepositoryProvider).delete(server.id);
    ref.invalidate(mcpServersProvider);
  }
}

/// Dialog to add or edit an MCP server config.
class McpServerDialog extends ConsumerStatefulWidget {
  const McpServerDialog({
    super.key,
    this.existing,
    required this.workspaceId,
  });

  final McpServerConfig? existing;
  final String workspaceId;

  @override
  ConsumerState<McpServerDialog> createState() => _McpServerDialogState();
}

class _McpServerDialogState extends ConsumerState<McpServerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _endpoint;
  late final TextEditingController _authHeader;
  late String _transport;
  bool _enabled = true;
  bool _autoConnect = true;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _name = TextEditingController(text: c?.name ?? '');
    _endpoint = TextEditingController(text: c?.endpoint ?? '');
    _authHeader = TextEditingController(
      text: c?.headers['Authorization'] ?? '',
    );
    _transport = c?.transport ?? 'http';
    _enabled = c?.enabled ?? true;
    _autoConnect = c?.autoConnect ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _endpoint.dispose();
    _authHeader.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final existing = widget.existing;
    final headers = <String, String>{};
    if (_authHeader.text.isNotEmpty) {
      headers['Authorization'] = _authHeader.text;
    }

    final config = McpServerConfig(
      id: existing?.id ?? newId(),
      workspaceId: widget.workspaceId,
      name: _name.text.trim(),
      transport: _transport,
      endpoint: _endpoint.text.trim(),
      headers: headers,
      enabled: _enabled,
      autoConnect: _autoConnect,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    Navigator.pop(context, config);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.existing == null ? 'Add MCP Server' : 'Edit MCP Server'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _transport,
                  decoration: const InputDecoration(labelText: 'Transport'),
                  items: const [
                    DropdownMenuItem(value: 'http', child: Text('HTTP (streamable)')),
                    DropdownMenuItem(
                        value: 'stdio', child: Text('stdio (local command)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _transport = v);
                  },
                ),
                const SizedBox(height: 12),
                if (_transport == 'http')
                  TextFormField(
                    controller: _endpoint,
                    decoration: const InputDecoration(
                      labelText: 'Endpoint URL',
                      hintText: 'https://mcp.example.com/mcp',
                    ),
                    keyboardType: TextInputType.url,
                    validator: (v) =>
                        _transport == 'http' && (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authHeader,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Authorization header (optional)',
                    hintText: 'Bearer ...',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enabled'),
                  subtitle: const Text('Agent can use this server'),
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
                SwitchListTile(
                  title: const Text('Auto-connect'),
                  subtitle: const Text('Connect when workspace opens'),
                  value: _autoConnect,
                  onChanged: (v) => setState(() => _autoConnect = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
