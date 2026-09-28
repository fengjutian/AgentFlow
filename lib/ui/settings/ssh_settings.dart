/// SSH settings tab — add, edit, test and delete SSH connections.
///
/// Each SSH config stores host, port, username, auth method and remote root.
/// Passwords and private keys are kept in SecretStore. A "Test" button
/// performs a live connection and shows the host key fingerprint for the user
/// to confirm on first use.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../runtime/ssh/ssh_runtime.dart';

/// SSH configs provider — filters runtime configs by kind='ssh'.
final FutureProvider<List<RuntimeConfig>> sshConfigsProvider =
    FutureProvider<List<RuntimeConfig>>((ref) async {
  final all = await ref.watch(runtimeConfigsProvider.future);
  return all.where((c) => c.kind == 'ssh').toList();
});

/// The SSH settings tab body.
class SshSettingsTab extends ConsumerWidget {
  const SshSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(sshConfigsProvider);
    return configsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(context.l10n.errorGeneric(e))),
      data: (configs) {
        if (configs.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'No SSH connections configured.',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add an SSH connection to run commands on remote servers.',
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
          itemCount: configs.length,
          itemBuilder: (context, i) {
            final config = configs[i];
            final host = config.options['host'] as String? ?? '';
            final username = config.options['username'] as String? ?? '';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.terminal,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(config.label),
                subtitle: Text('$username@$host'),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _editConfig(context, ref, config);
                    } else if (value == 'test') {
                      await _testConnection(context, ref, config);
                    } else if (value == 'delete') {
                      await _deleteConfig(context, ref, config);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'test', child: Text('Test connection')),
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

  Future<void> _editConfig(
      BuildContext context, WidgetRef ref, RuntimeConfig? existing) async {
    final result = await showDialog<RuntimeConfig>(
      context: context,
      builder: (_) => SshConfigDialog(existing: existing),
    );
    if (result == null) return;
    await ref.read(runtimeConfigRepositoryProvider).upsert(result);
    ref.invalidate(sshConfigsProvider);
    ref.invalidate(runtimeConfigsProvider);
  }

  Future<void> _testConnection(
      BuildContext context, WidgetRef ref, RuntimeConfig config) async {
    final secrets = ref.read(secretStoreProvider);
    final hostKeyStore = ref.read(sshHostKeyStoreProvider);

    final password = await secrets.read('ssh/${config.id}/password');
    final privateKey = await secrets.read('ssh/${config.id}/private-key');
    final passphrase = await secrets.read('ssh/${config.id}/passphrase');

    final sshConfig = SshConfig(
      id: config.id,
      host: config.options['host'] as String? ?? '',
      port: config.options['port'] as int? ?? 22,
      username: config.options['username'] as String? ?? '',
      password: password,
      privateKey: privateKey,
      passphrase: passphrase,
      remoteRoot: config.options['remoteRoot'] as String? ?? '~',
    );

    final runtime = SshRuntime(config: sshConfig, hostKeyStore: hostKeyStore);

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final hostKey = await runtime.testConnection();
      final verification = await hostKeyStore.verify(
        hostKey.host, hostKey.port, hostKey.fingerprint, hostKey.algorithm);

      if (!context.mounted) return;
      Navigator.pop(context); // dismiss spinner

      if (verification.isMismatch) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Host key mismatch!'),
            content: Text(
              'WARNING: The host key for ${hostKey.host}:${hostKey.port} has changed!\n\n'
              'Stored: ${verification.storedKey?.fingerprint}\n'
              'Presented: ${hostKey.fingerprint}\n\n'
              'This could indicate a man-in-the-middle attack.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Reject'),
              ),
            ],
          ),
        );
      } else {
        final accepted = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(verification.isUnknown
                ? 'New host key'
                : 'Host key verified'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${hostKey.host}:${hostKey.port}'),
                const SizedBox(height: 8),
                Text('Algorithm: ${hostKey.algorithm}'),
                Text('Fingerprint: ${hostKey.fingerprint}'),
                if (verification.isUnknown) ...[
                  const SizedBox(height: 12),
                  const Text('Trust this host key for future connections?'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Reject'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(verification.isUnknown ? 'Trust' : 'OK'),
              ),
            ],
          ),
        );
        if (accepted == true && verification.isUnknown) {
          await hostKeyStore.store(hostKey);
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // dismiss spinner
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    } finally {
      runtime.dispose();
    }
  }

  Future<void> _deleteConfig(
      BuildContext context, WidgetRef ref, RuntimeConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${config.label}"?'),
        content: const Text('This SSH connection will be removed.'),
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
    await ref.read(runtimeConfigRepositoryProvider).delete(config.id);
    ref.invalidate(sshConfigsProvider);
    ref.invalidate(runtimeConfigsProvider);
  }
}

