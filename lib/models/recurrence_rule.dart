/// How a [TaskDefinition] repeats.
enum RecurrenceKind { fixedWeekdays, timesPerWeek, monthly }

/// Value object describing a repeat schedule.
///
/// * [RecurrenceKind.fixedWeekdays] – occurs on each weekday in [weekdays]
///   (1 = Monday … 7 = Sunday). Materialised automatically.
/// * [RecurrenceKind.timesPerWeek] – a flexible weekly target of
///   [timesPerWeek] completions on any days; surfaces as a planner chip and
///   is placed onto days by the user.
/// * [RecurrenceKind.monthly] – occurs once per month, on [dayOfMonth]
///   (clamped to the last day of shorter months). Materialised automatically,
///   one occurrence per calendar month (monthly reviews, milestones).
class RecurrenceRule {
  const RecurrenceRule.fixedWeekdays(this.weekdays)
      : kind = RecurrenceKind.fixedWeekdays,
        timesPerWeek = 0,
        dayOfMonth = 1;

  const RecurrenceRule.timesPerWeek(this.timesPerWeek)
      : kind = RecurrenceKind.timesPerWeek,
        weekdays = const {},
        dayOfMonth = 1;

  const RecurrenceRule.monthly(this.dayOfMonth)
      : kind = RecurrenceKind.monthly,
        weekdays = const {},
        timesPerWeek = 0;

  const RecurrenceRule._({
    required this.kind,
    required this.weekdays,
    required this.timesPerWeek,
    required this.dayOfMonth,
  });

  final RecurrenceKind kind;
  final Set<int> weekdays;
  final int timesPerWeek;

  /// 1..31, [RecurrenceKind.monthly] only. Clamped to the month's last day.
  final int dayOfMonth;

  bool get isFixedWeekdays => kind == RecurrenceKind.fixedWeekdays;
  bool get isTimesPerWeek => kind == RecurrenceKind.timesPerWeek;
  bool get isMonthly => kind == RecurrenceKind.monthly;

  /// Whether this rule schedules the given [date] (fixed-weekday or monthly
  /// rules only — `timesPerWeek` has no fixed dates).
  bool occursOn(DateTime date) {
    if (isFixedWeekdays) return weekdays.contains(date.weekday);
    if (isMonthly) return date.day == _clampedDayOfMonth(date.year, date.month);
    return false;
  }

  int _clampedDayOfMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return dayOfMonth > lastDay ? lastDay : dayOfMonth;
  }

  RecurrenceRule withWeekday(int weekday, {required bool present}) {
    if (!isFixedWeekdays) return this;
    final next = Set<int>.from(weekdays);
    if (present) {
      next.add(weekday);
    } else {
      next.remove(weekday);
    }
    return RecurrenceRule.fixedWeekdays(next);
  }

  Map<String, Object?> toMap() => {
        'kind': kind.name,
        'weekdays': weekdays.toList()..sort(),
        'timesPerWeek': timesPerWeek,
        'dayOfMonth': dayOfMonth,
      };

  factory RecurrenceRule.fromMap(Map<String, Object?> map) {
    final kind = RecurrenceKind.values.firstWhere(
      (value) => value.name == map['kind'],
      orElse: () => RecurrenceKind.fixedWeekdays,
    );
    return RecurrenceRule._(
      kind: kind,
      weekdays: {
        for (final day in (map['weekdays'] as List? ?? const []))
          (day as num).toInt(),
      },
      timesPerWeek: (map['timesPerWeek'] as num? ?? 0).toInt(),
      dayOfMonth: (map['dayOfMonth'] as num? ?? 1).toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule &&
      other.kind == kind &&
      other.timesPerWeek == timesPerWeek &&
      other.dayOfMonth == dayOfMonth &&
      _sameWeekdays(other.weekdays, weekdays);

  @override
  int get hashCode => Object.hash(
        kind,
        timesPerWeek,
        dayOfMonth,
        Object.hashAllUnordered(weekdays),
      );

  static bool _sameWeekdays(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}
