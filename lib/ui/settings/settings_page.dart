/// Settings tab (design doc §24).
///
/// Model provider management: add/edit/delete OpenAI-compatible endpoints, pick
/// the default used for the next run, and see which runtime the active workspace
/// resolved to. Keys are stored in the local database; nothing leaves the device
/// except the model calls themselves.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/model/model_provider.dart';
import '../../runtime/runtime.dart';

/// Known vendor presets: choosing one prefills a sensible base URL.
const Map<String, String> _providerPresets = <String, String>{
  'openai': 'https://api.openai.com/v1',
  'deepseek': 'https://api.deepseek.com/v1',
  'qwen': 'https://dashscope.aliyuncs.com/compatible-mode/v1',
  'gemini': 'https://generativelanguage.googleapis.com/v1beta/openai',
  'openai-compatible': '',
  'local': 'http://localhost:1234/v1',
  'mock': '',
};

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(modelConfigsProvider);
    final activeAsync = ref.watch(activeModelConfigProvider);
    final workspace = ref.watch(currentWorkspaceProvider);
    final runtimeAsync = ref.watch(runtimeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Provider'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: <Widget>[
          _SectionHeader(
            title: 'Model providers',
            subtitle: activeAsync.when(
              data: (ModelConfig c) =>
                  c.provider == 'mock' ? 'Active: offline demo' : 'Active: ${c.label}',
              loading: () => 'Loading…',
              error: (Object _, StackTrace _) => 'Unavailable',
            ),
          ),
          configsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object e, StackTrace _) => Text('Failed to load: $e'),
            data: (List<ModelConfig> configs) {
              if (configs.isEmpty) {
                return const _EmptyProviders();
              }
              return Column(
                children: <Widget>[
                  for (final config in configs)
                    _ProviderTile(
                      config: config,
                      onTap: () => _edit(context, ref, config),
                      onSetDefault: () => _setDefault(ref, config),
                      onDelete: () => _delete(context, ref, config),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Runtime'),
          _RuntimeCard(
            workspaceName: workspace?.name,
            rootDirectory: workspace?.rootDirectory,
            runtime: runtimeAsync.value,
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'About'),
          const _AboutCard(),
        ],
      ),
    );
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, ModelConfig? existing) async {
    final saved = await showDialog<ModelConfig>(
      context: context,
      builder: (BuildContext context) => ProviderEditorDialog(existing: existing),
    );
    if (saved == null) return;
    final repo = ref.read(providerRepositoryProvider);
    await repo.upsert(saved);
    // The very first provider becomes the default automatically.
    final all = await ref.read(providerRepositoryProvider).all();
    if (all.length == 1 || saved.isDefault) {
      await repo.setDefault(saved.id);
    }
    ref.invalidate(modelConfigsProvider);
    ref.invalidate(activeModelConfigProvider);
  }

  Future<void> _setDefault(WidgetRef ref, ModelConfig config) async {
    await ref.read(providerRepositoryProvider).setDefault(config.id);
    ref.invalidate(modelConfigsProvider);
    ref.invalidate(activeModelConfigProvider);
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, ModelConfig config) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Delete "${config.label}"?'),
        content: const Text('This removes the provider configuration.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(providerRepositoryProvider).delete(config.id);
    ref.invalidate(modelConfigsProvider);
    ref.invalidate(activeModelConfigProvider);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...<Widget>[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subtitle!,
                textAlign: TextAlign.right,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyProviders extends StatelessWidget {
  const _EmptyProviders();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.science_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Running in offline demo mode',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'No provider is configured yet, so the agent uses a built-in mock '
              'that demonstrates the loop without any network. Add an '
              'OpenAI-compatible provider to use a real model.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.config,
    required this.onTap,
    required this.onSetDefault,
    required this.onDelete,
  });

  final ModelConfig config;
  final VoidCallback onTap;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMock = config.provider == 'mock';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isMock ? Icons.science_outlined : Icons.cloud_outlined,
          color: config.isDefault ? scheme.primary : scheme.outline,
        ),
        title: Row(
          children: <Widget>[
            Flexible(
              child: Text(config.label,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (config.isDefault) ...<Widget>[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'default',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          isMock ? 'offline mock' : '${config.provider} · ${config.model}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (String value) {
            if (value == 'default') onSetDefault();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
                value: 'default', child: Text('Set as default')),
            const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _RuntimeCard extends StatelessWidget {
  const _RuntimeCard({
    required this.workspaceName,
    required this.rootDirectory,
    required this.runtime,
  });

  final String? workspaceName;
  final String? rootDirectory;
  final Runtime? runtime;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _kv(context, 'Workspace', workspaceName ?? '— none —'),
            const SizedBox(height: 6),
            _kv(context, 'Directory', rootDirectory ?? '—'),
            const SizedBox(height: 6),
            _kv(context, 'Runtime',
                runtime == null ? 'resolving…' : runtime!.label),
            const SizedBox(height: 10),
            Text(
              'On Android the agent prefers the Termux bridge when available and '
              'falls back to on-device execution otherwise.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 92,
          child: Text(k,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        ),
        Expanded(child: SelectableText(v)),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('AgentFlow', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'An on-device AI agent workstation. The agent reads and edits code, '
              'runs commands and operates Git — asking before anything risky.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 8),
            Text('MVP build',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.outline)),
          ],
        ),
      ),
    );
  }
}

