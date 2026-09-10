import 'package:collection/collection.dart';

import '../data/motivation_database.dart';
import '../domain/difficulty.dart';
import '../domain/progression.dart';
import '../models/completion.dart';
import '../models/proposal.dart';
import '../models/recurrence_rule.dart';
import '../models/task_category.dart';
import '../models/task_definition.dart';
import '../models/task_occurrence.dart';
import '../models/week_template.dart';
import '../util/dates.dart';
import '../util/id.dart';
import 'materialisation_service.dart';

/// How far the planner lets you reach when attaching a recurring task to a
/// day it does not normally fall on.
enum AttachScope { thisDateOnly, everyWeekdayFromNow }

/// Result of applying a [WeekTemplate].
class TemplateApplyResult {
  const TemplateApplyResult({required this.added, required this.skipped});

  final int added;
  final int skipped;
}

/// The single write path for tasks, occurrences, completions and templates.
///
/// Widgets and the controller call this; nothing else writes to
/// [MotivationDatabase]. A future [AssistantGateway] can only build
/// [Proposal]s, which reach these methods exclusively through [apply] after
/// explicit user approval.
///
/// The list instances passed to the constructor are owned by the controller;
/// this service mutates them in place and persists each change. The caller is
/// responsible for notifying listeners afterwards.
class PlanService {
  PlanService({
    required MotivationDatabase database,
    required List<TaskCategory> categories,
    required List<TaskDefinition> definitions,
    required List<TaskOccurrence> occurrences,
    required List<WeekTemplate> templates,
    required List<Proposal> proposals,
  })  : _db = database,
        _categories = categories,
        _definitions = definitions,
        _occurrences = occurrences,
        _templates = templates,
        _proposals = proposals;

  final MotivationDatabase _db;

  // These lists are owned by the controller and passed by reference; the
  // service mutates them in place and persists each change.
  final List<TaskCategory> _categories;
  final List<TaskDefinition> _definitions;
  final List<TaskOccurrence> _occurrences;
  final List<WeekTemplate> _templates;
  final List<Proposal> _proposals;

  DateTime _now() => DateTime.now();

  // ---- One-off tasks ---------------------------------------------------------

  Future<TaskOccurrence> addOneOff({
    required DateTime date,
    required String title,
    required String categoryId,
    required int xp,
    String note = '',
    Difficulty? difficulty,
  }) async {
    final now = _now();
    final occurrence = TaskOccurrence(
      id: newId('occ'),
      dateKey: dayKey(date),
      title: title.trim(),
      note: note.trim(),
      categoryId: categoryId,
      difficulty: difficulty,
      xp: xp,
      origin: OccurrenceOrigin.oneOff,
      createdAt: now,
      updatedAt: now,
    );
    await _putOccurrence(occurrence);
    return occurrence;
  }

  // ---- Recurring definitions ------------------------------------------------

  Future<TaskDefinition> createRecurring({
    required String title,
    required String categoryId,
    required int xp,
    required RecurrenceRule recurrence,
    String note = '',
    Difficulty? difficulty,
  }) async {
    final now = _now();
    final definition = TaskDefinition(
      id: newId('def'),
      title: title.trim(),
      note: note.trim(),
      categoryId: categoryId,
      difficulty: difficulty,
      xp: xp,
      recurrence: recurrence,
      createdAt: now,
      updatedAt: now,
    );
    _definitions.add(definition);
    await _db.saveDefinition(definition);
    await _materialise(now);
    return definition;
  }

  Future<void> editDefinition(
    String definitionId, {
    String? title,
    String? note,
    String? categoryId,
    Difficulty? difficulty,
    bool clearDifficulty = false,
    int? xp,
    RecurrenceRule? recurrence,
    bool? isPaused,
    bool? isArchived,
  }) async {
    final index = _definitions.indexWhere((d) => d.id == definitionId);
    if (index == -1) return;
    final updated = _definitions[index].copyWith(
      title: title?.trim(),
      note: note?.trim(),
      categoryId: categoryId,
      difficulty: difficulty,
      clearDifficulty: clearDifficulty,
      xp: xp,
      recurrence: recurrence,
      isPaused: isPaused,
      isArchived: isArchived,
      updatedAt: _now(),
    );
    _definitions[index] = updated;
    await _db.saveDefinition(updated);
    await _materialise(_now());
  }

