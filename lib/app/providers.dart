/// Application-wide Riverpod wiring.
///
/// Composition root: constructs the database, repositories, the agent engine and
/// its collaborators, and exposes reactive providers the UI watches. Everything
/// is overridable, which is how tests inject an in-memory database and a mock
/// provider.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/agent/agent_engine.dart';
import '../core/approval/approval_manager.dart';
import '../core/mcp/mcp_connection_manager.dart';
import '../core/memory/memory_manager.dart';
import '../core/model/model_provider.dart';
import '../core/model/provider_factory.dart';
import '../core/context/context_manager.dart';
import '../core/document/document_context_builder.dart';
import '../core/search/code_indexer.dart';
import '../core/search/semantic_search_service.dart';
import '../core/document/document_parser.dart';
import '../core/document/document_service.dart';
import '../core/document/epub_parser.dart';
import '../core/document/pdf_parser.dart';
import '../core/editor/agent_modifications.dart';
import '../core/editor/editor_workspace.dart';
import '../core/lsp/lsp_client.dart';
import '../core/lsp/lsp_client_manager.dart';
import '../data/models.dart';
import '../runtime/bridge_runtime.dart';
import '../runtime/local_runtime.dart';
import '../runtime/runtime.dart';
import '../runtime/ssh/ssh_host_key_store.dart';
import '../runtime/ssh/ssh_runtime.dart';
import '../storage/database.dart';
import '../storage/document_repository.dart';
import '../storage/mcp_server_repository.dart';
import '../storage/repositories.dart';
import '../storage/secret_store.dart';
import '../tools/default_tools.dart';
import '../tools/document/document_tools.dart';
import '../tools/tool_registry.dart';

const Uuid _uuid = Uuid();

String newId() => _uuid.v4();

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
      (Ref ref) => WorkspaceRepository(ref.watch(databaseProvider)),
    );

final Provider<SessionRepository> sessionRepositoryProvider =
    Provider<SessionRepository>(
      (Ref ref) => SessionRepository(ref.watch(databaseProvider)),
    );

final Provider<RuntimeConfigRepository> runtimeConfigRepositoryProvider =
    Provider<RuntimeConfigRepository>(
      (Ref ref) => RuntimeConfigRepository(ref.watch(databaseProvider)),
    );

final Provider<DocumentStore> documentStoreProvider = Provider<DocumentStore>(
  (Ref ref) => DriftDocumentStore(ref.watch(databaseProvider)),
);

final Provider<DocumentParserRegistry> documentParserRegistryProvider =
    Provider<DocumentParserRegistry>(
  (Ref ref) => DocumentParserRegistry(
    parsers: <DocumentParser>[
      PdfDocumentParser(),
      EpubDocumentParser(),
    ],
  ),
);

final Provider<DocumentContextBuilder> documentContextBuilderProvider =
    Provider<DocumentContextBuilder>(
  (Ref ref) => DocumentContextBuilder(
    store: ref.watch(documentStoreProvider),
  ),
);

final FutureProvider<DocumentImportService> documentImportServiceProvider =
    FutureProvider<DocumentImportService>(
  (Ref ref) async {
    final appDir = await getApplicationDocumentsDirectory();
    return DocumentImportService(
      store: ref.watch(documentStoreProvider),
      parsers: ref.watch(documentParserRegistryProvider),
      documentsDirectory: '${appDir.path}/agentflow_documents',
      idGenerator: newId,
    );
  },
);

final Provider<SecretStore> secretStoreProvider = Provider<SecretStore>(
  (Ref ref) => PlatformSecretStore(),
);

final Provider<SshHostKeyStore> sshHostKeyStoreProvider =
    Provider<SshHostKeyStore>(
  (Ref ref) => SshHostKeyStore(ref.watch(secretStoreProvider)),
);

final Provider<McpServerRepository> mcpServerRepositoryProvider =
    Provider<McpServerRepository>(
  (Ref ref) => McpServerRepository(
    ref.watch(databaseProvider),
    ref.watch(secretStoreProvider),
  ),
);

final Provider<McpConnectionManager> mcpConnectionManagerProvider =
    Provider<McpConnectionManager>((Ref ref) {
  final manager = McpConnectionManager(
    repository: ref.watch(mcpServerRepositoryProvider),
    registry: ref.watch(toolRegistryProvider),
  );
  ref.onDispose(manager.disconnectAll);
  return manager;
});

final Provider<ProviderRepository> providerRepositoryProvider =
    Provider<ProviderRepository>(
      (Ref ref) => ProviderRepository(
        ref.watch(databaseProvider),
        ref.watch(secretStoreProvider),
      ),
    );