/// Add/edit dialog for a [ModelConfig].
class ProviderEditorDialog extends ConsumerStatefulWidget {
  const ProviderEditorDialog({super.key, this.existing});

  final ModelConfig? existing;

  @override
  ConsumerState<ProviderEditorDialog> createState() =>
      _ProviderEditorDialogState();
}

class _ProviderEditorDialogState extends ConsumerState<ProviderEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _model;
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _maxTokens;
  late String _provider;
  late double _temperature;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _provider = c?.provider ?? 'openai-compatible';
    _label = TextEditingController(text: c?.label ?? '');
    _model = TextEditingController(text: c?.model ?? '');
    _baseUrl = TextEditingController(text: c?.baseUrl ?? _providerPresets[_provider] ?? '');
    _apiKey = TextEditingController(text: c?.apiKey ?? '');
    _maxTokens = TextEditingController(text: '${c?.maxTokens ?? 4096}');
    _temperature = c?.temperature ?? 0.2;
  }

  @override
  void dispose() {
    _label.dispose();
    _model.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _maxTokens.dispose();
    super.dispose();
  }

  void _onProviderChanged(String value) {
    setState(() {
      _provider = value;
      final preset = _providerPresets[value];
      // Only overwrite the URL if it is empty or matches another preset.
      if (preset != null &&
          (_baseUrl.text.isEmpty ||
              _providerPresets.containsValue(_baseUrl.text))) {
        _baseUrl.text = preset;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final existing = widget.existing;
    final config = ModelConfig(
      id: existing?.id ?? newId(),
      label: _label.text.trim(),
      provider: _provider,
      model: _model.text.trim(),
      baseUrl: _baseUrl.text.trim(),
      apiKey: _apiKey.text.trim(),
      temperature: _temperature,
      maxTokens: int.tryParse(_maxTokens.text.trim()) ?? 4096,
      contextWindow: existing?.contextWindow ?? 128000,
      isDefault: existing?.isDefault ?? false,
    );
    Navigator.of(context).pop(config);
  }

  @override
  Widget build(BuildContext context) {
    final isMock = _provider == 'mock';
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add provider' : 'Edit provider'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _provider,
                  decoration: const InputDecoration(labelText: 'Provider type'),
                  items: _providerPresets.keys
                      .map((String p) => DropdownMenuItem<String>(
                            value: p,
                            child: Text(p),
                          ))
                      .toList(),
                  onChanged: (String? v) {
                    if (v != null) _onProviderChanged(v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _label,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'DeepSeek (personal)',
                  ),
                  validator: (String? v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _model,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'gpt-4o-mini / deepseek-chat',
                  ),
                  enabled: !isMock,
                  validator: (String? v) => !isMock &&
                          (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _baseUrl,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.example.com/v1',
                  ),
                  enabled: !isMock,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _apiKey,
                  obscureText: _obscureKey,
                  enabled: !isMock,
                  decoration: InputDecoration(
                    labelText: 'API key',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureKey
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Text('Temperature: ${_temperature.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Expanded(
                      child: Slider(
                        value: _temperature,
                        min: 0,
                        max: 1.5,
                        divisions: 30,
                        onChanged: (double v) =>
                            setState(() => _temperature = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _maxTokens,
                  decoration: const InputDecoration(labelText: 'Max tokens'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
