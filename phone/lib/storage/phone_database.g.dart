// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_database.dart';

// ignore_for_file: type=lint
class $PendingSyncDeltasTable extends PendingSyncDeltas
    with TableInfo<$PendingSyncDeltasTable, PendingSyncDelta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncDeltasTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deltaJsonMeta = const VerificationMeta(
    'deltaJson',
  );
  @override
  late final GeneratedColumn<String> deltaJson = GeneratedColumn<String>(
    'delta_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: const CustomExpression<DateTime>(
      'CURRENT_TIMESTAMP',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, deltaJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sync_deltas';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSyncDelta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('delta_json')) {
      context.handle(
        _deltaJsonMeta,
        deltaJson.isAcceptableOrUnknown(data['delta_json']!, _deltaJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSyncDelta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSyncDelta(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deltaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delta_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingSyncDeltasTable createAlias(String alias) {
    return $PendingSyncDeltasTable(attachedDatabase, alias);
  }
}

class PendingSyncDelta extends DataClass
    implements Insertable<PendingSyncDelta> {
  final int id;
  final String deltaJson;
  final DateTime createdAt;
  const PendingSyncDelta({
    required this.id,
    required this.deltaJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['delta_json'] = Variable<String>(deltaJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingSyncDeltasCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncDeltasCompanion(
      id: Value(id),
      deltaJson: Value(deltaJson),
      createdAt: Value(createdAt),
    );
  }

  factory PendingSyncDelta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSyncDelta(
      id: serializer.fromJson<int>(json['id']),
      deltaJson: serializer.fromJson<String>(json['deltaJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deltaJson': serializer.toJson<String>(deltaJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingSyncDelta copyWith({
    int? id,
    String? deltaJson,
    DateTime? createdAt,
  }) => PendingSyncDelta(
    id: id ?? this.id,
    deltaJson: deltaJson ?? this.deltaJson,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingSyncDelta copyWithCompanion(PendingSyncDeltasCompanion data) {
    return PendingSyncDelta(
      id: data.id.present ? data.id.value : this.id,
      deltaJson: data.deltaJson.present ? data.deltaJson.value : this.deltaJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncDelta(')
          ..write('id: $id, ')
          ..write('deltaJson: $deltaJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, deltaJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSyncDelta &&
          other.id == this.id &&
          other.deltaJson == this.deltaJson &&
          other.createdAt == this.createdAt);
}

class PendingSyncDeltasCompanion extends UpdateCompanion<PendingSyncDelta> {
  final Value<int> id;
  final Value<String> deltaJson;
  final Value<DateTime> createdAt;
  const PendingSyncDeltasCompanion({
    this.id = const Value.absent(),
    this.deltaJson = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingSyncDeltasCompanion.insert({
    this.id = const Value.absent(),
    required String deltaJson,
    this.createdAt = const Value.absent(),
  }) : deltaJson = Value(deltaJson);
  static Insertable<PendingSyncDelta> custom({
    Expression<int>? id,
    Expression<String>? deltaJson,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deltaJson != null) 'delta_json': deltaJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingSyncDeltasCompanion copyWith({
    Value<int>? id,
    Value<String>? deltaJson,
    Value<DateTime>? createdAt,
  }) {
    return PendingSyncDeltasCompanion(
      id: id ?? this.id,
      deltaJson: deltaJson ?? this.deltaJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deltaJson.present) {
      map['delta_json'] = Variable<String>(deltaJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncDeltasCompanion(')
          ..write('id: $id, ')
          ..write('deltaJson: $deltaJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PendingCapturesTable extends PendingCaptures
    with TableInfo<$PendingCapturesTable, PendingCapture> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingCapturesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('learning'),
  );
  static const VerificationMeta _sharedTextMeta = const VerificationMeta(
    'sharedText',
  );
  @override
  late final GeneratedColumn<String> sharedText = GeneratedColumn<String>(
    'shared_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectMeta = const VerificationMeta(
    'project',
  );
  @override
  late final GeneratedColumn<String> project = GeneratedColumn<String>(
    'project',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('learning'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    url,
    notes,
    category,
    sharedText,
    project,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_captures';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingCapture> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('shared_text')) {
      context.handle(
        _sharedTextMeta,
        sharedText.isAcceptableOrUnknown(data['shared_text']!, _sharedTextMeta),
      );
    }
    if (data.containsKey('project')) {
      context.handle(
        _projectMeta,
        project.isAcceptableOrUnknown(data['project']!, _projectMeta),
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
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingCapture map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingCapture(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      sharedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_text'],
      ),
      project: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $PendingCapturesTable createAlias(String alias) {
    return $PendingCapturesTable(attachedDatabase, alias);
  }
}

class PendingCapture extends DataClass implements Insertable<PendingCapture> {
  final int id;
  final String title;
  final String? url;
  final String? notes;
  final String category;
  final String? sharedText;
  final String project;
  final int createdAt;
  final bool synced;
  const PendingCapture({
    required this.id,
    required this.title,
    this.url,
    this.notes,
    required this.category,
    this.sharedText,
    required this.project,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || sharedText != null) {
      map['shared_text'] = Variable<String>(sharedText);
    }
    map['project'] = Variable<String>(project);
    map['created_at'] = Variable<int>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  PendingCapturesCompanion toCompanion(bool nullToAbsent) {
    return PendingCapturesCompanion(
      id: Value(id),
      title: Value(title),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      category: Value(category),
      sharedText: sharedText == null && nullToAbsent
          ? const Value.absent()
          : Value(sharedText),
      project: Value(project),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory PendingCapture.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingCapture(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      url: serializer.fromJson<String?>(json['url']),
      notes: serializer.fromJson<String?>(json['notes']),
      category: serializer.fromJson<String>(json['category']),
      sharedText: serializer.fromJson<String?>(json['sharedText']),
      project: serializer.fromJson<String>(json['project']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'url': serializer.toJson<String?>(url),
      'notes': serializer.toJson<String?>(notes),
      'category': serializer.toJson<String>(category),
      'sharedText': serializer.toJson<String?>(sharedText),
      'project': serializer.toJson<String>(project),
      'createdAt': serializer.toJson<int>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  PendingCapture copyWith({
    int? id,
    String? title,
    Value<String?> url = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? category,
    Value<String?> sharedText = const Value.absent(),
    String? project,
    int? createdAt,
    bool? synced,
  }) => PendingCapture(
    id: id ?? this.id,
    title: title ?? this.title,
    url: url.present ? url.value : this.url,
    notes: notes.present ? notes.value : this.notes,
    category: category ?? this.category,
    sharedText: sharedText.present ? sharedText.value : this.sharedText,
    project: project ?? this.project,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  PendingCapture copyWithCompanion(PendingCapturesCompanion data) {
    return PendingCapture(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      url: data.url.present ? data.url.value : this.url,
      notes: data.notes.present ? data.notes.value : this.notes,
      category: data.category.present ? data.category.value : this.category,
      sharedText: data.sharedText.present
          ? data.sharedText.value
          : this.sharedText,
      project: data.project.present ? data.project.value : this.project,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingCapture(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('notes: $notes, ')
          ..write('category: $category, ')
          ..write('sharedText: $sharedText, ')
          ..write('project: $project, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    url,
    notes,
    category,
    sharedText,
    project,
    createdAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingCapture &&
          other.id == this.id &&
          other.title == this.title &&
          other.url == this.url &&
          other.notes == this.notes &&
          other.category == this.category &&
          other.sharedText == this.sharedText &&
          other.project == this.project &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class PendingCapturesCompanion extends UpdateCompanion<PendingCapture> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> url;
  final Value<String?> notes;
  final Value<String> category;
  final Value<String?> sharedText;
  final Value<String> project;
  final Value<int> createdAt;
  final Value<bool> synced;
  const PendingCapturesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    this.notes = const Value.absent(),
    this.category = const Value.absent(),
    this.sharedText = const Value.absent(),
    this.project = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  PendingCapturesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.url = const Value.absent(),
    this.notes = const Value.absent(),
    this.category = const Value.absent(),
    this.sharedText = const Value.absent(),
    this.project = const Value.absent(),
    required int createdAt,
    this.synced = const Value.absent(),
  }) : title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<PendingCapture> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? url,
    Expression<String>? notes,
    Expression<String>? category,
    Expression<String>? sharedText,
    Expression<String>? project,
    Expression<int>? createdAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (notes != null) 'notes': notes,
      if (category != null) 'category': category,
      if (sharedText != null) 'shared_text': sharedText,
      if (project != null) 'project': project,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  PendingCapturesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? url,
    Value<String?>? notes,
    Value<String>? category,
    Value<String?>? sharedText,
    Value<String>? project,
    Value<int>? createdAt,
    Value<bool>? synced,
  }) {
    return PendingCapturesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      sharedText: sharedText ?? this.sharedText,
      project: project ?? this.project,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (sharedText.present) {
      map['shared_text'] = Variable<String>(sharedText.value);
    }
    if (project.present) {
      map['project'] = Variable<String>(project.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingCapturesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('notes: $notes, ')
          ..write('category: $category, ')
          ..write('sharedText: $sharedText, ')
          ..write('project: $project, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

abstract class _$PhoneDatabase extends GeneratedDatabase {
  _$PhoneDatabase(QueryExecutor e) : super(e);
  $PhoneDatabaseManager get managers => $PhoneDatabaseManager(this);
  late final $PendingCapturesTable pendingCaptures = $PendingCapturesTable(
    this,
  );
  late final $PendingSyncDeltasTable pendingSyncDeltas =
      $PendingSyncDeltasTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pendingCaptures,
    pendingSyncDeltas,
  ];
}

typedef $$PendingCapturesTableCreateCompanionBuilder =
    PendingCapturesCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> url,
      Value<String?> notes,
      Value<String> category,
      Value<String?> sharedText,
      Value<String> project,
      required int createdAt,
      Value<bool> synced,
    });
typedef $$PendingCapturesTableUpdateCompanionBuilder =
    PendingCapturesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> url,
      Value<String?> notes,
      Value<String> category,
      Value<String?> sharedText,
      Value<String> project,
      Value<int> createdAt,
      Value<bool> synced,
    });

class $$PendingCapturesTableFilterComposer
    extends Composer<_$PhoneDatabase, $PendingCapturesTable> {
  $$PendingCapturesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedText => $composableBuilder(
    column: $table.sharedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get project => $composableBuilder(
    column: $table.project,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingCapturesTableOrderingComposer
    extends Composer<_$PhoneDatabase, $PendingCapturesTable> {
  $$PendingCapturesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedText => $composableBuilder(
    column: $table.sharedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get project => $composableBuilder(
    column: $table.project,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingCapturesTableAnnotationComposer
    extends Composer<_$PhoneDatabase, $PendingCapturesTable> {
  $$PendingCapturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get sharedText => $composableBuilder(
    column: $table.sharedText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get project =>
      $composableBuilder(column: $table.project, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$PendingCapturesTableTableManager
    extends
        RootTableManager<
          _$PhoneDatabase,
          $PendingCapturesTable,
          PendingCapture,
          $$PendingCapturesTableFilterComposer,
          $$PendingCapturesTableOrderingComposer,
          $$PendingCapturesTableAnnotationComposer,
          $$PendingCapturesTableCreateCompanionBuilder,
          $$PendingCapturesTableUpdateCompanionBuilder,
          (
            PendingCapture,
            BaseReferences<
              _$PhoneDatabase,
              $PendingCapturesTable,
              PendingCapture
            >,
          ),
          PendingCapture,
          PrefetchHooks Function()
        > {
  $$PendingCapturesTableTableManager(
    _$PhoneDatabase db,
    $PendingCapturesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingCapturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingCapturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingCapturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> sharedText = const Value.absent(),
                Value<String> project = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
              }) => PendingCapturesCompanion(
                id: id,
                title: title,
                url: url,
                notes: notes,
                category: category,
                sharedText: sharedText,
                project: project,
                createdAt: createdAt,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> url = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> sharedText = const Value.absent(),
                Value<String> project = const Value.absent(),
                required int createdAt,
                Value<bool> synced = const Value.absent(),
              }) => PendingCapturesCompanion.insert(
                id: id,
                title: title,
                url: url,
                notes: notes,
                category: category,
                sharedText: sharedText,
                project: project,
                createdAt: createdAt,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingCapturesTableProcessedTableManager =
    ProcessedTableManager<
      _$PhoneDatabase,
      $PendingCapturesTable,
      PendingCapture,
      $$PendingCapturesTableFilterComposer,
      $$PendingCapturesTableOrderingComposer,
      $$PendingCapturesTableAnnotationComposer,
      $$PendingCapturesTableCreateCompanionBuilder,
      $$PendingCapturesTableUpdateCompanionBuilder,
      (
        PendingCapture,
        BaseReferences<_$PhoneDatabase, $PendingCapturesTable, PendingCapture>,
      ),
      PendingCapture,
      PrefetchHooks Function()
    >;

typedef $$PendingSyncDeltasTableCreateCompanionBuilder =
    PendingSyncDeltasCompanion Function({
      Value<int> id,
      required String deltaJson,
      Value<DateTime> createdAt,
    });
typedef $$PendingSyncDeltasTableUpdateCompanionBuilder =
    PendingSyncDeltasCompanion Function({
      Value<int> id,
      Value<String> deltaJson,
      Value<DateTime> createdAt,
    });

class $$PendingSyncDeltasTableFilterComposer
    extends Composer<_$PhoneDatabase, $PendingSyncDeltasTable> {
  $$PendingSyncDeltasTableFilterComposer({
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

  ColumnFilters<String> get deltaJson => $composableBuilder(
    column: $table.deltaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSyncDeltasTableOrderingComposer
    extends Composer<_$PhoneDatabase, $PendingSyncDeltasTable> {
  $$PendingSyncDeltasTableOrderingComposer({
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

  ColumnOrderings<String> get deltaJson => $composableBuilder(
    column: $table.deltaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSyncDeltasTableAnnotationComposer
    extends Composer<_$PhoneDatabase, $PendingSyncDeltasTable> {
  $$PendingSyncDeltasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deltaJson =>
      $composableBuilder(column: $table.deltaJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingSyncDeltasTableTableManager
    extends
        RootTableManager<
          _$PhoneDatabase,
          $PendingSyncDeltasTable,
          PendingSyncDelta,
          $$PendingSyncDeltasTableFilterComposer,
          $$PendingSyncDeltasTableOrderingComposer,
          $$PendingSyncDeltasTableAnnotationComposer,
          $$PendingSyncDeltasTableCreateCompanionBuilder,
          $$PendingSyncDeltasTableUpdateCompanionBuilder,
          (
            PendingSyncDelta,
            BaseReferences<
              _$PhoneDatabase,
              $PendingSyncDeltasTable,
              PendingSyncDelta
            >,
          ),
          PendingSyncDelta,
          PrefetchHooks Function()
        > {
  $$PendingSyncDeltasTableTableManager(
    _$PhoneDatabase db,
    $PendingSyncDeltasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSyncDeltasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSyncDeltasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSyncDeltasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> deltaJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingSyncDeltasCompanion(
                id: id,
                deltaJson: deltaJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String deltaJson,
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingSyncDeltasCompanion.insert(
                id: id,
                deltaJson: deltaJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSyncDeltasTableProcessedTableManager =
    ProcessedTableManager<
      _$PhoneDatabase,
      $PendingSyncDeltasTable,
      PendingSyncDelta,
      $$PendingSyncDeltasTableFilterComposer,
      $$PendingSyncDeltasTableOrderingComposer,
      $$PendingSyncDeltasTableAnnotationComposer,
      $$PendingSyncDeltasTableCreateCompanionBuilder,
      $$PendingSyncDeltasTableUpdateCompanionBuilder,
      (
        PendingSyncDelta,
        BaseReferences<
          _$PhoneDatabase,
          $PendingSyncDeltasTable,
          PendingSyncDelta
        >,
      ),
      PendingSyncDelta,
      PrefetchHooks Function()
    >;

class $PhoneDatabaseManager {
  final _$PhoneDatabase _db;
  $PhoneDatabaseManager(this._db);
  $$PendingCapturesTableTableManager get pendingCaptures =>
      $$PendingCapturesTableTableManager(_db, _db.pendingCaptures);
  $$PendingSyncDeltasTableTableManager get pendingSyncDeltas =>
      $$PendingSyncDeltasTableTableManager(_db, _db.pendingSyncDeltas);
}
