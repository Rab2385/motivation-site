/// The 9×9 Life Grid: eight life areas plus the central life goal, milestones
/// under each area with an explicit three-state status, and the "current
/// 90-day focus" areas.
///
/// Life areas are just [TaskCategory] rows flagged `isFocusArea` — see
/// `models/task_category.dart`. This file holds the fixed seed data (which
/// category id maps to which area, and its one-line description) plus the
/// [GoalStatus] states used by [Milestone].
library;

/// Status of a specific, explicit Life Grid goal or milestone. Deliberately
/// not derived from XP alone — reaching a milestone requires marking it,
/// not just accumulating points.
enum GoalStatus {
  notStarted(symbol: '○', label: 'Not started'),
  inProgress(symbol: '◐', label: 'In progress'),
  achieved(symbol: '✓', label: 'Achieved');

  const GoalStatus({required this.symbol, required this.label});

  final String symbol;
  final String label;

  static GoalStatus fromName(String? name) {
    for (final value in GoalStatus.values) {
      if (value.name == name) return value;
    }
    return GoalStatus.notStarted;
  }
}

const String lifeGridCentralGoal =
    'Build a life I actively choose — where I am healthy, confident, '
    'surrounded by people who choose me too, and free to turn my ideas '
    'into reality.';

/// Fixed ids for the seeded Life Grid daily/weekly/monthly definitions and
/// milestones, so controller selectors (weekly workout count, Minimum Viable
/// Week, 90-day progress) can look them up reliably even if the user renames
/// the task's title later. Seeded once by `MotivationController._seedLifeGrid`.
class LifeGridIds {
  LifeGridIds._();

  static const dailyMovement = 'lg_daily_movement';
  static const balancedMeals = 'lg_balanced_meals';
  static const protectSleep = 'lg_protect_sleep';
  static const decideAct = 'lg_decide_act';
  static const mentalReset = 'lg_mental_reset';
  static const learnOrBuild = 'lg_learn_or_build';

  static const weeklyWorkout = 'lg_weekly_workout';
  static const weighReview = 'lg_weigh_review';
  static const courageChallenge = 'lg_courage_challenge';
  static const createConnection = 'lg_create_connection';
  static const improvementIdea = 'lg_improvement_idea';
  static const sideBusiness = 'lg_side_business';
  static const learningSession = 'lg_learning_session';
  static const deepBuild = 'lg_deep_build';
  static const funWithoutProductivity = 'lg_fun_without_productivity';
  static const weeklyLifeReview = 'lg_weekly_life_review';

  static const monthlyHealth = 'lg_monthly_health';
  static const monthlyCourage = 'lg_monthly_courage';
  static const monthlyRelationships = 'lg_monthly_relationships';
  static const monthlyCareer = 'lg_monthly_career';
  static const monthlyFinancial = 'lg_monthly_financial';
  static const monthlyLearning = 'lg_monthly_learning';
  static const monthlyCreativity = 'lg_monthly_creativity';
  static const monthlyHappiness = 'lg_monthly_happiness';

  static const milestoneLearnFlutter = 'lg_ms_learn_flutter';
  static const milestonePublishApp = 'lg_ms_publish_app';
  static const milestoneReach100kg = 'lg_ms_reach_100kg';
  static const milestoneHardware = 'lg_ms_hardware';
}

/// The current 90-day focus targets (Health / Courage / Create), from the
/// user's own numbers. Not yet user-editable in the UI — seeded as fixed
/// values and displayed/tracked against; editing can follow later.
class NinetyDayFocus {
  const NinetyDayFocus({
    required this.startWeightKg,
    required this.longTermTargetKg,
    required this.currentTargetLowKg,
    required this.currentTargetHighKg,
    required this.minWorkoutsPerWeek,
    required this.targetWorkoutsPerWeek,
  });

  final double startWeightKg;
  final double longTermTargetKg;
  final double currentTargetLowKg;
  final double currentTargetHighKg;
  final int minWorkoutsPerWeek;
  final int targetWorkoutsPerWeek;
}

