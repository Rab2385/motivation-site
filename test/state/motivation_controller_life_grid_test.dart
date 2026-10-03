import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/data/motivation_database.dart';
import 'package:motivation/domain/life_grid.dart';
import 'package:motivation/models/recurrence_rule.dart';
import 'package:motivation/models/task_definition.dart';
import 'package:motivation/pages/life_grid_page.dart';
import 'package:motivation/state/motivation_controller.dart';
import 'package:sembast/sembast_memory.dart';

/// Covers the one-time Life Grid seed run by `MotivationController.initialize`:
/// it must add the default daily/weekly/monthly tasks and milestones without
/// touching or duplicating anything, and never re-seed on a later launch.
void main() {
  late MotivationDatabase db;

  setUp(() {
    db = MotivationDatabase.withFactory(newDatabaseFactoryMemory(), 'test.db');
  });

  test(
    'seeds the eight life-area categories, renaming existing ones and adding the new ones',
    () async {
      final controller = MotivationController(db);
      await controller.initialize();

      final byId = {for (final c in controller.categories) c.id: c};
      expect(byId['health']!.isFocusArea, isTrue);
      expect(byId['courage']!.name, 'Courage & Confidence');
      expect(byId['courage']!.isFocusArea, isTrue);
      expect(byId['relationships']!.name, 'Friends & Relationships');
      expect(byId['financial']!.name, 'Financial Freedom');
      expect(byId['work']!.name, 'Career & Meaning');
      expect(byId['learning']!.name, 'Adventure & Learning');
      expect(byId['coding']!.name, 'Creativity & Projects');
      expect(byId['coding']!.isFocusArea, isTrue);
      expect(byId['mindfulness']!.name, 'Happiness & Balance');

      // Non-life-grid categories are untouched.
      expect(byId['fitness']!.name, 'Fitness');
      expect(byId['home']!.name, 'Home');
    },
  );

  test('seeds the default daily, weekly and monthly Life Grid tasks', () async {
    final controller = MotivationController(db);
    await controller.initialize();

    final ids = controller.definitions.map((d) => d.id).toSet();
    for (final id in [
      LifeGridIds.dailyMovement,
      LifeGridIds.balancedMeals,
      LifeGridIds.protectSleep,
      LifeGridIds.decideAct,
      LifeGridIds.mentalReset,
      LifeGridIds.learnOrBuild,
      LifeGridIds.weeklyWorkout,
      LifeGridIds.weeklyLifeReview,
      LifeGridIds.monthlyHealth,
      LifeGridIds.monthlyCreativity,
    ]) {
      expect(ids, contains(id), reason: '$id should be seeded');
    }
  });

  testWidgets('shows an add milestone action on the Life Grid page', (
    tester,
  ) async {
    final controller = MotivationController(db);
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(home: LifeGridPage(controller: controller)),
    );
    await tester.pump();

    expect(find.text('add milestone'), findsOneWidget);
  });

  test(
    'marks "Development hardware acquired" achieved immediately and awards its XP',
    () async {
      final controller = MotivationController(db);
      await controller.initialize();

      final hardware = controller.milestones.firstWhere(
        (m) => m.id == LifeGridIds.milestoneHardware,
      );
      expect(hardware.status, GoalStatus.achieved);
      expect(hardware.awardedOccurrenceId, isNotNull);

      final others = controller.milestones.where(
        (m) => m.id != LifeGridIds.milestoneHardware,
      );
      expect(others, isNotEmpty);
      expect(others.every((m) => m.status == GoalStatus.inProgress), isTrue);
    },
  );

  test(
    'does not duplicate or reset anything on a second initialize (simulated relaunch)',
    () async {
      final first = MotivationController(db);
      await first.initialize();
      final defCountAfterFirst = first.definitions.length;
      final categoryCountAfterFirst = first.categories.length;
      final milestoneCountAfterFirst = first.milestones.length;

      // A user edit that must survive the "relaunch".
      await first.updateCategory('health', name: 'My Health');

      final second = MotivationController(db);
      await second.initialize();

      expect(second.definitions.length, defCountAfterFirst);
      expect(second.categories.length, categoryCountAfterFirst);
      expect(second.milestones.length, milestoneCountAfterFirst);
      expect(
        second.categories.firstWhere((c) => c.id == 'health').name,
        'My Health',
        reason: 'the seed must not silently overwrite a later user edit',
      );
    },
  );

  test('saves and restores the preferred weekly review day', () async {
    final controller = MotivationController(db);
    await controller.initialize();

    await controller.setWeeklyReviewDay(DateTime.friday);
    expect(controller.weeklyReviewDay, DateTime.friday);

    final reloaded = MotivationController(db);
    await reloaded.initialize();
    expect(reloaded.weeklyReviewDay, DateTime.friday);
  });

  test('shows a weekly review as due on the configured day', () async {
    final controller = MotivationController(db);
    await controller.initialize();

    await controller.setWeeklyReviewDay(DateTime.sunday);
    final sunday = DateTime(2026, 9, 20); // Sunday
    final monday = DateTime(2026, 9, 21); // Monday

    expect(controller.isWeeklyReviewDueFor(sunday), isTrue);
    expect(controller.isWeeklyReviewDueFor(monday), isFalse);

    await controller.markWeeklyReviewDone(
      wins: 'did well',
      misses: 'a few misses',
      nextFocus: 'be consistent',
    );

    expect(controller.isWeeklyReviewDueFor(sunday), isFalse);
  });

  test('removes test routine entries permanently on startup', () async {
    final now = DateTime(2026, 9, 18);
    final testDef = TaskDefinition(
      id: 'test_task_1',
      title: 'TEST',
      categoryId: 'general',
      xp: 10,
      recurrence: RecurrenceRule.fixedWeekdays({DateTime.monday}),
      createdAt: now,
      updatedAt: now,
    );
    await db.saveDefinition(testDef);

    final controller = MotivationController(db);
    await controller.initialize();

    expect(
      controller.definitions.any((d) => d.title.toUpperCase() == 'TEST'),
      isFalse,
    );

    final reloaded = MotivationController(db);
    await reloaded.initialize();
    expect(
      reloaded.definitions.any((d) => d.title.toUpperCase() == 'TEST'),
      isFalse,
    );
  });

  test('deletes all duplicate habit definitions with the same title', () async {
    final isolated = MotivationDatabase.withFactory(
      newDatabaseFactoryMemory(),
      'test-dup.db',
    );
    final controller = MotivationController(isolated);

    final now = DateTime(2026, 9, 18);
    final a = TaskDefinition(
      id: 'test_dup_a',
      title: 'TEST',
      categoryId: 'fitness',
      xp: 10,
      recurrence: RecurrenceRule.fixedWeekdays({DateTime.monday}),
      createdAt: now,
      updatedAt: now,
    );
    final b = TaskDefinition(
      id: 'test_dup_b',
      title: 'TEST',
      categoryId: 'fitness',
      xp: 10,
      recurrence: RecurrenceRule.fixedWeekdays({DateTime.tuesday}),
      createdAt: now,
      updatedAt: now,
    );

    await isolated.saveDefinition(a);
    await isolated.saveDefinition(b);
    await controller.initialize();

    expect(
      controller.definitions
          .where((definition) => definition.title.toUpperCase() == 'TEST')
          .length,
      2,
    );

    await controller.deleteDefinition(a.id);

    expect(
      controller.definitions
          .where((definition) => definition.title.toUpperCase() == 'TEST')
          .length,
      0,
    );
  });

  test(
    'builds a time-based greeting with the user name and birthday wishes',
    () async {
      final controller = MotivationController(db);
      await controller.initialize();

      await controller.setUserName('Ada');
      await controller.setUserBirthday(DateTime(1990, 9, 18));

      expect(
        controller.greetingFor(DateTime(2026, 9, 17, 8, 30)),
        'Good morning, Ada!',
      );

      expect(
        controller.greetingFor(DateTime(2026, 9, 18, 15, 30)),
        'Happy Birthday, Ada!',
      );

      await controller.setUserBirthday(null);
      expect(
        controller.greetingFor(DateTime(2026, 9, 18, 15, 30)),
        'Good afternoon, Ada!',
      );
    },
  );
}
