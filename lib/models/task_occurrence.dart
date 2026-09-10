import 'package:flutter/foundation.dart';

import '../domain/difficulty.dart';
import '../util/dates.dart';
import 'completion.dart';

/// Where an occurrence came from.
enum OccurrenceOrigin {
  /// Typed straight onto a day.
  oneOff,

  /// Materialised from a fixed-weekday [TaskDefinition].
  recurring,

  /// Placed onto a day from a `timesPerWeek` chip.
  quota,
}

/// A concrete task on one calendar day – the unit shown as a "quest".
@immutable
class TaskOccurrence {
  const TaskOccurrence({
    required this.id,
    required this.dateKey,
    required this.title,
    required this.categoryId,
    required this.xp,
    required this.origin,
    required this.createdAt,
    required this.updatedAt,
    this.note = '',
    this.difficulty,
    this.sourceDefinitionId,
    this.isForked = false,
    this.isSkipped = false,
    this.completion,
  });

  final String id;

  /// `yyyy-MM-dd`.
  final String dateKey;

  final String title;
  final String note;
  final String categoryId;
  final Difficulty? difficulty;
  final int xp;

  final OccurrenceOrigin origin;

  /// The recurring definition this came from, or null for a pure one-off.
  final String? sourceDefinitionId;

  /// True once the user has edited this occurrence – it then stops tracking
  /// later edits to its definition.
  final bool isForked;

  /// A planned skip (recurring only): shown struck-through, awards no XP and
  /// is streak-neutral.
  final bool isSkipped;

  final Completion? completion;

  DateTime get date => parseDayKey(dateKey);

  bool get isRecurring => sourceDefinitionId != null;
  bool get isCompleted => completion != null;
  bool get isFullyCompleted => completion?.isFull ?? false;
  bool get isOpen => !isCompleted && !isSkipped;

  /// XP that would be awarded for a full completion right now.
  int get effectiveXp => xp;

  TaskOccurrence copyWith({
    String? title,
    String? note,
    String? categoryId,
    Difficulty? difficulty,
    bool clearDifficulty = false,
    int? xp,
    OccurrenceOrigin? origin,
    String? sourceDefinitionId,
    bool clearSource = false,
    bool? isForked,
    bool? isSkipped,
    Completion? completion,
    bool clearCompletion = false,
    DateTime? updatedAt,
    String? dateKey,
  }) {
    return TaskOccurrence(
      id: id,
      dateKey: dateKey ?? this.dateKey,
      title: title ?? this.title,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      xp: xp ?? this.xp,
      origin: origin ?? this.origin,
      sourceDefinitionId:
          clearSource ? null : (sourceDefinitionId ?? this.sourceDefinitionId),
      isForked: isForked ?? this.isForked,
      isSkipped: isSkipped ?? this.isSkipped,
      completion: clearCompletion ? null : (completion ?? this.completion),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'dateKey': dateKey,
        'title': title,
        'note': note,
        'categoryId': categoryId,
        'difficulty': difficulty?.name,
        'xp': xp,
        'origin': origin.name,
        'sourceDefinitionId': sourceDefinitionId,
        'isForked': isForked,
        'isSkipped': isSkipped,
        'completion': completion?.toMap(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TaskOccurrence.fromMap(Map<String, Object?> map) {
    final completionMap = map['completion'];
    return TaskOccurrence(
      id: map['id']! as String,
      dateKey: map['dateKey']! as String,
      title: map['title']! as String,
      note: map['note'] as String? ?? '',
      categoryId: map['categoryId']! as String,
      difficulty: Difficulty.fromName(map['difficulty'] as String?),
      xp: (map['xp'] as num? ?? 0).toInt(),
      origin: OccurrenceOrigin.values.firstWhere(
        (value) => value.name == map['origin'],
        orElse: () => OccurrenceOrigin.oneOff,
      ),
      sourceDefinitionId: map['sourceDefinitionId'] as String?,
      isForked: map['isForked'] as bool? ?? false,
      isSkipped: map['isSkipped'] as bool? ?? false,
      completion: completionMap is Map
          ? Completion.fromMap(completionMap.cast<String, Object?>())
          : null,
      createdAt: DateTime.parse(map['createdAt']! as String),
      updatedAt: DateTime.parse(map['updatedAt']! as String),
    );
  }
}