  Future<void> deleteDefinition(String definitionId) async {
    _definitions.removeWhere((d) => d.id == definitionId);
    await _db.deleteDefinition(definitionId);

    // Drop its future, untouched occurrences; keep history (completed / past).
    final today = dateOnly(_now());
    final removable = _occurrences
        .where((o) =>
            o.sourceDefinitionId == definitionId &&
            !o.isCompleted &&
            !o.date.isBefore(today))
        .map((o) => o.id)
        .toList();
    await _removeOccurrences(removable);
  }

  /// Attach an existing recurring task to [date].
  ///
  /// [AttachScope.everyWeekdayFromNow] merges that weekday into the schedule;
  /// [AttachScope.thisDateOnly] adds a single extra occurrence and leaves the
  /// schedule alone.
  Future<void> attachDefinitionToDate({
    required String definitionId,
    required DateTime date,
    required AttachScope scope,
  }) async {
    final definition =
        _definitions.where((d) => d.id == definitionId).firstOrNull;
    if (definition == null) return;

    if (definition.recurrence.kind == RecurrenceKind.timesPerWeek) {
      await placeQuotaOccurrence(definitionId: definitionId, date: date);
      return;
    }

    if (scope == AttachScope.everyWeekdayFromNow) {
      await editDefinition(
        definitionId,
        recurrence: definition.recurrence
            .withWeekday(date.weekday, present: true),
      );
      return;
    }

    // Single extra occurrence: forked so materialisation leaves it alone.
    final now = _now();
    final occurrence = TaskOccurrence(
      id: newId('occ'),
      dateKey: dayKey(date),
      title: definition.title,
      note: definition.note,
      categoryId: definition.categoryId,
      difficulty: definition.difficulty,
      xp: definition.xp,
      origin: OccurrenceOrigin.recurring,
      sourceDefinitionId: definition.id,
      isForked: true,
      createdAt: now,
      updatedAt: now,
    );
    await _putOccurrence(occurrence);
  }

  Future<void> placeQuotaOccurrence({
    required String definitionId,
    required DateTime date,
  }) async {
    final definition =
        _definitions.where((d) => d.id == definitionId).firstOrNull;
    if (definition == null) return;
    final now = _now();
    final occurrence = TaskOccurrence(
      id: newId('occ'),
      dateKey: dayKey(date),
      title: definition.title,
      note: definition.note,
      categoryId: definition.categoryId,
      difficulty: definition.difficulty,
      xp: definition.xp,
      origin: OccurrenceOrigin.quota,
      sourceDefinitionId: definition.id,
      isForked: true,
      createdAt: now,
      updatedAt: now,
    );
    await _putOccurrence(occurrence);
  }

  // ---- Occurrence editing --------------------------------------------------

  Future<void> editOccurrence(
    String occurrenceId, {
    String? title,
    String? note,
    String? categoryId,
    Difficulty? difficulty,
    bool clearDifficulty = false,
    int? xp,
  }) async {
    final index = _occurrences.indexWhere((o) => o.id == occurrenceId);
    if (index == -1) return;
    final updated = _occurrences[index].copyWith(
      title: title?.trim(),
      note: note?.trim(),
      categoryId: categoryId,
      difficulty: difficulty,
      clearDifficulty: clearDifficulty,
      xp: xp,
      // Editing a recurring occurrence forks it from its definition.
      isForked: _occurrences[index].isRecurring ? true : null,
      updatedAt: _now(),
    );
    _occurrences[index] = updated;
    await _db.saveOccurrence(updated);
  }

  Future<void> skipOccurrence(String occurrenceId) =>
      _setSkipped(occurrenceId, true);

  Future<void> unskipOccurrence(String occurrenceId) =>
      _setSkipped(occurrenceId, false);

