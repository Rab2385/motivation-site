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

  /// Predefined household quest templates for single household.
  /// These are seeded on first run to give users a quick-start setup.
  static List<TaskDefinition> defaultHouseholdQuests(DateTime now) => [
    // Daily tasks
    TaskDefinition(
      id: 'hh_dishes',
      title: 'Geschirr spülen',
      note: 'Küche sauber halten',
      categoryId: 'haushalt',
      difficulty: Difficulty.leicht,
      xp: 15,
      recurrence: RecurrenceRule.fixedWeekdays({
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      }), // Every day
      createdAt: now,
      updatedAt: now,
    ),
    TaskDefinition(
      id: 'hh_kitchen_tidy',
      title: 'Küche aufräumen',
      note: 'Oberflächen abwischen, Ordnung halten',
      categoryId: 'haushalt',
      difficulty: Difficulty.leicht,
      xp: 20,
      recurrence: RecurrenceRule.fixedWeekdays({
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      }), // Every day
      createdAt: now,
      updatedAt: now,
    ),

    // 2x per week tasks
    TaskDefinition(
      id: 'hh_bathroom_clean',
      title: 'Badezimmer putzen',
      note: 'Fliesen, Spiegel, Toilette reinigen',
      categoryId: 'haushalt',
      difficulty: Difficulty.mittel,
      xp: 35,
      recurrence: RecurrenceRule.fixedWeekdays({2, 5}), // Tuesday, Friday
      createdAt: now,
      updatedAt: now,
    ),
    TaskDefinition(
      id: 'hh_vacuum',
      title: 'Zimmer staubsaugen',
      note: 'Wohn- und Schlafzimmer absaugen',
      categoryId: 'haushalt',
      difficulty: Difficulty.mittel,
      xp: 30,
      recurrence: RecurrenceRule.fixedWeekdays({3, 6}), // Wednesday, Saturday
      createdAt: now,
      updatedAt: now,
    ),
    TaskDefinition(
      id: 'hh_laundry',
      title: 'Wäsche waschen',
      note: 'Wäsche waschen, trocknen und falten',
      categoryId: 'haushalt',
      difficulty: Difficulty.mittel,
      xp: 40,
      recurrence: RecurrenceRule.fixedWeekdays({2, 6}), // Tuesday, Saturday
      createdAt: now,
      updatedAt: now,
    ),

    // Weekly tasks
    TaskDefinition(
      id: 'hh_sheets',
      title: 'Bettwäsche wechseln',
      note: 'Betten frische Laken geben',
      categoryId: 'haushalt',
      difficulty: Difficulty.mittel,
      xp: 25,
      recurrence: RecurrenceRule.fixedWeekdays({7}), // Sunday
      createdAt: now,
      updatedAt: now,
    ),
    TaskDefinition(
      id: 'hh_plants',
      title: 'Pflanzen gießen',
      note: 'Alle Zimmerpflanzen gießen',
      categoryId: 'haushalt',
      difficulty: Difficulty.leicht,
      xp: 10,
      recurrence: RecurrenceRule.fixedWeekdays({4}), // Thursday
      createdAt: now,
      updatedAt: now,
    ),
    TaskDefinition(
      id: 'hh_dust',
      title: 'Möbel abstauben',
      note: 'Regal, Tische und Regale abstauben',
      categoryId: 'haushalt',
      difficulty: Difficulty.leicht,
      xp: 20,
      recurrence: RecurrenceRule.fixedWeekdays({1}), // Monday
      createdAt: now,
      updatedAt: now,
    ),
    TaskDefinition(
      id: 'hh_living_tidy',
      title: 'Wohnzimmer organisieren',
      note: 'Kissen, Decken, Gegenstände sortieren',
      categoryId: 'haushalt',
      difficulty: Difficulty.leicht,
      xp: 15,
      recurrence: RecurrenceRule.fixedWeekdays({5}), // Friday
      createdAt: now,
      updatedAt: now,
    ),

    // Bi-weekly task
    TaskDefinition(
      id: 'hh_windows',
      title: 'Fenster putzen',
      note: 'Fenster innen und außen reinigen (alle 2 Wochen)',
      categoryId: 'haushalt',
      difficulty: Difficulty.schwer,
      xp: 50,
      recurrence: RecurrenceRule.fixedWeekdays({
        7,
      }), // Every other Sunday (manual adjustment)
      createdAt: now,
      updatedAt: now,
    ),
  ];

  /// Predefined fitness quest templates.
  static List<TaskDefinition> defaultFitnessQuests(DateTime now) => [
    // 3x per week main workouts
    TaskDefinition(
      id: 'fit_workout',
      title: 'Workout machen',
      note: 'Kraft- oder Cardio-Training (30-60 Min)',
      categoryId: 'fitness',
      difficulty: Difficulty.schwer,
      xp: 80,
      recurrence: RecurrenceRule.fixedWeekdays({1, 3, 5}), // Mon, Wed, Fri
      createdAt: now,
      updatedAt: now,
    ),
    // Daily light activity
    TaskDefinition(
      id: 'fit_stretch',
      title: 'Dehnen & Mobilität',
      note: 'Morgens oder abends 10-15 Min Dehnübungen',
      categoryId: 'fitness',
      difficulty: Difficulty.leicht,
      xp: 20,
      recurrence: RecurrenceRule.fixedWeekdays({1, 2, 3, 4, 5, 6, 7}),
      createdAt: now,
      updatedAt: now,
    ),
    // 2x per week cardio
    TaskDefinition(
      id: 'fit_cardio',
      title: 'Cardio-Tag',
      note: 'Laufen, Radfahren oder HIIT (20-30 Min)',
      categoryId: 'fitness',
      difficulty: Difficulty.mittel,
      xp: 50,
      recurrence: RecurrenceRule.fixedWeekdays({2, 6}), // Tue, Sat
      createdAt: now,
      updatedAt: now,
    ),
    // Weekly review
    TaskDefinition(
      id: 'fit_review',
      title: 'Fitness-Woche überprüfen',
      note: 'Trainingsplan für nächste Woche planen',
      categoryId: 'fitness',
      difficulty: Difficulty.leicht,
      xp: 25,
      recurrence: RecurrenceRule.fixedWeekdays({7}), // Sunday
      createdAt: now,
      updatedAt: now,
    ),
  ];

  /// Predefined learning quest templates.
  static List<TaskDefinition> defaultLearningQuests(DateTime now) => [
    // Daily learning habit
    TaskDefinition(
      id: 'learn_daily',
      title: 'Täglich lernen',
      note: 'Sprachlernapp, Podcast oder 15 Min Buch/Artikel',
      categoryId: 'lernen',
      difficulty: Difficulty.leicht,
      xp: 25,
      recurrence: RecurrenceRule.fixedWeekdays({1, 2, 3, 4, 5, 6, 7}),
      createdAt: now,
      updatedAt: now,
    ),
    // Deep focus learning sessions
    TaskDefinition(
      id: 'learn_deep',
      title: 'Tiefgehendes Lernen',
      note: 'Fokussierte Lerneinheit ohne Ablenkung (45-60 Min)',
      categoryId: 'lernen',
      difficulty: Difficulty.schwer,
      xp: 70,
      recurrence: RecurrenceRule.fixedWeekdays({2, 4, 6}), // Tue, Thu, Sat
      createdAt: now,
      updatedAt: now,
    ),
    // Spaced repetition / review
    TaskDefinition(
      id: 'learn_review',
      title: 'Wiederholung & Festigung',
      note: 'Vorher gelernte Inhalte wiederholen',
      categoryId: 'lernen',
      difficulty: Difficulty.mittel,
      xp: 40,
      recurrence: RecurrenceRule.fixedWeekdays({1, 4, 7}), // Mon, Thu, Sun
      createdAt: now,
      updatedAt: now,
    ),
    // Weekly reading
    TaskDefinition(
      id: 'learn_read',
      title: 'Wochenend-Lektüre',
      note: 'Ein Kapitel oder Artikel vollständig lesen',
      categoryId: 'lernen',
      difficulty: Difficulty.mittel,
      xp: 35,
      recurrence: RecurrenceRule.fixedWeekdays({6}), // Saturday
      createdAt: now,
      updatedAt: now,
    ),
    // Teach/share knowledge
    TaskDefinition(
      id: 'learn_teach',
      title: 'Wissen weitergeben',
      note: 'Gelerntes jemandem erklären oder dazu schreiben',
      categoryId: 'lernen',
      difficulty: Difficulty.mittel,
      xp: 45,
      recurrence: RecurrenceRule.fixedWeekdays({3}), // Wednesday
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
