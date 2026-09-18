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

/// Number of days ahead that fixed-weekday occurrences are kept materialised.
const int materialisationHorizonDays = 14;

/// Number of months ahead that monthly occurrences are kept materialised —
/// deliberately more than [materialisationHorizonDays] covers, since a
/// monthly review's date can fall further out than 14 days.
const int monthlyHorizonMonths = 2;

/// Derives concrete [TaskOccurrence]s from fixed-weekday and monthly
/// [TaskDefinition]s for the rolling horizon. Idempotent: running it twice
/// with no time change yields an empty result.
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

  final dated = {
    for (final definition in definitions)
      if (definition.isActive &&
          (definition.recurrence.kind == RecurrenceKind.fixedWeekdays ||
              definition.recurrence.kind == RecurrenceKind.monthly))
        definition.id: definition,
  };

  for (final definition in dated.values) {
    final anchor = dateOnly(definition.createdAt);
    final end = definition.recurrence.isMonthly
        ? DateTime(today.year, today.month + monthlyHorizonMonths, today.day)
        : horizonEnd;

    for (final day in daysInRange(today, end)) {
      if (day.isBefore(anchor)) continue;
      if (!definition.recurrence.occursOn(day)) continue;

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
          section: definition.section,
          categoryId: definition.categoryId,
          difficulty: definition.difficulty,
          clearDifficulty: definition.difficulty == null,
          xp: definition.xp,
          target: definition.target,
          clearTarget: definition.target == null,
          priority: definition.priority,
          isBonus: definition.isBonus,
          updatedAt: now,
        ));
      }
    }
  }

  // Drop future auto-occurrences the definition no longer schedules.
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

    final definition = dated[defId];
    final stillScheduled =
        definition != null && definition.recurrence.occursOn(occurrence.date);
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
    section: definition.section,
    categoryId: definition.categoryId,
    difficulty: definition.difficulty,
    xp: definition.xp,
    target: definition.target,
    priority: definition.priority,
    isBonus: definition.isBonus,
    origin: OccurrenceOrigin.recurring,
    sourceDefinitionId: definition.id,
    createdAt: now,
    updatedAt: now,
  );
}

bool _differsFromDefinition(TaskOccurrence occurrence, TaskDefinition d) {
  return occurrence.title != d.title ||
      occurrence.note != d.note ||
      occurrence.section != d.section ||
      occurrence.categoryId != d.categoryId ||
      occurrence.difficulty != d.difficulty ||
      occurrence.xp != d.xp ||
      occurrence.target != d.target ||
      occurrence.priority != d.priority ||
      occurrence.isBonus != d.isBonus;
}