  Future<void> _setSkipped(String occurrenceId, bool skipped) async {
    final index = _occurrences.indexWhere((o) => o.id == occurrenceId);
    if (index == -1) return;
    final updated = _occurrences[index].copyWith(
      isSkipped: skipped,
      clearCompletion: skipped,
      updatedAt: _now(),
    );
    _occurrences[index] = updated;
    await _db.saveOccurrence(updated);
  }

  /// Delete from the planner. A scheduled recurring occurrence becomes a
  /// streak-neutral skip; everything else is removed outright.
  Future<void> removeOccurrence(String occurrenceId) async {
    final occurrence =
        _occurrences.where((o) => o.id == occurrenceId).firstOrNull;
    if (occurrence == null) return;

    if (_isScheduledRecurring(occurrence)) {
      await skipOccurrence(occurrenceId);
    } else {
      await _removeOccurrences([occurrenceId]);
    }
  }

  Future<void> moveOccurrence(String occurrenceId, DateTime toDate) async {
    final index = _occurrences.indexWhere((o) => o.id == occurrenceId);
    if (index == -1) return;
    final occurrence = _occurrences[index];

    if (_isScheduledRecurring(occurrence)) {
      // Skip the source slot and drop a detached one-off on the target.
      await skipOccurrence(occurrenceId);
      await addOneOff(
        date: toDate,
        title: occurrence.title,
        note: occurrence.note,
        categoryId: occurrence.categoryId,
        difficulty: occurrence.difficulty,
        xp: occurrence.xp,
      );
      return;
    }

    final updated = occurrence.copyWith(
      dateKey: dayKey(toDate),
      updatedAt: _now(),
    );
    _occurrences[index] = updated;
    await _db.saveOccurrence(updated);
  }

  Future<TaskOccurrence> copyOccurrence(
    String occurrenceId,
    DateTime toDate,
  ) async {
    final source =
        _occurrences.where((o) => o.id == occurrenceId).firstOrNull;
    if (source == null) {
      throw StateError('Occurrence $occurrenceId not found');
    }
    return addOneOff(
      date: toDate,
      title: source.title,
      note: source.note,
      categoryId: source.categoryId,
      difficulty: source.difficulty,
      xp: source.xp,
    );
  }

  // ---- Completion --------------------------------------------------------

  Future<void> complete(
    String occurrenceId, {
    double fraction = 1.0,
    String note = '',
  }) async {
    final index = _occurrences.indexWhere((o) => o.id == occurrenceId);
    if (index == -1) return;
    final occurrence = _occurrences[index];
    final clamped = fraction.clamp(0.05, 1.0);
    final awardedXp = (occurrence.xp * clamped).round();

    final updated = occurrence.copyWith(
      isSkipped: false,
      completion: Completion(
        completedAt: _now(),
        awardedXp: awardedXp,
        fraction: clamped,
        note: note.trim(),
      ),
      updatedAt: _now(),
    );
    _occurrences[index] = updated;
    await _db.saveOccurrence(updated);
  }

  Future<void> undoComplete(String occurrenceId) async {
    final index = _occurrences.indexWhere((o) => o.id == occurrenceId);
    if (index == -1) return;
    final updated = _occurrences[index].copyWith(
      clearCompletion: true,
      updatedAt: _now(),
    );
    _occurrences[index] = updated;
    await _db.saveOccurrence(updated);
  }

  /// Correct the XP recorded for a past completion. Level and stats are
  /// derived from these snapshots, so this is the one supported past-day edit.
  Future<void> editAwardedXp(String occurrenceId, int awardedXp) async {
    final index = _occurrences.indexWhere((o) => o.id == occurrenceId);
    if (index == -1) return;
    final completion = _occurrences[index].completion;
    if (completion == null) return;
    final updated = _occurrences[index].copyWith(
      completion: completion.copyWith(awardedXp: awardedXp),
      updatedAt: _now(),
    );
    _occurrences[index] = updated;
    await _db.saveOccurrence(updated);
  }

  // ---- Week templates --------------------------------------------------------

