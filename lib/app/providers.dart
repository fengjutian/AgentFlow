/// Application-wide Riverpod wiring.
///
/// Composition root: constructs the database, repositories, the agent engine and
/// its collaborators, and exposes reactive providers the UI watches. Everything
/// is overridable, which is how tests inject an in-memory database and a mock
/// provider.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/agent/agent_engine.dart';
import '../core/approval/approval_manager.dart';
import '../core/memory/memory_manager.dart';
import '../core/model/model_provider.dart';
import '../core/model/provider_factory.dart';
import '../core/context/context_manager.dart';
import '../data/models.dart';
import '../runtime/bridge_runtime.dart';
import '../runtime/local_runtime.dart';
import '../runtime/runtime.dart';
import '../storage/database.dart';
import '../storage/repositories.dart';
import '../tools/default_tools.dart';
import '../tools/tool_registry.dart';

const Uuid _uuid = Uuid();

String newId() => _uuid.v4();

/// Offline demo config so the app is usable before any API key is entered.
const ModelConfig kDemoModelConfig = ModelConfig(
  id: 'demo',
  label: 'Demo (offline)',
  provider: 'mock',
  model: 'mock-agent',
  baseUrl: '',
  isDefault: true,
);

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final Provider<WorkspaceRepository> workspaceRepositoryProvider =
    Provider<WorkspaceRepository>(
        (Ref ref) => WorkspaceRepository(ref.watch(databaseProvider)));

final Provider<SessionRepository> sessionRepositoryProvider =
    Provider<SessionRepository>(
        (Ref ref) => SessionRepository(ref.watch(databaseProvider)));

final Provider<ProviderRepository> providerRepositoryProvider =
    Provider<ProviderRepository>(
        (Ref ref) => ProviderRepository(ref.watch(databaseProvider)));

final Provider<MemoryManager> memoryManagerProvider = Provider<MemoryManager>(
    (Ref ref) => MemoryManager(store: DriftMemoryStore(ref.watch(databaseProvider))));

final Provider<ApprovalManager> approvalManagerProvider =
    Provider<ApprovalManager>((Ref ref) {
  final manager = ApprovalManager();
  ref.onDispose(manager.dispose);
  return manager;
});

final Provider<ModelProviderFactory> modelProviderFactoryProvider =
    Provider<ModelProviderFactory>((Ref ref) {
  final factory = ModelProviderFactory();
  ref.onDispose(factory.dispose);
  return factory;
});

final Provider<ToolRegistry> toolRegistryProvider =
    Provider<ToolRegistry>((Ref ref) => defaultToolRegistry());

final Provider<AgentEngine> agentEngineProvider = Provider<AgentEngine>(
  (Ref ref) => AgentEngine(
    providerFactory: ref.watch(modelProviderFactoryProvider),
    approvalManager: ref.watch(approvalManagerProvider),
    defaultRegistry: ref.watch(toolRegistryProvider),
    contextManager: ContextManager(),
  ),
);

// ---------------------------------------------------------------------------
// Reactive data
// ---------------------------------------------------------------------------

final FutureProvider<List<Workspace>> workspaceListProvider =
    FutureProvider<List<Workspace>>(
        (Ref ref) => ref.watch(workspaceRepositoryProvider).all());

final sessionsProvider =
    FutureProvider.family<List<Session>, String>((Ref ref, String workspaceId) =>
        ref.watch(sessionRepositoryProvider).forWorkspace(workspaceId));

final FutureProvider<List<ModelConfig>> modelConfigsProvider =
    FutureProvider<List<ModelConfig>>(
        (Ref ref) => ref.watch(providerRepositoryProvider).all());

/// The config used for the next run: the stored default, else the offline demo.
final FutureProvider<ModelConfig> activeModelConfigProvider =
    FutureProvider<ModelConfig>((Ref ref) async {
  final configs = await ref.watch(modelConfigsProvider.future);
  if (configs.isEmpty) return kDemoModelConfig;
  return configs.firstWhere(
    (ModelConfig c) => c.isDefault,
    orElse: () => configs.first,
  );
});

// ---------------------------------------------------------------------------
// Selection
// ---------------------------------------------------------------------------

class ActiveWorkspaceNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final NotifierProvider<ActiveWorkspaceNotifier, String?> activeWorkspaceProvider =
    NotifierProvider<ActiveWorkspaceNotifier, String?>(
        ActiveWorkspaceNotifier.new);

class ActiveSessionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final NotifierProvider<ActiveSessionNotifier, String?> activeSessionProvider =
    NotifierProvider<ActiveSessionNotifier, String?>(ActiveSessionNotifier.new);

final Provider<Workspace?> currentWorkspaceProvider = Provider<Workspace?>((Ref ref) {
  final id = ref.watch(activeWorkspaceProvider);
  final list = ref.watch(workspaceListProvider).value;
  if (id == null || list == null) return null;
  for (final w in list) {
    if (w.id == id) return w;
  }
  return null;
});

// ---------------------------------------------------------------------------
// Runtime resolution
// ---------------------------------------------------------------------------

/// The [Runtime] for the currently selected workspace, resolved reactively.
///
/// Recomputes whenever the active workspace changes. `null` when no workspace is
/// selected. The Files and Terminal tabs watch this to browse and run commands.
final FutureProvider<Runtime?> runtimeProvider = FutureProvider<Runtime?>((Ref ref) async {
  final workspace = ref.watch(currentWorkspaceProvider);
  if (workspace == null) return null;
  return resolveRuntime(workspace);
});

/// Picks the best [Runtime] for a workspace: the Kotlin/Termux bridge on Android
/// when available, otherwise the local `dart:io` runtime. The Agent Core is
/// oblivious to which one it got.
Future<Runtime> resolveRuntime(Workspace workspace) async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final bridge = BridgeRuntime(rootDirectory: workspace.rootDirectory);
    if (await bridge.isAvailable()) return bridge;
  }
  return LocalRuntime(rootDirectory: workspace.rootDirectory);
}

/// Builds a registry reflecting a workspace's disabled-tool settings.
ToolRegistry registryForWorkspace(Workspace workspace, ToolRegistry base) {
  final registry = defaultToolRegistry();
  for (final name in workspace.disabledTools) {
    registry.setEnabled(name, false);
  }
  // `base` is currently only used for its enable/disable state; the tool set is
  // identical, so we mirror any tools disabled globally too.
  for (final name in base.names) {
    if (!base.isEnabled(name)) registry.setEnabled(name, false);
  }
  return registry;
}
