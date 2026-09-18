import 'package:flutter/foundation.dart';

/// A single weigh-in, for the Health area's "Weigh & Review" task and the
/// 90-day focus weight trend. Deliberately minimal — this is a trend input,
/// not a health-tracking feature in its own right.
@immutable
class WeightEntry {
  const WeightEntry({required this.id, required this.date, required this.kg});

  final String id;
  final DateTime date;
  final double kg;

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'kg': kg,
      };

  factory WeightEntry.fromMap(Map<String, Object?> map) {
    return WeightEntry(
      id: map['id']! as String,
      date: DateTime.parse(map['date']! as String),
      kg: (map['kg'] as num).toDouble(),
    );
  }
}
