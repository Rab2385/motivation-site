import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/domain/habit_target.dart';

void main() {
  group('formatTargetAmount', () {
    test('hours format as Xh Ymin', () {
      expect(formatTargetAmount(7, TargetUnit.hours), '7h');
      expect(formatTargetAmount(1.5, TargetUnit.hours), '1h30min');
      expect(formatTargetAmount(6 + 59 / 60, TargetUnit.hours), '6h59min');
      expect(formatTargetAmount(0.5, TargetUnit.hours), '30min');
    });

    test('minutes format plainly', () {
      expect(formatTargetAmount(15, TargetUnit.minutes), '15min');
    });

    test('steps abbreviate at 1000+', () {
      expect(formatTargetAmount(999, TargetUnit.steps), '999');
      expect(formatTargetAmount(7000, TargetUnit.steps), '7k');
      expect(formatTargetAmount(2900, TargetUnit.steps), '2.9k');
    });

    test('count uses the x suffix', () {
      expect(formatTargetAmount(3, TargetUnit.count), '3x');
    });
  });

  test('formatTargetProgress combines logged / target', () {
    final target = const HabitTarget(amount: 7, unit: TargetUnit.hours);
    expect(formatTargetProgress(6 + 59 / 60, target), '6h59min / 7h');

    final steps = const HabitTarget(amount: 7000, unit: TargetUnit.steps);
    expect(formatTargetProgress(2900, steps), '2.9k / 7k steps');
  });

  test('HabitTarget round-trips through toMap/fromMap', () {
    const target = HabitTarget(amount: 1.5, unit: TargetUnit.hours);
    final restored = HabitTarget.fromMap(target.toMap());
    expect(restored, target);
  });
}
