import '../models/recurrence_rule.dart';
import '../models/task_definition.dart';
import '../models/task_occurrence.dart';
import '../util/dates.dart';

/// Streak state for one recurring [TaskDefinition]. One-off tasks never have
/// a streak.
class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.best,
    required this.atRisk,
    required this.progressLabel,
  });

  const StreakInfo.empty()
      : current = 0,
        best = 0,
        atRisk = false,
        progressLabel = '';

  final int current;
  final int best;

  /// True when the most recent scheduled slot / week was missed but the
  /// 1-item grace is still holding the streak.
  final bool atRisk;

  /// Short German status for the current (in-progress) period,
  /// e.g. "2 / 3 diese Woche".
  final String progressLabel;
}

/// Consecutive misses tolerated before a streak breaks. Set per call from
/// [computeStreak]'s `graceLimit` (Streak-Schutz on = 1, off = 0). The UI
/// runs on a single isolate, so a call-scoped global is safe here.
int _graceLimit = 1;

StreakInfo computeStreak({
  required TaskDefinition definition,
  required List<TaskOccurrence> occurrences,
  required DateTime today,
  int graceLimit = 1,
}) {
  _graceLimit = graceLimit;
  final mine = occurrences
      .where((o) => o.sourceDefinitionId == definition.id)
      .toList();

  switch (definition.recurrence.kind) {
    case RecurrenceKind.fixedWeekdays:
      return _fixedWeekdayStreak(definition, mine, dateOnly(today));
    case RecurrenceKind.timesPerWeek:
      return _timesPerWeekStreak(definition, mine, dateOnly(today));
    case RecurrenceKind.monthly:
      // A once-a-month cadence doesn't have a consecutive-day streak; it's
      // tracked as a plain completion instead (see the Life Grid review).
      return const StreakInfo.empty();
  }
}

enum _SlotStatus { completed, skipped, missed }

StreakInfo _fixedWeekdayStreak(
  TaskDefinition definition,
  List<TaskOccurrence> occurrences,
  DateTime today,
) {
  final rule = definition.recurrence;
  if (rule.weekdays.isEmpty) return const StreakInfo.empty();

  final byDate = {for (final o in occurrences) o.dateKey: o};

  var anchor = dateOnly(definition.createdAt);
  for (final o in occurrences) {
    if (o.date.isBefore(anchor)) anchor = o.date;
  }

  // Past scheduled slots, oldest first (today and the future can't break it).
  final slots = <_SlotStatus>[];
  for (var day = anchor; day.isBefore(today);
      day = day.add(const Duration(days: 1))) {
    if (!rule.weekdays.contains(day.weekday)) continue;
    final occurrence = byDate[dayKey(day)];
    if (occurrence == null) {
      slots.add(_SlotStatus.missed);
    } else if (occurrence.isSkipped) {
      slots.add(_SlotStatus.skipped);
    } else if (occurrence.isFullyCompleted) {
      slots.add(_SlotStatus.completed);
    } else {
      slots.add(_SlotStatus.missed);
    }
  }

  final current = _runFromEnd(slots);
  final best = _bestRun(slots);
  final atRisk = slots.isNotEmpty && slots.last == _SlotStatus.missed;

  // Progress for the current period: has today's slot (if any) been done?
  final todaysSlot = rule.weekdays.contains(today.weekday);
  final todaysOccurrence = byDate[dayKey(today)];
  final progressLabel = todaysSlot
      ? (todaysOccurrence?.isFullyCompleted ?? false
          ? 'heute erledigt'
          : 'heute offen')
      : '';

  return StreakInfo(
    current: current,
    best: best,
    atRisk: atRisk,
    progressLabel: progressLabel,
  );
}

/// Length of the streak ending at the most recent slot, applying the grace
/// rule. Skips pass through without counting.
int _runFromEnd(List<_SlotStatus> slots) {
  var count = 0;
  var consecutiveMisses = 0;
  for (var i = slots.length - 1; i >= 0; i--) {
    final slot = slots[i];
    if (slot == _SlotStatus.skipped) continue;
    if (slot == _SlotStatus.completed) {
      count++;
      consecutiveMisses = 0;
    } else {
      consecutiveMisses++;
      if (consecutiveMisses > _graceLimit) return count;
    }
  }
  return count;
}

int _bestRun(List<_SlotStatus> slots) {
  var best = 0;
  var count = 0;
  var consecutiveMisses = 0;
  for (final slot in slots) {
    if (slot == _SlotStatus.skipped) continue;
    if (slot == _SlotStatus.completed) {
      count++;
      consecutiveMisses = 0;
      if (count > best) best = count;
    } else {
      consecutiveMisses++;
      if (consecutiveMisses > _graceLimit) {
        count = 0;
        consecutiveMisses = 0;
      }
    }
  }
  return best;
}

StreakInfo _timesPerWeekStreak(
  TaskDefinition definition,
  List<TaskOccurrence> occurrences,
  DateTime today,
) {
  final target = definition.recurrence.timesPerWeek;
  if (target <= 0) return const StreakInfo.empty();

  final completionsPerWeek = <String, int>{};
  for (final occurrence in occurrences) {
    if (!occurrence.isFullyCompleted) continue;
    final key = isoWeekKey(occurrence.date);
    completionsPerWeek[key] = (completionsPerWeek[key] ?? 0) + 1;
  }

  final currentWeekKey = isoWeekKey(today);
  final currentWeekCount = completionsPerWeek[currentWeekKey] ?? 0;

  // Completed weeks: from the anchor week up to the week before this one.
  var anchor = dateOnly(definition.createdAt);
  for (final occurrence in occurrences) {
    if (occurrence.date.isBefore(anchor)) anchor = occurrence.date;
  }

  final weekMet = <bool>[];
  for (var weekMonday = weekStart(anchor);
      weekMonday.isBefore(weekStart(today));
      weekMonday = weekMonday.add(const Duration(days: 7))) {
    final count = completionsPerWeek[isoWeekKey(weekMonday)] ?? 0;
    weekMet.add(count >= target);
  }

  final current = _runFromEndBool(weekMet);
  final best = _bestRunBool(weekMet);
  final atRisk = weekMet.isNotEmpty && !weekMet.last;

  return StreakInfo(
    current: current,
    best: best,
    atRisk: atRisk,
    progressLabel: '$currentWeekCount / $target diese Woche',
  );
}

int _runFromEndBool(List<bool> met) {
  var count = 0;
  var misses = 0;
  for (var i = met.length - 1; i >= 0; i--) {
    if (met[i]) {
      count++;
      misses = 0;
    } else {
      misses++;
      if (misses > _graceLimit) return count;
    }
  }
  return count;
}

int _bestRunBool(List<bool> met) {
  var best = 0;
  var count = 0;
  var misses = 0;
  for (final ok in met) {
    if (ok) {
      count++;
      misses = 0;
      if (count > best) best = count;
    } else {
      misses++;
      if (misses > _graceLimit) {
        count = 0;
        misses = 0;
      }
    }
  }
  return best;
}