  Future<WeekTemplate> saveWeekAsTemplate({
    required String name,
    required DateTime weekStartDate,
  }) async {
    final monday = weekStart(weekStartDate);
    final sunday = monday.add(const Duration(days: 6));
    final entries = <WeekTemplateEntry>[];
    for (final occurrence in _occurrences) {
      if (occurrence.isSkipped) continue;
      final date = occurrence.date;
      if (date.isBefore(monday) || date.isAfter(sunday)) continue;
      entries.add(WeekTemplateEntry(
        weekday: date.weekday,
        title: occurrence.title,
        note: occurrence.note,
        categoryId: occurrence.categoryId,
        difficulty: occurrence.difficulty,
        xp: occurrence.xp,
      ));
    }
    final template = WeekTemplate(
      id: newId('tpl'),
      name: name.trim(),
      entries: entries,
      createdAt: _now(),
    );
    _templates.add(template);
    await _db.saveTemplate(template);
    return template;
  }

  /// Apply a template to the week starting [weekStartDate].
  ///
  /// This is the only place normalised-title matching runs: an entry whose
  /// `normaliseTitle(title)` + `categoryId` already exists as an occurrence on
  /// the target day is skipped.
  Future<TemplateApplyResult> applyTemplate({
    required String templateId,
    required DateTime weekStartDate,
  }) async {
    final template =
        _templates.where((t) => t.id == templateId).firstOrNull;
    if (template == null) {
      return const TemplateApplyResult(added: 0, skipped: 0);
    }
    final monday = weekStart(weekStartDate);
    var added = 0;
    var skipped = 0;

    for (final entry in template.entries) {
      final targetDate = monday.add(Duration(days: entry.weekday - 1));
      final key = dayKey(targetDate);
      final duplicate = _occurrences.any((o) =>
          o.dateKey == key &&
          !o.isSkipped &&
          o.categoryId == entry.categoryId &&
          normaliseTitle(o.title) == normaliseTitle(entry.title));
      if (duplicate) {
        skipped++;
        continue;
      }
      await addOneOff(
        date: targetDate,
        title: entry.title,
        note: entry.note,
        categoryId: entry.categoryId,
        difficulty: entry.difficulty,
        xp: entry.xp,
      );
      added++;
    }
    return TemplateApplyResult(added: added, skipped: skipped);
  }

  Future<void> deleteTemplate(String templateId) async {
    _templates.removeWhere((t) => t.id == templateId);
    await _db.deleteTemplate(templateId);
  }

  // ---- Categories --------------------------------------------------------

  Future<void> addCategory({
    required String name,
    required int colorValue,
    required String iconKey,
  }) async {
    final category = TaskCategory(
      id: newId('cat'),
      name: name.trim(),
      colorValue: colorValue,
      iconKey: iconKey,
      sortOrder: _categories.length,
    );
    _categories.add(category);
    await _db.saveCategory(category);
  }

