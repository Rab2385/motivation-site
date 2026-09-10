import 'package:flutter/foundation.dart';

/// Records that a [TaskOccurrence] was completed.
///
/// [awardedXp] is a snapshot taken at completion time. It can be corrected
/// afterwards (which recalculates level and stats), but it never changes
/// silently when the underlying task's XP is edited.
///
/// [fraction] is `1.0` for a full completion. A partial completion
/// (`fraction < 1.0`) pro-rates the XP and does **not** count towards a
/// streak or a weekly quota.
@immutable
class Completion {
  const Completion({
    required this.completedAt,
    required this.awardedXp,
    this.fraction = 1.0,
    this.note = '',
  });

  final DateTime completedAt;
  final int awardedXp;
  final double fraction;
  final String note;

  bool get isFull => fraction >= 1.0;

  Completion copyWith({int? awardedXp, double? fraction, String? note}) {
    return Completion(
      completedAt: completedAt,
      awardedXp: awardedXp ?? this.awardedXp,
      fraction: fraction ?? this.fraction,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() => {
        'completedAt': completedAt.toIso8601String(),
        'awardedXp': awardedXp,
        'fraction': fraction,
        'note': note,
      };

  factory Completion.fromMap(Map<String, Object?> map) {
    return Completion(
      completedAt: DateTime.parse(map['completedAt']! as String),
      awardedXp: (map['awardedXp'] as num? ?? 0).toInt(),
      fraction: (map['fraction'] as num? ?? 1.0).toDouble(),
      note: map['note'] as String? ?? '',
    );
  }
}
