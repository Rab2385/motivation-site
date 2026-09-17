import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/domain/overview_stats.dart';

import '../support/factories.dart';

void main() {
  final monday = DateTime(2026, 9, 7);
  DateTime d(int add) => monday.add(Duration(days: add));

  group('dayCompletionRate', () {
    test('null when nothing was due', () {
      expect(dayCompletionRate(const [], monday), isNull);
    });

    test('ratio of fully-completed, non-skipped occurrences', () {
      final occurrences = [
        occ(id: 'a', date: monday, completed: true),
        occ(id: 'b', date: monday, completed: false),
        occ(id: 'c', date: monday, skipped: true),
      ];
      // 1 completed out of 2 due (the skip doesn't count as due).
      expect(dayCompletionRate(occurrences, monday), 0.5);
    });
  });

  group('computeGoalStreak', () {
    test('counts consecutive days at/above the goal, ending in a run', () {
      final occurrences = [
        occ(id: 'a', date: d(0), completed: true),
        occ(id: 'b', date: d(1), completed: true),
        occ(id: 'c', date: d(2), completed: true),
      ];
      final streak = computeGoalStreak(
        occurrences: occurrences,
        today: d(3),
        goalFraction: 0.6,
        since: d(0),
      );
      expect(streak.current, 3);
      expect(streak.best, 3);
    });

    test('a day with nothing due is neutral, not a break', () {
      final occurrences = [
        occ(id: 'a', date: d(0), completed: true),
        // d(1) has nothing scheduled at all.
        occ(id: 'b', date: d(2), completed: true),
      ];
      final streak = computeGoalStreak(
        occurrences: occurrences,
        today: d(3),
        goalFraction: 0.6,
        since: d(0),
      );
      expect(streak.current, 2);
    });

    test('missing the goal breaks the current streak', () {
      final occurrences = [
        occ(id: 'a', date: d(0), completed: true),
        occ(id: 'b', date: d(1), completed: false), // due, not done: 0%
        occ(id: 'c', date: d(2), completed: true),
      ];
      final streak = computeGoalStreak(
        occurrences: occurrences,
        today: d(3),
        goalFraction: 0.6,
        since: d(0),
      );
      expect(streak.current, 1);
      expect(streak.best, 1);
    });
  });

  group('computeOverviewStats', () {
    test('reports daily goal hits and total completions over the window', () {
      final occurrences = [
        occ(id: 'a', date: d(0), completed: true),
        occ(id: 'b', date: d(1), completed: true),
        occ(id: 'c', date: d(1), completed: false),
      ];
      final stats = computeOverviewStats(
        occurrences: occurrences,
        definitions: const [],
        today: d(2),
        window: DataWindow.d7,
        goalFraction: 0.6,
      );
      expect(stats.totalCompletions, 2);
      expect(stats.daysTracked, 2);
      // day 0: 100% (meets goal), day 1: 50% (misses 60% goal).
      expect(stats.dailyGoalMetDays, 1);
    });
  });

  group('buildContributionHeatmap', () {
    test('future days are marked with level -1', () {
      final columns = buildContributionHeatmap(occurrences: const [], today: monday, weeks: 2);
      final flatCells = columns.expand((c) => c).toList();
      expect(flatCells.any((c) => c.date.isAfter(monday) && c.level == -1), isTrue);
      expect(flatCells.every((c) => !c.date.isAfter(monday) ? c.level >= 0 : true), isTrue);
    });
  });
}
