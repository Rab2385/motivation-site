import '../models/recurrence_rule.dart';
import '../models/task_definition.dart';
import '../models/task_occurrence.dart';
import '../util/dates.dart';
import '../util/id.dart';

/// The result of a materialisation pass: rows to upsert and rows to delete.
/// Pure data so the pass itself can be unit-tested without a database.
class MaterialisationResult {
  const MaterialisationResult({required this.upserts, required this.deletions});

  final List<TaskOccurrence> upserts;
  final List<String> deletions;

  bool get isEmpty => upserts.isEmpty && deletions.isEmpty;
}

/// Number of days ahead that recurring occurrences are kept materialised.
const int materialisationHorizonDays = 14;

/// Derives concrete [TaskOccurrence]s from fixed-weekday [TaskDefinition]s for
/// the rolling horizon. Idempotent: running it twice with no time change
/// yields an empty result.
MaterialisationResult runMaterialisation({
  required List<TaskDefinition> definitions,
  required List<TaskOccurrence> occurrences,
  required DateTime now,
}) {
  final today = dateOnly(now);
  final horizonEnd = today.add(const Duration(days: materialisationHorizonDays));

  final upserts = <TaskOccurrence>[];
  final deletions = <String>[];

  // Index existing recurring occurrences by (definitionId, dateKey).
  final byDefAndDate = <String, TaskOccurrence>{};
  for (final occurrence in occurrences) {
    final defId = occurrence.sourceDefinitionId;
    if (defId == null) continue;
    byDefAndDate['$defId|${occurrence.dateKey}'] = occurrence;
  }

  final activeFixed = {
    for (final definition in definitions)
      if (definition.isActive &&
          definition.recurrence.kind == RecurrenceKind.fixedWeekdays)
        definition.id: definition,
  };

  // 1–3: ensure occurrences across the horizon.
  for (final definition in activeFixed.values) {
    final anchor = dateOnly(definition.createdAt);
    for (final day in daysInRange(today, horizonEnd)) {
      if (day.isBefore(anchor)) continue;
      if (!definition.recurrence.weekdays.contains(day.weekday)) continue;

      final key = '${definition.id}|${dayKey(day)}';
      final existing = byDefAndDate[key];

      if (existing == null) {
        upserts.add(_fromDefinition(definition, day, now));
        continue;
      }

      final canRefresh = !existing.isForked &&
          !existing.isCompleted &&
          !existing.isSkipped &&
          !day.isBefore(today);
      if (canRefresh && _differsFromDefinition(existing, definition)) {
        upserts.add(existing.copyWith(
          title: definition.title,
          note: definition.note,
          categoryId: definition.categoryId,
          difficulty: definition.difficulty,
          clearDifficulty: definition.difficulty == null,
          xp: definition.xp,
          updatedAt: now,
        ));
      }
    }
  }

  // 4: drop future auto-occurrences the definition no longer schedules.
  for (final occurrence in occurrences) {
    final defId = occurrence.sourceDefinitionId;
    if (defId == null) continue;
    if (occurrence.origin != OccurrenceOrigin.recurring) continue;
    if (occurrence.isForked ||
        occurrence.isCompleted ||
        occurrence.isSkipped) {
      continue;
    }
    if (occurrence.date.isBefore(today)) continue;

    final definition = activeFixed[defId];
    final stillScheduled = definition != null &&
        definition.recurrence.weekdays.contains(occurrence.date.weekday);
    if (!stillScheduled) deletions.add(occurrence.id);
  }

  return MaterialisationResult(upserts: upserts, deletions: deletions);
}

TaskOccurrence _fromDefinition(
  TaskDefinition definition,
  DateTime day,
  DateTime now,
) {
  return TaskOccurrence(
    id: newId('occ'),
    dateKey: dayKey(day),
    title: definition.title,
    note: definition.note,
    categoryId: definition.categoryId,
    difficulty: definition.difficulty,
    xp: definition.xp,
    origin: OccurrenceOrigin.recurring,
    sourceDefinitionId: definition.id,
    createdAt: now,
    updatedAt: now,
  );
}

bool _differsFromDefinition(TaskOccurrence occurrence, TaskDefinition d) {
  return occurrence.title != d.title ||
      occurrence.note != d.note ||
      occurrence.categoryId != d.categoryId ||
      occurrence.difficulty != d.difficulty ||
      occurrence.xp != d.xp;
}
