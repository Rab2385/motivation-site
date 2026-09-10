/// Date helpers shared across the domain layer.
///
/// The whole app works in device local time. A "day" is identified by its
/// `yyyy-MM-dd` key; weeks run Monday–Sunday.
library;

/// Strips the time component, keeping the local calendar day.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// `yyyy-MM-dd` key for [date] (local calendar day).
String dayKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Parses a `yyyy-MM-dd` key back into a local [DateTime] at midnight.
DateTime parseDayKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// The Monday (00:00) of the week containing [date].
DateTime weekStart(DateTime date) {
  final day = dateOnly(date);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// The Sunday of the week containing [date].
DateTime weekEnd(DateTime date) =>
    weekStart(date).add(const Duration(days: 6));

/// Whether [a] and [b] fall on the same local calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Whether [a] and [b] fall in the same Monday–Sunday week.
bool isSameWeek(DateTime a, DateTime b) =>
    isSameDay(weekStart(a), weekStart(b));

/// Inclusive list of calendar days from [start] to [end].
List<DateTime> daysInRange(DateTime start, DateTime end) {
  final from = dateOnly(start);
  final to = dateOnly(end);
  final result = <DateTime>[];
  for (var day = from; !day.isAfter(to); day = day.add(const Duration(days: 1))) {
    result.add(day);
  }
  return result;
}

/// ISO-8601 week key (`yyyy-Www`) for grouping `timesPerWeek` history.
///
/// The year in the key is the ISO week-numbering year (decided by the
/// Thursday of that week), which can differ from the calendar year around
/// New Year.
String isoWeekKey(DateTime date) {
  final day = dateOnly(date);
  // Thursday of the same Monday–Sunday week decides the week-numbering year.
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final dayOfYear = thursday.difference(DateTime(thursday.year, 1, 1)).inDays;
  final week = 1 + dayOfYear ~/ 7;
  return '${thursday.year.toString().padLeft(4, '0')}-W'
      '${week.toString().padLeft(2, '0')}';
}