final Provider<MemoryManager> memoryManagerProvider = Provider<MemoryManager>(
  (Ref ref) =>
      MemoryManager(store: DriftMemoryStore(ref.watch(databaseProvider))),
);

/// Shared diagnostic sink for analyzers, test runners and future LSP clients.
/// The editor watches this provider and turns every item into a navigable row.
class EditorDiagnosticsNotifier extends Notifier<List<EditorDiagnostic>> {
  @override
  List<EditorDiagnostic> build() => const <EditorDiagnostic>[];

  void replace(List<EditorDiagnostic> diagnostics) {
    state = List<EditorDiagnostic>.unmodifiable(diagnostics);
  }

  void clear() => state = const <EditorDiagnostic>[];

  /// Merges LSP diagnostics for a specific file URI.
  ///
  /// Removes any previous LSP diagnostics from the same URI, then appends
  /// the new ones. Non-LSP diagnostics (from terminal parsers) are preserved.
  void addLspDiagnostics(String uri, List<EditorDiagnostic> diagnostics) {
    final path = _uriToPath(uri);
    // Remove old LSP diagnostics for this file.
    final remaining = state
        .where((d) => !(d.source == 'LSP' && d.location.path == path))
        .toList();
    remaining.addAll(diagnostics);
    state = List<EditorDiagnostic>.unmodifiable(remaining);
  }

  /// Removes all LSP diagnostics for a specific file URI.
  void removeLspDiagnostics(String uri) {
    final path = _uriToPath(uri);
    state = List<EditorDiagnostic>.unmodifiable(
      state.where((d) => !(d.source == 'LSP' && d.location.path == path)),
    );
  }
}

final NotifierProvider<EditorDiagnosticsNotifier, List<EditorDiagnostic>>
editorDiagnosticsProvider =
    NotifierProvider<EditorDiagnosticsNotifier, List<EditorDiagnostic>>(
      EditorDiagnosticsNotifier.new,
    );

/// Tracks line ranges modified by the agent for gutter markers (DIFF-01/02).
final Provider<AgentModificationStore> agentModificationProvider =
    Provider<AgentModificationStore>((Ref ref) {
  final store = AgentModificationStore();
  ref.onDispose(store.dispose);
  return store;
});

/// Background code indexer for BM25 semantic search.
final Provider<CodeIndexer> codeIndexerProvider = Provider<CodeIndexer>(
  (Ref ref) => CodeIndexer(db: ref.watch(databaseProvider)),
);

/// Unified semantic search service (BM25 over FTS5).
final Provider<SemanticSearchService> semanticSearchServiceProvider =
    Provider<SemanticSearchService>(
  (Ref ref) => SemanticSearchService(db: ref.watch(databaseProvider)),
);

/// LSP client manager — one server per language per workspace.
///
/// The manager is created once and configured with the active workspace's
/// runtime via [initializeLspForWorkspace]. Diagnostics from all connected
/// language servers are forwarded to [editorDiagnosticsProvider].
final Provider<LspClientManager> lspClientManagerProvider =
    Provider<LspClientManager>((Ref ref) {
  final manager = LspClientManager();
  ref.onDispose(manager.shutdownAll);

  // Wire LSP diagnostics into the editor diagnostic provider.
  manager.diagnostics.listen((LspDiagnosticsEvent event) {
    final editorDiags = event.diagnostics
        .map((LspDiagnostic d) => EditorDiagnostic(
              message: d.message,
              location: EditorLocation(
                path: _uriToPath(event.uri),
                line: d.range.start.line + 1, // LSP 0-based -> editor 1-based
                column: d.range.start.character + 1,
              ),
              severity: switch (d.severity) {
                LspDiagnosticSeverity.warning => DiagnosticSeverity.warning,
                LspDiagnosticSeverity.information ||
                LspDiagnosticSeverity.hint =>
                  DiagnosticSeverity.information,
                _ => DiagnosticSeverity.error,
              },
              source: d.source ?? 'LSP',
            ))
        .toList();

    // Merge with existing diagnostics (from terminal parsers, etc.)
    ref.read(editorDiagnosticsProvider.notifier).addLspDiagnostics(
          event.uri,
          editorDiags,
        );
  });

  return manager;
});

/// Converts a file:// URI to a path string.
String _uriToPath(String uri) {
  try {
    return Uri.parse(uri).toFilePath();
  } catch (_) {
    return uri;
  }
}

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