/// Dialog to add or edit an SSH connection config.
class SshConfigDialog extends ConsumerStatefulWidget {
  const SshConfigDialog({super.key, this.existing});
  final RuntimeConfig? existing;

  @override
  ConsumerState<SshConfigDialog> createState() => _SshConfigDialogState();
}

class _SshConfigDialogState extends ConsumerState<SshConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _privateKey;
  late final TextEditingController _passphrase;
  late final TextEditingController _remoteRoot;
  String _authMethod = 'password';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _label = TextEditingController(text: c?.label ?? '');
    _host = TextEditingController(text: c?.options['host'] as String? ?? '');
    _port = TextEditingController(text: '${c?.options['port'] as int? ?? 22}');
    _username = TextEditingController(
        text: c?.options['username'] as String? ?? '');
    _password = TextEditingController(); // Never pre-fill password.
    _privateKey = TextEditingController(); // Never pre-fill private key.
    _passphrase = TextEditingController();
    _remoteRoot = TextEditingController(
        text: c?.options['remoteRoot'] as String? ?? '~');
    _authMethod = c?.options['authMethod'] as String? ?? 'password';
  }

  @override
  void dispose() {
    _label.dispose();
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    _privateKey.dispose();
    _passphrase.dispose();
    _remoteRoot.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final existing = widget.existing;
    final config = RuntimeConfig(
      id: existing?.id ?? newId(),
      label: _label.text.trim(),
      kind: 'ssh',
      options: {
        'host': _host.text.trim(),
        'port': int.tryParse(_port.text.trim()) ?? 22,
        'username': _username.text.trim(),
        'remoteRoot': _remoteRoot.text.trim(),
        'authMethod': _authMethod,
      },
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Store secrets.
    final secrets = ref.read(secretStoreProvider);
    if (_authMethod == 'password' && _password.text.isNotEmpty) {
      await secrets.write('ssh/${config.id}/password', _password.text);
    }
    if (_authMethod == 'key' && _privateKey.text.isNotEmpty) {
      await secrets.write('ssh/${config.id}/private-key', _privateKey.text);
      if (_passphrase.text.isNotEmpty) {
        await secrets.write('ssh/${config.id}/passphrase', _passphrase.text);
      }
    }

    if (!mounted) return;
    Navigator.pop(context, config);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add SSH Connection' : 'Edit SSH Connection'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _label,
                  decoration: const InputDecoration(labelText: 'Label'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _host,
                        decoration: const InputDecoration(labelText: 'Host'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _port,
                        decoration: const InputDecoration(labelText: 'Port'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _authMethod,
                  decoration: const InputDecoration(labelText: 'Auth method'),
                  items: const [
                    DropdownMenuItem(value: 'password', child: Text('Password')),
                    DropdownMenuItem(value: 'key', child: Text('Private key')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _authMethod = v);
                  },
                ),
                const SizedBox(height: 12),
                if (_authMethod == 'password')
                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  )
                else ...[
                  TextFormField(
                    controller: _privateKey,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Private key (PEM)',
                      hintText: '-----BEGIN OPENSSH PRIVATE KEY-----',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passphrase,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Key passphrase (optional)',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _remoteRoot,
                  decoration: const InputDecoration(
                    labelText: 'Remote root',
                    hintText: '~',
                  ),
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
