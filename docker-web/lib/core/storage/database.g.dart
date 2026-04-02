// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeSpentMeta = const VerificationMeta(
    'timeSpent',
  );
  @override
  late final GeneratedColumn<int> timeSpent = GeneratedColumn<int>(
    'time_spent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timeEstimateMeta = const VerificationMeta(
    'timeEstimate',
  );
  @override
  late final GeneratedColumn<int> timeEstimate = GeneratedColumn<int>(
    'time_estimate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timeSpentOnDayMeta = const VerificationMeta(
    'timeSpentOnDay',
  );
  @override
  late final GeneratedColumn<String> timeSpentOnDay = GeneratedColumn<String>(
    'time_spent_on_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _dueWithTimeMeta = const VerificationMeta(
    'dueWithTime',
  );
  @override
  late final GeneratedColumn<int> dueWithTime = GeneratedColumn<int>(
    'due_with_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<String> dueDay = GeneratedColumn<String>(
    'due_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagIdsMeta = const VerificationMeta('tagIds');
  @override
  late final GeneratedColumn<String> tagIds = GeneratedColumn<String>(
    'tag_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _attachmentsMeta = const VerificationMeta(
    'attachments',
  );
  @override
  late final GeneratedColumn<String> attachments = GeneratedColumn<String>(
    'attachments',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _reminderIdMeta = const VerificationMeta(
    'reminderId',
  );
  @override
  late final GeneratedColumn<String> reminderId = GeneratedColumn<String>(
    'reminder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remindAtMeta = const VerificationMeta(
    'remindAt',
  );
  @override
  late final GeneratedColumn<int> remindAt = GeneratedColumn<int>(
    'remind_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doneOnMeta = const VerificationMeta('doneOn');
  @override
  late final GeneratedColumn<int> doneOn = GeneratedColumn<int>(
    'done_on',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<int> modified = GeneratedColumn<int>(
    'modified',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatCfgIdMeta = const VerificationMeta(
    'repeatCfgId',
  );
  @override
  late final GeneratedColumn<String> repeatCfgId = GeneratedColumn<String>(
    'repeat_cfg_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueIdMeta = const VerificationMeta(
    'issueId',
  );
  @override
  late final GeneratedColumn<String> issueId = GeneratedColumn<String>(
    'issue_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueProviderIdMeta = const VerificationMeta(
    'issueProviderId',
  );
  @override
  late final GeneratedColumn<String> issueProviderId = GeneratedColumn<String>(
    'issue_provider_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueTypeMeta = const VerificationMeta(
    'issueType',
  );
  @override
  late final GeneratedColumn<String> issueType = GeneratedColumn<String>(
    'issue_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueWasUpdatedMeta = const VerificationMeta(
    'issueWasUpdated',
  );
  @override
  late final GeneratedColumn<bool> issueWasUpdated = GeneratedColumn<bool>(
    'issue_was_updated',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("issue_was_updated" IN (0, 1))',
    ),
  );
  static const VerificationMeta _issueLastUpdatedMeta = const VerificationMeta(
    'issueLastUpdated',
  );
  @override
  late final GeneratedColumn<int> issueLastUpdated = GeneratedColumn<int>(
    'issue_last_updated',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueAttachmentNrMeta = const VerificationMeta(
    'issueAttachmentNr',
  );
  @override
  late final GeneratedColumn<int> issueAttachmentNr = GeneratedColumn<int>(
    'issue_attachment_nr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issueTimeTrackedMeta = const VerificationMeta(
    'issueTimeTracked',
  );
  @override
  late final GeneratedColumn<String> issueTimeTracked = GeneratedColumn<String>(
    'issue_time_tracked',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issuePointsMeta = const VerificationMeta(
    'issuePoints',
  );
  @override
  late final GeneratedColumn<int> issuePoints = GeneratedColumn<int>(
    'issue_points',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _crdtClockMeta = const VerificationMeta(
    'crdtClock',
  );
  @override
  late final GeneratedColumn<String> crdtClock = GeneratedColumn<String>(
    'crdt_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _crdtStateMeta = const VerificationMeta(
    'crdtState',
  );
  @override
  late final GeneratedColumn<String> crdtState = GeneratedColumn<String>(
    'crdt_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    title,
    description,
    isDone,
    created,
    timeSpent,
    timeEstimate,
    timeSpentOnDay,
    dueWithTime,
    dueDay,
    tagIds,
    attachments,
    reminderId,
    remindAt,
    doneOn,
    modified,
    repeatCfgId,
    issueId,
    issueProviderId,
    issueType,
    issueWasUpdated,
    issueLastUpdated,
    issueAttachmentNr,
    issueTimeTracked,
    issuePoints,
    crdtClock,
    crdtState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('time_spent')) {
      context.handle(
        _timeSpentMeta,
        timeSpent.isAcceptableOrUnknown(data['time_spent']!, _timeSpentMeta),
      );
    }
    if (data.containsKey('time_estimate')) {
      context.handle(
        _timeEstimateMeta,
        timeEstimate.isAcceptableOrUnknown(
          data['time_estimate']!,
          _timeEstimateMeta,
        ),
      );
    }
    if (data.containsKey('time_spent_on_day')) {
      context.handle(
        _timeSpentOnDayMeta,
        timeSpentOnDay.isAcceptableOrUnknown(
          data['time_spent_on_day']!,
          _timeSpentOnDayMeta,
        ),
      );
    }
    if (data.containsKey('due_with_time')) {
      context.handle(
        _dueWithTimeMeta,
        dueWithTime.isAcceptableOrUnknown(
          data['due_with_time']!,
          _dueWithTimeMeta,
        ),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    }
    if (data.containsKey('tag_ids')) {
      context.handle(
        _tagIdsMeta,
        tagIds.isAcceptableOrUnknown(data['tag_ids']!, _tagIdsMeta),
      );
    }
    if (data.containsKey('attachments')) {
      context.handle(
        _attachmentsMeta,
        attachments.isAcceptableOrUnknown(
          data['attachments']!,
          _attachmentsMeta,
        ),
      );
    }
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
      );
    }
    if (data.containsKey('remind_at')) {
      context.handle(
        _remindAtMeta,
        remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta),
      );
    }
    if (data.containsKey('done_on')) {
      context.handle(
        _doneOnMeta,
        doneOn.isAcceptableOrUnknown(data['done_on']!, _doneOnMeta),
      );
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    }
    if (data.containsKey('repeat_cfg_id')) {
      context.handle(
        _repeatCfgIdMeta,
        repeatCfgId.isAcceptableOrUnknown(
          data['repeat_cfg_id']!,
          _repeatCfgIdMeta,
        ),
      );
    }
    if (data.containsKey('issue_id')) {
      context.handle(
        _issueIdMeta,
        issueId.isAcceptableOrUnknown(data['issue_id']!, _issueIdMeta),
      );
    }
    if (data.containsKey('issue_provider_id')) {
      context.handle(
        _issueProviderIdMeta,
        issueProviderId.isAcceptableOrUnknown(
          data['issue_provider_id']!,
          _issueProviderIdMeta,
        ),
      );
    }
    if (data.containsKey('issue_type')) {
      context.handle(
        _issueTypeMeta,
        issueType.isAcceptableOrUnknown(data['issue_type']!, _issueTypeMeta),
      );
    }
    if (data.containsKey('issue_was_updated')) {
      context.handle(
        _issueWasUpdatedMeta,
        issueWasUpdated.isAcceptableOrUnknown(
          data['issue_was_updated']!,
          _issueWasUpdatedMeta,
        ),
      );
    }
    if (data.containsKey('issue_last_updated')) {
      context.handle(
        _issueLastUpdatedMeta,
        issueLastUpdated.isAcceptableOrUnknown(
          data['issue_last_updated']!,
          _issueLastUpdatedMeta,
        ),
      );
    }
    if (data.containsKey('issue_attachment_nr')) {
      context.handle(
        _issueAttachmentNrMeta,
        issueAttachmentNr.isAcceptableOrUnknown(
          data['issue_attachment_nr']!,
          _issueAttachmentNrMeta,
        ),
      );
    }
    if (data.containsKey('issue_time_tracked')) {
      context.handle(
        _issueTimeTrackedMeta,
        issueTimeTracked.isAcceptableOrUnknown(
          data['issue_time_tracked']!,
          _issueTimeTrackedMeta,
        ),
      );
    }
    if (data.containsKey('issue_points')) {
      context.handle(
        _issuePointsMeta,
        issuePoints.isAcceptableOrUnknown(
          data['issue_points']!,
          _issuePointsMeta,
        ),
      );
    }
    if (data.containsKey('crdt_clock')) {
      context.handle(
        _crdtClockMeta,
        crdtClock.isAcceptableOrUnknown(data['crdt_clock']!, _crdtClockMeta),
      );
    }
    if (data.containsKey('crdt_state')) {
      context.handle(
        _crdtStateMeta,
        crdtState.isAcceptableOrUnknown(data['crdt_state']!, _crdtStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created'],
      )!,
      timeSpent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_spent'],
      )!,
      timeEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_estimate'],
      )!,
      timeSpentOnDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_spent_on_day'],
      )!,
      dueWithTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_with_time'],
      ),
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_day'],
      ),
      tagIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_ids'],
      )!,
      attachments: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments'],
      )!,
      reminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_id'],
      ),
      remindAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_at'],
      ),
      doneOn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}done_on'],
      ),
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified'],
      ),
      repeatCfgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_cfg_id'],
      ),
      issueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_id'],
      ),
      issueProviderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_provider_id'],
      ),
      issueType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_type'],
      ),
      issueWasUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}issue_was_updated'],
      ),
      issueLastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}issue_last_updated'],
      ),
      issueAttachmentNr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}issue_attachment_nr'],
      ),
      issueTimeTracked: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_time_tracked'],
      ),
      issuePoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}issue_points'],
      ),
      crdtClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_clock'],
      )!,
      crdtState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_state'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String? projectId;
  final String title;
  final String? description;
  final bool isDone;
  final int created;
  final int timeSpent;
  final int timeEstimate;
  final String timeSpentOnDay;
  final int? dueWithTime;
  final String? dueDay;
  final String tagIds;
  final String attachments;
  final String? reminderId;
  final int? remindAt;
  final int? doneOn;
  final int? modified;
  final String? repeatCfgId;
  final String? issueId;
  final String? issueProviderId;
  final String? issueType;
  final bool? issueWasUpdated;
  final int? issueLastUpdated;
  final int? issueAttachmentNr;
  final String? issueTimeTracked;
  final int? issuePoints;
  final String crdtClock;
  final String crdtState;
  const Task({
    required this.id,
    this.projectId,
    required this.title,
    this.description,
    required this.isDone,
    required this.created,
    required this.timeSpent,
    required this.timeEstimate,
    required this.timeSpentOnDay,
    this.dueWithTime,
    this.dueDay,
    required this.tagIds,
    required this.attachments,
    this.reminderId,
    this.remindAt,
    this.doneOn,
    this.modified,
    this.repeatCfgId,
    this.issueId,
    this.issueProviderId,
    this.issueType,
    this.issueWasUpdated,
    this.issueLastUpdated,
    this.issueAttachmentNr,
    this.issueTimeTracked,
    this.issuePoints,
    required this.crdtClock,
    required this.crdtState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_done'] = Variable<bool>(isDone);
    map['created'] = Variable<int>(created);
    map['time_spent'] = Variable<int>(timeSpent);
    map['time_estimate'] = Variable<int>(timeEstimate);
    map['time_spent_on_day'] = Variable<String>(timeSpentOnDay);
    if (!nullToAbsent || dueWithTime != null) {
      map['due_with_time'] = Variable<int>(dueWithTime);
    }
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<String>(dueDay);
    }
    map['tag_ids'] = Variable<String>(tagIds);
    map['attachments'] = Variable<String>(attachments);
    if (!nullToAbsent || reminderId != null) {
      map['reminder_id'] = Variable<String>(reminderId);
    }
    if (!nullToAbsent || remindAt != null) {
      map['remind_at'] = Variable<int>(remindAt);
    }
    if (!nullToAbsent || doneOn != null) {
      map['done_on'] = Variable<int>(doneOn);
    }
    if (!nullToAbsent || modified != null) {
      map['modified'] = Variable<int>(modified);
    }
    if (!nullToAbsent || repeatCfgId != null) {
      map['repeat_cfg_id'] = Variable<String>(repeatCfgId);
    }
    if (!nullToAbsent || issueId != null) {
      map['issue_id'] = Variable<String>(issueId);
    }
    if (!nullToAbsent || issueProviderId != null) {
      map['issue_provider_id'] = Variable<String>(issueProviderId);
    }
    if (!nullToAbsent || issueType != null) {
      map['issue_type'] = Variable<String>(issueType);
    }
    if (!nullToAbsent || issueWasUpdated != null) {
      map['issue_was_updated'] = Variable<bool>(issueWasUpdated);
    }
    if (!nullToAbsent || issueLastUpdated != null) {
      map['issue_last_updated'] = Variable<int>(issueLastUpdated);
    }
    if (!nullToAbsent || issueAttachmentNr != null) {
      map['issue_attachment_nr'] = Variable<int>(issueAttachmentNr);
    }
    if (!nullToAbsent || issueTimeTracked != null) {
      map['issue_time_tracked'] = Variable<String>(issueTimeTracked);
    }
    if (!nullToAbsent || issuePoints != null) {
      map['issue_points'] = Variable<int>(issuePoints);
    }
    map['crdt_clock'] = Variable<String>(crdtClock);
    map['crdt_state'] = Variable<String>(crdtState);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isDone: Value(isDone),
      created: Value(created),
      timeSpent: Value(timeSpent),
      timeEstimate: Value(timeEstimate),
      timeSpentOnDay: Value(timeSpentOnDay),
      dueWithTime: dueWithTime == null && nullToAbsent
          ? const Value.absent()
          : Value(dueWithTime),
      dueDay: dueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDay),
      tagIds: Value(tagIds),
      attachments: Value(attachments),
      reminderId: reminderId == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderId),
      remindAt: remindAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remindAt),
      doneOn: doneOn == null && nullToAbsent
          ? const Value.absent()
          : Value(doneOn),
      modified: modified == null && nullToAbsent
          ? const Value.absent()
          : Value(modified),
      repeatCfgId: repeatCfgId == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatCfgId),
      issueId: issueId == null && nullToAbsent
          ? const Value.absent()
          : Value(issueId),
      issueProviderId: issueProviderId == null && nullToAbsent
          ? const Value.absent()
          : Value(issueProviderId),
      issueType: issueType == null && nullToAbsent
          ? const Value.absent()
          : Value(issueType),
      issueWasUpdated: issueWasUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(issueWasUpdated),
      issueLastUpdated: issueLastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(issueLastUpdated),
      issueAttachmentNr: issueAttachmentNr == null && nullToAbsent
          ? const Value.absent()
          : Value(issueAttachmentNr),
      issueTimeTracked: issueTimeTracked == null && nullToAbsent
          ? const Value.absent()
          : Value(issueTimeTracked),
      issuePoints: issuePoints == null && nullToAbsent
          ? const Value.absent()
          : Value(issuePoints),
      crdtClock: Value(crdtClock),
      crdtState: Value(crdtState),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      created: serializer.fromJson<int>(json['created']),
      timeSpent: serializer.fromJson<int>(json['timeSpent']),
      timeEstimate: serializer.fromJson<int>(json['timeEstimate']),
      timeSpentOnDay: serializer.fromJson<String>(json['timeSpentOnDay']),
      dueWithTime: serializer.fromJson<int?>(json['dueWithTime']),
      dueDay: serializer.fromJson<String?>(json['dueDay']),
      tagIds: serializer.fromJson<String>(json['tagIds']),
      attachments: serializer.fromJson<String>(json['attachments']),
      reminderId: serializer.fromJson<String?>(json['reminderId']),
      remindAt: serializer.fromJson<int?>(json['remindAt']),
      doneOn: serializer.fromJson<int?>(json['doneOn']),
      modified: serializer.fromJson<int?>(json['modified']),
      repeatCfgId: serializer.fromJson<String?>(json['repeatCfgId']),
      issueId: serializer.fromJson<String?>(json['issueId']),
      issueProviderId: serializer.fromJson<String?>(json['issueProviderId']),
      issueType: serializer.fromJson<String?>(json['issueType']),
      issueWasUpdated: serializer.fromJson<bool?>(json['issueWasUpdated']),
      issueLastUpdated: serializer.fromJson<int?>(json['issueLastUpdated']),
      issueAttachmentNr: serializer.fromJson<int?>(json['issueAttachmentNr']),
      issueTimeTracked: serializer.fromJson<String?>(json['issueTimeTracked']),
      issuePoints: serializer.fromJson<int?>(json['issuePoints']),
      crdtClock: serializer.fromJson<String>(json['crdtClock']),
      crdtState: serializer.fromJson<String>(json['crdtState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String?>(projectId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'isDone': serializer.toJson<bool>(isDone),
      'created': serializer.toJson<int>(created),
      'timeSpent': serializer.toJson<int>(timeSpent),
      'timeEstimate': serializer.toJson<int>(timeEstimate),
      'timeSpentOnDay': serializer.toJson<String>(timeSpentOnDay),
      'dueWithTime': serializer.toJson<int?>(dueWithTime),
      'dueDay': serializer.toJson<String?>(dueDay),
      'tagIds': serializer.toJson<String>(tagIds),
      'attachments': serializer.toJson<String>(attachments),
      'reminderId': serializer.toJson<String?>(reminderId),
      'remindAt': serializer.toJson<int?>(remindAt),
      'doneOn': serializer.toJson<int?>(doneOn),
      'modified': serializer.toJson<int?>(modified),
      'repeatCfgId': serializer.toJson<String?>(repeatCfgId),
      'issueId': serializer.toJson<String?>(issueId),
      'issueProviderId': serializer.toJson<String?>(issueProviderId),
      'issueType': serializer.toJson<String?>(issueType),
      'issueWasUpdated': serializer.toJson<bool?>(issueWasUpdated),
      'issueLastUpdated': serializer.toJson<int?>(issueLastUpdated),
      'issueAttachmentNr': serializer.toJson<int?>(issueAttachmentNr),
      'issueTimeTracked': serializer.toJson<String?>(issueTimeTracked),
      'issuePoints': serializer.toJson<int?>(issuePoints),
      'crdtClock': serializer.toJson<String>(crdtClock),
      'crdtState': serializer.toJson<String>(crdtState),
    };
  }

  Task copyWith({
    String? id,
    Value<String?> projectId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    bool? isDone,
    int? created,
    int? timeSpent,
    int? timeEstimate,
    String? timeSpentOnDay,
    Value<int?> dueWithTime = const Value.absent(),
    Value<String?> dueDay = const Value.absent(),
    String? tagIds,
    String? attachments,
    Value<String?> reminderId = const Value.absent(),
    Value<int?> remindAt = const Value.absent(),
    Value<int?> doneOn = const Value.absent(),
    Value<int?> modified = const Value.absent(),
    Value<String?> repeatCfgId = const Value.absent(),
    Value<String?> issueId = const Value.absent(),
    Value<String?> issueProviderId = const Value.absent(),
    Value<String?> issueType = const Value.absent(),
    Value<bool?> issueWasUpdated = const Value.absent(),
    Value<int?> issueLastUpdated = const Value.absent(),
    Value<int?> issueAttachmentNr = const Value.absent(),
    Value<String?> issueTimeTracked = const Value.absent(),
    Value<int?> issuePoints = const Value.absent(),
    String? crdtClock,
    String? crdtState,
  }) => Task(
    id: id ?? this.id,
    projectId: projectId.present ? projectId.value : this.projectId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    isDone: isDone ?? this.isDone,
    created: created ?? this.created,
    timeSpent: timeSpent ?? this.timeSpent,
    timeEstimate: timeEstimate ?? this.timeEstimate,
    timeSpentOnDay: timeSpentOnDay ?? this.timeSpentOnDay,
    dueWithTime: dueWithTime.present ? dueWithTime.value : this.dueWithTime,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    tagIds: tagIds ?? this.tagIds,
    attachments: attachments ?? this.attachments,
    reminderId: reminderId.present ? reminderId.value : this.reminderId,
    remindAt: remindAt.present ? remindAt.value : this.remindAt,
    doneOn: doneOn.present ? doneOn.value : this.doneOn,
    modified: modified.present ? modified.value : this.modified,
    repeatCfgId: repeatCfgId.present ? repeatCfgId.value : this.repeatCfgId,
    issueId: issueId.present ? issueId.value : this.issueId,
    issueProviderId: issueProviderId.present
        ? issueProviderId.value
        : this.issueProviderId,
    issueType: issueType.present ? issueType.value : this.issueType,
    issueWasUpdated: issueWasUpdated.present
        ? issueWasUpdated.value
        : this.issueWasUpdated,
    issueLastUpdated: issueLastUpdated.present
        ? issueLastUpdated.value
        : this.issueLastUpdated,
    issueAttachmentNr: issueAttachmentNr.present
        ? issueAttachmentNr.value
        : this.issueAttachmentNr,
    issueTimeTracked: issueTimeTracked.present
        ? issueTimeTracked.value
        : this.issueTimeTracked,
    issuePoints: issuePoints.present ? issuePoints.value : this.issuePoints,
    crdtClock: crdtClock ?? this.crdtClock,
    crdtState: crdtState ?? this.crdtState,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      created: data.created.present ? data.created.value : this.created,
      timeSpent: data.timeSpent.present ? data.timeSpent.value : this.timeSpent,
      timeEstimate: data.timeEstimate.present
          ? data.timeEstimate.value
          : this.timeEstimate,
      timeSpentOnDay: data.timeSpentOnDay.present
          ? data.timeSpentOnDay.value
          : this.timeSpentOnDay,
      dueWithTime: data.dueWithTime.present
          ? data.dueWithTime.value
          : this.dueWithTime,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      tagIds: data.tagIds.present ? data.tagIds.value : this.tagIds,
      attachments: data.attachments.present
          ? data.attachments.value
          : this.attachments,
      reminderId: data.reminderId.present
          ? data.reminderId.value
          : this.reminderId,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
      doneOn: data.doneOn.present ? data.doneOn.value : this.doneOn,
      modified: data.modified.present ? data.modified.value : this.modified,
      repeatCfgId: data.repeatCfgId.present
          ? data.repeatCfgId.value
          : this.repeatCfgId,
      issueId: data.issueId.present ? data.issueId.value : this.issueId,
      issueProviderId: data.issueProviderId.present
          ? data.issueProviderId.value
          : this.issueProviderId,
      issueType: data.issueType.present ? data.issueType.value : this.issueType,
      issueWasUpdated: data.issueWasUpdated.present
          ? data.issueWasUpdated.value
          : this.issueWasUpdated,
      issueLastUpdated: data.issueLastUpdated.present
          ? data.issueLastUpdated.value
          : this.issueLastUpdated,
      issueAttachmentNr: data.issueAttachmentNr.present
          ? data.issueAttachmentNr.value
          : this.issueAttachmentNr,
      issueTimeTracked: data.issueTimeTracked.present
          ? data.issueTimeTracked.value
          : this.issueTimeTracked,
      issuePoints: data.issuePoints.present
          ? data.issuePoints.value
          : this.issuePoints,
      crdtClock: data.crdtClock.present ? data.crdtClock.value : this.crdtClock,
      crdtState: data.crdtState.present ? data.crdtState.value : this.crdtState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('isDone: $isDone, ')
          ..write('created: $created, ')
          ..write('timeSpent: $timeSpent, ')
          ..write('timeEstimate: $timeEstimate, ')
          ..write('timeSpentOnDay: $timeSpentOnDay, ')
          ..write('dueWithTime: $dueWithTime, ')
          ..write('dueDay: $dueDay, ')
          ..write('tagIds: $tagIds, ')
          ..write('attachments: $attachments, ')
          ..write('reminderId: $reminderId, ')
          ..write('remindAt: $remindAt, ')
          ..write('doneOn: $doneOn, ')
          ..write('modified: $modified, ')
          ..write('repeatCfgId: $repeatCfgId, ')
          ..write('issueId: $issueId, ')
          ..write('issueProviderId: $issueProviderId, ')
          ..write('issueType: $issueType, ')
          ..write('issueWasUpdated: $issueWasUpdated, ')
          ..write('issueLastUpdated: $issueLastUpdated, ')
          ..write('issueAttachmentNr: $issueAttachmentNr, ')
          ..write('issueTimeTracked: $issueTimeTracked, ')
          ..write('issuePoints: $issuePoints, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    projectId,
    title,
    description,
    isDone,
    created,
    timeSpent,
    timeEstimate,
    timeSpentOnDay,
    dueWithTime,
    dueDay,
    tagIds,
    attachments,
    reminderId,
    remindAt,
    doneOn,
    modified,
    repeatCfgId,
    issueId,
    issueProviderId,
    issueType,
    issueWasUpdated,
    issueLastUpdated,
    issueAttachmentNr,
    issueTimeTracked,
    issuePoints,
    crdtClock,
    crdtState,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.title == this.title &&
          other.description == this.description &&
          other.isDone == this.isDone &&
          other.created == this.created &&
          other.timeSpent == this.timeSpent &&
          other.timeEstimate == this.timeEstimate &&
          other.timeSpentOnDay == this.timeSpentOnDay &&
          other.dueWithTime == this.dueWithTime &&
          other.dueDay == this.dueDay &&
          other.tagIds == this.tagIds &&
          other.attachments == this.attachments &&
          other.reminderId == this.reminderId &&
          other.remindAt == this.remindAt &&
          other.doneOn == this.doneOn &&
          other.modified == this.modified &&
          other.repeatCfgId == this.repeatCfgId &&
          other.issueId == this.issueId &&
          other.issueProviderId == this.issueProviderId &&
          other.issueType == this.issueType &&
          other.issueWasUpdated == this.issueWasUpdated &&
          other.issueLastUpdated == this.issueLastUpdated &&
          other.issueAttachmentNr == this.issueAttachmentNr &&
          other.issueTimeTracked == this.issueTimeTracked &&
          other.issuePoints == this.issuePoints &&
          other.crdtClock == this.crdtClock &&
          other.crdtState == this.crdtState);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String?> projectId;
  final Value<String> title;
  final Value<String?> description;
  final Value<bool> isDone;
  final Value<int> created;
  final Value<int> timeSpent;
  final Value<int> timeEstimate;
  final Value<String> timeSpentOnDay;
  final Value<int?> dueWithTime;
  final Value<String?> dueDay;
  final Value<String> tagIds;
  final Value<String> attachments;
  final Value<String?> reminderId;
  final Value<int?> remindAt;
  final Value<int?> doneOn;
  final Value<int?> modified;
  final Value<String?> repeatCfgId;
  final Value<String?> issueId;
  final Value<String?> issueProviderId;
  final Value<String?> issueType;
  final Value<bool?> issueWasUpdated;
  final Value<int?> issueLastUpdated;
  final Value<int?> issueAttachmentNr;
  final Value<String?> issueTimeTracked;
  final Value<int?> issuePoints;
  final Value<String> crdtClock;
  final Value<String> crdtState;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.isDone = const Value.absent(),
    this.created = const Value.absent(),
    this.timeSpent = const Value.absent(),
    this.timeEstimate = const Value.absent(),
    this.timeSpentOnDay = const Value.absent(),
    this.dueWithTime = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.tagIds = const Value.absent(),
    this.attachments = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.doneOn = const Value.absent(),
    this.modified = const Value.absent(),
    this.repeatCfgId = const Value.absent(),
    this.issueId = const Value.absent(),
    this.issueProviderId = const Value.absent(),
    this.issueType = const Value.absent(),
    this.issueWasUpdated = const Value.absent(),
    this.issueLastUpdated = const Value.absent(),
    this.issueAttachmentNr = const Value.absent(),
    this.issueTimeTracked = const Value.absent(),
    this.issuePoints = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    this.projectId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.isDone = const Value.absent(),
    required int created,
    this.timeSpent = const Value.absent(),
    this.timeEstimate = const Value.absent(),
    this.timeSpentOnDay = const Value.absent(),
    this.dueWithTime = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.tagIds = const Value.absent(),
    this.attachments = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.doneOn = const Value.absent(),
    this.modified = const Value.absent(),
    this.repeatCfgId = const Value.absent(),
    this.issueId = const Value.absent(),
    this.issueProviderId = const Value.absent(),
    this.issueType = const Value.absent(),
    this.issueWasUpdated = const Value.absent(),
    this.issueLastUpdated = const Value.absent(),
    this.issueAttachmentNr = const Value.absent(),
    this.issueTimeTracked = const Value.absent(),
    this.issuePoints = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       created = Value(created);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<bool>? isDone,
    Expression<int>? created,
    Expression<int>? timeSpent,
    Expression<int>? timeEstimate,
    Expression<String>? timeSpentOnDay,
    Expression<int>? dueWithTime,
    Expression<String>? dueDay,
    Expression<String>? tagIds,
    Expression<String>? attachments,
    Expression<String>? reminderId,
    Expression<int>? remindAt,
    Expression<int>? doneOn,
    Expression<int>? modified,
    Expression<String>? repeatCfgId,
    Expression<String>? issueId,
    Expression<String>? issueProviderId,
    Expression<String>? issueType,
    Expression<bool>? issueWasUpdated,
    Expression<int>? issueLastUpdated,
    Expression<int>? issueAttachmentNr,
    Expression<String>? issueTimeTracked,
    Expression<int>? issuePoints,
    Expression<String>? crdtClock,
    Expression<String>? crdtState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (isDone != null) 'is_done': isDone,
      if (created != null) 'created': created,
      if (timeSpent != null) 'time_spent': timeSpent,
      if (timeEstimate != null) 'time_estimate': timeEstimate,
      if (timeSpentOnDay != null) 'time_spent_on_day': timeSpentOnDay,
      if (dueWithTime != null) 'due_with_time': dueWithTime,
      if (dueDay != null) 'due_day': dueDay,
      if (tagIds != null) 'tag_ids': tagIds,
      if (attachments != null) 'attachments': attachments,
      if (reminderId != null) 'reminder_id': reminderId,
      if (remindAt != null) 'remind_at': remindAt,
      if (doneOn != null) 'done_on': doneOn,
      if (modified != null) 'modified': modified,
      if (repeatCfgId != null) 'repeat_cfg_id': repeatCfgId,
      if (issueId != null) 'issue_id': issueId,
      if (issueProviderId != null) 'issue_provider_id': issueProviderId,
      if (issueType != null) 'issue_type': issueType,
      if (issueWasUpdated != null) 'issue_was_updated': issueWasUpdated,
      if (issueLastUpdated != null) 'issue_last_updated': issueLastUpdated,
      if (issueAttachmentNr != null) 'issue_attachment_nr': issueAttachmentNr,
      if (issueTimeTracked != null) 'issue_time_tracked': issueTimeTracked,
      if (issuePoints != null) 'issue_points': issuePoints,
      if (crdtClock != null) 'crdt_clock': crdtClock,
      if (crdtState != null) 'crdt_state': crdtState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String?>? projectId,
    Value<String>? title,
    Value<String?>? description,
    Value<bool>? isDone,
    Value<int>? created,
    Value<int>? timeSpent,
    Value<int>? timeEstimate,
    Value<String>? timeSpentOnDay,
    Value<int?>? dueWithTime,
    Value<String?>? dueDay,
    Value<String>? tagIds,
    Value<String>? attachments,
    Value<String?>? reminderId,
    Value<int?>? remindAt,
    Value<int?>? doneOn,
    Value<int?>? modified,
    Value<String?>? repeatCfgId,
    Value<String?>? issueId,
    Value<String?>? issueProviderId,
    Value<String?>? issueType,
    Value<bool?>? issueWasUpdated,
    Value<int?>? issueLastUpdated,
    Value<int?>? issueAttachmentNr,
    Value<String?>? issueTimeTracked,
    Value<int?>? issuePoints,
    Value<String>? crdtClock,
    Value<String>? crdtState,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      created: created ?? this.created,
      timeSpent: timeSpent ?? this.timeSpent,
      timeEstimate: timeEstimate ?? this.timeEstimate,
      timeSpentOnDay: timeSpentOnDay ?? this.timeSpentOnDay,
      dueWithTime: dueWithTime ?? this.dueWithTime,
      dueDay: dueDay ?? this.dueDay,
      tagIds: tagIds ?? this.tagIds,
      attachments: attachments ?? this.attachments,
      reminderId: reminderId ?? this.reminderId,
      remindAt: remindAt ?? this.remindAt,
      doneOn: doneOn ?? this.doneOn,
      modified: modified ?? this.modified,
      repeatCfgId: repeatCfgId ?? this.repeatCfgId,
      issueId: issueId ?? this.issueId,
      issueProviderId: issueProviderId ?? this.issueProviderId,
      issueType: issueType ?? this.issueType,
      issueWasUpdated: issueWasUpdated ?? this.issueWasUpdated,
      issueLastUpdated: issueLastUpdated ?? this.issueLastUpdated,
      issueAttachmentNr: issueAttachmentNr ?? this.issueAttachmentNr,
      issueTimeTracked: issueTimeTracked ?? this.issueTimeTracked,
      issuePoints: issuePoints ?? this.issuePoints,
      crdtClock: crdtClock ?? this.crdtClock,
      crdtState: crdtState ?? this.crdtState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (created.present) {
      map['created'] = Variable<int>(created.value);
    }
    if (timeSpent.present) {
      map['time_spent'] = Variable<int>(timeSpent.value);
    }
    if (timeEstimate.present) {
      map['time_estimate'] = Variable<int>(timeEstimate.value);
    }
    if (timeSpentOnDay.present) {
      map['time_spent_on_day'] = Variable<String>(timeSpentOnDay.value);
    }
    if (dueWithTime.present) {
      map['due_with_time'] = Variable<int>(dueWithTime.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<String>(dueDay.value);
    }
    if (tagIds.present) {
      map['tag_ids'] = Variable<String>(tagIds.value);
    }
    if (attachments.present) {
      map['attachments'] = Variable<String>(attachments.value);
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<String>(reminderId.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<int>(remindAt.value);
    }
    if (doneOn.present) {
      map['done_on'] = Variable<int>(doneOn.value);
    }
    if (modified.present) {
      map['modified'] = Variable<int>(modified.value);
    }
    if (repeatCfgId.present) {
      map['repeat_cfg_id'] = Variable<String>(repeatCfgId.value);
    }
    if (issueId.present) {
      map['issue_id'] = Variable<String>(issueId.value);
    }
    if (issueProviderId.present) {
      map['issue_provider_id'] = Variable<String>(issueProviderId.value);
    }
    if (issueType.present) {
      map['issue_type'] = Variable<String>(issueType.value);
    }
    if (issueWasUpdated.present) {
      map['issue_was_updated'] = Variable<bool>(issueWasUpdated.value);
    }
    if (issueLastUpdated.present) {
      map['issue_last_updated'] = Variable<int>(issueLastUpdated.value);
    }
    if (issueAttachmentNr.present) {
      map['issue_attachment_nr'] = Variable<int>(issueAttachmentNr.value);
    }
    if (issueTimeTracked.present) {
      map['issue_time_tracked'] = Variable<String>(issueTimeTracked.value);
    }
    if (issuePoints.present) {
      map['issue_points'] = Variable<int>(issuePoints.value);
    }
    if (crdtClock.present) {
      map['crdt_clock'] = Variable<String>(crdtClock.value);
    }
    if (crdtState.present) {
      map['crdt_state'] = Variable<String>(crdtState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('isDone: $isDone, ')
          ..write('created: $created, ')
          ..write('timeSpent: $timeSpent, ')
          ..write('timeEstimate: $timeEstimate, ')
          ..write('timeSpentOnDay: $timeSpentOnDay, ')
          ..write('dueWithTime: $dueWithTime, ')
          ..write('dueDay: $dueDay, ')
          ..write('tagIds: $tagIds, ')
          ..write('attachments: $attachments, ')
          ..write('reminderId: $reminderId, ')
          ..write('remindAt: $remindAt, ')
          ..write('doneOn: $doneOn, ')
          ..write('modified: $modified, ')
          ..write('repeatCfgId: $repeatCfgId, ')
          ..write('issueId: $issueId, ')
          ..write('issueProviderId: $issueProviderId, ')
          ..write('issueType: $issueType, ')
          ..write('issueWasUpdated: $issueWasUpdated, ')
          ..write('issueLastUpdated: $issueLastUpdated, ')
          ..write('issueAttachmentNr: $issueAttachmentNr, ')
          ..write('issueTimeTracked: $issueTimeTracked, ')
          ..write('issuePoints: $issuePoints, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubtasksTable extends Subtasks with TableInfo<$SubtasksTable, Subtask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubtasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<int> modified = GeneratedColumn<int>(
    'modified',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _crdtClockMeta = const VerificationMeta(
    'crdtClock',
  );
  @override
  late final GeneratedColumn<String> crdtClock = GeneratedColumn<String>(
    'crdt_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _crdtStateMeta = const VerificationMeta(
    'crdtState',
  );
  @override
  late final GeneratedColumn<String> crdtState = GeneratedColumn<String>(
    'crdt_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    title,
    isDone,
    order,
    notes,
    created,
    modified,
    crdtClock,
    crdtState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subtasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subtask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    }
    if (data.containsKey('crdt_clock')) {
      context.handle(
        _crdtClockMeta,
        crdtClock.isAcceptableOrUnknown(data['crdt_clock']!, _crdtClockMeta),
      );
    }
    if (data.containsKey('crdt_state')) {
      context.handle(
        _crdtStateMeta,
        crdtState.isAcceptableOrUnknown(data['crdt_state']!, _crdtStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subtask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subtask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created'],
      )!,
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified'],
      ),
      crdtClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_clock'],
      )!,
      crdtState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_state'],
      )!,
    );
  }

  @override
  $SubtasksTable createAlias(String alias) {
    return $SubtasksTable(attachedDatabase, alias);
  }
}

class Subtask extends DataClass implements Insertable<Subtask> {
  final String id;
  final String taskId;
  final String title;
  final bool isDone;
  final int order;
  final String? notes;
  final int created;
  final int? modified;
  final String crdtClock;
  final String crdtState;
  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isDone,
    required this.order,
    this.notes,
    required this.created,
    this.modified,
    required this.crdtClock,
    required this.crdtState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['title'] = Variable<String>(title);
    map['is_done'] = Variable<bool>(isDone);
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created'] = Variable<int>(created);
    if (!nullToAbsent || modified != null) {
      map['modified'] = Variable<int>(modified);
    }
    map['crdt_clock'] = Variable<String>(crdtClock);
    map['crdt_state'] = Variable<String>(crdtState);
    return map;
  }

  SubtasksCompanion toCompanion(bool nullToAbsent) {
    return SubtasksCompanion(
      id: Value(id),
      taskId: Value(taskId),
      title: Value(title),
      isDone: Value(isDone),
      order: Value(order),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      created: Value(created),
      modified: modified == null && nullToAbsent
          ? const Value.absent()
          : Value(modified),
      crdtClock: Value(crdtClock),
      crdtState: Value(crdtState),
    );
  }

  factory Subtask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subtask(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      title: serializer.fromJson<String>(json['title']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      order: serializer.fromJson<int>(json['order']),
      notes: serializer.fromJson<String?>(json['notes']),
      created: serializer.fromJson<int>(json['created']),
      modified: serializer.fromJson<int?>(json['modified']),
      crdtClock: serializer.fromJson<String>(json['crdtClock']),
      crdtState: serializer.fromJson<String>(json['crdtState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'title': serializer.toJson<String>(title),
      'isDone': serializer.toJson<bool>(isDone),
      'order': serializer.toJson<int>(order),
      'notes': serializer.toJson<String?>(notes),
      'created': serializer.toJson<int>(created),
      'modified': serializer.toJson<int?>(modified),
      'crdtClock': serializer.toJson<String>(crdtClock),
      'crdtState': serializer.toJson<String>(crdtState),
    };
  }

  Subtask copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isDone,
    int? order,
    Value<String?> notes = const Value.absent(),
    int? created,
    Value<int?> modified = const Value.absent(),
    String? crdtClock,
    String? crdtState,
  }) => Subtask(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    title: title ?? this.title,
    isDone: isDone ?? this.isDone,
    order: order ?? this.order,
    notes: notes.present ? notes.value : this.notes,
    created: created ?? this.created,
    modified: modified.present ? modified.value : this.modified,
    crdtClock: crdtClock ?? this.crdtClock,
    crdtState: crdtState ?? this.crdtState,
  );
  Subtask copyWithCompanion(SubtasksCompanion data) {
    return Subtask(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      title: data.title.present ? data.title.value : this.title,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      order: data.order.present ? data.order.value : this.order,
      notes: data.notes.present ? data.notes.value : this.notes,
      created: data.created.present ? data.created.value : this.created,
      modified: data.modified.present ? data.modified.value : this.modified,
      crdtClock: data.crdtClock.present ? data.crdtClock.value : this.crdtClock,
      crdtState: data.crdtState.present ? data.crdtState.value : this.crdtState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subtask(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('isDone: $isDone, ')
          ..write('order: $order, ')
          ..write('notes: $notes, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    title,
    isDone,
    order,
    notes,
    created,
    modified,
    crdtClock,
    crdtState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subtask &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.title == this.title &&
          other.isDone == this.isDone &&
          other.order == this.order &&
          other.notes == this.notes &&
          other.created == this.created &&
          other.modified == this.modified &&
          other.crdtClock == this.crdtClock &&
          other.crdtState == this.crdtState);
}

class SubtasksCompanion extends UpdateCompanion<Subtask> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> title;
  final Value<bool> isDone;
  final Value<int> order;
  final Value<String?> notes;
  final Value<int> created;
  final Value<int?> modified;
  final Value<String> crdtClock;
  final Value<String> crdtState;
  final Value<int> rowid;
  const SubtasksCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.title = const Value.absent(),
    this.isDone = const Value.absent(),
    this.order = const Value.absent(),
    this.notes = const Value.absent(),
    this.created = const Value.absent(),
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubtasksCompanion.insert({
    required String id,
    required String taskId,
    required String title,
    this.isDone = const Value.absent(),
    this.order = const Value.absent(),
    this.notes = const Value.absent(),
    required int created,
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       title = Value(title),
       created = Value(created);
  static Insertable<Subtask> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? title,
    Expression<bool>? isDone,
    Expression<int>? order,
    Expression<String>? notes,
    Expression<int>? created,
    Expression<int>? modified,
    Expression<String>? crdtClock,
    Expression<String>? crdtState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (title != null) 'title': title,
      if (isDone != null) 'is_done': isDone,
      if (order != null) 'order': order,
      if (notes != null) 'notes': notes,
      if (created != null) 'created': created,
      if (modified != null) 'modified': modified,
      if (crdtClock != null) 'crdt_clock': crdtClock,
      if (crdtState != null) 'crdt_state': crdtState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubtasksCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? title,
    Value<bool>? isDone,
    Value<int>? order,
    Value<String?>? notes,
    Value<int>? created,
    Value<int?>? modified,
    Value<String>? crdtClock,
    Value<String>? crdtState,
    Value<int>? rowid,
  }) {
    return SubtasksCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      order: order ?? this.order,
      notes: notes ?? this.notes,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      crdtClock: crdtClock ?? this.crdtClock,
      crdtState: crdtState ?? this.crdtState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (created.present) {
      map['created'] = Variable<int>(created.value);
    }
    if (modified.present) {
      map['modified'] = Variable<int>(modified.value);
    }
    if (crdtClock.present) {
      map['crdt_clock'] = Variable<String>(crdtClock.value);
    }
    if (crdtState.present) {
      map['crdt_state'] = Variable<String>(crdtState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubtasksCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('title: $title, ')
          ..write('isDone: $isDone, ')
          ..write('order: $order, ')
          ..write('notes: $notes, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isHiddenFromMenuMeta = const VerificationMeta(
    'isHiddenFromMenu',
  );
  @override
  late final GeneratedColumn<bool> isHiddenFromMenu = GeneratedColumn<bool>(
    'is_hidden_from_menu',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden_from_menu" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isEnableBacklogMeta = const VerificationMeta(
    'isEnableBacklog',
  );
  @override
  late final GeneratedColumn<bool> isEnableBacklog = GeneratedColumn<bool>(
    'is_enable_backlog',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enable_backlog" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _taskIdsMeta = const VerificationMeta(
    'taskIds',
  );
  @override
  late final GeneratedColumn<String> taskIds = GeneratedColumn<String>(
    'task_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _backlogTaskIdsMeta = const VerificationMeta(
    'backlogTaskIds',
  );
  @override
  late final GeneratedColumn<String> backlogTaskIds = GeneratedColumn<String>(
    'backlog_task_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _advancedCfgMeta = const VerificationMeta(
    'advancedCfg',
  );
  @override
  late final GeneratedColumn<String> advancedCfg = GeneratedColumn<String>(
    'advanced_cfg',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<int> modified = GeneratedColumn<int>(
    'modified',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _crdtClockMeta = const VerificationMeta(
    'crdtClock',
  );
  @override
  late final GeneratedColumn<String> crdtClock = GeneratedColumn<String>(
    'crdt_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _crdtStateMeta = const VerificationMeta(
    'crdtState',
  );
  @override
  late final GeneratedColumn<String> crdtState = GeneratedColumn<String>(
    'crdt_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    isArchived,
    isHiddenFromMenu,
    isEnableBacklog,
    taskIds,
    backlogTaskIds,
    theme,
    advancedCfg,
    icon,
    created,
    modified,
    crdtClock,
    crdtState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_hidden_from_menu')) {
      context.handle(
        _isHiddenFromMenuMeta,
        isHiddenFromMenu.isAcceptableOrUnknown(
          data['is_hidden_from_menu']!,
          _isHiddenFromMenuMeta,
        ),
      );
    }
    if (data.containsKey('is_enable_backlog')) {
      context.handle(
        _isEnableBacklogMeta,
        isEnableBacklog.isAcceptableOrUnknown(
          data['is_enable_backlog']!,
          _isEnableBacklogMeta,
        ),
      );
    }
    if (data.containsKey('task_ids')) {
      context.handle(
        _taskIdsMeta,
        taskIds.isAcceptableOrUnknown(data['task_ids']!, _taskIdsMeta),
      );
    }
    if (data.containsKey('backlog_task_ids')) {
      context.handle(
        _backlogTaskIdsMeta,
        backlogTaskIds.isAcceptableOrUnknown(
          data['backlog_task_ids']!,
          _backlogTaskIdsMeta,
        ),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    }
    if (data.containsKey('advanced_cfg')) {
      context.handle(
        _advancedCfgMeta,
        advancedCfg.isAcceptableOrUnknown(
          data['advanced_cfg']!,
          _advancedCfgMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    }
    if (data.containsKey('crdt_clock')) {
      context.handle(
        _crdtClockMeta,
        crdtClock.isAcceptableOrUnknown(data['crdt_clock']!, _crdtClockMeta),
      );
    }
    if (data.containsKey('crdt_state')) {
      context.handle(
        _crdtStateMeta,
        crdtState.isAcceptableOrUnknown(data['crdt_state']!, _crdtStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      isHiddenFromMenu: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden_from_menu'],
      )!,
      isEnableBacklog: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enable_backlog'],
      )!,
      taskIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_ids'],
      )!,
      backlogTaskIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backlog_task_ids'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      advancedCfg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}advanced_cfg'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created'],
      )!,
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified'],
      ),
      crdtClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_clock'],
      )!,
      crdtState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_state'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String title;
  final bool isArchived;
  final bool isHiddenFromMenu;
  final bool isEnableBacklog;
  final String taskIds;
  final String backlogTaskIds;
  final String theme;
  final String advancedCfg;
  final String? icon;
  final int created;
  final int? modified;
  final String crdtClock;
  final String crdtState;
  const Project({
    required this.id,
    required this.title,
    required this.isArchived,
    required this.isHiddenFromMenu,
    required this.isEnableBacklog,
    required this.taskIds,
    required this.backlogTaskIds,
    required this.theme,
    required this.advancedCfg,
    this.icon,
    required this.created,
    this.modified,
    required this.crdtClock,
    required this.crdtState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_hidden_from_menu'] = Variable<bool>(isHiddenFromMenu);
    map['is_enable_backlog'] = Variable<bool>(isEnableBacklog);
    map['task_ids'] = Variable<String>(taskIds);
    map['backlog_task_ids'] = Variable<String>(backlogTaskIds);
    map['theme'] = Variable<String>(theme);
    map['advanced_cfg'] = Variable<String>(advancedCfg);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['created'] = Variable<int>(created);
    if (!nullToAbsent || modified != null) {
      map['modified'] = Variable<int>(modified);
    }
    map['crdt_clock'] = Variable<String>(crdtClock);
    map['crdt_state'] = Variable<String>(crdtState);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      title: Value(title),
      isArchived: Value(isArchived),
      isHiddenFromMenu: Value(isHiddenFromMenu),
      isEnableBacklog: Value(isEnableBacklog),
      taskIds: Value(taskIds),
      backlogTaskIds: Value(backlogTaskIds),
      theme: Value(theme),
      advancedCfg: Value(advancedCfg),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      created: Value(created),
      modified: modified == null && nullToAbsent
          ? const Value.absent()
          : Value(modified),
      crdtClock: Value(crdtClock),
      crdtState: Value(crdtState),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isHiddenFromMenu: serializer.fromJson<bool>(json['isHiddenFromMenu']),
      isEnableBacklog: serializer.fromJson<bool>(json['isEnableBacklog']),
      taskIds: serializer.fromJson<String>(json['taskIds']),
      backlogTaskIds: serializer.fromJson<String>(json['backlogTaskIds']),
      theme: serializer.fromJson<String>(json['theme']),
      advancedCfg: serializer.fromJson<String>(json['advancedCfg']),
      icon: serializer.fromJson<String?>(json['icon']),
      created: serializer.fromJson<int>(json['created']),
      modified: serializer.fromJson<int?>(json['modified']),
      crdtClock: serializer.fromJson<String>(json['crdtClock']),
      crdtState: serializer.fromJson<String>(json['crdtState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isHiddenFromMenu': serializer.toJson<bool>(isHiddenFromMenu),
      'isEnableBacklog': serializer.toJson<bool>(isEnableBacklog),
      'taskIds': serializer.toJson<String>(taskIds),
      'backlogTaskIds': serializer.toJson<String>(backlogTaskIds),
      'theme': serializer.toJson<String>(theme),
      'advancedCfg': serializer.toJson<String>(advancedCfg),
      'icon': serializer.toJson<String?>(icon),
      'created': serializer.toJson<int>(created),
      'modified': serializer.toJson<int?>(modified),
      'crdtClock': serializer.toJson<String>(crdtClock),
      'crdtState': serializer.toJson<String>(crdtState),
    };
  }

  Project copyWith({
    String? id,
    String? title,
    bool? isArchived,
    bool? isHiddenFromMenu,
    bool? isEnableBacklog,
    String? taskIds,
    String? backlogTaskIds,
    String? theme,
    String? advancedCfg,
    Value<String?> icon = const Value.absent(),
    int? created,
    Value<int?> modified = const Value.absent(),
    String? crdtClock,
    String? crdtState,
  }) => Project(
    id: id ?? this.id,
    title: title ?? this.title,
    isArchived: isArchived ?? this.isArchived,
    isHiddenFromMenu: isHiddenFromMenu ?? this.isHiddenFromMenu,
    isEnableBacklog: isEnableBacklog ?? this.isEnableBacklog,
    taskIds: taskIds ?? this.taskIds,
    backlogTaskIds: backlogTaskIds ?? this.backlogTaskIds,
    theme: theme ?? this.theme,
    advancedCfg: advancedCfg ?? this.advancedCfg,
    icon: icon.present ? icon.value : this.icon,
    created: created ?? this.created,
    modified: modified.present ? modified.value : this.modified,
    crdtClock: crdtClock ?? this.crdtClock,
    crdtState: crdtState ?? this.crdtState,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isHiddenFromMenu: data.isHiddenFromMenu.present
          ? data.isHiddenFromMenu.value
          : this.isHiddenFromMenu,
      isEnableBacklog: data.isEnableBacklog.present
          ? data.isEnableBacklog.value
          : this.isEnableBacklog,
      taskIds: data.taskIds.present ? data.taskIds.value : this.taskIds,
      backlogTaskIds: data.backlogTaskIds.present
          ? data.backlogTaskIds.value
          : this.backlogTaskIds,
      theme: data.theme.present ? data.theme.value : this.theme,
      advancedCfg: data.advancedCfg.present
          ? data.advancedCfg.value
          : this.advancedCfg,
      icon: data.icon.present ? data.icon.value : this.icon,
      created: data.created.present ? data.created.value : this.created,
      modified: data.modified.present ? data.modified.value : this.modified,
      crdtClock: data.crdtClock.present ? data.crdtClock.value : this.crdtClock,
      crdtState: data.crdtState.present ? data.crdtState.value : this.crdtState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('isArchived: $isArchived, ')
          ..write('isHiddenFromMenu: $isHiddenFromMenu, ')
          ..write('isEnableBacklog: $isEnableBacklog, ')
          ..write('taskIds: $taskIds, ')
          ..write('backlogTaskIds: $backlogTaskIds, ')
          ..write('theme: $theme, ')
          ..write('advancedCfg: $advancedCfg, ')
          ..write('icon: $icon, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    isArchived,
    isHiddenFromMenu,
    isEnableBacklog,
    taskIds,
    backlogTaskIds,
    theme,
    advancedCfg,
    icon,
    created,
    modified,
    crdtClock,
    crdtState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.title == this.title &&
          other.isArchived == this.isArchived &&
          other.isHiddenFromMenu == this.isHiddenFromMenu &&
          other.isEnableBacklog == this.isEnableBacklog &&
          other.taskIds == this.taskIds &&
          other.backlogTaskIds == this.backlogTaskIds &&
          other.theme == this.theme &&
          other.advancedCfg == this.advancedCfg &&
          other.icon == this.icon &&
          other.created == this.created &&
          other.modified == this.modified &&
          other.crdtClock == this.crdtClock &&
          other.crdtState == this.crdtState);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> title;
  final Value<bool> isArchived;
  final Value<bool> isHiddenFromMenu;
  final Value<bool> isEnableBacklog;
  final Value<String> taskIds;
  final Value<String> backlogTaskIds;
  final Value<String> theme;
  final Value<String> advancedCfg;
  final Value<String?> icon;
  final Value<int> created;
  final Value<int?> modified;
  final Value<String> crdtClock;
  final Value<String> crdtState;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isHiddenFromMenu = const Value.absent(),
    this.isEnableBacklog = const Value.absent(),
    this.taskIds = const Value.absent(),
    this.backlogTaskIds = const Value.absent(),
    this.theme = const Value.absent(),
    this.advancedCfg = const Value.absent(),
    this.icon = const Value.absent(),
    this.created = const Value.absent(),
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String title,
    this.isArchived = const Value.absent(),
    this.isHiddenFromMenu = const Value.absent(),
    this.isEnableBacklog = const Value.absent(),
    this.taskIds = const Value.absent(),
    this.backlogTaskIds = const Value.absent(),
    this.theme = const Value.absent(),
    this.advancedCfg = const Value.absent(),
    this.icon = const Value.absent(),
    required int created,
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       created = Value(created);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<bool>? isArchived,
    Expression<bool>? isHiddenFromMenu,
    Expression<bool>? isEnableBacklog,
    Expression<String>? taskIds,
    Expression<String>? backlogTaskIds,
    Expression<String>? theme,
    Expression<String>? advancedCfg,
    Expression<String>? icon,
    Expression<int>? created,
    Expression<int>? modified,
    Expression<String>? crdtClock,
    Expression<String>? crdtState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (isArchived != null) 'is_archived': isArchived,
      if (isHiddenFromMenu != null) 'is_hidden_from_menu': isHiddenFromMenu,
      if (isEnableBacklog != null) 'is_enable_backlog': isEnableBacklog,
      if (taskIds != null) 'task_ids': taskIds,
      if (backlogTaskIds != null) 'backlog_task_ids': backlogTaskIds,
      if (theme != null) 'theme': theme,
      if (advancedCfg != null) 'advanced_cfg': advancedCfg,
      if (icon != null) 'icon': icon,
      if (created != null) 'created': created,
      if (modified != null) 'modified': modified,
      if (crdtClock != null) 'crdt_clock': crdtClock,
      if (crdtState != null) 'crdt_state': crdtState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<bool>? isArchived,
    Value<bool>? isHiddenFromMenu,
    Value<bool>? isEnableBacklog,
    Value<String>? taskIds,
    Value<String>? backlogTaskIds,
    Value<String>? theme,
    Value<String>? advancedCfg,
    Value<String?>? icon,
    Value<int>? created,
    Value<int?>? modified,
    Value<String>? crdtClock,
    Value<String>? crdtState,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      isArchived: isArchived ?? this.isArchived,
      isHiddenFromMenu: isHiddenFromMenu ?? this.isHiddenFromMenu,
      isEnableBacklog: isEnableBacklog ?? this.isEnableBacklog,
      taskIds: taskIds ?? this.taskIds,
      backlogTaskIds: backlogTaskIds ?? this.backlogTaskIds,
      theme: theme ?? this.theme,
      advancedCfg: advancedCfg ?? this.advancedCfg,
      icon: icon ?? this.icon,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      crdtClock: crdtClock ?? this.crdtClock,
      crdtState: crdtState ?? this.crdtState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isHiddenFromMenu.present) {
      map['is_hidden_from_menu'] = Variable<bool>(isHiddenFromMenu.value);
    }
    if (isEnableBacklog.present) {
      map['is_enable_backlog'] = Variable<bool>(isEnableBacklog.value);
    }
    if (taskIds.present) {
      map['task_ids'] = Variable<String>(taskIds.value);
    }
    if (backlogTaskIds.present) {
      map['backlog_task_ids'] = Variable<String>(backlogTaskIds.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (advancedCfg.present) {
      map['advanced_cfg'] = Variable<String>(advancedCfg.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (created.present) {
      map['created'] = Variable<int>(created.value);
    }
    if (modified.present) {
      map['modified'] = Variable<int>(modified.value);
    }
    if (crdtClock.present) {
      map['crdt_clock'] = Variable<String>(crdtClock.value);
    }
    if (crdtState.present) {
      map['crdt_state'] = Variable<String>(crdtState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('isArchived: $isArchived, ')
          ..write('isHiddenFromMenu: $isHiddenFromMenu, ')
          ..write('isEnableBacklog: $isEnableBacklog, ')
          ..write('taskIds: $taskIds, ')
          ..write('backlogTaskIds: $backlogTaskIds, ')
          ..write('theme: $theme, ')
          ..write('advancedCfg: $advancedCfg, ')
          ..write('icon: $icon, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdsMeta = const VerificationMeta(
    'taskIds',
  );
  @override
  late final GeneratedColumn<String> taskIds = GeneratedColumn<String>(
    'task_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _advancedCfgMeta = const VerificationMeta(
    'advancedCfg',
  );
  @override
  late final GeneratedColumn<String> advancedCfg = GeneratedColumn<String>(
    'advanced_cfg',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<int> modified = GeneratedColumn<int>(
    'modified',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _crdtClockMeta = const VerificationMeta(
    'crdtClock',
  );
  @override
  late final GeneratedColumn<String> crdtClock = GeneratedColumn<String>(
    'crdt_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _crdtStateMeta = const VerificationMeta(
    'crdtState',
  );
  @override
  late final GeneratedColumn<String> crdtState = GeneratedColumn<String>(
    'crdt_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    icon,
    taskIds,
    theme,
    advancedCfg,
    created,
    modified,
    crdtClock,
    crdtState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('task_ids')) {
      context.handle(
        _taskIdsMeta,
        taskIds.isAcceptableOrUnknown(data['task_ids']!, _taskIdsMeta),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    }
    if (data.containsKey('advanced_cfg')) {
      context.handle(
        _advancedCfgMeta,
        advancedCfg.isAcceptableOrUnknown(
          data['advanced_cfg']!,
          _advancedCfgMeta,
        ),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    }
    if (data.containsKey('crdt_clock')) {
      context.handle(
        _crdtClockMeta,
        crdtClock.isAcceptableOrUnknown(data['crdt_clock']!, _crdtClockMeta),
      );
    }
    if (data.containsKey('crdt_state')) {
      context.handle(
        _crdtStateMeta,
        crdtState.isAcceptableOrUnknown(data['crdt_state']!, _crdtStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      taskIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_ids'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      advancedCfg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}advanced_cfg'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created'],
      )!,
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified'],
      ),
      crdtClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_clock'],
      )!,
      crdtState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_state'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String title;
  final String? icon;
  final String taskIds;
  final String theme;
  final String advancedCfg;
  final int created;
  final int? modified;
  final String crdtClock;
  final String crdtState;
  const Tag({
    required this.id,
    required this.title,
    this.icon,
    required this.taskIds,
    required this.theme,
    required this.advancedCfg,
    required this.created,
    this.modified,
    required this.crdtClock,
    required this.crdtState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['task_ids'] = Variable<String>(taskIds);
    map['theme'] = Variable<String>(theme);
    map['advanced_cfg'] = Variable<String>(advancedCfg);
    map['created'] = Variable<int>(created);
    if (!nullToAbsent || modified != null) {
      map['modified'] = Variable<int>(modified);
    }
    map['crdt_clock'] = Variable<String>(crdtClock);
    map['crdt_state'] = Variable<String>(crdtState);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      title: Value(title),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      taskIds: Value(taskIds),
      theme: Value(theme),
      advancedCfg: Value(advancedCfg),
      created: Value(created),
      modified: modified == null && nullToAbsent
          ? const Value.absent()
          : Value(modified),
      crdtClock: Value(crdtClock),
      crdtState: Value(crdtState),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      icon: serializer.fromJson<String?>(json['icon']),
      taskIds: serializer.fromJson<String>(json['taskIds']),
      theme: serializer.fromJson<String>(json['theme']),
      advancedCfg: serializer.fromJson<String>(json['advancedCfg']),
      created: serializer.fromJson<int>(json['created']),
      modified: serializer.fromJson<int?>(json['modified']),
      crdtClock: serializer.fromJson<String>(json['crdtClock']),
      crdtState: serializer.fromJson<String>(json['crdtState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'icon': serializer.toJson<String?>(icon),
      'taskIds': serializer.toJson<String>(taskIds),
      'theme': serializer.toJson<String>(theme),
      'advancedCfg': serializer.toJson<String>(advancedCfg),
      'created': serializer.toJson<int>(created),
      'modified': serializer.toJson<int?>(modified),
      'crdtClock': serializer.toJson<String>(crdtClock),
      'crdtState': serializer.toJson<String>(crdtState),
    };
  }

  Tag copyWith({
    String? id,
    String? title,
    Value<String?> icon = const Value.absent(),
    String? taskIds,
    String? theme,
    String? advancedCfg,
    int? created,
    Value<int?> modified = const Value.absent(),
    String? crdtClock,
    String? crdtState,
  }) => Tag(
    id: id ?? this.id,
    title: title ?? this.title,
    icon: icon.present ? icon.value : this.icon,
    taskIds: taskIds ?? this.taskIds,
    theme: theme ?? this.theme,
    advancedCfg: advancedCfg ?? this.advancedCfg,
    created: created ?? this.created,
    modified: modified.present ? modified.value : this.modified,
    crdtClock: crdtClock ?? this.crdtClock,
    crdtState: crdtState ?? this.crdtState,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      icon: data.icon.present ? data.icon.value : this.icon,
      taskIds: data.taskIds.present ? data.taskIds.value : this.taskIds,
      theme: data.theme.present ? data.theme.value : this.theme,
      advancedCfg: data.advancedCfg.present
          ? data.advancedCfg.value
          : this.advancedCfg,
      created: data.created.present ? data.created.value : this.created,
      modified: data.modified.present ? data.modified.value : this.modified,
      crdtClock: data.crdtClock.present ? data.crdtClock.value : this.crdtClock,
      crdtState: data.crdtState.present ? data.crdtState.value : this.crdtState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('taskIds: $taskIds, ')
          ..write('theme: $theme, ')
          ..write('advancedCfg: $advancedCfg, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    icon,
    taskIds,
    theme,
    advancedCfg,
    created,
    modified,
    crdtClock,
    crdtState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.title == this.title &&
          other.icon == this.icon &&
          other.taskIds == this.taskIds &&
          other.theme == this.theme &&
          other.advancedCfg == this.advancedCfg &&
          other.created == this.created &&
          other.modified == this.modified &&
          other.crdtClock == this.crdtClock &&
          other.crdtState == this.crdtState);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> icon;
  final Value<String> taskIds;
  final Value<String> theme;
  final Value<String> advancedCfg;
  final Value<int> created;
  final Value<int?> modified;
  final Value<String> crdtClock;
  final Value<String> crdtState;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.icon = const Value.absent(),
    this.taskIds = const Value.absent(),
    this.theme = const Value.absent(),
    this.advancedCfg = const Value.absent(),
    this.created = const Value.absent(),
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String title,
    this.icon = const Value.absent(),
    this.taskIds = const Value.absent(),
    this.theme = const Value.absent(),
    this.advancedCfg = const Value.absent(),
    required int created,
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       created = Value(created);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? icon,
    Expression<String>? taskIds,
    Expression<String>? theme,
    Expression<String>? advancedCfg,
    Expression<int>? created,
    Expression<int>? modified,
    Expression<String>? crdtClock,
    Expression<String>? crdtState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (icon != null) 'icon': icon,
      if (taskIds != null) 'task_ids': taskIds,
      if (theme != null) 'theme': theme,
      if (advancedCfg != null) 'advanced_cfg': advancedCfg,
      if (created != null) 'created': created,
      if (modified != null) 'modified': modified,
      if (crdtClock != null) 'crdt_clock': crdtClock,
      if (crdtState != null) 'crdt_state': crdtState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? icon,
    Value<String>? taskIds,
    Value<String>? theme,
    Value<String>? advancedCfg,
    Value<int>? created,
    Value<int?>? modified,
    Value<String>? crdtClock,
    Value<String>? crdtState,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      taskIds: taskIds ?? this.taskIds,
      theme: theme ?? this.theme,
      advancedCfg: advancedCfg ?? this.advancedCfg,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      crdtClock: crdtClock ?? this.crdtClock,
      crdtState: crdtState ?? this.crdtState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (taskIds.present) {
      map['task_ids'] = Variable<String>(taskIds.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (advancedCfg.present) {
      map['advanced_cfg'] = Variable<String>(advancedCfg.value);
    }
    if (created.present) {
      map['created'] = Variable<int>(created.value);
    }
    if (modified.present) {
      map['modified'] = Variable<int>(modified.value);
    }
    if (crdtClock.present) {
      map['crdt_clock'] = Variable<String>(crdtClock.value);
    }
    if (crdtState.present) {
      map['crdt_state'] = Variable<String>(crdtState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('taskIds: $taskIds, ')
          ..write('theme: $theme, ')
          ..write('advancedCfg: $advancedCfg, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorklogEntriesTable extends WorklogEntries
    with TableInfo<$WorklogEntriesTable, WorklogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorklogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<int> start = GeneratedColumn<int>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<int> end = GeneratedColumn<int>(
    'end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jiraWorklogIdMeta = const VerificationMeta(
    'jiraWorklogId',
  );
  @override
  late final GeneratedColumn<String> jiraWorklogId = GeneratedColumn<String>(
    'jira_worklog_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  @override
  late final GeneratedColumn<int> updated = GeneratedColumn<int>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _crdtClockMeta = const VerificationMeta(
    'crdtClock',
  );
  @override
  late final GeneratedColumn<String> crdtClock = GeneratedColumn<String>(
    'crdt_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _crdtStateMeta = const VerificationMeta(
    'crdtState',
  );
  @override
  late final GeneratedColumn<String> crdtState = GeneratedColumn<String>(
    'crdt_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    start,
    end,
    duration,
    date,
    comment,
    jiraWorklogId,
    created,
    updated,
    crdtClock,
    crdtState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'worklog_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorklogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('jira_worklog_id')) {
      context.handle(
        _jiraWorklogIdMeta,
        jiraWorklogId.isAcceptableOrUnknown(
          data['jira_worklog_id']!,
          _jiraWorklogIdMeta,
        ),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    if (data.containsKey('crdt_clock')) {
      context.handle(
        _crdtClockMeta,
        crdtClock.isAcceptableOrUnknown(data['crdt_clock']!, _crdtClockMeta),
      );
    }
    if (data.containsKey('crdt_state')) {
      context.handle(
        _crdtStateMeta,
        crdtState.isAcceptableOrUnknown(data['crdt_state']!, _crdtStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorklogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorklogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start'],
      )!,
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      jiraWorklogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jira_worklog_id'],
      ),
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated'],
      )!,
      crdtClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_clock'],
      )!,
      crdtState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_state'],
      )!,
    );
  }

  @override
  $WorklogEntriesTable createAlias(String alias) {
    return $WorklogEntriesTable(attachedDatabase, alias);
  }
}

class WorklogEntry extends DataClass implements Insertable<WorklogEntry> {
  final String id;
  final String taskId;
  final int start;
  final int end;
  final int duration;
  final String date;
  final String? comment;
  final String? jiraWorklogId;
  final int created;
  final int updated;
  final String crdtClock;
  final String crdtState;
  const WorklogEntry({
    required this.id,
    required this.taskId,
    required this.start,
    required this.end,
    required this.duration,
    required this.date,
    this.comment,
    this.jiraWorklogId,
    required this.created,
    required this.updated,
    required this.crdtClock,
    required this.crdtState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['start'] = Variable<int>(start);
    map['end'] = Variable<int>(end);
    map['duration'] = Variable<int>(duration);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    if (!nullToAbsent || jiraWorklogId != null) {
      map['jira_worklog_id'] = Variable<String>(jiraWorklogId);
    }
    map['created'] = Variable<int>(created);
    map['updated'] = Variable<int>(updated);
    map['crdt_clock'] = Variable<String>(crdtClock);
    map['crdt_state'] = Variable<String>(crdtState);
    return map;
  }

  WorklogEntriesCompanion toCompanion(bool nullToAbsent) {
    return WorklogEntriesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      start: Value(start),
      end: Value(end),
      duration: Value(duration),
      date: Value(date),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      jiraWorklogId: jiraWorklogId == null && nullToAbsent
          ? const Value.absent()
          : Value(jiraWorklogId),
      created: Value(created),
      updated: Value(updated),
      crdtClock: Value(crdtClock),
      crdtState: Value(crdtState),
    );
  }

  factory WorklogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorklogEntry(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      start: serializer.fromJson<int>(json['start']),
      end: serializer.fromJson<int>(json['end']),
      duration: serializer.fromJson<int>(json['duration']),
      date: serializer.fromJson<String>(json['date']),
      comment: serializer.fromJson<String?>(json['comment']),
      jiraWorklogId: serializer.fromJson<String?>(json['jiraWorklogId']),
      created: serializer.fromJson<int>(json['created']),
      updated: serializer.fromJson<int>(json['updated']),
      crdtClock: serializer.fromJson<String>(json['crdtClock']),
      crdtState: serializer.fromJson<String>(json['crdtState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'start': serializer.toJson<int>(start),
      'end': serializer.toJson<int>(end),
      'duration': serializer.toJson<int>(duration),
      'date': serializer.toJson<String>(date),
      'comment': serializer.toJson<String?>(comment),
      'jiraWorklogId': serializer.toJson<String?>(jiraWorklogId),
      'created': serializer.toJson<int>(created),
      'updated': serializer.toJson<int>(updated),
      'crdtClock': serializer.toJson<String>(crdtClock),
      'crdtState': serializer.toJson<String>(crdtState),
    };
  }

  WorklogEntry copyWith({
    String? id,
    String? taskId,
    int? start,
    int? end,
    int? duration,
    String? date,
    Value<String?> comment = const Value.absent(),
    Value<String?> jiraWorklogId = const Value.absent(),
    int? created,
    int? updated,
    String? crdtClock,
    String? crdtState,
  }) => WorklogEntry(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    start: start ?? this.start,
    end: end ?? this.end,
    duration: duration ?? this.duration,
    date: date ?? this.date,
    comment: comment.present ? comment.value : this.comment,
    jiraWorklogId: jiraWorklogId.present
        ? jiraWorklogId.value
        : this.jiraWorklogId,
    created: created ?? this.created,
    updated: updated ?? this.updated,
    crdtClock: crdtClock ?? this.crdtClock,
    crdtState: crdtState ?? this.crdtState,
  );
  WorklogEntry copyWithCompanion(WorklogEntriesCompanion data) {
    return WorklogEntry(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      duration: data.duration.present ? data.duration.value : this.duration,
      date: data.date.present ? data.date.value : this.date,
      comment: data.comment.present ? data.comment.value : this.comment,
      jiraWorklogId: data.jiraWorklogId.present
          ? data.jiraWorklogId.value
          : this.jiraWorklogId,
      created: data.created.present ? data.created.value : this.created,
      updated: data.updated.present ? data.updated.value : this.updated,
      crdtClock: data.crdtClock.present ? data.crdtClock.value : this.crdtClock,
      crdtState: data.crdtState.present ? data.crdtState.value : this.crdtState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorklogEntry(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('duration: $duration, ')
          ..write('date: $date, ')
          ..write('comment: $comment, ')
          ..write('jiraWorklogId: $jiraWorklogId, ')
          ..write('created: $created, ')
          ..write('updated: $updated, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    start,
    end,
    duration,
    date,
    comment,
    jiraWorklogId,
    created,
    updated,
    crdtClock,
    crdtState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorklogEntry &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.start == this.start &&
          other.end == this.end &&
          other.duration == this.duration &&
          other.date == this.date &&
          other.comment == this.comment &&
          other.jiraWorklogId == this.jiraWorklogId &&
          other.created == this.created &&
          other.updated == this.updated &&
          other.crdtClock == this.crdtClock &&
          other.crdtState == this.crdtState);
}

class WorklogEntriesCompanion extends UpdateCompanion<WorklogEntry> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<int> start;
  final Value<int> end;
  final Value<int> duration;
  final Value<String> date;
  final Value<String?> comment;
  final Value<String?> jiraWorklogId;
  final Value<int> created;
  final Value<int> updated;
  final Value<String> crdtClock;
  final Value<String> crdtState;
  final Value<int> rowid;
  const WorklogEntriesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.duration = const Value.absent(),
    this.date = const Value.absent(),
    this.comment = const Value.absent(),
    this.jiraWorklogId = const Value.absent(),
    this.created = const Value.absent(),
    this.updated = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorklogEntriesCompanion.insert({
    required String id,
    required String taskId,
    required int start,
    required int end,
    required int duration,
    required String date,
    this.comment = const Value.absent(),
    this.jiraWorklogId = const Value.absent(),
    required int created,
    required int updated,
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       start = Value(start),
       end = Value(end),
       duration = Value(duration),
       date = Value(date),
       created = Value(created),
       updated = Value(updated);
  static Insertable<WorklogEntry> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<int>? start,
    Expression<int>? end,
    Expression<int>? duration,
    Expression<String>? date,
    Expression<String>? comment,
    Expression<String>? jiraWorklogId,
    Expression<int>? created,
    Expression<int>? updated,
    Expression<String>? crdtClock,
    Expression<String>? crdtState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (duration != null) 'duration': duration,
      if (date != null) 'date': date,
      if (comment != null) 'comment': comment,
      if (jiraWorklogId != null) 'jira_worklog_id': jiraWorklogId,
      if (created != null) 'created': created,
      if (updated != null) 'updated': updated,
      if (crdtClock != null) 'crdt_clock': crdtClock,
      if (crdtState != null) 'crdt_state': crdtState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorklogEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<int>? start,
    Value<int>? end,
    Value<int>? duration,
    Value<String>? date,
    Value<String?>? comment,
    Value<String?>? jiraWorklogId,
    Value<int>? created,
    Value<int>? updated,
    Value<String>? crdtClock,
    Value<String>? crdtState,
    Value<int>? rowid,
  }) {
    return WorklogEntriesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      start: start ?? this.start,
      end: end ?? this.end,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      comment: comment ?? this.comment,
      jiraWorklogId: jiraWorklogId ?? this.jiraWorklogId,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      crdtClock: crdtClock ?? this.crdtClock,
      crdtState: crdtState ?? this.crdtState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (start.present) {
      map['start'] = Variable<int>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<int>(end.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (jiraWorklogId.present) {
      map['jira_worklog_id'] = Variable<String>(jiraWorklogId.value);
    }
    if (created.present) {
      map['created'] = Variable<int>(created.value);
    }
    if (updated.present) {
      map['updated'] = Variable<int>(updated.value);
    }
    if (crdtClock.present) {
      map['crdt_clock'] = Variable<String>(crdtClock.value);
    }
    if (crdtState.present) {
      map['crdt_state'] = Variable<String>(crdtState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorklogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('duration: $duration, ')
          ..write('date: $date, ')
          ..write('comment: $comment, ')
          ..write('jiraWorklogId: $jiraWorklogId, ')
          ..write('created: $created, ')
          ..write('updated: $updated, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JiraIntegrationsTable extends JiraIntegrations
    with TableInfo<$JiraIntegrationsTable, JiraIntegration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JiraIntegrationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _jiraProjectKeyMeta = const VerificationMeta(
    'jiraProjectKey',
  );
  @override
  late final GeneratedColumn<String> jiraProjectKey = GeneratedColumn<String>(
    'jira_project_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _credentialsFilePathMeta =
      const VerificationMeta('credentialsFilePath');
  @override
  late final GeneratedColumn<String> credentialsFilePath =
      GeneratedColumn<String>(
        'credentials_file_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _jqlFilterMeta = const VerificationMeta(
    'jqlFilter',
  );
  @override
  late final GeneratedColumn<String> jqlFilter = GeneratedColumn<String>(
    'jql_filter',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncEnabledMeta = const VerificationMeta(
    'syncEnabled',
  );
  @override
  late final GeneratedColumn<bool> syncEnabled = GeneratedColumn<bool>(
    'sync_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncSubtasksMeta = const VerificationMeta(
    'syncSubtasks',
  );
  @override
  late final GeneratedColumn<bool> syncSubtasks = GeneratedColumn<bool>(
    'sync_subtasks',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_subtasks" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _syncWorklogsMeta = const VerificationMeta(
    'syncWorklogs',
  );
  @override
  late final GeneratedColumn<bool> syncWorklogs = GeneratedColumn<bool>(
    'sync_worklogs',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_worklogs" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncIntervalMinutesMeta =
      const VerificationMeta('syncIntervalMinutes');
  @override
  late final GeneratedColumn<int> syncIntervalMinutes = GeneratedColumn<int>(
    'sync_interval_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(15),
  );
  static const VerificationMeta _fieldMappingsMeta = const VerificationMeta(
    'fieldMappings',
  );
  @override
  late final GeneratedColumn<String> fieldMappings = GeneratedColumn<String>(
    'field_mappings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _statusMappingsMeta = const VerificationMeta(
    'statusMappings',
  );
  @override
  late final GeneratedColumn<String> statusMappings = GeneratedColumn<String>(
    'status_mappings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncAt = GeneratedColumn<int>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<int> created = GeneratedColumn<int>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<int> modified = GeneratedColumn<int>(
    'modified',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _crdtClockMeta = const VerificationMeta(
    'crdtClock',
  );
  @override
  late final GeneratedColumn<String> crdtClock = GeneratedColumn<String>(
    'crdt_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _crdtStateMeta = const VerificationMeta(
    'crdtState',
  );
  @override
  late final GeneratedColumn<String> crdtState = GeneratedColumn<String>(
    'crdt_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    baseUrl,
    jiraProjectKey,
    boardId,
    credentialsFilePath,
    jqlFilter,
    syncEnabled,
    syncSubtasks,
    syncWorklogs,
    syncIntervalMinutes,
    fieldMappings,
    statusMappings,
    lastSyncAt,
    lastSyncError,
    created,
    modified,
    crdtClock,
    crdtState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'jira_integrations';
  @override
  VerificationContext validateIntegrity(
    Insertable<JiraIntegration> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('jira_project_key')) {
      context.handle(
        _jiraProjectKeyMeta,
        jiraProjectKey.isAcceptableOrUnknown(
          data['jira_project_key']!,
          _jiraProjectKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jiraProjectKeyMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    }
    if (data.containsKey('credentials_file_path')) {
      context.handle(
        _credentialsFilePathMeta,
        credentialsFilePath.isAcceptableOrUnknown(
          data['credentials_file_path']!,
          _credentialsFilePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_credentialsFilePathMeta);
    }
    if (data.containsKey('jql_filter')) {
      context.handle(
        _jqlFilterMeta,
        jqlFilter.isAcceptableOrUnknown(data['jql_filter']!, _jqlFilterMeta),
      );
    }
    if (data.containsKey('sync_enabled')) {
      context.handle(
        _syncEnabledMeta,
        syncEnabled.isAcceptableOrUnknown(
          data['sync_enabled']!,
          _syncEnabledMeta,
        ),
      );
    }
    if (data.containsKey('sync_subtasks')) {
      context.handle(
        _syncSubtasksMeta,
        syncSubtasks.isAcceptableOrUnknown(
          data['sync_subtasks']!,
          _syncSubtasksMeta,
        ),
      );
    }
    if (data.containsKey('sync_worklogs')) {
      context.handle(
        _syncWorklogsMeta,
        syncWorklogs.isAcceptableOrUnknown(
          data['sync_worklogs']!,
          _syncWorklogsMeta,
        ),
      );
    }
    if (data.containsKey('sync_interval_minutes')) {
      context.handle(
        _syncIntervalMinutesMeta,
        syncIntervalMinutes.isAcceptableOrUnknown(
          data['sync_interval_minutes']!,
          _syncIntervalMinutesMeta,
        ),
      );
    }
    if (data.containsKey('field_mappings')) {
      context.handle(
        _fieldMappingsMeta,
        fieldMappings.isAcceptableOrUnknown(
          data['field_mappings']!,
          _fieldMappingsMeta,
        ),
      );
    }
    if (data.containsKey('status_mappings')) {
      context.handle(
        _statusMappingsMeta,
        statusMappings.isAcceptableOrUnknown(
          data['status_mappings']!,
          _statusMappingsMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    }
    if (data.containsKey('crdt_clock')) {
      context.handle(
        _crdtClockMeta,
        crdtClock.isAcceptableOrUnknown(data['crdt_clock']!, _crdtClockMeta),
      );
    }
    if (data.containsKey('crdt_state')) {
      context.handle(
        _crdtStateMeta,
        crdtState.isAcceptableOrUnknown(data['crdt_state']!, _crdtStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JiraIntegration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JiraIntegration(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      jiraProjectKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jira_project_key'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      ),
      credentialsFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credentials_file_path'],
      )!,
      jqlFilter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jql_filter'],
      ),
      syncEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_enabled'],
      )!,
      syncSubtasks: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_subtasks'],
      )!,
      syncWorklogs: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_worklogs'],
      )!,
      syncIntervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_interval_minutes'],
      )!,
      fieldMappings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_mappings'],
      )!,
      statusMappings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_mappings'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync_at'],
      ),
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created'],
      )!,
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified'],
      ),
      crdtClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_clock'],
      )!,
      crdtState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_state'],
      )!,
    );
  }

  @override
  $JiraIntegrationsTable createAlias(String alias) {
    return $JiraIntegrationsTable(attachedDatabase, alias);
  }
}

class JiraIntegration extends DataClass implements Insertable<JiraIntegration> {
  final String id;
  final String? projectId;
  final String baseUrl;
  final String jiraProjectKey;
  final String? boardId;
  final String credentialsFilePath;
  final String? jqlFilter;
  final bool syncEnabled;
  final bool syncSubtasks;
  final bool syncWorklogs;
  final int syncIntervalMinutes;
  final String fieldMappings;
  final String statusMappings;
  final int? lastSyncAt;
  final String? lastSyncError;
  final int created;
  final int? modified;
  final String crdtClock;
  final String crdtState;
  const JiraIntegration({
    required this.id,
    this.projectId,
    required this.baseUrl,
    required this.jiraProjectKey,
    this.boardId,
    required this.credentialsFilePath,
    this.jqlFilter,
    required this.syncEnabled,
    required this.syncSubtasks,
    required this.syncWorklogs,
    required this.syncIntervalMinutes,
    required this.fieldMappings,
    required this.statusMappings,
    this.lastSyncAt,
    this.lastSyncError,
    required this.created,
    this.modified,
    required this.crdtClock,
    required this.crdtState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['base_url'] = Variable<String>(baseUrl);
    map['jira_project_key'] = Variable<String>(jiraProjectKey);
    if (!nullToAbsent || boardId != null) {
      map['board_id'] = Variable<String>(boardId);
    }
    map['credentials_file_path'] = Variable<String>(credentialsFilePath);
    if (!nullToAbsent || jqlFilter != null) {
      map['jql_filter'] = Variable<String>(jqlFilter);
    }
    map['sync_enabled'] = Variable<bool>(syncEnabled);
    map['sync_subtasks'] = Variable<bool>(syncSubtasks);
    map['sync_worklogs'] = Variable<bool>(syncWorklogs);
    map['sync_interval_minutes'] = Variable<int>(syncIntervalMinutes);
    map['field_mappings'] = Variable<String>(fieldMappings);
    map['status_mappings'] = Variable<String>(statusMappings);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<int>(lastSyncAt);
    }
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    map['created'] = Variable<int>(created);
    if (!nullToAbsent || modified != null) {
      map['modified'] = Variable<int>(modified);
    }
    map['crdt_clock'] = Variable<String>(crdtClock);
    map['crdt_state'] = Variable<String>(crdtState);
    return map;
  }

  JiraIntegrationsCompanion toCompanion(bool nullToAbsent) {
    return JiraIntegrationsCompanion(
      id: Value(id),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      baseUrl: Value(baseUrl),
      jiraProjectKey: Value(jiraProjectKey),
      boardId: boardId == null && nullToAbsent
          ? const Value.absent()
          : Value(boardId),
      credentialsFilePath: Value(credentialsFilePath),
      jqlFilter: jqlFilter == null && nullToAbsent
          ? const Value.absent()
          : Value(jqlFilter),
      syncEnabled: Value(syncEnabled),
      syncSubtasks: Value(syncSubtasks),
      syncWorklogs: Value(syncWorklogs),
      syncIntervalMinutes: Value(syncIntervalMinutes),
      fieldMappings: Value(fieldMappings),
      statusMappings: Value(statusMappings),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
      created: Value(created),
      modified: modified == null && nullToAbsent
          ? const Value.absent()
          : Value(modified),
      crdtClock: Value(crdtClock),
      crdtState: Value(crdtState),
    );
  }

  factory JiraIntegration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JiraIntegration(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      jiraProjectKey: serializer.fromJson<String>(json['jiraProjectKey']),
      boardId: serializer.fromJson<String?>(json['boardId']),
      credentialsFilePath: serializer.fromJson<String>(
        json['credentialsFilePath'],
      ),
      jqlFilter: serializer.fromJson<String?>(json['jqlFilter']),
      syncEnabled: serializer.fromJson<bool>(json['syncEnabled']),
      syncSubtasks: serializer.fromJson<bool>(json['syncSubtasks']),
      syncWorklogs: serializer.fromJson<bool>(json['syncWorklogs']),
      syncIntervalMinutes: serializer.fromJson<int>(
        json['syncIntervalMinutes'],
      ),
      fieldMappings: serializer.fromJson<String>(json['fieldMappings']),
      statusMappings: serializer.fromJson<String>(json['statusMappings']),
      lastSyncAt: serializer.fromJson<int?>(json['lastSyncAt']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
      created: serializer.fromJson<int>(json['created']),
      modified: serializer.fromJson<int?>(json['modified']),
      crdtClock: serializer.fromJson<String>(json['crdtClock']),
      crdtState: serializer.fromJson<String>(json['crdtState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String?>(projectId),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'jiraProjectKey': serializer.toJson<String>(jiraProjectKey),
      'boardId': serializer.toJson<String?>(boardId),
      'credentialsFilePath': serializer.toJson<String>(credentialsFilePath),
      'jqlFilter': serializer.toJson<String?>(jqlFilter),
      'syncEnabled': serializer.toJson<bool>(syncEnabled),
      'syncSubtasks': serializer.toJson<bool>(syncSubtasks),
      'syncWorklogs': serializer.toJson<bool>(syncWorklogs),
      'syncIntervalMinutes': serializer.toJson<int>(syncIntervalMinutes),
      'fieldMappings': serializer.toJson<String>(fieldMappings),
      'statusMappings': serializer.toJson<String>(statusMappings),
      'lastSyncAt': serializer.toJson<int?>(lastSyncAt),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'created': serializer.toJson<int>(created),
      'modified': serializer.toJson<int?>(modified),
      'crdtClock': serializer.toJson<String>(crdtClock),
      'crdtState': serializer.toJson<String>(crdtState),
    };
  }

  JiraIntegration copyWith({
    String? id,
    Value<String?> projectId = const Value.absent(),
    String? baseUrl,
    String? jiraProjectKey,
    Value<String?> boardId = const Value.absent(),
    String? credentialsFilePath,
    Value<String?> jqlFilter = const Value.absent(),
    bool? syncEnabled,
    bool? syncSubtasks,
    bool? syncWorklogs,
    int? syncIntervalMinutes,
    String? fieldMappings,
    String? statusMappings,
    Value<int?> lastSyncAt = const Value.absent(),
    Value<String?> lastSyncError = const Value.absent(),
    int? created,
    Value<int?> modified = const Value.absent(),
    String? crdtClock,
    String? crdtState,
  }) => JiraIntegration(
    id: id ?? this.id,
    projectId: projectId.present ? projectId.value : this.projectId,
    baseUrl: baseUrl ?? this.baseUrl,
    jiraProjectKey: jiraProjectKey ?? this.jiraProjectKey,
    boardId: boardId.present ? boardId.value : this.boardId,
    credentialsFilePath: credentialsFilePath ?? this.credentialsFilePath,
    jqlFilter: jqlFilter.present ? jqlFilter.value : this.jqlFilter,
    syncEnabled: syncEnabled ?? this.syncEnabled,
    syncSubtasks: syncSubtasks ?? this.syncSubtasks,
    syncWorklogs: syncWorklogs ?? this.syncWorklogs,
    syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
    fieldMappings: fieldMappings ?? this.fieldMappings,
    statusMappings: statusMappings ?? this.statusMappings,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
    created: created ?? this.created,
    modified: modified.present ? modified.value : this.modified,
    crdtClock: crdtClock ?? this.crdtClock,
    crdtState: crdtState ?? this.crdtState,
  );
  JiraIntegration copyWithCompanion(JiraIntegrationsCompanion data) {
    return JiraIntegration(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      jiraProjectKey: data.jiraProjectKey.present
          ? data.jiraProjectKey.value
          : this.jiraProjectKey,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      credentialsFilePath: data.credentialsFilePath.present
          ? data.credentialsFilePath.value
          : this.credentialsFilePath,
      jqlFilter: data.jqlFilter.present ? data.jqlFilter.value : this.jqlFilter,
      syncEnabled: data.syncEnabled.present
          ? data.syncEnabled.value
          : this.syncEnabled,
      syncSubtasks: data.syncSubtasks.present
          ? data.syncSubtasks.value
          : this.syncSubtasks,
      syncWorklogs: data.syncWorklogs.present
          ? data.syncWorklogs.value
          : this.syncWorklogs,
      syncIntervalMinutes: data.syncIntervalMinutes.present
          ? data.syncIntervalMinutes.value
          : this.syncIntervalMinutes,
      fieldMappings: data.fieldMappings.present
          ? data.fieldMappings.value
          : this.fieldMappings,
      statusMappings: data.statusMappings.present
          ? data.statusMappings.value
          : this.statusMappings,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
      created: data.created.present ? data.created.value : this.created,
      modified: data.modified.present ? data.modified.value : this.modified,
      crdtClock: data.crdtClock.present ? data.crdtClock.value : this.crdtClock,
      crdtState: data.crdtState.present ? data.crdtState.value : this.crdtState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JiraIntegration(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('jiraProjectKey: $jiraProjectKey, ')
          ..write('boardId: $boardId, ')
          ..write('credentialsFilePath: $credentialsFilePath, ')
          ..write('jqlFilter: $jqlFilter, ')
          ..write('syncEnabled: $syncEnabled, ')
          ..write('syncSubtasks: $syncSubtasks, ')
          ..write('syncWorklogs: $syncWorklogs, ')
          ..write('syncIntervalMinutes: $syncIntervalMinutes, ')
          ..write('fieldMappings: $fieldMappings, ')
          ..write('statusMappings: $statusMappings, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    baseUrl,
    jiraProjectKey,
    boardId,
    credentialsFilePath,
    jqlFilter,
    syncEnabled,
    syncSubtasks,
    syncWorklogs,
    syncIntervalMinutes,
    fieldMappings,
    statusMappings,
    lastSyncAt,
    lastSyncError,
    created,
    modified,
    crdtClock,
    crdtState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JiraIntegration &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.baseUrl == this.baseUrl &&
          other.jiraProjectKey == this.jiraProjectKey &&
          other.boardId == this.boardId &&
          other.credentialsFilePath == this.credentialsFilePath &&
          other.jqlFilter == this.jqlFilter &&
          other.syncEnabled == this.syncEnabled &&
          other.syncSubtasks == this.syncSubtasks &&
          other.syncWorklogs == this.syncWorklogs &&
          other.syncIntervalMinutes == this.syncIntervalMinutes &&
          other.fieldMappings == this.fieldMappings &&
          other.statusMappings == this.statusMappings &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastSyncError == this.lastSyncError &&
          other.created == this.created &&
          other.modified == this.modified &&
          other.crdtClock == this.crdtClock &&
          other.crdtState == this.crdtState);
}

class JiraIntegrationsCompanion extends UpdateCompanion<JiraIntegration> {
  final Value<String> id;
  final Value<String?> projectId;
  final Value<String> baseUrl;
  final Value<String> jiraProjectKey;
  final Value<String?> boardId;
  final Value<String> credentialsFilePath;
  final Value<String?> jqlFilter;
  final Value<bool> syncEnabled;
  final Value<bool> syncSubtasks;
  final Value<bool> syncWorklogs;
  final Value<int> syncIntervalMinutes;
  final Value<String> fieldMappings;
  final Value<String> statusMappings;
  final Value<int?> lastSyncAt;
  final Value<String?> lastSyncError;
  final Value<int> created;
  final Value<int?> modified;
  final Value<String> crdtClock;
  final Value<String> crdtState;
  final Value<int> rowid;
  const JiraIntegrationsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.jiraProjectKey = const Value.absent(),
    this.boardId = const Value.absent(),
    this.credentialsFilePath = const Value.absent(),
    this.jqlFilter = const Value.absent(),
    this.syncEnabled = const Value.absent(),
    this.syncSubtasks = const Value.absent(),
    this.syncWorklogs = const Value.absent(),
    this.syncIntervalMinutes = const Value.absent(),
    this.fieldMappings = const Value.absent(),
    this.statusMappings = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.created = const Value.absent(),
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JiraIntegrationsCompanion.insert({
    required String id,
    this.projectId = const Value.absent(),
    required String baseUrl,
    required String jiraProjectKey,
    this.boardId = const Value.absent(),
    required String credentialsFilePath,
    this.jqlFilter = const Value.absent(),
    this.syncEnabled = const Value.absent(),
    this.syncSubtasks = const Value.absent(),
    this.syncWorklogs = const Value.absent(),
    this.syncIntervalMinutes = const Value.absent(),
    this.fieldMappings = const Value.absent(),
    this.statusMappings = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    required int created,
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       baseUrl = Value(baseUrl),
       jiraProjectKey = Value(jiraProjectKey),
       credentialsFilePath = Value(credentialsFilePath),
       created = Value(created);
  static Insertable<JiraIntegration> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? baseUrl,
    Expression<String>? jiraProjectKey,
    Expression<String>? boardId,
    Expression<String>? credentialsFilePath,
    Expression<String>? jqlFilter,
    Expression<bool>? syncEnabled,
    Expression<bool>? syncSubtasks,
    Expression<bool>? syncWorklogs,
    Expression<int>? syncIntervalMinutes,
    Expression<String>? fieldMappings,
    Expression<String>? statusMappings,
    Expression<int>? lastSyncAt,
    Expression<String>? lastSyncError,
    Expression<int>? created,
    Expression<int>? modified,
    Expression<String>? crdtClock,
    Expression<String>? crdtState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (baseUrl != null) 'base_url': baseUrl,
      if (jiraProjectKey != null) 'jira_project_key': jiraProjectKey,
      if (boardId != null) 'board_id': boardId,
      if (credentialsFilePath != null)
        'credentials_file_path': credentialsFilePath,
      if (jqlFilter != null) 'jql_filter': jqlFilter,
      if (syncEnabled != null) 'sync_enabled': syncEnabled,
      if (syncSubtasks != null) 'sync_subtasks': syncSubtasks,
      if (syncWorklogs != null) 'sync_worklogs': syncWorklogs,
      if (syncIntervalMinutes != null)
        'sync_interval_minutes': syncIntervalMinutes,
      if (fieldMappings != null) 'field_mappings': fieldMappings,
      if (statusMappings != null) 'status_mappings': statusMappings,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (created != null) 'created': created,
      if (modified != null) 'modified': modified,
      if (crdtClock != null) 'crdt_clock': crdtClock,
      if (crdtState != null) 'crdt_state': crdtState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JiraIntegrationsCompanion copyWith({
    Value<String>? id,
    Value<String?>? projectId,
    Value<String>? baseUrl,
    Value<String>? jiraProjectKey,
    Value<String?>? boardId,
    Value<String>? credentialsFilePath,
    Value<String?>? jqlFilter,
    Value<bool>? syncEnabled,
    Value<bool>? syncSubtasks,
    Value<bool>? syncWorklogs,
    Value<int>? syncIntervalMinutes,
    Value<String>? fieldMappings,
    Value<String>? statusMappings,
    Value<int?>? lastSyncAt,
    Value<String?>? lastSyncError,
    Value<int>? created,
    Value<int?>? modified,
    Value<String>? crdtClock,
    Value<String>? crdtState,
    Value<int>? rowid,
  }) {
    return JiraIntegrationsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      baseUrl: baseUrl ?? this.baseUrl,
      jiraProjectKey: jiraProjectKey ?? this.jiraProjectKey,
      boardId: boardId ?? this.boardId,
      credentialsFilePath: credentialsFilePath ?? this.credentialsFilePath,
      jqlFilter: jqlFilter ?? this.jqlFilter,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      syncSubtasks: syncSubtasks ?? this.syncSubtasks,
      syncWorklogs: syncWorklogs ?? this.syncWorklogs,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      fieldMappings: fieldMappings ?? this.fieldMappings,
      statusMappings: statusMappings ?? this.statusMappings,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      crdtClock: crdtClock ?? this.crdtClock,
      crdtState: crdtState ?? this.crdtState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (jiraProjectKey.present) {
      map['jira_project_key'] = Variable<String>(jiraProjectKey.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (credentialsFilePath.present) {
      map['credentials_file_path'] = Variable<String>(
        credentialsFilePath.value,
      );
    }
    if (jqlFilter.present) {
      map['jql_filter'] = Variable<String>(jqlFilter.value);
    }
    if (syncEnabled.present) {
      map['sync_enabled'] = Variable<bool>(syncEnabled.value);
    }
    if (syncSubtasks.present) {
      map['sync_subtasks'] = Variable<bool>(syncSubtasks.value);
    }
    if (syncWorklogs.present) {
      map['sync_worklogs'] = Variable<bool>(syncWorklogs.value);
    }
    if (syncIntervalMinutes.present) {
      map['sync_interval_minutes'] = Variable<int>(syncIntervalMinutes.value);
    }
    if (fieldMappings.present) {
      map['field_mappings'] = Variable<String>(fieldMappings.value);
    }
    if (statusMappings.present) {
      map['status_mappings'] = Variable<String>(statusMappings.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<int>(lastSyncAt.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (created.present) {
      map['created'] = Variable<int>(created.value);
    }
    if (modified.present) {
      map['modified'] = Variable<int>(modified.value);
    }
    if (crdtClock.present) {
      map['crdt_clock'] = Variable<String>(crdtClock.value);
    }
    if (crdtState.present) {
      map['crdt_state'] = Variable<String>(crdtState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JiraIntegrationsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('jiraProjectKey: $jiraProjectKey, ')
          ..write('boardId: $boardId, ')
          ..write('credentialsFilePath: $credentialsFilePath, ')
          ..write('jqlFilter: $jqlFilter, ')
          ..write('syncEnabled: $syncEnabled, ')
          ..write('syncSubtasks: $syncSubtasks, ')
          ..write('syncWorklogs: $syncWorklogs, ')
          ..write('syncIntervalMinutes: $syncIntervalMinutes, ')
          ..write('fieldMappings: $fieldMappings, ')
          ..write('statusMappings: $statusMappings, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimerEntriesTable extends TimerEntries
    with TableInfo<$TimerEntriesTable, TimerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskTitleMeta = const VerificationMeta(
    'taskTitle',
  );
  @override
  late final GeneratedColumn<String> taskTitle = GeneratedColumn<String>(
    'task_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectTitleMeta = const VerificationMeta(
    'projectTitle',
  );
  @override
  late final GeneratedColumn<String> projectTitle = GeneratedColumn<String>(
    'project_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isRunningMeta = const VerificationMeta(
    'isRunning',
  );
  @override
  late final GeneratedColumn<bool> isRunning = GeneratedColumn<bool>(
    'is_running',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_running" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pausedAtMeta = const VerificationMeta(
    'pausedAt',
  );
  @override
  late final GeneratedColumn<int> pausedAt = GeneratedColumn<int>(
    'paused_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accumulatedMsMeta = const VerificationMeta(
    'accumulatedMs',
  );
  @override
  late final GeneratedColumn<int> accumulatedMs = GeneratedColumn<int>(
    'accumulated_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _crdtClockMeta = const VerificationMeta(
    'crdtClock',
  );
  @override
  late final GeneratedColumn<String> crdtClock = GeneratedColumn<String>(
    'crdt_clock',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _crdtStateMeta = const VerificationMeta(
    'crdtState',
  );
  @override
  late final GeneratedColumn<String> crdtState = GeneratedColumn<String>(
    'crdt_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    taskTitle,
    projectId,
    projectTitle,
    startedAt,
    isRunning,
    pausedAt,
    accumulatedMs,
    note,
    crdtClock,
    crdtState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timer_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('task_title')) {
      context.handle(
        _taskTitleMeta,
        taskTitle.isAcceptableOrUnknown(data['task_title']!, _taskTitleMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('project_title')) {
      context.handle(
        _projectTitleMeta,
        projectTitle.isAcceptableOrUnknown(
          data['project_title']!,
          _projectTitleMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('is_running')) {
      context.handle(
        _isRunningMeta,
        isRunning.isAcceptableOrUnknown(data['is_running']!, _isRunningMeta),
      );
    }
    if (data.containsKey('paused_at')) {
      context.handle(
        _pausedAtMeta,
        pausedAt.isAcceptableOrUnknown(data['paused_at']!, _pausedAtMeta),
      );
    }
    if (data.containsKey('accumulated_ms')) {
      context.handle(
        _accumulatedMsMeta,
        accumulatedMs.isAcceptableOrUnknown(
          data['accumulated_ms']!,
          _accumulatedMsMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('crdt_clock')) {
      context.handle(
        _crdtClockMeta,
        crdtClock.isAcceptableOrUnknown(data['crdt_clock']!, _crdtClockMeta),
      );
    }
    if (data.containsKey('crdt_state')) {
      context.handle(
        _crdtStateMeta,
        crdtState.isAcceptableOrUnknown(data['crdt_state']!, _crdtStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      taskTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_title'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      projectTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_title'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      isRunning: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_running'],
      )!,
      pausedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_at'],
      ),
      accumulatedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accumulated_ms'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      crdtClock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_clock'],
      )!,
      crdtState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crdt_state'],
      )!,
    );
  }

  @override
  $TimerEntriesTable createAlias(String alias) {
    return $TimerEntriesTable(attachedDatabase, alias);
  }
}

class TimerEntry extends DataClass implements Insertable<TimerEntry> {
  /// Well-known ID: 'active-timer'
  final String id;

  /// Task ID being timed (null for ad-hoc).
  final String? taskId;

  /// Task title (denormalized for display).
  final String taskTitle;

  /// Project ID (null if no project).
  final String? projectId;

  /// Project title (denormalized for display).
  final String? projectTitle;

  /// When timer was started (Unix ms).
  final int startedAt;

  /// Whether timer is currently running.
  final bool isRunning;

  /// When timer was paused (Unix ms, null if not paused).
  final int? pausedAt;

  /// Time accumulated before pause (ms).
  final int accumulatedMs;

  /// Optional note about current work.
  final String? note;
  final String crdtClock;
  final String crdtState;
  const TimerEntry({
    required this.id,
    this.taskId,
    required this.taskTitle,
    this.projectId,
    this.projectTitle,
    required this.startedAt,
    required this.isRunning,
    this.pausedAt,
    required this.accumulatedMs,
    this.note,
    required this.crdtClock,
    required this.crdtState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['task_title'] = Variable<String>(taskTitle);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || projectTitle != null) {
      map['project_title'] = Variable<String>(projectTitle);
    }
    map['started_at'] = Variable<int>(startedAt);
    map['is_running'] = Variable<bool>(isRunning);
    if (!nullToAbsent || pausedAt != null) {
      map['paused_at'] = Variable<int>(pausedAt);
    }
    map['accumulated_ms'] = Variable<int>(accumulatedMs);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['crdt_clock'] = Variable<String>(crdtClock);
    map['crdt_state'] = Variable<String>(crdtState);
    return map;
  }

  TimerEntriesCompanion toCompanion(bool nullToAbsent) {
    return TimerEntriesCompanion(
      id: Value(id),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      taskTitle: Value(taskTitle),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      projectTitle: projectTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(projectTitle),
      startedAt: Value(startedAt),
      isRunning: Value(isRunning),
      pausedAt: pausedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAt),
      accumulatedMs: Value(accumulatedMs),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      crdtClock: Value(crdtClock),
      crdtState: Value(crdtState),
    );
  }

  factory TimerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimerEntry(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      taskTitle: serializer.fromJson<String>(json['taskTitle']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      projectTitle: serializer.fromJson<String?>(json['projectTitle']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      isRunning: serializer.fromJson<bool>(json['isRunning']),
      pausedAt: serializer.fromJson<int?>(json['pausedAt']),
      accumulatedMs: serializer.fromJson<int>(json['accumulatedMs']),
      note: serializer.fromJson<String?>(json['note']),
      crdtClock: serializer.fromJson<String>(json['crdtClock']),
      crdtState: serializer.fromJson<String>(json['crdtState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String?>(taskId),
      'taskTitle': serializer.toJson<String>(taskTitle),
      'projectId': serializer.toJson<String?>(projectId),
      'projectTitle': serializer.toJson<String?>(projectTitle),
      'startedAt': serializer.toJson<int>(startedAt),
      'isRunning': serializer.toJson<bool>(isRunning),
      'pausedAt': serializer.toJson<int?>(pausedAt),
      'accumulatedMs': serializer.toJson<int>(accumulatedMs),
      'note': serializer.toJson<String?>(note),
      'crdtClock': serializer.toJson<String>(crdtClock),
      'crdtState': serializer.toJson<String>(crdtState),
    };
  }

  TimerEntry copyWith({
    String? id,
    Value<String?> taskId = const Value.absent(),
    String? taskTitle,
    Value<String?> projectId = const Value.absent(),
    Value<String?> projectTitle = const Value.absent(),
    int? startedAt,
    bool? isRunning,
    Value<int?> pausedAt = const Value.absent(),
    int? accumulatedMs,
    Value<String?> note = const Value.absent(),
    String? crdtClock,
    String? crdtState,
  }) => TimerEntry(
    id: id ?? this.id,
    taskId: taskId.present ? taskId.value : this.taskId,
    taskTitle: taskTitle ?? this.taskTitle,
    projectId: projectId.present ? projectId.value : this.projectId,
    projectTitle: projectTitle.present ? projectTitle.value : this.projectTitle,
    startedAt: startedAt ?? this.startedAt,
    isRunning: isRunning ?? this.isRunning,
    pausedAt: pausedAt.present ? pausedAt.value : this.pausedAt,
    accumulatedMs: accumulatedMs ?? this.accumulatedMs,
    note: note.present ? note.value : this.note,
    crdtClock: crdtClock ?? this.crdtClock,
    crdtState: crdtState ?? this.crdtState,
  );
  TimerEntry copyWithCompanion(TimerEntriesCompanion data) {
    return TimerEntry(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      taskTitle: data.taskTitle.present ? data.taskTitle.value : this.taskTitle,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      projectTitle: data.projectTitle.present
          ? data.projectTitle.value
          : this.projectTitle,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      isRunning: data.isRunning.present ? data.isRunning.value : this.isRunning,
      pausedAt: data.pausedAt.present ? data.pausedAt.value : this.pausedAt,
      accumulatedMs: data.accumulatedMs.present
          ? data.accumulatedMs.value
          : this.accumulatedMs,
      note: data.note.present ? data.note.value : this.note,
      crdtClock: data.crdtClock.present ? data.crdtClock.value : this.crdtClock,
      crdtState: data.crdtState.present ? data.crdtState.value : this.crdtState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimerEntry(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('taskTitle: $taskTitle, ')
          ..write('projectId: $projectId, ')
          ..write('projectTitle: $projectTitle, ')
          ..write('startedAt: $startedAt, ')
          ..write('isRunning: $isRunning, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('accumulatedMs: $accumulatedMs, ')
          ..write('note: $note, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    taskTitle,
    projectId,
    projectTitle,
    startedAt,
    isRunning,
    pausedAt,
    accumulatedMs,
    note,
    crdtClock,
    crdtState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerEntry &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.taskTitle == this.taskTitle &&
          other.projectId == this.projectId &&
          other.projectTitle == this.projectTitle &&
          other.startedAt == this.startedAt &&
          other.isRunning == this.isRunning &&
          other.pausedAt == this.pausedAt &&
          other.accumulatedMs == this.accumulatedMs &&
          other.note == this.note &&
          other.crdtClock == this.crdtClock &&
          other.crdtState == this.crdtState);
}

class TimerEntriesCompanion extends UpdateCompanion<TimerEntry> {
  final Value<String> id;
  final Value<String?> taskId;
  final Value<String> taskTitle;
  final Value<String?> projectId;
  final Value<String?> projectTitle;
  final Value<int> startedAt;
  final Value<bool> isRunning;
  final Value<int?> pausedAt;
  final Value<int> accumulatedMs;
  final Value<String?> note;
  final Value<String> crdtClock;
  final Value<String> crdtState;
  final Value<int> rowid;
  const TimerEntriesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.taskTitle = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectTitle = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.isRunning = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.accumulatedMs = const Value.absent(),
    this.note = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimerEntriesCompanion.insert({
    required String id,
    this.taskId = const Value.absent(),
    this.taskTitle = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectTitle = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.isRunning = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.accumulatedMs = const Value.absent(),
    this.note = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<TimerEntry> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? taskTitle,
    Expression<String>? projectId,
    Expression<String>? projectTitle,
    Expression<int>? startedAt,
    Expression<bool>? isRunning,
    Expression<int>? pausedAt,
    Expression<int>? accumulatedMs,
    Expression<String>? note,
    Expression<String>? crdtClock,
    Expression<String>? crdtState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (taskTitle != null) 'task_title': taskTitle,
      if (projectId != null) 'project_id': projectId,
      if (projectTitle != null) 'project_title': projectTitle,
      if (startedAt != null) 'started_at': startedAt,
      if (isRunning != null) 'is_running': isRunning,
      if (pausedAt != null) 'paused_at': pausedAt,
      if (accumulatedMs != null) 'accumulated_ms': accumulatedMs,
      if (note != null) 'note': note,
      if (crdtClock != null) 'crdt_clock': crdtClock,
      if (crdtState != null) 'crdt_state': crdtState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimerEntriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? taskId,
    Value<String>? taskTitle,
    Value<String?>? projectId,
    Value<String?>? projectTitle,
    Value<int>? startedAt,
    Value<bool>? isRunning,
    Value<int?>? pausedAt,
    Value<int>? accumulatedMs,
    Value<String?>? note,
    Value<String>? crdtClock,
    Value<String>? crdtState,
    Value<int>? rowid,
  }) {
    return TimerEntriesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      startedAt: startedAt ?? this.startedAt,
      isRunning: isRunning ?? this.isRunning,
      pausedAt: pausedAt ?? this.pausedAt,
      accumulatedMs: accumulatedMs ?? this.accumulatedMs,
      note: note ?? this.note,
      crdtClock: crdtClock ?? this.crdtClock,
      crdtState: crdtState ?? this.crdtState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (taskTitle.present) {
      map['task_title'] = Variable<String>(taskTitle.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (projectTitle.present) {
      map['project_title'] = Variable<String>(projectTitle.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (isRunning.present) {
      map['is_running'] = Variable<bool>(isRunning.value);
    }
    if (pausedAt.present) {
      map['paused_at'] = Variable<int>(pausedAt.value);
    }
    if (accumulatedMs.present) {
      map['accumulated_ms'] = Variable<int>(accumulatedMs.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (crdtClock.present) {
      map['crdt_clock'] = Variable<String>(crdtClock.value);
    }
    if (crdtState.present) {
      map['crdt_state'] = Variable<String>(crdtState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('taskTitle: $taskTitle, ')
          ..write('projectId: $projectId, ')
          ..write('projectTitle: $projectTitle, ')
          ..write('startedAt: $startedAt, ')
          ..write('isRunning: $isRunning, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('accumulatedMs: $accumulatedMs, ')
          ..write('note: $note, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $SubtasksTable subtasks = $SubtasksTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $WorklogEntriesTable worklogEntries = $WorklogEntriesTable(this);
  late final $JiraIntegrationsTable jiraIntegrations = $JiraIntegrationsTable(
    this,
  );
  late final $TimerEntriesTable timerEntries = $TimerEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    subtasks,
    projects,
    tags,
    worklogEntries,
    jiraIntegrations,
    timerEntries,
  ];
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      Value<String?> projectId,
      required String title,
      Value<String?> description,
      Value<bool> isDone,
      required int created,
      Value<int> timeSpent,
      Value<int> timeEstimate,
      Value<String> timeSpentOnDay,
      Value<int?> dueWithTime,
      Value<String?> dueDay,
      Value<String> tagIds,
      Value<String> attachments,
      Value<String?> reminderId,
      Value<int?> remindAt,
      Value<int?> doneOn,
      Value<int?> modified,
      Value<String?> repeatCfgId,
      Value<String?> issueId,
      Value<String?> issueProviderId,
      Value<String?> issueType,
      Value<bool?> issueWasUpdated,
      Value<int?> issueLastUpdated,
      Value<int?> issueAttachmentNr,
      Value<String?> issueTimeTracked,
      Value<int?> issuePoints,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String?> projectId,
      Value<String> title,
      Value<String?> description,
      Value<bool> isDone,
      Value<int> created,
      Value<int> timeSpent,
      Value<int> timeEstimate,
      Value<String> timeSpentOnDay,
      Value<int?> dueWithTime,
      Value<String?> dueDay,
      Value<String> tagIds,
      Value<String> attachments,
      Value<String?> reminderId,
      Value<int?> remindAt,
      Value<int?> doneOn,
      Value<int?> modified,
      Value<String?> repeatCfgId,
      Value<String?> issueId,
      Value<String?> issueProviderId,
      Value<String?> issueType,
      Value<bool?> issueWasUpdated,
      Value<int?> issueLastUpdated,
      Value<int?> issueAttachmentNr,
      Value<String?> issueTimeTracked,
      Value<int?> issuePoints,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
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

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSpent => $composableBuilder(
    column: $table.timeSpent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeEstimate => $composableBuilder(
    column: $table.timeEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeSpentOnDay => $composableBuilder(
    column: $table.timeSpentOnDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueWithTime => $composableBuilder(
    column: $table.dueWithTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagIds => $composableBuilder(
    column: $table.tagIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get doneOn => $composableBuilder(
    column: $table.doneOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatCfgId => $composableBuilder(
    column: $table.repeatCfgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueId => $composableBuilder(
    column: $table.issueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueProviderId => $composableBuilder(
    column: $table.issueProviderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueType => $composableBuilder(
    column: $table.issueType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get issueWasUpdated => $composableBuilder(
    column: $table.issueWasUpdated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get issueLastUpdated => $composableBuilder(
    column: $table.issueLastUpdated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get issueAttachmentNr => $composableBuilder(
    column: $table.issueAttachmentNr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueTimeTracked => $composableBuilder(
    column: $table.issueTimeTracked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get issuePoints => $composableBuilder(
    column: $table.issuePoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
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

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSpent => $composableBuilder(
    column: $table.timeSpent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeEstimate => $composableBuilder(
    column: $table.timeEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeSpentOnDay => $composableBuilder(
    column: $table.timeSpentOnDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueWithTime => $composableBuilder(
    column: $table.dueWithTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagIds => $composableBuilder(
    column: $table.tagIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get doneOn => $composableBuilder(
    column: $table.doneOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatCfgId => $composableBuilder(
    column: $table.repeatCfgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueId => $composableBuilder(
    column: $table.issueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueProviderId => $composableBuilder(
    column: $table.issueProviderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueType => $composableBuilder(
    column: $table.issueType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get issueWasUpdated => $composableBuilder(
    column: $table.issueWasUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get issueLastUpdated => $composableBuilder(
    column: $table.issueLastUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get issueAttachmentNr => $composableBuilder(
    column: $table.issueAttachmentNr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueTimeTracked => $composableBuilder(
    column: $table.issueTimeTracked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get issuePoints => $composableBuilder(
    column: $table.issuePoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<int> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<int> get timeSpent =>
      $composableBuilder(column: $table.timeSpent, builder: (column) => column);

  GeneratedColumn<int> get timeEstimate => $composableBuilder(
    column: $table.timeEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeSpentOnDay => $composableBuilder(
    column: $table.timeSpentOnDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueWithTime => $composableBuilder(
    column: $table.dueWithTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<String> get tagIds =>
      $composableBuilder(column: $table.tagIds, builder: (column) => column);

  GeneratedColumn<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  GeneratedColumn<int> get doneOn =>
      $composableBuilder(column: $table.doneOn, builder: (column) => column);

  GeneratedColumn<int> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<String> get repeatCfgId => $composableBuilder(
    column: $table.repeatCfgId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issueId =>
      $composableBuilder(column: $table.issueId, builder: (column) => column);

  GeneratedColumn<String> get issueProviderId => $composableBuilder(
    column: $table.issueProviderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issueType =>
      $composableBuilder(column: $table.issueType, builder: (column) => column);

  GeneratedColumn<bool> get issueWasUpdated => $composableBuilder(
    column: $table.issueWasUpdated,
    builder: (column) => column,
  );

  GeneratedColumn<int> get issueLastUpdated => $composableBuilder(
    column: $table.issueLastUpdated,
    builder: (column) => column,
  );

  GeneratedColumn<int> get issueAttachmentNr => $composableBuilder(
    column: $table.issueAttachmentNr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issueTimeTracked => $composableBuilder(
    column: $table.issueTimeTracked,
    builder: (column) => column,
  );

  GeneratedColumn<int> get issuePoints => $composableBuilder(
    column: $table.issuePoints,
    builder: (column) => column,
  );

  GeneratedColumn<String> get crdtClock =>
      $composableBuilder(column: $table.crdtClock, builder: (column) => column);

  GeneratedColumn<String> get crdtState =>
      $composableBuilder(column: $table.crdtState, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<int> created = const Value.absent(),
                Value<int> timeSpent = const Value.absent(),
                Value<int> timeEstimate = const Value.absent(),
                Value<String> timeSpentOnDay = const Value.absent(),
                Value<int?> dueWithTime = const Value.absent(),
                Value<String?> dueDay = const Value.absent(),
                Value<String> tagIds = const Value.absent(),
                Value<String> attachments = const Value.absent(),
                Value<String?> reminderId = const Value.absent(),
                Value<int?> remindAt = const Value.absent(),
                Value<int?> doneOn = const Value.absent(),
                Value<int?> modified = const Value.absent(),
                Value<String?> repeatCfgId = const Value.absent(),
                Value<String?> issueId = const Value.absent(),
                Value<String?> issueProviderId = const Value.absent(),
                Value<String?> issueType = const Value.absent(),
                Value<bool?> issueWasUpdated = const Value.absent(),
                Value<int?> issueLastUpdated = const Value.absent(),
                Value<int?> issueAttachmentNr = const Value.absent(),
                Value<String?> issueTimeTracked = const Value.absent(),
                Value<int?> issuePoints = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                projectId: projectId,
                title: title,
                description: description,
                isDone: isDone,
                created: created,
                timeSpent: timeSpent,
                timeEstimate: timeEstimate,
                timeSpentOnDay: timeSpentOnDay,
                dueWithTime: dueWithTime,
                dueDay: dueDay,
                tagIds: tagIds,
                attachments: attachments,
                reminderId: reminderId,
                remindAt: remindAt,
                doneOn: doneOn,
                modified: modified,
                repeatCfgId: repeatCfgId,
                issueId: issueId,
                issueProviderId: issueProviderId,
                issueType: issueType,
                issueWasUpdated: issueWasUpdated,
                issueLastUpdated: issueLastUpdated,
                issueAttachmentNr: issueAttachmentNr,
                issueTimeTracked: issueTimeTracked,
                issuePoints: issuePoints,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> projectId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                required int created,
                Value<int> timeSpent = const Value.absent(),
                Value<int> timeEstimate = const Value.absent(),
                Value<String> timeSpentOnDay = const Value.absent(),
                Value<int?> dueWithTime = const Value.absent(),
                Value<String?> dueDay = const Value.absent(),
                Value<String> tagIds = const Value.absent(),
                Value<String> attachments = const Value.absent(),
                Value<String?> reminderId = const Value.absent(),
                Value<int?> remindAt = const Value.absent(),
                Value<int?> doneOn = const Value.absent(),
                Value<int?> modified = const Value.absent(),
                Value<String?> repeatCfgId = const Value.absent(),
                Value<String?> issueId = const Value.absent(),
                Value<String?> issueProviderId = const Value.absent(),
                Value<String?> issueType = const Value.absent(),
                Value<bool?> issueWasUpdated = const Value.absent(),
                Value<int?> issueLastUpdated = const Value.absent(),
                Value<int?> issueAttachmentNr = const Value.absent(),
                Value<String?> issueTimeTracked = const Value.absent(),
                Value<int?> issuePoints = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                projectId: projectId,
                title: title,
                description: description,
                isDone: isDone,
                created: created,
                timeSpent: timeSpent,
                timeEstimate: timeEstimate,
                timeSpentOnDay: timeSpentOnDay,
                dueWithTime: dueWithTime,
                dueDay: dueDay,
                tagIds: tagIds,
                attachments: attachments,
                reminderId: reminderId,
                remindAt: remindAt,
                doneOn: doneOn,
                modified: modified,
                repeatCfgId: repeatCfgId,
                issueId: issueId,
                issueProviderId: issueProviderId,
                issueType: issueType,
                issueWasUpdated: issueWasUpdated,
                issueLastUpdated: issueLastUpdated,
                issueAttachmentNr: issueAttachmentNr,
                issueTimeTracked: issueTimeTracked,
                issuePoints: issuePoints,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$SubtasksTableCreateCompanionBuilder =
    SubtasksCompanion Function({
      required String id,
      required String taskId,
      required String title,
      Value<bool> isDone,
      Value<int> order,
      Value<String?> notes,
      required int created,
      Value<int?> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });
typedef $$SubtasksTableUpdateCompanionBuilder =
    SubtasksCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> title,
      Value<bool> isDone,
      Value<int> order,
      Value<String?> notes,
      Value<int> created,
      Value<int?> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });

class $$SubtasksTableFilterComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableFilterComposer({
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

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubtasksTableOrderingComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableOrderingComposer({
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

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubtasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<int> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<String> get crdtClock =>
      $composableBuilder(column: $table.crdtClock, builder: (column) => column);

  GeneratedColumn<String> get crdtState =>
      $composableBuilder(column: $table.crdtState, builder: (column) => column);
}

class $$SubtasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubtasksTable,
          Subtask,
          $$SubtasksTableFilterComposer,
          $$SubtasksTableOrderingComposer,
          $$SubtasksTableAnnotationComposer,
          $$SubtasksTableCreateCompanionBuilder,
          $$SubtasksTableUpdateCompanionBuilder,
          (Subtask, BaseReferences<_$AppDatabase, $SubtasksTable, Subtask>),
          Subtask,
          PrefetchHooks Function()
        > {
  $$SubtasksTableTableManager(_$AppDatabase db, $SubtasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubtasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubtasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubtasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> created = const Value.absent(),
                Value<int?> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubtasksCompanion(
                id: id,
                taskId: taskId,
                title: title,
                isDone: isDone,
                order: order,
                notes: notes,
                created: created,
                modified: modified,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String title,
                Value<bool> isDone = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required int created,
                Value<int?> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubtasksCompanion.insert(
                id: id,
                taskId: taskId,
                title: title,
                isDone: isDone,
                order: order,
                notes: notes,
                created: created,
                modified: modified,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubtasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubtasksTable,
      Subtask,
      $$SubtasksTableFilterComposer,
      $$SubtasksTableOrderingComposer,
      $$SubtasksTableAnnotationComposer,
      $$SubtasksTableCreateCompanionBuilder,
      $$SubtasksTableUpdateCompanionBuilder,
      (Subtask, BaseReferences<_$AppDatabase, $SubtasksTable, Subtask>),
      Subtask,
      PrefetchHooks Function()
    >;
typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      required String id,
      required String title,
      Value<bool> isArchived,
      Value<bool> isHiddenFromMenu,
      Value<bool> isEnableBacklog,
      Value<String> taskIds,
      Value<String> backlogTaskIds,
      Value<String> theme,
      Value<String> advancedCfg,
      Value<String?> icon,
      required int created,
      Value<int?> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<bool> isArchived,
      Value<bool> isHiddenFromMenu,
      Value<bool> isEnableBacklog,
      Value<String> taskIds,
      Value<String> backlogTaskIds,
      Value<String> theme,
      Value<String> advancedCfg,
      Value<String?> icon,
      Value<int> created,
      Value<int?> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
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

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHiddenFromMenu => $composableBuilder(
    column: $table.isHiddenFromMenu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnableBacklog => $composableBuilder(
    column: $table.isEnableBacklog,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskIds => $composableBuilder(
    column: $table.taskIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backlogTaskIds => $composableBuilder(
    column: $table.backlogTaskIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get advancedCfg => $composableBuilder(
    column: $table.advancedCfg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
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

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHiddenFromMenu => $composableBuilder(
    column: $table.isHiddenFromMenu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnableBacklog => $composableBuilder(
    column: $table.isEnableBacklog,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskIds => $composableBuilder(
    column: $table.taskIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backlogTaskIds => $composableBuilder(
    column: $table.backlogTaskIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get advancedCfg => $composableBuilder(
    column: $table.advancedCfg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
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

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isHiddenFromMenu => $composableBuilder(
    column: $table.isHiddenFromMenu,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnableBacklog => $composableBuilder(
    column: $table.isEnableBacklog,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskIds =>
      $composableBuilder(column: $table.taskIds, builder: (column) => column);

  GeneratedColumn<String> get backlogTaskIds => $composableBuilder(
    column: $table.backlogTaskIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<String> get advancedCfg => $composableBuilder(
    column: $table.advancedCfg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<int> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<String> get crdtClock =>
      $composableBuilder(column: $table.crdtClock, builder: (column) => column);

  GeneratedColumn<String> get crdtState =>
      $composableBuilder(column: $table.crdtState, builder: (column) => column);
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
          Project,
          PrefetchHooks Function()
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isHiddenFromMenu = const Value.absent(),
                Value<bool> isEnableBacklog = const Value.absent(),
                Value<String> taskIds = const Value.absent(),
                Value<String> backlogTaskIds = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> advancedCfg = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> created = const Value.absent(),
                Value<int?> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                title: title,
                isArchived: isArchived,
                isHiddenFromMenu: isHiddenFromMenu,
                isEnableBacklog: isEnableBacklog,
                taskIds: taskIds,
                backlogTaskIds: backlogTaskIds,
                theme: theme,
                advancedCfg: advancedCfg,
                icon: icon,
                created: created,
                modified: modified,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isHiddenFromMenu = const Value.absent(),
                Value<bool> isEnableBacklog = const Value.absent(),
                Value<String> taskIds = const Value.absent(),
                Value<String> backlogTaskIds = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> advancedCfg = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                required int created,
                Value<int?> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                title: title,
                isArchived: isArchived,
                isHiddenFromMenu: isHiddenFromMenu,
                isEnableBacklog: isEnableBacklog,
                taskIds: taskIds,
                backlogTaskIds: backlogTaskIds,
                theme: theme,
                advancedCfg: advancedCfg,
                icon: icon,
                created: created,
                modified: modified,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
      Project,
      PrefetchHooks Function()
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String title,
      Value<String?> icon,
      Value<String> taskIds,
      Value<String> theme,
      Value<String> advancedCfg,
      required int created,
      Value<int?> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> icon,
      Value<String> taskIds,
      Value<String> theme,
      Value<String> advancedCfg,
      Value<int> created,
      Value<int?> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskIds => $composableBuilder(
    column: $table.taskIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get advancedCfg => $composableBuilder(
    column: $table.advancedCfg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskIds => $composableBuilder(
    column: $table.taskIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get advancedCfg => $composableBuilder(
    column: $table.advancedCfg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
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

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get taskIds =>
      $composableBuilder(column: $table.taskIds, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<String> get advancedCfg => $composableBuilder(
    column: $table.advancedCfg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<int> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<String> get crdtClock =>
      $composableBuilder(column: $table.crdtClock, builder: (column) => column);

  GeneratedColumn<String> get crdtState =>
      $composableBuilder(column: $table.crdtState, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String> taskIds = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> advancedCfg = const Value.absent(),
                Value<int> created = const Value.absent(),
                Value<int?> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                title: title,
                icon: icon,
                taskIds: taskIds,
                theme: theme,
                advancedCfg: advancedCfg,
                created: created,
                modified: modified,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> icon = const Value.absent(),
                Value<String> taskIds = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> advancedCfg = const Value.absent(),
                required int created,
                Value<int?> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                title: title,
                icon: icon,
                taskIds: taskIds,
                theme: theme,
                advancedCfg: advancedCfg,
                created: created,
                modified: modified,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$WorklogEntriesTableCreateCompanionBuilder =
    WorklogEntriesCompanion Function({
      required String id,
      required String taskId,
      required int start,
      required int end,
      required int duration,
      required String date,
      Value<String?> comment,
      Value<String?> jiraWorklogId,
      required int created,
      required int updated,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });
typedef $$WorklogEntriesTableUpdateCompanionBuilder =
    WorklogEntriesCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<int> start,
      Value<int> end,
      Value<int> duration,
      Value<String> date,
      Value<String?> comment,
      Value<String?> jiraWorklogId,
      Value<int> created,
      Value<int> updated,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });

class $$WorklogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WorklogEntriesTable> {
  $$WorklogEntriesTableFilterComposer({
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

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jiraWorklogId => $composableBuilder(
    column: $table.jiraWorklogId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorklogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorklogEntriesTable> {
  $$WorklogEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jiraWorklogId => $composableBuilder(
    column: $table.jiraWorklogId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorklogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorklogEntriesTable> {
  $$WorklogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<int> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<int> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<String> get jiraWorklogId => $composableBuilder(
    column: $table.jiraWorklogId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<int> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);

  GeneratedColumn<String> get crdtClock =>
      $composableBuilder(column: $table.crdtClock, builder: (column) => column);

  GeneratedColumn<String> get crdtState =>
      $composableBuilder(column: $table.crdtState, builder: (column) => column);
}

class $$WorklogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorklogEntriesTable,
          WorklogEntry,
          $$WorklogEntriesTableFilterComposer,
          $$WorklogEntriesTableOrderingComposer,
          $$WorklogEntriesTableAnnotationComposer,
          $$WorklogEntriesTableCreateCompanionBuilder,
          $$WorklogEntriesTableUpdateCompanionBuilder,
          (
            WorklogEntry,
            BaseReferences<_$AppDatabase, $WorklogEntriesTable, WorklogEntry>,
          ),
          WorklogEntry,
          PrefetchHooks Function()
        > {
  $$WorklogEntriesTableTableManager(
    _$AppDatabase db,
    $WorklogEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorklogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorklogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorklogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<int> start = const Value.absent(),
                Value<int> end = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<String?> jiraWorklogId = const Value.absent(),
                Value<int> created = const Value.absent(),
                Value<int> updated = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorklogEntriesCompanion(
                id: id,
                taskId: taskId,
                start: start,
                end: end,
                duration: duration,
                date: date,
                comment: comment,
                jiraWorklogId: jiraWorklogId,
                created: created,
                updated: updated,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required int start,
                required int end,
                required int duration,
                required String date,
                Value<String?> comment = const Value.absent(),
                Value<String?> jiraWorklogId = const Value.absent(),
                required int created,
                required int updated,
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorklogEntriesCompanion.insert(
                id: id,
                taskId: taskId,
                start: start,
                end: end,
                duration: duration,
                date: date,
                comment: comment,
                jiraWorklogId: jiraWorklogId,
                created: created,
                updated: updated,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorklogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorklogEntriesTable,
      WorklogEntry,
      $$WorklogEntriesTableFilterComposer,
      $$WorklogEntriesTableOrderingComposer,
      $$WorklogEntriesTableAnnotationComposer,
      $$WorklogEntriesTableCreateCompanionBuilder,
      $$WorklogEntriesTableUpdateCompanionBuilder,
      (
        WorklogEntry,
        BaseReferences<_$AppDatabase, $WorklogEntriesTable, WorklogEntry>,
      ),
      WorklogEntry,
      PrefetchHooks Function()
    >;
typedef $$JiraIntegrationsTableCreateCompanionBuilder =
    JiraIntegrationsCompanion Function({
      required String id,
      Value<String?> projectId,
      required String baseUrl,
      required String jiraProjectKey,
      Value<String?> boardId,
      required String credentialsFilePath,
      Value<String?> jqlFilter,
      Value<bool> syncEnabled,
      Value<bool> syncSubtasks,
      Value<bool> syncWorklogs,
      Value<int> syncIntervalMinutes,
      Value<String> fieldMappings,
      Value<String> statusMappings,
      Value<int?> lastSyncAt,
      Value<String?> lastSyncError,
      required int created,
      Value<int?> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });
typedef $$JiraIntegrationsTableUpdateCompanionBuilder =
    JiraIntegrationsCompanion Function({
      Value<String> id,
      Value<String?> projectId,
      Value<String> baseUrl,
      Value<String> jiraProjectKey,
      Value<String?> boardId,
      Value<String> credentialsFilePath,
      Value<String?> jqlFilter,
      Value<bool> syncEnabled,
      Value<bool> syncSubtasks,
      Value<bool> syncWorklogs,
      Value<int> syncIntervalMinutes,
      Value<String> fieldMappings,
      Value<String> statusMappings,
      Value<int?> lastSyncAt,
      Value<String?> lastSyncError,
      Value<int> created,
      Value<int?> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });

class $$JiraIntegrationsTableFilterComposer
    extends Composer<_$AppDatabase, $JiraIntegrationsTable> {
  $$JiraIntegrationsTableFilterComposer({
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

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jiraProjectKey => $composableBuilder(
    column: $table.jiraProjectKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boardId => $composableBuilder(
    column: $table.boardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialsFilePath => $composableBuilder(
    column: $table.credentialsFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jqlFilter => $composableBuilder(
    column: $table.jqlFilter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncSubtasks => $composableBuilder(
    column: $table.syncSubtasks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncWorklogs => $composableBuilder(
    column: $table.syncWorklogs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncIntervalMinutes => $composableBuilder(
    column: $table.syncIntervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldMappings => $composableBuilder(
    column: $table.fieldMappings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusMappings => $composableBuilder(
    column: $table.statusMappings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JiraIntegrationsTableOrderingComposer
    extends Composer<_$AppDatabase, $JiraIntegrationsTable> {
  $$JiraIntegrationsTableOrderingComposer({
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

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jiraProjectKey => $composableBuilder(
    column: $table.jiraProjectKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boardId => $composableBuilder(
    column: $table.boardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialsFilePath => $composableBuilder(
    column: $table.credentialsFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jqlFilter => $composableBuilder(
    column: $table.jqlFilter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncSubtasks => $composableBuilder(
    column: $table.syncSubtasks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncWorklogs => $composableBuilder(
    column: $table.syncWorklogs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncIntervalMinutes => $composableBuilder(
    column: $table.syncIntervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldMappings => $composableBuilder(
    column: $table.fieldMappings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusMappings => $composableBuilder(
    column: $table.statusMappings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JiraIntegrationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JiraIntegrationsTable> {
  $$JiraIntegrationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get jiraProjectKey => $composableBuilder(
    column: $table.jiraProjectKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boardId =>
      $composableBuilder(column: $table.boardId, builder: (column) => column);

  GeneratedColumn<String> get credentialsFilePath => $composableBuilder(
    column: $table.credentialsFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jqlFilter =>
      $composableBuilder(column: $table.jqlFilter, builder: (column) => column);

  GeneratedColumn<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncSubtasks => $composableBuilder(
    column: $table.syncSubtasks,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncWorklogs => $composableBuilder(
    column: $table.syncWorklogs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncIntervalMinutes => $composableBuilder(
    column: $table.syncIntervalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldMappings => $composableBuilder(
    column: $table.fieldMappings,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statusMappings => $composableBuilder(
    column: $table.statusMappings,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );

  GeneratedColumn<int> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<int> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<String> get crdtClock =>
      $composableBuilder(column: $table.crdtClock, builder: (column) => column);

  GeneratedColumn<String> get crdtState =>
      $composableBuilder(column: $table.crdtState, builder: (column) => column);
}

class $$JiraIntegrationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JiraIntegrationsTable,
          JiraIntegration,
          $$JiraIntegrationsTableFilterComposer,
          $$JiraIntegrationsTableOrderingComposer,
          $$JiraIntegrationsTableAnnotationComposer,
          $$JiraIntegrationsTableCreateCompanionBuilder,
          $$JiraIntegrationsTableUpdateCompanionBuilder,
          (
            JiraIntegration,
            BaseReferences<
              _$AppDatabase,
              $JiraIntegrationsTable,
              JiraIntegration
            >,
          ),
          JiraIntegration,
          PrefetchHooks Function()
        > {
  $$JiraIntegrationsTableTableManager(
    _$AppDatabase db,
    $JiraIntegrationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JiraIntegrationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JiraIntegrationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JiraIntegrationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String> jiraProjectKey = const Value.absent(),
                Value<String?> boardId = const Value.absent(),
                Value<String> credentialsFilePath = const Value.absent(),
                Value<String?> jqlFilter = const Value.absent(),
                Value<bool> syncEnabled = const Value.absent(),
                Value<bool> syncSubtasks = const Value.absent(),
                Value<bool> syncWorklogs = const Value.absent(),
                Value<int> syncIntervalMinutes = const Value.absent(),
                Value<String> fieldMappings = const Value.absent(),
                Value<String> statusMappings = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> created = const Value.absent(),
                Value<int?> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JiraIntegrationsCompanion(
                id: id,
                projectId: projectId,
                baseUrl: baseUrl,
                jiraProjectKey: jiraProjectKey,
                boardId: boardId,
                credentialsFilePath: credentialsFilePath,
                jqlFilter: jqlFilter,
                syncEnabled: syncEnabled,
                syncSubtasks: syncSubtasks,
                syncWorklogs: syncWorklogs,
                syncIntervalMinutes: syncIntervalMinutes,
                fieldMappings: fieldMappings,
                statusMappings: statusMappings,
                lastSyncAt: lastSyncAt,
                lastSyncError: lastSyncError,
                created: created,
                modified: modified,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> projectId = const Value.absent(),
                required String baseUrl,
                required String jiraProjectKey,
                Value<String?> boardId = const Value.absent(),
                required String credentialsFilePath,
                Value<String?> jqlFilter = const Value.absent(),
                Value<bool> syncEnabled = const Value.absent(),
                Value<bool> syncSubtasks = const Value.absent(),
                Value<bool> syncWorklogs = const Value.absent(),
                Value<int> syncIntervalMinutes = const Value.absent(),
                Value<String> fieldMappings = const Value.absent(),
                Value<String> statusMappings = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                required int created,
                Value<int?> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JiraIntegrationsCompanion.insert(
                id: id,
                projectId: projectId,
                baseUrl: baseUrl,
                jiraProjectKey: jiraProjectKey,
                boardId: boardId,
                credentialsFilePath: credentialsFilePath,
                jqlFilter: jqlFilter,
                syncEnabled: syncEnabled,
                syncSubtasks: syncSubtasks,
                syncWorklogs: syncWorklogs,
                syncIntervalMinutes: syncIntervalMinutes,
                fieldMappings: fieldMappings,
                statusMappings: statusMappings,
                lastSyncAt: lastSyncAt,
                lastSyncError: lastSyncError,
                created: created,
                modified: modified,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JiraIntegrationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JiraIntegrationsTable,
      JiraIntegration,
      $$JiraIntegrationsTableFilterComposer,
      $$JiraIntegrationsTableOrderingComposer,
      $$JiraIntegrationsTableAnnotationComposer,
      $$JiraIntegrationsTableCreateCompanionBuilder,
      $$JiraIntegrationsTableUpdateCompanionBuilder,
      (
        JiraIntegration,
        BaseReferences<_$AppDatabase, $JiraIntegrationsTable, JiraIntegration>,
      ),
      JiraIntegration,
      PrefetchHooks Function()
    >;
typedef $$TimerEntriesTableCreateCompanionBuilder =
    TimerEntriesCompanion Function({
      required String id,
      Value<String?> taskId,
      Value<String> taskTitle,
      Value<String?> projectId,
      Value<String?> projectTitle,
      Value<int> startedAt,
      Value<bool> isRunning,
      Value<int?> pausedAt,
      Value<int> accumulatedMs,
      Value<String?> note,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });
typedef $$TimerEntriesTableUpdateCompanionBuilder =
    TimerEntriesCompanion Function({
      Value<String> id,
      Value<String?> taskId,
      Value<String> taskTitle,
      Value<String?> projectId,
      Value<String?> projectTitle,
      Value<int> startedAt,
      Value<bool> isRunning,
      Value<int?> pausedAt,
      Value<int> accumulatedMs,
      Value<String?> note,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });

class $$TimerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TimerEntriesTable> {
  $$TimerEntriesTableFilterComposer({
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

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskTitle => $composableBuilder(
    column: $table.taskTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectTitle => $composableBuilder(
    column: $table.projectTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRunning => $composableBuilder(
    column: $table.isRunning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accumulatedMs => $composableBuilder(
    column: $table.accumulatedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TimerEntriesTable> {
  $$TimerEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskTitle => $composableBuilder(
    column: $table.taskTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectTitle => $composableBuilder(
    column: $table.projectTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRunning => $composableBuilder(
    column: $table.isRunning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accumulatedMs => $composableBuilder(
    column: $table.accumulatedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtClock => $composableBuilder(
    column: $table.crdtClock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get crdtState => $composableBuilder(
    column: $table.crdtState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimerEntriesTable> {
  $$TimerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get taskTitle =>
      $composableBuilder(column: $table.taskTitle, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get projectTitle => $composableBuilder(
    column: $table.projectTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<bool> get isRunning =>
      $composableBuilder(column: $table.isRunning, builder: (column) => column);

  GeneratedColumn<int> get pausedAt =>
      $composableBuilder(column: $table.pausedAt, builder: (column) => column);

  GeneratedColumn<int> get accumulatedMs => $composableBuilder(
    column: $table.accumulatedMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get crdtClock =>
      $composableBuilder(column: $table.crdtClock, builder: (column) => column);

  GeneratedColumn<String> get crdtState =>
      $composableBuilder(column: $table.crdtState, builder: (column) => column);
}

class $$TimerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimerEntriesTable,
          TimerEntry,
          $$TimerEntriesTableFilterComposer,
          $$TimerEntriesTableOrderingComposer,
          $$TimerEntriesTableAnnotationComposer,
          $$TimerEntriesTableCreateCompanionBuilder,
          $$TimerEntriesTableUpdateCompanionBuilder,
          (
            TimerEntry,
            BaseReferences<_$AppDatabase, $TimerEntriesTable, TimerEntry>,
          ),
          TimerEntry,
          PrefetchHooks Function()
        > {
  $$TimerEntriesTableTableManager(_$AppDatabase db, $TimerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String> taskTitle = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> projectTitle = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<bool> isRunning = const Value.absent(),
                Value<int?> pausedAt = const Value.absent(),
                Value<int> accumulatedMs = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimerEntriesCompanion(
                id: id,
                taskId: taskId,
                taskTitle: taskTitle,
                projectId: projectId,
                projectTitle: projectTitle,
                startedAt: startedAt,
                isRunning: isRunning,
                pausedAt: pausedAt,
                accumulatedMs: accumulatedMs,
                note: note,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> taskId = const Value.absent(),
                Value<String> taskTitle = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> projectTitle = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<bool> isRunning = const Value.absent(),
                Value<int?> pausedAt = const Value.absent(),
                Value<int> accumulatedMs = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimerEntriesCompanion.insert(
                id: id,
                taskId: taskId,
                taskTitle: taskTitle,
                projectId: projectId,
                projectTitle: projectTitle,
                startedAt: startedAt,
                isRunning: isRunning,
                pausedAt: pausedAt,
                accumulatedMs: accumulatedMs,
                note: note,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimerEntriesTable,
      TimerEntry,
      $$TimerEntriesTableFilterComposer,
      $$TimerEntriesTableOrderingComposer,
      $$TimerEntriesTableAnnotationComposer,
      $$TimerEntriesTableCreateCompanionBuilder,
      $$TimerEntriesTableUpdateCompanionBuilder,
      (
        TimerEntry,
        BaseReferences<_$AppDatabase, $TimerEntriesTable, TimerEntry>,
      ),
      TimerEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$SubtasksTableTableManager get subtasks =>
      $$SubtasksTableTableManager(_db, _db.subtasks);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$WorklogEntriesTableTableManager get worklogEntries =>
      $$WorklogEntriesTableTableManager(_db, _db.worklogEntries);
  $$JiraIntegrationsTableTableManager get jiraIntegrations =>
      $$JiraIntegrationsTableTableManager(_db, _db.jiraIntegrations);
  $$TimerEntriesTableTableManager get timerEntries =>
      $$TimerEntriesTableTableManager(_db, _db.timerEntries);
}
