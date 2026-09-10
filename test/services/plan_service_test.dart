import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/data/motivation_database.dart';
import 'package:motivation/models/proposal.dart';
import 'package:motivation/models/recurrence_rule.dart';
import 'package:motivation/models/reward.dart';
import 'package:motivation/models/task_category.dart';
import 'package:motivation/models/task_definition.dart';
import 'package:motivation/models/task_occurrence.dart';
import 'package:motivation/models/week_template.dart';
import 'package:motivation/services/plan_service.dart';
import 'package:motivation/util/dates.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late MotivationDatabase db;
  late List<TaskCategory> categories;
  late List<TaskDefinition> definitions;
  late List<TaskOccurrence> occurrences;
  late List<WeekTemplate> templates;
  late List<Proposal> proposals;
  late List<Reward> rewards;
  late PlanService plan;

  final monday = weekStart(DateTime.now()).add(const Duration(days: 7));
  DateTime day(int add) => monday.add(Duration(days: add));

  setUp(() {
    db = MotivationDatabase.withFactory(newDatabaseFactoryMemory(), 'test.db');
    categories = [...TaskCategory.defaults()];
    definitions = [];
    occurrences = [];
    templates = [];
    proposals = [];
    rewards = [];
    plan = PlanService(
      database: db,
      categories: categories,
      definitions: definitions,
      occurrences: occurrences,
      templates: templates,
      proposals: proposals,
      rewards: rewards,
    );
  });

  test('addOneOff persists and appears in the list', () async {
    await plan.addOneOff(
      date: day(0),
      title: 'Lesen',
      categoryId: 'lernen',
      xp: 40,
    );
    expect(occurrences, hasLength(1));
    expect(occurrences.single.origin, OccurrenceOrigin.oneOff);

    final reloaded = await db.loadAll();
    expect(reloaded.occurrences, hasLength(1));
  });

  test('createRecurring materialises occurrences', () async {
    await plan.createRecurring(
      title: 'Workout',
      categoryId: 'fitness',
      xp: 60,
      recurrence: RecurrenceRule.fixedWeekdays({monday.weekday}),
    );
    expect(definitions, hasLength(1));
    expect(occurrences.where((o) => o.isRecurring), isNotEmpty);
  });

  test('attach thisDateOnly adds a forked extra without changing the schedule',
      () async {
    await plan.createRecurring(
      title: 'Workout',
      categoryId: 'fitness',
      xp: 60,
      recurrence: RecurrenceRule.fixedWeekdays({DateTime.monday}),
    );
    final def = definitions.single;
    final thursday = day(3);

    await plan.attachDefinitionToDate(
      definitionId: def.id,
      date: thursday,
      scope: AttachScope.thisDateOnly,
    );

    final extra = occurrences.firstWhere((o) => o.dateKey == dayKey(thursday));
    expect(extra.isForked, isTrue);
    expect(definitions.single.recurrence.weekdays, {DateTime.monday});
  });

  test('attach everyWeekdayFromNow merges the weekday into the schedule',
      () async {
    await plan.createRecurring(
      title: 'Workout',
      categoryId: 'fitness',
      xp: 60,
      recurrence: RecurrenceRule.fixedWeekdays({DateTime.monday}),
    );
    final def = definitions.single;

    await plan.attachDefinitionToDate(
      definitionId: def.id,
      date: day(2), // Wednesday
      scope: AttachScope.everyWeekdayFromNow,
    );

    expect(
      definitions.single.recurrence.weekdays,
      containsAll(<int>{DateTime.monday, DateTime.wednesday}),
    );
  });

  test('removing a scheduled recurring occurrence turns it into a skip',
      () async {
    await plan.createRecurring(
      title: 'Workout',
      categoryId: 'fitness',
      xp: 60,
      recurrence: RecurrenceRule.fixedWeekdays({monday.weekday}),
    );
    final target = occurrences.firstWhere((o) => o.dateKey == dayKey(monday));

    await plan.removeOccurrence(target.id);

    final after = occurrences.firstWhere((o) => o.id == target.id);
    expect(after.isSkipped, isTrue);
    expect(occurrences.any((o) => o.id == target.id), isTrue);
  });

  test('removing a one-off deletes it', () async {
    await plan.addOneOff(
        date: day(0), title: 'Einmalig', categoryId: 'lernen', xp: 20);
    final id = occurrences.single.id;
    await plan.removeOccurrence(id);
    expect(occurrences, isEmpty);
  });

  test('editing a recurring occurrence forks it', () async {
    await plan.createRecurring(
      title: 'Workout',
      categoryId: 'fitness',
      xp: 60,
      recurrence: RecurrenceRule.fixedWeekdays({monday.weekday}),
    );
    final target = occurrences.firstWhere((o) => o.dateKey == dayKey(monday));
    await plan.editOccurrence(target.id, xp: 100);
    final after = occurrences.firstWhere((o) => o.id == target.id);
    expect(after.xp, 100);
    expect(after.isForked, isTrue);
  });

  test('moving a scheduled recurring occurrence skips source, one-off on target',
      () async {
    await plan.createRecurring(
      title: 'Workout',
      categoryId: 'fitness',
      xp: 60,
      recurrence: RecurrenceRule.fixedWeekdays({monday.weekday}),
    );
    final source = occurrences.firstWhere((o) => o.dateKey == dayKey(monday));
    await plan.moveOccurrence(source.id, day(1));

    expect(occurrences.firstWhere((o) => o.id == source.id).isSkipped, isTrue);
    final moved = occurrences.firstWhere((o) => o.dateKey == dayKey(day(1)));
    expect(moved.origin, OccurrenceOrigin.oneOff);
    expect(moved.sourceDefinitionId, isNull);
  });

  test('copyOccurrence always makes a detached one-off', () async {
    await plan.addOneOff(
        date: day(0), title: 'Coden', categoryId: 'coding', xp: 50);
    final id = occurrences.single.id;
    await plan.copyOccurrence(id, day(2));
    expect(occurrences, hasLength(2));
    final copy = occurrences.firstWhere((o) => o.dateKey == dayKey(day(2)));
    expect(copy.origin, OccurrenceOrigin.oneOff);
    expect(copy.title, 'Coden');
  });

  test('partial completion pro-rates XP', () async {
    await plan.addOneOff(
        date: day(0), title: 'Lesen', categoryId: 'lernen', xp: 40);
    final id = occurrences.single.id;
    await plan.complete(id, fraction: 0.5);
    expect(occurrences.single.completion!.awardedXp, 20);
    expect(occurrences.single.isFullyCompleted, isFalse);
  });

  test('editAwardedXp corrects a past completion', () async {
    await plan.addOneOff(
        date: day(0), title: 'Lesen', categoryId: 'lernen', xp: 40);
    final id = occurrences.single.id;
    await plan.complete(id);
    await plan.editAwardedXp(id, 10);
    expect(occurrences.single.completion!.awardedXp, 10);
  });

  group('week templates', () {
    test('save then apply recreates the tasks on the target week', () async {
      await plan.addOneOff(
          date: day(0), title: 'Workout', categoryId: 'fitness', xp: 60);
      await plan.addOneOff(
          date: day(1), title: 'Lesen', categoryId: 'lernen', xp: 40);

      final template = await plan.saveWeekAsTemplate(
          name: 'Standardwoche', weekStartDate: monday);
      expect(template.entries, hasLength(2));

      final targetWeek = monday.add(const Duration(days: 7));
      final result = await plan.applyTemplate(
          templateId: template.id, weekStartDate: targetWeek);
      expect(result.added, 2);
      expect(result.skipped, 0);
      expect(
        occurrences.where((o) => o.date.isAfter(day(6))).length,
        2,
      );
    });

    test('apply skips a normalised-title + category duplicate', () async {
      await plan.addOneOff(
          date: day(0), title: 'Workout', categoryId: 'fitness', xp: 60);
      final template = await plan.saveWeekAsTemplate(
          name: 'W', weekStartDate: monday);

      // Pre-seed the same task (different spacing/case) on the same week again.
      await plan.addOneOff(
          date: day(0), title: '  workout ', categoryId: 'fitness', xp: 10);

      final result = await plan.applyTemplate(
          templateId: template.id, weekStartDate: monday);
      expect(result.added, 0);
      expect(result.skipped, 1);
    });
  });

  group('rewards', () {
    test('redeem is blocked until the reward is unlocked', () async {
      await plan.addReward(
        title: 'Gaming',
        description: '',
        iconKey: 'game',
        requiredLevel: 4,
      );
      final id = rewards.single.id;

      expect(await plan.redeemReward(id, 1), isFalse);
      expect(rewards.single.redeemedCount, 0);

      expect(await plan.redeemReward(id, 4), isTrue);
      expect(rewards.single.redeemedCount, 1);
      expect(rewards.single.lastRedeemedAt, isNotNull);
    });

    test('reward survives a database round-trip', () async {
      await plan.addReward(
        title: 'Kaffee',
        description: 'Auszeit',
        iconKey: 'coffee',
        requiredLevel: 1,
      );
      final reloaded = await db.loadAll();
      expect(reloaded.rewards.single.title, 'Kaffee');
      expect(reloaded.rewards.single.requiredLevel, 1);
    });
  });

  test('apply(Proposal) runs its operations through the write path', () async {
    final proposal = Proposal(
      id: 'p1',
      source: 'ai:test',
      rationale: 'Testplan',
      createdAt: DateTime.now(),
      operations: [
        PlanOperation(
          kind: PlanOperationKind.addOneOff,
          targetDateKey: dayKey(day(0)),
          payload: const {
            'title': 'Journaling',
            'categoryId': 'achtsamkeit',
            'xp': 30,
          },
        ),
      ],
    );
    await plan.stageProposal(proposal);
    await plan.apply('p1');

    expect(occurrences.any((o) => o.title == 'Journaling'), isTrue);
    expect(proposals.single.status, ProposalStatus.approved);
  });
}
