import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/util/dates.dart';

void main() {
  test('weekStart returns the Monday', () {
    // 2026-09-10 is a Thursday.
    final thursday = DateTime(2026, 9, 10);
    expect(weekStart(thursday), DateTime(2026, 9, 7));
    expect(weekEnd(thursday), DateTime(2026, 9, 13));
  });

  test('weekStart on a Monday is that Monday', () {
    final monday = DateTime(2026, 9, 7);
    expect(weekStart(monday), monday);
  });

  test('dayKey round-trips', () {
    final date = DateTime(2026, 1, 5);
    expect(dayKey(date), '2026-01-05');
    expect(parseDayKey('2026-01-05'), date);
  });

  test('isSameWeek', () {
    expect(isSameWeek(DateTime(2026, 9, 7), DateTime(2026, 9, 13)), isTrue);
    expect(isSameWeek(DateTime(2026, 9, 7), DateTime(2026, 9, 14)), isFalse);
  });

  test('isoWeekKey groups a Mon-Sun week together', () {
    final monday = DateTime(2026, 9, 7);
    final sunday = DateTime(2026, 9, 13);
    expect(isoWeekKey(monday), isoWeekKey(sunday));
    expect(isoWeekKey(monday), isNot(isoWeekKey(DateTime(2026, 9, 14))));
  });
}
