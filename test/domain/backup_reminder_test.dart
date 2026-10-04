import 'package:flutter_test/flutter_test.dart';
import 'package:motivation/domain/backup_reminder.dart';

void main() {
  final now = DateTime(2026, 10, 4, 12);
  DateTime daysAgo(int d) => now.subtract(Duration(days: d));

  test('off never nudges', () {
    expect(
      isBackupNudgeDue(now: now, reminderDays: 0, lastBackupAt: daysAgo(90)),
      isFalse,
    );
  });

  test('nudges once the last backup is older than the interval', () {
    expect(
      isBackupNudgeDue(now: now, reminderDays: 7, lastBackupAt: daysAgo(6)),
      isFalse,
    );
    expect(
      isBackupNudgeDue(now: now, reminderDays: 7, lastBackupAt: daysAgo(7)),
      isTrue,
    );
  });

  test('never backed up: waits until there is a week of history', () {
    expect(isBackupNudgeDue(now: now, reminderDays: 7), isFalse);
    expect(
      isBackupNudgeDue(now: now, reminderDays: 7, firstActivityAt: daysAgo(3)),
      isFalse,
    );
    expect(
      isBackupNudgeDue(now: now, reminderDays: 7, firstActivityAt: daysAgo(8)),
      isTrue,
    );
  });

  test('a snooze hides the nudge until it runs out', () {
    expect(
      isBackupNudgeDue(
        now: now,
        reminderDays: 7,
        lastBackupAt: daysAgo(30),
        snoozedUntil: now.add(const Duration(days: 1)),
      ),
      isFalse,
    );
    expect(
      isBackupNudgeDue(
        now: now,
        reminderDays: 7,
        lastBackupAt: daysAgo(30),
        snoozedUntil: now.subtract(const Duration(minutes: 1)),
      ),
      isTrue,
    );
  });
}
