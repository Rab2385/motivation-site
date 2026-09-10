import '../models/task_definition.dart';
import '../models/task_occurrence.dart';
import '../util/dates.dart';
import 'progression.dart';
import 'streaks.dart';

/// Whether [dayOccurrences] (all occurrences on one date) make a "perfect day":
/// at least one real completion and nothing left open.
bool isPerfectDay(Iterable<TaskOccurrence> dayOccurrences) {
  final list = dayOccurrences.toList();
  return list.isNotEmpty &&
      list.every((o) => o.isCompleted || o.isSkipped) &&
      list.any((o) => o.isFullyCompleted);
}

/// An aggregate view of progress. Consumed by the Statistik page and the
/// achievement engine so both agree on the numbers.
class StatsSnapshot {
  const StatsSnapshot({
    required this.totalXp,
    required this.level,
    required this.totalCompletions,
    required this.completionsToday,
    required this.hadPerfectDayToday,
    required this.perfectDaysTotal,
    required this.bestCurrentStreak,
    required this.longestStreakEver,
    required this.distinctCategoriesCompleted,
    required this.xpByCategory,
    required this.xpByDay,
    required this.plannedXpByDay,
    required this.fullyPlannedWeeks,
  });

  final int totalXp;
  final int level;
  final int totalCompletions;
  final int completionsToday;
  final bool hadPerfectDayToday;
  final int perfectDaysTotal;
  final int bestCurrentStreak;
  final int longestStreakEver;
  final int distinctCategoriesCompleted;

  final Map<String, int> xpByCategory;

  /// dateKey -> awarded XP that day (task XP + perfect-day bonus).
  final Map<String, int> xpByDay;

  /// dateKey -> planned XP that day (non-skipped).
  final Map<String, int> plannedXpByDay;

  /// Number of upcoming Mon–Sun weeks that already have at least one planned
  /// task on every day.
  final int fullyPlannedWeeks;
}

StatsSnapshot buildStatsSnapshot({
  required List<TaskOccurrence> occurrences,
  required List<TaskDefinition> definitions,
  required DateTime today,
  int perfectDayBonus = 0,
  int graceLimit = 1,
  LevelCurve levelCurve = LevelCurve.standard,
}) {
  final todayKey = dayKey(today);

  var totalXp = 0;
  var totalCompletions = 0;
  var completionsToday = 0;
  final xpByCategory = <String, int>{};
  final xpByDay = <String, int>{};
  final plannedXpByDay = <String, int>{};
  final completedCategories = <String>{};
  final byDay = <String, List<TaskOccurrence>>{};

  for (final occurrence in occurrences) {
    byDay.putIfAbsent(occurrence.dateKey, () => []).add(occurrence);
    if (!occurrence.isSkipped) {
      plannedXpByDay.update(
        occurrence.dateKey,
        (value) => value + occurrence.xp,
        ifAbsent: () => occurrence.xp,
      );
    }
    final completion = occurrence.completion;
    if (completion == null) continue;
    totalXp += completion.awardedXp;
    totalCompletions++;
    if (occurrence.dateKey == todayKey) completionsToday++;
    completedCategories.add(occurrence.categoryId);
    xpByCategory.update(
      occurrence.categoryId,
      (value) => value + completion.awardedXp,
      ifAbsent: () => completion.awardedXp,
    );
    xpByDay.update(
      occurrence.dateKey,
      (value) => value + completion.awardedXp,
      ifAbsent: () => completion.awardedXp,
    );
  }

  var perfectDaysTotal = 0;
  for (final entry in byDay.entries) {
    if (!isPerfectDay(entry.value)) continue;
    perfectDaysTotal++;
    if (perfectDayBonus > 0) {
      totalXp += perfectDayBonus;
      xpByDay.update(entry.key, (value) => value + perfectDayBonus,
          ifAbsent: () => perfectDayBonus);
    }
  }

  final hadPerfectDayToday = isPerfectDay(byDay[todayKey] ?? const []);

  var bestCurrentStreak = 0;
  var longestStreakEver = 0;
  for (final definition in definitions) {
    final streak = computeStreak(
      definition: definition,
      occurrences: occurrences,
      today: today,
      graceLimit: graceLimit,
    );
    if (streak.current > bestCurrentStreak) bestCurrentStreak = streak.current;
    if (streak.best > longestStreakEver) longestStreakEver = streak.best;
  }

  return StatsSnapshot(
    totalXp: totalXp,
    level: levelProgressFor(totalXp, curve: levelCurve).level,
    totalCompletions: totalCompletions,
    completionsToday: completionsToday,
    hadPerfectDayToday: hadPerfectDayToday,
    perfectDaysTotal: perfectDaysTotal,
    bestCurrentStreak: bestCurrentStreak,
    longestStreakEver: longestStreakEver,
    distinctCategoriesCompleted: completedCategories.length,
    xpByCategory: xpByCategory,
    xpByDay: xpByDay,
    plannedXpByDay: plannedXpByDay,
    fullyPlannedWeeks: _countFullyPlannedWeeks(occurrences, today),
  );
}

int _countFullyPlannedWeeks(List<TaskOccurrence> occurrences, DateTime today) {
  final plannedDays = occurrences
      .where((o) => !o.isSkipped)
      .map((o) => o.dateKey)
      .toSet();
  var count = 0;
  for (var week = 0; week < 2; week++) {
    final monday = weekStart(today).add(Duration(days: 7 * week));
    final allDays = daysInRange(monday, monday.add(const Duration(days: 6)));
    if (allDays.every((day) => plannedDays.contains(dayKey(day)))) count++;
  }
  return count;
}

// ---- Statistik page: period aggregation ------------------------------------

enum StatsPeriod {
  woche('Woche'),
  monat('Monat'),
  jahr('Jahr'),
  alleZeit('Alle Zeit');

