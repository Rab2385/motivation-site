import '../models/task_definition.dart';
import '../models/task_occurrence.dart';
import '../util/dates.dart';
import 'progression.dart';
import 'streaks.dart';

/// An aggregate view of progress. Consumed by the Statistik page and the
/// achievement engine so both agree on the numbers.
class StatsSnapshot {
  const StatsSnapshot({
    required this.totalXp,
    required this.level,
    required this.totalCompletions,
    required this.completionsToday,
    required this.hadPerfectDayToday,
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
  final int bestCurrentStreak;
  final int longestStreakEver;
  final int distinctCategoriesCompleted;

  final Map<String, int> xpByCategory;

  /// dateKey -> awarded XP that day.
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
}) {
  final todayKey = dayKey(today);

  var totalXp = 0;
  var totalCompletions = 0;
  var completionsToday = 0;
  final xpByCategory = <String, int>{};
  final xpByDay = <String, int>{};
  final plannedXpByDay = <String, int>{};
  final completedCategories = <String>{};

  for (final occurrence in occurrences) {
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

  final todays = occurrences.where((o) => o.dateKey == todayKey).toList();
  final hadPerfectDayToday = todays.isNotEmpty &&
      todays.every((o) => o.isCompleted || o.isSkipped) &&
      todays.any((o) => o.isFullyCompleted);

  var bestCurrentStreak = 0;
  var longestStreakEver = 0;
  for (final definition in definitions) {
    final streak = computeStreak(
      definition: definition,
      occurrences: occurrences,
      today: today,
    );
    if (streak.current > bestCurrentStreak) bestCurrentStreak = streak.current;
    if (streak.best > longestStreakEver) longestStreakEver = streak.best;
  }

  return StatsSnapshot(
    totalXp: totalXp,
    level: levelProgressFor(totalXp).level,
    totalCompletions: totalCompletions,
    completionsToday: completionsToday,
    hadPerfectDayToday: hadPerfectDayToday,
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
