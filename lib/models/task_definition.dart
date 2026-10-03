import 'package:flutter/foundation.dart';

import '../domain/difficulty.dart';
import '../domain/habit_target.dart';
import '../domain/priority.dart';
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
    this.section = '',
    this.difficulty,
    this.target,
    this.priority = Priority.normal,
    this.isFocus,
    this.isBonus = false,
    this.isPaused = false,
    this.isArchived = false,
  });

  final String id;
  final String title;
  final String note;

  /// Time-of-day / routine grouping, e.g. "Morning", "Deep Work" — free
  /// text, empty means "General". See `domain/habit_section.dart`.
  final String section;

  final String categoryId;
  final Difficulty? difficulty;
  final int xp;

  /// Optional quantity/duration target (e.g. 7 hours, 7000 steps). When set,
  /// completion is normally reached by logging progress rather than a
  /// straight tap.
  final HabitTarget? target;

  final Priority priority;

  /// Overrides the category's `isFocusArea` for this one task, when set.
  /// Null means "inherit from the category" (the normal case).
  final bool? isFocus;

  /// Marks this as extra credit beyond the minimum for its recurrence (e.g.
  /// a 3rd weekly workout when the quota target is 2). Purely a display flag.
  final bool isBonus;

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
    String? section,
    String? categoryId,
    Difficulty? difficulty,
    bool clearDifficulty = false,
    int? xp,
    HabitTarget? target,
    bool clearTarget = false,
    Priority? priority,
    bool? isFocus,
    bool clearIsFocus = false,
    bool? isBonus,
    RecurrenceRule? recurrence,
    DateTime? updatedAt,
    bool? isPaused,
    bool? isArchived,
  }) {
    return TaskDefinition(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      section: section ?? this.section,
      categoryId: categoryId ?? this.categoryId,
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      xp: xp ?? this.xp,
      target: clearTarget ? null : (target ?? this.target),
      priority: priority ?? this.priority,
      isFocus: clearIsFocus ? null : (isFocus ?? this.isFocus),
      isBonus: isBonus ?? this.isBonus,
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
    'section': section,
    'categoryId': categoryId,
    'difficulty': difficulty?.name,
    'xp': xp,
    'target': target?.toMap(),
    'priority': priority.name,
    'isFocus': isFocus,
    'isBonus': isBonus,
    'recurrence': recurrence.toMap(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isPaused': isPaused,
    'isArchived': isArchived,
  };

  factory TaskDefinition.fromMap(Map<String, Object?> map) {
    final targetMap = map['target'];
    return TaskDefinition(
      id: map['id']! as String,
      title: map['title']! as String,
      note: map['note'] as String? ?? '',
      section: map['section'] as String? ?? '',
      categoryId: map['categoryId']! as String,
      difficulty: Difficulty.fromName(map['difficulty'] as String?),
      xp: (map['xp'] as num? ?? 0).toInt(),
      target: targetMap is Map
          ? HabitTarget.fromMap(targetMap.cast<String, Object?>())
          : null,
      priority: Priority.fromName(map['priority'] as String?),
      isFocus: map['isFocus'] as bool?,
      isBonus: map['isBonus'] as bool? ?? false,
      recurrence: RecurrenceRule.fromMap(
        (map['recurrence'] as Map).cast<String, Object?>(),
      ),
      createdAt: DateTime.parse(map['createdAt']! as String),
      updatedAt: DateTime.parse(map['updatedAt']! as String),
      isPaused: map['isPaused'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  /// A small, English starter set matching the reference mockups — seeded
  /// once on first run so the app isn't empty. Grouped into the same
  /// sections shown there.
  static List<TaskDefinition> starterHabits(DateTime now) {
    const allDays = {1, 2, 3, 4, 5, 6, 7};
    TaskDefinition def({
      required String id,
      required String title,
      required String section,
      required String categoryId,
      required int xp,
      String note = '',
      Difficulty? difficulty,
      HabitTarget? target,
      Set<int> weekdays = allDays,
    }) {
      return TaskDefinition(
        id: id,
        title: title,
        section: section,
        categoryId: categoryId,
        xp: xp,
        note: note,
        difficulty: difficulty,
        target: target,
        recurrence: RecurrenceRule.fixedWeekdays(weekdays),
        createdAt: now,
        updatedAt: now,
      );
    }

    return [
      def(
        id: 'starter_morning_routine',
        title: 'Morning routine',
        section: 'Morning',
        categoryId: 'mindfulness',
        xp: 25,
        note: 'Wake up, breathe, get moving.',
        difficulty: Difficulty.easy,
      ),
      def(
        id: 'starter_workout',
        title: 'Workout',
        section: 'Morning',
        categoryId: 'fitness',
        xp: 35,
        note: 'Train for strength and energy.',
        difficulty: Difficulty.medium,
      ),
      def(
        id: 'starter_read',
        title: 'Read',
        section: 'Morning',
        categoryId: 'learning',
        xp: 20,
        target: const HabitTarget(amount: 20, unit: TargetUnit.minutes),
      ),
      def(
        id: 'starter_walk',
        title: 'Walk 7k steps',
        section: 'Afternoon',
        categoryId: 'fitness',
        xp: 30,
        target: const HabitTarget(amount: 7000, unit: TargetUnit.steps),
      ),
      def(
        id: 'starter_focus_block',
        title: 'Focus block',
        section: 'Afternoon',
        categoryId: 'work',
        xp: 25,
        note: 'One uninterrupted work session.',
        difficulty: Difficulty.medium,
      ),
      def(
        id: 'starter_deep_work',
        title: 'Deep work',
        section: 'Deep Work',
        categoryId: 'work',
        xp: 60,
        note: 'One real block, no tabs.',
        difficulty: Difficulty.hard,
        target: const HabitTarget(amount: 1.5, unit: TargetUnit.hours),
      ),
      def(
        id: 'starter_inbox_zero',
        title: 'Inbox zero',
        section: 'Deep Work',
        categoryId: 'work',
        xp: 15,
        difficulty: Difficulty.easy,
      ),
      def(
        id: 'starter_train_ideas',
        title: 'Train your ideas',
        section: 'Night',
        categoryId: 'learning',
        xp: 20,
        note: 'Journal or think deeper.',
        difficulty: Difficulty.easy,
      ),
      def(
        id: 'starter_shower',
        title: 'Take a shower',
        section: 'Night',
        categoryId: 'health',
        xp: 10,
        difficulty: Difficulty.easy,
      ),
      def(
        id: 'starter_bed_early',
        title: 'In bed early',
        section: 'Night',
        categoryId: 'mindfulness',
        xp: 20,
      ),
    ];
  }
}
