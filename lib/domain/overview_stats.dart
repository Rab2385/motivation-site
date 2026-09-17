import '../models/task_definition.dart';
import '../models/task_occurrence.dart';
import '../util/dates.dart';
import 'streaks.dart';

/// Preset windows for the stats panel, plus a caller-supplied custom range.
enum DataWindow { d7, d30, d90, all, custom }

extension DataWindowLabel on DataWindow {
  String get label => switch (this) {
        DataWindow.d7 => '7d',
        DataWindow.d30 => '30d',
        DataWindow.d90 => '90d',
        DataWindow.all => 'all',
        DataWindow.custom => 'custom',
      };
}

/// Ratio of fully-completed, non-skipped occurrences due on [date]. Null if
/// nothing was due that day (so it doesn't count for/against averages).
double? dayCompletionRate(List<TaskOccurrence> occurrences, DateTime date) {
  final key = dayKey(date);
  final due = occurrences.where((o) => o.dateKey == key && !o.isSkipped).toList();
  if (due.isEmpty) return null;
  final done = due.where((o) => o.isFullyCompleted).length;
  return done / due.length;
}

/// "// consecutive days hitting your daily goal" — current/best run of days
/// whose completion rate is >= [goalFraction]. Days with nothing due are
/// neutral (skipped over), matching the per-habit streak's skip semantics.
class GoalStreak {
  const GoalStreak({required this.current, required this.best});
  final int current;
  final int best;
}

