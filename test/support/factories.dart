import 'package:motivation/domain/difficulty.dart';
import 'package:motivation/models/completion.dart';
import 'package:motivation/models/recurrence_rule.dart';
import 'package:motivation/models/task_definition.dart';
import 'package:motivation/models/task_occurrence.dart';
import 'package:motivation/util/dates.dart';

TaskDefinition fixedDef({
  String id = 'def1',
  Set<int> weekdays = const {1, 3, 5},
  int xp = 60,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 1, 1);
  return TaskDefinition(
    id: id,
    title: 'Workout',
    categoryId: 'fitness',
    xp: xp,
    recurrence: RecurrenceRule.fixedWeekdays(weekdays),
    createdAt: now,
    updatedAt: now,
  );
}

TaskDefinition quotaDef({
  String id = 'defq',
  int times = 3,
  int xp = 60,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 1, 1);
  return TaskDefinition(
    id: id,
    title: 'Laufen',
    categoryId: 'fitness',
    xp: xp,
    recurrence: RecurrenceRule.timesPerWeek(times),
    createdAt: now,
    updatedAt: now,
  );
}

TaskOccurrence occ({
  required DateTime date,
  String id = 'occ',
  String? sourceDefinitionId,
  bool completed = false,
  bool skipped = false,
  double fraction = 1.0,
  int xp = 60,
  OccurrenceOrigin origin = OccurrenceOrigin.oneOff,
  String title = 'Workout',
  String categoryId = 'fitness',
  Difficulty? difficulty,
}) {
  return TaskOccurrence(
    id: id,
    dateKey: dayKey(date),
    title: title,
    categoryId: categoryId,
    difficulty: difficulty,
    xp: xp,
    origin: origin,
    sourceDefinitionId: sourceDefinitionId,
    isSkipped: skipped,
    completion: completed
        ? Completion(
            completedAt: date,
            awardedXp: (xp * fraction).round(),
            fraction: fraction,
          )
        : null,
    createdAt: date,
    updatedAt: date,
  );
}
