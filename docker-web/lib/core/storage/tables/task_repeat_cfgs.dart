import 'package:drift/drift.dart';

/// Task repeat configuration table - aligned with Super Productivity TaskRepeatCfg
class TaskRepeatCfgs extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get tagIds => text().withDefault(const Constant('[]'))(); // JSON array

  // Ordering
  IntColumn get order => integer().withDefault(const Constant(0))();

  // Defaults for created tasks
  IntColumn get defaultEstimate => integer().nullable()(); // ms
  TextColumn get startTime => text().nullable()(); // HH:MM
  TextColumn get remindAt => text().nullable()(); // TaskReminderOptionId

  // Repeat settings
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  TextColumn get quickSetting => text()(); // DAILY, WEEKLY_CURRENT_WEEKDAY, etc.
  TextColumn get repeatCycle => text()(); // DAILY, WEEKLY, MONTHLY, YEARLY
  TextColumn get startDate => text().nullable()(); // YYYY-MM-DD
  IntColumn get repeatEvery => integer().withDefault(const Constant(1))();

  // Weekday flags
  BoolColumn get monday => boolean().withDefault(const Constant(false))();
  BoolColumn get tuesday => boolean().withDefault(const Constant(false))();
  BoolColumn get wednesday => boolean().withDefault(const Constant(false))();
  BoolColumn get thursday => boolean().withDefault(const Constant(false))();
  BoolColumn get friday => boolean().withDefault(const Constant(false))();
  BoolColumn get saturday => boolean().withDefault(const Constant(false))();
  BoolColumn get sunday => boolean().withDefault(const Constant(false))();

  // Notes
  TextColumn get notes => text().nullable()();

  // Subtask templates (JSON array)
  TextColumn get subTaskTemplates => text().withDefault(const Constant('[]'))();

  // Tracking
  IntColumn get lastTaskCreation => integer().nullable()(); // Unix ms
  TextColumn get lastTaskCreationDay => text().nullable()(); // YYYY-MM-DD
  TextColumn get deletedInstanceDates => text().withDefault(const Constant('[]'))(); // JSON array

  // CRDT metadata
  TextColumn get crdtClock => text().withDefault(const Constant(''))();
  TextColumn get crdtState => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}
