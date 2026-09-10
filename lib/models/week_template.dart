import 'package:flutter/foundation.dart';

import '../domain/difficulty.dart';

/// One task inside a [WeekTemplate], pinned to a weekday (1 = Mon … 7 = Sun).
@immutable
class WeekTemplateEntry {
  const WeekTemplateEntry({
    required this.weekday,
    required this.title,
    required this.categoryId,
    required this.xp,
    this.note = '',
    this.difficulty,
  });

  final int weekday;
  final String title;
  final String note;
  final String categoryId;
  final Difficulty? difficulty;
  final int xp;

  Map<String, Object?> toMap() => {
        'weekday': weekday,
        'title': title,
        'note': note,
        'categoryId': categoryId,
        'difficulty': difficulty?.name,
        'xp': xp,
      };

  factory WeekTemplateEntry.fromMap(Map<String, Object?> map) {
    return WeekTemplateEntry(
      weekday: (map['weekday'] as num).toInt(),
      title: map['title']! as String,
      note: map['note'] as String? ?? '',
      categoryId: map['categoryId']! as String,
      difficulty: Difficulty.fromName(map['difficulty'] as String?),
      xp: (map['xp'] as num? ?? 0).toInt(),
    );
  }
}

/// A saved week arrangement that can be applied to a future week.
///
/// Applying a template is the **only** place normalised title matching runs:
/// an entry whose `normalise(title)` + `categoryId` already exists as an
/// occurrence on the target day is skipped.
@immutable
class WeekTemplate {
  const WeekTemplate({
    required this.id,
    required this.name,
    required this.entries,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<WeekTemplateEntry> entries;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'entries': entries.map((entry) => entry.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory WeekTemplate.fromMap(Map<String, Object?> map) {
    return WeekTemplate(
      id: map['id']! as String,
      name: map['name']! as String,
      entries: [
        for (final entry in (map['entries'] as List? ?? const []))
          WeekTemplateEntry.fromMap((entry as Map).cast<String, Object?>()),
      ],
      createdAt: DateTime.parse(map['createdAt']! as String),
    );
  }
}

/// Normalisation used for the template-application dedup check.
String normaliseTitle(String title) =>
    title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
