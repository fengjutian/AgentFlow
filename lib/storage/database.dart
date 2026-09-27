/// SQLite persistence via Drift (design doc §26).
///
/// Tables mirror the core entities: workspace → session → message, plus provider
/// configs, approvals/artifacts metadata and long-term memory. Generated row
/// classes are suffixed `Row` so they never collide with the domain models or
/// core types (`ModelConfig`, `MemoryEntry`) that the rest of the app uses.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@DataClassName('WorkspaceRow')
class Workspaces extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get rootDirectory => text()();

  /// Which [Runtime] this workspace uses: `local`, `termux`, ...
  TextColumn get runtimeId => text().withDefault(const Constant('local'))();
  DateTimeColumn get createdAt => dateTime()();

  /// Per-workspace JSON settings (enabled tools, approval policy, ...).
  TextColumn get settingsJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

@DataClassName('SessionRow')
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withDefault(const Constant('New session'))();
  TextColumn get status => text().withDefault(const Constant('idle'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

@DataClassName('MessageRow')
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();

  /// Ordering within a session.
  IntColumn get seq => integer()();
  TextColumn get role => text()();
  TextColumn get content => text().withDefault(const Constant(''))();

  /// JSON-encoded `List<ToolCall>` for assistant messages.
  TextColumn get toolCallsJson => text().nullable()();
  TextColumn get toolCallId => text().nullable()();
  TextColumn get name => text().nullable()();
  BoolColumn get isError => boolean().withDefault(const Constant(false))();

  /// JSON-encoded structured tool payload (diffs, exit codes, file lists).
  TextColumn get dataJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('ProviderRow')
class ProviderConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get provider => text()();
  TextColumn get model => text()();
  TextColumn get baseUrl => text()();
  TextColumn get apiKey => text().withDefault(const Constant(''))();
  RealColumn get temperature => real().withDefault(const Constant(0.2))();
  IntColumn get maxTokens => integer().withDefault(const Constant(4096))();
  IntColumn get contextWindow =>
      integer().withDefault(const Constant(128000))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

@DataClassName('MemoryRow')
class MemoryNotes extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text()();
  TextColumn get content => text()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

@DataClassName('RuntimeConfigRow')
class RuntimeConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get kind => text()();
  TextColumn get optionsJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

@DataClassName('DocumentRow')
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get displayName => text()();
  TextColumn get sourceUri => text()();
  TextColumn get localPath => text()();
  TextColumn get type => text()();
  TextColumn get mimeType => text().withDefault(const Constant(''))();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  TextColumn get contentHash => text().withDefault(const Constant(''))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get author => text().withDefault(const Constant(''))();
  TextColumn get language => text().withDefault(const Constant(''))();
  IntColumn get pageCount => integer().withDefault(const Constant(0))();
  IntColumn get sectionCount => integer().withDefault(const Constant(0))();
  TextColumn get parseStatus => text().withDefault(const Constant('pending'))();
  TextColumn get parseError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

@DataClassName('DocumentSectionRow')
class DocumentSections extends Table {
  TextColumn get id => text()();
  TextColumn get documentId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();
  IntColumn get sectionIndex => integer()();
  TextColumn get parentSectionId => text().nullable()();
  TextColumn get kind => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get locator => text()();
  TextColumn get plainText => text().withDefault(const Constant(''))();
  IntColumn get charCount => integer().withDefault(const Constant(0))();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => <Column>{id};

  @override
  List<Set<Column>> get uniqueKeys => <Set<Column>>[
    <Column>{documentId, sectionIndex},
  ];
}

@DataClassName('McpServerRow')
class McpServers extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get transport => text()();
  TextColumn get endpoint => text().withDefault(const Constant(''))();
  TextColumn get command => text().withDefault(const Constant(''))();
  TextColumn get argumentsJson => text().withDefault(const Constant('[]'))();
  TextColumn get environmentJson => text().withDefault(const Constant('{}'))();
  TextColumn get headersJson => text().withDefault(const Constant('{}'))();
  TextColumn get runtimeConfigId => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  BoolColumn get autoConnect => boolean().withDefault(const Constant(true))();
  IntColumn get connectionTimeoutMs =>
      integer().withDefault(const Constant(10000))();
  IntColumn get toolTimeoutMs => integer().withDefault(const Constant(60000))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

@DriftDatabase(
  tables: <Type>[
    Workspaces,
    Sessions,
    Messages,
    ProviderConfigs,
    MemoryNotes,
    RuntimeConfigs,
    Documents,
    DocumentSections,
    McpServers,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens (and creates if needed) the on-device database.
  AppDatabase() : super(driftDatabase(name: 'agentflow'));

  /// Wrap any [QueryExecutor] — used by tests with `NativeDatabase.memory()`.
  AppDatabase.connect(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createFtsTable();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(runtimeConfigs);
        await m.createTable(documents);
        await m.createTable(documentSections);
        await m.createTable(mcpServers);
      }
      if (from < 3) {
        await _createFtsTable();
      }
    },
  );

  Future<void> _createFtsTable() async {
    await customStatement(
      'CREATE VIRTUAL TABLE IF NOT EXISTS document_sections_fts '
      'USING fts5(plain_text, content=document_sections, content_rowid=rowid)',
    );
  }
}
