import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/domain/progression.dart';
import 'package:motivation/domain/statistics.dart';
import 'package:motivation/domain/streaks.dart';

import '../support/factories.dart';

void main() {
  final monday = DateTime(2026, 9, 7);
  DateTime d(int add) => monday.add(Duration(days: add));

  group('level curve', () {
    test('steep needs more XP than standard for the same level', () {
      final std = levelProgressFor(700, curve: LevelCurve.standard).level;
      final steep = levelProgressFor(700, curve: LevelCurve.steep).level;
      expect(steep, lessThan(std));
    });

    test('gentle needs less XP', () {
      final gentle = levelProgressFor(700, curve: LevelCurve.gentle).level;
      expect(gentle, greaterThanOrEqualTo(5));
    });
  });

  group('perfect-day bonus', () {
    test('adds the bonus once per perfect day to total XP', () {
      final occurrences = [
        occ(id: 'a', date: d(0), xp: 40, completed: true),
        occ(id: 'b', date: d(0), xp: 60, completed: true),
      ];
      final withBonus = buildStatsSnapshot(
        occurrences: occurrences,
        definitions: const [],
        today: d(1),
        perfectDayBonus: 50,
      );
      final without = buildStatsSnapshot(
        occurrences: occurrences,
        definitions: const [],
        today: d(1),
      );
      expect(without.totalXp, 100);
      expect(withBonus.totalXp, 150);
      expect(withBonus.perfectDaysTotal, 1);
    });

    test('no bonus when a task is still open', () {
      final occurrences = [
        occ(id: 'a', date: d(0), xp: 40, completed: true),
        occ(id: 'b', date: d(0), xp: 60),
      ];
      final snapshot = buildStatsSnapshot(
        occurrences: occurrences,
        definitions: const [],
        today: d(1),
        perfectDayBonus: 50,
      );
      expect(snapshot.totalXp, 40);
      expect(snapshot.perfectDaysTotal, 0);
    });
  });

  group('streak protection off (graceLimit 0)', () {
    test('a single missed slot breaks the streak immediately', () {
      final definition = fixedDef(
        weekdays: {1, 3, 5},
        createdAt: DateTime(2026, 8, 1),
      );
      final occurrences = [
        occ(id: 'a', date: d(0), sourceDefinitionId: 'def1', completed: true),
        // Wednesday d(2) missing
      ];
      final withGrace = computeStreak(
        definition: definition,
        occurrences: occurrences,
        today: d(4),
        graceLimit: 1,
      );
      final noGrace = computeStreak(
        definition: definition,
        occurrences: occurrences,
        today: d(4),
        graceLimit: 0,
      );
      expect(withGrace.current, 1);
      expect(noGrace.current, 0);
    });
  });

  group('computePeriodStats', () {
    test('week bars have 7 buckets and count completions', () {
      final occurrences = [
        occ(id: 'a', date: monday, completed: true),
        occ(id: 'b', date: monday, completed: true),
        occ(id: 'c', date: d(2), completed: true),
      ];
      final stats = computePeriodStats(
        occurrences: occurrences,
        today: d(3),
        period: StatsPeriod.woche,
      );
      expect(stats.bars.length, 7);
      expect(stats.bars[0], 2);
      expect(stats.bars[2], 1);
      expect(stats.tasksDone, 3);
    });
  });
}
