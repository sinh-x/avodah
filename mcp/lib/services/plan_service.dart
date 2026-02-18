/// Service layer for daily plan operations.
library;

import 'package:avodah_core/avodah_core.dart';

/// Plan-vs-actual for a single category.
class PlanVsActual {
  final String category;
  final Duration planned;
  final Duration actual;

  const PlanVsActual({
    required this.category,
    required this.planned,
    required this.actual,
  });

  Duration get delta => actual - planned;
}

/// Summary of a day's plan with plan-vs-actual per category.
class DayPlanSummary {
  final String day;
  final List<PlanVsActual> categories;
  final PlanVsActual? nonCategorized;

  const DayPlanSummary({
    required this.day,
    required this.categories,
    this.nonCategorized,
  });

  Duration get totalPlanned => categories.fold(
      Duration.zero, (sum, c) => sum + c.planned);

  Duration get totalActual {
    var total = categories.fold(
        Duration.zero, (sum, c) => sum + c.actual);
    if (nonCategorized != null) total += nonCategorized!.actual;
    return total;
  }
}

/// Wraps daily plan database operations.
class PlanService {
  final AppDatabase db;
  final HybridLogicalClock clock;

  PlanService({required this.db, required this.clock});

  Future<void> _savePlan(DailyPlanDocument plan) async {
    await db
        .into(db.dailyPlanEntries)
        .insertOnConflictUpdate(plan.toDriftCompanion());
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Creates a plan entry. Throws [DuplicatePlanEntryException] if
  /// the same category+day already exists (and is not deleted).
  Future<DailyPlanDocument> add({
    required String category,
    required int durationMs,
    String? day,
  }) async {
    final targetDay = day ?? _today();

    // Check for duplicate
    final existing = await _entriesForDay(targetDay);
    final dup = existing.where(
        (e) => e.category.toLowerCase() == category.toLowerCase()).toList();
    if (dup.isNotEmpty) {
      throw DuplicatePlanEntryException(category, targetDay);
    }

    final plan = DailyPlanDocument.create(
      clock: clock,
      category: category,
      day: targetDay,
      durationMs: durationMs,
    );

    await _savePlan(plan);
    return plan;
  }

  /// Soft-deletes a plan entry for a category on a day.
  /// Throws [PlanEntryNotFoundException] if not found.
  Future<DailyPlanDocument> remove({
    required String category,
    String? day,
  }) async {
    final targetDay = day ?? _today();
    final existing = await _entriesForDay(targetDay);
    final match = existing.where(
        (e) => e.category.toLowerCase() == category.toLowerCase()).toList();

    if (match.isEmpty) {
      throw PlanEntryNotFoundException(category, targetDay);
    }

    final entry = match.first;
    entry.delete();
    await _savePlan(entry);
    return entry;
  }

  /// Lists non-deleted plan entries for a day.
  Future<List<DailyPlanDocument>> listForDay({String? day}) async {
    final targetDay = day ?? _today();
    return _entriesForDay(targetDay);
  }

  /// Computes plan-vs-actual summary for a day.
  Future<DayPlanSummary> summary({String? day}) async {
    final targetDay = day ?? _today();
    final plans = await _entriesForDay(targetDay);

    // Get worklogs for the day
    final worklogRows = await (db.select(db.worklogEntries)
          ..where((w) => w.date.equals(targetDay)))
        .get();
    final worklogs = worklogRows
        .map((row) => WorklogDocument.fromDrift(worklog: row, clock: clock))
        .where((doc) => !doc.isDeleted)
        .toList();

    // Get all tasks to map taskId → category
    final taskRows = await db.select(db.tasks).get();
    final taskCategory = <String, String?>{};
    for (final row in taskRows) {
      final doc = TaskDocument.fromDrift(task: row, clock: clock);
      taskCategory[doc.id] = doc.category;
    }

    // Sum actual time per category from worklogs
    final actualByCategory = <String, int>{};
    int nonCategorizedMs = 0;
    for (final w in worklogs) {
      final cat = taskCategory[w.taskId];
      if (cat == null) {
        nonCategorizedMs += w.durationMs;
      } else {
        actualByCategory[cat] =
            (actualByCategory[cat] ?? 0) + w.durationMs;
      }
    }

    // Build per-category plan-vs-actual
    final categories = <PlanVsActual>[];
    for (final plan in plans) {
      final actualMs = actualByCategory.remove(plan.category) ?? 0;
      categories.add(PlanVsActual(
        category: plan.category,
        planned: Duration(milliseconds: plan.durationMs),
        actual: Duration(milliseconds: actualMs),
      ));
    }

    // Any remaining actual categories that weren't in the plan
    // go into non-categorized or as extra entries
    for (final entry in actualByCategory.entries) {
      // Actual time in a category that has no plan entry — still show it
      categories.add(PlanVsActual(
        category: entry.key,
        planned: Duration.zero,
        actual: Duration(milliseconds: entry.value),
      ));
    }

    PlanVsActual? nonCat;
    if (nonCategorizedMs > 0) {
      nonCat = PlanVsActual(
        category: 'Non-Categorized',
        planned: Duration.zero,
        actual: Duration(milliseconds: nonCategorizedMs),
      );
    }

    return DayPlanSummary(
      day: targetDay,
      categories: categories,
      nonCategorized: nonCat,
    );
  }

  /// Aggregates plan-vs-actual across a date range.
  ///
  /// This is the core primitive — [weekSummary] derives from this.
  /// Returns a [DayPlanSummary] whose [day] is the start date and whose
  /// categories contain totals across all days in the range.
  Future<DayPlanSummary> rangeSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final days = <String>[];
    var current = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!current.isAfter(end)) {
      days.add(
          '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}');
      current = current.add(const Duration(days: 1));
    }

