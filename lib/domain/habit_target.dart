/// Optional quantity/duration target on a habit (e.g. "7h sleep", "7000
/// steps", "1h30min focused work") — layered on top of the existing
/// completion/fraction mechanic. Reaching the target auto-completes the
/// occurrence for full XP; logging less than the target just updates the
/// progress shown on the row, it does not complete it.
library;

enum TargetUnit {
  minutes('min'),
  hours('h'),
  steps('steps'),
  count('x');

  const TargetUnit(this.suffix);

  final String suffix;

  static TargetUnit fromName(String? name) {
    for (final value in TargetUnit.values) {
      if (value.name == name) return value;
    }
    return TargetUnit.count;
  }
}

class HabitTarget {
  const HabitTarget({required this.amount, required this.unit});

  final double amount;
  final TargetUnit unit;

  Map<String, Object?> toMap() => {'amount': amount, 'unit': unit.name};

  static HabitTarget? fromMap(Map<String, Object?>? map) {
    if (map == null) return null;
    final amount = (map['amount'] as num?)?.toDouble();
    if (amount == null) return null;
    return HabitTarget(amount: amount, unit: TargetUnit.fromName(map['unit'] as String?));
  }

  HabitTarget copyWith({double? amount, TargetUnit? unit}) =>
      HabitTarget(amount: amount ?? this.amount, unit: unit ?? this.unit);

  @override
  bool operator ==(Object other) =>
      other is HabitTarget && other.amount == amount && other.unit == unit;

  @override
  int get hashCode => Object.hash(amount, unit);
}

/// "1h30min", "45min", "7k", "3x" — compact, mockup-style formatting.
String formatTargetAmount(double value, TargetUnit unit) {
  switch (unit) {
    case TargetUnit.hours:
      final totalMinutes = (value * 60).round();
      final h = totalMinutes ~/ 60;
      final m = totalMinutes % 60;
      if (h > 0 && m > 0) return '${h}h${m}min';
      if (h > 0) return '${h}h';
      if (m > 0) return '${m}min';
      return '0h';
    case TargetUnit.minutes:
      return '${value.round()}min';
    case TargetUnit.steps:
      if (value >= 1000) {
        final k = value / 1000;
        final text = k % 1 == 0 ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
        return '${text}k';
      }
      return value.round().toString();
    case TargetUnit.count:
      final text = value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
      return '$text${unit.suffix}';
  }
}

/// "6h59min / 7h", "2.9k / 7k steps", "1h30min / 1h30min".
String formatTargetProgress(double logged, HabitTarget target) {
  final loggedText = formatTargetAmount(logged, target.unit);
  final targetText = formatTargetAmount(target.amount, target.unit);
  final unitSuffix = target.unit == TargetUnit.steps ? ' steps' : '';
  return '$loggedText / $targetText$unitSuffix';
}
