import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/domain/workload.dart';
import 'package:motivation/util/dates.dart';

import '../support/factories.dart';

void main() {
  final monday = DateTime(2026, 9, 7);

  test('bands follow the planned / target ratio', () {
    final occurrences = [
      occ(id: 'a', date: monday, xp: 60),
      occ(id: 'b', date: monday, xp: 60),
    ];
    final workload = workloadForDay(
      date: monday,
      occurrences: occurrences,
      dayTargets: [150, 150, 150, 150, 150, 80, 80],
    );
    expect(workload.plannedXp, 120);
    expect(workload.band, WorkloadBand.ok); // 120/150 = 0.8
  });

  test('overloaded above 110 percent', () {
    final occurrences = [occ(id: 'a', date: monday, xp: 200)];
    final workload = workloadForDay(
      date: monday,
      occurrences: occurrences,
      dayTargets: null,
    );
    expect(workload.isOverloaded, isTrue);
  });

  test('skipped occurrences do not count towards planned XP', () {
    final occurrences = [
      occ(id: 'a', date: monday, xp: 60),
      occ(id: 'b', date: monday, xp: 60, skipped: true),
    ];
    final workload = workloadForDay(
      date: monday,
      occurrences: occurrences,
      dayTargets: null,
    );
    expect(workload.plannedXp, 60);
  });

  test('lightestOtherDayInWeek skips the source and past days', () {
    final occurrences = [
      occ(id: 'a', date: monday, xp: 300),
      occ(id: 'b', date: monday.add(const Duration(days: 1)), xp: 100),
      occ(id: 'c', date: monday.add(const Duration(days: 2)), xp: 20),
    ];
    final lightest = lightestOtherDayInWeek(
      from: monday,
      today: monday,
      occurrences: occurrences,
      dayTargets: null,
    );
    expect(lightest, isNotNull);
    expect(dayKey(lightest!), dayKey(monday.add(const Duration(days: 3))));
  });
}
