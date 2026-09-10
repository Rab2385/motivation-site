import '../models/task_occurrence.dart';
import '../util/dates.dart';

/// Default per-weekday XP capacity (index 0 = Monday … 6 = Sunday).
const List<int> defaultDayTargetXp = [150, 150, 150, 150, 150, 80, 80];

enum WorkloadBand { leer, ok, voll, ueberladen }

class DayWorkload {
  const DayWorkload({
    required this.date,
    required this.plannedXp,
    required this.completedXp,
    required this.targetXp,
    required this.openCount,
    required this.doneCount,
  });

  final DateTime date;
  final int plannedXp;
  final int completedXp;
  final int targetXp;
  final int openCount;
  final int doneCount;

  double get load => targetXp <= 0 ? 0 : plannedXp / targetXp;

  WorkloadBand get band {
    if (plannedXp == 0) return WorkloadBand.leer;
    if (load <= 0.85) return WorkloadBand.ok;
    if (load <= 1.10) return WorkloadBand.voll;
    return WorkloadBand.ueberladen;
  }

  bool get isOverloaded => band == WorkloadBand.ueberladen;
}

/// Target XP for [weekday] (1 = Mon … 7 = Sun) from a stored 7-item list, or
/// the default when none is set.
int targetXpForWeekday(List<int>? targets, int weekday) {
  final list = (targets != null && targets.length == 7)
      ? targets
      : defaultDayTargetXp;
  return list[weekday - 1];
}

DayWorkload workloadForDay({
  required DateTime date,
  required List<TaskOccurrence> occurrences,
  required List<int>? dayTargets,
}) {
  final key = dayKey(date);
  final onDay = occurrences.where((o) => o.dateKey == key && !o.isSkipped);

  var plannedXp = 0;
  var completedXp = 0;
  var openCount = 0;
  var doneCount = 0;
  for (final occurrence in onDay) {
    plannedXp += occurrence.xp;
    if (occurrence.isCompleted) {
      completedXp += occurrence.completion!.awardedXp;
      doneCount++;
    } else {
      openCount++;
    }
  }

  return DayWorkload(
    date: dateOnly(date),
    plannedXp: plannedXp,
    completedXp: completedXp,
    targetXp: targetXpForWeekday(dayTargets, date.weekday),
    openCount: openCount,
    doneCount: doneCount,
  );
}

/// The lightest day (by planned XP headroom) in the same Mon–Sun week as
/// [from], excluding [from] itself and past days. Used for the overload hint.
DateTime? lightestOtherDayInWeek({
  required DateTime from,
  required DateTime today,
  required List<TaskOccurrence> occurrences,
  required List<int>? dayTargets,
}) {
  DateTime? best;
  double bestLoad = double.infinity;
  for (final day in daysInRange(weekStart(from), weekEnd(from))) {
    if (isSameDay(day, from)) continue;
    if (day.isBefore(dateOnly(today))) continue;
    final load = workloadForDay(
      date: day,
      occurrences: occurrences,
      dayTargets: dayTargets,
    ).load;
    if (load < bestLoad) {
      bestLoad = load;
      best = day;
    }
  }
  return best;
}
