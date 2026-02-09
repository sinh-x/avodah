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
  static const VerificationMeta _noteIdsMeta = const VerificationMeta(
    'noteIds',
  );
  @override
  late final GeneratedColumn<String> noteIds = GeneratedColumn<String>(
    'note_ids',
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
  static const VerificationMeta _issueIntegrationCfgsMeta =
      const VerificationMeta('issueIntegrationCfgs');
  @override
  late final GeneratedColumn<String> issueIntegrationCfgs =
      GeneratedColumn<String>(
        'issue_integration_cfgs',
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
    isArchived,
    isHiddenFromMenu,
    isEnableBacklog,
    taskIds,
    backlogTaskIds,
    noteIds,
    theme,
    advancedCfg,
    icon,
    issueIntegrationCfgs,
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
    if (data.containsKey('note_ids')) {
      context.handle(
        _noteIdsMeta,
        noteIds.isAcceptableOrUnknown(data['note_ids']!, _noteIdsMeta),
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
    if (data.containsKey('issue_integration_cfgs')) {
      context.handle(
        _issueIntegrationCfgsMeta,
        issueIntegrationCfgs.isAcceptableOrUnknown(
          data['issue_integration_cfgs']!,
          _issueIntegrationCfgsMeta,
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
      noteIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_ids'],
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
      issueIntegrationCfgs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_integration_cfgs'],
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
  final String noteIds;
  final String theme;
  final String advancedCfg;
  final String? icon;
  final String issueIntegrationCfgs;
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
    required this.noteIds,
    required this.theme,
    required this.advancedCfg,
    this.icon,
    required this.issueIntegrationCfgs,
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
    map['note_ids'] = Variable<String>(noteIds);
    map['theme'] = Variable<String>(theme);
    map['advanced_cfg'] = Variable<String>(advancedCfg);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['issue_integration_cfgs'] = Variable<String>(issueIntegrationCfgs);
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
      noteIds: Value(noteIds),
      theme: Value(theme),
      advancedCfg: Value(advancedCfg),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      issueIntegrationCfgs: Value(issueIntegrationCfgs),
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
      noteIds: serializer.fromJson<String>(json['noteIds']),
      theme: serializer.fromJson<String>(json['theme']),
      advancedCfg: serializer.fromJson<String>(json['advancedCfg']),
      icon: serializer.fromJson<String?>(json['icon']),
      issueIntegrationCfgs: serializer.fromJson<String>(
        json['issueIntegrationCfgs'],
      ),
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
      'noteIds': serializer.toJson<String>(noteIds),
      'theme': serializer.toJson<String>(theme),
      'advancedCfg': serializer.toJson<String>(advancedCfg),
      'icon': serializer.toJson<String?>(icon),
      'issueIntegrationCfgs': serializer.toJson<String>(issueIntegrationCfgs),
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
    String? noteIds,
    String? theme,
    String? advancedCfg,
    Value<String?> icon = const Value.absent(),
    String? issueIntegrationCfgs,
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
    noteIds: noteIds ?? this.noteIds,
    theme: theme ?? this.theme,
    advancedCfg: advancedCfg ?? this.advancedCfg,
    icon: icon.present ? icon.value : this.icon,
    issueIntegrationCfgs: issueIntegrationCfgs ?? this.issueIntegrationCfgs,
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
      noteIds: data.noteIds.present ? data.noteIds.value : this.noteIds,
      theme: data.theme.present ? data.theme.value : this.theme,
      advancedCfg: data.advancedCfg.present
          ? data.advancedCfg.value
          : this.advancedCfg,
      icon: data.icon.present ? data.icon.value : this.icon,
      issueIntegrationCfgs: data.issueIntegrationCfgs.present
          ? data.issueIntegrationCfgs.value
          : this.issueIntegrationCfgs,
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
          ..write('noteIds: $noteIds, ')
          ..write('theme: $theme, ')
          ..write('advancedCfg: $advancedCfg, ')
          ..write('icon: $icon, ')
          ..write('issueIntegrationCfgs: $issueIntegrationCfgs, ')
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
    noteIds,
    theme,
    advancedCfg,
    icon,
    issueIntegrationCfgs,
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
          other.noteIds == this.noteIds &&
          other.theme == this.theme &&
          other.advancedCfg == this.advancedCfg &&
          other.icon == this.icon &&
          other.issueIntegrationCfgs == this.issueIntegrationCfgs &&
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
  final Value<String> noteIds;
  final Value<String> theme;
  final Value<String> advancedCfg;
  final Value<String?> icon;
  final Value<String> issueIntegrationCfgs;
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
    this.noteIds = const Value.absent(),
    this.theme = const Value.absent(),
    this.advancedCfg = const Value.absent(),
    this.icon = const Value.absent(),
    this.issueIntegrationCfgs = const Value.absent(),
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
    this.noteIds = const Value.absent(),
    this.theme = const Value.absent(),
    this.advancedCfg = const Value.absent(),
    this.icon = const Value.absent(),
    this.issueIntegrationCfgs = const Value.absent(),
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
    Expression<String>? noteIds,
    Expression<String>? theme,
    Expression<String>? advancedCfg,
    Expression<String>? icon,
    Expression<String>? issueIntegrationCfgs,
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
      if (noteIds != null) 'note_ids': noteIds,
      if (theme != null) 'theme': theme,
      if (advancedCfg != null) 'advanced_cfg': advancedCfg,
      if (icon != null) 'icon': icon,
      if (issueIntegrationCfgs != null)
        'issue_integration_cfgs': issueIntegrationCfgs,
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
    Value<String>? noteIds,
    Value<String>? theme,
    Value<String>? advancedCfg,
    Value<String?>? icon,
    Value<String>? issueIntegrationCfgs,
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
      noteIds: noteIds ?? this.noteIds,
      theme: theme ?? this.theme,
      advancedCfg: advancedCfg ?? this.advancedCfg,
      icon: icon ?? this.icon,
      issueIntegrationCfgs: issueIntegrationCfgs ?? this.issueIntegrationCfgs,
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
    if (noteIds.present) {
      map['note_ids'] = Variable<String>(noteIds.value);
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
    if (issueIntegrationCfgs.present) {
      map['issue_integration_cfgs'] = Variable<String>(
        issueIntegrationCfgs.value,
      );
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
          ..write('noteIds: $noteIds, ')
          ..write('theme: $theme, ')
          ..write('advancedCfg: $advancedCfg, ')
          ..write('icon: $icon, ')
          ..write('issueIntegrationCfgs: $issueIntegrationCfgs, ')
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

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _imgUrlMeta = const VerificationMeta('imgUrl');
  @override
  late final GeneratedColumn<String> imgUrl = GeneratedColumn<String>(
    'img_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backgroundColorMeta = const VerificationMeta(
    'backgroundColor',
  );
  @override
  late final GeneratedColumn<String> backgroundColor = GeneratedColumn<String>(
    'background_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPinnedToTodayMeta = const VerificationMeta(
    'isPinnedToToday',
  );
  @override
  late final GeneratedColumn<bool> isPinnedToToday = GeneratedColumn<bool>(
    'is_pinned_to_today',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned_to_today" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isLockMeta = const VerificationMeta('isLock');
  @override
  late final GeneratedColumn<bool> isLock = GeneratedColumn<bool>(
    'is_lock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_lock" IN (0, 1))',
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
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<int> modified = GeneratedColumn<int>(
    'modified',
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
    projectId,
    content,
    imgUrl,
    backgroundColor,
    isPinnedToToday,
    isLock,
    created,
    modified,
    crdtClock,
    crdtState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
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
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('img_url')) {
      context.handle(
        _imgUrlMeta,
        imgUrl.isAcceptableOrUnknown(data['img_url']!, _imgUrlMeta),
      );
    }
    if (data.containsKey('background_color')) {
      context.handle(
        _backgroundColorMeta,
        backgroundColor.isAcceptableOrUnknown(
          data['background_color']!,
          _backgroundColorMeta,
        ),
      );
    }
    if (data.containsKey('is_pinned_to_today')) {
      context.handle(
        _isPinnedToTodayMeta,
        isPinnedToToday.isAcceptableOrUnknown(
          data['is_pinned_to_today']!,
          _isPinnedToTodayMeta,
        ),
      );
    }
    if (data.containsKey('is_lock')) {
      context.handle(
        _isLockMeta,
        isLock.isAcceptableOrUnknown(data['is_lock']!, _isLockMeta),
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
    } else if (isInserting) {
      context.missing(_modifiedMeta);
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
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      imgUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}img_url'],
      ),
      backgroundColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_color'],
      ),
      isPinnedToToday: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned_to_today'],
      )!,
      isLock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_lock'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created'],
      )!,
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified'],
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
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final String? projectId;
  final String content;
  final String? imgUrl;
  final String? backgroundColor;
  final bool isPinnedToToday;
  final bool isLock;
  final int created;
  final int modified;
  final String crdtClock;
  final String crdtState;
  const Note({
    required this.id,
    this.projectId,
    required this.content,
    this.imgUrl,
    this.backgroundColor,
    required this.isPinnedToToday,
    required this.isLock,
    required this.created,
    required this.modified,
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
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || imgUrl != null) {
      map['img_url'] = Variable<String>(imgUrl);
    }
    if (!nullToAbsent || backgroundColor != null) {
      map['background_color'] = Variable<String>(backgroundColor);
    }
    map['is_pinned_to_today'] = Variable<bool>(isPinnedToToday);
    map['is_lock'] = Variable<bool>(isLock);
    map['created'] = Variable<int>(created);
    map['modified'] = Variable<int>(modified);
    map['crdt_clock'] = Variable<String>(crdtClock);
    map['crdt_state'] = Variable<String>(crdtState);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      content: Value(content),
      imgUrl: imgUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imgUrl),
      backgroundColor: backgroundColor == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundColor),
      isPinnedToToday: Value(isPinnedToToday),
      isLock: Value(isLock),
      created: Value(created),
      modified: Value(modified),
      crdtClock: Value(crdtClock),
      crdtState: Value(crdtState),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      content: serializer.fromJson<String>(json['content']),
      imgUrl: serializer.fromJson<String?>(json['imgUrl']),
      backgroundColor: serializer.fromJson<String?>(json['backgroundColor']),
      isPinnedToToday: serializer.fromJson<bool>(json['isPinnedToToday']),
      isLock: serializer.fromJson<bool>(json['isLock']),
      created: serializer.fromJson<int>(json['created']),
      modified: serializer.fromJson<int>(json['modified']),
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
      'content': serializer.toJson<String>(content),
      'imgUrl': serializer.toJson<String?>(imgUrl),
      'backgroundColor': serializer.toJson<String?>(backgroundColor),
      'isPinnedToToday': serializer.toJson<bool>(isPinnedToToday),
      'isLock': serializer.toJson<bool>(isLock),
      'created': serializer.toJson<int>(created),
      'modified': serializer.toJson<int>(modified),
      'crdtClock': serializer.toJson<String>(crdtClock),
      'crdtState': serializer.toJson<String>(crdtState),
    };
  }

  Note copyWith({
    String? id,
    Value<String?> projectId = const Value.absent(),
    String? content,
    Value<String?> imgUrl = const Value.absent(),
    Value<String?> backgroundColor = const Value.absent(),
    bool? isPinnedToToday,
    bool? isLock,
    int? created,
    int? modified,
    String? crdtClock,
    String? crdtState,
  }) => Note(
    id: id ?? this.id,
    projectId: projectId.present ? projectId.value : this.projectId,
    content: content ?? this.content,
    imgUrl: imgUrl.present ? imgUrl.value : this.imgUrl,
    backgroundColor: backgroundColor.present
        ? backgroundColor.value
        : this.backgroundColor,
    isPinnedToToday: isPinnedToToday ?? this.isPinnedToToday,
    isLock: isLock ?? this.isLock,
    created: created ?? this.created,
    modified: modified ?? this.modified,
    crdtClock: crdtClock ?? this.crdtClock,
    crdtState: crdtState ?? this.crdtState,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      content: data.content.present ? data.content.value : this.content,
      imgUrl: data.imgUrl.present ? data.imgUrl.value : this.imgUrl,
      backgroundColor: data.backgroundColor.present
          ? data.backgroundColor.value
          : this.backgroundColor,
      isPinnedToToday: data.isPinnedToToday.present
          ? data.isPinnedToToday.value
          : this.isPinnedToToday,
      isLock: data.isLock.present ? data.isLock.value : this.isLock,
      created: data.created.present ? data.created.value : this.created,
      modified: data.modified.present ? data.modified.value : this.modified,
      crdtClock: data.crdtClock.present ? data.crdtClock.value : this.crdtClock,
      crdtState: data.crdtState.present ? data.crdtState.value : this.crdtState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('content: $content, ')
          ..write('imgUrl: $imgUrl, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('isPinnedToToday: $isPinnedToToday, ')
          ..write('isLock: $isLock, ')
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
    content,
    imgUrl,
    backgroundColor,
    isPinnedToToday,
    isLock,
    created,
    modified,
    crdtClock,
    crdtState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.content == this.content &&
          other.imgUrl == this.imgUrl &&
          other.backgroundColor == this.backgroundColor &&
          other.isPinnedToToday == this.isPinnedToToday &&
          other.isLock == this.isLock &&
          other.created == this.created &&
          other.modified == this.modified &&
          other.crdtClock == this.crdtClock &&
          other.crdtState == this.crdtState);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<String?> projectId;
  final Value<String> content;
  final Value<String?> imgUrl;
  final Value<String?> backgroundColor;
  final Value<bool> isPinnedToToday;
  final Value<bool> isLock;
  final Value<int> created;
  final Value<int> modified;
  final Value<String> crdtClock;
  final Value<String> crdtState;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.content = const Value.absent(),
    this.imgUrl = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.isPinnedToToday = const Value.absent(),
    this.isLock = const Value.absent(),
    this.created = const Value.absent(),
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    this.projectId = const Value.absent(),
    required String content,
    this.imgUrl = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.isPinnedToToday = const Value.absent(),
    this.isLock = const Value.absent(),
    required int created,
    required int modified,
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       content = Value(content),
       created = Value(created),
       modified = Value(modified);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? content,
    Expression<String>? imgUrl,
    Expression<String>? backgroundColor,
    Expression<bool>? isPinnedToToday,
    Expression<bool>? isLock,
    Expression<int>? created,
    Expression<int>? modified,
    Expression<String>? crdtClock,
    Expression<String>? crdtState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (content != null) 'content': content,
      if (imgUrl != null) 'img_url': imgUrl,
      if (backgroundColor != null) 'background_color': backgroundColor,
      if (isPinnedToToday != null) 'is_pinned_to_today': isPinnedToToday,
      if (isLock != null) 'is_lock': isLock,
      if (created != null) 'created': created,
      if (modified != null) 'modified': modified,
      if (crdtClock != null) 'crdt_clock': crdtClock,
      if (crdtState != null) 'crdt_state': crdtState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String?>? projectId,
    Value<String>? content,
    Value<String?>? imgUrl,
    Value<String?>? backgroundColor,
    Value<bool>? isPinnedToToday,
    Value<bool>? isLock,
    Value<int>? created,
    Value<int>? modified,
    Value<String>? crdtClock,
    Value<String>? crdtState,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      content: content ?? this.content,
      imgUrl: imgUrl ?? this.imgUrl,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isPinnedToToday: isPinnedToToday ?? this.isPinnedToToday,
      isLock: isLock ?? this.isLock,
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
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (imgUrl.present) {
      map['img_url'] = Variable<String>(imgUrl.value);
    }
    if (backgroundColor.present) {
      map['background_color'] = Variable<String>(backgroundColor.value);
    }
    if (isPinnedToToday.present) {
      map['is_pinned_to_today'] = Variable<bool>(isPinnedToToday.value);
    }
    if (isLock.present) {
      map['is_lock'] = Variable<bool>(isLock.value);
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
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('content: $content, ')
          ..write('imgUrl: $imgUrl, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('isPinnedToToday: $isPinnedToToday, ')
          ..write('isLock: $isLock, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskRepeatCfgsTable extends TaskRepeatCfgs
    with TableInfo<$TaskRepeatCfgsTable, TaskRepeatCfg> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRepeatCfgsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _defaultEstimateMeta = const VerificationMeta(
    'defaultEstimate',
  );
  @override
  late final GeneratedColumn<int> defaultEstimate = GeneratedColumn<int>(
    'default_estimate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remindAtMeta = const VerificationMeta(
    'remindAt',
  );
  @override
  late final GeneratedColumn<String> remindAt = GeneratedColumn<String>(
    'remind_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPausedMeta = const VerificationMeta(
    'isPaused',
  );
  @override
  late final GeneratedColumn<bool> isPaused = GeneratedColumn<bool>(
    'is_paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _quickSettingMeta = const VerificationMeta(
    'quickSetting',
  );
  @override
  late final GeneratedColumn<String> quickSetting = GeneratedColumn<String>(
    'quick_setting',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repeatCycleMeta = const VerificationMeta(
    'repeatCycle',
  );
  @override
  late final GeneratedColumn<String> repeatCycle = GeneratedColumn<String>(
    'repeat_cycle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatEveryMeta = const VerificationMeta(
    'repeatEvery',
  );
  @override
  late final GeneratedColumn<int> repeatEvery = GeneratedColumn<int>(
    'repeat_every',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _mondayMeta = const VerificationMeta('monday');
  @override
  late final GeneratedColumn<bool> monday = GeneratedColumn<bool>(
    'monday',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("monday" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tuesdayMeta = const VerificationMeta(
    'tuesday',
  );
  @override
  late final GeneratedColumn<bool> tuesday = GeneratedColumn<bool>(
    'tuesday',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tuesday" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _wednesdayMeta = const VerificationMeta(
    'wednesday',
  );
  @override
  late final GeneratedColumn<bool> wednesday = GeneratedColumn<bool>(
    'wednesday',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("wednesday" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _thursdayMeta = const VerificationMeta(
    'thursday',
  );
  @override
  late final GeneratedColumn<bool> thursday = GeneratedColumn<bool>(
    'thursday',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("thursday" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fridayMeta = const VerificationMeta('friday');
  @override
  late final GeneratedColumn<bool> friday = GeneratedColumn<bool>(
    'friday',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("friday" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _saturdayMeta = const VerificationMeta(
    'saturday',
  );
  @override
  late final GeneratedColumn<bool> saturday = GeneratedColumn<bool>(
    'saturday',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("saturday" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sundayMeta = const VerificationMeta('sunday');
  @override
  late final GeneratedColumn<bool> sunday = GeneratedColumn<bool>(
    'sunday',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sunday" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _subTaskTemplatesMeta = const VerificationMeta(
    'subTaskTemplates',
  );
  @override
  late final GeneratedColumn<String> subTaskTemplates = GeneratedColumn<String>(
    'sub_task_templates',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _lastTaskCreationMeta = const VerificationMeta(
    'lastTaskCreation',
  );
  @override
  late final GeneratedColumn<int> lastTaskCreation = GeneratedColumn<int>(
    'last_task_creation',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastTaskCreationDayMeta =
      const VerificationMeta('lastTaskCreationDay');
  @override
  late final GeneratedColumn<String> lastTaskCreationDay =
      GeneratedColumn<String>(
        'last_task_creation_day',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deletedInstanceDatesMeta =
      const VerificationMeta('deletedInstanceDates');
  @override
  late final GeneratedColumn<String> deletedInstanceDates =
      GeneratedColumn<String>(
        'deleted_instance_dates',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
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
    tagIds,
    order,
    defaultEstimate,
    startTime,
    remindAt,
    isPaused,
    quickSetting,
    repeatCycle,
    startDate,
    repeatEvery,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
    notes,
    subTaskTemplates,
    lastTaskCreation,
    lastTaskCreationDay,
    deletedInstanceDates,
    crdtClock,
    crdtState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_repeat_cfgs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRepeatCfg> instance, {
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
    }
    if (data.containsKey('tag_ids')) {
      context.handle(
        _tagIdsMeta,
        tagIds.isAcceptableOrUnknown(data['tag_ids']!, _tagIdsMeta),
      );
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('default_estimate')) {
      context.handle(
        _defaultEstimateMeta,
        defaultEstimate.isAcceptableOrUnknown(
          data['default_estimate']!,
          _defaultEstimateMeta,
        ),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('remind_at')) {
      context.handle(
        _remindAtMeta,
        remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta),
      );
    }
    if (data.containsKey('is_paused')) {
      context.handle(
        _isPausedMeta,
        isPaused.isAcceptableOrUnknown(data['is_paused']!, _isPausedMeta),
      );
    }
    if (data.containsKey('quick_setting')) {
      context.handle(
        _quickSettingMeta,
        quickSetting.isAcceptableOrUnknown(
          data['quick_setting']!,
          _quickSettingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quickSettingMeta);
    }
    if (data.containsKey('repeat_cycle')) {
      context.handle(
        _repeatCycleMeta,
        repeatCycle.isAcceptableOrUnknown(
          data['repeat_cycle']!,
          _repeatCycleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repeatCycleMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('repeat_every')) {
      context.handle(
        _repeatEveryMeta,
        repeatEvery.isAcceptableOrUnknown(
          data['repeat_every']!,
          _repeatEveryMeta,
        ),
      );
    }
    if (data.containsKey('monday')) {
      context.handle(
        _mondayMeta,
        monday.isAcceptableOrUnknown(data['monday']!, _mondayMeta),
      );
    }
    if (data.containsKey('tuesday')) {
      context.handle(
        _tuesdayMeta,
        tuesday.isAcceptableOrUnknown(data['tuesday']!, _tuesdayMeta),
      );
    }
    if (data.containsKey('wednesday')) {
      context.handle(
        _wednesdayMeta,
        wednesday.isAcceptableOrUnknown(data['wednesday']!, _wednesdayMeta),
      );
    }
    if (data.containsKey('thursday')) {
      context.handle(
        _thursdayMeta,
        thursday.isAcceptableOrUnknown(data['thursday']!, _thursdayMeta),
      );
    }
    if (data.containsKey('friday')) {
      context.handle(
        _fridayMeta,
        friday.isAcceptableOrUnknown(data['friday']!, _fridayMeta),
      );
    }
    if (data.containsKey('saturday')) {
      context.handle(
        _saturdayMeta,
        saturday.isAcceptableOrUnknown(data['saturday']!, _saturdayMeta),
      );
    }
    if (data.containsKey('sunday')) {
      context.handle(
        _sundayMeta,
        sunday.isAcceptableOrUnknown(data['sunday']!, _sundayMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sub_task_templates')) {
      context.handle(
        _subTaskTemplatesMeta,
        subTaskTemplates.isAcceptableOrUnknown(
          data['sub_task_templates']!,
          _subTaskTemplatesMeta,
        ),
      );
    }
    if (data.containsKey('last_task_creation')) {
      context.handle(
        _lastTaskCreationMeta,
        lastTaskCreation.isAcceptableOrUnknown(
          data['last_task_creation']!,
          _lastTaskCreationMeta,
        ),
      );
    }
    if (data.containsKey('last_task_creation_day')) {
      context.handle(
        _lastTaskCreationDayMeta,
        lastTaskCreationDay.isAcceptableOrUnknown(
          data['last_task_creation_day']!,
          _lastTaskCreationDayMeta,
        ),
      );
    }
    if (data.containsKey('deleted_instance_dates')) {
      context.handle(
        _deletedInstanceDatesMeta,
        deletedInstanceDates.isAcceptableOrUnknown(
          data['deleted_instance_dates']!,
          _deletedInstanceDatesMeta,
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
  TaskRepeatCfg map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRepeatCfg(
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
      ),
      tagIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_ids'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      defaultEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_estimate'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      remindAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remind_at'],
      ),
      isPaused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_paused'],
      )!,
      quickSetting: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quick_setting'],
      )!,
      repeatCycle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_cycle'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      repeatEvery: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_every'],
      )!,
      monday: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}monday'],
      )!,
      tuesday: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tuesday'],
      )!,
      wednesday: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}wednesday'],
      )!,
      thursday: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}thursday'],
      )!,
      friday: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}friday'],
      )!,
      saturday: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}saturday'],
      )!,
      sunday: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sunday'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      subTaskTemplates: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_task_templates'],
      )!,
      lastTaskCreation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_task_creation'],
      ),
      lastTaskCreationDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_task_creation_day'],
      ),
      deletedInstanceDates: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_instance_dates'],
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
  $TaskRepeatCfgsTable createAlias(String alias) {
    return $TaskRepeatCfgsTable(attachedDatabase, alias);
  }
}

class TaskRepeatCfg extends DataClass implements Insertable<TaskRepeatCfg> {
  final String id;
  final String? projectId;
  final String? title;
  final String tagIds;
  final int order;
  final int? defaultEstimate;
  final String? startTime;
  final String? remindAt;
  final bool isPaused;
  final String quickSetting;
  final String repeatCycle;
  final String? startDate;
  final int repeatEvery;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;
  final String? notes;
  final String subTaskTemplates;
  final int? lastTaskCreation;
  final String? lastTaskCreationDay;
  final String deletedInstanceDates;
  final String crdtClock;
  final String crdtState;
  const TaskRepeatCfg({
    required this.id,
    this.projectId,
    this.title,
    required this.tagIds,
    required this.order,
    this.defaultEstimate,
    this.startTime,
    this.remindAt,
    required this.isPaused,
    required this.quickSetting,
    required this.repeatCycle,
    this.startDate,
    required this.repeatEvery,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    this.notes,
    required this.subTaskTemplates,
    this.lastTaskCreation,
    this.lastTaskCreationDay,
    required this.deletedInstanceDates,
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
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['tag_ids'] = Variable<String>(tagIds);
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || defaultEstimate != null) {
      map['default_estimate'] = Variable<int>(defaultEstimate);
    }
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || remindAt != null) {
      map['remind_at'] = Variable<String>(remindAt);
    }
    map['is_paused'] = Variable<bool>(isPaused);
    map['quick_setting'] = Variable<String>(quickSetting);
    map['repeat_cycle'] = Variable<String>(repeatCycle);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    map['repeat_every'] = Variable<int>(repeatEvery);
    map['monday'] = Variable<bool>(monday);
    map['tuesday'] = Variable<bool>(tuesday);
    map['wednesday'] = Variable<bool>(wednesday);
    map['thursday'] = Variable<bool>(thursday);
    map['friday'] = Variable<bool>(friday);
    map['saturday'] = Variable<bool>(saturday);
    map['sunday'] = Variable<bool>(sunday);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sub_task_templates'] = Variable<String>(subTaskTemplates);
    if (!nullToAbsent || lastTaskCreation != null) {
      map['last_task_creation'] = Variable<int>(lastTaskCreation);
    }
    if (!nullToAbsent || lastTaskCreationDay != null) {
      map['last_task_creation_day'] = Variable<String>(lastTaskCreationDay);
    }
    map['deleted_instance_dates'] = Variable<String>(deletedInstanceDates);
    map['crdt_clock'] = Variable<String>(crdtClock);
    map['crdt_state'] = Variable<String>(crdtState);
    return map;
  }

  TaskRepeatCfgsCompanion toCompanion(bool nullToAbsent) {
    return TaskRepeatCfgsCompanion(
      id: Value(id),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      tagIds: Value(tagIds),
      order: Value(order),
      defaultEstimate: defaultEstimate == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultEstimate),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      remindAt: remindAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remindAt),
      isPaused: Value(isPaused),
      quickSetting: Value(quickSetting),
      repeatCycle: Value(repeatCycle),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      repeatEvery: Value(repeatEvery),
      monday: Value(monday),
      tuesday: Value(tuesday),
      wednesday: Value(wednesday),
      thursday: Value(thursday),
      friday: Value(friday),
      saturday: Value(saturday),
      sunday: Value(sunday),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      subTaskTemplates: Value(subTaskTemplates),
      lastTaskCreation: lastTaskCreation == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTaskCreation),
      lastTaskCreationDay: lastTaskCreationDay == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTaskCreationDay),
      deletedInstanceDates: Value(deletedInstanceDates),
      crdtClock: Value(crdtClock),
      crdtState: Value(crdtState),
    );
  }

  factory TaskRepeatCfg.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRepeatCfg(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      title: serializer.fromJson<String?>(json['title']),
      tagIds: serializer.fromJson<String>(json['tagIds']),
      order: serializer.fromJson<int>(json['order']),
      defaultEstimate: serializer.fromJson<int?>(json['defaultEstimate']),
      startTime: serializer.fromJson<String?>(json['startTime']),
      remindAt: serializer.fromJson<String?>(json['remindAt']),
      isPaused: serializer.fromJson<bool>(json['isPaused']),
      quickSetting: serializer.fromJson<String>(json['quickSetting']),
      repeatCycle: serializer.fromJson<String>(json['repeatCycle']),
      startDate: serializer.fromJson<String?>(json['startDate']),
      repeatEvery: serializer.fromJson<int>(json['repeatEvery']),
      monday: serializer.fromJson<bool>(json['monday']),
      tuesday: serializer.fromJson<bool>(json['tuesday']),
      wednesday: serializer.fromJson<bool>(json['wednesday']),
      thursday: serializer.fromJson<bool>(json['thursday']),
      friday: serializer.fromJson<bool>(json['friday']),
      saturday: serializer.fromJson<bool>(json['saturday']),
      sunday: serializer.fromJson<bool>(json['sunday']),
      notes: serializer.fromJson<String?>(json['notes']),
      subTaskTemplates: serializer.fromJson<String>(json['subTaskTemplates']),
      lastTaskCreation: serializer.fromJson<int?>(json['lastTaskCreation']),
      lastTaskCreationDay: serializer.fromJson<String?>(
        json['lastTaskCreationDay'],
      ),
      deletedInstanceDates: serializer.fromJson<String>(
        json['deletedInstanceDates'],
      ),
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
      'title': serializer.toJson<String?>(title),
      'tagIds': serializer.toJson<String>(tagIds),
      'order': serializer.toJson<int>(order),
      'defaultEstimate': serializer.toJson<int?>(defaultEstimate),
      'startTime': serializer.toJson<String?>(startTime),
      'remindAt': serializer.toJson<String?>(remindAt),
      'isPaused': serializer.toJson<bool>(isPaused),
      'quickSetting': serializer.toJson<String>(quickSetting),
      'repeatCycle': serializer.toJson<String>(repeatCycle),
      'startDate': serializer.toJson<String?>(startDate),
      'repeatEvery': serializer.toJson<int>(repeatEvery),
      'monday': serializer.toJson<bool>(monday),
      'tuesday': serializer.toJson<bool>(tuesday),
      'wednesday': serializer.toJson<bool>(wednesday),
      'thursday': serializer.toJson<bool>(thursday),
      'friday': serializer.toJson<bool>(friday),
      'saturday': serializer.toJson<bool>(saturday),
      'sunday': serializer.toJson<bool>(sunday),
      'notes': serializer.toJson<String?>(notes),
      'subTaskTemplates': serializer.toJson<String>(subTaskTemplates),
      'lastTaskCreation': serializer.toJson<int?>(lastTaskCreation),
      'lastTaskCreationDay': serializer.toJson<String?>(lastTaskCreationDay),
      'deletedInstanceDates': serializer.toJson<String>(deletedInstanceDates),
      'crdtClock': serializer.toJson<String>(crdtClock),
      'crdtState': serializer.toJson<String>(crdtState),
    };
  }

  TaskRepeatCfg copyWith({
    String? id,
    Value<String?> projectId = const Value.absent(),
    Value<String?> title = const Value.absent(),
    String? tagIds,
    int? order,
    Value<int?> defaultEstimate = const Value.absent(),
    Value<String?> startTime = const Value.absent(),
    Value<String?> remindAt = const Value.absent(),
    bool? isPaused,
    String? quickSetting,
    String? repeatCycle,
    Value<String?> startDate = const Value.absent(),
    int? repeatEvery,
    bool? monday,
    bool? tuesday,
    bool? wednesday,
    bool? thursday,
    bool? friday,
    bool? saturday,
    bool? sunday,
    Value<String?> notes = const Value.absent(),
    String? subTaskTemplates,
    Value<int?> lastTaskCreation = const Value.absent(),
    Value<String?> lastTaskCreationDay = const Value.absent(),
    String? deletedInstanceDates,
    String? crdtClock,
    String? crdtState,
  }) => TaskRepeatCfg(
    id: id ?? this.id,
    projectId: projectId.present ? projectId.value : this.projectId,
    title: title.present ? title.value : this.title,
    tagIds: tagIds ?? this.tagIds,
    order: order ?? this.order,
    defaultEstimate: defaultEstimate.present
        ? defaultEstimate.value
        : this.defaultEstimate,
    startTime: startTime.present ? startTime.value : this.startTime,
    remindAt: remindAt.present ? remindAt.value : this.remindAt,
    isPaused: isPaused ?? this.isPaused,
    quickSetting: quickSetting ?? this.quickSetting,
    repeatCycle: repeatCycle ?? this.repeatCycle,
    startDate: startDate.present ? startDate.value : this.startDate,
    repeatEvery: repeatEvery ?? this.repeatEvery,
    monday: monday ?? this.monday,
    tuesday: tuesday ?? this.tuesday,
    wednesday: wednesday ?? this.wednesday,
    thursday: thursday ?? this.thursday,
    friday: friday ?? this.friday,
    saturday: saturday ?? this.saturday,
    sunday: sunday ?? this.sunday,
    notes: notes.present ? notes.value : this.notes,
    subTaskTemplates: subTaskTemplates ?? this.subTaskTemplates,
    lastTaskCreation: lastTaskCreation.present
        ? lastTaskCreation.value
        : this.lastTaskCreation,
    lastTaskCreationDay: lastTaskCreationDay.present
        ? lastTaskCreationDay.value
        : this.lastTaskCreationDay,
    deletedInstanceDates: deletedInstanceDates ?? this.deletedInstanceDates,
    crdtClock: crdtClock ?? this.crdtClock,
    crdtState: crdtState ?? this.crdtState,
  );
  TaskRepeatCfg copyWithCompanion(TaskRepeatCfgsCompanion data) {
    return TaskRepeatCfg(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      title: data.title.present ? data.title.value : this.title,
      tagIds: data.tagIds.present ? data.tagIds.value : this.tagIds,
      order: data.order.present ? data.order.value : this.order,
      defaultEstimate: data.defaultEstimate.present
          ? data.defaultEstimate.value
          : this.defaultEstimate,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
      isPaused: data.isPaused.present ? data.isPaused.value : this.isPaused,
      quickSetting: data.quickSetting.present
          ? data.quickSetting.value
          : this.quickSetting,
      repeatCycle: data.repeatCycle.present
          ? data.repeatCycle.value
          : this.repeatCycle,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      repeatEvery: data.repeatEvery.present
          ? data.repeatEvery.value
          : this.repeatEvery,
      monday: data.monday.present ? data.monday.value : this.monday,
      tuesday: data.tuesday.present ? data.tuesday.value : this.tuesday,
      wednesday: data.wednesday.present ? data.wednesday.value : this.wednesday,
      thursday: data.thursday.present ? data.thursday.value : this.thursday,
      friday: data.friday.present ? data.friday.value : this.friday,
      saturday: data.saturday.present ? data.saturday.value : this.saturday,
      sunday: data.sunday.present ? data.sunday.value : this.sunday,
      notes: data.notes.present ? data.notes.value : this.notes,
      subTaskTemplates: data.subTaskTemplates.present
          ? data.subTaskTemplates.value
          : this.subTaskTemplates,
      lastTaskCreation: data.lastTaskCreation.present
          ? data.lastTaskCreation.value
          : this.lastTaskCreation,
      lastTaskCreationDay: data.lastTaskCreationDay.present
          ? data.lastTaskCreationDay.value
          : this.lastTaskCreationDay,
      deletedInstanceDates: data.deletedInstanceDates.present
          ? data.deletedInstanceDates.value
          : this.deletedInstanceDates,
      crdtClock: data.crdtClock.present ? data.crdtClock.value : this.crdtClock,
      crdtState: data.crdtState.present ? data.crdtState.value : this.crdtState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRepeatCfg(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('tagIds: $tagIds, ')
          ..write('order: $order, ')
          ..write('defaultEstimate: $defaultEstimate, ')
          ..write('startTime: $startTime, ')
          ..write('remindAt: $remindAt, ')
          ..write('isPaused: $isPaused, ')
          ..write('quickSetting: $quickSetting, ')
          ..write('repeatCycle: $repeatCycle, ')
          ..write('startDate: $startDate, ')
          ..write('repeatEvery: $repeatEvery, ')
          ..write('monday: $monday, ')
          ..write('tuesday: $tuesday, ')
          ..write('wednesday: $wednesday, ')
          ..write('thursday: $thursday, ')
          ..write('friday: $friday, ')
          ..write('saturday: $saturday, ')
          ..write('sunday: $sunday, ')
          ..write('notes: $notes, ')
          ..write('subTaskTemplates: $subTaskTemplates, ')
          ..write('lastTaskCreation: $lastTaskCreation, ')
          ..write('lastTaskCreationDay: $lastTaskCreationDay, ')
          ..write('deletedInstanceDates: $deletedInstanceDates, ')
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
    tagIds,
    order,
    defaultEstimate,
    startTime,
    remindAt,
    isPaused,
    quickSetting,
    repeatCycle,
    startDate,
    repeatEvery,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
    notes,
    subTaskTemplates,
    lastTaskCreation,
    lastTaskCreationDay,
    deletedInstanceDates,
    crdtClock,
    crdtState,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRepeatCfg &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.title == this.title &&
          other.tagIds == this.tagIds &&
          other.order == this.order &&
          other.defaultEstimate == this.defaultEstimate &&
          other.startTime == this.startTime &&
          other.remindAt == this.remindAt &&
          other.isPaused == this.isPaused &&
          other.quickSetting == this.quickSetting &&
          other.repeatCycle == this.repeatCycle &&
          other.startDate == this.startDate &&
          other.repeatEvery == this.repeatEvery &&
          other.monday == this.monday &&
          other.tuesday == this.tuesday &&
          other.wednesday == this.wednesday &&
          other.thursday == this.thursday &&
          other.friday == this.friday &&
          other.saturday == this.saturday &&
          other.sunday == this.sunday &&
          other.notes == this.notes &&
          other.subTaskTemplates == this.subTaskTemplates &&
          other.lastTaskCreation == this.lastTaskCreation &&
          other.lastTaskCreationDay == this.lastTaskCreationDay &&
          other.deletedInstanceDates == this.deletedInstanceDates &&
          other.crdtClock == this.crdtClock &&
          other.crdtState == this.crdtState);
}

class TaskRepeatCfgsCompanion extends UpdateCompanion<TaskRepeatCfg> {
  final Value<String> id;
  final Value<String?> projectId;
  final Value<String?> title;
  final Value<String> tagIds;
  final Value<int> order;
  final Value<int?> defaultEstimate;
  final Value<String?> startTime;
  final Value<String?> remindAt;
  final Value<bool> isPaused;
  final Value<String> quickSetting;
  final Value<String> repeatCycle;
  final Value<String?> startDate;
  final Value<int> repeatEvery;
  final Value<bool> monday;
  final Value<bool> tuesday;
  final Value<bool> wednesday;
  final Value<bool> thursday;
  final Value<bool> friday;
  final Value<bool> saturday;
  final Value<bool> sunday;
  final Value<String?> notes;
  final Value<String> subTaskTemplates;
  final Value<int?> lastTaskCreation;
  final Value<String?> lastTaskCreationDay;
  final Value<String> deletedInstanceDates;
  final Value<String> crdtClock;
  final Value<String> crdtState;
  final Value<int> rowid;
  const TaskRepeatCfgsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.tagIds = const Value.absent(),
    this.order = const Value.absent(),
    this.defaultEstimate = const Value.absent(),
    this.startTime = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.quickSetting = const Value.absent(),
    this.repeatCycle = const Value.absent(),
    this.startDate = const Value.absent(),
    this.repeatEvery = const Value.absent(),
    this.monday = const Value.absent(),
    this.tuesday = const Value.absent(),
    this.wednesday = const Value.absent(),
    this.thursday = const Value.absent(),
    this.friday = const Value.absent(),
    this.saturday = const Value.absent(),
    this.sunday = const Value.absent(),
    this.notes = const Value.absent(),
    this.subTaskTemplates = const Value.absent(),
    this.lastTaskCreation = const Value.absent(),
    this.lastTaskCreationDay = const Value.absent(),
    this.deletedInstanceDates = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskRepeatCfgsCompanion.insert({
    required String id,
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.tagIds = const Value.absent(),
    this.order = const Value.absent(),
    this.defaultEstimate = const Value.absent(),
    this.startTime = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.isPaused = const Value.absent(),
    required String quickSetting,
    required String repeatCycle,
    this.startDate = const Value.absent(),
    this.repeatEvery = const Value.absent(),
    this.monday = const Value.absent(),
    this.tuesday = const Value.absent(),
    this.wednesday = const Value.absent(),
    this.thursday = const Value.absent(),
    this.friday = const Value.absent(),
    this.saturday = const Value.absent(),
    this.sunday = const Value.absent(),
    this.notes = const Value.absent(),
    this.subTaskTemplates = const Value.absent(),
    this.lastTaskCreation = const Value.absent(),
    this.lastTaskCreationDay = const Value.absent(),
    this.deletedInstanceDates = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       quickSetting = Value(quickSetting),
       repeatCycle = Value(repeatCycle);
  static Insertable<TaskRepeatCfg> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? title,
    Expression<String>? tagIds,
    Expression<int>? order,
    Expression<int>? defaultEstimate,
    Expression<String>? startTime,
    Expression<String>? remindAt,
    Expression<bool>? isPaused,
    Expression<String>? quickSetting,
    Expression<String>? repeatCycle,
    Expression<String>? startDate,
    Expression<int>? repeatEvery,
    Expression<bool>? monday,
    Expression<bool>? tuesday,
    Expression<bool>? wednesday,
    Expression<bool>? thursday,
    Expression<bool>? friday,
    Expression<bool>? saturday,
    Expression<bool>? sunday,
    Expression<String>? notes,
    Expression<String>? subTaskTemplates,
    Expression<int>? lastTaskCreation,
    Expression<String>? lastTaskCreationDay,
    Expression<String>? deletedInstanceDates,
    Expression<String>? crdtClock,
    Expression<String>? crdtState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (title != null) 'title': title,
      if (tagIds != null) 'tag_ids': tagIds,
      if (order != null) 'order': order,
      if (defaultEstimate != null) 'default_estimate': defaultEstimate,
      if (startTime != null) 'start_time': startTime,
      if (remindAt != null) 'remind_at': remindAt,
      if (isPaused != null) 'is_paused': isPaused,
      if (quickSetting != null) 'quick_setting': quickSetting,
      if (repeatCycle != null) 'repeat_cycle': repeatCycle,
      if (startDate != null) 'start_date': startDate,
      if (repeatEvery != null) 'repeat_every': repeatEvery,
      if (monday != null) 'monday': monday,
      if (tuesday != null) 'tuesday': tuesday,
      if (wednesday != null) 'wednesday': wednesday,
      if (thursday != null) 'thursday': thursday,
      if (friday != null) 'friday': friday,
      if (saturday != null) 'saturday': saturday,
      if (sunday != null) 'sunday': sunday,
      if (notes != null) 'notes': notes,
      if (subTaskTemplates != null) 'sub_task_templates': subTaskTemplates,
      if (lastTaskCreation != null) 'last_task_creation': lastTaskCreation,
      if (lastTaskCreationDay != null)
        'last_task_creation_day': lastTaskCreationDay,
      if (deletedInstanceDates != null)
        'deleted_instance_dates': deletedInstanceDates,
      if (crdtClock != null) 'crdt_clock': crdtClock,
      if (crdtState != null) 'crdt_state': crdtState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskRepeatCfgsCompanion copyWith({
    Value<String>? id,
    Value<String?>? projectId,
    Value<String?>? title,
    Value<String>? tagIds,
    Value<int>? order,
    Value<int?>? defaultEstimate,
    Value<String?>? startTime,
    Value<String?>? remindAt,
    Value<bool>? isPaused,
    Value<String>? quickSetting,
    Value<String>? repeatCycle,
    Value<String?>? startDate,
    Value<int>? repeatEvery,
    Value<bool>? monday,
    Value<bool>? tuesday,
    Value<bool>? wednesday,
    Value<bool>? thursday,
    Value<bool>? friday,
    Value<bool>? saturday,
    Value<bool>? sunday,
    Value<String?>? notes,
    Value<String>? subTaskTemplates,
    Value<int?>? lastTaskCreation,
    Value<String?>? lastTaskCreationDay,
    Value<String>? deletedInstanceDates,
    Value<String>? crdtClock,
    Value<String>? crdtState,
    Value<int>? rowid,
  }) {
    return TaskRepeatCfgsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      tagIds: tagIds ?? this.tagIds,
      order: order ?? this.order,
      defaultEstimate: defaultEstimate ?? this.defaultEstimate,
      startTime: startTime ?? this.startTime,
      remindAt: remindAt ?? this.remindAt,
      isPaused: isPaused ?? this.isPaused,
      quickSetting: quickSetting ?? this.quickSetting,
      repeatCycle: repeatCycle ?? this.repeatCycle,
      startDate: startDate ?? this.startDate,
      repeatEvery: repeatEvery ?? this.repeatEvery,
      monday: monday ?? this.monday,
      tuesday: tuesday ?? this.tuesday,
      wednesday: wednesday ?? this.wednesday,
      thursday: thursday ?? this.thursday,
      friday: friday ?? this.friday,
      saturday: saturday ?? this.saturday,
      sunday: sunday ?? this.sunday,
      notes: notes ?? this.notes,
      subTaskTemplates: subTaskTemplates ?? this.subTaskTemplates,
      lastTaskCreation: lastTaskCreation ?? this.lastTaskCreation,
      lastTaskCreationDay: lastTaskCreationDay ?? this.lastTaskCreationDay,
      deletedInstanceDates: deletedInstanceDates ?? this.deletedInstanceDates,
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
    if (tagIds.present) {
      map['tag_ids'] = Variable<String>(tagIds.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (defaultEstimate.present) {
      map['default_estimate'] = Variable<int>(defaultEstimate.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<String>(remindAt.value);
    }
    if (isPaused.present) {
      map['is_paused'] = Variable<bool>(isPaused.value);
    }
    if (quickSetting.present) {
      map['quick_setting'] = Variable<String>(quickSetting.value);
    }
    if (repeatCycle.present) {
      map['repeat_cycle'] = Variable<String>(repeatCycle.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (repeatEvery.present) {
      map['repeat_every'] = Variable<int>(repeatEvery.value);
    }
    if (monday.present) {
      map['monday'] = Variable<bool>(monday.value);
    }
    if (tuesday.present) {
      map['tuesday'] = Variable<bool>(tuesday.value);
    }
    if (wednesday.present) {
      map['wednesday'] = Variable<bool>(wednesday.value);
    }
    if (thursday.present) {
      map['thursday'] = Variable<bool>(thursday.value);
    }
    if (friday.present) {
      map['friday'] = Variable<bool>(friday.value);
    }
    if (saturday.present) {
      map['saturday'] = Variable<bool>(saturday.value);
    }
    if (sunday.present) {
      map['sunday'] = Variable<bool>(sunday.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (subTaskTemplates.present) {
      map['sub_task_templates'] = Variable<String>(subTaskTemplates.value);
    }
    if (lastTaskCreation.present) {
      map['last_task_creation'] = Variable<int>(lastTaskCreation.value);
    }
    if (lastTaskCreationDay.present) {
      map['last_task_creation_day'] = Variable<String>(
        lastTaskCreationDay.value,
      );
    }
    if (deletedInstanceDates.present) {
      map['deleted_instance_dates'] = Variable<String>(
        deletedInstanceDates.value,
      );
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
    return (StringBuffer('TaskRepeatCfgsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('tagIds: $tagIds, ')
          ..write('order: $order, ')
          ..write('defaultEstimate: $defaultEstimate, ')
          ..write('startTime: $startTime, ')
          ..write('remindAt: $remindAt, ')
          ..write('isPaused: $isPaused, ')
          ..write('quickSetting: $quickSetting, ')
          ..write('repeatCycle: $repeatCycle, ')
          ..write('startDate: $startDate, ')
          ..write('repeatEvery: $repeatEvery, ')
          ..write('monday: $monday, ')
          ..write('tuesday: $tuesday, ')
          ..write('wednesday: $wednesday, ')
          ..write('thursday: $thursday, ')
          ..write('friday: $friday, ')
          ..write('saturday: $saturday, ')
          ..write('sunday: $sunday, ')
          ..write('notes: $notes, ')
          ..write('subTaskTemplates: $subTaskTemplates, ')
          ..write('lastTaskCreation: $lastTaskCreation, ')
          ..write('lastTaskCreationDay: $lastTaskCreationDay, ')
          ..write('deletedInstanceDates: $deletedInstanceDates, ')
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
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apiTokenMeta = const VerificationMeta(
    'apiToken',
  );
  @override
  late final GeneratedColumn<String> apiToken = GeneratedColumn<String>(
    'api_token',
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
    email,
    apiToken,
    jiraProjectKey,
    boardId,
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
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('api_token')) {
      context.handle(
        _apiTokenMeta,
        apiToken.isAcceptableOrUnknown(data['api_token']!, _apiTokenMeta),
      );
    } else if (isInserting) {
      context.missing(_apiTokenMeta);
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
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      apiToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_token'],
      )!,
      jiraProjectKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jira_project_key'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      ),
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
  final String email;
  final String apiToken;
  final String jiraProjectKey;
  final String? boardId;
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
    required this.email,
    required this.apiToken,
    required this.jiraProjectKey,
    this.boardId,
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
    map['email'] = Variable<String>(email);
    map['api_token'] = Variable<String>(apiToken);
    map['jira_project_key'] = Variable<String>(jiraProjectKey);
    if (!nullToAbsent || boardId != null) {
      map['board_id'] = Variable<String>(boardId);
    }
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
      email: Value(email),
      apiToken: Value(apiToken),
      jiraProjectKey: Value(jiraProjectKey),
      boardId: boardId == null && nullToAbsent
          ? const Value.absent()
          : Value(boardId),
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
      email: serializer.fromJson<String>(json['email']),
      apiToken: serializer.fromJson<String>(json['apiToken']),
      jiraProjectKey: serializer.fromJson<String>(json['jiraProjectKey']),
      boardId: serializer.fromJson<String?>(json['boardId']),
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
      'email': serializer.toJson<String>(email),
      'apiToken': serializer.toJson<String>(apiToken),
      'jiraProjectKey': serializer.toJson<String>(jiraProjectKey),
      'boardId': serializer.toJson<String?>(boardId),
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
    String? email,
    String? apiToken,
    String? jiraProjectKey,
    Value<String?> boardId = const Value.absent(),
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
    email: email ?? this.email,
    apiToken: apiToken ?? this.apiToken,
    jiraProjectKey: jiraProjectKey ?? this.jiraProjectKey,
    boardId: boardId.present ? boardId.value : this.boardId,
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
      email: data.email.present ? data.email.value : this.email,
      apiToken: data.apiToken.present ? data.apiToken.value : this.apiToken,
      jiraProjectKey: data.jiraProjectKey.present
          ? data.jiraProjectKey.value
          : this.jiraProjectKey,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
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
          ..write('email: $email, ')
          ..write('apiToken: $apiToken, ')
          ..write('jiraProjectKey: $jiraProjectKey, ')
          ..write('boardId: $boardId, ')
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
    email,
    apiToken,
    jiraProjectKey,
    boardId,
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
          other.email == this.email &&
          other.apiToken == this.apiToken &&
          other.jiraProjectKey == this.jiraProjectKey &&
          other.boardId == this.boardId &&
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
  final Value<String> email;
  final Value<String> apiToken;
  final Value<String> jiraProjectKey;
  final Value<String?> boardId;
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
    this.email = const Value.absent(),
    this.apiToken = const Value.absent(),
    this.jiraProjectKey = const Value.absent(),
    this.boardId = const Value.absent(),
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
    required String email,
    required String apiToken,
    required String jiraProjectKey,
    this.boardId = const Value.absent(),
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
       email = Value(email),
       apiToken = Value(apiToken),
       jiraProjectKey = Value(jiraProjectKey),
       created = Value(created);
  static Insertable<JiraIntegration> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? baseUrl,
    Expression<String>? email,
    Expression<String>? apiToken,
    Expression<String>? jiraProjectKey,
    Expression<String>? boardId,
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
      if (email != null) 'email': email,
      if (apiToken != null) 'api_token': apiToken,
      if (jiraProjectKey != null) 'jira_project_key': jiraProjectKey,
      if (boardId != null) 'board_id': boardId,
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
    Value<String>? email,
    Value<String>? apiToken,
    Value<String>? jiraProjectKey,
    Value<String?>? boardId,
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
      email: email ?? this.email,
      apiToken: apiToken ?? this.apiToken,
      jiraProjectKey: jiraProjectKey ?? this.jiraProjectKey,
      boardId: boardId ?? this.boardId,
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
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (apiToken.present) {
      map['api_token'] = Variable<String>(apiToken.value);
    }
    if (jiraProjectKey.present) {
      map['jira_project_key'] = Variable<String>(jiraProjectKey.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
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
          ..write('email: $email, ')
          ..write('apiToken: $apiToken, ')
          ..write('jiraProjectKey: $jiraProjectKey, ')
          ..write('boardId: $boardId, ')
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

class $GithubIntegrationsTable extends GithubIntegrations
    with TableInfo<$GithubIntegrationsTable, GithubIntegration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GithubIntegrationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  @override
  late final GeneratedColumn<String> owner = GeneratedColumn<String>(
    'owner',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repoMeta = const VerificationMeta('repo');
  @override
  late final GeneratedColumn<String> repo = GeneratedColumn<String>(
    'repo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accessTokenMeta = const VerificationMeta(
    'accessToken',
  );
  @override
  late final GeneratedColumn<String> accessToken = GeneratedColumn<String>(
    'access_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelFilterMeta = const VerificationMeta(
    'labelFilter',
  );
  @override
  late final GeneratedColumn<String> labelFilter = GeneratedColumn<String>(
    'label_filter',
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
  static const VerificationMeta _syncClosedIssuesMeta = const VerificationMeta(
    'syncClosedIssues',
  );
  @override
  late final GeneratedColumn<bool> syncClosedIssues = GeneratedColumn<bool>(
    'sync_closed_issues',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sync_closed_issues" IN (0, 1))',
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
  static const VerificationMeta _labelMappingsMeta = const VerificationMeta(
    'labelMappings',
  );
  @override
  late final GeneratedColumn<String> labelMappings = GeneratedColumn<String>(
    'label_mappings',
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
  static const VerificationMeta _milestoneMappingsMeta = const VerificationMeta(
    'milestoneMappings',
  );
  @override
  late final GeneratedColumn<String> milestoneMappings =
      GeneratedColumn<String>(
        'milestone_mappings',
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
    owner,
    repo,
    accessToken,
    labelFilter,
    syncEnabled,
    syncClosedIssues,
    syncIntervalMinutes,
    labelMappings,
    statusMappings,
    milestoneMappings,
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
  static const String $name = 'github_integrations';
  @override
  VerificationContext validateIntegrity(
    Insertable<GithubIntegration> instance, {
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
    if (data.containsKey('owner')) {
      context.handle(
        _ownerMeta,
        owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerMeta);
    }
    if (data.containsKey('repo')) {
      context.handle(
        _repoMeta,
        repo.isAcceptableOrUnknown(data['repo']!, _repoMeta),
      );
    } else if (isInserting) {
      context.missing(_repoMeta);
    }
    if (data.containsKey('access_token')) {
      context.handle(
        _accessTokenMeta,
        accessToken.isAcceptableOrUnknown(
          data['access_token']!,
          _accessTokenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accessTokenMeta);
    }
    if (data.containsKey('label_filter')) {
      context.handle(
        _labelFilterMeta,
        labelFilter.isAcceptableOrUnknown(
          data['label_filter']!,
          _labelFilterMeta,
        ),
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
    if (data.containsKey('sync_closed_issues')) {
      context.handle(
        _syncClosedIssuesMeta,
        syncClosedIssues.isAcceptableOrUnknown(
          data['sync_closed_issues']!,
          _syncClosedIssuesMeta,
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
    if (data.containsKey('label_mappings')) {
      context.handle(
        _labelMappingsMeta,
        labelMappings.isAcceptableOrUnknown(
          data['label_mappings']!,
          _labelMappingsMeta,
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
    if (data.containsKey('milestone_mappings')) {
      context.handle(
        _milestoneMappingsMeta,
        milestoneMappings.isAcceptableOrUnknown(
          data['milestone_mappings']!,
          _milestoneMappingsMeta,
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
  GithubIntegration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GithubIntegration(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      owner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner'],
      )!,
      repo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo'],
      )!,
      accessToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_token'],
      )!,
      labelFilter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_filter'],
      ),
      syncEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_enabled'],
      )!,
      syncClosedIssues: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sync_closed_issues'],
      )!,
      syncIntervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_interval_minutes'],
      )!,
      labelMappings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_mappings'],
      )!,
      statusMappings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_mappings'],
      )!,
      milestoneMappings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}milestone_mappings'],
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
  $GithubIntegrationsTable createAlias(String alias) {
    return $GithubIntegrationsTable(attachedDatabase, alias);
  }
}

class GithubIntegration extends DataClass
    implements Insertable<GithubIntegration> {
  final String id;
  final String? projectId;
  final String owner;
  final String repo;
  final String accessToken;
  final String? labelFilter;
  final bool syncEnabled;
  final bool syncClosedIssues;
  final int syncIntervalMinutes;
  final String labelMappings;
  final String statusMappings;
  final String milestoneMappings;
  final int? lastSyncAt;
  final String? lastSyncError;
  final int created;
  final int? modified;
  final String crdtClock;
  final String crdtState;
  const GithubIntegration({
    required this.id,
    this.projectId,
    required this.owner,
    required this.repo,
    required this.accessToken,
    this.labelFilter,
    required this.syncEnabled,
    required this.syncClosedIssues,
    required this.syncIntervalMinutes,
    required this.labelMappings,
    required this.statusMappings,
    required this.milestoneMappings,
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
    map['owner'] = Variable<String>(owner);
    map['repo'] = Variable<String>(repo);
    map['access_token'] = Variable<String>(accessToken);
    if (!nullToAbsent || labelFilter != null) {
      map['label_filter'] = Variable<String>(labelFilter);
    }
    map['sync_enabled'] = Variable<bool>(syncEnabled);
    map['sync_closed_issues'] = Variable<bool>(syncClosedIssues);
    map['sync_interval_minutes'] = Variable<int>(syncIntervalMinutes);
    map['label_mappings'] = Variable<String>(labelMappings);
    map['status_mappings'] = Variable<String>(statusMappings);
    map['milestone_mappings'] = Variable<String>(milestoneMappings);
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

  GithubIntegrationsCompanion toCompanion(bool nullToAbsent) {
    return GithubIntegrationsCompanion(
      id: Value(id),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      owner: Value(owner),
      repo: Value(repo),
      accessToken: Value(accessToken),
      labelFilter: labelFilter == null && nullToAbsent
          ? const Value.absent()
          : Value(labelFilter),
      syncEnabled: Value(syncEnabled),
      syncClosedIssues: Value(syncClosedIssues),
      syncIntervalMinutes: Value(syncIntervalMinutes),
      labelMappings: Value(labelMappings),
      statusMappings: Value(statusMappings),
      milestoneMappings: Value(milestoneMappings),
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

  factory GithubIntegration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GithubIntegration(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      owner: serializer.fromJson<String>(json['owner']),
      repo: serializer.fromJson<String>(json['repo']),
      accessToken: serializer.fromJson<String>(json['accessToken']),
      labelFilter: serializer.fromJson<String?>(json['labelFilter']),
      syncEnabled: serializer.fromJson<bool>(json['syncEnabled']),
      syncClosedIssues: serializer.fromJson<bool>(json['syncClosedIssues']),
      syncIntervalMinutes: serializer.fromJson<int>(
        json['syncIntervalMinutes'],
      ),
      labelMappings: serializer.fromJson<String>(json['labelMappings']),
      statusMappings: serializer.fromJson<String>(json['statusMappings']),
      milestoneMappings: serializer.fromJson<String>(json['milestoneMappings']),
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
      'owner': serializer.toJson<String>(owner),
      'repo': serializer.toJson<String>(repo),
      'accessToken': serializer.toJson<String>(accessToken),
      'labelFilter': serializer.toJson<String?>(labelFilter),
      'syncEnabled': serializer.toJson<bool>(syncEnabled),
      'syncClosedIssues': serializer.toJson<bool>(syncClosedIssues),
      'syncIntervalMinutes': serializer.toJson<int>(syncIntervalMinutes),
      'labelMappings': serializer.toJson<String>(labelMappings),
      'statusMappings': serializer.toJson<String>(statusMappings),
      'milestoneMappings': serializer.toJson<String>(milestoneMappings),
      'lastSyncAt': serializer.toJson<int?>(lastSyncAt),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'created': serializer.toJson<int>(created),
      'modified': serializer.toJson<int?>(modified),
      'crdtClock': serializer.toJson<String>(crdtClock),
      'crdtState': serializer.toJson<String>(crdtState),
    };
  }

  GithubIntegration copyWith({
    String? id,
    Value<String?> projectId = const Value.absent(),
    String? owner,
    String? repo,
    String? accessToken,
    Value<String?> labelFilter = const Value.absent(),
    bool? syncEnabled,
    bool? syncClosedIssues,
    int? syncIntervalMinutes,
    String? labelMappings,
    String? statusMappings,
    String? milestoneMappings,
    Value<int?> lastSyncAt = const Value.absent(),
    Value<String?> lastSyncError = const Value.absent(),
    int? created,
    Value<int?> modified = const Value.absent(),
    String? crdtClock,
    String? crdtState,
  }) => GithubIntegration(
    id: id ?? this.id,
    projectId: projectId.present ? projectId.value : this.projectId,
    owner: owner ?? this.owner,
    repo: repo ?? this.repo,
    accessToken: accessToken ?? this.accessToken,
    labelFilter: labelFilter.present ? labelFilter.value : this.labelFilter,
    syncEnabled: syncEnabled ?? this.syncEnabled,
    syncClosedIssues: syncClosedIssues ?? this.syncClosedIssues,
    syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
    labelMappings: labelMappings ?? this.labelMappings,
    statusMappings: statusMappings ?? this.statusMappings,
    milestoneMappings: milestoneMappings ?? this.milestoneMappings,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
    created: created ?? this.created,
    modified: modified.present ? modified.value : this.modified,
    crdtClock: crdtClock ?? this.crdtClock,
    crdtState: crdtState ?? this.crdtState,
  );
  GithubIntegration copyWithCompanion(GithubIntegrationsCompanion data) {
    return GithubIntegration(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      owner: data.owner.present ? data.owner.value : this.owner,
      repo: data.repo.present ? data.repo.value : this.repo,
      accessToken: data.accessToken.present
          ? data.accessToken.value
          : this.accessToken,
      labelFilter: data.labelFilter.present
          ? data.labelFilter.value
          : this.labelFilter,
      syncEnabled: data.syncEnabled.present
          ? data.syncEnabled.value
          : this.syncEnabled,
      syncClosedIssues: data.syncClosedIssues.present
          ? data.syncClosedIssues.value
          : this.syncClosedIssues,
      syncIntervalMinutes: data.syncIntervalMinutes.present
          ? data.syncIntervalMinutes.value
          : this.syncIntervalMinutes,
      labelMappings: data.labelMappings.present
          ? data.labelMappings.value
          : this.labelMappings,
      statusMappings: data.statusMappings.present
          ? data.statusMappings.value
          : this.statusMappings,
      milestoneMappings: data.milestoneMappings.present
          ? data.milestoneMappings.value
          : this.milestoneMappings,
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
    return (StringBuffer('GithubIntegration(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('owner: $owner, ')
          ..write('repo: $repo, ')
          ..write('accessToken: $accessToken, ')
          ..write('labelFilter: $labelFilter, ')
          ..write('syncEnabled: $syncEnabled, ')
          ..write('syncClosedIssues: $syncClosedIssues, ')
          ..write('syncIntervalMinutes: $syncIntervalMinutes, ')
          ..write('labelMappings: $labelMappings, ')
          ..write('statusMappings: $statusMappings, ')
          ..write('milestoneMappings: $milestoneMappings, ')
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
    owner,
    repo,
    accessToken,
    labelFilter,
    syncEnabled,
    syncClosedIssues,
    syncIntervalMinutes,
    labelMappings,
    statusMappings,
    milestoneMappings,
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
      (other is GithubIntegration &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.owner == this.owner &&
          other.repo == this.repo &&
          other.accessToken == this.accessToken &&
          other.labelFilter == this.labelFilter &&
          other.syncEnabled == this.syncEnabled &&
          other.syncClosedIssues == this.syncClosedIssues &&
          other.syncIntervalMinutes == this.syncIntervalMinutes &&
          other.labelMappings == this.labelMappings &&
          other.statusMappings == this.statusMappings &&
          other.milestoneMappings == this.milestoneMappings &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastSyncError == this.lastSyncError &&
          other.created == this.created &&
          other.modified == this.modified &&
          other.crdtClock == this.crdtClock &&
          other.crdtState == this.crdtState);
}

class GithubIntegrationsCompanion extends UpdateCompanion<GithubIntegration> {
  final Value<String> id;
  final Value<String?> projectId;
  final Value<String> owner;
  final Value<String> repo;
  final Value<String> accessToken;
  final Value<String?> labelFilter;
  final Value<bool> syncEnabled;
  final Value<bool> syncClosedIssues;
  final Value<int> syncIntervalMinutes;
  final Value<String> labelMappings;
  final Value<String> statusMappings;
  final Value<String> milestoneMappings;
  final Value<int?> lastSyncAt;
  final Value<String?> lastSyncError;
  final Value<int> created;
  final Value<int?> modified;
  final Value<String> crdtClock;
  final Value<String> crdtState;
  final Value<int> rowid;
  const GithubIntegrationsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.owner = const Value.absent(),
    this.repo = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.labelFilter = const Value.absent(),
    this.syncEnabled = const Value.absent(),
    this.syncClosedIssues = const Value.absent(),
    this.syncIntervalMinutes = const Value.absent(),
    this.labelMappings = const Value.absent(),
    this.statusMappings = const Value.absent(),
    this.milestoneMappings = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.created = const Value.absent(),
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GithubIntegrationsCompanion.insert({
    required String id,
    this.projectId = const Value.absent(),
    required String owner,
    required String repo,
    required String accessToken,
    this.labelFilter = const Value.absent(),
    this.syncEnabled = const Value.absent(),
    this.syncClosedIssues = const Value.absent(),
    this.syncIntervalMinutes = const Value.absent(),
    this.labelMappings = const Value.absent(),
    this.statusMappings = const Value.absent(),
    this.milestoneMappings = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    required int created,
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       owner = Value(owner),
       repo = Value(repo),
       accessToken = Value(accessToken),
       created = Value(created);
  static Insertable<GithubIntegration> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? owner,
    Expression<String>? repo,
    Expression<String>? accessToken,
    Expression<String>? labelFilter,
    Expression<bool>? syncEnabled,
    Expression<bool>? syncClosedIssues,
    Expression<int>? syncIntervalMinutes,
    Expression<String>? labelMappings,
    Expression<String>? statusMappings,
    Expression<String>? milestoneMappings,
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
      if (owner != null) 'owner': owner,
      if (repo != null) 'repo': repo,
      if (accessToken != null) 'access_token': accessToken,
      if (labelFilter != null) 'label_filter': labelFilter,
      if (syncEnabled != null) 'sync_enabled': syncEnabled,
      if (syncClosedIssues != null) 'sync_closed_issues': syncClosedIssues,
      if (syncIntervalMinutes != null)
        'sync_interval_minutes': syncIntervalMinutes,
      if (labelMappings != null) 'label_mappings': labelMappings,
      if (statusMappings != null) 'status_mappings': statusMappings,
      if (milestoneMappings != null) 'milestone_mappings': milestoneMappings,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (created != null) 'created': created,
      if (modified != null) 'modified': modified,
      if (crdtClock != null) 'crdt_clock': crdtClock,
      if (crdtState != null) 'crdt_state': crdtState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GithubIntegrationsCompanion copyWith({
    Value<String>? id,
    Value<String?>? projectId,
    Value<String>? owner,
    Value<String>? repo,
    Value<String>? accessToken,
    Value<String?>? labelFilter,
    Value<bool>? syncEnabled,
    Value<bool>? syncClosedIssues,
    Value<int>? syncIntervalMinutes,
    Value<String>? labelMappings,
    Value<String>? statusMappings,
    Value<String>? milestoneMappings,
    Value<int?>? lastSyncAt,
    Value<String?>? lastSyncError,
    Value<int>? created,
    Value<int?>? modified,
    Value<String>? crdtClock,
    Value<String>? crdtState,
    Value<int>? rowid,
  }) {
    return GithubIntegrationsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      owner: owner ?? this.owner,
      repo: repo ?? this.repo,
      accessToken: accessToken ?? this.accessToken,
      labelFilter: labelFilter ?? this.labelFilter,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      syncClosedIssues: syncClosedIssues ?? this.syncClosedIssues,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      labelMappings: labelMappings ?? this.labelMappings,
      statusMappings: statusMappings ?? this.statusMappings,
      milestoneMappings: milestoneMappings ?? this.milestoneMappings,
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
    if (owner.present) {
      map['owner'] = Variable<String>(owner.value);
    }
    if (repo.present) {
      map['repo'] = Variable<String>(repo.value);
    }
    if (accessToken.present) {
      map['access_token'] = Variable<String>(accessToken.value);
    }
    if (labelFilter.present) {
      map['label_filter'] = Variable<String>(labelFilter.value);
    }
    if (syncEnabled.present) {
      map['sync_enabled'] = Variable<bool>(syncEnabled.value);
    }
    if (syncClosedIssues.present) {
      map['sync_closed_issues'] = Variable<bool>(syncClosedIssues.value);
    }
    if (syncIntervalMinutes.present) {
      map['sync_interval_minutes'] = Variable<int>(syncIntervalMinutes.value);
    }
    if (labelMappings.present) {
      map['label_mappings'] = Variable<String>(labelMappings.value);
    }
    if (statusMappings.present) {
      map['status_mappings'] = Variable<String>(statusMappings.value);
    }
    if (milestoneMappings.present) {
      map['milestone_mappings'] = Variable<String>(milestoneMappings.value);
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
    return (StringBuffer('GithubIntegrationsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('owner: $owner, ')
          ..write('repo: $repo, ')
          ..write('accessToken: $accessToken, ')
          ..write('labelFilter: $labelFilter, ')
          ..write('syncEnabled: $syncEnabled, ')
          ..write('syncClosedIssues: $syncClosedIssues, ')
          ..write('syncIntervalMinutes: $syncIntervalMinutes, ')
          ..write('labelMappings: $labelMappings, ')
          ..write('statusMappings: $statusMappings, ')
          ..write('milestoneMappings: $milestoneMappings, ')
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

class $IssueLinksTable extends IssueLinks
    with TableInfo<$IssueLinksTable, IssueLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IssueLinksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _integrationIdMeta = const VerificationMeta(
    'integrationId',
  );
  @override
  late final GeneratedColumn<String> integrationId = GeneratedColumn<String>(
    'integration_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issueTypeMeta = const VerificationMeta(
    'issueType',
  );
  @override
  late final GeneratedColumn<String> issueType = GeneratedColumn<String>(
    'issue_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIssueIdMeta = const VerificationMeta(
    'externalIssueId',
  );
  @override
  late final GeneratedColumn<String> externalIssueId = GeneratedColumn<String>(
    'external_issue_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIssueKeyMeta = const VerificationMeta(
    'externalIssueKey',
  );
  @override
  late final GeneratedColumn<String> externalIssueKey = GeneratedColumn<String>(
    'external_issue_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIssueUrlMeta = const VerificationMeta(
    'externalIssueUrl',
  );
  @override
  late final GeneratedColumn<String> externalIssueUrl = GeneratedColumn<String>(
    'external_issue_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalTitleMeta = const VerificationMeta(
    'externalTitle',
  );
  @override
  late final GeneratedColumn<String> externalTitle = GeneratedColumn<String>(
    'external_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalStatusMeta = const VerificationMeta(
    'externalStatus',
  );
  @override
  late final GeneratedColumn<String> externalStatus = GeneratedColumn<String>(
    'external_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalPriorityMeta = const VerificationMeta(
    'externalPriority',
  );
  @override
  late final GeneratedColumn<String> externalPriority = GeneratedColumn<String>(
    'external_priority',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalAssigneeMeta = const VerificationMeta(
    'externalAssignee',
  );
  @override
  late final GeneratedColumn<String> externalAssignee = GeneratedColumn<String>(
    'external_assignee',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalUpdatedAtMeta = const VerificationMeta(
    'externalUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> externalUpdatedAt = GeneratedColumn<int>(
    'external_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasConflictMeta = const VerificationMeta(
    'hasConflict',
  );
  @override
  late final GeneratedColumn<bool> hasConflict = GeneratedColumn<bool>(
    'has_conflict',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_conflict" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _conflictDataMeta = const VerificationMeta(
    'conflictData',
  );
  @override
  late final GeneratedColumn<String> conflictData = GeneratedColumn<String>(
    'conflict_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pullChangesMeta = const VerificationMeta(
    'pullChanges',
  );
  @override
  late final GeneratedColumn<bool> pullChanges = GeneratedColumn<bool>(
    'pull_changes',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pull_changes" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pushChangesMeta = const VerificationMeta(
    'pushChanges',
  );
  @override
  late final GeneratedColumn<bool> pushChanges = GeneratedColumn<bool>(
    'push_changes',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("push_changes" IN (0, 1))',
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
    integrationId,
    issueType,
    externalIssueId,
    externalIssueKey,
    externalIssueUrl,
    externalTitle,
    externalStatus,
    externalPriority,
    externalAssignee,
    externalUpdatedAt,
    lastSyncedAt,
    hasConflict,
    conflictData,
    pullChanges,
    pushChanges,
    created,
    modified,
    crdtClock,
    crdtState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'issue_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<IssueLink> instance, {
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
    if (data.containsKey('integration_id')) {
      context.handle(
        _integrationIdMeta,
        integrationId.isAcceptableOrUnknown(
          data['integration_id']!,
          _integrationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_integrationIdMeta);
    }
    if (data.containsKey('issue_type')) {
      context.handle(
        _issueTypeMeta,
        issueType.isAcceptableOrUnknown(data['issue_type']!, _issueTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_issueTypeMeta);
    }
    if (data.containsKey('external_issue_id')) {
      context.handle(
        _externalIssueIdMeta,
        externalIssueId.isAcceptableOrUnknown(
          data['external_issue_id']!,
          _externalIssueIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_externalIssueIdMeta);
    }
    if (data.containsKey('external_issue_key')) {
      context.handle(
        _externalIssueKeyMeta,
        externalIssueKey.isAcceptableOrUnknown(
          data['external_issue_key']!,
          _externalIssueKeyMeta,
        ),
      );
    }
    if (data.containsKey('external_issue_url')) {
      context.handle(
        _externalIssueUrlMeta,
        externalIssueUrl.isAcceptableOrUnknown(
          data['external_issue_url']!,
          _externalIssueUrlMeta,
        ),
      );
    }
    if (data.containsKey('external_title')) {
      context.handle(
        _externalTitleMeta,
        externalTitle.isAcceptableOrUnknown(
          data['external_title']!,
          _externalTitleMeta,
        ),
      );
    }
    if (data.containsKey('external_status')) {
      context.handle(
        _externalStatusMeta,
        externalStatus.isAcceptableOrUnknown(
          data['external_status']!,
          _externalStatusMeta,
        ),
      );
    }
    if (data.containsKey('external_priority')) {
      context.handle(
        _externalPriorityMeta,
        externalPriority.isAcceptableOrUnknown(
          data['external_priority']!,
          _externalPriorityMeta,
        ),
      );
    }
    if (data.containsKey('external_assignee')) {
      context.handle(
        _externalAssigneeMeta,
        externalAssignee.isAcceptableOrUnknown(
          data['external_assignee']!,
          _externalAssigneeMeta,
        ),
      );
    }
    if (data.containsKey('external_updated_at')) {
      context.handle(
        _externalUpdatedAtMeta,
        externalUpdatedAt.isAcceptableOrUnknown(
          data['external_updated_at']!,
          _externalUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('has_conflict')) {
      context.handle(
        _hasConflictMeta,
        hasConflict.isAcceptableOrUnknown(
          data['has_conflict']!,
          _hasConflictMeta,
        ),
      );
    }
    if (data.containsKey('conflict_data')) {
      context.handle(
        _conflictDataMeta,
        conflictData.isAcceptableOrUnknown(
          data['conflict_data']!,
          _conflictDataMeta,
        ),
      );
    }
    if (data.containsKey('pull_changes')) {
      context.handle(
        _pullChangesMeta,
        pullChanges.isAcceptableOrUnknown(
          data['pull_changes']!,
          _pullChangesMeta,
        ),
      );
    }
    if (data.containsKey('push_changes')) {
      context.handle(
        _pushChangesMeta,
        pushChanges.isAcceptableOrUnknown(
          data['push_changes']!,
          _pushChangesMeta,
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
  IssueLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IssueLink(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      integrationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}integration_id'],
      )!,
      issueType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_type'],
      )!,
      externalIssueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_issue_id'],
      )!,
      externalIssueKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_issue_key'],
      ),
      externalIssueUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_issue_url'],
      ),
      externalTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_title'],
      ),
      externalStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_status'],
      ),
      externalPriority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_priority'],
      ),
      externalAssignee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_assignee'],
      ),
      externalUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}external_updated_at'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      ),
      hasConflict: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_conflict'],
      )!,
      conflictData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflict_data'],
      ),
      pullChanges: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pull_changes'],
      )!,
      pushChanges: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}push_changes'],
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
  $IssueLinksTable createAlias(String alias) {
    return $IssueLinksTable(attachedDatabase, alias);
  }
}

class IssueLink extends DataClass implements Insertable<IssueLink> {
  final String id;
  final String taskId;
  final String integrationId;
  final String issueType;
  final String externalIssueId;
  final String? externalIssueKey;
  final String? externalIssueUrl;
  final String? externalTitle;
  final String? externalStatus;
  final String? externalPriority;
  final String? externalAssignee;
  final int? externalUpdatedAt;
  final int? lastSyncedAt;
  final bool hasConflict;
  final String? conflictData;
  final bool pullChanges;
  final bool pushChanges;
  final int created;
  final int? modified;
  final String crdtClock;
  final String crdtState;
  const IssueLink({
    required this.id,
    required this.taskId,
    required this.integrationId,
    required this.issueType,
    required this.externalIssueId,
    this.externalIssueKey,
    this.externalIssueUrl,
    this.externalTitle,
    this.externalStatus,
    this.externalPriority,
    this.externalAssignee,
    this.externalUpdatedAt,
    this.lastSyncedAt,
    required this.hasConflict,
    this.conflictData,
    required this.pullChanges,
    required this.pushChanges,
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
    map['integration_id'] = Variable<String>(integrationId);
    map['issue_type'] = Variable<String>(issueType);
    map['external_issue_id'] = Variable<String>(externalIssueId);
    if (!nullToAbsent || externalIssueKey != null) {
      map['external_issue_key'] = Variable<String>(externalIssueKey);
    }
    if (!nullToAbsent || externalIssueUrl != null) {
      map['external_issue_url'] = Variable<String>(externalIssueUrl);
    }
    if (!nullToAbsent || externalTitle != null) {
      map['external_title'] = Variable<String>(externalTitle);
    }
    if (!nullToAbsent || externalStatus != null) {
      map['external_status'] = Variable<String>(externalStatus);
    }
    if (!nullToAbsent || externalPriority != null) {
      map['external_priority'] = Variable<String>(externalPriority);
    }
    if (!nullToAbsent || externalAssignee != null) {
      map['external_assignee'] = Variable<String>(externalAssignee);
    }
    if (!nullToAbsent || externalUpdatedAt != null) {
      map['external_updated_at'] = Variable<int>(externalUpdatedAt);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt);
    }
    map['has_conflict'] = Variable<bool>(hasConflict);
    if (!nullToAbsent || conflictData != null) {
      map['conflict_data'] = Variable<String>(conflictData);
    }
    map['pull_changes'] = Variable<bool>(pullChanges);
    map['push_changes'] = Variable<bool>(pushChanges);
    map['created'] = Variable<int>(created);
    if (!nullToAbsent || modified != null) {
      map['modified'] = Variable<int>(modified);
    }
    map['crdt_clock'] = Variable<String>(crdtClock);
    map['crdt_state'] = Variable<String>(crdtState);
    return map;
  }

  IssueLinksCompanion toCompanion(bool nullToAbsent) {
    return IssueLinksCompanion(
      id: Value(id),
      taskId: Value(taskId),
      integrationId: Value(integrationId),
      issueType: Value(issueType),
      externalIssueId: Value(externalIssueId),
      externalIssueKey: externalIssueKey == null && nullToAbsent
          ? const Value.absent()
          : Value(externalIssueKey),
      externalIssueUrl: externalIssueUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(externalIssueUrl),
      externalTitle: externalTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(externalTitle),
      externalStatus: externalStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(externalStatus),
      externalPriority: externalPriority == null && nullToAbsent
          ? const Value.absent()
          : Value(externalPriority),
      externalAssignee: externalAssignee == null && nullToAbsent
          ? const Value.absent()
          : Value(externalAssignee),
      externalUpdatedAt: externalUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(externalUpdatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      hasConflict: Value(hasConflict),
      conflictData: conflictData == null && nullToAbsent
          ? const Value.absent()
          : Value(conflictData),
      pullChanges: Value(pullChanges),
      pushChanges: Value(pushChanges),
      created: Value(created),
      modified: modified == null && nullToAbsent
          ? const Value.absent()
          : Value(modified),
      crdtClock: Value(crdtClock),
      crdtState: Value(crdtState),
    );
  }

  factory IssueLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IssueLink(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      integrationId: serializer.fromJson<String>(json['integrationId']),
      issueType: serializer.fromJson<String>(json['issueType']),
      externalIssueId: serializer.fromJson<String>(json['externalIssueId']),
      externalIssueKey: serializer.fromJson<String?>(json['externalIssueKey']),
      externalIssueUrl: serializer.fromJson<String?>(json['externalIssueUrl']),
      externalTitle: serializer.fromJson<String?>(json['externalTitle']),
      externalStatus: serializer.fromJson<String?>(json['externalStatus']),
      externalPriority: serializer.fromJson<String?>(json['externalPriority']),
      externalAssignee: serializer.fromJson<String?>(json['externalAssignee']),
      externalUpdatedAt: serializer.fromJson<int?>(json['externalUpdatedAt']),
      lastSyncedAt: serializer.fromJson<int?>(json['lastSyncedAt']),
      hasConflict: serializer.fromJson<bool>(json['hasConflict']),
      conflictData: serializer.fromJson<String?>(json['conflictData']),
      pullChanges: serializer.fromJson<bool>(json['pullChanges']),
      pushChanges: serializer.fromJson<bool>(json['pushChanges']),
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
      'integrationId': serializer.toJson<String>(integrationId),
      'issueType': serializer.toJson<String>(issueType),
      'externalIssueId': serializer.toJson<String>(externalIssueId),
      'externalIssueKey': serializer.toJson<String?>(externalIssueKey),
      'externalIssueUrl': serializer.toJson<String?>(externalIssueUrl),
      'externalTitle': serializer.toJson<String?>(externalTitle),
      'externalStatus': serializer.toJson<String?>(externalStatus),
      'externalPriority': serializer.toJson<String?>(externalPriority),
      'externalAssignee': serializer.toJson<String?>(externalAssignee),
      'externalUpdatedAt': serializer.toJson<int?>(externalUpdatedAt),
      'lastSyncedAt': serializer.toJson<int?>(lastSyncedAt),
      'hasConflict': serializer.toJson<bool>(hasConflict),
      'conflictData': serializer.toJson<String?>(conflictData),
      'pullChanges': serializer.toJson<bool>(pullChanges),
      'pushChanges': serializer.toJson<bool>(pushChanges),
      'created': serializer.toJson<int>(created),
      'modified': serializer.toJson<int?>(modified),
      'crdtClock': serializer.toJson<String>(crdtClock),
      'crdtState': serializer.toJson<String>(crdtState),
    };
  }

  IssueLink copyWith({
    String? id,
    String? taskId,
    String? integrationId,
    String? issueType,
    String? externalIssueId,
    Value<String?> externalIssueKey = const Value.absent(),
    Value<String?> externalIssueUrl = const Value.absent(),
    Value<String?> externalTitle = const Value.absent(),
    Value<String?> externalStatus = const Value.absent(),
    Value<String?> externalPriority = const Value.absent(),
    Value<String?> externalAssignee = const Value.absent(),
    Value<int?> externalUpdatedAt = const Value.absent(),
    Value<int?> lastSyncedAt = const Value.absent(),
    bool? hasConflict,
    Value<String?> conflictData = const Value.absent(),
    bool? pullChanges,
    bool? pushChanges,
    int? created,
    Value<int?> modified = const Value.absent(),
    String? crdtClock,
    String? crdtState,
  }) => IssueLink(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    integrationId: integrationId ?? this.integrationId,
    issueType: issueType ?? this.issueType,
    externalIssueId: externalIssueId ?? this.externalIssueId,
    externalIssueKey: externalIssueKey.present
        ? externalIssueKey.value
        : this.externalIssueKey,
    externalIssueUrl: externalIssueUrl.present
        ? externalIssueUrl.value
        : this.externalIssueUrl,
    externalTitle: externalTitle.present
        ? externalTitle.value
        : this.externalTitle,
    externalStatus: externalStatus.present
        ? externalStatus.value
        : this.externalStatus,
    externalPriority: externalPriority.present
        ? externalPriority.value
        : this.externalPriority,
    externalAssignee: externalAssignee.present
        ? externalAssignee.value
        : this.externalAssignee,
    externalUpdatedAt: externalUpdatedAt.present
        ? externalUpdatedAt.value
        : this.externalUpdatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    hasConflict: hasConflict ?? this.hasConflict,
    conflictData: conflictData.present ? conflictData.value : this.conflictData,
    pullChanges: pullChanges ?? this.pullChanges,
    pushChanges: pushChanges ?? this.pushChanges,
    created: created ?? this.created,
    modified: modified.present ? modified.value : this.modified,
    crdtClock: crdtClock ?? this.crdtClock,
    crdtState: crdtState ?? this.crdtState,
  );
  IssueLink copyWithCompanion(IssueLinksCompanion data) {
    return IssueLink(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      integrationId: data.integrationId.present
          ? data.integrationId.value
          : this.integrationId,
      issueType: data.issueType.present ? data.issueType.value : this.issueType,
      externalIssueId: data.externalIssueId.present
          ? data.externalIssueId.value
          : this.externalIssueId,
      externalIssueKey: data.externalIssueKey.present
          ? data.externalIssueKey.value
          : this.externalIssueKey,
      externalIssueUrl: data.externalIssueUrl.present
          ? data.externalIssueUrl.value
          : this.externalIssueUrl,
      externalTitle: data.externalTitle.present
          ? data.externalTitle.value
          : this.externalTitle,
      externalStatus: data.externalStatus.present
          ? data.externalStatus.value
          : this.externalStatus,
      externalPriority: data.externalPriority.present
          ? data.externalPriority.value
          : this.externalPriority,
      externalAssignee: data.externalAssignee.present
          ? data.externalAssignee.value
          : this.externalAssignee,
      externalUpdatedAt: data.externalUpdatedAt.present
          ? data.externalUpdatedAt.value
          : this.externalUpdatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      hasConflict: data.hasConflict.present
          ? data.hasConflict.value
          : this.hasConflict,
      conflictData: data.conflictData.present
          ? data.conflictData.value
          : this.conflictData,
      pullChanges: data.pullChanges.present
          ? data.pullChanges.value
          : this.pullChanges,
      pushChanges: data.pushChanges.present
          ? data.pushChanges.value
          : this.pushChanges,
      created: data.created.present ? data.created.value : this.created,
      modified: data.modified.present ? data.modified.value : this.modified,
      crdtClock: data.crdtClock.present ? data.crdtClock.value : this.crdtClock,
      crdtState: data.crdtState.present ? data.crdtState.value : this.crdtState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IssueLink(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('integrationId: $integrationId, ')
          ..write('issueType: $issueType, ')
          ..write('externalIssueId: $externalIssueId, ')
          ..write('externalIssueKey: $externalIssueKey, ')
          ..write('externalIssueUrl: $externalIssueUrl, ')
          ..write('externalTitle: $externalTitle, ')
          ..write('externalStatus: $externalStatus, ')
          ..write('externalPriority: $externalPriority, ')
          ..write('externalAssignee: $externalAssignee, ')
          ..write('externalUpdatedAt: $externalUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('hasConflict: $hasConflict, ')
          ..write('conflictData: $conflictData, ')
          ..write('pullChanges: $pullChanges, ')
          ..write('pushChanges: $pushChanges, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
          ..write('crdtClock: $crdtClock, ')
          ..write('crdtState: $crdtState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    taskId,
    integrationId,
    issueType,
    externalIssueId,
    externalIssueKey,
    externalIssueUrl,
    externalTitle,
    externalStatus,
    externalPriority,
    externalAssignee,
    externalUpdatedAt,
    lastSyncedAt,
    hasConflict,
    conflictData,
    pullChanges,
    pushChanges,
    created,
    modified,
    crdtClock,
    crdtState,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IssueLink &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.integrationId == this.integrationId &&
          other.issueType == this.issueType &&
          other.externalIssueId == this.externalIssueId &&
          other.externalIssueKey == this.externalIssueKey &&
          other.externalIssueUrl == this.externalIssueUrl &&
          other.externalTitle == this.externalTitle &&
          other.externalStatus == this.externalStatus &&
          other.externalPriority == this.externalPriority &&
          other.externalAssignee == this.externalAssignee &&
          other.externalUpdatedAt == this.externalUpdatedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.hasConflict == this.hasConflict &&
          other.conflictData == this.conflictData &&
          other.pullChanges == this.pullChanges &&
          other.pushChanges == this.pushChanges &&
          other.created == this.created &&
          other.modified == this.modified &&
          other.crdtClock == this.crdtClock &&
          other.crdtState == this.crdtState);
}

class IssueLinksCompanion extends UpdateCompanion<IssueLink> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> integrationId;
  final Value<String> issueType;
  final Value<String> externalIssueId;
  final Value<String?> externalIssueKey;
  final Value<String?> externalIssueUrl;
  final Value<String?> externalTitle;
  final Value<String?> externalStatus;
  final Value<String?> externalPriority;
  final Value<String?> externalAssignee;
  final Value<int?> externalUpdatedAt;
  final Value<int?> lastSyncedAt;
  final Value<bool> hasConflict;
  final Value<String?> conflictData;
  final Value<bool> pullChanges;
  final Value<bool> pushChanges;
  final Value<int> created;
  final Value<int?> modified;
  final Value<String> crdtClock;
  final Value<String> crdtState;
  final Value<int> rowid;
  const IssueLinksCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.integrationId = const Value.absent(),
    this.issueType = const Value.absent(),
    this.externalIssueId = const Value.absent(),
    this.externalIssueKey = const Value.absent(),
    this.externalIssueUrl = const Value.absent(),
    this.externalTitle = const Value.absent(),
    this.externalStatus = const Value.absent(),
    this.externalPriority = const Value.absent(),
    this.externalAssignee = const Value.absent(),
    this.externalUpdatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.hasConflict = const Value.absent(),
    this.conflictData = const Value.absent(),
    this.pullChanges = const Value.absent(),
    this.pushChanges = const Value.absent(),
    this.created = const Value.absent(),
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IssueLinksCompanion.insert({
    required String id,
    required String taskId,
    required String integrationId,
    required String issueType,
    required String externalIssueId,
    this.externalIssueKey = const Value.absent(),
    this.externalIssueUrl = const Value.absent(),
    this.externalTitle = const Value.absent(),
    this.externalStatus = const Value.absent(),
    this.externalPriority = const Value.absent(),
    this.externalAssignee = const Value.absent(),
    this.externalUpdatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.hasConflict = const Value.absent(),
    this.conflictData = const Value.absent(),
    this.pullChanges = const Value.absent(),
    this.pushChanges = const Value.absent(),
    required int created,
    this.modified = const Value.absent(),
    this.crdtClock = const Value.absent(),
    this.crdtState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       integrationId = Value(integrationId),
       issueType = Value(issueType),
       externalIssueId = Value(externalIssueId),
       created = Value(created);
  static Insertable<IssueLink> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? integrationId,
    Expression<String>? issueType,
    Expression<String>? externalIssueId,
    Expression<String>? externalIssueKey,
    Expression<String>? externalIssueUrl,
    Expression<String>? externalTitle,
    Expression<String>? externalStatus,
    Expression<String>? externalPriority,
    Expression<String>? externalAssignee,
    Expression<int>? externalUpdatedAt,
    Expression<int>? lastSyncedAt,
    Expression<bool>? hasConflict,
    Expression<String>? conflictData,
    Expression<bool>? pullChanges,
    Expression<bool>? pushChanges,
    Expression<int>? created,
    Expression<int>? modified,
    Expression<String>? crdtClock,
    Expression<String>? crdtState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (integrationId != null) 'integration_id': integrationId,
      if (issueType != null) 'issue_type': issueType,
      if (externalIssueId != null) 'external_issue_id': externalIssueId,
      if (externalIssueKey != null) 'external_issue_key': externalIssueKey,
      if (externalIssueUrl != null) 'external_issue_url': externalIssueUrl,
      if (externalTitle != null) 'external_title': externalTitle,
      if (externalStatus != null) 'external_status': externalStatus,
      if (externalPriority != null) 'external_priority': externalPriority,
      if (externalAssignee != null) 'external_assignee': externalAssignee,
      if (externalUpdatedAt != null) 'external_updated_at': externalUpdatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (hasConflict != null) 'has_conflict': hasConflict,
      if (conflictData != null) 'conflict_data': conflictData,
      if (pullChanges != null) 'pull_changes': pullChanges,
      if (pushChanges != null) 'push_changes': pushChanges,
      if (created != null) 'created': created,
      if (modified != null) 'modified': modified,
      if (crdtClock != null) 'crdt_clock': crdtClock,
      if (crdtState != null) 'crdt_state': crdtState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IssueLinksCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? integrationId,
    Value<String>? issueType,
    Value<String>? externalIssueId,
    Value<String?>? externalIssueKey,
    Value<String?>? externalIssueUrl,
    Value<String?>? externalTitle,
    Value<String?>? externalStatus,
    Value<String?>? externalPriority,
    Value<String?>? externalAssignee,
    Value<int?>? externalUpdatedAt,
    Value<int?>? lastSyncedAt,
    Value<bool>? hasConflict,
    Value<String?>? conflictData,
    Value<bool>? pullChanges,
    Value<bool>? pushChanges,
    Value<int>? created,
    Value<int?>? modified,
    Value<String>? crdtClock,
    Value<String>? crdtState,
    Value<int>? rowid,
  }) {
    return IssueLinksCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      integrationId: integrationId ?? this.integrationId,
      issueType: issueType ?? this.issueType,
      externalIssueId: externalIssueId ?? this.externalIssueId,
      externalIssueKey: externalIssueKey ?? this.externalIssueKey,
      externalIssueUrl: externalIssueUrl ?? this.externalIssueUrl,
      externalTitle: externalTitle ?? this.externalTitle,
      externalStatus: externalStatus ?? this.externalStatus,
      externalPriority: externalPriority ?? this.externalPriority,
      externalAssignee: externalAssignee ?? this.externalAssignee,
      externalUpdatedAt: externalUpdatedAt ?? this.externalUpdatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      hasConflict: hasConflict ?? this.hasConflict,
      conflictData: conflictData ?? this.conflictData,
      pullChanges: pullChanges ?? this.pullChanges,
      pushChanges: pushChanges ?? this.pushChanges,
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
    if (integrationId.present) {
      map['integration_id'] = Variable<String>(integrationId.value);
    }
    if (issueType.present) {
      map['issue_type'] = Variable<String>(issueType.value);
    }
    if (externalIssueId.present) {
      map['external_issue_id'] = Variable<String>(externalIssueId.value);
    }
    if (externalIssueKey.present) {
      map['external_issue_key'] = Variable<String>(externalIssueKey.value);
    }
    if (externalIssueUrl.present) {
      map['external_issue_url'] = Variable<String>(externalIssueUrl.value);
    }
    if (externalTitle.present) {
      map['external_title'] = Variable<String>(externalTitle.value);
    }
    if (externalStatus.present) {
      map['external_status'] = Variable<String>(externalStatus.value);
    }
    if (externalPriority.present) {
      map['external_priority'] = Variable<String>(externalPriority.value);
    }
    if (externalAssignee.present) {
      map['external_assignee'] = Variable<String>(externalAssignee.value);
    }
    if (externalUpdatedAt.present) {
      map['external_updated_at'] = Variable<int>(externalUpdatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    if (hasConflict.present) {
      map['has_conflict'] = Variable<bool>(hasConflict.value);
    }
    if (conflictData.present) {
      map['conflict_data'] = Variable<String>(conflictData.value);
    }
    if (pullChanges.present) {
      map['pull_changes'] = Variable<bool>(pullChanges.value);
    }
    if (pushChanges.present) {
      map['push_changes'] = Variable<bool>(pushChanges.value);
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
    return (StringBuffer('IssueLinksCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('integrationId: $integrationId, ')
          ..write('issueType: $issueType, ')
          ..write('externalIssueId: $externalIssueId, ')
          ..write('externalIssueKey: $externalIssueKey, ')
          ..write('externalIssueUrl: $externalIssueUrl, ')
          ..write('externalTitle: $externalTitle, ')
          ..write('externalStatus: $externalStatus, ')
          ..write('externalPriority: $externalPriority, ')
          ..write('externalAssignee: $externalAssignee, ')
          ..write('externalUpdatedAt: $externalUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('hasConflict: $hasConflict, ')
          ..write('conflictData: $conflictData, ')
          ..write('pullChanges: $pullChanges, ')
          ..write('pushChanges: $pushChanges, ')
          ..write('created: $created, ')
          ..write('modified: $modified, ')
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
  late final $NotesTable notes = $NotesTable(this);
  late final $TaskRepeatCfgsTable taskRepeatCfgs = $TaskRepeatCfgsTable(this);
  late final $JiraIntegrationsTable jiraIntegrations = $JiraIntegrationsTable(
    this,
  );
  late final $GithubIntegrationsTable githubIntegrations =
      $GithubIntegrationsTable(this);
  late final $IssueLinksTable issueLinks = $IssueLinksTable(this);
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
    notes,
    taskRepeatCfgs,
    jiraIntegrations,
    githubIntegrations,
    issueLinks,
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
      Value<String> noteIds,
      Value<String> theme,
      Value<String> advancedCfg,
      Value<String?> icon,
      Value<String> issueIntegrationCfgs,
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
      Value<String> noteIds,
      Value<String> theme,
      Value<String> advancedCfg,
      Value<String?> icon,
      Value<String> issueIntegrationCfgs,
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

  ColumnFilters<String> get noteIds => $composableBuilder(
    column: $table.noteIds,
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

  ColumnFilters<String> get issueIntegrationCfgs => $composableBuilder(
    column: $table.issueIntegrationCfgs,
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

  ColumnOrderings<String> get noteIds => $composableBuilder(
    column: $table.noteIds,
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

  ColumnOrderings<String> get issueIntegrationCfgs => $composableBuilder(
    column: $table.issueIntegrationCfgs,
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

  GeneratedColumn<String> get noteIds =>
      $composableBuilder(column: $table.noteIds, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<String> get advancedCfg => $composableBuilder(
    column: $table.advancedCfg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get issueIntegrationCfgs => $composableBuilder(
    column: $table.issueIntegrationCfgs,
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
                Value<String> noteIds = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> advancedCfg = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String> issueIntegrationCfgs = const Value.absent(),
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
                noteIds: noteIds,
                theme: theme,
                advancedCfg: advancedCfg,
                icon: icon,
                issueIntegrationCfgs: issueIntegrationCfgs,
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
                Value<String> noteIds = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> advancedCfg = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String> issueIntegrationCfgs = const Value.absent(),
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
                noteIds: noteIds,
                theme: theme,
                advancedCfg: advancedCfg,
                icon: icon,
                issueIntegrationCfgs: issueIntegrationCfgs,
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
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      required String id,
      Value<String?> projectId,
      required String content,
      Value<String?> imgUrl,
      Value<String?> backgroundColor,
      Value<bool> isPinnedToToday,
      Value<bool> isLock,
      required int created,
      required int modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      Value<String?> projectId,
      Value<String> content,
      Value<String?> imgUrl,
      Value<String?> backgroundColor,
      Value<bool> isPinnedToToday,
      Value<bool> isLock,
      Value<int> created,
      Value<int> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
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

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imgUrl => $composableBuilder(
    column: $table.imgUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinnedToToday => $composableBuilder(
    column: $table.isPinnedToToday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLock => $composableBuilder(
    column: $table.isLock,
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

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
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

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imgUrl => $composableBuilder(
    column: $table.imgUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinnedToToday => $composableBuilder(
    column: $table.isPinnedToToday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLock => $composableBuilder(
    column: $table.isLock,
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

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
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

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get imgUrl =>
      $composableBuilder(column: $table.imgUrl, builder: (column) => column);

  GeneratedColumn<String> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinnedToToday => $composableBuilder(
    column: $table.isPinnedToToday,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLock =>
      $composableBuilder(column: $table.isLock, builder: (column) => column);

  GeneratedColumn<int> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<int> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<String> get crdtClock =>
      $composableBuilder(column: $table.crdtClock, builder: (column) => column);

  GeneratedColumn<String> get crdtState =>
      $composableBuilder(column: $table.crdtState, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> imgUrl = const Value.absent(),
                Value<String?> backgroundColor = const Value.absent(),
                Value<bool> isPinnedToToday = const Value.absent(),
                Value<bool> isLock = const Value.absent(),
                Value<int> created = const Value.absent(),
                Value<int> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                projectId: projectId,
                content: content,
                imgUrl: imgUrl,
                backgroundColor: backgroundColor,
                isPinnedToToday: isPinnedToToday,
                isLock: isLock,
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
                required String content,
                Value<String?> imgUrl = const Value.absent(),
                Value<String?> backgroundColor = const Value.absent(),
                Value<bool> isPinnedToToday = const Value.absent(),
                Value<bool> isLock = const Value.absent(),
                required int created,
                required int modified,
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                projectId: projectId,
                content: content,
                imgUrl: imgUrl,
                backgroundColor: backgroundColor,
                isPinnedToToday: isPinnedToToday,
                isLock: isLock,
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

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$TaskRepeatCfgsTableCreateCompanionBuilder =
    TaskRepeatCfgsCompanion Function({
      required String id,
      Value<String?> projectId,
      Value<String?> title,
      Value<String> tagIds,
      Value<int> order,
      Value<int?> defaultEstimate,
      Value<String?> startTime,
      Value<String?> remindAt,
      Value<bool> isPaused,
      required String quickSetting,
      required String repeatCycle,
      Value<String?> startDate,
      Value<int> repeatEvery,
      Value<bool> monday,
      Value<bool> tuesday,
      Value<bool> wednesday,
      Value<bool> thursday,
      Value<bool> friday,
      Value<bool> saturday,
      Value<bool> sunday,
      Value<String?> notes,
      Value<String> subTaskTemplates,
      Value<int?> lastTaskCreation,
      Value<String?> lastTaskCreationDay,
      Value<String> deletedInstanceDates,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });
typedef $$TaskRepeatCfgsTableUpdateCompanionBuilder =
    TaskRepeatCfgsCompanion Function({
      Value<String> id,
      Value<String?> projectId,
      Value<String?> title,
      Value<String> tagIds,
      Value<int> order,
      Value<int?> defaultEstimate,
      Value<String?> startTime,
      Value<String?> remindAt,
      Value<bool> isPaused,
      Value<String> quickSetting,
      Value<String> repeatCycle,
      Value<String?> startDate,
      Value<int> repeatEvery,
      Value<bool> monday,
      Value<bool> tuesday,
      Value<bool> wednesday,
      Value<bool> thursday,
      Value<bool> friday,
      Value<bool> saturday,
      Value<bool> sunday,
      Value<String?> notes,
      Value<String> subTaskTemplates,
      Value<int?> lastTaskCreation,
      Value<String?> lastTaskCreationDay,
      Value<String> deletedInstanceDates,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });

class $$TaskRepeatCfgsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskRepeatCfgsTable> {
  $$TaskRepeatCfgsTableFilterComposer({
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

  ColumnFilters<String> get tagIds => $composableBuilder(
    column: $table.tagIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultEstimate => $composableBuilder(
    column: $table.defaultEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaused => $composableBuilder(
    column: $table.isPaused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quickSetting => $composableBuilder(
    column: $table.quickSetting,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatCycle => $composableBuilder(
    column: $table.repeatCycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repeatEvery => $composableBuilder(
    column: $table.repeatEvery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get monday => $composableBuilder(
    column: $table.monday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tuesday => $composableBuilder(
    column: $table.tuesday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wednesday => $composableBuilder(
    column: $table.wednesday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get thursday => $composableBuilder(
    column: $table.thursday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get friday => $composableBuilder(
    column: $table.friday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get saturday => $composableBuilder(
    column: $table.saturday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sunday => $composableBuilder(
    column: $table.sunday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subTaskTemplates => $composableBuilder(
    column: $table.subTaskTemplates,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastTaskCreation => $composableBuilder(
    column: $table.lastTaskCreation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastTaskCreationDay => $composableBuilder(
    column: $table.lastTaskCreationDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedInstanceDates => $composableBuilder(
    column: $table.deletedInstanceDates,
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

class $$TaskRepeatCfgsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskRepeatCfgsTable> {
  $$TaskRepeatCfgsTableOrderingComposer({
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

  ColumnOrderings<String> get tagIds => $composableBuilder(
    column: $table.tagIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultEstimate => $composableBuilder(
    column: $table.defaultEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaused => $composableBuilder(
    column: $table.isPaused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quickSetting => $composableBuilder(
    column: $table.quickSetting,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatCycle => $composableBuilder(
    column: $table.repeatCycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatEvery => $composableBuilder(
    column: $table.repeatEvery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get monday => $composableBuilder(
    column: $table.monday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tuesday => $composableBuilder(
    column: $table.tuesday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wednesday => $composableBuilder(
    column: $table.wednesday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get thursday => $composableBuilder(
    column: $table.thursday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get friday => $composableBuilder(
    column: $table.friday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get saturday => $composableBuilder(
    column: $table.saturday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sunday => $composableBuilder(
    column: $table.sunday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subTaskTemplates => $composableBuilder(
    column: $table.subTaskTemplates,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastTaskCreation => $composableBuilder(
    column: $table.lastTaskCreation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastTaskCreationDay => $composableBuilder(
    column: $table.lastTaskCreationDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedInstanceDates => $composableBuilder(
    column: $table.deletedInstanceDates,
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

class $$TaskRepeatCfgsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskRepeatCfgsTable> {
  $$TaskRepeatCfgsTableAnnotationComposer({
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

  GeneratedColumn<String> get tagIds =>
      $composableBuilder(column: $table.tagIds, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<int> get defaultEstimate => $composableBuilder(
    column: $table.defaultEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  GeneratedColumn<bool> get isPaused =>
      $composableBuilder(column: $table.isPaused, builder: (column) => column);

  GeneratedColumn<String> get quickSetting => $composableBuilder(
    column: $table.quickSetting,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeatCycle => $composableBuilder(
    column: $table.repeatCycle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get repeatEvery => $composableBuilder(
    column: $table.repeatEvery,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get monday =>
      $composableBuilder(column: $table.monday, builder: (column) => column);

  GeneratedColumn<bool> get tuesday =>
      $composableBuilder(column: $table.tuesday, builder: (column) => column);

  GeneratedColumn<bool> get wednesday =>
      $composableBuilder(column: $table.wednesday, builder: (column) => column);

  GeneratedColumn<bool> get thursday =>
      $composableBuilder(column: $table.thursday, builder: (column) => column);

  GeneratedColumn<bool> get friday =>
      $composableBuilder(column: $table.friday, builder: (column) => column);

  GeneratedColumn<bool> get saturday =>
      $composableBuilder(column: $table.saturday, builder: (column) => column);

  GeneratedColumn<bool> get sunday =>
      $composableBuilder(column: $table.sunday, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get subTaskTemplates => $composableBuilder(
    column: $table.subTaskTemplates,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastTaskCreation => $composableBuilder(
    column: $table.lastTaskCreation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastTaskCreationDay => $composableBuilder(
    column: $table.lastTaskCreationDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deletedInstanceDates => $composableBuilder(
    column: $table.deletedInstanceDates,
    builder: (column) => column,
  );

  GeneratedColumn<String> get crdtClock =>
      $composableBuilder(column: $table.crdtClock, builder: (column) => column);

  GeneratedColumn<String> get crdtState =>
      $composableBuilder(column: $table.crdtState, builder: (column) => column);
}

class $$TaskRepeatCfgsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRepeatCfgsTable,
          TaskRepeatCfg,
          $$TaskRepeatCfgsTableFilterComposer,
          $$TaskRepeatCfgsTableOrderingComposer,
          $$TaskRepeatCfgsTableAnnotationComposer,
          $$TaskRepeatCfgsTableCreateCompanionBuilder,
          $$TaskRepeatCfgsTableUpdateCompanionBuilder,
          (
            TaskRepeatCfg,
            BaseReferences<_$AppDatabase, $TaskRepeatCfgsTable, TaskRepeatCfg>,
          ),
          TaskRepeatCfg,
          PrefetchHooks Function()
        > {
  $$TaskRepeatCfgsTableTableManager(
    _$AppDatabase db,
    $TaskRepeatCfgsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRepeatCfgsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskRepeatCfgsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskRepeatCfgsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> tagIds = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<int?> defaultEstimate = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> remindAt = const Value.absent(),
                Value<bool> isPaused = const Value.absent(),
                Value<String> quickSetting = const Value.absent(),
                Value<String> repeatCycle = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<int> repeatEvery = const Value.absent(),
                Value<bool> monday = const Value.absent(),
                Value<bool> tuesday = const Value.absent(),
                Value<bool> wednesday = const Value.absent(),
                Value<bool> thursday = const Value.absent(),
                Value<bool> friday = const Value.absent(),
                Value<bool> saturday = const Value.absent(),
                Value<bool> sunday = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> subTaskTemplates = const Value.absent(),
                Value<int?> lastTaskCreation = const Value.absent(),
                Value<String?> lastTaskCreationDay = const Value.absent(),
                Value<String> deletedInstanceDates = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRepeatCfgsCompanion(
                id: id,
                projectId: projectId,
                title: title,
                tagIds: tagIds,
                order: order,
                defaultEstimate: defaultEstimate,
                startTime: startTime,
                remindAt: remindAt,
                isPaused: isPaused,
                quickSetting: quickSetting,
                repeatCycle: repeatCycle,
                startDate: startDate,
                repeatEvery: repeatEvery,
                monday: monday,
                tuesday: tuesday,
                wednesday: wednesday,
                thursday: thursday,
                friday: friday,
                saturday: saturday,
                sunday: sunday,
                notes: notes,
                subTaskTemplates: subTaskTemplates,
                lastTaskCreation: lastTaskCreation,
                lastTaskCreationDay: lastTaskCreationDay,
                deletedInstanceDates: deletedInstanceDates,
                crdtClock: crdtClock,
                crdtState: crdtState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> projectId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> tagIds = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<int?> defaultEstimate = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> remindAt = const Value.absent(),
                Value<bool> isPaused = const Value.absent(),
                required String quickSetting,
                required String repeatCycle,
                Value<String?> startDate = const Value.absent(),
                Value<int> repeatEvery = const Value.absent(),
                Value<bool> monday = const Value.absent(),
                Value<bool> tuesday = const Value.absent(),
                Value<bool> wednesday = const Value.absent(),
                Value<bool> thursday = const Value.absent(),
                Value<bool> friday = const Value.absent(),
                Value<bool> saturday = const Value.absent(),
                Value<bool> sunday = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> subTaskTemplates = const Value.absent(),
                Value<int?> lastTaskCreation = const Value.absent(),
                Value<String?> lastTaskCreationDay = const Value.absent(),
                Value<String> deletedInstanceDates = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRepeatCfgsCompanion.insert(
                id: id,
                projectId: projectId,
                title: title,
                tagIds: tagIds,
                order: order,
                defaultEstimate: defaultEstimate,
                startTime: startTime,
                remindAt: remindAt,
                isPaused: isPaused,
                quickSetting: quickSetting,
                repeatCycle: repeatCycle,
                startDate: startDate,
                repeatEvery: repeatEvery,
                monday: monday,
                tuesday: tuesday,
                wednesday: wednesday,
                thursday: thursday,
                friday: friday,
                saturday: saturday,
                sunday: sunday,
                notes: notes,
                subTaskTemplates: subTaskTemplates,
                lastTaskCreation: lastTaskCreation,
                lastTaskCreationDay: lastTaskCreationDay,
                deletedInstanceDates: deletedInstanceDates,
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

typedef $$TaskRepeatCfgsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRepeatCfgsTable,
      TaskRepeatCfg,
      $$TaskRepeatCfgsTableFilterComposer,
      $$TaskRepeatCfgsTableOrderingComposer,
      $$TaskRepeatCfgsTableAnnotationComposer,
      $$TaskRepeatCfgsTableCreateCompanionBuilder,
      $$TaskRepeatCfgsTableUpdateCompanionBuilder,
      (
        TaskRepeatCfg,
        BaseReferences<_$AppDatabase, $TaskRepeatCfgsTable, TaskRepeatCfg>,
      ),
      TaskRepeatCfg,
      PrefetchHooks Function()
    >;
typedef $$JiraIntegrationsTableCreateCompanionBuilder =
    JiraIntegrationsCompanion Function({
      required String id,
      Value<String?> projectId,
      required String baseUrl,
      required String email,
      required String apiToken,
      required String jiraProjectKey,
      Value<String?> boardId,
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
      Value<String> email,
      Value<String> apiToken,
      Value<String> jiraProjectKey,
      Value<String?> boardId,
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

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiToken => $composableBuilder(
    column: $table.apiToken,
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

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiToken => $composableBuilder(
    column: $table.apiToken,
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

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get apiToken =>
      $composableBuilder(column: $table.apiToken, builder: (column) => column);

  GeneratedColumn<String> get jiraProjectKey => $composableBuilder(
    column: $table.jiraProjectKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boardId =>
      $composableBuilder(column: $table.boardId, builder: (column) => column);

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
                Value<String> email = const Value.absent(),
                Value<String> apiToken = const Value.absent(),
                Value<String> jiraProjectKey = const Value.absent(),
                Value<String?> boardId = const Value.absent(),
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
                email: email,
                apiToken: apiToken,
                jiraProjectKey: jiraProjectKey,
                boardId: boardId,
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
                required String email,
                required String apiToken,
                required String jiraProjectKey,
                Value<String?> boardId = const Value.absent(),
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
                email: email,
                apiToken: apiToken,
                jiraProjectKey: jiraProjectKey,
                boardId: boardId,
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
typedef $$GithubIntegrationsTableCreateCompanionBuilder =
    GithubIntegrationsCompanion Function({
      required String id,
      Value<String?> projectId,
      required String owner,
      required String repo,
      required String accessToken,
      Value<String?> labelFilter,
      Value<bool> syncEnabled,
      Value<bool> syncClosedIssues,
      Value<int> syncIntervalMinutes,
      Value<String> labelMappings,
      Value<String> statusMappings,
      Value<String> milestoneMappings,
      Value<int?> lastSyncAt,
      Value<String?> lastSyncError,
      required int created,
      Value<int?> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });
typedef $$GithubIntegrationsTableUpdateCompanionBuilder =
    GithubIntegrationsCompanion Function({
      Value<String> id,
      Value<String?> projectId,
      Value<String> owner,
      Value<String> repo,
      Value<String> accessToken,
      Value<String?> labelFilter,
      Value<bool> syncEnabled,
      Value<bool> syncClosedIssues,
      Value<int> syncIntervalMinutes,
      Value<String> labelMappings,
      Value<String> statusMappings,
      Value<String> milestoneMappings,
      Value<int?> lastSyncAt,
      Value<String?> lastSyncError,
      Value<int> created,
      Value<int?> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });

class $$GithubIntegrationsTableFilterComposer
    extends Composer<_$AppDatabase, $GithubIntegrationsTable> {
  $$GithubIntegrationsTableFilterComposer({
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

  ColumnFilters<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repo => $composableBuilder(
    column: $table.repo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelFilter => $composableBuilder(
    column: $table.labelFilter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get syncClosedIssues => $composableBuilder(
    column: $table.syncClosedIssues,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncIntervalMinutes => $composableBuilder(
    column: $table.syncIntervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelMappings => $composableBuilder(
    column: $table.labelMappings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusMappings => $composableBuilder(
    column: $table.statusMappings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get milestoneMappings => $composableBuilder(
    column: $table.milestoneMappings,
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

class $$GithubIntegrationsTableOrderingComposer
    extends Composer<_$AppDatabase, $GithubIntegrationsTable> {
  $$GithubIntegrationsTableOrderingComposer({
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

  ColumnOrderings<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repo => $composableBuilder(
    column: $table.repo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelFilter => $composableBuilder(
    column: $table.labelFilter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get syncClosedIssues => $composableBuilder(
    column: $table.syncClosedIssues,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncIntervalMinutes => $composableBuilder(
    column: $table.syncIntervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelMappings => $composableBuilder(
    column: $table.labelMappings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusMappings => $composableBuilder(
    column: $table.statusMappings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get milestoneMappings => $composableBuilder(
    column: $table.milestoneMappings,
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

class $$GithubIntegrationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GithubIntegrationsTable> {
  $$GithubIntegrationsTableAnnotationComposer({
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

  GeneratedColumn<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => column);

  GeneratedColumn<String> get repo =>
      $composableBuilder(column: $table.repo, builder: (column) => column);

  GeneratedColumn<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get labelFilter => $composableBuilder(
    column: $table.labelFilter,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncEnabled => $composableBuilder(
    column: $table.syncEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get syncClosedIssues => $composableBuilder(
    column: $table.syncClosedIssues,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncIntervalMinutes => $composableBuilder(
    column: $table.syncIntervalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get labelMappings => $composableBuilder(
    column: $table.labelMappings,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statusMappings => $composableBuilder(
    column: $table.statusMappings,
    builder: (column) => column,
  );

  GeneratedColumn<String> get milestoneMappings => $composableBuilder(
    column: $table.milestoneMappings,
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

class $$GithubIntegrationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GithubIntegrationsTable,
          GithubIntegration,
          $$GithubIntegrationsTableFilterComposer,
          $$GithubIntegrationsTableOrderingComposer,
          $$GithubIntegrationsTableAnnotationComposer,
          $$GithubIntegrationsTableCreateCompanionBuilder,
          $$GithubIntegrationsTableUpdateCompanionBuilder,
          (
            GithubIntegration,
            BaseReferences<
              _$AppDatabase,
              $GithubIntegrationsTable,
              GithubIntegration
            >,
          ),
          GithubIntegration,
          PrefetchHooks Function()
        > {
  $$GithubIntegrationsTableTableManager(
    _$AppDatabase db,
    $GithubIntegrationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GithubIntegrationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GithubIntegrationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GithubIntegrationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String> owner = const Value.absent(),
                Value<String> repo = const Value.absent(),
                Value<String> accessToken = const Value.absent(),
                Value<String?> labelFilter = const Value.absent(),
                Value<bool> syncEnabled = const Value.absent(),
                Value<bool> syncClosedIssues = const Value.absent(),
                Value<int> syncIntervalMinutes = const Value.absent(),
                Value<String> labelMappings = const Value.absent(),
                Value<String> statusMappings = const Value.absent(),
                Value<String> milestoneMappings = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<int> created = const Value.absent(),
                Value<int?> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GithubIntegrationsCompanion(
                id: id,
                projectId: projectId,
                owner: owner,
                repo: repo,
                accessToken: accessToken,
                labelFilter: labelFilter,
                syncEnabled: syncEnabled,
                syncClosedIssues: syncClosedIssues,
                syncIntervalMinutes: syncIntervalMinutes,
                labelMappings: labelMappings,
                statusMappings: statusMappings,
                milestoneMappings: milestoneMappings,
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
                required String owner,
                required String repo,
                required String accessToken,
                Value<String?> labelFilter = const Value.absent(),
                Value<bool> syncEnabled = const Value.absent(),
                Value<bool> syncClosedIssues = const Value.absent(),
                Value<int> syncIntervalMinutes = const Value.absent(),
                Value<String> labelMappings = const Value.absent(),
                Value<String> statusMappings = const Value.absent(),
                Value<String> milestoneMappings = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                required int created,
                Value<int?> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GithubIntegrationsCompanion.insert(
                id: id,
                projectId: projectId,
                owner: owner,
                repo: repo,
                accessToken: accessToken,
                labelFilter: labelFilter,
                syncEnabled: syncEnabled,
                syncClosedIssues: syncClosedIssues,
                syncIntervalMinutes: syncIntervalMinutes,
                labelMappings: labelMappings,
                statusMappings: statusMappings,
                milestoneMappings: milestoneMappings,
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

typedef $$GithubIntegrationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GithubIntegrationsTable,
      GithubIntegration,
      $$GithubIntegrationsTableFilterComposer,
      $$GithubIntegrationsTableOrderingComposer,
      $$GithubIntegrationsTableAnnotationComposer,
      $$GithubIntegrationsTableCreateCompanionBuilder,
      $$GithubIntegrationsTableUpdateCompanionBuilder,
      (
        GithubIntegration,
        BaseReferences<
          _$AppDatabase,
          $GithubIntegrationsTable,
          GithubIntegration
        >,
      ),
      GithubIntegration,
      PrefetchHooks Function()
    >;
typedef $$IssueLinksTableCreateCompanionBuilder =
    IssueLinksCompanion Function({
      required String id,
      required String taskId,
      required String integrationId,
      required String issueType,
      required String externalIssueId,
      Value<String?> externalIssueKey,
      Value<String?> externalIssueUrl,
      Value<String?> externalTitle,
      Value<String?> externalStatus,
      Value<String?> externalPriority,
      Value<String?> externalAssignee,
      Value<int?> externalUpdatedAt,
      Value<int?> lastSyncedAt,
      Value<bool> hasConflict,
      Value<String?> conflictData,
      Value<bool> pullChanges,
      Value<bool> pushChanges,
      required int created,
      Value<int?> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });
typedef $$IssueLinksTableUpdateCompanionBuilder =
    IssueLinksCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> integrationId,
      Value<String> issueType,
      Value<String> externalIssueId,
      Value<String?> externalIssueKey,
      Value<String?> externalIssueUrl,
      Value<String?> externalTitle,
      Value<String?> externalStatus,
      Value<String?> externalPriority,
      Value<String?> externalAssignee,
      Value<int?> externalUpdatedAt,
      Value<int?> lastSyncedAt,
      Value<bool> hasConflict,
      Value<String?> conflictData,
      Value<bool> pullChanges,
      Value<bool> pushChanges,
      Value<int> created,
      Value<int?> modified,
      Value<String> crdtClock,
      Value<String> crdtState,
      Value<int> rowid,
    });

class $$IssueLinksTableFilterComposer
    extends Composer<_$AppDatabase, $IssueLinksTable> {
  $$IssueLinksTableFilterComposer({
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

  ColumnFilters<String> get integrationId => $composableBuilder(
    column: $table.integrationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueType => $composableBuilder(
    column: $table.issueType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalIssueId => $composableBuilder(
    column: $table.externalIssueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalIssueKey => $composableBuilder(
    column: $table.externalIssueKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalIssueUrl => $composableBuilder(
    column: $table.externalIssueUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalTitle => $composableBuilder(
    column: $table.externalTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalStatus => $composableBuilder(
    column: $table.externalStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalPriority => $composableBuilder(
    column: $table.externalPriority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalAssignee => $composableBuilder(
    column: $table.externalAssignee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get externalUpdatedAt => $composableBuilder(
    column: $table.externalUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasConflict => $composableBuilder(
    column: $table.hasConflict,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conflictData => $composableBuilder(
    column: $table.conflictData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pullChanges => $composableBuilder(
    column: $table.pullChanges,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pushChanges => $composableBuilder(
    column: $table.pushChanges,
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

class $$IssueLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $IssueLinksTable> {
  $$IssueLinksTableOrderingComposer({
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

  ColumnOrderings<String> get integrationId => $composableBuilder(
    column: $table.integrationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueType => $composableBuilder(
    column: $table.issueType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalIssueId => $composableBuilder(
    column: $table.externalIssueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalIssueKey => $composableBuilder(
    column: $table.externalIssueKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalIssueUrl => $composableBuilder(
    column: $table.externalIssueUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalTitle => $composableBuilder(
    column: $table.externalTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalStatus => $composableBuilder(
    column: $table.externalStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalPriority => $composableBuilder(
    column: $table.externalPriority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalAssignee => $composableBuilder(
    column: $table.externalAssignee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get externalUpdatedAt => $composableBuilder(
    column: $table.externalUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasConflict => $composableBuilder(
    column: $table.hasConflict,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conflictData => $composableBuilder(
    column: $table.conflictData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pullChanges => $composableBuilder(
    column: $table.pullChanges,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pushChanges => $composableBuilder(
    column: $table.pushChanges,
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

class $$IssueLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $IssueLinksTable> {
  $$IssueLinksTableAnnotationComposer({
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

  GeneratedColumn<String> get integrationId => $composableBuilder(
    column: $table.integrationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issueType =>
      $composableBuilder(column: $table.issueType, builder: (column) => column);

  GeneratedColumn<String> get externalIssueId => $composableBuilder(
    column: $table.externalIssueId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalIssueKey => $composableBuilder(
    column: $table.externalIssueKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalIssueUrl => $composableBuilder(
    column: $table.externalIssueUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalTitle => $composableBuilder(
    column: $table.externalTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalStatus => $composableBuilder(
    column: $table.externalStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalPriority => $composableBuilder(
    column: $table.externalPriority,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalAssignee => $composableBuilder(
    column: $table.externalAssignee,
    builder: (column) => column,
  );

  GeneratedColumn<int> get externalUpdatedAt => $composableBuilder(
    column: $table.externalUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasConflict => $composableBuilder(
    column: $table.hasConflict,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conflictData => $composableBuilder(
    column: $table.conflictData,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pullChanges => $composableBuilder(
    column: $table.pullChanges,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pushChanges => $composableBuilder(
    column: $table.pushChanges,
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

class $$IssueLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IssueLinksTable,
          IssueLink,
          $$IssueLinksTableFilterComposer,
          $$IssueLinksTableOrderingComposer,
          $$IssueLinksTableAnnotationComposer,
          $$IssueLinksTableCreateCompanionBuilder,
          $$IssueLinksTableUpdateCompanionBuilder,
          (
            IssueLink,
            BaseReferences<_$AppDatabase, $IssueLinksTable, IssueLink>,
          ),
          IssueLink,
          PrefetchHooks Function()
        > {
  $$IssueLinksTableTableManager(_$AppDatabase db, $IssueLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IssueLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IssueLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IssueLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> integrationId = const Value.absent(),
                Value<String> issueType = const Value.absent(),
                Value<String> externalIssueId = const Value.absent(),
                Value<String?> externalIssueKey = const Value.absent(),
                Value<String?> externalIssueUrl = const Value.absent(),
                Value<String?> externalTitle = const Value.absent(),
                Value<String?> externalStatus = const Value.absent(),
                Value<String?> externalPriority = const Value.absent(),
                Value<String?> externalAssignee = const Value.absent(),
                Value<int?> externalUpdatedAt = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<bool> hasConflict = const Value.absent(),
                Value<String?> conflictData = const Value.absent(),
                Value<bool> pullChanges = const Value.absent(),
                Value<bool> pushChanges = const Value.absent(),
                Value<int> created = const Value.absent(),
                Value<int?> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IssueLinksCompanion(
                id: id,
                taskId: taskId,
                integrationId: integrationId,
                issueType: issueType,
                externalIssueId: externalIssueId,
                externalIssueKey: externalIssueKey,
                externalIssueUrl: externalIssueUrl,
                externalTitle: externalTitle,
                externalStatus: externalStatus,
                externalPriority: externalPriority,
                externalAssignee: externalAssignee,
                externalUpdatedAt: externalUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                hasConflict: hasConflict,
                conflictData: conflictData,
                pullChanges: pullChanges,
                pushChanges: pushChanges,
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
                required String integrationId,
                required String issueType,
                required String externalIssueId,
                Value<String?> externalIssueKey = const Value.absent(),
                Value<String?> externalIssueUrl = const Value.absent(),
                Value<String?> externalTitle = const Value.absent(),
                Value<String?> externalStatus = const Value.absent(),
                Value<String?> externalPriority = const Value.absent(),
                Value<String?> externalAssignee = const Value.absent(),
                Value<int?> externalUpdatedAt = const Value.absent(),
                Value<int?> lastSyncedAt = const Value.absent(),
                Value<bool> hasConflict = const Value.absent(),
                Value<String?> conflictData = const Value.absent(),
                Value<bool> pullChanges = const Value.absent(),
                Value<bool> pushChanges = const Value.absent(),
                required int created,
                Value<int?> modified = const Value.absent(),
                Value<String> crdtClock = const Value.absent(),
                Value<String> crdtState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IssueLinksCompanion.insert(
                id: id,
                taskId: taskId,
                integrationId: integrationId,
                issueType: issueType,
                externalIssueId: externalIssueId,
                externalIssueKey: externalIssueKey,
                externalIssueUrl: externalIssueUrl,
                externalTitle: externalTitle,
                externalStatus: externalStatus,
                externalPriority: externalPriority,
                externalAssignee: externalAssignee,
                externalUpdatedAt: externalUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                hasConflict: hasConflict,
                conflictData: conflictData,
                pullChanges: pullChanges,
                pushChanges: pushChanges,
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

typedef $$IssueLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IssueLinksTable,
      IssueLink,
      $$IssueLinksTableFilterComposer,
      $$IssueLinksTableOrderingComposer,
      $$IssueLinksTableAnnotationComposer,
      $$IssueLinksTableCreateCompanionBuilder,
      $$IssueLinksTableUpdateCompanionBuilder,
      (IssueLink, BaseReferences<_$AppDatabase, $IssueLinksTable, IssueLink>),
      IssueLink,
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
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$TaskRepeatCfgsTableTableManager get taskRepeatCfgs =>
      $$TaskRepeatCfgsTableTableManager(_db, _db.taskRepeatCfgs);
  $$JiraIntegrationsTableTableManager get jiraIntegrations =>
      $$JiraIntegrationsTableTableManager(_db, _db.jiraIntegrations);
  $$GithubIntegrationsTableTableManager get githubIntegrations =>
      $$GithubIntegrationsTableTableManager(_db, _db.githubIntegrations);
  $$IssueLinksTableTableManager get issueLinks =>
      $$IssueLinksTableTableManager(_db, _db.issueLinks);
}