const ninetyDayFocus = NinetyDayFocus(
  startWeightKg: 117.5,
  longTermTargetKg: 100,
  currentTargetLowKg: 110,
  currentTargetHighKg: 112,
  minWorkoutsPerWeek: 2,
  targetWorkoutsPerWeek: 3,
);

const String courageObjective =
    "Overthinking can speak, but it doesn't get the final vote.";
const String createObjective = 'Turn an idea into something real.';

/// This week's progress toward the "Minimum Viable Week" — 2 workouts, 1
/// build session, 1 Courage Challenge. Shown separately from a perfect week
/// to reinforce consistency over perfectionism.
class MinimumViableWeekStatus {
  const MinimumViableWeekStatus({
    required this.workoutsDone,
    required this.workoutsTarget,
    required this.deepBuildDone,
    required this.courageDone,
  });

  final int workoutsDone;
  final int workoutsTarget;
  final bool deepBuildDone;
  final bool courageDone;

  bool get workoutsMet => workoutsDone >= workoutsTarget;
  bool get isMet => workoutsMet && deepBuildDone && courageDone;
}

/// One of the eight life areas, backed by a [TaskCategory] with the same id.
class LifeAreaSeed {
  const LifeAreaSeed({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.iconKey,
    required this.colorValue,
    required this.isFocusArea,
  });

  final String categoryId;
  final String name;
  final String description;
  final String iconKey;
  final int colorValue;
  final bool isFocusArea;
}

/// The eight areas, in the order the grid displays them. Reuses existing
/// category ids where a prior category already fits (see task_category.dart)
/// so old tasks keep working; only `courage`, `relationships` and `financial`
/// are genuinely new categories.
const List<LifeAreaSeed> lifeAreaSeeds = [
  LifeAreaSeed(
    categoryId: 'health',
    name: 'Health',
    description: 'Movement, food, sleep and how my body feels day to day.',
    iconKey: 'health',
    colorValue: 0xFF66BB6A,
    isFocusArea: true,
  ),
  LifeAreaSeed(
    categoryId: 'courage',
    name: 'Courage & Confidence',
    description: "Acting despite overthinking — it can speak, but it doesn't get the final vote.",
    iconKey: 'courage',
    colorValue: 0xFFE3A64F,
    isFocusArea: true,
  ),
  LifeAreaSeed(
    categoryId: 'relationships',
    name: 'Friends & Relationships',
    description: 'People who choose me back — measured by my own effort, not their reply.',
    iconKey: 'social',
    colorValue: 0xFFEC407A,
    isFocusArea: false,
  ),
  LifeAreaSeed(
    categoryId: 'work',
    name: 'Career & Meaning',
    description: 'Process, product and professional independence.',
    iconKey: 'work',
    colorValue: 0xFF5E7CE2,
    isFocusArea: false,
  ),
  LifeAreaSeed(
    categoryId: 'financial',
    name: 'Financial Freedom',
    description: 'Saving, investing and validating additional income.',
    iconKey: 'money',
    colorValue: 0xFF2FB380,
    isFocusArea: false,
  ),
  LifeAreaSeed(
    categoryId: 'learning',
    name: 'Adventure & Learning',
    description: 'New places, new skills, new experiences.',
    iconKey: 'book',
    colorValue: 0xFF4C8DFF,
    isFocusArea: false,
  ),
  LifeAreaSeed(
    categoryId: 'coding',
    name: 'Creativity & Projects',
    description: 'Turning an idea into something real.',
    iconKey: 'compass',
    colorValue: 0xFF7C4DFF,
    isFocusArea: true,
  ),
  LifeAreaSeed(
    categoryId: 'mindfulness',
    name: 'Happiness & Balance',
    description: 'Did I actually enjoy the life I lived?',
    iconKey: 'mindful',
    colorValue: 0xFF26A69A,
    isFocusArea: false,
  ),
];