  Future<void> updateCategory(
    String id, {
    String? name,
    int? colorValue,
    String? iconKey,
    bool? isArchived,
  }) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final updated = _categories[index].copyWith(
      name: name?.trim(),
      colorValue: colorValue,
      iconKey: iconKey,
      isArchived: isArchived,
    );
    _categories[index] = updated;
    await _db.saveCategory(updated);
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    await _db.deleteCategory(id);
  }

  // ---- Proposals (AI seam) ------------------------------------------------

  /// Persist a proposal produced by a non-user actor so the user can review
  /// it. The only entry point for AI-originated change.
  Future<void> stageProposal(Proposal proposal) async {
    _proposals.add(proposal);
    await _db.saveProposal(proposal);
  }

  Future<void> rejectProposal(String proposalId) async {
    final index = _proposals.indexWhere((p) => p.id == proposalId);
    if (index == -1) return;
    _proposals[index] =
        _proposals[index].copyWith(status: ProposalStatus.rejected);
    await _db.saveProposal(_proposals[index]);
  }

  /// Execute an approved proposal's operations through the normal write path.
  Future<void> apply(String proposalId) async {
    final index = _proposals.indexWhere((p) => p.id == proposalId);
    if (index == -1) return;
    final proposal = _proposals[index];

    for (final op in proposal.operations) {
      await _applyOperation(op);
    }

    _proposals[index] = proposal.copyWith(status: ProposalStatus.approved);
    await _db.saveProposal(_proposals[index]);
  }

  Future<void> _applyOperation(PlanOperation op) async {
    final payload = op.payload;
    String str(String k, [String fallback = '']) =>
        payload[k] as String? ?? fallback;
    int intOf(String k, [int fallback = 0]) =>
        (payload[k] as num?)?.toInt() ?? fallback;

    switch (op.kind) {
      case PlanOperationKind.addOneOff:
        await addOneOff(
          date: parseDayKey(op.targetDateKey!),
          title: str('title'),
          note: str('note'),
          categoryId: str('categoryId'),
          xp: intOf('xp'),
          difficulty: Difficulty.fromName(payload['difficulty'] as String?),
        );
      case PlanOperationKind.editOccurrence:
        await editOccurrence(
          op.occurrenceId!,
          title: payload.containsKey('title') ? str('title') : null,
          note: payload.containsKey('note') ? str('note') : null,
          categoryId:
              payload.containsKey('categoryId') ? str('categoryId') : null,
          xp: payload.containsKey('xp') ? intOf('xp') : null,
        );
      case PlanOperationKind.moveOccurrence:
        await moveOccurrence(op.occurrenceId!, parseDayKey(op.targetDateKey!));
      case PlanOperationKind.removeOccurrence:
        await removeOccurrence(op.occurrenceId!);
      case PlanOperationKind.skipOccurrence:
        await skipOccurrence(op.occurrenceId!);
      case PlanOperationKind.createRecurring:
        await createRecurring(
          title: str('title'),
          note: str('note'),
          categoryId: str('categoryId'),
          xp: intOf('xp'),
          difficulty: Difficulty.fromName(payload['difficulty'] as String?),
          recurrence: RecurrenceRule.fromMap(
            (payload['recurrence'] as Map).cast<String, Object?>(),
          ),
        );
      case PlanOperationKind.placeQuotaOccurrence:
        await placeQuotaOccurrence(
          definitionId: op.definitionId!,
          date: parseDayKey(op.targetDateKey!),
        );
    }
  }

  // ---- Internals --------------------------------------------------------

  bool _isScheduledRecurring(TaskOccurrence occurrence) {
    if (occurrence.origin != OccurrenceOrigin.recurring) return false;
    final definition = _definitions
        .where((d) => d.id == occurrence.sourceDefinitionId)
        .firstOrNull;
    if (definition == null) return false;
    return definition.recurrence.kind == RecurrenceKind.fixedWeekdays &&
        definition.recurrence.weekdays.contains(occurrence.date.weekday);
  }

  Future<void> _materialise(DateTime now) async {
    final result = runMaterialisation(
      definitions: _definitions,
      occurrences: _occurrences,
      now: now,
    );
    if (result.isEmpty) return;

    for (final occurrence in result.upserts) {
      final index = _occurrences.indexWhere((o) => o.id == occurrence.id);
      if (index == -1) {
        _occurrences.add(occurrence);
      } else {
        _occurrences[index] = occurrence;
      }
    }
    _occurrences.removeWhere((o) => result.deletions.contains(o.id));

    await _db.saveOccurrences(result.upserts);
    await _db.deleteOccurrences(result.deletions);
  }

  Future<void> _putOccurrence(TaskOccurrence occurrence) async {
    final index = _occurrences.indexWhere((o) => o.id == occurrence.id);
    if (index == -1) {
      _occurrences.add(occurrence);
    } else {
      _occurrences[index] = occurrence;
    }
    await _db.saveOccurrence(occurrence);
  }

  Future<void> _removeOccurrences(List<String> ids) async {
    if (ids.isEmpty) return;
    _occurrences.removeWhere((o) => ids.contains(o.id));
    await _db.deleteOccurrences(ids);
  }

  /// Runs a materialisation pass on demand (startup, day rollover).
  Future<void> refreshMaterialisation() => _materialise(_now());
}

/// Suggested XP for a fresh task with the given difficulty (nullable).
int suggestedXp(Difficulty? difficulty) =>
    difficulty?.defaultXp ?? Difficulty.mittel.defaultXp;

/// Convenience re-export so callers don't import progression just for this.
int levelForXp(int totalXp) => levelProgressFor(totalXp).level;
