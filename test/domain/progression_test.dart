import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/domain/progression.dart';

void main() {
  group('levelProgressFor', () {
    test('level 1 at 0 XP', () {
      final progress = levelProgressFor(0);
      expect(progress.level, 1);
      expect(progress.xpForThisLevel, 100);
      expect(progress.xpIntoLevel, 0);
    });

    test('curve boundaries', () {
      expect(levelProgressFor(99).level, 1);
      expect(levelProgressFor(100).level, 2);
      expect(levelProgressFor(249).level, 2);
      expect(levelProgressFor(250).level, 3);
      expect(levelProgressFor(700).level, 5);
      expect(levelProgressFor(1000).level, 6);
    });

    test('fraction within a level', () {
      final progress = levelProgressFor(175); // level 2 spans 100..250
      expect(progress.level, 2);
      expect(progress.xpIntoLevel, 75);
      expect(progress.xpForThisLevel, 150);
      expect(progress.fraction, closeTo(0.5, 0.001));
    });

    test('negative XP is clamped', () {
      expect(levelProgressFor(-50).level, 1);
    });
  });
}