final Provider<ToolRegistry> toolRegistryProvider = Provider<ToolRegistry>((
  Ref ref,
) {
  final registry = defaultToolRegistry(
    memoryManager: ref.watch(memoryManagerProvider),
    database: ref.watch(databaseProvider),
  );
  registry.registerAll(documentTools(ref.watch(documentStoreProvider)));
  return registry;
});

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
      (Ref ref) => ref.watch(workspaceRepositoryProvider).all(),
    );

final sessionsProvider = FutureProvider.family<List<Session>, String>(
  (Ref ref, String workspaceId) =>
      ref.watch(sessionRepositoryProvider).forWorkspace(workspaceId),
);

final FutureProvider<List<RuntimeConfig>> runtimeConfigsProvider =
    FutureProvider<List<RuntimeConfig>>(
      (Ref ref) => ref.watch(runtimeConfigRepositoryProvider).all(),
    );

final FutureProvider<List<ModelConfig>> modelConfigsProvider =
    FutureProvider<List<ModelConfig>>(
      (Ref ref) => ref.watch(providerRepositoryProvider).all(),
    );

/// The config used for the next run: the stored default, or null if none configured.
///
/// When null, the chat layer blocks sending and directs the user to Settings.
final FutureProvider<ModelConfig?> activeModelConfigProvider =
    FutureProvider<ModelConfig?>((Ref ref) async {
      final configs = await ref.watch(modelConfigsProvider.future);
      if (configs.isEmpty) return null;
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

final NotifierProvider<ActiveWorkspaceNotifier, String?>
activeWorkspaceProvider = NotifierProvider<ActiveWorkspaceNotifier, String?>(
  ActiveWorkspaceNotifier.new,
);

class ActiveSessionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final NotifierProvider<ActiveSessionNotifier, String?> activeSessionProvider =
    NotifierProvider<ActiveSessionNotifier, String?>(ActiveSessionNotifier.new);

final Provider<Workspace?> currentWorkspaceProvider = Provider<Workspace?>((
  Ref ref,
) {
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
final FutureProvider<Runtime?> runtimeProvider = FutureProvider<Runtime?>((
  Ref ref,
) async {
  final workspace = ref.watch(currentWorkspaceProvider);
  if (workspace == null) return null;
  return resolveRuntime(workspace);
});

/// Picks the best [Runtime] for a workspace: the Kotlin/Termux bridge on Android
/// when available, otherwise the local `dart:io` runtime. The Agent Core is
/// oblivious to which one it got.
Future<Runtime> resolveRuntime(Workspace workspace) async {
  // Check if workspace is bound to a specific runtime config.
  if (workspace.runtimeId.isNotEmpty &&
      workspace.runtimeId != 'local' &&
      workspace.runtimeId != 'termux') {
    // Look up the runtime config.
    final config = await _runtimeConfigRepo?.byId(workspace.runtimeId);
    if (config != null && config.kind == 'ssh') {
      return _createSshRuntime(config);
    }
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final bridge = BridgeRuntime(rootDirectory: workspace.rootDirectory);
    if (await bridge.isAvailable()) return bridge;
  }
  return LocalRuntime(rootDirectory: workspace.rootDirectory);
}

RuntimeConfigRepository? _runtimeConfigRepo;
SecretStore? _secretStore;

/// Initializes the runtime resolver with required dependencies.
void initializeRuntimeResolver({
  required RuntimeConfigRepository runtimeConfigRepo,
  required SecretStore secretStore,
}) {
  _runtimeConfigRepo = runtimeConfigRepo;
  _secretStore = secretStore;
}

/// Creates an SSH runtime from a runtime config, reading secrets from SecretStore.
Future<SshRuntime> _createSshRuntime(RuntimeConfig config) async {
  final options = config.options;
  final host = options['host'] as String? ?? '';
  final port = options['port'] as int? ?? 22;
  final username = options['username'] as String? ?? '';
  final remoteRoot = options['remoteRoot'] as String? ?? '~';

  final secrets = _secretStore!;
  final password = await secrets.read('ssh/${config.id}/password');
  final privateKey = await secrets.read('ssh/${config.id}/private-key');
  final passphrase = await secrets.read('ssh/${config.id}/passphrase');

  return SshRuntime(
    config: SshConfig(
      id: config.id,
      host: host,
      port: port,
      username: username,
      password: password,
      privateKey: privateKey,
      passphrase: passphrase,
      remoteRoot: remoteRoot,
      label: config.label,
    ),
    hostKeyStore: SshHostKeyStore(secrets),
  );
}

/// Builds a registry reflecting a workspace's disabled-tool settings.
ToolRegistry registryForWorkspace(Workspace workspace, ToolRegistry base) {
  final registry = base.copy();
  for (final name in workspace.disabledTools) {
    registry.setEnabled(name, false);
  }
  return registry;
}
