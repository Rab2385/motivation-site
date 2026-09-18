import 'package:flutter/foundation.dart';

import '../domain/life_grid.dart';

/// A one-time, explicit Life Grid goal ("Publish an iOS App") — distinct from
/// a recurring [TaskDefinition] because it isn't done daily/weekly, it's
/// *achieved* once, and its status is set explicitly rather than derived
/// from a completion count.
///
/// Achieving one awards [xp] exactly once, through the normal completion
/// pipeline (see `PlanService.setMilestoneStatus`), so it shows up in stats
/// like anything else — no separate XP ledger.
@immutable
class Milestone {
  const Milestone({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.xp,
    required this.createdAt,
    this.description = '',
    this.status = GoalStatus.notStarted,
    this.targetDate,
    this.achievedAt,
    this.awardedOccurrenceId,
  });

  final String id;
  final String title;
  final String description;
  final String categoryId;
  final int xp;
  final GoalStatus status;
  final DateTime? targetDate;
  final DateTime createdAt;
  final DateTime? achievedAt;

  /// The synthetic completed [TaskOccurrence] created when this was marked
  /// achieved, so undoing/re-achieving doesn't double-award XP.
  final String? awardedOccurrenceId;

  Milestone copyWith({
    String? title,
    String? description,
    String? categoryId,
    int? xp,
    GoalStatus? status,
    DateTime? targetDate,
    bool clearTargetDate = false,
    DateTime? achievedAt,
    bool clearAchievedAt = false,
    String? awardedOccurrenceId,
    bool clearAwardedOccurrenceId = false,
  }) {
    return Milestone(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      xp: xp ?? this.xp,
      status: status ?? this.status,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      createdAt: createdAt,
      achievedAt: clearAchievedAt ? null : (achievedAt ?? this.achievedAt),
      awardedOccurrenceId: clearAwardedOccurrenceId
          ? null
          : (awardedOccurrenceId ?? this.awardedOccurrenceId),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'xp': xp,
        'status': status.name,
        'targetDate': targetDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'achievedAt': achievedAt?.toIso8601String(),
        'awardedOccurrenceId': awardedOccurrenceId,
      };

  factory Milestone.fromMap(Map<String, Object?> map) {
    return Milestone(
      id: map['id']! as String,
      title: map['title']! as String,
      description: map['description'] as String? ?? '',
      categoryId: map['categoryId']! as String,
      xp: (map['xp'] as num? ?? 0).toInt(),
      status: GoalStatus.fromName(map['status'] as String?),
      targetDate: map['targetDate'] == null
          ? null
          : DateTime.parse(map['targetDate']! as String),
      createdAt: DateTime.parse(map['createdAt']! as String),
      achievedAt: map['achievedAt'] == null
          ? null
          : DateTime.parse(map['achievedAt']! as String),
      awardedOccurrenceId: map['awardedOccurrenceId'] as String?,
    );
  }
}
