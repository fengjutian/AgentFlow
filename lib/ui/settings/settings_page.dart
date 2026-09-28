/// Settings tab (design doc §24).
///
/// Model provider management: add/edit/delete OpenAI-compatible endpoints, pick
/// the default used for the next run, and see which runtime the active workspace
/// resolved to. Keys are stored in the local database; nothing leaves the device
/// except the model calls themselves.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/l10n.dart';
import '../../core/model/model_provider.dart';
import '../../core/model/provider_catalog.dart';
import '../../data/models.dart';
import '../../runtime/bridge_runtime.dart';
import '../../runtime/runtime.dart';
import '../../storage/mcp_server_repository.dart';
import 'ssh_settings.dart';
import 'mcp_settings.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this)
      ..addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging && mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configsAsync = ref.watch(modelConfigsProvider);
    final activeAsync = ref.watch(activeModelConfigProvider);
    final workspace = ref.watch(currentWorkspaceProvider);
    final runtimeAsync = ref.watch(runtimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: <Widget>[
            Tab(
              icon: const Icon(Icons.hub_outlined),
              text: context.l10n.provider,
            ),
            Tab(
              icon: const Icon(Icons.terminal_outlined),
              text: context.l10n.runtime,
            ),
            Tab(
              icon: const Icon(Icons.cloud_outlined),
              text: 'SSH',
            ),
            Tab(
              icon: const Icon(Icons.extension_outlined),
              text: 'MCP',
            ),
            Tab(icon: const Icon(Icons.info_outline), text: context.l10n.about),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _edit(context, ref, null),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.provider),
            )
          : _tabController.index == 2
              ? FloatingActionButton.extended(
                  onPressed: () => _addSsh(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('SSH'),
                )
              : _tabController.index == 3
                  ? FloatingActionButton.extended(
                      onPressed: () => _addMcp(context, ref),
                      icon: const Icon(Icons.add),
                      label: Text(context.l10n.settings),
                    )
                  : null,
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          ListView(
            key: const PageStorageKey<String>('settings-providers'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: <Widget>[
              _SectionHeader(
                title: context.l10n.modelProviders,
                subtitle: activeAsync.when(
                  data: (ModelConfig c) => c.provider == 'mock'
                      ? context.l10n.activeOfflineDemo
                      : context.l10n.activeProvider(c.label),
                  loading: () => context.l10n.loading,
                  error: (Object _, StackTrace _) => context.l10n.unavailable,
                ),
              ),
              configsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object e, StackTrace _) =>
                    Text(context.l10n.failedToLoad(e)),
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
            ],
          ),
          ListView(
            key: const PageStorageKey<String>('settings-runtime'),
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _SectionHeader(title: context.l10n.runtime),
              _RuntimeCard(
                workspaceName: workspace?.name,
                rootDirectory: workspace?.rootDirectory,
                runtime: runtimeAsync.value,
              ),
            ],
          ),
          const SshSettingsTab(),
          const McpSettingsTab(),
          ListView(
            key: const PageStorageKey<String>('settings-about'),
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _SectionHeader(title: context.l10n.about),
              const _AboutCard(),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addSsh(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<RuntimeConfig>(
      context: context,
      builder: (_) => const SshConfigDialog(),
    );
    if (result == null) return;
    await ref.read(runtimeConfigRepositoryProvider).upsert(result);
    ref.invalidate(sshConfigsProvider);
    ref.invalidate(runtimeConfigsProvider);
  }

  Future<void> _addMcp(BuildContext context, WidgetRef ref) async {
    final workspaceId = ref.read(activeWorkspaceProvider);
    if (workspaceId == null) return;
    final result = await showDialog<McpServerConfig>(
      context: context,
      builder: (_) => McpServerDialog(workspaceId: workspaceId),
    );
    if (result == null) return;
    await ref.read(mcpServerRepositoryProvider).upsert(result);
    ref.invalidate(mcpServersProvider);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ModelConfig? existing,
  ) async {
    final saved = await showDialog<ModelConfig>(
      context: context,
      builder: (BuildContext context) =>
          ProviderEditorDialog(existing: existing),
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
    BuildContext context,
    WidgetRef ref,
    ModelConfig config,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(context.l10n.deleteProviderTitle(config.label)),
        content: Text(context.l10n.deleteProviderDescription),
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.primary),
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
                Text(
                  context.l10n.offlineDemoMode,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.noProviderConfiguredHint,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.outline),
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
              child: Text(
                config.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
            PopupMenuItem<String>(
              value: 'default',
              child: Text(context.l10n.setAsDefault),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text(context.l10n.delete),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuntimeCard extends ConsumerStatefulWidget {
  const _RuntimeCard({
    required this.workspaceName,
    required this.rootDirectory,
    required this.runtime,
  });

  final String? workspaceName;
  final String? rootDirectory;
  final Runtime? runtime;

  @override
  ConsumerState<_RuntimeCard> createState() => _RuntimeCardState();
}

class _RuntimeCardState extends ConsumerState<_RuntimeCard>
    with WidgetsBindingObserver {
  ShellInfo? _shellInfo;
  bool _requesting = false;

  /// Non-null only on Android, where commands may be routed into Termux.
  BridgeRuntime? get _bridge {
    final runtime = widget.runtime;
    return runtime is BridgeRuntime ? runtime : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadShellInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Termux may have been installed or granted while we were in the
    // background, so re-query the bridge whenever the app comes back.
    if (state == AppLifecycleState.resumed) _loadShellInfo();
  }

  @override
  void didUpdateWidget(_RuntimeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime != widget.runtime) _loadShellInfo();
  }

  Future<void> _loadShellInfo() async {
    final bridge = _bridge;
    if (bridge == null) return;
    try {
      final info = await bridge.shellInfo();
      if (mounted) setState(() => _shellInfo = info);
    } on PlatformException {
      // Host without the runtime channel; the card just omits the shell rows.
    } on MissingPluginException {
      // Running on a platform that has no Kotlin bridge at all.
    }
  }

  Future<void> _grantTermuxAccess() async {
    final bridge = _bridge;
    if (bridge == null || _requesting) return;
    setState(() => _requesting = true);
    await bridge.requestTermuxPermission();
    if (!mounted) return;
    setState(() => _requesting = false);
    await _loadShellInfo();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = _shellInfo;
    final needsPermission =
        info != null && info.termuxInstalled && !info.termuxUsable;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _kv(
              context,
              context.l10n.workspace,
              widget.workspaceName ?? '— ${context.l10n.none} —',
            ),
            const SizedBox(height: 6),
            _kv(context, context.l10n.directory, widget.rootDirectory ?? '—'),
            const SizedBox(height: 6),
            _kv(
              context,
              context.l10n.runtime,
              widget.runtime == null
                  ? context.l10n.resolving
                  : widget.runtime!.label,
            ),
            if (info != null) ...<Widget>[
              const SizedBox(height: 6),
              _kv(context, context.l10n.shell, info.shell),
              const SizedBox(height: 6),
              _kv(context, context.l10n.termux, info.termuxState),
            ],
            const SizedBox(height: 10),
            Text(
              context.l10n.termuxDescription,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            if (needsPermission) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                info.termuxPermission
                    ? context.l10n.termuxExternalAppsHint
                    : context.l10n.termuxPermissionHint,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
              if (!info.termuxPermission) ...<Widget>[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _requesting ? null : _grantTermuxAccess,
                  child: Text(
                    _requesting
                        ? context.l10n.waitingForAnswer
                        : context.l10n.grantTermuxAccess,
                  ),
                ),
              ],
            ],
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
          child: Text(
            k,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
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
              context.l10n.aboutDescription,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.mvpBuild,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.outline),
            ),
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
    final preset = providerPresetById(_provider);
    _label = TextEditingController(text: c?.label ?? '');
    _model = TextEditingController(text: c?.model ?? '');
    _baseUrl = TextEditingController(text: c?.baseUrl ?? preset?.baseUrl ?? '');
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
      final preset = providerPresetById(value);
      if (preset == null) return;
      final knownUrls = providerCatalog.map((item) => item.baseUrl);
      final knownModels = providerCatalog.map((item) => item.defaultModel);
      final knownLabels = providerCatalog.map((item) => item.displayName);
      if (_baseUrl.text.isEmpty || knownUrls.contains(_baseUrl.text)) {
        _baseUrl.text = preset.baseUrl;
      }
      if (_model.text.isEmpty || knownModels.contains(_model.text)) {
        _model.text = preset.defaultModel;
      }
      if (_label.text.isEmpty || knownLabels.contains(_label.text)) {
        _label.text = preset.displayName;
      }
      _maxTokens.text = '${preset.maxTokens}';
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
      contextWindow:
          existing?.contextWindow ??
          providerPresetById(_provider)?.contextWindow ??
          128000,
      isDefault: existing?.isDefault ?? false,
    );
    Navigator.of(context).pop(config);
  }

  @override
  Widget build(BuildContext context) {
    final isMock = _provider == 'mock';
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? context.l10n.addProvider
            : context.l10n.editProvider,
      ),
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
                  decoration: InputDecoration(
                    labelText: context.l10n.providerType,
                  ),
                  items: providerCatalog
                      .map(
                        (ProviderPreset preset) => DropdownMenuItem<String>(
                          value: preset.id,
                          child: Text(preset.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) {
                    if (v != null) _onProviderChanged(v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _label,
                  decoration: InputDecoration(
                    labelText: context.l10n.providerLabel,
                    hintText: context.l10n.providerLabelHint,
                  ),
                  validator: (String? v) => (v == null || v.trim().isEmpty)
                      ? context.l10n.requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _model,
                  decoration: InputDecoration(
                    labelText: context.l10n.model,
                    hintText: context.l10n.modelHint,
                  ),
                  enabled: !isMock,
                  validator: (String? v) =>
                      !isMock && (v == null || v.trim().isEmpty)
                      ? context.l10n.requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _baseUrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.baseUrl,
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
                    labelText: context.l10n.apiKey,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Text(
                      context.l10n.temperatureValue(
                        _temperature.toStringAsFixed(2),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                  decoration: InputDecoration(
                    labelText: context.l10n.maxTokens,
                  ),
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
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(context.l10n.save)),
      ],
    );
  }
}
