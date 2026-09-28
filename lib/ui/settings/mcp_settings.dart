/// MCP server settings tab — add, edit, connect, and delete MCP servers.
///
/// Each MCP server config specifies an endpoint (HTTP) or command (stdio) and
/// optional auth headers. Connected servers show their discovered tools and
/// connection status.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/mcp/mcp_connection_manager.dart';
import '../../l10n/l10n.dart';
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(context.l10n.selectWorkspaceFirstMcp),
        ),
      );
    }
    final serversAsync = ref.watch(mcpServersProvider);
    return serversAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(context.l10n.errorGeneric(e))),
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
                        context.l10n.noMcpServers,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.addMcpHint,
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

        final manager = ref.watch(mcpConnectionManagerProvider);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: servers.length,
          itemBuilder: (context, i) {
            final server = servers[i];
            final state = manager.stateFor(server.id);
            return _buildServerCard(context, ref, server, state, workspaceId);
          },
        );
      },
    );
  }

  Widget _buildServerCard(
    BuildContext context,
    WidgetRef ref,
    McpServerConfig server,
    McpConnectionState? state,
    String workspaceId,
  ) {
    final status = state?.status ?? McpConnectionStatus.disconnected;
    final theme = Theme.of(context);
    final statusColor = _statusColor(status, theme);
    final statusLabel = _statusLabel(status, context);
    final subtitle = server.transport == 'stdio'
        ? 'stdio · ${server.command}'
        : '${server.transport.toUpperCase()} · ${server.endpoint}';
    final tools = state?.tools ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  server.enabled ? Icons.extension : Icons.extension_outlined,
                  color: server.enabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            title: Text(server.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (status == McpConnectionStatus.error && state?.error != null)
                  Text(
                    state!.error!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(statusLabel, style: const TextStyle(fontSize: 11)),
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  side: BorderSide(color: statusColor, width: 0.5),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _editServer(context, ref, server, workspaceId);
                    } else if (value == 'connect') {
                      final manager = ref.read(mcpConnectionManagerProvider);
                      await manager.connect(server.id);
                      ref.invalidate(mcpServersProvider);
                    } else if (value == 'disconnect') {
                      final manager = ref.read(mcpConnectionManagerProvider);
                      await manager.disconnect(server.id);
                      ref.invalidate(mcpServersProvider);
                    } else if (value == 'refresh') {
                      final manager = ref.read(mcpConnectionManagerProvider);
                      try {
                        await manager.refreshTools(server.id);
                      } catch (_) {}
                      ref.invalidate(mcpServersProvider);
                    } else if (value == 'test') {
                      await _testConnection(context, ref, server);
                    } else if (value == 'delete') {
                      await _deleteServer(context, ref, server);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'test', child: Text(context.l10n.testConnection)),
                    if (status != McpConnectionStatus.connected)
                      PopupMenuItem(value: 'connect', child: Text(context.l10n.connect)),
                    if (status == McpConnectionStatus.connected) ...[
                      PopupMenuItem(
                          value: 'disconnect', child: Text(context.l10n.disconnect)),
                      PopupMenuItem(
                          value: 'refresh', child: Text(context.l10n.refreshTools)),
                    ],
                    PopupMenuItem(value: 'edit', child: Text(context.l10n.edit)),
                    PopupMenuItem(value: 'delete', child: Text(context.l10n.delete)),
                  ],
                ),
              ],
            ),
          ),
          // Show discovered tools when connected.
          if (status == McpConnectionStatus.connected && tools.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border(
                  top: BorderSide(color: theme.dividerColor, width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.toolsAvailable(tools.length),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tools.map((tool) {
                      return Tooltip(
                        message: tool.description,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                          ),
                          child: Text(
                            tool.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(McpConnectionStatus status, ThemeData theme) {
    switch (status) {
      case McpConnectionStatus.connected:
        return Colors.green;
      case McpConnectionStatus.connecting:
        return Colors.orange;
      case McpConnectionStatus.error:
        return theme.colorScheme.error;
      case McpConnectionStatus.disconnected:
        return theme.colorScheme.outline;
    }
  }

  String _statusLabel(McpConnectionStatus status, BuildContext context) {
    switch (status) {
      case McpConnectionStatus.connected:
        return context.l10n.mcpConnected;
      case McpConnectionStatus.connecting:
        return context.l10n.mcpConnecting;
      case McpConnectionStatus.error:
        return context.l10n.phaseError;
      case McpConnectionStatus.disconnected:
        return context.l10n.mcpDisconnected;
    }
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

  Future<void> _testConnection(
    BuildContext context,
    WidgetRef ref,
    McpServerConfig server,
  ) async {
    // Show a progress dialog while testing.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final manager = ref.read(mcpConnectionManagerProvider);
    final (success, toolCount, error) = await manager.testConnection(server);

    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss progress dialog

    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(success ? context.l10n.connectionSuccessful : context.l10n.connectionFailedTitle),
          ],
        ),
        content: success
            ? Text(context.l10n.connectionSuccessfulDetail(toolCount))
            : Text(error ?? context.l10n.unknownError),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.accept),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteServer(
    BuildContext context,
    WidgetRef ref,
    McpServerConfig server,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.deleteMcpConfigTitle(server.name)),
        content: Text(context.l10n.deleteMcpConfigDescription),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(mcpServerRepositoryProvider).delete(server.id);
    await ref.read(mcpConnectionManagerProvider).onServerDeleted(server.id);
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
  late final TextEditingController _command;
  late final TextEditingController _arguments;
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
    _command = TextEditingController(text: c?.command ?? '');
    _arguments = TextEditingController(
      text: (c?.arguments ?? const <String>[]).join(' '),
    );
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
    _command.dispose();
    _arguments.dispose();
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

    final args = _arguments.text.trim().isEmpty
        ? <String>[]
        : _arguments.text.trim().split(RegExp(r'\s+'));

    final config = McpServerConfig(
      id: existing?.id ?? newId(),
      workspaceId: widget.workspaceId,
      name: _name.text.trim(),
      transport: _transport,
      endpoint: _transport == 'http' ? _endpoint.text.trim() : '',
      command: _transport == 'stdio' ? _command.text.trim() : '',
      arguments: _transport == 'stdio' ? args : const <String>[],
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
          widget.existing == null ? context.l10n.addMcpServer : context.l10n.editMcpServer),
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
                  decoration: InputDecoration(labelText: context.l10n.name),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? context.l10n.requiredField : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _transport,
                  decoration: InputDecoration(labelText: context.l10n.transport),
                  items: [
                    DropdownMenuItem(value: 'http', child: Text('HTTP (streamable)')),
                    DropdownMenuItem(
                        value: 'stdio', child: Text('stdio (${context.l10n.command})')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _transport = v);
                  },
                ),
                const SizedBox(height: 12),
                if (_transport == 'http')
                  TextFormField(
                    controller: _endpoint,
                    decoration: InputDecoration(
                      labelText: context.l10n.endpointUrl,
                      hintText: context.l10n.endpointUrlHint,
                    ),
                    keyboardType: TextInputType.url,
                    validator: (v) =>
                        _transport == 'http' && (v == null || v.trim().isEmpty)
                            ? context.l10n.requiredField
                            : null,
                  ),
                if (_transport == 'stdio') ...[
                  TextFormField(
                    controller: _command,
                    decoration: InputDecoration(
                      labelText: context.l10n.command,
                      hintText: context.l10n.commandHint,
                    ),
                    validator: (v) =>
                        _transport == 'stdio' && (v == null || v.trim().isEmpty)
                            ? context.l10n.requiredField
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _arguments,
                    decoration: InputDecoration(
                      labelText: context.l10n.argumentsLabel,
                      hintText: context.l10n.argumentsHint,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authHeader,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.authorizationHeader,
                    hintText: 'Bearer ...',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(context.l10n.mcpEnabled),
                  subtitle: Text(context.l10n.mcpEnabledDescription),
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
                SwitchListTile(
                  title: Text(context.l10n.mcpAutoConnect),
                  subtitle: Text(context.l10n.mcpAutoConnectDescription),
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
            child: Text(context.l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(context.l10n.save)),
      ],
    );
  }
}