  const StatsPeriod(this.label);
  final String label;
}

/// Inclusive [start, end] date range for [period] ending on [today].
({DateTime start, DateTime end}) periodRange(StatsPeriod period, DateTime today) {
  final end = dateOnly(today);
  switch (period) {
    case StatsPeriod.woche:
      return (start: weekStart(today), end: end);
    case StatsPeriod.monat:
      return (start: end.subtract(const Duration(days: 29)), end: end);
    case StatsPeriod.jahr:
      return (start: DateTime(end.year, 1, 1), end: end);
    case StatsPeriod.alleZeit:
      return (start: DateTime(2000), end: end);
  }
}

class PeriodStats {
  const PeriodStats({
    required this.tasksDone,
    required this.xpEarned,
    required this.tasksDelta,
    required this.xpDelta,
    required this.dueCount,
    required this.completedRate,
    required this.bars,
    required this.barLabels,
  });

  final int tasksDone;
  final int xpEarned;

  /// Percent change vs the previous period of the same length; null if the
  /// previous period had nothing.
  final int? tasksDelta;
  final int? xpDelta;

  final int dueCount;
  final double completedRate;

  /// Chart values (task counts) and their axis labels.
  final List<int> bars;
  final List<String> barLabels;
}

PeriodStats computePeriodStats({
  required List<TaskOccurrence> occurrences,
  required DateTime today,
  required StatsPeriod period,
  int perfectDayBonus = 0,
}) {
  final range = periodRange(period, today);
  final span = range.end.difference(range.start).inDays + 1;
  final prevEnd = range.start.subtract(const Duration(days: 1));
  final prevStart = prevEnd.subtract(Duration(days: span - 1));

  ({int tasks, int xp, int due, int done}) tally(DateTime from, DateTime to) {
    var tasks = 0, xp = 0, due = 0, done = 0;
    final perfectByDay = <String, List<TaskOccurrence>>{};
    for (final occurrence in occurrences) {
      final date = occurrence.date;
      if (date.isBefore(from) || date.isAfter(to)) continue;
      perfectByDay.putIfAbsent(occurrence.dateKey, () => []).add(occurrence);
      if (!occurrence.isSkipped && !date.isAfter(dateOnly(today))) {
        due++;
        if (occurrence.isFullyCompleted) done++;
      }
      final completion = occurrence.completion;
      if (completion == null) continue;
      tasks++;
      xp += completion.awardedXp;
    }
    if (perfectDayBonus > 0) {
      for (final day in perfectByDay.values) {
        if (isPerfectDay(day)) xp += perfectDayBonus;
      }
    }
    return (tasks: tasks, xp: xp, due: due, done: done);
  }

  final now = tally(range.start, range.end);
  final before = tally(prevStart, prevEnd);

  int? delta(int current, int previous) =>
      previous == 0 ? null : ((current - previous) / previous * 100).round();

  // Bars: 7 weekday buckets for Woche, otherwise up to 12 evenly-spaced slots.
  final bars = <int>[];
  final labels = <String>[];
  if (period == StatsPeriod.woche) {
    final monday = weekStart(today);
    for (final day in daysInRange(monday, monday.add(const Duration(days: 6)))) {
      bars.add(occurrences
          .where((o) => o.dateKey == dayKey(day) && o.isCompleted)
          .length);
      labels.add(weekdayShortLabels[day.weekday - 1]);
    }
  } else {
    final buckets = period == StatsPeriod.jahr ? 12 : 10;
    final bucketDays = (span / buckets).ceil();
    for (var i = 0; i < buckets; i++) {
      final bStart = range.start.add(Duration(days: i * bucketDays));
      if (bStart.isAfter(range.end)) break;
      final bEnd = bStart.add(Duration(days: bucketDays - 1));
      bars.add(occurrences
          .where((o) =>
              o.isCompleted &&
              !o.date.isBefore(bStart) &&
              !o.date.isAfter(bEnd))
          .length);
      labels.add('${bStart.day}.${bStart.month}.');
    }
  }

  return PeriodStats(
    tasksDone: now.tasks,
    xpEarned: now.xp,
    tasksDelta: delta(now.tasks, before.tasks),
    xpDelta: delta(now.xp, before.xp),
    dueCount: now.due,
    completedRate: now.due == 0 ? 0 : now.done / now.due,
    bars: bars,
    barLabels: labels,
  );
}

const List<String> weekdayShortLabels = [
  'Mo',
  'Di',
  'Mi',
  'Do',
  'Fr',
  'Sa',
  'So',
];

/// XP earned per ISO week, oldest first, for the trend chart.
List<MapEntry<String, int>> xpByWeek(List<TaskOccurrence> occurrences) {
  final byWeek = <String, int>{};
  for (final occurrence in occurrences) {
    final completion = occurrence.completion;
    if (completion == null) continue;
    byWeek.update(
      isoWeekKey(occurrence.date),
      (value) => value + completion.awardedXp,
      ifAbsent: () => completion.awardedXp,
    );
  }
  final entries = byWeek.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries;
}

/// Completion rate (full completions ÷ due occurrences) over the last
/// [days] days, ignoring skips and the future.
double recentCompletionRate(
  List<TaskOccurrence> occurrences,
  DateTime today, {
  int days = 30,
}) {
  final from = dateOnly(today).subtract(Duration(days: days - 1));
  var due = 0;
  var done = 0;
  for (final occurrence in occurrences) {
    if (occurrence.isSkipped) continue;
    final date = occurrence.date;
    if (date.isBefore(from) || date.isAfter(dateOnly(today))) continue;
    due++;
    if (occurrence.isFullyCompleted) done++;
  }
  return due == 0 ? 0 : done / due;
}
