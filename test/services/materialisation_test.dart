import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/models/task_occurrence.dart';
import 'package:motivation/services/materialisation_service.dart';

import '../support/factories.dart';

void main() {
  final now = DateTime(2026, 9, 7, 9); // Monday morning

  test('creates one occurrence per matching day in the horizon', () {
    final result = runMaterialisation(
      definitions: [fixedDef(weekdays: {1, 3, 5}, createdAt: DateTime(2026, 8, 1))],
      occurrences: const [],
      now: now,
    );
    // 14-day horizon from Mon: Mon/Wed/Fri x2 weeks + next Mon = 7.
    expect(result.upserts.length, 7);
    expect(result.deletions, isEmpty);
    expect(
      result.upserts.every((o) => o.origin == OccurrenceOrigin.recurring),
      isTrue,
    );
  });

  test('is idempotent with no time change', () {
    final first = runMaterialisation(
      definitions: [fixedDef(createdAt: DateTime(2026, 8, 1))],
      occurrences: const [],
      now: now,
    );
    final second = runMaterialisation(
      definitions: [fixedDef(createdAt: DateTime(2026, 8, 1))],
      occurrences: first.upserts,
      now: now,
    );
    expect(second.isEmpty, isTrue);
  });

  test('removing a weekday deletes its future untouched occurrences', () {
    final seeded = runMaterialisation(
      definitions: [fixedDef(weekdays: {1, 3, 5}, createdAt: DateTime(2026, 8, 1))],
      occurrences: const [],
      now: now,
    ).upserts;

    final narrowed = runMaterialisation(
      definitions: [fixedDef(weekdays: {1}, createdAt: DateTime(2026, 8, 1))],
      occurrences: seeded,
      now: now,
    );
    // Wed + Fri occurrences (2 per week + …) are dropped.
    expect(narrowed.deletions, isNotEmpty);
    for (final id in narrowed.deletions) {
      final removed = seeded.firstWhere((o) => o.id == id);
      expect(removed.date.weekday, isNot(DateTime.monday));
    }
  });

  test('does not touch forked or completed occurrences', () {
    final forked = occ(
      id: 'forked',
      date: DateTime(2026, 9, 9), // Wednesday
      sourceDefinitionId: 'def1',
      origin: OccurrenceOrigin.recurring,
      xp: 999,
    ).copyWith(isForked: true);

    final result = runMaterialisation(
      definitions: [fixedDef(weekdays: {1}, createdAt: DateTime(2026, 8, 1))],
      occurrences: [forked],
      now: now,
    );
    expect(result.deletions, isNot(contains('forked')));
  });

  test('timesPerWeek definitions are not auto-dated', () {
    final result = runMaterialisation(
      definitions: [quotaDef(createdAt: DateTime(2026, 8, 1))],
      occurrences: const [],
      now: now,
    );
    expect(result.isEmpty, isTrue);
  });

  test('refreshes a non-forked future occurrence when the definition changes',
      () {
    final seeded = runMaterialisation(
      definitions: [fixedDef(weekdays: {1}, xp: 60, createdAt: DateTime(2026, 8, 1))],
      occurrences: const [],
      now: now,
    ).upserts;

    final refreshed = runMaterialisation(
      definitions: [fixedDef(weekdays: {1}, xp: 90, createdAt: DateTime(2026, 8, 1))],
      occurrences: seeded,
      now: now,
    );
    expect(refreshed.upserts.every((o) => o.xp == 90), isTrue);
    expect(refreshed.upserts, isNotEmpty);
  });

  test('monthly definitions materialise one occurrence on their day, within the longer horizon', () {
    // now = Mon 2026-09-07. Horizon is monthlyHorizonMonths (2) ahead, so
    // this should catch the 15th of both September and October.
    final result = runMaterialisation(
      definitions: [monthlyDef(dayOfMonth: 15, createdAt: DateTime(2026, 8, 1))],
      occurrences: const [],
      now: now,
    );
    expect(result.upserts.length, 2);
    expect(result.upserts.map((o) => o.date.day), everyElement(15));
    expect(result.upserts.map((o) => o.date.month), containsAll([9, 10]));
  });

  test('monthly definition clamps to the last day of a shorter month', () {
    final result = runMaterialisation(
      definitions: [monthlyDef(dayOfMonth: 31, createdAt: DateTime(2026, 1, 1))],
      occurrences: const [],
      now: DateTime(2026, 3, 20), // April has no 31st within the 2-month horizon
    );
    expect(result.upserts, isNotEmpty);
    expect(result.upserts.any((o) => o.date.month == 4 && o.date.day == 30), isTrue);
  });

  test('monthly materialisation is idempotent with no time change', () {
    final first = runMaterialisation(
      definitions: [monthlyDef(createdAt: DateTime(2026, 8, 1))],
      occurrences: const [],
      now: now,
    );
    final second = runMaterialisation(
      definitions: [monthlyDef(createdAt: DateTime(2026, 8, 1))],
      occurrences: first.upserts,
      now: now,
    );
    expect(second.isEmpty, isTrue);
  });
}
