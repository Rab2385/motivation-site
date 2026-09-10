import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/domain/streaks.dart';
import 'package:motivation/models/task_occurrence.dart';

import '../support/factories.dart';

void main() {
  // Anchor everything to a known week. 2026-09-07 is a Monday.
  final monday = DateTime(2026, 9, 7);
  DateTime d(int addDays) => monday.add(Duration(days: addDays));

  group('fixed-weekday streak', () {
    final definition = fixedDef(
      weekdays: {1, 3, 5},
      createdAt: DateTime(2026, 8, 1),
    );

    test('counts consecutive completed scheduled slots', () {
      final occurrences = [
        occ(id: 'a', date: d(0), sourceDefinitionId: 'def1', completed: true),
        occ(id: 'b', date: d(2), sourceDefinitionId: 'def1', completed: true),
        occ(id: 'c', date: d(4), sourceDefinitionId: 'def1', completed: true),
      ];
      final streak = computeStreak(
        definition: definition,
        occurrences: occurrences,
        today: d(5), // Saturday, after Fri slot
      );
      expect(streak.current, 3);
      expect(streak.atRisk, isFalse);
    });

    test('one missed slot is forgiven (freezes, at risk)', () {
      final occurrences = [
        occ(id: 'a', date: d(0), sourceDefinitionId: 'def1', completed: true),
        occ(id: 'b', date: d(2), sourceDefinitionId: 'def1', completed: true),
        // Friday d(4) missing entirely
      ];
      final streak = computeStreak(
        definition: definition,
        occurrences: occurrences,
        today: d(6),
      );
      expect(streak.current, 2);
      expect(streak.atRisk, isTrue);
    });

    test('two consecutive missed slots break the streak', () {
      final occurrences = [
        occ(id: 'a', date: d(0), sourceDefinitionId: 'def1', completed: true),
        // Wed d(2) and Fri d(4) both missing
      ];
      final streak = computeStreak(
        definition: definition,
        occurrences: occurrences,
        today: d(7),
      );
      expect(streak.current, 0);
    });

    test('a planned skip is neutral, not a miss', () {
      final occurrences = [
        occ(id: 'a', date: d(0), sourceDefinitionId: 'def1', completed: true),
        occ(id: 'b', date: d(2), sourceDefinitionId: 'def1', skipped: true),
        occ(id: 'c', date: d(4), sourceDefinitionId: 'def1', completed: true),
      ];
      final streak = computeStreak(
        definition: definition,
        occurrences: occurrences,
        today: d(6),
      );
      expect(streak.current, 2);
      expect(streak.atRisk, isFalse);
    });

    test('partial completion does not count for the streak', () {
      final occurrences = [
        occ(
          id: 'a',
          date: d(0),
          sourceDefinitionId: 'def1',
          completed: true,
          fraction: 0.4,
        ),
        occ(id: 'b', date: d(2), sourceDefinitionId: 'def1', completed: true),
      ];
      final streak = computeStreak(
        definition: definition,
        occurrences: occurrences,
        today: d(3),
      );
      // Monday counts as a miss (partial), forgiven once; Wed completed = 1.
      expect(streak.current, 1);
    });
  });

  group('times-per-week streak', () {
    final definition = quotaDef(times: 3, createdAt: DateTime(2026, 8, 3));

    List<TaskOccurrence> week(DateTime weekMonday, int completedCount) => [
          for (var i = 0; i < completedCount; i++)
            occ(
              id: 'q${weekMonday.day}_$i',
              date: weekMonday.add(Duration(days: i)),
              sourceDefinitionId: 'defq',
              origin: OccurrenceOrigin.quota,
              completed: true,
            ),
        ];

    test('weeks that meet the target extend the streak', () {
      final occurrences = [
        ...week(DateTime(2026, 8, 24), 3),
        ...week(DateTime(2026, 8, 31), 4),
        ...week(DateTime(2026, 9, 7), 1), // current week, in progress
      ];
      final streak = computeStreak(
        definition: definition,
        occurrences: occurrences,
        today: DateTime(2026, 9, 9),
      );
      expect(streak.current, 2);
      expect(streak.progressLabel, '1 / 3 diese Woche');
    });

    test('one short week is forgiven, two break it', () {
      final occurrences = [
        ...week(DateTime(2026, 8, 17), 3),
        ...week(DateTime(2026, 8, 24), 1), // short
        ...week(DateTime(2026, 8, 31), 1), // short again
      ];
      final streak = computeStreak(
        definition: definition,
        occurrences: occurrences,
        today: DateTime(2026, 9, 7),
      );
      expect(streak.current, 0);
    });
  });
}
