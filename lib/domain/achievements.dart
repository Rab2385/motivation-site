import 'package:flutter/material.dart';

import 'statistics.dart';

/// A single achievement. Definitions are code; unlocks are data
/// (`achievement_unlocks` store).
class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;

  /// Pure predicate over a [StatsSnapshot].
  final bool Function(StatsSnapshot snapshot) isUnlocked;
}

/// The full catalogue, evaluated after every completion and at day rollover.
const List<_Def> _catalogue = [
  _Def(
    'first_quest',
    'Erster Schritt',
    'Schließe deine erste Quest ab.',
    Icons.flag_outlined,
  ),
  _Def(
    'ten_quests',
    'In Fahrt',
    'Schließe 10 Quests ab.',
    Icons.directions_run,
  ),
  _Def(
    'hundred_quests',
    'Durchhalter',
    'Schließe 100 Quests ab.',
    Icons.military_tech_outlined,
  ),
  _Def(
    'perfect_day',
    'Perfekter Tag',
    'Erledige an einem Tag alles, was geplant war.',
    Icons.wb_sunny_outlined,
  ),
  _Def(
    'streak_7',
    'Woche gehalten',
    'Erreiche eine Streak von 7.',
    Icons.local_fire_department_outlined,
  ),
  _Def(
    'streak_30',
    'Eiserne Disziplin',
    'Erreiche eine Streak von 30.',
    Icons.local_fire_department,
  ),
  _Def('level_5', 'Level 5', 'Erreiche Level 5.', Icons.trending_up),
  _Def(
    'level_10',
    'Level 10',
    'Erreiche Level 10.',
    Icons.rocket_launch_outlined,
  ),
  _Def('xp_1000', '1.000 XP', 'Sammle insgesamt 1.000 XP.', Icons.bolt),
  _Def(
    'xp_10000',
    '10.000 XP',
    'Sammle insgesamt 10.000 XP.',
    Icons.electric_bolt,
  ),
  _Def(
    'five_categories',
    'Vielseitig',
    'Schließe Quests aus 5 verschiedenen Kategorien ab.',
    Icons.category_outlined,
  ),
  _Def(
    'week_planned',
    'Vorausdenker',
    'Plane eine ganze Woche im Voraus durch.',
    Icons.event_available_outlined,
  ),

  // Category badges
  _Def(
    'badge_haushalt',
    'Hausmeister',
    'Sammle 100 XP in Haushalt.',
    Icons.home_outlined,
  ),
  _Def(
    'badge_fitness',
    'Fitness-Enthusiast',
    'Sammle 100 XP in Fitness.',
    Icons.fitness_center,
  ),
  _Def(
    'badge_lernen',
    'Wissenshunger',
    'Sammle 100 XP in Lernen.',
    Icons.menu_book,
  ),
  _Def('badge_coding', 'Code-Meister', 'Sammle 100 XP in Coding.', Icons.code),
  _Def(
    'badge_achtsamkeit',
    'Achtsamkeits-Guru',
    'Sammle 50 XP in Achtsamkeit.',
    Icons.self_improvement,
  ),
  _Def(
    'badge_gesundheit',
    'Gesundheits-Profi',
    'Sammle 75 XP in Gesundheit.',
    Icons.favorite,
  ),
  _Def(
    'badge_shopping',
    'Organisiert',
    'Sammle 50 XP in Einkaufen.',
    Icons.shopping_bag_outlined,
  ),
];

class _Def {
  const _Def(this.id, this.title, this.description, this.icon);
  final String id;
  final String title;
  final String description;
  final IconData icon;
}

bool _test(String id, StatsSnapshot s) {
  switch (id) {
    case 'first_quest':
      return s.totalCompletions >= 1;
    case 'ten_quests':
      return s.totalCompletions >= 10;
    case 'hundred_quests':
      return s.totalCompletions >= 100;
    case 'perfect_day':
      return s.hadPerfectDayToday;
    case 'streak_7':
      return s.bestCurrentStreak >= 7 || s.longestStreakEver >= 7;
    case 'streak_30':
      return s.bestCurrentStreak >= 30 || s.longestStreakEver >= 30;
    case 'level_5':
      return s.level >= 5;
    case 'level_10':
      return s.level >= 10;
    case 'xp_1000':
      return s.totalXp >= 1000;
    case 'xp_10000':
      return s.totalXp >= 10000;
    case 'five_categories':
      return s.distinctCategoriesCompleted >= 5;
    case 'week_planned':
      return s.fullyPlannedWeeks >= 1;

    // Category badges
    case 'badge_haushalt':
      return (s.xpByCategory['haushalt'] ?? 0) >= 100;
    case 'badge_fitness':
      return (s.xpByCategory['fitness'] ?? 0) >= 100;
    case 'badge_lernen':
      return (s.xpByCategory['lernen'] ?? 0) >= 100;
    case 'badge_coding':
      return (s.xpByCategory['coding'] ?? 0) >= 100;
    case 'badge_achtsamkeit':
      return (s.xpByCategory['achtsamkeit'] ?? 0) >= 50;
    case 'badge_gesundheit':
      return (s.xpByCategory['gesundheit'] ?? 0) >= 75;
    case 'badge_shopping':
      return (s.xpByCategory['shopping'] ?? 0) >= 50;
    default:
      return false;
  }
}

List<AchievementDefinition> get achievementCatalogue => [
  for (final def in _catalogue)
    AchievementDefinition(
      id: def.id,
      title: def.title,
      description: def.description,
      icon: def.icon,
      isUnlocked: (snapshot) => _test(def.id, snapshot),
    ),
];

/// Returns the ids that are satisfied by [snapshot] but not in [alreadyUnlocked].
List<String> newlyUnlockedAchievements({
  required StatsSnapshot snapshot,
  required Set<String> alreadyUnlocked,
}) {
  return [
    for (final achievement in achievementCatalogue)
      if (!alreadyUnlocked.contains(achievement.id) &&
          achievement.isUnlocked(snapshot))
        achievement.id,
  ];
}
