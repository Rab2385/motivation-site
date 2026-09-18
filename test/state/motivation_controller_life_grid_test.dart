import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/data/motivation_database.dart';
import 'package:motivation/domain/life_grid.dart';
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

  test('seeds the eight life-area categories, renaming existing ones and adding the new ones', () async {
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
  });

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

  test('marks "Development hardware acquired" achieved immediately and awards its XP', () async {
    final controller = MotivationController(db);
    await controller.initialize();

    final hardware = controller.milestones
        .firstWhere((m) => m.id == LifeGridIds.milestoneHardware);
    expect(hardware.status, GoalStatus.achieved);
    expect(hardware.awardedOccurrenceId, isNotNull);

    final others = controller.milestones
        .where((m) => m.id != LifeGridIds.milestoneHardware);
    expect(others, isNotEmpty);
    expect(others.every((m) => m.status == GoalStatus.inProgress), isTrue);
  });

  test('does not duplicate or reset anything on a second initialize (simulated relaunch)', () async {
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
  });
}