GoalStreak computeGoalStreak({
  required List<TaskOccurrence> occurrences,
  required DateTime today,
  required double goalFraction,
  required DateTime since,
}) {
  final day0 = dateOnly(today);
  final start = dateOnly(since);
  final hits = <bool?>[];
  for (var day = start; day.isBefore(day0); day = day.add(const Duration(days: 1))) {
    final rate = dayCompletionRate(occurrences, day);
    hits.add(rate == null ? null : rate >= goalFraction);
  }

  int runFromEnd() {
    var count = 0;
    for (var i = hits.length - 1; i >= 0; i--) {
      final hit = hits[i];
      if (hit == null) continue;
      if (hit) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  int bestRun() {
    var best = 0;
    var count = 0;
    for (final hit in hits) {
      if (hit == null) continue;
      if (hit) {
        count++;
        if (count > best) best = count;
      } else {
        count = 0;
      }
    }
    return best;
  }

  return GoalStreak(current: runFromEnd(), best: bestRun());
}

/// The left "$ status" + right "$ stats --overview" panel data.
class OverviewStats {
  const OverviewStats({
    required this.daysTracked,
    required this.avgCompletion,
    required this.dailyGoalMetDays,
    required this.totalCompletions,
    required this.goalStreak,
    required this.topHabitTitle,
    required this.topHabitStreak,
    required this.thisWindowCompletion,
    required this.perfectDays,
    required this.totalDaysInWindow,
    required this.weekdayAvg,
    required this.weekendAvg,
    required this.dayOfWeekRates,
    required this.bestWeekday,
    required this.worstWeekday,
  });

  final int daysTracked;
  final double avgCompletion;
  final int dailyGoalMetDays;
  final int totalCompletions;
  final GoalStreak goalStreak;
  final String? topHabitTitle;
  final int topHabitStreak;
  final double thisWindowCompletion;
  final int perfectDays;
  final int totalDaysInWindow;
  final double weekdayAvg;
  final double weekendAvg;

  /// Mon..Sun completion rate within the window.
  final List<double> dayOfWeekRates;
  final int? bestWeekday;
  final int? worstWeekday;
}

DateTime windowStart(DataWindow window, DateTime today, {DateTime? customStart}) {
  final day0 = dateOnly(today);
  switch (window) {
    case DataWindow.d7:
      return day0.subtract(const Duration(days: 6));
    case DataWindow.d30:
      return day0.subtract(const Duration(days: 29));
    case DataWindow.d90:
      return day0.subtract(const Duration(days: 89));
    case DataWindow.all:
      return DateTime(2000);
    case DataWindow.custom:
      return customStart ?? day0.subtract(const Duration(days: 29));
  }
}

OverviewStats computeOverviewStats({
  required List<TaskOccurrence> occurrences,
  required List<TaskDefinition> definitions,
  required DateTime today,
  required DataWindow window,
  double goalFraction = 0.6,
  DateTime? customStart,
}) {
  final day0 = dateOnly(today);
  var start = windowStart(window, today, customStart: customStart);
  if (window == DataWindow.all) {
    for (final o in occurrences) {
      if (o.date.isBefore(start)) start = o.date;
    }
  }

  final ratesByDay = <DateTime, double>{};
  var totalCompletions = 0;
  for (var day = start; !day.isAfter(day0); day = day.add(const Duration(days: 1))) {
    final rate = dayCompletionRate(occurrences, day);
    if (rate != null) ratesByDay[day] = rate;
  }
  for (final o in occurrences) {
    if (o.isFullyCompleted &&
        !o.date.isBefore(start) &&
        !o.date.isAfter(day0)) {
      totalCompletions++;
    }
  }

  final daysTracked = ratesByDay.length;
  final avgCompletion = daysTracked == 0
      ? 0.0
      : ratesByDay.values.reduce((a, b) => a + b) / daysTracked;
  final dailyGoalMetDays =
      ratesByDay.values.where((rate) => rate >= goalFraction).length;
  final perfectDays = ratesByDay.values.where((rate) => rate >= 1.0).length;

  final weekdayRates = <double>[];
  final weekendRates = <double>[];
  final byWeekday = List.generate(7, (_) => <double>[]);
  for (final entry in ratesByDay.entries) {
    final weekday = entry.key.weekday; // 1=Mon..7=Sun
    byWeekday[weekday - 1].add(entry.value);
    if (weekday >= 6) {
      weekendRates.add(entry.value);
    } else {
      weekdayRates.add(entry.value);
    }
  }
  double avgOf(List<double> values) =>
      values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;

  final dayOfWeekRates = [for (final list in byWeekday) avgOf(list)];
  int? bestDay;
  int? worstDay;
  for (var i = 0; i < 7; i++) {
    if (byWeekday[i].isEmpty) continue;
    if (bestDay == null || dayOfWeekRates[i] > dayOfWeekRates[bestDay]) {
      bestDay = i;
    }
    if (worstDay == null || dayOfWeekRates[i] < dayOfWeekRates[worstDay]) {
      worstDay = i;
    }
  }

  final goalStreak = computeGoalStreak(
    occurrences: occurrences,
    today: today,
    goalFraction: goalFraction,
    since: start,
  );

  String? topTitle;
  var topStreak = 0;
  for (final definition in definitions) {
    final streak = computeStreak(
      definition: definition,
      occurrences: occurrences,
      today: today,
    );
    if (streak.best > topStreak) {
      topStreak = streak.best;
      topTitle = definition.title;
    }
  }

  return OverviewStats(
    daysTracked: daysTracked,
    avgCompletion: avgCompletion,
    dailyGoalMetDays: dailyGoalMetDays,
    totalCompletions: totalCompletions,
    goalStreak: goalStreak,
    topHabitTitle: topTitle,
    topHabitStreak: topStreak,
    thisWindowCompletion: avgCompletion,
    perfectDays: perfectDays,
    totalDaysInWindow: ratesByDay.length,
    weekdayAvg: avgOf(weekdayRates),
    weekendAvg: avgOf(weekendRates),
    dayOfWeekRates: dayOfWeekRates,
    bestWeekday: bestDay,
    worstWeekday: worstDay,
  );
}

/// One cell of the GitHub-style contribution heatmap.
class HeatCell {
  const HeatCell({required this.date, required this.level});

  /// 0 (nothing) .. 4 (best), matching the "less … more" legend.
  final DateTime date;
  final int level;
}

/// Contribution heatmap over the last [weeks] weeks, Mon-first columns.
List<List<HeatCell>> buildContributionHeatmap({
  required List<TaskOccurrence> occurrences,
  required DateTime today,
  int weeks = 20,
}) {
  final countByDay = <String, int>{};
  for (final o in occurrences) {
    if (!o.isFullyCompleted) continue;
    countByDay.update(o.dateKey, (v) => v + 1, ifAbsent: () => 1);
  }
  var maxCount = 1;
  for (final count in countByDay.values) {
    if (count > maxCount) maxCount = count;
  }

  int levelFor(int count) {
    if (count <= 0) return 0;
    final ratio = count / maxCount;
    if (ratio > 0.75) return 4;
    if (ratio > 0.5) return 3;
    if (ratio > 0.25) return 2;
    return 1;
  }

  final end = weekStart(today).add(const Duration(days: 6));
  final start = end.subtract(Duration(days: weeks * 7 - 1));

  final columns = <List<HeatCell>>[];
  for (var w = 0; w < weeks; w++) {
    final column = <HeatCell>[];
    for (var d = 0; d < 7; d++) {
      final date = start.add(Duration(days: w * 7 + d));
      final count = countByDay[dayKey(date)] ?? 0;
      column.add(HeatCell(date: date, level: date.isAfter(today) ? -1 : levelFor(count)));
    }
    columns.add(column);
  }
  return columns;
}
