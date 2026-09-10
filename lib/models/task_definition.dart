import 'package:flutter/foundation.dart';

import '../domain/difficulty.dart';
import 'recurrence_rule.dart';

/// The template for a recurring task. It is never rendered as a quest itself;
/// [MaterialisationService] derives dated [TaskOccurrence]s from it.
@immutable
class TaskDefinition {
  const TaskDefinition({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.xp,
    required this.recurrence,
    required this.createdAt,
    required this.updatedAt,
    this.note = '',
    this.difficulty,
    this.isPaused = false,
    this.isArchived = false,
  });

  final String id;
  final String title;
  final String note;
  final String categoryId;
  final Difficulty? difficulty;
  final int xp;
  final RecurrenceRule recurrence;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Paused definitions stop materialising new occurrences but keep history.
  final bool isPaused;
  final bool isArchived;

  bool get isActive => !isPaused && !isArchived;

  TaskDefinition copyWith({
    String? title,
    String? note,
    String? categoryId,
    Difficulty? difficulty,
    bool clearDifficulty = false,
    int? xp,
    RecurrenceRule? recurrence,
    DateTime? updatedAt,
    bool? isPaused,
    bool? isArchived,
  }) {
    return TaskDefinition(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      xp: xp ?? this.xp,
      recurrence: recurrence ?? this.recurrence,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPaused: isPaused ?? this.isPaused,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'note': note,
        'categoryId': categoryId,
        'difficulty': difficulty?.name,
        'xp': xp,
        'recurrence': recurrence.toMap(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isPaused': isPaused,
        'isArchived': isArchived,
      };

  factory TaskDefinition.fromMap(Map<String, Object?> map) {
    return TaskDefinition(
      id: map['id']! as String,
      title: map['title']! as String,
      note: map['note'] as String? ?? '',
      categoryId: map['categoryId']! as String,
      difficulty: Difficulty.fromName(map['difficulty'] as String?),
      xp: (map['xp'] as num? ?? 0).toInt(),
      recurrence: RecurrenceRule.fromMap(
        (map['recurrence'] as Map).cast<String, Object?>(),
      ),
      createdAt: DateTime.parse(map['createdAt']! as String),
      updatedAt: DateTime.parse(map['updatedAt']! as String),
      isPaused: map['isPaused'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }
}
