/// How a [TaskDefinition] repeats.
enum RecurrenceKind { fixedWeekdays, timesPerWeek }

/// Value object describing a repeat schedule.
///
/// * [RecurrenceKind.fixedWeekdays] – occurs on each weekday in [weekdays]
///   (1 = Monday … 7 = Sunday). Materialised automatically.
/// * [RecurrenceKind.timesPerWeek] – a flexible weekly target of
///   [timesPerWeek] completions on any days; surfaces as a planner chip and
///   is placed onto days by the user.
class RecurrenceRule {
  const RecurrenceRule.fixedWeekdays(this.weekdays)
      : kind = RecurrenceKind.fixedWeekdays,
        timesPerWeek = 0;

  const RecurrenceRule.timesPerWeek(this.timesPerWeek)
      : kind = RecurrenceKind.timesPerWeek,
        weekdays = const {};

  const RecurrenceRule._({
    required this.kind,
    required this.weekdays,
    required this.timesPerWeek,
  });

  final RecurrenceKind kind;
  final Set<int> weekdays;
  final int timesPerWeek;

  bool get isFixedWeekdays => kind == RecurrenceKind.fixedWeekdays;
  bool get isTimesPerWeek => kind == RecurrenceKind.timesPerWeek;

  /// Whether this rule schedules the given [date] (fixed-weekday rules only).
  bool occursOn(DateTime date) =>
      isFixedWeekdays && weekdays.contains(date.weekday);

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
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule &&
      other.kind == kind &&
      other.timesPerWeek == timesPerWeek &&
      _sameWeekdays(other.weekdays, weekdays);

  @override
  int get hashCode => Object.hash(
        kind,
        timesPerWeek,
        Object.hashAllUnordered(weekdays),
      );

  static bool _sameWeekdays(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}