    // Aggregate planned per category across the range
    final plannedByCategory = <String, int>{};
    for (final day in days) {
      final entries = await _entriesForDay(day);
      for (final e in entries) {
        plannedByCategory[e.category] =
            (plannedByCategory[e.category] ?? 0) + e.durationMs;
      }
    }

    // Aggregate actual per category from worklogs across the range
    final allWorklogRows = await db.select(db.worklogEntries).get();
    final rangeWorklogs = allWorklogRows
        .map((row) => WorklogDocument.fromDrift(worklog: row, clock: clock))
        .where((doc) => !doc.isDeleted && days.contains(doc.date))
        .toList();

    final taskRows = await db.select(db.tasks).get();
    final taskCategory = <String, String?>{};
    for (final row in taskRows) {
      final doc = TaskDocument.fromDrift(task: row, clock: clock);
      taskCategory[doc.id] = doc.category;
    }

    final actualByCategory = <String, int>{};
    int nonCategorizedMs = 0;
    for (final w in rangeWorklogs) {
      final cat = taskCategory[w.taskId];
      if (cat == null) {
        nonCategorizedMs += w.durationMs;
      } else {
        actualByCategory[cat] =
            (actualByCategory[cat] ?? 0) + w.durationMs;
      }
    }

    // Merge planned and actual
    final allCategories = <String>{
      ...plannedByCategory.keys,
      ...actualByCategory.keys,
    };
    final categories = <PlanVsActual>[];
    for (final cat in allCategories) {
      categories.add(PlanVsActual(
        category: cat,
        planned: Duration(milliseconds: plannedByCategory[cat] ?? 0),
        actual: Duration(milliseconds: actualByCategory.remove(cat) ?? 0),
      ));
    }

    PlanVsActual? nonCat;
    if (nonCategorizedMs > 0) {
      nonCat = PlanVsActual(
        category: 'Non-Categorized',
        planned: Duration.zero,
        actual: Duration(milliseconds: nonCategorizedMs),
      );
    }

    return DayPlanSummary(
      day: days.first,
      categories: categories,
      nonCategorized: nonCat,
    );
  }

  /// Aggregates plan-vs-actual across a week (Mon-Sun).
  ///
  /// Convenience wrapper around [rangeSummary].
  Future<DayPlanSummary> weekSummary({DateTime? anchor}) async {
    final now = anchor ?? DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return rangeSummary(from: monday, to: sunday);
  }

  /// Returns non-deleted entries for a given day.
  Future<List<DailyPlanDocument>> _entriesForDay(String day) async {
    final rows = await (db.select(db.dailyPlanEntries)
          ..where((e) => e.day.equals(day)))
        .get();

    return rows
        .map((row) =>
            DailyPlanDocument.fromDrift(entry: row, clock: clock))
        .where((doc) => !doc.isDeleted)
        .toList();
  }
}

/// Thrown when a plan entry already exists for the category+day.
class DuplicatePlanEntryException implements Exception {
  final String category;
  final String day;
  DuplicatePlanEntryException(this.category, this.day);

  @override
  String toString() =>
      'Plan entry for "$category" on $day already exists. Remove it first.';
}

/// Thrown when no plan entry matches the category+day.
class PlanEntryNotFoundException implements Exception {
  final String category;
  final String day;
  PlanEntryNotFoundException(this.category, this.day);

  @override
  String toString() =>
      'No plan entry for "$category" on $day.';
}
