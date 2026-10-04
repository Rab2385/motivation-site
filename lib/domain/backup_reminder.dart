// When to nudge the user to download a backup.
//
// All data lives only in local storage, which the browser may clear, so
// the home screen shows a nudge once the last backup is older than the
// chosen interval. A brand-new user is only nudged once they have
// `reminderDays` of history worth losing.

/// Interval choices offered in system → data; 0 turns the nudge off.
const List<int> backupReminderChoices = [0, 7, 14, 30];
const int defaultBackupReminderDays = 7;

/// Whether the backup nudge should show at [now].
///
/// - [reminderDays] 0: never.
/// - Snoozed until after [now]: no.
/// - Never backed up: once the first completion is [reminderDays] old.
/// - Otherwise: once the last backup is [reminderDays] old.
bool isBackupNudgeDue({
  required DateTime now,
  required int reminderDays,
  DateTime? lastBackupAt,
  DateTime? snoozedUntil,
  DateTime? firstActivityAt,
}) {
  if (reminderDays <= 0) return false;
  if (snoozedUntil != null && snoozedUntil.isAfter(now)) return false;
  final since = lastBackupAt ?? firstActivityAt;
  if (since == null) return false;
  return now.difference(since) >= Duration(days: reminderDays);
}

/// Short label for the interval dropdown.
String backupReminderLabel(int days) => switch (days) {
  0 => 'off',
  7 => 'weekly',
  14 => 'every 2 weeks',
  30 => 'monthly',
  _ => 'every $days days',
};
