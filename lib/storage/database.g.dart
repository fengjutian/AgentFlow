// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WorkspacesTable extends Workspaces
    with TableInfo<$WorkspacesTable, WorkspaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rootDirectoryMeta = const VerificationMeta(
    'rootDirectory',
  );
  @override
  late final GeneratedColumn<String> rootDirectory = GeneratedColumn<String>(
    'root_directory',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runtimeIdMeta = const VerificationMeta(
    'runtimeId',
  );
  @override
  late final GeneratedColumn<String> runtimeId = GeneratedColumn<String>(
    'runtime_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingsJsonMeta = const VerificationMeta(
    'settingsJson',
  );
  @override
  late final GeneratedColumn<String> settingsJson = GeneratedColumn<String>(
    'settings_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    rootDirectory,
    runtimeId,
    createdAt,
    settingsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('root_directory')) {
      context.handle(
        _rootDirectoryMeta,
        rootDirectory.isAcceptableOrUnknown(
          data['root_directory']!,
          _rootDirectoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rootDirectoryMeta);
    }
    if (data.containsKey('runtime_id')) {
      context.handle(
        _runtimeIdMeta,
        runtimeId.isAcceptableOrUnknown(data['runtime_id']!, _runtimeIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('settings_json')) {
      context.handle(
        _settingsJsonMeta,
        settingsJson.isAcceptableOrUnknown(
          data['settings_json']!,
          _settingsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkspaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      rootDirectory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_directory'],
      )!,
      runtimeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}runtime_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      settingsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings_json'],
      )!,
    );
  }

  @override
  $WorkspacesTable createAlias(String alias) {
    return $WorkspacesTable(attachedDatabase, alias);
  }
}

class WorkspaceRow extends DataClass implements Insertable<WorkspaceRow> {
  final String id;
  final String name;
  final String rootDirectory;

  /// Which [Runtime] this workspace uses: `local`, `termux`, ...
  final String runtimeId;
  final DateTime createdAt;

  /// Per-workspace JSON settings (enabled tools, approval policy, ...).
  final String settingsJson;
  const WorkspaceRow({
    required this.id,
    required this.name,
    required this.rootDirectory,
    required this.runtimeId,
    required this.createdAt,
    required this.settingsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['root_directory'] = Variable<String>(rootDirectory);
    map['runtime_id'] = Variable<String>(runtimeId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['settings_json'] = Variable<String>(settingsJson);
    return map;
  }

  WorkspacesCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesCompanion(
      id: Value(id),
      name: Value(name),
      rootDirectory: Value(rootDirectory),
      runtimeId: Value(runtimeId),
      createdAt: Value(createdAt),
      settingsJson: Value(settingsJson),
    );
  }

  factory WorkspaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      rootDirectory: serializer.fromJson<String>(json['rootDirectory']),
      runtimeId: serializer.fromJson<String>(json['runtimeId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      settingsJson: serializer.fromJson<String>(json['settingsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'rootDirectory': serializer.toJson<String>(rootDirectory),
      'runtimeId': serializer.toJson<String>(runtimeId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'settingsJson': serializer.toJson<String>(settingsJson),
    };
  }

  WorkspaceRow copyWith({
    String? id,
    String? name,
    String? rootDirectory,
    String? runtimeId,
    DateTime? createdAt,
    String? settingsJson,
  }) => WorkspaceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    rootDirectory: rootDirectory ?? this.rootDirectory,
    runtimeId: runtimeId ?? this.runtimeId,
    createdAt: createdAt ?? this.createdAt,
    settingsJson: settingsJson ?? this.settingsJson,
  );
  WorkspaceRow copyWithCompanion(WorkspacesCompanion data) {
    return WorkspaceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      rootDirectory: data.rootDirectory.present
          ? data.rootDirectory.value
          : this.rootDirectory,
      runtimeId: data.runtimeId.present ? data.runtimeId.value : this.runtimeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      settingsJson: data.settingsJson.present
          ? data.settingsJson.value
          : this.settingsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rootDirectory: $rootDirectory, ')
          ..write('runtimeId: $runtimeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('settingsJson: $settingsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, rootDirectory, runtimeId, createdAt, settingsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.rootDirectory == this.rootDirectory &&
          other.runtimeId == this.runtimeId &&
          other.createdAt == this.createdAt &&
          other.settingsJson == this.settingsJson);
}

class WorkspacesCompanion extends UpdateCompanion<WorkspaceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> rootDirectory;
  final Value<String> runtimeId;
  final Value<DateTime> createdAt;
  final Value<String> settingsJson;
  final Value<int> rowid;
  const WorkspacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rootDirectory = const Value.absent(),
    this.runtimeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.settingsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesCompanion.insert({
    required String id,
    required String name,
    required String rootDirectory,
    this.runtimeId = const Value.absent(),
    required DateTime createdAt,
    this.settingsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       rootDirectory = Value(rootDirectory),
       createdAt = Value(createdAt);
  static Insertable<WorkspaceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? rootDirectory,
    Expression<String>? runtimeId,
    Expression<DateTime>? createdAt,
    Expression<String>? settingsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rootDirectory != null) 'root_directory': rootDirectory,
      if (runtimeId != null) 'runtime_id': runtimeId,
      if (createdAt != null) 'created_at': createdAt,
      if (settingsJson != null) 'settings_json': settingsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? rootDirectory,
    Value<String>? runtimeId,
    Value<DateTime>? createdAt,
    Value<String>? settingsJson,
    Value<int>? rowid,
  }) {
    return WorkspacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rootDirectory: rootDirectory ?? this.rootDirectory,
      runtimeId: runtimeId ?? this.runtimeId,
      createdAt: createdAt ?? this.createdAt,
      settingsJson: settingsJson ?? this.settingsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rootDirectory.present) {
      map['root_directory'] = Variable<String>(rootDirectory.value);
    }
    if (runtimeId.present) {
      map['runtime_id'] = Variable<String>(runtimeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (settingsJson.present) {
      map['settings_json'] = Variable<String>(settingsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rootDirectory: $rootDirectory, ')
          ..write('runtimeId: $runtimeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('New session'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('idle'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    title,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final String id;
  final String workspaceId;
  final String title;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SessionRow({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['title'] = Variable<String>(title);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      title: Value(title),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      title: serializer.fromJson<String>(json['title']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SessionRow copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SessionRow(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    title: title ?? this.title,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, workspaceId, title, status, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.title == this.title &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> title;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String workspaceId,
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SessionRow> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? title,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? title,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, MessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _toolCallsJsonMeta = const VerificationMeta(
    'toolCallsJson',
  );
  @override
  late final GeneratedColumn<String> toolCallsJson = GeneratedColumn<String>(
    'tool_calls_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toolCallIdMeta = const VerificationMeta(
    'toolCallId',
  );
  @override
  late final GeneratedColumn<String> toolCallId = GeneratedColumn<String>(
    'tool_call_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isErrorMeta = const VerificationMeta(
    'isError',
  );
  @override
  late final GeneratedColumn<bool> isError = GeneratedColumn<bool>(
    'is_error',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_error" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    seq,
    role,
    content,
    toolCallsJson,
    toolCallId,
    name,
    isError,
    dataJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('tool_calls_json')) {
      context.handle(
        _toolCallsJsonMeta,
        toolCallsJson.isAcceptableOrUnknown(
          data['tool_calls_json']!,
          _toolCallsJsonMeta,
        ),
      );
    }
    if (data.containsKey('tool_call_id')) {
      context.handle(
        _toolCallIdMeta,
        toolCallId.isAcceptableOrUnknown(
          data['tool_call_id']!,
          _toolCallIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('is_error')) {
      context.handle(
        _isErrorMeta,
        isError.isAcceptableOrUnknown(data['is_error']!, _isErrorMeta),
      );
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      toolCallsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_calls_json'],
      ),
      toolCallId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_call_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      isError: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_error'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class MessageRow extends DataClass implements Insertable<MessageRow> {
  final int id;
  final String sessionId;

  /// Ordering within a session.
  final int seq;
  final String role;
  final String content;

  /// JSON-encoded `List<ToolCall>` for assistant messages.
  final String? toolCallsJson;
  final String? toolCallId;
  final String? name;
  final bool isError;

  /// JSON-encoded structured tool payload (diffs, exit codes, file lists).
  final String? dataJson;
  final DateTime createdAt;
  const MessageRow({
    required this.id,
    required this.sessionId,
    required this.seq,
    required this.role,
    required this.content,
    this.toolCallsJson,
    this.toolCallId,
    this.name,
    required this.isError,
    this.dataJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['seq'] = Variable<int>(seq);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || toolCallsJson != null) {
      map['tool_calls_json'] = Variable<String>(toolCallsJson);
    }
    if (!nullToAbsent || toolCallId != null) {
      map['tool_call_id'] = Variable<String>(toolCallId);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['is_error'] = Variable<bool>(isError);
    if (!nullToAbsent || dataJson != null) {
      map['data_json'] = Variable<String>(dataJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      seq: Value(seq),
      role: Value(role),
      content: Value(content),
      toolCallsJson: toolCallsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(toolCallsJson),
      toolCallId: toolCallId == null && nullToAbsent
          ? const Value.absent()
          : Value(toolCallId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      isError: Value(isError),
      dataJson: dataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(dataJson),
      createdAt: Value(createdAt),
    );
  }

  factory MessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      seq: serializer.fromJson<int>(json['seq']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      toolCallsJson: serializer.fromJson<String?>(json['toolCallsJson']),
      toolCallId: serializer.fromJson<String?>(json['toolCallId']),
      name: serializer.fromJson<String?>(json['name']),
      isError: serializer.fromJson<bool>(json['isError']),
      dataJson: serializer.fromJson<String?>(json['dataJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'seq': serializer.toJson<int>(seq),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'toolCallsJson': serializer.toJson<String?>(toolCallsJson),
      'toolCallId': serializer.toJson<String?>(toolCallId),
      'name': serializer.toJson<String?>(name),
      'isError': serializer.toJson<bool>(isError),
      'dataJson': serializer.toJson<String?>(dataJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MessageRow copyWith({
    int? id,
    String? sessionId,
    int? seq,
    String? role,
    String? content,
    Value<String?> toolCallsJson = const Value.absent(),
    Value<String?> toolCallId = const Value.absent(),
    Value<String?> name = const Value.absent(),
    bool? isError,
    Value<String?> dataJson = const Value.absent(),
    DateTime? createdAt,
  }) => MessageRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    seq: seq ?? this.seq,
    role: role ?? this.role,
    content: content ?? this.content,
    toolCallsJson: toolCallsJson.present
        ? toolCallsJson.value
        : this.toolCallsJson,
    toolCallId: toolCallId.present ? toolCallId.value : this.toolCallId,
    name: name.present ? name.value : this.name,
    isError: isError ?? this.isError,
    dataJson: dataJson.present ? dataJson.value : this.dataJson,
    createdAt: createdAt ?? this.createdAt,
  );
  MessageRow copyWithCompanion(MessagesCompanion data) {
    return MessageRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      seq: data.seq.present ? data.seq.value : this.seq,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      toolCallsJson: data.toolCallsJson.present
          ? data.toolCallsJson.value
          : this.toolCallsJson,
      toolCallId: data.toolCallId.present
          ? data.toolCallId.value
          : this.toolCallId,
      name: data.name.present ? data.name.value : this.name,
      isError: data.isError.present ? data.isError.value : this.isError,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('toolCallsJson: $toolCallsJson, ')
          ..write('toolCallId: $toolCallId, ')
          ..write('name: $name, ')
          ..write('isError: $isError, ')
          ..write('dataJson: $dataJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    seq,
    role,
    content,
    toolCallsJson,
    toolCallId,
    name,
    isError,
    dataJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.seq == this.seq &&
          other.role == this.role &&
          other.content == this.content &&
          other.toolCallsJson == this.toolCallsJson &&
          other.toolCallId == this.toolCallId &&
          other.name == this.name &&
          other.isError == this.isError &&
          other.dataJson == this.dataJson &&
          other.createdAt == this.createdAt);
}

class MessagesCompanion extends UpdateCompanion<MessageRow> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<int> seq;
  final Value<String> role;
  final Value<String> content;
  final Value<String?> toolCallsJson;
  final Value<String?> toolCallId;
  final Value<String?> name;
  final Value<bool> isError;
  final Value<String?> dataJson;
  final Value<DateTime> createdAt;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.seq = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.toolCallsJson = const Value.absent(),
    this.toolCallId = const Value.absent(),
    this.name = const Value.absent(),
    this.isError = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required int seq,
    required String role,
    this.content = const Value.absent(),
    this.toolCallsJson = const Value.absent(),
    this.toolCallId = const Value.absent(),
    this.name = const Value.absent(),
    this.isError = const Value.absent(),
    this.dataJson = const Value.absent(),
    required DateTime createdAt,
  }) : sessionId = Value(sessionId),
       seq = Value(seq),
       role = Value(role),
       createdAt = Value(createdAt);
  static Insertable<MessageRow> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<int>? seq,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? toolCallsJson,
    Expression<String>? toolCallId,
    Expression<String>? name,
    Expression<bool>? isError,
    Expression<String>? dataJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (seq != null) 'seq': seq,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (toolCallsJson != null) 'tool_calls_json': toolCallsJson,
      if (toolCallId != null) 'tool_call_id': toolCallId,
      if (name != null) 'name': name,
      if (isError != null) 'is_error': isError,
      if (dataJson != null) 'data_json': dataJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MessagesCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<int>? seq,
    Value<String>? role,
    Value<String>? content,
    Value<String?>? toolCallsJson,
    Value<String?>? toolCallId,
    Value<String?>? name,
    Value<bool>? isError,
    Value<String?>? dataJson,
    Value<DateTime>? createdAt,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      seq: seq ?? this.seq,
      role: role ?? this.role,
      content: content ?? this.content,
      toolCallsJson: toolCallsJson ?? this.toolCallsJson,
      toolCallId: toolCallId ?? this.toolCallId,
      name: name ?? this.name,
      isError: isError ?? this.isError,
      dataJson: dataJson ?? this.dataJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (toolCallsJson.present) {
      map['tool_calls_json'] = Variable<String>(toolCallsJson.value);
    }
    if (toolCallId.present) {
      map['tool_call_id'] = Variable<String>(toolCallId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isError.present) {
      map['is_error'] = Variable<bool>(isError.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('toolCallsJson: $toolCallsJson, ')
          ..write('toolCallId: $toolCallId, ')
          ..write('name: $name, ')
          ..write('isError: $isError, ')
          ..write('dataJson: $dataJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProviderConfigsTable extends ProviderConfigs
    with TableInfo<$ProviderConfigsTable, ProviderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
    'api_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.2),
  );
  static const VerificationMeta _maxTokensMeta = const VerificationMeta(
    'maxTokens',
  );
  @override
  late final GeneratedColumn<int> maxTokens = GeneratedColumn<int>(
    'max_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4096),
  );
  static const VerificationMeta _contextWindowMeta = const VerificationMeta(
    'contextWindow',
  );
  @override
  late final GeneratedColumn<int> contextWindow = GeneratedColumn<int>(
    'context_window',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(128000),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    provider,
    model,
    baseUrl,
    apiKey,
    temperature,
    maxTokens,
    contextWindow,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('api_key')) {
      context.handle(
        _apiKeyMeta,
        apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta),
      );
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    }
    if (data.containsKey('max_tokens')) {
      context.handle(
        _maxTokensMeta,
        maxTokens.isAcceptableOrUnknown(data['max_tokens']!, _maxTokensMeta),
      );
    }
    if (data.containsKey('context_window')) {
      context.handle(
        _contextWindowMeta,
        contextWindow.isAcceptableOrUnknown(
          data['context_window']!,
          _contextWindowMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      apiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_key'],
      )!,
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      )!,
      maxTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_tokens'],
      )!,
      contextWindow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}context_window'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $ProviderConfigsTable createAlias(String alias) {
    return $ProviderConfigsTable(attachedDatabase, alias);
  }
}

class ProviderRow extends DataClass implements Insertable<ProviderRow> {
  final String id;
  final String label;
  final String provider;
  final String model;
  final String baseUrl;
  final String apiKey;
  final double temperature;
  final int maxTokens;
  final int contextWindow;
  final bool isDefault;
  const ProviderRow({
    required this.id,
    required this.label,
    required this.provider,
    required this.model,
    required this.baseUrl,
    required this.apiKey,
    required this.temperature,
    required this.maxTokens,
    required this.contextWindow,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['provider'] = Variable<String>(provider);
    map['model'] = Variable<String>(model);
    map['base_url'] = Variable<String>(baseUrl);
    map['api_key'] = Variable<String>(apiKey);
    map['temperature'] = Variable<double>(temperature);
    map['max_tokens'] = Variable<int>(maxTokens);
    map['context_window'] = Variable<int>(contextWindow);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  ProviderConfigsCompanion toCompanion(bool nullToAbsent) {
    return ProviderConfigsCompanion(
      id: Value(id),
      label: Value(label),
      provider: Value(provider),
      model: Value(model),
      baseUrl: Value(baseUrl),
      apiKey: Value(apiKey),
      temperature: Value(temperature),
      maxTokens: Value(maxTokens),
      contextWindow: Value(contextWindow),
      isDefault: Value(isDefault),
    );
  }

  factory ProviderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderRow(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      provider: serializer.fromJson<String>(json['provider']),
      model: serializer.fromJson<String>(json['model']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      apiKey: serializer.fromJson<String>(json['apiKey']),
      temperature: serializer.fromJson<double>(json['temperature']),
      maxTokens: serializer.fromJson<int>(json['maxTokens']),
      contextWindow: serializer.fromJson<int>(json['contextWindow']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'provider': serializer.toJson<String>(provider),
      'model': serializer.toJson<String>(model),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'apiKey': serializer.toJson<String>(apiKey),
      'temperature': serializer.toJson<double>(temperature),
      'maxTokens': serializer.toJson<int>(maxTokens),
      'contextWindow': serializer.toJson<int>(contextWindow),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  ProviderRow copyWith({
    String? id,
    String? label,
    String? provider,
    String? model,
    String? baseUrl,
    String? apiKey,
    double? temperature,
    int? maxTokens,
    int? contextWindow,
    bool? isDefault,
  }) => ProviderRow(
    id: id ?? this.id,
    label: label ?? this.label,
    provider: provider ?? this.provider,
    model: model ?? this.model,
    baseUrl: baseUrl ?? this.baseUrl,
    apiKey: apiKey ?? this.apiKey,
    temperature: temperature ?? this.temperature,
    maxTokens: maxTokens ?? this.maxTokens,
    contextWindow: contextWindow ?? this.contextWindow,
    isDefault: isDefault ?? this.isDefault,
  );
  ProviderRow copyWithCompanion(ProviderConfigsCompanion data) {
    return ProviderRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      provider: data.provider.present ? data.provider.value : this.provider,
      model: data.model.present ? data.model.value : this.model,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      maxTokens: data.maxTokens.present ? data.maxTokens.value : this.maxTokens,
      contextWindow: data.contextWindow.present
          ? data.contextWindow.value
          : this.contextWindow,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('provider: $provider, ')
          ..write('model: $model, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('apiKey: $apiKey, ')
          ..write('temperature: $temperature, ')
          ..write('maxTokens: $maxTokens, ')
          ..write('contextWindow: $contextWindow, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    provider,
    model,
    baseUrl,
    apiKey,
    temperature,
    maxTokens,
    contextWindow,
    isDefault,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.provider == this.provider &&
          other.model == this.model &&
          other.baseUrl == this.baseUrl &&
          other.apiKey == this.apiKey &&
          other.temperature == this.temperature &&
          other.maxTokens == this.maxTokens &&
          other.contextWindow == this.contextWindow &&
          other.isDefault == this.isDefault);
}

class ProviderConfigsCompanion extends UpdateCompanion<ProviderRow> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> provider;
  final Value<String> model;
  final Value<String> baseUrl;
  final Value<String> apiKey;
  final Value<double> temperature;
  final Value<int> maxTokens;
  final Value<int> contextWindow;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const ProviderConfigsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.provider = const Value.absent(),
    this.model = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.temperature = const Value.absent(),
    this.maxTokens = const Value.absent(),
    this.contextWindow = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderConfigsCompanion.insert({
    required String id,
    required String label,
    required String provider,
    required String model,
    required String baseUrl,
    this.apiKey = const Value.absent(),
    this.temperature = const Value.absent(),
    this.maxTokens = const Value.absent(),
    this.contextWindow = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       provider = Value(provider),
       model = Value(model),
       baseUrl = Value(baseUrl);
  static Insertable<ProviderRow> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? provider,
    Expression<String>? model,
    Expression<String>? baseUrl,
    Expression<String>? apiKey,
    Expression<double>? temperature,
    Expression<int>? maxTokens,
    Expression<int>? contextWindow,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (provider != null) 'provider': provider,
      if (model != null) 'model': model,
      if (baseUrl != null) 'base_url': baseUrl,
      if (apiKey != null) 'api_key': apiKey,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (contextWindow != null) 'context_window': contextWindow,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderConfigsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String>? provider,
    Value<String>? model,
    Value<String>? baseUrl,
    Value<String>? apiKey,
    Value<double>? temperature,
    Value<int>? maxTokens,
    Value<int>? contextWindow,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return ProviderConfigsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      contextWindow: contextWindow ?? this.contextWindow,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (maxTokens.present) {
      map['max_tokens'] = Variable<int>(maxTokens.value);
    }
    if (contextWindow.present) {
      map['context_window'] = Variable<int>(contextWindow.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConfigsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('provider: $provider, ')
          ..write('model: $model, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('apiKey: $apiKey, ')
          ..write('temperature: $temperature, ')
          ..write('maxTokens: $maxTokens, ')
          ..write('contextWindow: $contextWindow, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryNotesTable extends MemoryNotes
    with TableInfo<$MemoryNotesTable, MemoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    content,
    tagsJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MemoryNotesTable createAlias(String alias) {
    return $MemoryNotesTable(attachedDatabase, alias);
  }
}

class MemoryRow extends DataClass implements Insertable<MemoryRow> {
  final String id;
  final String workspaceId;
  final String content;
  final String tagsJson;
  final DateTime createdAt;
  const MemoryRow({
    required this.id,
    required this.workspaceId,
    required this.content,
    required this.tagsJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['content'] = Variable<String>(content);
    map['tags_json'] = Variable<String>(tagsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MemoryNotesCompanion toCompanion(bool nullToAbsent) {
    return MemoryNotesCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      content: Value(content),
      tagsJson: Value(tagsJson),
      createdAt: Value(createdAt),
    );
  }

  factory MemoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryRow(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      content: serializer.fromJson<String>(json['content']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'content': serializer.toJson<String>(content),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MemoryRow copyWith({
    String? id,
    String? workspaceId,
    String? content,
    String? tagsJson,
    DateTime? createdAt,
  }) => MemoryRow(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    content: content ?? this.content,
    tagsJson: tagsJson ?? this.tagsJson,
    createdAt: createdAt ?? this.createdAt,
  );
  MemoryRow copyWithCompanion(MemoryNotesCompanion data) {
    return MemoryRow(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      content: data.content.present ? data.content.value : this.content,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryRow(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('content: $content, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, workspaceId, content, tagsJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryRow &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.content == this.content &&
          other.tagsJson == this.tagsJson &&
          other.createdAt == this.createdAt);
}

class MemoryNotesCompanion extends UpdateCompanion<MemoryRow> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> content;
  final Value<String> tagsJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MemoryNotesCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.content = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryNotesCompanion.insert({
    required String id,
    required String workspaceId,
    required String content,
    this.tagsJson = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<MemoryRow> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? content,
    Expression<String>? tagsJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (content != null) 'content': content,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? content,
    Value<String>? tagsJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MemoryNotesCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      content: content ?? this.content,
      tagsJson: tagsJson ?? this.tagsJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryNotesCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('content: $content, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RuntimeConfigsTable extends RuntimeConfigs
    with TableInfo<$RuntimeConfigsTable, RuntimeConfigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuntimeConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    kind,
    optionsJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'runtime_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RuntimeConfigRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RuntimeConfigRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuntimeConfigRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RuntimeConfigsTable createAlias(String alias) {
    return $RuntimeConfigsTable(attachedDatabase, alias);
  }
}

class RuntimeConfigRow extends DataClass
    implements Insertable<RuntimeConfigRow> {
  final String id;
  final String label;
  final String kind;
  final String optionsJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RuntimeConfigRow({
    required this.id,
    required this.label,
    required this.kind,
    required this.optionsJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['kind'] = Variable<String>(kind);
    map['options_json'] = Variable<String>(optionsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RuntimeConfigsCompanion toCompanion(bool nullToAbsent) {
    return RuntimeConfigsCompanion(
      id: Value(id),
      label: Value(label),
      kind: Value(kind),
      optionsJson: Value(optionsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RuntimeConfigRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuntimeConfigRow(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      kind: serializer.fromJson<String>(json['kind']),
      optionsJson: serializer.fromJson<String>(json['optionsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'kind': serializer.toJson<String>(kind),
      'optionsJson': serializer.toJson<String>(optionsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RuntimeConfigRow copyWith({
    String? id,
    String? label,
    String? kind,
    String? optionsJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RuntimeConfigRow(
    id: id ?? this.id,
    label: label ?? this.label,
    kind: kind ?? this.kind,
    optionsJson: optionsJson ?? this.optionsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RuntimeConfigRow copyWithCompanion(RuntimeConfigsCompanion data) {
    return RuntimeConfigRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      kind: data.kind.present ? data.kind.value : this.kind,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuntimeConfigRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('kind: $kind, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, label, kind, optionsJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuntimeConfigRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.kind == this.kind &&
          other.optionsJson == this.optionsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RuntimeConfigsCompanion extends UpdateCompanion<RuntimeConfigRow> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> kind;
  final Value<String> optionsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RuntimeConfigsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.kind = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RuntimeConfigsCompanion.insert({
    required String id,
    required String label,
    required String kind,
    this.optionsJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       label = Value(label),
       kind = Value(kind),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<RuntimeConfigRow> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? kind,
    Expression<String>? optionsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (kind != null) 'kind': kind,
      if (optionsJson != null) 'options_json': optionsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RuntimeConfigsCompanion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String>? kind,
    Value<String>? optionsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RuntimeConfigsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      kind: kind ?? this.kind,
      optionsJson: optionsJson ?? this.optionsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RuntimeConfigsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('kind: $kind, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceUriMeta = const VerificationMeta(
    'sourceUri',
  );
  @override
  late final GeneratedColumn<String> sourceUri = GeneratedColumn<String>(
    'source_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sectionCountMeta = const VerificationMeta(
    'sectionCount',
  );
  @override
  late final GeneratedColumn<int> sectionCount = GeneratedColumn<int>(
    'section_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _parseStatusMeta = const VerificationMeta(
    'parseStatus',
  );
  @override
  late final GeneratedColumn<String> parseStatus = GeneratedColumn<String>(
    'parse_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _parseErrorMeta = const VerificationMeta(
    'parseError',
  );
  @override
  late final GeneratedColumn<String> parseError = GeneratedColumn<String>(
    'parse_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSectionIndexMeta = const VerificationMeta(
    'lastSectionIndex',
  );
  @override
  late final GeneratedColumn<int> lastSectionIndex = GeneratedColumn<int>(
    'last_section_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    displayName,
    sourceUri,
    localPath,
    type,
    mimeType,
    fileSize,
    contentHash,
    title,
    author,
    language,
    pageCount,
    sectionCount,
    parseStatus,
    parseError,
    lastSectionIndex,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('source_uri')) {
      context.handle(
        _sourceUriMeta,
        sourceUri.isAcceptableOrUnknown(data['source_uri']!, _sourceUriMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUriMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('section_count')) {
      context.handle(
        _sectionCountMeta,
        sectionCount.isAcceptableOrUnknown(
          data['section_count']!,
          _sectionCountMeta,
        ),
      );
    }
    if (data.containsKey('parse_status')) {
      context.handle(
        _parseStatusMeta,
        parseStatus.isAcceptableOrUnknown(
          data['parse_status']!,
          _parseStatusMeta,
        ),
      );
    }
    if (data.containsKey('parse_error')) {
      context.handle(
        _parseErrorMeta,
        parseError.isAcceptableOrUnknown(data['parse_error']!, _parseErrorMeta),
      );
    }
    if (data.containsKey('last_section_index')) {
      context.handle(
        _lastSectionIndexMeta,
        lastSectionIndex.isAcceptableOrUnknown(
          data['last_section_index']!,
          _lastSectionIndexMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      sourceUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_uri'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      sectionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section_count'],
      )!,
      parseStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parse_status'],
      )!,
      parseError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parse_error'],
      ),
      lastSectionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_section_index'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class DocumentRow extends DataClass implements Insertable<DocumentRow> {
  final String id;
  final String workspaceId;
  final String displayName;
  final String sourceUri;
  final String localPath;
  final String type;
  final String mimeType;
  final int fileSize;
  final String contentHash;
  final String title;
  final String author;
  final String language;
  final int pageCount;
  final int sectionCount;
  final String parseStatus;
  final String? parseError;

  /// Last-read section index for position persistence (DOC-07).
  final int? lastSectionIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DocumentRow({
    required this.id,
    required this.workspaceId,
    required this.displayName,
    required this.sourceUri,
    required this.localPath,
    required this.type,
    required this.mimeType,
    required this.fileSize,
    required this.contentHash,
    required this.title,
    required this.author,
    required this.language,
    required this.pageCount,
    required this.sectionCount,
    required this.parseStatus,
    this.parseError,
    this.lastSectionIndex,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['display_name'] = Variable<String>(displayName);
    map['source_uri'] = Variable<String>(sourceUri);
    map['local_path'] = Variable<String>(localPath);
    map['type'] = Variable<String>(type);
    map['mime_type'] = Variable<String>(mimeType);
    map['file_size'] = Variable<int>(fileSize);
    map['content_hash'] = Variable<String>(contentHash);
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    map['language'] = Variable<String>(language);
    map['page_count'] = Variable<int>(pageCount);
    map['section_count'] = Variable<int>(sectionCount);
    map['parse_status'] = Variable<String>(parseStatus);
    if (!nullToAbsent || parseError != null) {
      map['parse_error'] = Variable<String>(parseError);
    }
    if (!nullToAbsent || lastSectionIndex != null) {
      map['last_section_index'] = Variable<int>(lastSectionIndex);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      displayName: Value(displayName),
      sourceUri: Value(sourceUri),
      localPath: Value(localPath),
      type: Value(type),
      mimeType: Value(mimeType),
      fileSize: Value(fileSize),
      contentHash: Value(contentHash),
      title: Value(title),
      author: Value(author),
      language: Value(language),
      pageCount: Value(pageCount),
      sectionCount: Value(sectionCount),
      parseStatus: Value(parseStatus),
      parseError: parseError == null && nullToAbsent
          ? const Value.absent()
          : Value(parseError),
      lastSectionIndex: lastSectionIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSectionIndex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRow(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      sourceUri: serializer.fromJson<String>(json['sourceUri']),
      localPath: serializer.fromJson<String>(json['localPath']),
      type: serializer.fromJson<String>(json['type']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      language: serializer.fromJson<String>(json['language']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      sectionCount: serializer.fromJson<int>(json['sectionCount']),
      parseStatus: serializer.fromJson<String>(json['parseStatus']),
      parseError: serializer.fromJson<String?>(json['parseError']),
      lastSectionIndex: serializer.fromJson<int?>(json['lastSectionIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'displayName': serializer.toJson<String>(displayName),
      'sourceUri': serializer.toJson<String>(sourceUri),
      'localPath': serializer.toJson<String>(localPath),
      'type': serializer.toJson<String>(type),
      'mimeType': serializer.toJson<String>(mimeType),
      'fileSize': serializer.toJson<int>(fileSize),
      'contentHash': serializer.toJson<String>(contentHash),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'language': serializer.toJson<String>(language),
      'pageCount': serializer.toJson<int>(pageCount),
      'sectionCount': serializer.toJson<int>(sectionCount),
      'parseStatus': serializer.toJson<String>(parseStatus),
      'parseError': serializer.toJson<String?>(parseError),
      'lastSectionIndex': serializer.toJson<int?>(lastSectionIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DocumentRow copyWith({
    String? id,
    String? workspaceId,
    String? displayName,
    String? sourceUri,
    String? localPath,
    String? type,
    String? mimeType,
    int? fileSize,
    String? contentHash,
    String? title,
    String? author,
    String? language,
    int? pageCount,
    int? sectionCount,
    String? parseStatus,
    Value<String?> parseError = const Value.absent(),
    Value<int?> lastSectionIndex = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DocumentRow(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    displayName: displayName ?? this.displayName,
    sourceUri: sourceUri ?? this.sourceUri,
    localPath: localPath ?? this.localPath,
    type: type ?? this.type,
    mimeType: mimeType ?? this.mimeType,
    fileSize: fileSize ?? this.fileSize,
    contentHash: contentHash ?? this.contentHash,
    title: title ?? this.title,
    author: author ?? this.author,
    language: language ?? this.language,
    pageCount: pageCount ?? this.pageCount,
    sectionCount: sectionCount ?? this.sectionCount,
    parseStatus: parseStatus ?? this.parseStatus,
    parseError: parseError.present ? parseError.value : this.parseError,
    lastSectionIndex: lastSectionIndex.present
        ? lastSectionIndex.value
        : this.lastSectionIndex,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DocumentRow copyWithCompanion(DocumentsCompanion data) {
    return DocumentRow(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      sourceUri: data.sourceUri.present ? data.sourceUri.value : this.sourceUri,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      type: data.type.present ? data.type.value : this.type,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      language: data.language.present ? data.language.value : this.language,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      sectionCount: data.sectionCount.present
          ? data.sectionCount.value
          : this.sectionCount,
      parseStatus: data.parseStatus.present
          ? data.parseStatus.value
          : this.parseStatus,
      parseError: data.parseError.present
          ? data.parseError.value
          : this.parseError,
      lastSectionIndex: data.lastSectionIndex.present
          ? data.lastSectionIndex.value
          : this.lastSectionIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRow(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('displayName: $displayName, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('localPath: $localPath, ')
          ..write('type: $type, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('contentHash: $contentHash, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('language: $language, ')
          ..write('pageCount: $pageCount, ')
          ..write('sectionCount: $sectionCount, ')
          ..write('parseStatus: $parseStatus, ')
          ..write('parseError: $parseError, ')
          ..write('lastSectionIndex: $lastSectionIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    displayName,
    sourceUri,
    localPath,
    type,
    mimeType,
    fileSize,
    contentHash,
    title,
    author,
    language,
    pageCount,
    sectionCount,
    parseStatus,
    parseError,
    lastSectionIndex,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.displayName == this.displayName &&
          other.sourceUri == this.sourceUri &&
          other.localPath == this.localPath &&
          other.type == this.type &&
          other.mimeType == this.mimeType &&
          other.fileSize == this.fileSize &&
          other.contentHash == this.contentHash &&
          other.title == this.title &&
          other.author == this.author &&
          other.language == this.language &&
          other.pageCount == this.pageCount &&
          other.sectionCount == this.sectionCount &&
          other.parseStatus == this.parseStatus &&
          other.parseError == this.parseError &&
          other.lastSectionIndex == this.lastSectionIndex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DocumentsCompanion extends UpdateCompanion<DocumentRow> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> displayName;
  final Value<String> sourceUri;
  final Value<String> localPath;
  final Value<String> type;
  final Value<String> mimeType;
  final Value<int> fileSize;
  final Value<String> contentHash;
  final Value<String> title;
  final Value<String> author;
  final Value<String> language;
  final Value<int> pageCount;
  final Value<int> sectionCount;
  final Value<String> parseStatus;
  final Value<String?> parseError;
  final Value<int?> lastSectionIndex;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.sourceUri = const Value.absent(),
    this.localPath = const Value.absent(),
    this.type = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.language = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.sectionCount = const Value.absent(),
    this.parseStatus = const Value.absent(),
    this.parseError = const Value.absent(),
    this.lastSectionIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String id,
    required String workspaceId,
    required String displayName,
    required String sourceUri,
    required String localPath,
    required String type,
    this.mimeType = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.language = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.sectionCount = const Value.absent(),
    this.parseStatus = const Value.absent(),
    this.parseError = const Value.absent(),
    this.lastSectionIndex = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       displayName = Value(displayName),
       sourceUri = Value(sourceUri),
       localPath = Value(localPath),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DocumentRow> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? displayName,
    Expression<String>? sourceUri,
    Expression<String>? localPath,
    Expression<String>? type,
    Expression<String>? mimeType,
    Expression<int>? fileSize,
    Expression<String>? contentHash,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? language,
    Expression<int>? pageCount,
    Expression<int>? sectionCount,
    Expression<String>? parseStatus,
    Expression<String>? parseError,
    Expression<int>? lastSectionIndex,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (displayName != null) 'display_name': displayName,
      if (sourceUri != null) 'source_uri': sourceUri,
      if (localPath != null) 'local_path': localPath,
      if (type != null) 'type': type,
      if (mimeType != null) 'mime_type': mimeType,
      if (fileSize != null) 'file_size': fileSize,
      if (contentHash != null) 'content_hash': contentHash,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (language != null) 'language': language,
      if (pageCount != null) 'page_count': pageCount,
      if (sectionCount != null) 'section_count': sectionCount,
      if (parseStatus != null) 'parse_status': parseStatus,
      if (parseError != null) 'parse_error': parseError,
      if (lastSectionIndex != null) 'last_section_index': lastSectionIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? displayName,
    Value<String>? sourceUri,
    Value<String>? localPath,
    Value<String>? type,
    Value<String>? mimeType,
    Value<int>? fileSize,
    Value<String>? contentHash,
    Value<String>? title,
    Value<String>? author,
    Value<String>? language,
    Value<int>? pageCount,
    Value<int>? sectionCount,
    Value<String>? parseStatus,
    Value<String?>? parseError,
    Value<int?>? lastSectionIndex,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      displayName: displayName ?? this.displayName,
      sourceUri: sourceUri ?? this.sourceUri,
      localPath: localPath ?? this.localPath,
      type: type ?? this.type,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      contentHash: contentHash ?? this.contentHash,
      title: title ?? this.title,
      author: author ?? this.author,
      language: language ?? this.language,
      pageCount: pageCount ?? this.pageCount,
      sectionCount: sectionCount ?? this.sectionCount,
      parseStatus: parseStatus ?? this.parseStatus,
      parseError: parseError ?? this.parseError,
      lastSectionIndex: lastSectionIndex ?? this.lastSectionIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (sourceUri.present) {
      map['source_uri'] = Variable<String>(sourceUri.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (sectionCount.present) {
      map['section_count'] = Variable<int>(sectionCount.value);
    }
    if (parseStatus.present) {
      map['parse_status'] = Variable<String>(parseStatus.value);
    }
    if (parseError.present) {
      map['parse_error'] = Variable<String>(parseError.value);
    }
    if (lastSectionIndex.present) {
      map['last_section_index'] = Variable<int>(lastSectionIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('displayName: $displayName, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('localPath: $localPath, ')
          ..write('type: $type, ')
          ..write('mimeType: $mimeType, ')
          ..write('fileSize: $fileSize, ')
          ..write('contentHash: $contentHash, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('language: $language, ')
          ..write('pageCount: $pageCount, ')
          ..write('sectionCount: $sectionCount, ')
          ..write('parseStatus: $parseStatus, ')
          ..write('parseError: $parseError, ')
          ..write('lastSectionIndex: $lastSectionIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentSectionsTable extends DocumentSections
    with TableInfo<$DocumentSectionsTable, DocumentSectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentSectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sectionIndexMeta = const VerificationMeta(
    'sectionIndex',
  );
  @override
  late final GeneratedColumn<int> sectionIndex = GeneratedColumn<int>(
    'section_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentSectionIdMeta = const VerificationMeta(
    'parentSectionId',
  );
  @override
  late final GeneratedColumn<String> parentSectionId = GeneratedColumn<String>(
    'parent_section_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _locatorMeta = const VerificationMeta(
    'locator',
  );
  @override
  late final GeneratedColumn<String> locator = GeneratedColumn<String>(
    'locator',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plainTextMeta = const VerificationMeta(
    'plainText',
  );
  @override
  late final GeneratedColumn<String> plainText = GeneratedColumn<String>(
    'plain_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _charCountMeta = const VerificationMeta(
    'charCount',
  );
  @override
  late final GeneratedColumn<int> charCount = GeneratedColumn<int>(
    'char_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    sectionIndex,
    parentSectionId,
    kind,
    title,
    locator,
    plainText,
    charCount,
    metadataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_sections';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentSectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('section_index')) {
      context.handle(
        _sectionIndexMeta,
        sectionIndex.isAcceptableOrUnknown(
          data['section_index']!,
          _sectionIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sectionIndexMeta);
    }
    if (data.containsKey('parent_section_id')) {
      context.handle(
        _parentSectionIdMeta,
        parentSectionId.isAcceptableOrUnknown(
          data['parent_section_id']!,
          _parentSectionIdMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('locator')) {
      context.handle(
        _locatorMeta,
        locator.isAcceptableOrUnknown(data['locator']!, _locatorMeta),
      );
    } else if (isInserting) {
      context.missing(_locatorMeta);
    }
    if (data.containsKey('plain_text')) {
      context.handle(
        _plainTextMeta,
        plainText.isAcceptableOrUnknown(data['plain_text']!, _plainTextMeta),
      );
    }
    if (data.containsKey('char_count')) {
      context.handle(
        _charCountMeta,
        charCount.isAcceptableOrUnknown(data['char_count']!, _charCountMeta),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {documentId, sectionIndex},
  ];
  @override
  DocumentSectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentSectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      sectionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section_index'],
      )!,
      parentSectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_section_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      locator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locator'],
      )!,
      plainText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plain_text'],
      )!,
      charCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}char_count'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
    );
  }

  @override
  $DocumentSectionsTable createAlias(String alias) {
    return $DocumentSectionsTable(attachedDatabase, alias);
  }
}

class DocumentSectionRow extends DataClass
    implements Insertable<DocumentSectionRow> {
  final String id;
  final String documentId;
  final int sectionIndex;
  final String? parentSectionId;
  final String kind;
  final String title;
  final String locator;
  final String plainText;
  final int charCount;
  final String metadataJson;
  const DocumentSectionRow({
    required this.id,
    required this.documentId,
    required this.sectionIndex,
    this.parentSectionId,
    required this.kind,
    required this.title,
    required this.locator,
    required this.plainText,
    required this.charCount,
    required this.metadataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['section_index'] = Variable<int>(sectionIndex);
    if (!nullToAbsent || parentSectionId != null) {
      map['parent_section_id'] = Variable<String>(parentSectionId);
    }
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    map['locator'] = Variable<String>(locator);
    map['plain_text'] = Variable<String>(plainText);
    map['char_count'] = Variable<int>(charCount);
    map['metadata_json'] = Variable<String>(metadataJson);
    return map;
  }

  DocumentSectionsCompanion toCompanion(bool nullToAbsent) {
    return DocumentSectionsCompanion(
      id: Value(id),
      documentId: Value(documentId),
      sectionIndex: Value(sectionIndex),
      parentSectionId: parentSectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentSectionId),
      kind: Value(kind),
      title: Value(title),
      locator: Value(locator),
      plainText: Value(plainText),
      charCount: Value(charCount),
      metadataJson: Value(metadataJson),
    );
  }

  factory DocumentSectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentSectionRow(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      sectionIndex: serializer.fromJson<int>(json['sectionIndex']),
      parentSectionId: serializer.fromJson<String?>(json['parentSectionId']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      locator: serializer.fromJson<String>(json['locator']),
      plainText: serializer.fromJson<String>(json['plainText']),
      charCount: serializer.fromJson<int>(json['charCount']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'sectionIndex': serializer.toJson<int>(sectionIndex),
      'parentSectionId': serializer.toJson<String?>(parentSectionId),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'locator': serializer.toJson<String>(locator),
      'plainText': serializer.toJson<String>(plainText),
      'charCount': serializer.toJson<int>(charCount),
      'metadataJson': serializer.toJson<String>(metadataJson),
    };
  }

  DocumentSectionRow copyWith({
    String? id,
    String? documentId,
    int? sectionIndex,
    Value<String?> parentSectionId = const Value.absent(),
    String? kind,
    String? title,
    String? locator,
    String? plainText,
    int? charCount,
    String? metadataJson,
  }) => DocumentSectionRow(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    sectionIndex: sectionIndex ?? this.sectionIndex,
    parentSectionId: parentSectionId.present
        ? parentSectionId.value
        : this.parentSectionId,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    locator: locator ?? this.locator,
    plainText: plainText ?? this.plainText,
    charCount: charCount ?? this.charCount,
    metadataJson: metadataJson ?? this.metadataJson,
  );
  DocumentSectionRow copyWithCompanion(DocumentSectionsCompanion data) {
    return DocumentSectionRow(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      sectionIndex: data.sectionIndex.present
          ? data.sectionIndex.value
          : this.sectionIndex,
      parentSectionId: data.parentSectionId.present
          ? data.parentSectionId.value
          : this.parentSectionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      locator: data.locator.present ? data.locator.value : this.locator,
      plainText: data.plainText.present ? data.plainText.value : this.plainText,
      charCount: data.charCount.present ? data.charCount.value : this.charCount,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentSectionRow(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('sectionIndex: $sectionIndex, ')
          ..write('parentSectionId: $parentSectionId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('locator: $locator, ')
          ..write('plainText: $plainText, ')
          ..write('charCount: $charCount, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    sectionIndex,
    parentSectionId,
    kind,
    title,
    locator,
    plainText,
    charCount,
    metadataJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentSectionRow &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.sectionIndex == this.sectionIndex &&
          other.parentSectionId == this.parentSectionId &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.locator == this.locator &&
          other.plainText == this.plainText &&
          other.charCount == this.charCount &&
          other.metadataJson == this.metadataJson);
}

class DocumentSectionsCompanion extends UpdateCompanion<DocumentSectionRow> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<int> sectionIndex;
  final Value<String?> parentSectionId;
  final Value<String> kind;
  final Value<String> title;
  final Value<String> locator;
  final Value<String> plainText;
  final Value<int> charCount;
  final Value<String> metadataJson;
  final Value<int> rowid;
  const DocumentSectionsCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.sectionIndex = const Value.absent(),
    this.parentSectionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.locator = const Value.absent(),
    this.plainText = const Value.absent(),
    this.charCount = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentSectionsCompanion.insert({
    required String id,
    required String documentId,
    required int sectionIndex,
    this.parentSectionId = const Value.absent(),
    required String kind,
    this.title = const Value.absent(),
    required String locator,
    this.plainText = const Value.absent(),
    this.charCount = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       sectionIndex = Value(sectionIndex),
       kind = Value(kind),
       locator = Value(locator);
  static Insertable<DocumentSectionRow> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<int>? sectionIndex,
    Expression<String>? parentSectionId,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? locator,
    Expression<String>? plainText,
    Expression<int>? charCount,
    Expression<String>? metadataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (sectionIndex != null) 'section_index': sectionIndex,
      if (parentSectionId != null) 'parent_section_id': parentSectionId,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (locator != null) 'locator': locator,
      if (plainText != null) 'plain_text': plainText,
      if (charCount != null) 'char_count': charCount,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentSectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<int>? sectionIndex,
    Value<String?>? parentSectionId,
    Value<String>? kind,
    Value<String>? title,
    Value<String>? locator,
    Value<String>? plainText,
    Value<int>? charCount,
    Value<String>? metadataJson,
    Value<int>? rowid,
  }) {
    return DocumentSectionsCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      sectionIndex: sectionIndex ?? this.sectionIndex,
      parentSectionId: parentSectionId ?? this.parentSectionId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      locator: locator ?? this.locator,
      plainText: plainText ?? this.plainText,
      charCount: charCount ?? this.charCount,
      metadataJson: metadataJson ?? this.metadataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (sectionIndex.present) {
      map['section_index'] = Variable<int>(sectionIndex.value);
    }
    if (parentSectionId.present) {
      map['parent_section_id'] = Variable<String>(parentSectionId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (locator.present) {
      map['locator'] = Variable<String>(locator.value);
    }
    if (plainText.present) {
      map['plain_text'] = Variable<String>(plainText.value);
    }
    if (charCount.present) {
      map['char_count'] = Variable<int>(charCount.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentSectionsCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('sectionIndex: $sectionIndex, ')
          ..write('parentSectionId: $parentSectionId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('locator: $locator, ')
          ..write('plainText: $plainText, ')
          ..write('charCount: $charCount, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $McpServersTable extends McpServers
    with TableInfo<$McpServersTable, McpServerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $McpServersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transportMeta = const VerificationMeta(
    'transport',
  );
  @override
  late final GeneratedColumn<String> transport = GeneratedColumn<String>(
    'transport',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _commandMeta = const VerificationMeta(
    'command',
  );
  @override
  late final GeneratedColumn<String> command = GeneratedColumn<String>(
    'command',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _argumentsJsonMeta = const VerificationMeta(
    'argumentsJson',
  );
  @override
  late final GeneratedColumn<String> argumentsJson = GeneratedColumn<String>(
    'arguments_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _environmentJsonMeta = const VerificationMeta(
    'environmentJson',
  );
  @override
  late final GeneratedColumn<String> environmentJson = GeneratedColumn<String>(
    'environment_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _headersJsonMeta = const VerificationMeta(
    'headersJson',
  );
  @override
  late final GeneratedColumn<String> headersJson = GeneratedColumn<String>(
    'headers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _runtimeConfigIdMeta = const VerificationMeta(
    'runtimeConfigId',
  );
  @override
  late final GeneratedColumn<String> runtimeConfigId = GeneratedColumn<String>(
    'runtime_config_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _autoConnectMeta = const VerificationMeta(
    'autoConnect',
  );
  @override
  late final GeneratedColumn<bool> autoConnect = GeneratedColumn<bool>(
    'auto_connect',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_connect" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _connectionTimeoutMsMeta =
      const VerificationMeta('connectionTimeoutMs');
  @override
  late final GeneratedColumn<int> connectionTimeoutMs = GeneratedColumn<int>(
    'connection_timeout_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10000),
  );
  static const VerificationMeta _toolTimeoutMsMeta = const VerificationMeta(
    'toolTimeoutMs',
  );
  @override
  late final GeneratedColumn<int> toolTimeoutMs = GeneratedColumn<int>(
    'tool_timeout_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60000),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    name,
    transport,
    endpoint,
    command,
    argumentsJson,
    environmentJson,
    headersJson,
    runtimeConfigId,
    enabled,
    autoConnect,
    connectionTimeoutMs,
    toolTimeoutMs,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mcp_servers';
  @override
  VerificationContext validateIntegrity(
    Insertable<McpServerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('transport')) {
      context.handle(
        _transportMeta,
        transport.isAcceptableOrUnknown(data['transport']!, _transportMeta),
      );
    } else if (isInserting) {
      context.missing(_transportMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    }
    if (data.containsKey('command')) {
      context.handle(
        _commandMeta,
        command.isAcceptableOrUnknown(data['command']!, _commandMeta),
      );
    }
    if (data.containsKey('arguments_json')) {
      context.handle(
        _argumentsJsonMeta,
        argumentsJson.isAcceptableOrUnknown(
          data['arguments_json']!,
          _argumentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('environment_json')) {
      context.handle(
        _environmentJsonMeta,
        environmentJson.isAcceptableOrUnknown(
          data['environment_json']!,
          _environmentJsonMeta,
        ),
      );
    }
    if (data.containsKey('headers_json')) {
      context.handle(
        _headersJsonMeta,
        headersJson.isAcceptableOrUnknown(
          data['headers_json']!,
          _headersJsonMeta,
        ),
      );
    }
    if (data.containsKey('runtime_config_id')) {
      context.handle(
        _runtimeConfigIdMeta,
        runtimeConfigId.isAcceptableOrUnknown(
          data['runtime_config_id']!,
          _runtimeConfigIdMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('auto_connect')) {
      context.handle(
        _autoConnectMeta,
        autoConnect.isAcceptableOrUnknown(
          data['auto_connect']!,
          _autoConnectMeta,
        ),
      );
    }
    if (data.containsKey('connection_timeout_ms')) {
      context.handle(
        _connectionTimeoutMsMeta,
        connectionTimeoutMs.isAcceptableOrUnknown(
          data['connection_timeout_ms']!,
          _connectionTimeoutMsMeta,
        ),
      );
    }
    if (data.containsKey('tool_timeout_ms')) {
      context.handle(
        _toolTimeoutMsMeta,
        toolTimeoutMs.isAcceptableOrUnknown(
          data['tool_timeout_ms']!,
          _toolTimeoutMsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  McpServerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return McpServerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      transport: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transport'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      command: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command'],
      )!,
      argumentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arguments_json'],
      )!,
      environmentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_json'],
      )!,
      headersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headers_json'],
      )!,
      runtimeConfigId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}runtime_config_id'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      autoConnect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_connect'],
      )!,
      connectionTimeoutMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}connection_timeout_ms'],
      )!,
      toolTimeoutMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tool_timeout_ms'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $McpServersTable createAlias(String alias) {
    return $McpServersTable(attachedDatabase, alias);
  }
}

class McpServerRow extends DataClass implements Insertable<McpServerRow> {
  final String id;
  final String workspaceId;
  final String name;
  final String transport;
  final String endpoint;
  final String command;
  final String argumentsJson;
  final String environmentJson;
  final String headersJson;
  final String? runtimeConfigId;
  final bool enabled;
  final bool autoConnect;
  final int connectionTimeoutMs;
  final int toolTimeoutMs;
  final DateTime createdAt;
  final DateTime updatedAt;
  const McpServerRow({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.transport,
    required this.endpoint,
    required this.command,
    required this.argumentsJson,
    required this.environmentJson,
    required this.headersJson,
    this.runtimeConfigId,
    required this.enabled,
    required this.autoConnect,
    required this.connectionTimeoutMs,
    required this.toolTimeoutMs,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['name'] = Variable<String>(name);
    map['transport'] = Variable<String>(transport);
    map['endpoint'] = Variable<String>(endpoint);
    map['command'] = Variable<String>(command);
    map['arguments_json'] = Variable<String>(argumentsJson);
    map['environment_json'] = Variable<String>(environmentJson);
    map['headers_json'] = Variable<String>(headersJson);
    if (!nullToAbsent || runtimeConfigId != null) {
      map['runtime_config_id'] = Variable<String>(runtimeConfigId);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['auto_connect'] = Variable<bool>(autoConnect);
    map['connection_timeout_ms'] = Variable<int>(connectionTimeoutMs);
    map['tool_timeout_ms'] = Variable<int>(toolTimeoutMs);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  McpServersCompanion toCompanion(bool nullToAbsent) {
    return McpServersCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      name: Value(name),
      transport: Value(transport),
      endpoint: Value(endpoint),
      command: Value(command),
      argumentsJson: Value(argumentsJson),
      environmentJson: Value(environmentJson),
      headersJson: Value(headersJson),
      runtimeConfigId: runtimeConfigId == null && nullToAbsent
          ? const Value.absent()
          : Value(runtimeConfigId),
      enabled: Value(enabled),
      autoConnect: Value(autoConnect),
      connectionTimeoutMs: Value(connectionTimeoutMs),
      toolTimeoutMs: Value(toolTimeoutMs),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory McpServerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return McpServerRow(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      name: serializer.fromJson<String>(json['name']),
      transport: serializer.fromJson<String>(json['transport']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      command: serializer.fromJson<String>(json['command']),
      argumentsJson: serializer.fromJson<String>(json['argumentsJson']),
      environmentJson: serializer.fromJson<String>(json['environmentJson']),
      headersJson: serializer.fromJson<String>(json['headersJson']),
      runtimeConfigId: serializer.fromJson<String?>(json['runtimeConfigId']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      autoConnect: serializer.fromJson<bool>(json['autoConnect']),
      connectionTimeoutMs: serializer.fromJson<int>(
        json['connectionTimeoutMs'],
      ),
      toolTimeoutMs: serializer.fromJson<int>(json['toolTimeoutMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'name': serializer.toJson<String>(name),
      'transport': serializer.toJson<String>(transport),
      'endpoint': serializer.toJson<String>(endpoint),
      'command': serializer.toJson<String>(command),
      'argumentsJson': serializer.toJson<String>(argumentsJson),
      'environmentJson': serializer.toJson<String>(environmentJson),
      'headersJson': serializer.toJson<String>(headersJson),
      'runtimeConfigId': serializer.toJson<String?>(runtimeConfigId),
      'enabled': serializer.toJson<bool>(enabled),
      'autoConnect': serializer.toJson<bool>(autoConnect),
      'connectionTimeoutMs': serializer.toJson<int>(connectionTimeoutMs),
      'toolTimeoutMs': serializer.toJson<int>(toolTimeoutMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  McpServerRow copyWith({
    String? id,
    String? workspaceId,
    String? name,
    String? transport,
    String? endpoint,
    String? command,
    String? argumentsJson,
    String? environmentJson,
    String? headersJson,
    Value<String?> runtimeConfigId = const Value.absent(),
    bool? enabled,
    bool? autoConnect,
    int? connectionTimeoutMs,
    int? toolTimeoutMs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => McpServerRow(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    name: name ?? this.name,
    transport: transport ?? this.transport,
    endpoint: endpoint ?? this.endpoint,
    command: command ?? this.command,
    argumentsJson: argumentsJson ?? this.argumentsJson,
    environmentJson: environmentJson ?? this.environmentJson,
    headersJson: headersJson ?? this.headersJson,
    runtimeConfigId: runtimeConfigId.present
        ? runtimeConfigId.value
        : this.runtimeConfigId,
    enabled: enabled ?? this.enabled,
    autoConnect: autoConnect ?? this.autoConnect,
    connectionTimeoutMs: connectionTimeoutMs ?? this.connectionTimeoutMs,
    toolTimeoutMs: toolTimeoutMs ?? this.toolTimeoutMs,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  McpServerRow copyWithCompanion(McpServersCompanion data) {
    return McpServerRow(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      name: data.name.present ? data.name.value : this.name,
      transport: data.transport.present ? data.transport.value : this.transport,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      command: data.command.present ? data.command.value : this.command,
      argumentsJson: data.argumentsJson.present
          ? data.argumentsJson.value
          : this.argumentsJson,
      environmentJson: data.environmentJson.present
          ? data.environmentJson.value
          : this.environmentJson,
      headersJson: data.headersJson.present
          ? data.headersJson.value
          : this.headersJson,
      runtimeConfigId: data.runtimeConfigId.present
          ? data.runtimeConfigId.value
          : this.runtimeConfigId,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      autoConnect: data.autoConnect.present
          ? data.autoConnect.value
          : this.autoConnect,
      connectionTimeoutMs: data.connectionTimeoutMs.present
          ? data.connectionTimeoutMs.value
          : this.connectionTimeoutMs,
      toolTimeoutMs: data.toolTimeoutMs.present
          ? data.toolTimeoutMs.value
          : this.toolTimeoutMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('McpServerRow(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('transport: $transport, ')
          ..write('endpoint: $endpoint, ')
          ..write('command: $command, ')
          ..write('argumentsJson: $argumentsJson, ')
          ..write('environmentJson: $environmentJson, ')
          ..write('headersJson: $headersJson, ')
          ..write('runtimeConfigId: $runtimeConfigId, ')
          ..write('enabled: $enabled, ')
          ..write('autoConnect: $autoConnect, ')
          ..write('connectionTimeoutMs: $connectionTimeoutMs, ')
          ..write('toolTimeoutMs: $toolTimeoutMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    name,
    transport,
    endpoint,
    command,
    argumentsJson,
    environmentJson,
    headersJson,
    runtimeConfigId,
    enabled,
    autoConnect,
    connectionTimeoutMs,
    toolTimeoutMs,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McpServerRow &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.name == this.name &&
          other.transport == this.transport &&
          other.endpoint == this.endpoint &&
          other.command == this.command &&
          other.argumentsJson == this.argumentsJson &&
          other.environmentJson == this.environmentJson &&
          other.headersJson == this.headersJson &&
          other.runtimeConfigId == this.runtimeConfigId &&
          other.enabled == this.enabled &&
          other.autoConnect == this.autoConnect &&
          other.connectionTimeoutMs == this.connectionTimeoutMs &&
          other.toolTimeoutMs == this.toolTimeoutMs &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class McpServersCompanion extends UpdateCompanion<McpServerRow> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> name;
  final Value<String> transport;
  final Value<String> endpoint;
  final Value<String> command;
  final Value<String> argumentsJson;
  final Value<String> environmentJson;
  final Value<String> headersJson;
  final Value<String?> runtimeConfigId;
  final Value<bool> enabled;
  final Value<bool> autoConnect;
  final Value<int> connectionTimeoutMs;
  final Value<int> toolTimeoutMs;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const McpServersCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.transport = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.command = const Value.absent(),
    this.argumentsJson = const Value.absent(),
    this.environmentJson = const Value.absent(),
    this.headersJson = const Value.absent(),
    this.runtimeConfigId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.autoConnect = const Value.absent(),
    this.connectionTimeoutMs = const Value.absent(),
    this.toolTimeoutMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  McpServersCompanion.insert({
    required String id,
    required String workspaceId,
    required String name,
    required String transport,
    this.endpoint = const Value.absent(),
    this.command = const Value.absent(),
    this.argumentsJson = const Value.absent(),
    this.environmentJson = const Value.absent(),
    this.headersJson = const Value.absent(),
    this.runtimeConfigId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.autoConnect = const Value.absent(),
    this.connectionTimeoutMs = const Value.absent(),
    this.toolTimeoutMs = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       name = Value(name),
       transport = Value(transport),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<McpServerRow> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? name,
    Expression<String>? transport,
    Expression<String>? endpoint,
    Expression<String>? command,
    Expression<String>? argumentsJson,
    Expression<String>? environmentJson,
    Expression<String>? headersJson,
    Expression<String>? runtimeConfigId,
    Expression<bool>? enabled,
    Expression<bool>? autoConnect,
    Expression<int>? connectionTimeoutMs,
    Expression<int>? toolTimeoutMs,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (name != null) 'name': name,
      if (transport != null) 'transport': transport,
      if (endpoint != null) 'endpoint': endpoint,
      if (command != null) 'command': command,
      if (argumentsJson != null) 'arguments_json': argumentsJson,
      if (environmentJson != null) 'environment_json': environmentJson,
      if (headersJson != null) 'headers_json': headersJson,
      if (runtimeConfigId != null) 'runtime_config_id': runtimeConfigId,
      if (enabled != null) 'enabled': enabled,
      if (autoConnect != null) 'auto_connect': autoConnect,
      if (connectionTimeoutMs != null)
        'connection_timeout_ms': connectionTimeoutMs,
      if (toolTimeoutMs != null) 'tool_timeout_ms': toolTimeoutMs,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  McpServersCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? name,
    Value<String>? transport,
    Value<String>? endpoint,
    Value<String>? command,
    Value<String>? argumentsJson,
    Value<String>? environmentJson,
    Value<String>? headersJson,
    Value<String?>? runtimeConfigId,
    Value<bool>? enabled,
    Value<bool>? autoConnect,
    Value<int>? connectionTimeoutMs,
    Value<int>? toolTimeoutMs,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return McpServersCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      transport: transport ?? this.transport,
      endpoint: endpoint ?? this.endpoint,
      command: command ?? this.command,
      argumentsJson: argumentsJson ?? this.argumentsJson,
      environmentJson: environmentJson ?? this.environmentJson,
      headersJson: headersJson ?? this.headersJson,
      runtimeConfigId: runtimeConfigId ?? this.runtimeConfigId,
      enabled: enabled ?? this.enabled,
      autoConnect: autoConnect ?? this.autoConnect,
      connectionTimeoutMs: connectionTimeoutMs ?? this.connectionTimeoutMs,
      toolTimeoutMs: toolTimeoutMs ?? this.toolTimeoutMs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (transport.present) {
      map['transport'] = Variable<String>(transport.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (command.present) {
      map['command'] = Variable<String>(command.value);
    }
    if (argumentsJson.present) {
      map['arguments_json'] = Variable<String>(argumentsJson.value);
    }
    if (environmentJson.present) {
      map['environment_json'] = Variable<String>(environmentJson.value);
    }
    if (headersJson.present) {
      map['headers_json'] = Variable<String>(headersJson.value);
    }
    if (runtimeConfigId.present) {
      map['runtime_config_id'] = Variable<String>(runtimeConfigId.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (autoConnect.present) {
      map['auto_connect'] = Variable<bool>(autoConnect.value);
    }
    if (connectionTimeoutMs.present) {
      map['connection_timeout_ms'] = Variable<int>(connectionTimeoutMs.value);
    }
    if (toolTimeoutMs.present) {
      map['tool_timeout_ms'] = Variable<int>(toolTimeoutMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('McpServersCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('transport: $transport, ')
          ..write('endpoint: $endpoint, ')
          ..write('command: $command, ')
          ..write('argumentsJson: $argumentsJson, ')
          ..write('environmentJson: $environmentJson, ')
          ..write('headersJson: $headersJson, ')
          ..write('runtimeConfigId: $runtimeConfigId, ')
          ..write('enabled: $enabled, ')
          ..write('autoConnect: $autoConnect, ')
          ..write('connectionTimeoutMs: $connectionTimeoutMs, ')
          ..write('toolTimeoutMs: $toolTimeoutMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LspServerConfigsTable extends LspServerConfigs
    with TableInfo<$LspServerConfigsTable, LspServerConfigRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LspServerConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _languageIdMeta = const VerificationMeta(
    'languageId',
  );
  @override
  late final GeneratedColumn<String> languageId = GeneratedColumn<String>(
    'language_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commandMeta = const VerificationMeta(
    'command',
  );
  @override
  late final GeneratedColumn<String> command = GeneratedColumn<String>(
    'command',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _argumentsJsonMeta = const VerificationMeta(
    'argumentsJson',
  );
  @override
  late final GeneratedColumn<String> argumentsJson = GeneratedColumn<String>(
    'arguments_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _environmentJsonMeta = const VerificationMeta(
    'environmentJson',
  );
  @override
  late final GeneratedColumn<String> environmentJson = GeneratedColumn<String>(
    'environment_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _initializationOptionsJsonMeta =
      const VerificationMeta('initializationOptionsJson');
  @override
  late final GeneratedColumn<String> initializationOptionsJson =
      GeneratedColumn<String>(
        'initialization_options_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    languageId,
    command,
    argumentsJson,
    environmentJson,
    enabled,
    initializationOptionsJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lsp_server_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LspServerConfigRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('language_id')) {
      context.handle(
        _languageIdMeta,
        languageId.isAcceptableOrUnknown(data['language_id']!, _languageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_languageIdMeta);
    }
    if (data.containsKey('command')) {
      context.handle(
        _commandMeta,
        command.isAcceptableOrUnknown(data['command']!, _commandMeta),
      );
    } else if (isInserting) {
      context.missing(_commandMeta);
    }
    if (data.containsKey('arguments_json')) {
      context.handle(
        _argumentsJsonMeta,
        argumentsJson.isAcceptableOrUnknown(
          data['arguments_json']!,
          _argumentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('environment_json')) {
      context.handle(
        _environmentJsonMeta,
        environmentJson.isAcceptableOrUnknown(
          data['environment_json']!,
          _environmentJsonMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('initialization_options_json')) {
      context.handle(
        _initializationOptionsJsonMeta,
        initializationOptionsJson.isAcceptableOrUnknown(
          data['initialization_options_json']!,
          _initializationOptionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workspaceId, languageId},
  ];
  @override
  LspServerConfigRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LspServerConfigRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      languageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_id'],
      )!,
      command: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command'],
      )!,
      argumentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arguments_json'],
      )!,
      environmentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_json'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      initializationOptionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initialization_options_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LspServerConfigsTable createAlias(String alias) {
    return $LspServerConfigsTable(attachedDatabase, alias);
  }
}

class LspServerConfigRow extends DataClass
    implements Insertable<LspServerConfigRow> {
  final String id;
  final String workspaceId;
  final String languageId;
  final String command;
  final String argumentsJson;
  final String environmentJson;
  final bool enabled;
  final String initializationOptionsJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LspServerConfigRow({
    required this.id,
    required this.workspaceId,
    required this.languageId,
    required this.command,
    required this.argumentsJson,
    required this.environmentJson,
    required this.enabled,
    required this.initializationOptionsJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['language_id'] = Variable<String>(languageId);
    map['command'] = Variable<String>(command);
    map['arguments_json'] = Variable<String>(argumentsJson);
    map['environment_json'] = Variable<String>(environmentJson);
    map['enabled'] = Variable<bool>(enabled);
    map['initialization_options_json'] = Variable<String>(
      initializationOptionsJson,
    );
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LspServerConfigsCompanion toCompanion(bool nullToAbsent) {
    return LspServerConfigsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      languageId: Value(languageId),
      command: Value(command),
      argumentsJson: Value(argumentsJson),
      environmentJson: Value(environmentJson),
      enabled: Value(enabled),
      initializationOptionsJson: Value(initializationOptionsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LspServerConfigRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LspServerConfigRow(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      languageId: serializer.fromJson<String>(json['languageId']),
      command: serializer.fromJson<String>(json['command']),
      argumentsJson: serializer.fromJson<String>(json['argumentsJson']),
      environmentJson: serializer.fromJson<String>(json['environmentJson']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      initializationOptionsJson: serializer.fromJson<String>(
        json['initializationOptionsJson'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'languageId': serializer.toJson<String>(languageId),
      'command': serializer.toJson<String>(command),
      'argumentsJson': serializer.toJson<String>(argumentsJson),
      'environmentJson': serializer.toJson<String>(environmentJson),
      'enabled': serializer.toJson<bool>(enabled),
      'initializationOptionsJson': serializer.toJson<String>(
        initializationOptionsJson,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LspServerConfigRow copyWith({
    String? id,
    String? workspaceId,
    String? languageId,
    String? command,
    String? argumentsJson,
    String? environmentJson,
    bool? enabled,
    String? initializationOptionsJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LspServerConfigRow(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    languageId: languageId ?? this.languageId,
    command: command ?? this.command,
    argumentsJson: argumentsJson ?? this.argumentsJson,
    environmentJson: environmentJson ?? this.environmentJson,
    enabled: enabled ?? this.enabled,
    initializationOptionsJson:
        initializationOptionsJson ?? this.initializationOptionsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LspServerConfigRow copyWithCompanion(LspServerConfigsCompanion data) {
    return LspServerConfigRow(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      languageId: data.languageId.present
          ? data.languageId.value
          : this.languageId,
      command: data.command.present ? data.command.value : this.command,
      argumentsJson: data.argumentsJson.present
          ? data.argumentsJson.value
          : this.argumentsJson,
      environmentJson: data.environmentJson.present
          ? data.environmentJson.value
          : this.environmentJson,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      initializationOptionsJson: data.initializationOptionsJson.present
          ? data.initializationOptionsJson.value
          : this.initializationOptionsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LspServerConfigRow(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('languageId: $languageId, ')
          ..write('command: $command, ')
          ..write('argumentsJson: $argumentsJson, ')
          ..write('environmentJson: $environmentJson, ')
          ..write('enabled: $enabled, ')
          ..write('initializationOptionsJson: $initializationOptionsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    languageId,
    command,
    argumentsJson,
    environmentJson,
    enabled,
    initializationOptionsJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LspServerConfigRow &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.languageId == this.languageId &&
          other.command == this.command &&
          other.argumentsJson == this.argumentsJson &&
          other.environmentJson == this.environmentJson &&
          other.enabled == this.enabled &&
          other.initializationOptionsJson == this.initializationOptionsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LspServerConfigsCompanion extends UpdateCompanion<LspServerConfigRow> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> languageId;
  final Value<String> command;
  final Value<String> argumentsJson;
  final Value<String> environmentJson;
  final Value<bool> enabled;
  final Value<String> initializationOptionsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LspServerConfigsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.languageId = const Value.absent(),
    this.command = const Value.absent(),
    this.argumentsJson = const Value.absent(),
    this.environmentJson = const Value.absent(),
    this.enabled = const Value.absent(),
    this.initializationOptionsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LspServerConfigsCompanion.insert({
    required String id,
    required String workspaceId,
    required String languageId,
    required String command,
    this.argumentsJson = const Value.absent(),
    this.environmentJson = const Value.absent(),
    this.enabled = const Value.absent(),
    this.initializationOptionsJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       languageId = Value(languageId),
       command = Value(command),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LspServerConfigRow> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? languageId,
    Expression<String>? command,
    Expression<String>? argumentsJson,
    Expression<String>? environmentJson,
    Expression<bool>? enabled,
    Expression<String>? initializationOptionsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (languageId != null) 'language_id': languageId,
      if (command != null) 'command': command,
      if (argumentsJson != null) 'arguments_json': argumentsJson,
      if (environmentJson != null) 'environment_json': environmentJson,
      if (enabled != null) 'enabled': enabled,
      if (initializationOptionsJson != null)
        'initialization_options_json': initializationOptionsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LspServerConfigsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? languageId,
    Value<String>? command,
    Value<String>? argumentsJson,
    Value<String>? environmentJson,
    Value<bool>? enabled,
    Value<String>? initializationOptionsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LspServerConfigsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      languageId: languageId ?? this.languageId,
      command: command ?? this.command,
      argumentsJson: argumentsJson ?? this.argumentsJson,
      environmentJson: environmentJson ?? this.environmentJson,
      enabled: enabled ?? this.enabled,
      initializationOptionsJson:
          initializationOptionsJson ?? this.initializationOptionsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (languageId.present) {
      map['language_id'] = Variable<String>(languageId.value);
    }
    if (command.present) {
      map['command'] = Variable<String>(command.value);
    }
    if (argumentsJson.present) {
      map['arguments_json'] = Variable<String>(argumentsJson.value);
    }
    if (environmentJson.present) {
      map['environment_json'] = Variable<String>(environmentJson.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (initializationOptionsJson.present) {
      map['initialization_options_json'] = Variable<String>(
        initializationOptionsJson.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LspServerConfigsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('languageId: $languageId, ')
          ..write('command: $command, ')
          ..write('argumentsJson: $argumentsJson, ')
          ..write('environmentJson: $environmentJson, ')
          ..write('enabled: $enabled, ')
          ..write('initializationOptionsJson: $initializationOptionsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CodeChunksTable extends CodeChunks
    with TableInfo<$CodeChunksTable, CodeChunkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CodeChunksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chunkIndexMeta = const VerificationMeta(
    'chunkIndex',
  );
  @override
  late final GeneratedColumn<int> chunkIndex = GeneratedColumn<int>(
    'chunk_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startLineMeta = const VerificationMeta(
    'startLine',
  );
  @override
  late final GeneratedColumn<int> startLine = GeneratedColumn<int>(
    'start_line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endLineMeta = const VerificationMeta(
    'endLine',
  );
  @override
  late final GeneratedColumn<int> endLine = GeneratedColumn<int>(
    'end_line',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageIdMeta = const VerificationMeta(
    'languageId',
  );
  @override
  late final GeneratedColumn<String> languageId = GeneratedColumn<String>(
    'language_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _mtimeMeta = const VerificationMeta('mtime');
  @override
  late final GeneratedColumn<int> mtime = GeneratedColumn<int>(
    'mtime',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<DateTime> indexedAt = GeneratedColumn<DateTime>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    filePath,
    chunkIndex,
    startLine,
    endLine,
    content,
    languageId,
    mtime,
    indexedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'code_chunks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CodeChunkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('chunk_index')) {
      context.handle(
        _chunkIndexMeta,
        chunkIndex.isAcceptableOrUnknown(data['chunk_index']!, _chunkIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_chunkIndexMeta);
    }
    if (data.containsKey('start_line')) {
      context.handle(
        _startLineMeta,
        startLine.isAcceptableOrUnknown(data['start_line']!, _startLineMeta),
      );
    } else if (isInserting) {
      context.missing(_startLineMeta);
    }
    if (data.containsKey('end_line')) {
      context.handle(
        _endLineMeta,
        endLine.isAcceptableOrUnknown(data['end_line']!, _endLineMeta),
      );
    } else if (isInserting) {
      context.missing(_endLineMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('language_id')) {
      context.handle(
        _languageIdMeta,
        languageId.isAcceptableOrUnknown(data['language_id']!, _languageIdMeta),
      );
    }
    if (data.containsKey('mtime')) {
      context.handle(
        _mtimeMeta,
        mtime.isAcceptableOrUnknown(data['mtime']!, _mtimeMeta),
      );
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_indexedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CodeChunkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CodeChunkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      chunkIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chunk_index'],
      )!,
      startLine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_line'],
      )!,
      endLine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_line'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      languageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_id'],
      )!,
      mtime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mtime'],
      )!,
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}indexed_at'],
      )!,
    );
  }

  @override
  $CodeChunksTable createAlias(String alias) {
    return $CodeChunksTable(attachedDatabase, alias);
  }
}

class CodeChunkRow extends DataClass implements Insertable<CodeChunkRow> {
  final int id;
  final String workspaceId;
  final String filePath;
  final int chunkIndex;
  final int startLine;
  final int endLine;
  final String content;
  final String languageId;
  final int mtime;
  final DateTime indexedAt;
  const CodeChunkRow({
    required this.id,
    required this.workspaceId,
    required this.filePath,
    required this.chunkIndex,
    required this.startLine,
    required this.endLine,
    required this.content,
    required this.languageId,
    required this.mtime,
    required this.indexedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['file_path'] = Variable<String>(filePath);
    map['chunk_index'] = Variable<int>(chunkIndex);
    map['start_line'] = Variable<int>(startLine);
    map['end_line'] = Variable<int>(endLine);
    map['content'] = Variable<String>(content);
    map['language_id'] = Variable<String>(languageId);
    map['mtime'] = Variable<int>(mtime);
    map['indexed_at'] = Variable<DateTime>(indexedAt);
    return map;
  }

  CodeChunksCompanion toCompanion(bool nullToAbsent) {
    return CodeChunksCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      filePath: Value(filePath),
      chunkIndex: Value(chunkIndex),
      startLine: Value(startLine),
      endLine: Value(endLine),
      content: Value(content),
      languageId: Value(languageId),
      mtime: Value(mtime),
      indexedAt: Value(indexedAt),
    );
  }

  factory CodeChunkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CodeChunkRow(
      id: serializer.fromJson<int>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      chunkIndex: serializer.fromJson<int>(json['chunkIndex']),
      startLine: serializer.fromJson<int>(json['startLine']),
      endLine: serializer.fromJson<int>(json['endLine']),
      content: serializer.fromJson<String>(json['content']),
      languageId: serializer.fromJson<String>(json['languageId']),
      mtime: serializer.fromJson<int>(json['mtime']),
      indexedAt: serializer.fromJson<DateTime>(json['indexedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'filePath': serializer.toJson<String>(filePath),
      'chunkIndex': serializer.toJson<int>(chunkIndex),
      'startLine': serializer.toJson<int>(startLine),
      'endLine': serializer.toJson<int>(endLine),
      'content': serializer.toJson<String>(content),
      'languageId': serializer.toJson<String>(languageId),
      'mtime': serializer.toJson<int>(mtime),
      'indexedAt': serializer.toJson<DateTime>(indexedAt),
    };
  }

  CodeChunkRow copyWith({
    int? id,
    String? workspaceId,
    String? filePath,
    int? chunkIndex,
    int? startLine,
    int? endLine,
    String? content,
    String? languageId,
    int? mtime,
    DateTime? indexedAt,
  }) => CodeChunkRow(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    filePath: filePath ?? this.filePath,
    chunkIndex: chunkIndex ?? this.chunkIndex,
    startLine: startLine ?? this.startLine,
    endLine: endLine ?? this.endLine,
    content: content ?? this.content,
    languageId: languageId ?? this.languageId,
    mtime: mtime ?? this.mtime,
    indexedAt: indexedAt ?? this.indexedAt,
  );
  CodeChunkRow copyWithCompanion(CodeChunksCompanion data) {
    return CodeChunkRow(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      chunkIndex: data.chunkIndex.present
          ? data.chunkIndex.value
          : this.chunkIndex,
      startLine: data.startLine.present ? data.startLine.value : this.startLine,
      endLine: data.endLine.present ? data.endLine.value : this.endLine,
      content: data.content.present ? data.content.value : this.content,
      languageId: data.languageId.present
          ? data.languageId.value
          : this.languageId,
      mtime: data.mtime.present ? data.mtime.value : this.mtime,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CodeChunkRow(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('filePath: $filePath, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('startLine: $startLine, ')
          ..write('endLine: $endLine, ')
          ..write('content: $content, ')
          ..write('languageId: $languageId, ')
          ..write('mtime: $mtime, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    filePath,
    chunkIndex,
    startLine,
    endLine,
    content,
    languageId,
    mtime,
    indexedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CodeChunkRow &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.filePath == this.filePath &&
          other.chunkIndex == this.chunkIndex &&
          other.startLine == this.startLine &&
          other.endLine == this.endLine &&
          other.content == this.content &&
          other.languageId == this.languageId &&
          other.mtime == this.mtime &&
          other.indexedAt == this.indexedAt);
}

class CodeChunksCompanion extends UpdateCompanion<CodeChunkRow> {
  final Value<int> id;
  final Value<String> workspaceId;
  final Value<String> filePath;
  final Value<int> chunkIndex;
  final Value<int> startLine;
  final Value<int> endLine;
  final Value<String> content;
  final Value<String> languageId;
  final Value<int> mtime;
  final Value<DateTime> indexedAt;
  const CodeChunksCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.chunkIndex = const Value.absent(),
    this.startLine = const Value.absent(),
    this.endLine = const Value.absent(),
    this.content = const Value.absent(),
    this.languageId = const Value.absent(),
    this.mtime = const Value.absent(),
    this.indexedAt = const Value.absent(),
  });
  CodeChunksCompanion.insert({
    this.id = const Value.absent(),
    required String workspaceId,
    required String filePath,
    required int chunkIndex,
    required int startLine,
    required int endLine,
    required String content,
    this.languageId = const Value.absent(),
    this.mtime = const Value.absent(),
    required DateTime indexedAt,
  }) : workspaceId = Value(workspaceId),
       filePath = Value(filePath),
       chunkIndex = Value(chunkIndex),
       startLine = Value(startLine),
       endLine = Value(endLine),
       content = Value(content),
       indexedAt = Value(indexedAt);
  static Insertable<CodeChunkRow> custom({
    Expression<int>? id,
    Expression<String>? workspaceId,
    Expression<String>? filePath,
    Expression<int>? chunkIndex,
    Expression<int>? startLine,
    Expression<int>? endLine,
    Expression<String>? content,
    Expression<String>? languageId,
    Expression<int>? mtime,
    Expression<DateTime>? indexedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (filePath != null) 'file_path': filePath,
      if (chunkIndex != null) 'chunk_index': chunkIndex,
      if (startLine != null) 'start_line': startLine,
      if (endLine != null) 'end_line': endLine,
      if (content != null) 'content': content,
      if (languageId != null) 'language_id': languageId,
      if (mtime != null) 'mtime': mtime,
      if (indexedAt != null) 'indexed_at': indexedAt,
    });
  }

  CodeChunksCompanion copyWith({
    Value<int>? id,
    Value<String>? workspaceId,
    Value<String>? filePath,
    Value<int>? chunkIndex,
    Value<int>? startLine,
    Value<int>? endLine,
    Value<String>? content,
    Value<String>? languageId,
    Value<int>? mtime,
    Value<DateTime>? indexedAt,
  }) {
    return CodeChunksCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      filePath: filePath ?? this.filePath,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      content: content ?? this.content,
      languageId: languageId ?? this.languageId,
      mtime: mtime ?? this.mtime,
      indexedAt: indexedAt ?? this.indexedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (chunkIndex.present) {
      map['chunk_index'] = Variable<int>(chunkIndex.value);
    }
    if (startLine.present) {
      map['start_line'] = Variable<int>(startLine.value);
    }
    if (endLine.present) {
      map['end_line'] = Variable<int>(endLine.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (languageId.present) {
      map['language_id'] = Variable<String>(languageId.value);
    }
    if (mtime.present) {
      map['mtime'] = Variable<int>(mtime.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<DateTime>(indexedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CodeChunksCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('filePath: $filePath, ')
          ..write('chunkIndex: $chunkIndex, ')
          ..write('startLine: $startLine, ')
          ..write('endLine: $endLine, ')
          ..write('content: $content, ')
          ..write('languageId: $languageId, ')
          ..write('mtime: $mtime, ')
          ..write('indexedAt: $indexedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorkspacesTable workspaces = $WorkspacesTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $ProviderConfigsTable providerConfigs = $ProviderConfigsTable(
    this,
  );
  late final $MemoryNotesTable memoryNotes = $MemoryNotesTable(this);
  late final $RuntimeConfigsTable runtimeConfigs = $RuntimeConfigsTable(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $DocumentSectionsTable documentSections = $DocumentSectionsTable(
    this,
  );
  late final $McpServersTable mcpServers = $McpServersTable(this);
  late final $LspServerConfigsTable lspServerConfigs = $LspServerConfigsTable(
    this,
  );
  late final $CodeChunksTable codeChunks = $CodeChunksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workspaces,
    sessions,
    messages,
    providerConfigs,
    memoryNotes,
    runtimeConfigs,
    documents,
    documentSections,
    mcpServers,
    lspServerConfigs,
    codeChunks,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('messages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('documents', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('document_sections', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('mcp_servers', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lsp_server_configs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('code_chunks', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$WorkspacesTableCreateCompanionBuilder =
    WorkspacesCompanion Function({
      required String id,
      required String name,
      required String rootDirectory,
      Value<String> runtimeId,
      required DateTime createdAt,
      Value<String> settingsJson,
      Value<int> rowid,
    });
typedef $$WorkspacesTableUpdateCompanionBuilder =
    WorkspacesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> rootDirectory,
      Value<String> runtimeId,
      Value<DateTime> createdAt,
      Value<String> settingsJson,
      Value<int> rowid,
    });

final class $$WorkspacesTableReferences
    extends BaseReferences<_$AppDatabase, $WorkspacesTable, WorkspaceRow> {
  $$WorkspacesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<SessionRow>>
  _sessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: 'workspaces__id__sessions__workspace_id',
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DocumentsTable, List<DocumentRow>>
  _documentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.documents,
    aliasName: 'workspaces__id__documents__workspace_id',
  );

  $$DocumentsTableProcessedTableManager get documentsRefs {
    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_documentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$McpServersTable, List<McpServerRow>>
  _mcpServersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mcpServers,
    aliasName: 'workspaces__id__mcp_servers__workspace_id',
  );

  $$McpServersTableProcessedTableManager get mcpServersRefs {
    final manager = $$McpServersTableTableManager(
      $_db,
      $_db.mcpServers,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mcpServersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LspServerConfigsTable, List<LspServerConfigRow>>
  _lspServerConfigsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lspServerConfigs,
    aliasName: 'workspaces__id__lsp_server_configs__workspace_id',
  );

  $$LspServerConfigsTableProcessedTableManager get lspServerConfigsRefs {
    final manager = $$LspServerConfigsTableTableManager(
      $_db,
      $_db.lspServerConfigs,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _lspServerConfigsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CodeChunksTable, List<CodeChunkRow>>
  _codeChunksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.codeChunks,
    aliasName: 'workspaces__id__code_chunks__workspace_id',
  );

  $$CodeChunksTableProcessedTableManager get codeChunksRefs {
    final manager = $$CodeChunksTableTableManager(
      $_db,
      $_db.codeChunks,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_codeChunksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkspacesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootDirectory => $composableBuilder(
    column: $table.rootDirectory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runtimeId => $composableBuilder(
    column: $table.runtimeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> documentsRefs(
    Expression<bool> Function($$DocumentsTableFilterComposer f) f,
  ) {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mcpServersRefs(
    Expression<bool> Function($$McpServersTableFilterComposer f) f,
  ) {
    final $$McpServersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mcpServers,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$McpServersTableFilterComposer(
            $db: $db,
            $table: $db.mcpServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lspServerConfigsRefs(
    Expression<bool> Function($$LspServerConfigsTableFilterComposer f) f,
  ) {
    final $$LspServerConfigsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lspServerConfigs,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LspServerConfigsTableFilterComposer(
            $db: $db,
            $table: $db.lspServerConfigs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> codeChunksRefs(
    Expression<bool> Function($$CodeChunksTableFilterComposer f) f,
  ) {
    final $$CodeChunksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.codeChunks,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CodeChunksTableFilterComposer(
            $db: $db,
            $table: $db.codeChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkspacesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootDirectory => $composableBuilder(
    column: $table.rootDirectory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runtimeId => $composableBuilder(
    column: $table.runtimeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkspacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get rootDirectory => $composableBuilder(
    column: $table.rootDirectory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get runtimeId =>
      $composableBuilder(column: $table.runtimeId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => column,
  );

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> documentsRefs<T extends Object>(
    Expression<T> Function($$DocumentsTableAnnotationComposer a) f,
  ) {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mcpServersRefs<T extends Object>(
    Expression<T> Function($$McpServersTableAnnotationComposer a) f,
  ) {
    final $$McpServersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mcpServers,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$McpServersTableAnnotationComposer(
            $db: $db,
            $table: $db.mcpServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lspServerConfigsRefs<T extends Object>(
    Expression<T> Function($$LspServerConfigsTableAnnotationComposer a) f,
  ) {
    final $$LspServerConfigsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lspServerConfigs,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LspServerConfigsTableAnnotationComposer(
            $db: $db,
            $table: $db.lspServerConfigs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> codeChunksRefs<T extends Object>(
    Expression<T> Function($$CodeChunksTableAnnotationComposer a) f,
  ) {
    final $$CodeChunksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.codeChunks,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CodeChunksTableAnnotationComposer(
            $db: $db,
            $table: $db.codeChunks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkspacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkspacesTable,
          WorkspaceRow,
          $$WorkspacesTableFilterComposer,
          $$WorkspacesTableOrderingComposer,
          $$WorkspacesTableAnnotationComposer,
          $$WorkspacesTableCreateCompanionBuilder,
          $$WorkspacesTableUpdateCompanionBuilder,
          (WorkspaceRow, $$WorkspacesTableReferences),
          WorkspaceRow,
          PrefetchHooks Function({
            bool sessionsRefs,
            bool documentsRefs,
            bool mcpServersRefs,
            bool lspServerConfigsRefs,
            bool codeChunksRefs,
          })
        > {
  $$WorkspacesTableTableManager(_$AppDatabase db, $WorkspacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkspacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> rootDirectory = const Value.absent(),
                Value<String> runtimeId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> settingsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion(
                id: id,
                name: name,
                rootDirectory: rootDirectory,
                runtimeId: runtimeId,
                createdAt: createdAt,
                settingsJson: settingsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String rootDirectory,
                Value<String> runtimeId = const Value.absent(),
                required DateTime createdAt,
                Value<String> settingsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion.insert(
                id: id,
                name: name,
                rootDirectory: rootDirectory,
                runtimeId: runtimeId,
                createdAt: createdAt,
                settingsJson: settingsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkspacesTable, WorkspaceRow>(table),
                  $$WorkspacesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sessionsRefs = false,
                documentsRefs = false,
                mcpServersRefs = false,
                lspServerConfigsRefs = false,
                codeChunksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionsRefs) db.sessions,
                    if (documentsRefs) db.documents,
                    if (mcpServersRefs) db.mcpServers,
                    if (lspServerConfigsRefs) db.lspServerConfigs,
                    if (codeChunksRefs) db.codeChunks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionsRefs)
                        await $_getPrefetchedData<
                          WorkspaceRow,
                          $WorkspacesTable,
                          SessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._sessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (documentsRefs)
                        await $_getPrefetchedData<
                          WorkspaceRow,
                          $WorkspacesTable,
                          DocumentRow
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._documentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).documentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (mcpServersRefs)
                        await $_getPrefetchedData<
                          WorkspaceRow,
                          $WorkspacesTable,
                          McpServerRow
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._mcpServersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).mcpServersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lspServerConfigsRefs)
                        await $_getPrefetchedData<
                          WorkspaceRow,
                          $WorkspacesTable,
                          LspServerConfigRow
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._lspServerConfigsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).lspServerConfigsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (codeChunksRefs)
                        await $_getPrefetchedData<
                          WorkspaceRow,
                          $WorkspacesTable,
                          CodeChunkRow
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._codeChunksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).codeChunksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workspaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkspacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkspacesTable,
      WorkspaceRow,
      $$WorkspacesTableFilterComposer,
      $$WorkspacesTableOrderingComposer,
      $$WorkspacesTableAnnotationComposer,
      $$WorkspacesTableCreateCompanionBuilder,
      $$WorkspacesTableUpdateCompanionBuilder,
      (WorkspaceRow, $$WorkspacesTableReferences),
      WorkspaceRow,
      PrefetchHooks Function({
        bool sessionsRefs,
        bool documentsRefs,
        bool mcpServersRefs,
        bool lspServerConfigsRefs,
        bool codeChunksRefs,
      })
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required String workspaceId,
      Value<String> title,
      Value<String> status,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> title,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('sessions__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MessagesTable, List<MessageRow>>
  _messagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: 'sessions__id__messages__session_id',
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({bool workspaceId, bool messagesRefs})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                workspaceId: workspaceId,
                title: title,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                Value<String> title = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                title: title,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, SessionRow>(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false, messagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (messagesRefs) db.messages],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workspaceId,
                                referencedTable: $$SessionsTableReferences
                                    ._workspaceIdTable(db),
                                referencedColumn: $$SessionsTableReferences
                                    ._workspaceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messagesRefs)
                    await $_getPrefetchedData<
                      SessionRow,
                      $SessionsTable,
                      MessageRow
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._messagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SessionsTableReferences(db, table, p0).messagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({bool workspaceId, bool messagesRefs})
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      required String sessionId,
      required int seq,
      required String role,
      Value<String> content,
      Value<String?> toolCallsJson,
      Value<String?> toolCallId,
      Value<String?> name,
      Value<bool> isError,
      Value<String?> dataJson,
      required DateTime createdAt,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      Value<String> sessionId,
      Value<int> seq,
      Value<String> role,
      Value<String> content,
      Value<String?> toolCallsJson,
      Value<String?> toolCallId,
      Value<String?> name,
      Value<bool> isError,
      Value<String?> dataJson,
      Value<DateTime> createdAt,
    });

final class $$MessagesTableReferences
    extends BaseReferences<_$AppDatabase, $MessagesTable, MessageRow> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('messages__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolCallsJson => $composableBuilder(
    column: $table.toolCallsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolCallId => $composableBuilder(
    column: $table.toolCallId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isError => $composableBuilder(
    column: $table.isError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolCallsJson => $composableBuilder(
    column: $table.toolCallsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolCallId => $composableBuilder(
    column: $table.toolCallId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isError => $composableBuilder(
    column: $table.isError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get toolCallsJson => $composableBuilder(
    column: $table.toolCallsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toolCallId => $composableBuilder(
    column: $table.toolCallId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isError =>
      $composableBuilder(column: $table.isError, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          MessageRow,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (MessageRow, $$MessagesTableReferences),
          MessageRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> toolCallsJson = const Value.absent(),
                Value<String?> toolCallId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<bool> isError = const Value.absent(),
                Value<String?> dataJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                sessionId: sessionId,
                seq: seq,
                role: role,
                content: content,
                toolCallsJson: toolCallsJson,
                toolCallId: toolCallId,
                name: name,
                isError: isError,
                dataJson: dataJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required int seq,
                required String role,
                Value<String> content = const Value.absent(),
                Value<String?> toolCallsJson = const Value.absent(),
                Value<String?> toolCallId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<bool> isError = const Value.absent(),
                Value<String?> dataJson = const Value.absent(),
                required DateTime createdAt,
              }) => MessagesCompanion.insert(
                id: id,
                sessionId: sessionId,
                seq: seq,
                role: role,
                content: content,
                toolCallsJson: toolCallsJson,
                toolCallId: toolCallId,
                name: name,
                isError: isError,
                dataJson: dataJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessagesTable, MessageRow>(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$MessagesTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$MessagesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      MessageRow,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (MessageRow, $$MessagesTableReferences),
      MessageRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$ProviderConfigsTableCreateCompanionBuilder =
    ProviderConfigsCompanion Function({
      required String id,
      required String label,
      required String provider,
      required String model,
      required String baseUrl,
      Value<String> apiKey,
      Value<double> temperature,
      Value<int> maxTokens,
      Value<int> contextWindow,
      Value<bool> isDefault,
      Value<int> rowid,
    });
typedef $$ProviderConfigsTableUpdateCompanionBuilder =
    ProviderConfigsCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<String> provider,
      Value<String> model,
      Value<String> baseUrl,
      Value<String> apiKey,
      Value<double> temperature,
      Value<int> maxTokens,
      Value<int> contextWindow,
      Value<bool> isDefault,
      Value<int> rowid,
    });

class $$ProviderConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxTokens => $composableBuilder(
    column: $table.maxTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contextWindow => $composableBuilder(
    column: $table.contextWindow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxTokens => $composableBuilder(
    column: $table.maxTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contextWindow => $composableBuilder(
    column: $table.contextWindow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxTokens =>
      $composableBuilder(column: $table.maxTokens, builder: (column) => column);

  GeneratedColumn<int> get contextWindow => $composableBuilder(
    column: $table.contextWindow,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$ProviderConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProviderConfigsTable,
          ProviderRow,
          $$ProviderConfigsTableFilterComposer,
          $$ProviderConfigsTableOrderingComposer,
          $$ProviderConfigsTableAnnotationComposer,
          $$ProviderConfigsTableCreateCompanionBuilder,
          $$ProviderConfigsTableUpdateCompanionBuilder,
          (
            ProviderRow,
            BaseReferences<_$AppDatabase, $ProviderConfigsTable, ProviderRow>,
          ),
          ProviderRow,
          PrefetchHooks Function()
        > {
  $$ProviderConfigsTableTableManager(
    _$AppDatabase db,
    $ProviderConfigsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String> apiKey = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<int> maxTokens = const Value.absent(),
                Value<int> contextWindow = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderConfigsCompanion(
                id: id,
                label: label,
                provider: provider,
                model: model,
                baseUrl: baseUrl,
                apiKey: apiKey,
                temperature: temperature,
                maxTokens: maxTokens,
                contextWindow: contextWindow,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required String provider,
                required String model,
                required String baseUrl,
                Value<String> apiKey = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<int> maxTokens = const Value.absent(),
                Value<int> contextWindow = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderConfigsCompanion.insert(
                id: id,
                label: label,
                provider: provider,
                model: model,
                baseUrl: baseUrl,
                apiKey: apiKey,
                temperature: temperature,
                maxTokens: maxTokens,
                contextWindow: contextWindow,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProviderConfigsTable, ProviderRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProviderConfigsTable,
                    ProviderRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProviderConfigsTable,
      ProviderRow,
      $$ProviderConfigsTableFilterComposer,
      $$ProviderConfigsTableOrderingComposer,
      $$ProviderConfigsTableAnnotationComposer,
      $$ProviderConfigsTableCreateCompanionBuilder,
      $$ProviderConfigsTableUpdateCompanionBuilder,
      (
        ProviderRow,
        BaseReferences<_$AppDatabase, $ProviderConfigsTable, ProviderRow>,
      ),
      ProviderRow,
      PrefetchHooks Function()
    >;
typedef $$MemoryNotesTableCreateCompanionBuilder =
    MemoryNotesCompanion Function({
      required String id,
      required String workspaceId,
      required String content,
      Value<String> tagsJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MemoryNotesTableUpdateCompanionBuilder =
    MemoryNotesCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> content,
      Value<String> tagsJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MemoryNotesTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryNotesTable> {
  $$MemoryNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoryNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryNotesTable> {
  $$MemoryNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoryNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryNotesTable> {
  $$MemoryNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workspaceId => $composableBuilder(
    column: $table.workspaceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MemoryNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoryNotesTable,
          MemoryRow,
          $$MemoryNotesTableFilterComposer,
          $$MemoryNotesTableOrderingComposer,
          $$MemoryNotesTableAnnotationComposer,
          $$MemoryNotesTableCreateCompanionBuilder,
          $$MemoryNotesTableUpdateCompanionBuilder,
          (
            MemoryRow,
            BaseReferences<_$AppDatabase, $MemoryNotesTable, MemoryRow>,
          ),
          MemoryRow,
          PrefetchHooks Function()
        > {
  $$MemoryNotesTableTableManager(_$AppDatabase db, $MemoryNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryNotesCompanion(
                id: id,
                workspaceId: workspaceId,
                content: content,
                tagsJson: tagsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String content,
                Value<String> tagsJson = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MemoryNotesCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                content: content,
                tagsJson: tagsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MemoryNotesTable, MemoryRow>(table),
                  BaseReferences<_$AppDatabase, $MemoryNotesTable, MemoryRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoryNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoryNotesTable,
      MemoryRow,
      $$MemoryNotesTableFilterComposer,
      $$MemoryNotesTableOrderingComposer,
      $$MemoryNotesTableAnnotationComposer,
      $$MemoryNotesTableCreateCompanionBuilder,
      $$MemoryNotesTableUpdateCompanionBuilder,
      (MemoryRow, BaseReferences<_$AppDatabase, $MemoryNotesTable, MemoryRow>),
      MemoryRow,
      PrefetchHooks Function()
    >;
typedef $$RuntimeConfigsTableCreateCompanionBuilder =
    RuntimeConfigsCompanion Function({
      required String id,
      required String label,
      required String kind,
      Value<String> optionsJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$RuntimeConfigsTableUpdateCompanionBuilder =
    RuntimeConfigsCompanion Function({
      Value<String> id,
      Value<String> label,
      Value<String> kind,
      Value<String> optionsJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$RuntimeConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $RuntimeConfigsTable> {
  $$RuntimeConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RuntimeConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $RuntimeConfigsTable> {
  $$RuntimeConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RuntimeConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RuntimeConfigsTable> {
  $$RuntimeConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RuntimeConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RuntimeConfigsTable,
          RuntimeConfigRow,
          $$RuntimeConfigsTableFilterComposer,
          $$RuntimeConfigsTableOrderingComposer,
          $$RuntimeConfigsTableAnnotationComposer,
          $$RuntimeConfigsTableCreateCompanionBuilder,
          $$RuntimeConfigsTableUpdateCompanionBuilder,
          (
            RuntimeConfigRow,
            BaseReferences<
              _$AppDatabase,
              $RuntimeConfigsTable,
              RuntimeConfigRow
            >,
          ),
          RuntimeConfigRow,
          PrefetchHooks Function()
        > {
  $$RuntimeConfigsTableTableManager(
    _$AppDatabase db,
    $RuntimeConfigsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RuntimeConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RuntimeConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RuntimeConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> optionsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuntimeConfigsCompanion(
                id: id,
                label: label,
                kind: kind,
                optionsJson: optionsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String label,
                required String kind,
                Value<String> optionsJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RuntimeConfigsCompanion.insert(
                id: id,
                label: label,
                kind: kind,
                optionsJson: optionsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RuntimeConfigsTable, RuntimeConfigRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RuntimeConfigsTable,
                    RuntimeConfigRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RuntimeConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RuntimeConfigsTable,
      RuntimeConfigRow,
      $$RuntimeConfigsTableFilterComposer,
      $$RuntimeConfigsTableOrderingComposer,
      $$RuntimeConfigsTableAnnotationComposer,
      $$RuntimeConfigsTableCreateCompanionBuilder,
      $$RuntimeConfigsTableUpdateCompanionBuilder,
      (
        RuntimeConfigRow,
        BaseReferences<_$AppDatabase, $RuntimeConfigsTable, RuntimeConfigRow>,
      ),
      RuntimeConfigRow,
      PrefetchHooks Function()
    >;
typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      required String id,
      required String workspaceId,
      required String displayName,
      required String sourceUri,
      required String localPath,
      required String type,
      Value<String> mimeType,
      Value<int> fileSize,
      Value<String> contentHash,
      Value<String> title,
      Value<String> author,
      Value<String> language,
      Value<int> pageCount,
      Value<int> sectionCount,
      Value<String> parseStatus,
      Value<String?> parseError,
      Value<int?> lastSectionIndex,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> displayName,
      Value<String> sourceUri,
      Value<String> localPath,
      Value<String> type,
      Value<String> mimeType,
      Value<int> fileSize,
      Value<String> contentHash,
      Value<String> title,
      Value<String> author,
      Value<String> language,
      Value<int> pageCount,
      Value<int> sectionCount,
      Value<String> parseStatus,
      Value<String?> parseError,
      Value<int?> lastSectionIndex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DocumentsTableReferences
    extends BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow> {
  $$DocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('documents__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DocumentSectionsTable, List<DocumentSectionRow>>
  _documentSectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.documentSections,
    aliasName: 'documents__id__document_sections__document_id',
  );

  $$DocumentSectionsTableProcessedTableManager get documentSectionsRefs {
    final manager = $$DocumentSectionsTableTableManager(
      $_db,
      $_db.documentSections,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _documentSectionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUri => $composableBuilder(
    column: $table.sourceUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sectionCount => $composableBuilder(
    column: $table.sectionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parseStatus => $composableBuilder(
    column: $table.parseStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parseError => $composableBuilder(
    column: $table.parseError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSectionIndex => $composableBuilder(
    column: $table.lastSectionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> documentSectionsRefs(
    Expression<bool> Function($$DocumentSectionsTableFilterComposer f) f,
  ) {
    final $$DocumentSectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documentSections,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentSectionsTableFilterComposer(
            $db: $db,
            $table: $db.documentSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUri => $composableBuilder(
    column: $table.sourceUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sectionCount => $composableBuilder(
    column: $table.sectionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parseStatus => $composableBuilder(
    column: $table.parseStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parseError => $composableBuilder(
    column: $table.parseError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSectionIndex => $composableBuilder(
    column: $table.lastSectionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUri =>
      $composableBuilder(column: $table.sourceUri, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<int> get sectionCount => $composableBuilder(
    column: $table.sectionCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parseStatus => $composableBuilder(
    column: $table.parseStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parseError => $composableBuilder(
    column: $table.parseError,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSectionIndex => $composableBuilder(
    column: $table.lastSectionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> documentSectionsRefs<T extends Object>(
    Expression<T> Function($$DocumentSectionsTableAnnotationComposer a) f,
  ) {
    final $$DocumentSectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.documentSections,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentSectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.documentSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          DocumentRow,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (DocumentRow, $$DocumentsTableReferences),
          DocumentRow,
          PrefetchHooks Function({bool workspaceId, bool documentSectionsRefs})
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> sourceUri = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<int> sectionCount = const Value.absent(),
                Value<String> parseStatus = const Value.absent(),
                Value<String?> parseError = const Value.absent(),
                Value<int?> lastSectionIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                workspaceId: workspaceId,
                displayName: displayName,
                sourceUri: sourceUri,
                localPath: localPath,
                type: type,
                mimeType: mimeType,
                fileSize: fileSize,
                contentHash: contentHash,
                title: title,
                author: author,
                language: language,
                pageCount: pageCount,
                sectionCount: sectionCount,
                parseStatus: parseStatus,
                parseError: parseError,
                lastSectionIndex: lastSectionIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String displayName,
                required String sourceUri,
                required String localPath,
                required String type,
                Value<String> mimeType = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<int> sectionCount = const Value.absent(),
                Value<String> parseStatus = const Value.absent(),
                Value<String?> parseError = const Value.absent(),
                Value<int?> lastSectionIndex = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                displayName: displayName,
                sourceUri: sourceUri,
                localPath: localPath,
                type: type,
                mimeType: mimeType,
                fileSize: fileSize,
                contentHash: contentHash,
                title: title,
                author: author,
                language: language,
                pageCount: pageCount,
                sectionCount: sectionCount,
                parseStatus: parseStatus,
                parseError: parseError,
                lastSectionIndex: lastSectionIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentsTable, DocumentRow>(table),
                  $$DocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workspaceId = false, documentSectionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (documentSectionsRefs) db.documentSections,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable: $$DocumentsTableReferences
                                        ._workspaceIdTable(db),
                                    referencedColumn: $$DocumentsTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (documentSectionsRefs)
                        await $_getPrefetchedData<
                          DocumentRow,
                          $DocumentsTable,
                          DocumentSectionRow
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._documentSectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).documentSectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.documentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      DocumentRow,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (DocumentRow, $$DocumentsTableReferences),
      DocumentRow,
      PrefetchHooks Function({bool workspaceId, bool documentSectionsRefs})
    >;
typedef $$DocumentSectionsTableCreateCompanionBuilder =
    DocumentSectionsCompanion Function({
      required String id,
      required String documentId,
      required int sectionIndex,
      Value<String?> parentSectionId,
      required String kind,
      Value<String> title,
      required String locator,
      Value<String> plainText,
      Value<int> charCount,
      Value<String> metadataJson,
      Value<int> rowid,
    });
typedef $$DocumentSectionsTableUpdateCompanionBuilder =
    DocumentSectionsCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<int> sectionIndex,
      Value<String?> parentSectionId,
      Value<String> kind,
      Value<String> title,
      Value<String> locator,
      Value<String> plainText,
      Value<int> charCount,
      Value<String> metadataJson,
      Value<int> rowid,
    });

final class $$DocumentSectionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DocumentSectionsTable,
          DocumentSectionRow
        > {
  $$DocumentSectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.documents.createAlias('document_sections__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DocumentSectionsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentSectionsTable> {
  $$DocumentSectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentSectionId => $composableBuilder(
    column: $table.parentSectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locator => $composableBuilder(
    column: $table.locator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plainText => $composableBuilder(
    column: $table.plainText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get charCount => $composableBuilder(
    column: $table.charCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentSectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentSectionsTable> {
  $$DocumentSectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentSectionId => $composableBuilder(
    column: $table.parentSectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locator => $composableBuilder(
    column: $table.locator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plainText => $composableBuilder(
    column: $table.plainText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get charCount => $composableBuilder(
    column: $table.charCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentSectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentSectionsTable> {
  $$DocumentSectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentSectionId => $composableBuilder(
    column: $table.parentSectionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get locator =>
      $composableBuilder(column: $table.locator, builder: (column) => column);

  GeneratedColumn<String> get plainText =>
      $composableBuilder(column: $table.plainText, builder: (column) => column);

  GeneratedColumn<int> get charCount =>
      $composableBuilder(column: $table.charCount, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DocumentSectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentSectionsTable,
          DocumentSectionRow,
          $$DocumentSectionsTableFilterComposer,
          $$DocumentSectionsTableOrderingComposer,
          $$DocumentSectionsTableAnnotationComposer,
          $$DocumentSectionsTableCreateCompanionBuilder,
          $$DocumentSectionsTableUpdateCompanionBuilder,
          (DocumentSectionRow, $$DocumentSectionsTableReferences),
          DocumentSectionRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$DocumentSectionsTableTableManager(
    _$AppDatabase db,
    $DocumentSectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentSectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentSectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentSectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int> sectionIndex = const Value.absent(),
                Value<String?> parentSectionId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> locator = const Value.absent(),
                Value<String> plainText = const Value.absent(),
                Value<int> charCount = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentSectionsCompanion(
                id: id,
                documentId: documentId,
                sectionIndex: sectionIndex,
                parentSectionId: parentSectionId,
                kind: kind,
                title: title,
                locator: locator,
                plainText: plainText,
                charCount: charCount,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required int sectionIndex,
                Value<String?> parentSectionId = const Value.absent(),
                required String kind,
                Value<String> title = const Value.absent(),
                required String locator,
                Value<String> plainText = const Value.absent(),
                Value<int> charCount = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentSectionsCompanion.insert(
                id: id,
                documentId: documentId,
                sectionIndex: sectionIndex,
                parentSectionId: parentSectionId,
                kind: kind,
                title: title,
                locator: locator,
                plainText: plainText,
                charCount: charCount,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentSectionsTable, DocumentSectionRow>(
                    table,
                  ),
                  $$DocumentSectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (documentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.documentId,
                                referencedTable:
                                    $$DocumentSectionsTableReferences
                                        ._documentIdTable(db),
                                referencedColumn:
                                    $$DocumentSectionsTableReferences
                                        ._documentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DocumentSectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentSectionsTable,
      DocumentSectionRow,
      $$DocumentSectionsTableFilterComposer,
      $$DocumentSectionsTableOrderingComposer,
      $$DocumentSectionsTableAnnotationComposer,
      $$DocumentSectionsTableCreateCompanionBuilder,
      $$DocumentSectionsTableUpdateCompanionBuilder,
      (DocumentSectionRow, $$DocumentSectionsTableReferences),
      DocumentSectionRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$McpServersTableCreateCompanionBuilder =
    McpServersCompanion Function({
      required String id,
      required String workspaceId,
      required String name,
      required String transport,
      Value<String> endpoint,
      Value<String> command,
      Value<String> argumentsJson,
      Value<String> environmentJson,
      Value<String> headersJson,
      Value<String?> runtimeConfigId,
      Value<bool> enabled,
      Value<bool> autoConnect,
      Value<int> connectionTimeoutMs,
      Value<int> toolTimeoutMs,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$McpServersTableUpdateCompanionBuilder =
    McpServersCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> name,
      Value<String> transport,
      Value<String> endpoint,
      Value<String> command,
      Value<String> argumentsJson,
      Value<String> environmentJson,
      Value<String> headersJson,
      Value<String?> runtimeConfigId,
      Value<bool> enabled,
      Value<bool> autoConnect,
      Value<int> connectionTimeoutMs,
      Value<int> toolTimeoutMs,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$McpServersTableReferences
    extends BaseReferences<_$AppDatabase, $McpServersTable, McpServerRow> {
  $$McpServersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('mcp_servers__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$McpServersTableFilterComposer
    extends Composer<_$AppDatabase, $McpServersTable> {
  $$McpServersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transport => $composableBuilder(
    column: $table.transport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get argumentsJson => $composableBuilder(
    column: $table.argumentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentJson => $composableBuilder(
    column: $table.environmentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runtimeConfigId => $composableBuilder(
    column: $table.runtimeConfigId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoConnect => $composableBuilder(
    column: $table.autoConnect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get connectionTimeoutMs => $composableBuilder(
    column: $table.connectionTimeoutMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toolTimeoutMs => $composableBuilder(
    column: $table.toolTimeoutMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$McpServersTableOrderingComposer
    extends Composer<_$AppDatabase, $McpServersTable> {
  $$McpServersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transport => $composableBuilder(
    column: $table.transport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get argumentsJson => $composableBuilder(
    column: $table.argumentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentJson => $composableBuilder(
    column: $table.environmentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runtimeConfigId => $composableBuilder(
    column: $table.runtimeConfigId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoConnect => $composableBuilder(
    column: $table.autoConnect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get connectionTimeoutMs => $composableBuilder(
    column: $table.connectionTimeoutMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toolTimeoutMs => $composableBuilder(
    column: $table.toolTimeoutMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$McpServersTableAnnotationComposer
    extends Composer<_$AppDatabase, $McpServersTable> {
  $$McpServersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get transport =>
      $composableBuilder(column: $table.transport, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get command =>
      $composableBuilder(column: $table.command, builder: (column) => column);

  GeneratedColumn<String> get argumentsJson => $composableBuilder(
    column: $table.argumentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get environmentJson => $composableBuilder(
    column: $table.environmentJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get runtimeConfigId => $composableBuilder(
    column: $table.runtimeConfigId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get autoConnect => $composableBuilder(
    column: $table.autoConnect,
    builder: (column) => column,
  );

  GeneratedColumn<int> get connectionTimeoutMs => $composableBuilder(
    column: $table.connectionTimeoutMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get toolTimeoutMs => $composableBuilder(
    column: $table.toolTimeoutMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$McpServersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $McpServersTable,
          McpServerRow,
          $$McpServersTableFilterComposer,
          $$McpServersTableOrderingComposer,
          $$McpServersTableAnnotationComposer,
          $$McpServersTableCreateCompanionBuilder,
          $$McpServersTableUpdateCompanionBuilder,
          (McpServerRow, $$McpServersTableReferences),
          McpServerRow,
          PrefetchHooks Function({bool workspaceId})
        > {
  $$McpServersTableTableManager(_$AppDatabase db, $McpServersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$McpServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$McpServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$McpServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> transport = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> command = const Value.absent(),
                Value<String> argumentsJson = const Value.absent(),
                Value<String> environmentJson = const Value.absent(),
                Value<String> headersJson = const Value.absent(),
                Value<String?> runtimeConfigId = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> autoConnect = const Value.absent(),
                Value<int> connectionTimeoutMs = const Value.absent(),
                Value<int> toolTimeoutMs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => McpServersCompanion(
                id: id,
                workspaceId: workspaceId,
                name: name,
                transport: transport,
                endpoint: endpoint,
                command: command,
                argumentsJson: argumentsJson,
                environmentJson: environmentJson,
                headersJson: headersJson,
                runtimeConfigId: runtimeConfigId,
                enabled: enabled,
                autoConnect: autoConnect,
                connectionTimeoutMs: connectionTimeoutMs,
                toolTimeoutMs: toolTimeoutMs,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String name,
                required String transport,
                Value<String> endpoint = const Value.absent(),
                Value<String> command = const Value.absent(),
                Value<String> argumentsJson = const Value.absent(),
                Value<String> environmentJson = const Value.absent(),
                Value<String> headersJson = const Value.absent(),
                Value<String?> runtimeConfigId = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> autoConnect = const Value.absent(),
                Value<int> connectionTimeoutMs = const Value.absent(),
                Value<int> toolTimeoutMs = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => McpServersCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                name: name,
                transport: transport,
                endpoint: endpoint,
                command: command,
                argumentsJson: argumentsJson,
                environmentJson: environmentJson,
                headersJson: headersJson,
                runtimeConfigId: runtimeConfigId,
                enabled: enabled,
                autoConnect: autoConnect,
                connectionTimeoutMs: connectionTimeoutMs,
                toolTimeoutMs: toolTimeoutMs,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$McpServersTable, McpServerRow>(table),
                  $$McpServersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workspaceId,
                                referencedTable: $$McpServersTableReferences
                                    ._workspaceIdTable(db),
                                referencedColumn: $$McpServersTableReferences
                                    ._workspaceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$McpServersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $McpServersTable,
      McpServerRow,
      $$McpServersTableFilterComposer,
      $$McpServersTableOrderingComposer,
      $$McpServersTableAnnotationComposer,
      $$McpServersTableCreateCompanionBuilder,
      $$McpServersTableUpdateCompanionBuilder,
      (McpServerRow, $$McpServersTableReferences),
      McpServerRow,
      PrefetchHooks Function({bool workspaceId})
    >;
typedef $$LspServerConfigsTableCreateCompanionBuilder =
    LspServerConfigsCompanion Function({
      required String id,
      required String workspaceId,
      required String languageId,
      required String command,
      Value<String> argumentsJson,
      Value<String> environmentJson,
      Value<bool> enabled,
      Value<String> initializationOptionsJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LspServerConfigsTableUpdateCompanionBuilder =
    LspServerConfigsCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> languageId,
      Value<String> command,
      Value<String> argumentsJson,
      Value<String> environmentJson,
      Value<bool> enabled,
      Value<String> initializationOptionsJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LspServerConfigsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LspServerConfigsTable,
          LspServerConfigRow
        > {
  $$LspServerConfigsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) => db.workspaces
      .createAlias('lsp_server_configs__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LspServerConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $LspServerConfigsTable> {
  $$LspServerConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageId => $composableBuilder(
    column: $table.languageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get argumentsJson => $composableBuilder(
    column: $table.argumentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentJson => $composableBuilder(
    column: $table.environmentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initializationOptionsJson => $composableBuilder(
    column: $table.initializationOptionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LspServerConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $LspServerConfigsTable> {
  $$LspServerConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageId => $composableBuilder(
    column: $table.languageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get command => $composableBuilder(
    column: $table.command,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get argumentsJson => $composableBuilder(
    column: $table.argumentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentJson => $composableBuilder(
    column: $table.environmentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initializationOptionsJson => $composableBuilder(
    column: $table.initializationOptionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LspServerConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LspServerConfigsTable> {
  $$LspServerConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get languageId => $composableBuilder(
    column: $table.languageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get command =>
      $composableBuilder(column: $table.command, builder: (column) => column);

  GeneratedColumn<String> get argumentsJson => $composableBuilder(
    column: $table.argumentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get environmentJson => $composableBuilder(
    column: $table.environmentJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get initializationOptionsJson => $composableBuilder(
    column: $table.initializationOptionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LspServerConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LspServerConfigsTable,
          LspServerConfigRow,
          $$LspServerConfigsTableFilterComposer,
          $$LspServerConfigsTableOrderingComposer,
          $$LspServerConfigsTableAnnotationComposer,
          $$LspServerConfigsTableCreateCompanionBuilder,
          $$LspServerConfigsTableUpdateCompanionBuilder,
          (LspServerConfigRow, $$LspServerConfigsTableReferences),
          LspServerConfigRow,
          PrefetchHooks Function({bool workspaceId})
        > {
  $$LspServerConfigsTableTableManager(
    _$AppDatabase db,
    $LspServerConfigsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LspServerConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LspServerConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LspServerConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> languageId = const Value.absent(),
                Value<String> command = const Value.absent(),
                Value<String> argumentsJson = const Value.absent(),
                Value<String> environmentJson = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> initializationOptionsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LspServerConfigsCompanion(
                id: id,
                workspaceId: workspaceId,
                languageId: languageId,
                command: command,
                argumentsJson: argumentsJson,
                environmentJson: environmentJson,
                enabled: enabled,
                initializationOptionsJson: initializationOptionsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String languageId,
                required String command,
                Value<String> argumentsJson = const Value.absent(),
                Value<String> environmentJson = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> initializationOptionsJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LspServerConfigsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                languageId: languageId,
                command: command,
                argumentsJson: argumentsJson,
                environmentJson: environmentJson,
                enabled: enabled,
                initializationOptionsJson: initializationOptionsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LspServerConfigsTable, LspServerConfigRow>(
                    table,
                  ),
                  $$LspServerConfigsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workspaceId,
                                referencedTable:
                                    $$LspServerConfigsTableReferences
                                        ._workspaceIdTable(db),
                                referencedColumn:
                                    $$LspServerConfigsTableReferences
                                        ._workspaceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LspServerConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LspServerConfigsTable,
      LspServerConfigRow,
      $$LspServerConfigsTableFilterComposer,
      $$LspServerConfigsTableOrderingComposer,
      $$LspServerConfigsTableAnnotationComposer,
      $$LspServerConfigsTableCreateCompanionBuilder,
      $$LspServerConfigsTableUpdateCompanionBuilder,
      (LspServerConfigRow, $$LspServerConfigsTableReferences),
      LspServerConfigRow,
      PrefetchHooks Function({bool workspaceId})
    >;
typedef $$CodeChunksTableCreateCompanionBuilder =
    CodeChunksCompanion Function({
      Value<int> id,
      required String workspaceId,
      required String filePath,
      required int chunkIndex,
      required int startLine,
      required int endLine,
      required String content,
      Value<String> languageId,
      Value<int> mtime,
      required DateTime indexedAt,
    });
typedef $$CodeChunksTableUpdateCompanionBuilder =
    CodeChunksCompanion Function({
      Value<int> id,
      Value<String> workspaceId,
      Value<String> filePath,
      Value<int> chunkIndex,
      Value<int> startLine,
      Value<int> endLine,
      Value<String> content,
      Value<String> languageId,
      Value<int> mtime,
      Value<DateTime> indexedAt,
    });

final class $$CodeChunksTableReferences
    extends BaseReferences<_$AppDatabase, $CodeChunksTable, CodeChunkRow> {
  $$CodeChunksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('code_chunks__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CodeChunksTableFilterComposer
    extends Composer<_$AppDatabase, $CodeChunksTable> {
  $$CodeChunksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startLine => $composableBuilder(
    column: $table.startLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endLine => $composableBuilder(
    column: $table.endLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageId => $composableBuilder(
    column: $table.languageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mtime => $composableBuilder(
    column: $table.mtime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CodeChunksTableOrderingComposer
    extends Composer<_$AppDatabase, $CodeChunksTable> {
  $$CodeChunksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startLine => $composableBuilder(
    column: $table.startLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endLine => $composableBuilder(
    column: $table.endLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageId => $composableBuilder(
    column: $table.languageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mtime => $composableBuilder(
    column: $table.mtime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CodeChunksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CodeChunksTable> {
  $$CodeChunksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get chunkIndex => $composableBuilder(
    column: $table.chunkIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startLine =>
      $composableBuilder(column: $table.startLine, builder: (column) => column);

  GeneratedColumn<int> get endLine =>
      $composableBuilder(column: $table.endLine, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get languageId => $composableBuilder(
    column: $table.languageId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mtime =>
      $composableBuilder(column: $table.mtime, builder: (column) => column);

  GeneratedColumn<DateTime> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CodeChunksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CodeChunksTable,
          CodeChunkRow,
          $$CodeChunksTableFilterComposer,
          $$CodeChunksTableOrderingComposer,
          $$CodeChunksTableAnnotationComposer,
          $$CodeChunksTableCreateCompanionBuilder,
          $$CodeChunksTableUpdateCompanionBuilder,
          (CodeChunkRow, $$CodeChunksTableReferences),
          CodeChunkRow,
          PrefetchHooks Function({bool workspaceId})
        > {
  $$CodeChunksTableTableManager(_$AppDatabase db, $CodeChunksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CodeChunksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CodeChunksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CodeChunksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> chunkIndex = const Value.absent(),
                Value<int> startLine = const Value.absent(),
                Value<int> endLine = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> languageId = const Value.absent(),
                Value<int> mtime = const Value.absent(),
                Value<DateTime> indexedAt = const Value.absent(),
              }) => CodeChunksCompanion(
                id: id,
                workspaceId: workspaceId,
                filePath: filePath,
                chunkIndex: chunkIndex,
                startLine: startLine,
                endLine: endLine,
                content: content,
                languageId: languageId,
                mtime: mtime,
                indexedAt: indexedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String workspaceId,
                required String filePath,
                required int chunkIndex,
                required int startLine,
                required int endLine,
                required String content,
                Value<String> languageId = const Value.absent(),
                Value<int> mtime = const Value.absent(),
                required DateTime indexedAt,
              }) => CodeChunksCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                filePath: filePath,
                chunkIndex: chunkIndex,
                startLine: startLine,
                endLine: endLine,
                content: content,
                languageId: languageId,
                mtime: mtime,
                indexedAt: indexedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CodeChunksTable, CodeChunkRow>(table),
                  $$CodeChunksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workspaceId,
                                referencedTable: $$CodeChunksTableReferences
                                    ._workspaceIdTable(db),
                                referencedColumn: $$CodeChunksTableReferences
                                    ._workspaceIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CodeChunksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CodeChunksTable,
      CodeChunkRow,
      $$CodeChunksTableFilterComposer,
      $$CodeChunksTableOrderingComposer,
      $$CodeChunksTableAnnotationComposer,
      $$CodeChunksTableCreateCompanionBuilder,
      $$CodeChunksTableUpdateCompanionBuilder,
      (CodeChunkRow, $$CodeChunksTableReferences),
      CodeChunkRow,
      PrefetchHooks Function({bool workspaceId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db, _db.workspaces);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$ProviderConfigsTableTableManager get providerConfigs =>
      $$ProviderConfigsTableTableManager(_db, _db.providerConfigs);
  $$MemoryNotesTableTableManager get memoryNotes =>
      $$MemoryNotesTableTableManager(_db, _db.memoryNotes);
  $$RuntimeConfigsTableTableManager get runtimeConfigs =>
      $$RuntimeConfigsTableTableManager(_db, _db.runtimeConfigs);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$DocumentSectionsTableTableManager get documentSections =>
      $$DocumentSectionsTableTableManager(_db, _db.documentSections);
  $$McpServersTableTableManager get mcpServers =>
      $$McpServersTableTableManager(_db, _db.mcpServers);
  $$LspServerConfigsTableTableManager get lspServerConfigs =>
      $$LspServerConfigsTableTableManager(_db, _db.lspServerConfigs);
  $$CodeChunksTableTableManager get codeChunks =>
      $$CodeChunksTableTableManager(_db, _db.codeChunks);
}
