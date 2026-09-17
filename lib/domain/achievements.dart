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
  _Def('first_habit', 'First step', 'Complete your first habit.', Icons.flag_outlined),
  _Def('ten_habits', 'Building momentum', 'Complete 10 habits.', Icons.directions_run),
  _Def(
    'hundred_habits',
    'Consistent',
    'Complete 100 habits.',
    Icons.military_tech_outlined,
  ),
  _Def(
    'perfect_day',
    'Perfect day',
    'Finish everything scheduled in one day.',
    Icons.wb_sunny_outlined,
  ),
  _Def(
    'streak_7',
    'One week strong',
    'Reach a 7-day streak.',
    Icons.local_fire_department_outlined,
  ),
  _Def(
    'streak_30',
    'Iron discipline',
    'Reach a 30-day streak.',
    Icons.local_fire_department,
  ),
  _Def('level_5', 'Level 5', 'Reach level 5.', Icons.trending_up),
  _Def('level_10', 'Level 10', 'Reach level 10.', Icons.rocket_launch_outlined),
  _Def('xp_1000', '1,000 XP', 'Earn 1,000 XP in total.', Icons.bolt),
  _Def('xp_10000', '10,000 XP', 'Earn 10,000 XP in total.', Icons.electric_bolt),
  _Def(
    'five_categories',
    'Well-rounded',
    'Complete habits in 5 different categories.',
    Icons.category_outlined,
  ),
  _Def(
    'week_planned',
    'Forward thinker',
    'Plan a full week ahead of time.',
    Icons.event_available_outlined,
  ),

  // Category badges
  _Def('badge_home', 'Housekeeper', 'Earn 100 XP in Home.', Icons.home_outlined),
  _Def(
    'badge_fitness',
    'Fitness enthusiast',
    'Earn 100 XP in Fitness.',
    Icons.fitness_center,
  ),
  _Def(
    'badge_learning',
    'Hungry mind',
    'Earn 100 XP in Learning.',
    Icons.menu_book,
  ),
  _Def('badge_coding', 'Code master', 'Earn 100 XP in Coding.', Icons.code),
  _Def(
    'badge_mindfulness',
    'Mindfulness guru',
    'Earn 50 XP in Mindfulness.',
    Icons.self_improvement,
  ),
  _Def(
    'badge_health',
    'Health pro',
    'Earn 75 XP in Health.',
    Icons.favorite,
  ),
  _Def(
    'badge_shopping',
    'Organized',
    'Earn 50 XP in Shopping.',
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
    case 'first_habit':
      return s.totalCompletions >= 1;
    case 'ten_habits':
      return s.totalCompletions >= 10;
    case 'hundred_habits':
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
    case 'badge_home':
      return (s.xpByCategory['home'] ?? 0) >= 100;
    case 'badge_fitness':
      return (s.xpByCategory['fitness'] ?? 0) >= 100;
    case 'badge_learning':
      return (s.xpByCategory['learning'] ?? 0) >= 100;
    case 'badge_coding':
      return (s.xpByCategory['coding'] ?? 0) >= 100;
    case 'badge_mindfulness':
      return (s.xpByCategory['mindfulness'] ?? 0) >= 50;
    case 'badge_health':
      return (s.xpByCategory['health'] ?? 0) >= 75;
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
