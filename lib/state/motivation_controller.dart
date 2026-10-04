import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/motivation_database.dart';
import '../domain/achievements.dart';
import '../domain/difficulty.dart';
import '../domain/habit_section.dart';
import '../domain/habit_target.dart';
import '../domain/life_grid.dart';
import '../domain/overview_stats.dart';
import '../domain/priority.dart';
import '../domain/progression.dart';
import '../domain/statistics.dart';
import '../domain/streaks.dart';
import '../domain/workload.dart';
import '../models/milestone.dart';
import '../models/proposal.dart';
import '../models/recurrence_rule.dart';
import '../models/task_category.dart';
import '../models/task_definition.dart';
import '../models/task_occurrence.dart';
import '../models/week_template.dart';
import '../models/weight_entry.dart';
import '../services/backup_service.dart';
import '../services/plan_service.dart';
import '../util/dates.dart';
import '../util/passcode_hash.dart';

/// The single in-memory hub. Holds the loaded lists, exposes read selectors
/// backed by `lib/domain/`, and forwards every write to [PlanService].
class MotivationController extends ChangeNotifier {
  MotivationController(this._database) : _backup = BackupService(_database);

  final MotivationDatabase _database;
  final BackupService _backup;
  late PlanService _plan; // rebuilt by initialize(), e.g. after a backup import

  final List<TaskCategory> _categories = [];
  final List<TaskDefinition> _definitions = [];
  final List<TaskOccurrence> _occurrences = [];
  final List<WeekTemplate> _templates = [];
  final List<Proposal> _proposals = [];
  final List<Milestone> _milestones = [];
  final List<WeightEntry> _weightEntries = [];
  final Map<String, DateTime> _achievementUnlocks = {};

  bool _darkMode = true;
  List<int> _dayTargetXp = List.of(defaultDayTargetXp);
  String _userName = '';
  DateTime? _userBirthday;
  // Salted hashes (see util/passcode_hash.dart), never the plain values.
  String _appPasscodeHash = '';
  String _appRecoveryCodeHash = '';
  String _lastRolloverKey = '';
  final Set<String> _dismissedOverloadHints = {};

  bool get hasAppPasscode => _appPasscodeHash.isNotEmpty;
  bool get hasAppRecoveryCode => _appRecoveryCodeHash.isNotEmpty;
  String get userName => _userName.trim();
  DateTime? get userBirthday => _userBirthday;
  bool get hasUserName => userName.isNotEmpty;
  bool get hasBirthday => _userBirthday != null;
  String get birthdayLabel =>
      _userBirthday == null ? 'Not set' : _formatBirthday(_userBirthday!);

  // Gamification / app settings (System page).
  double _xpMultiplier = 1.0;
  LevelCurve _levelCurve = LevelCurve.standard;
  int _perfectDayBonus = 50;
  bool _streakProtection = true;
  bool _dailyReminder = false;
  String _reminderTime = '09:00';
  bool _motivationMessages = true;
  bool _showAtmosphere = true;
  int _dailyGoalPercent = 60;
  int _weeklyReviewDay = DateTime.sunday;
  String _weeklyReviewCompletedWeekKey = '';
  String _defaultWeekTemplateId = '';
  DataWindow _statsWindow = DataWindow.d30;

  int get weeklyReviewDay => _weeklyReviewDay;
  String get defaultWeekTemplateId => _defaultWeekTemplateId;
  WeekTemplate? get defaultWeekTemplate => _templates
      .where((template) => template.id == _defaultWeekTemplateId)
      .firstOrNull;
  String get weeklyReviewCompletedWeekKey => _weeklyReviewCompletedWeekKey;
  bool get hasCompletedWeeklyReviewThisWeek =>
      _weeklyReviewCompletedWeekKey == dayKey(weekStart(today));

  bool isWeeklyReviewDueFor(DateTime date) {
    final normalized = dateOnly(date);
    if (normalized.weekday != _weeklyReviewDay) return false;
    return _weeklyReviewCompletedWeekKey != dayKey(weekStart(normalized));
  }

  /// dateKey of the last day we already handed out a perfect-day toast for.
  String _lastPerfectToastKey = '';
  bool _pendingPerfectToast = false;

  /// Achievement ids unlocked since the UI last cleared them (toast queue).
  final List<String> _pendingAchievementToasts = [];

  bool _ready = false;
  bool get isReady => _ready;

  // ---- Bootstrap --------------------------------------------------------

  Future<void> initialize() async {
    final snapshot = await _database.loadAll();

    _categories
      ..clear()
      ..addAll(snapshot.categories);
    _definitions
      ..clear()
      ..addAll(snapshot.definitions);
    _occurrences
      ..clear()
      ..addAll(snapshot.occurrences);
    _templates
      ..clear()
      ..addAll(snapshot.templates);
    _proposals
      ..clear()
      ..addAll(snapshot.proposals);
    _milestones
      ..clear()
      ..addAll(snapshot.milestones);
    _weightEntries
      ..clear()
      ..addAll(snapshot.weightEntries);
    _achievementUnlocks
      ..clear()
      ..addAll(snapshot.achievementUnlocks);

    final settings = snapshot.settings;
    _darkMode = settings['darkMode'] as bool? ?? true;
    _userName = (settings['userName'] as String?)?.trim() ?? '';
    final birthdayRaw = settings['userBirthday'] as String?;
    _userBirthday = birthdayRaw != null && birthdayRaw.isNotEmpty
        ? DateTime.tryParse(birthdayRaw)
        : null;
    _appPasscodeHash = await _loadSecretHash(settings, 'appPasscode');
    _appRecoveryCodeHash = await _loadSecretHash(settings, 'appRecoveryCode');
    final storedTargets = settings['dayTargetXp'];
    if (storedTargets is List && storedTargets.length == 7) {
      _dayTargetXp = [for (final t in storedTargets) (t as num).toInt()];
    }
    _xpMultiplier =
        (settings['xpMultiplier'] as num?)?.toDouble().clamp(0.1, 5.0) ?? 1.0;
    _levelCurve = LevelCurve.fromName(settings['levelCurve'] as String?);
    _perfectDayBonus =
        (settings['perfectDayBonus'] as num?)?.toInt().clamp(0, 500) ?? 50;
    _streakProtection = settings['streakProtection'] as bool? ?? true;
    _dailyReminder = settings['dailyReminder'] as bool? ?? false;
    _reminderTime = settings['reminderTime'] as String? ?? '09:00';
    _motivationMessages = settings['motivationMessages'] as bool? ?? true;
    _showAtmosphere = settings['showAtmosphere'] as bool? ?? true;
    _dailyGoalPercent =
        (settings['dailyGoalPercent'] as num?)?.toInt().clamp(1, 100) ?? 60;
    _weeklyReviewDay =
        (settings['weeklyReviewDay'] as num?)?.toInt().clamp(1, 7) ??
        DateTime.sunday;
    _weeklyReviewCompletedWeekKey =
        settings['weeklyReviewDoneKey'] as String? ?? '';
    _defaultWeekTemplateId = settings['defaultWeekTemplateId'] as String? ?? '';
    _lastPerfectToastKey = settings['lastPerfectToastKey'] as String? ?? '';
    _lastRolloverKey = snapshot.settings['lastRolloverKey'] as String? ?? '';

    if (_categories.isEmpty) {
      for (final category in TaskCategory.defaults()) {
        _categories.add(category);
        await _database.saveCategory(category);
      }
    }

    // Seed a small starter set of habits on first run.
    final starterHabitsSeeded =
        snapshot.settings['starterHabitsSeeded'] as bool? ?? false;
    if (_definitions.isEmpty && !starterHabitsSeeded) {
      for (final definition in TaskDefinition.starterHabits(DateTime.now())) {
        _definitions.add(definition);
        await _database.saveDefinition(definition);
      }
      await _database.saveSetting('starterHabitsSeeded', true);
    }

    await _purgeTestRoutineEntries();

    _plan = PlanService(
      database: _database,
      categories: _categories,
      definitions: _definitions,
      occurrences: _occurrences,
      templates: _templates,
      proposals: _proposals,
      milestones: _milestones,
      weightEntries: _weightEntries,
    );

    await _seedLifeGrid(snapshot.settings);

    await _plan.refreshMaterialisation();
    await _runRollover();

    _ready = true;
    notifyListeners();
  }

  Future<void> _purgeTestRoutineEntries() async {
    final testIds = _definitions
        .where((definition) => definition.title.trim().toUpperCase() == 'TEST')
        .map((definition) => definition.id)
        .toList();
    if (testIds.isEmpty) return;

    for (final id in testIds) {
      _definitions.removeWhere((definition) => definition.id == id);
      await _database.deleteDefinition(id);

      final occurrenceIds = _occurrences
          .where((occurrence) => occurrence.sourceDefinitionId == id)
          .map((occurrence) => occurrence.id)
          .toList();
      if (occurrenceIds.isNotEmpty) {
        _occurrences.removeWhere(
          (occurrence) => occurrenceIds.contains(occurrence.id),
        );
        await _database.deleteOccurrences(occurrenceIds);
      }
    }
  }

  String generateRecoveryCode() {
    final random = Random.secure();
    final first = random.nextInt(900000) + 100000;
    final second = random.nextInt(900000) + 100000;
    return 'QUEST-$first-$second';
  }

  Future<void> setAppPasscode(String passcode, {String? recoveryCode}) async {
    final normalized = passcode.trim();
    if (normalized.isEmpty) return;
    final code = (recoveryCode ?? generateRecoveryCode()).trim();
    _appPasscodeHash = hashSecret(normalized);
    _appRecoveryCodeHash = hashSecret(code);
    await _database.saveSetting('appPasscode', _appPasscodeHash);
    await _database.saveSetting('appRecoveryCode', _appRecoveryCodeHash);
  }

  Future<bool> validateAppPasscode(String passcode) async {
    final normalized = passcode.trim();
    return _appPasscodeHash.isNotEmpty &&
        verifySecret(normalized, _appPasscodeHash);
  }

  Future<bool> validateRecoveryCode(String recoveryCode) async {
    final normalized = recoveryCode.trim();
    return _appRecoveryCodeHash.isNotEmpty &&
        verifySecret(normalized, _appRecoveryCodeHash);
  }

  Future<void> resetAppPasscode({
    required String recoveryCode,
    required String newPasscode,
  }) async {
    final normalizedRecovery = recoveryCode.trim();
    final normalizedPasscode = newPasscode.trim();
    if (normalizedRecovery.isEmpty || normalizedPasscode.isEmpty) {
      throw ArgumentError('Recovery code and new passcode are required.');
    }
    if (!await validateRecoveryCode(normalizedRecovery)) {
      throw ArgumentError('Recovery code is incorrect.');
    }
    _appPasscodeHash = hashSecret(normalizedPasscode);
    await _database.saveSetting('appPasscode', _appPasscodeHash);
  }

  Future<void> clearAppPasscode() async {
    _appPasscodeHash = '';
    _appRecoveryCodeHash = '';
    await _database.saveSetting('appPasscode', null);
    await _database.saveSetting('appRecoveryCode', null);
  }

  /// Reads a stored secret, hashing (and re-saving) legacy plain-text values
  /// written by versions before hashing was introduced.
  Future<String> _loadSecretHash(
    Map<String, Object?> settings,
    String key,
  ) async {
    final stored = (settings[key] as String? ?? '').trim();
    if (stored.isEmpty || isHashedSecret(stored)) return stored;
    final hashed = hashSecret(stored);
    await _database.saveSetting(key, hashed);
    return hashed;
  }

  /// One-time seed for the 9×9 Life Grid: renames/extends categories into
  /// the eight life areas, adds the default daily/weekly/monthly tasks and
  /// milestones. Guarded by the `lifeGridSeeded` flag so it never re-adds or
  /// overwrites anything on later launches — existing habits are untouched.
  Future<void> _seedLifeGrid(Map<String, Object?> settings) async {
    final alreadySeeded = settings['lifeGridSeeded'] as bool? ?? false;
    if (alreadySeeded) return;
    final now = DateTime.now();
    const allDays = {1, 2, 3, 4, 5, 6, 7};

    // Rename/flag the five existing categories that double as life areas.
    for (final seed in lifeAreaSeeds) {
      final exists = _categories.any((c) => c.id == seed.categoryId);
      if (!exists) continue;
      await _plan.updateCategory(
        seed.categoryId,
        name: seed.name,
        iconKey: seed.iconKey,
        isFocusArea: seed.isFocusArea,
      );
    }
    // Add the three genuinely new life-area categories.
    for (final seed in lifeAreaSeeds) {
      if (_categories.any((c) => c.id == seed.categoryId)) continue;
      final category = TaskCategory(
        id: seed.categoryId,
        name: seed.name,
        colorValue: seed.colorValue,
        iconKey: seed.iconKey,
        sortOrder: _categories.length,
        isFocusArea: seed.isFocusArea,
      );
      _categories.add(category);
      await _database.saveCategory(category);
    }

    TaskDefinition daily({
      required String id,
      required String title,
      required String categoryId,
      required int xp,
      required String note,
      RecurrenceRule? recurrence,
      HabitTarget? target,
    }) {
      return TaskDefinition(
        id: id,
        title: title,
        note: note,
        section: 'Life Grid',
        categoryId: categoryId,
        xp: xp,
        target: target,
        recurrence: recurrence ?? RecurrenceRule.fixedWeekdays(allDays),
        createdAt: now,
        updatedAt: now,
      );
    }

    final dailyHabits = [
      daily(
        id: LifeGridIds.dailyMovement,
        title: 'Daily Movement',
        categoryId: 'health',
        xp: 10,
        note: 'Approximately 7,500+ steps, or otherwise intentional movement.',
      ),
      daily(
        id: LifeGridIds.balancedMeals,
        title: 'Balanced Meals',
        categoryId: 'health',
        xp: 5,
        note:
            'At least two main meals built around protein and nutritious food.',
      ),
      daily(
        id: LifeGridIds.protectSleep,
        title: 'Protect Sleep',
        categoryId: 'health',
        xp: 5,
        note: 'Give yourself approximately 7 hours of sleep opportunity.',
        recurrence: const RecurrenceRule.timesPerWeek(5),
        target: const HabitTarget(amount: 7, unit: TargetUnit.hours),
      ),
      daily(
        id: LifeGridIds.decideAct,
        title: 'Decide & Act',
        categoryId: 'courage',
        xp: 10,
        note:
            'Choose one normal, reversible decision you are overthinking. '
            'Give yourself a maximum of ~10 minutes to think, then choose and '
            'act. Success is making the decision, not whether it was perfect.',
      ),
      daily(
        id: LifeGridIds.mentalReset,
        title: 'Mental Reset',
        categoryId: 'mindfulness',
        xp: 5,
        note:
            'Spend ~5 minutes writing down what is occupying your mind and '
            'classify it: ACT, ACCEPT, or LET GO.',
        recurrence: const RecurrenceRule.timesPerWeek(5),
      ),
      daily(
        id: LifeGridIds.learnOrBuild,
        title: 'Learn or Build',
        categoryId: 'coding',
        xp: 10,
        note:
            'At least 20 focused minutes learning or building something '
            'related to Flutter, Dart, iOS development, app development, '
            'AI-assisted development, or one of your active projects.',
        recurrence: const RecurrenceRule.timesPerWeek(4),
        target: const HabitTarget(amount: 20, unit: TargetUnit.minutes),
      ),
    ];

    TaskDefinition weekly({
      required String id,
      required String title,
      required String categoryId,
      required int xp,
      required String note,
      RecurrenceRule? recurrence,
      HabitTarget? target,
    }) {
      return TaskDefinition(
        id: id,
        title: title,
        note: note,
        section: 'Life Grid',
        categoryId: categoryId,
        xp: xp,
        target: target,
        recurrence: recurrence ?? const RecurrenceRule.timesPerWeek(1),
        createdAt: now,
        updatedAt: now,
      );
    }

    final weeklyTasks = [
      weekly(
        id: LifeGridIds.weeklyWorkout,
        title: 'Workout',
        categoryId: 'health',
        xp: 20,
        note: 'Minimum 2 workouts per week. A 3rd workout counts as bonus.',
        recurrence: const RecurrenceRule.timesPerWeek(2),
      ),
      weekly(
        id: LifeGridIds.weighReview,
        title: 'Weigh & Review',
        categoryId: 'health',
        xp: 10,
        note:
            'Record ~3 weigh-ins during the week and enter the weekly average.',
      ),
      weekly(
        id: LifeGridIds.courageChallenge,
        title: 'Courage Challenge',
        categoryId: 'courage',
        xp: 25,
        note:
            'Do one thing that makes you slightly uncomfortable but supports '
            'the person you want to become — ask instead of wondering, speak '
            'openly, share something you made, attend something unfamiliar, '
            'talk to somebody new, say no when appropriate, try something you '
            'might fail at.',
      ),
      weekly(
        id: LifeGridIds.createConnection,
        title: 'Create Connection',
        categoryId: 'relationships',
        xp: 15,
        note:
            'Create one genuine opportunity for connection — invite a friend '
            'somewhere, organize a game night, ask someone to grab food or '
            'coffee, contact somebody you haven\'t seen recently. Success is '
            'measured by your action, not the other person\'s response.',
      ),
      weekly(
        id: LifeGridIds.improvementIdea,
        title: 'Improvement Idea',
        categoryId: 'work',
        xp: 10,
        note:
            'Record at least one idea for improving a process, automating '
            'something, solving a problem, creating a product, or challenging '
            'an inefficient existing process.',
      ),
      weekly(
        id: LifeGridIds.sideBusiness,
        title: 'Side Business Session',
        categoryId: 'financial',
        xp: 20,
        note:
            'At least 60 focused minutes developing, researching or '
            'validating a realistic additional income source or side business.',
        target: const HabitTarget(amount: 60, unit: TargetUnit.minutes),
      ),
      weekly(
        id: LifeGridIds.learningSession,
        title: 'Learning Session',
        categoryId: 'learning',
        xp: 20,
        note:
            '60–90 focused minutes improving Flutter, Dart, iOS, Xcode, '
            'product development, or another useful skill.',
        target: const HabitTarget(amount: 60, unit: TargetUnit.minutes),
      ),
      weekly(
        id: LifeGridIds.deepBuild,
        title: 'Deep Build',
        categoryId: 'coding',
        xp: 30,
        note:
            'At least two focused hours moving one active project forward — '
            'ideally ending with something tangible: a working feature, '
            'prototype, design, tested functionality, published build, useful '
            'document, or user feedback.',
        target: const HabitTarget(amount: 120, unit: TargetUnit.minutes),
      ),
      weekly(
        id: LifeGridIds.funWithoutProductivity,
        title: 'Fun Without Productivity',
        categoryId: 'mindfulness',
        xp: 15,
        note:
            'Do something because you enjoy it, not because it is '
            'productive — board games, friends, gaming, a trip, a movie, a '
            'hobby, a relaxed evening.',
      ),
      weekly(
        id: LifeGridIds.weeklyLifeReview,
        title: 'Weekly Life Review',
        categoryId: 'mindfulness',
        xp: 20,
        note:
            'Did I train at least twice? What was my weight trend? What did '
            'I do despite overthinking? What did I create or learn? Did I '
            'create meaningful social contact? Did I actually enjoy part of '
            'this week? What is the ONE most important thing next week?',
        recurrence: const RecurrenceRule.fixedWeekdays({7}),
      ),
    ];

    TaskDefinition monthly({
      required String id,
      required String title,
      required String categoryId,
      required int xp,
      required String note,
    }) {
      return TaskDefinition(
        id: id,
        title: title,
        note: note,
        section: 'Monthly Review',
        categoryId: categoryId,
        xp: xp,
        recurrence: const RecurrenceRule.monthly(28),
        createdAt: now,
        updatedAt: now,
      );
    }

    final monthlyReview = [
      monthly(
        id: LifeGridIds.monthlyHealth,
        title: 'Monthly Review: Health',
        categoryId: 'health',
        xp: 50,
        note:
            'Review weight trend, training consistency, energy, fitness. '
            'Long-term goal ~100kg or slightly below; starting range '
            '~117–118kg.',
      ),
      monthly(
        id: LifeGridIds.monthlyCourage,
        title: 'Monthly Review: Courage & Confidence',
        categoryId: 'courage',
        xp: 50,
        note:
            'Identify the most meaningful situation this month where you '
            'acted despite insecurity or overthinking.',
      ),
      monthly(
        id: LifeGridIds.monthlyRelationships,
        title: 'Monthly Review: Friends & Relationships',
        categoryId: 'relationships',
        xp: 40,
        note:
            'Who initiated contact? Who did you enjoy spending time with? '
            'Which relationships felt reciprocal? Where did you spend too '
            'much energy chasing clarity or attention? Not meant to score '
            'people — just to notice healthy reciprocity.',
      ),
      monthly(
        id: LifeGridIds.monthlyCareer,
        title: 'Monthly Review: Career & Meaning',
        categoryId: 'work',
        xp: 40,
        note:
            'Choose one idea — process improvement, new thinking, '
            'automation, product creation, professional independence — and '
            'decide whether to pursue, save or discard it.',
      ),
      monthly(
        id: LifeGridIds.monthlyFinancial,
        title: 'Monthly Review: Financial Freedom',
        categoryId: 'financial',
        xp: 50,
        note:
            'Review saving/investing, side-business progress, additional-'
            'income experiments. Run or define at least one small validation '
            'experiment instead of a large financial commitment based only '
            'on an idea.',
      ),
      monthly(
        id: LifeGridIds.monthlyLearning,
        title: 'Monthly Review: Adventure & Learning',
        categoryId: 'learning',
        xp: 50,
        note:
            'Record at least one new experience, new place, meaningful '
            'learning milestone, or spontaneous activity.',
      ),
      monthly(
        id: LifeGridIds.monthlyCreativity,
        title: 'Ship Something',
        categoryId: 'coding',
        xp: 60,
        note:
            'Complete something tangible: an app feature, prototype, '
            'TestFlight build, tester release, finished design, useful tool, '
            'or published creation.',
      ),
      monthly(
        id: LifeGridIds.monthlyHappiness,
        title: 'Monthly Review: Happiness & Balance',
        categoryId: 'mindfulness',
        xp: 50,
        note:
            'Did you actually enjoy the life you lived this month? Score '
            '1–10. What gave you energy? What drained you? What should you '
            'do more of? What should you reduce? What is one change for next '
            'month?',
      ),
    ];

    for (final definition in [
      ...dailyHabits,
      ...weeklyTasks,
      ...monthlyReview,
    ]) {
      _definitions.add(definition);
      await _database.saveDefinition(definition);
    }

    Future<void> milestone({
      required String id,
      required String title,
      required String categoryId,
      required int xp,
      String description = '',
      GoalStatus status = GoalStatus.inProgress,
    }) async {
      final record = Milestone(
        id: id,
        title: title,
        description: description,
        categoryId: categoryId,
        xp: xp,
        status: GoalStatus.notStarted,
        createdAt: now,
      );
      _milestones.add(record);
      await _database.saveMilestone(record);
      if (status != GoalStatus.notStarted) {
        await _plan.setMilestoneStatus(id, status);
      }
    }

    await milestone(
      id: LifeGridIds.milestoneLearnFlutter,
      title: 'Learn Flutter / iOS',
      categoryId: 'coding',
      xp: 100,
      status: GoalStatus.inProgress,
    );
    await milestone(
      id: LifeGridIds.milestonePublishApp,
      title: 'Publish an iOS App',
      categoryId: 'coding',
      xp: 150,
      description:
          'Dev environment → working app → stable core → testing → '
          'TestFlight → App Store preparation → publication.',
      status: GoalStatus.inProgress,
    );
    await milestone(
      id: LifeGridIds.milestoneReach100kg,
      title: 'Reach ~100 kg',
      categoryId: 'health',
      xp: 100,
      status: GoalStatus.inProgress,
    );
    await milestone(
      id: LifeGridIds.milestoneHardware,
      title: 'Development hardware acquired',
      categoryId: 'coding',
      xp: 50,
      description:
          '2020 M1 MacBook Air, acquired to support learning iOS '
          'development and building future projects.',
      status: GoalStatus.achieved,
    );

    await _database.saveSetting('lifeGridSeeded', true);
  }

  /// Call when the app resumes / on the first frame of a new day.
  Future<void> maybeRollover() async {
    if (_lastRolloverKey == dayKey(DateTime.now())) return;
    await _plan.refreshMaterialisation();
    await _runRollover();
    notifyListeners();
  }

  Future<void> _runRollover() async {
    _lastRolloverKey = dayKey(DateTime.now());
    _dismissedOverloadHints.clear();
    await _database.saveSetting('lastRolloverKey', _lastRolloverKey);
    await _checkAchievements();
  }

  // ---- Read selectors --------------------------------------------------------

  DateTime get today => dateOnly(DateTime.now());
  bool get darkMode => _darkMode;
  List<int> get dayTargetXp => List.unmodifiable(_dayTargetXp);
  String get languageCode => 'en';

  List<TaskCategory> get categories => List.unmodifiable(
    [..._categories]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
  );

  List<TaskCategory> get activeCategories =>
      categories.where((c) => !c.isArchived).toList();

  TaskCategory categoryById(String id) {
    return _categories.firstWhere(
      (category) => category.id == id,
      orElse: () => TaskCategory(
        id: id,
        name: 'Uncategorized',
        colorValue: 0xFF9E9E9E,
        iconKey: 'star',
        sortOrder: 999,
      ),
    );
  }

  List<TaskDefinition> get definitions => List.unmodifiable(_definitions);

  /// Raw occurrences, for the statistics selectors.
  List<TaskOccurrence> get allOccurrences => List.unmodifiable(_occurrences);

  List<TaskDefinition> get activeDefinitions =>
      _definitions.where((d) => !d.isArchived).toList()..sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

  /// Fixed-weekday and paused definitions the "add existing" picker offers.
  List<TaskDefinition> get attachableDefinitions => activeDefinitions
      .where((d) => d.recurrence.kind == RecurrenceKind.fixedWeekdays)
      .toList();

  List<TaskDefinition> get quotaDefinitions => _definitions
      .where(
        (d) => d.isActive && d.recurrence.kind == RecurrenceKind.timesPerWeek,
      )
      .toList();

  /// Future one-off tasks (no definition), for the "Einmalig" habits filter.
  List<TaskOccurrence> get upcomingOneOffs {
    final list =
        _occurrences
            .where(
              (o) =>
                  o.sourceDefinitionId == null &&
                  !o.isCompleted &&
                  !o.isSkipped &&
                  !o.date.isBefore(today),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  List<Proposal> get pendingProposals =>
      _proposals.where((p) => p.status == ProposalStatus.pending).toList();

  List<WeekTemplate> get templates => List.unmodifiable(_templates);

  Map<String, DateTime> get achievementUnlocks =>
      Map.unmodifiable(_achievementUnlocks);

  List<String> takeAchievementToasts() {
    final toasts = List<String>.from(_pendingAchievementToasts);
    _pendingAchievementToasts.clear();
    return toasts;
  }

  // ---- Life Grid --------------------------------------------------------

  List<Milestone> get milestones => List.unmodifiable(_milestones);
  List<WeightEntry> get weightEntries => List.unmodifiable(_weightEntries);
  WeightEntry? get latestWeightEntry =>
      _weightEntries.isEmpty ? null : _weightEntries.last;

  /// The eight life-area categories, in Life Grid display order.
  List<TaskCategory> get lifeAreaCategories {
    final byId = {for (final c in _categories) c.id: c};
    return [
      for (final seed in lifeAreaSeeds)
        if (byId[seed.categoryId] != null) byId[seed.categoryId]!,
    ];
  }

  List<Milestone> milestonesForCategory(String categoryId) =>
      _milestones.where((m) => m.categoryId == categoryId).toList();

  /// XP awarded this calendar month for tasks/milestones in [categoryId].
  int xpThisMonthForCategory(String categoryId) {
    final now = DateTime.now();
    var xp = 0;
    for (final occurrence in _occurrences) {
      if (occurrence.categoryId != categoryId) continue;
      final completion = occurrence.completion;
      if (completion == null) continue;
      if (completion.completedAt.year != now.year ||
          completion.completedAt.month != now.month) {
        continue;
      }
      xp += completion.awardedXp;
    }
    return xp;
  }

  Future<void> logWeight(DateTime date, double kg) async {
    await _plan.logWeight(date, kg);
    await _afterWrite();
  }

  Future<void> deleteWeightEntry(String id) async {
    await _plan.deleteWeightEntry(id);
    await _afterWrite();
  }

  Future<Milestone> addMilestone({
    required String title,
    required String categoryId,
    required int xp,
    String description = '',
    DateTime? targetDate,
  }) async {
    final milestone = await _plan.addMilestone(
      title: title,
      categoryId: categoryId,
      xp: xp,
      description: description,
      targetDate: targetDate,
    );
    await _afterWrite();
    return milestone;
  }

  Future<void> updateMilestone(
    String id, {
    String? title,
    String? description,
    String? categoryId,
    int? xp,
    DateTime? targetDate,
    bool clearTargetDate = false,
  }) async {
    await _plan.updateMilestone(
      id,
      title: title,
      description: description,
      categoryId: categoryId,
      xp: xp,
      targetDate: targetDate,
      clearTargetDate: clearTargetDate,
    );
    await _afterWrite();
  }

  Future<void> setMilestoneStatus(String id, GoalStatus status) async {
    await _plan.setMilestoneStatus(id, status);
    await _afterWrite();
  }

  Future<void> deleteMilestone(String id) async {
    await _plan.deleteMilestone(id);
    await _afterWrite();
  }

  /// This week's count of fully-completed occurrences from one seeded Life
  /// Grid definition (workouts, Courage Challenges, ...).
  int weeklyCompletionCount(String definitionId) {
    return _occurrences
        .where(
          (o) =>
              o.sourceDefinitionId == definitionId &&
              o.isFullyCompleted &&
              isSameWeek(o.date, today),
        )
        .length;
  }

  /// "2 workouts + 1 build session + 1 Courage Challenge" — a meaningful week
  /// even if it isn't a perfect one. See `domain/life_grid.dart`.
  MinimumViableWeekStatus get minimumViableWeekStatus {
    return MinimumViableWeekStatus(
      workoutsDone: weeklyCompletionCount(LifeGridIds.weeklyWorkout),
      workoutsTarget: ninetyDayFocus.minWorkoutsPerWeek,
      deepBuildDone: weeklyCompletionCount(LifeGridIds.deepBuild) > 0,
      courageDone: weeklyCompletionCount(LifeGridIds.courageChallenge) > 0,
    );
  }

  /// All occurrences on [date], ordered: open first → category sort order →
  /// XP desc; completed / skipped collapse to the bottom.
  List<TaskOccurrence> occurrencesForDay(DateTime date) {
    final key = dayKey(date);
    final list = _occurrences.where((o) => o.dateKey == key).toList();
    list.sort(_questOrder);
    return list;
  }

  int _questOrder(TaskOccurrence a, TaskOccurrence b) {
    int rank(TaskOccurrence o) => o.isCompleted || o.isSkipped ? 1 : 0;
    final byState = rank(a).compareTo(rank(b));
    if (byState != 0) return byState;

    final byCategory = categoryById(
      a.categoryId,
    ).sortOrder.compareTo(categoryById(b.categoryId).sortOrder);
    if (byCategory != 0) return byCategory;

    final byXp = b.xp.compareTo(a.xp);
    if (byXp != 0) return byXp;
    return a.createdAt.compareTo(b.createdAt);
  }

  List<TaskOccurrence> get todaysQuests => occurrencesForDay(today);

  /// Today's (or [date]'s) occurrences grouped into sections, in display
  /// order — the "$ habits" list on the home screen.
  List<MapEntry<String, List<TaskOccurrence>>> groupedHabitsForDay(
    DateTime date,
  ) {
    return groupBySection(occurrencesForDay(date), (o) => o.section);
  }

  int get dailyGoalPercent => _dailyGoalPercent;
  double get dailyGoalFraction => _dailyGoalPercent / 100;

  DataWindow get statsWindow => _statsWindow;

  void setStatsWindow(DataWindow window) {
    if (_statsWindow == window) return;
    _statsWindow = window;
    notifyListeners();
  }

  OverviewStats overviewStats({DataWindow? window, DateTime? customStart}) =>
      computeOverviewStats(
        occurrences: _occurrences,
        definitions: _definitions,
        today: today,
        window: window ?? _statsWindow,
        goalFraction: dailyGoalFraction,
        customStart: customStart,
      );

  List<List<HeatCell>> contributionHeatmap({int weeks = 20}) =>
      buildContributionHeatmap(
        occurrences: _occurrences,
        today: today,
        weeks: weeks,
      );

  int completedCountForDate(DateTime date) =>
      occurrencesForDay(date).where((o) => o.isCompleted).length;

  /// Completed-task count + awarded XP over the Mon–Sun week at [weekOffset]
  /// (0 = this week, -1 = last week).
  ({int tasks, int xp}) weekTotals(int weekOffset) {
    var tasks = 0;
    var xp = 0;
    for (final day in weekDays(weekOffset)) {
      for (final occurrence in occurrencesForDay(day)) {
        final completion = occurrence.completion;
        if (completion == null) continue;
        tasks++;
        xp += completion.awardedXp;
      }
    }
    return (tasks: tasks, xp: xp);
  }

  int get totalXp => statsSnapshot.totalXp;

  LevelProgress get levelProgress =>
      levelProgressFor(totalXp, curve: _levelCurve);

  // Gamification settings, read-only.
  double get xpMultiplier => _xpMultiplier;
  LevelCurve get levelCurve => _levelCurve;
  int get perfectDayBonus => _perfectDayBonus;
  bool get streakProtection => _streakProtection;
  bool get dailyReminder => _dailyReminder;
  String get reminderTime => _reminderTime;
  bool get motivationMessages => _motivationMessages;
  bool get showAtmosphere => _showAtmosphere;

  int get _graceLimit => _streakProtection ? 1 : 0;

  /// Perfect-day bonus that applies to [date] (0 if disabled or not perfect).
  int bonusXpForDate(DateTime date) {
    if (_perfectDayBonus <= 0) return 0;
    return isPerfectDay(occurrencesForDay(date)) ? _perfectDayBonus : 0;
  }

  bool takePerfectToast() {
    final pending = _pendingPerfectToast;
    _pendingPerfectToast = false;
    return pending;
  }

  DayWorkload workloadForDate(DateTime date) => workloadForDay(
    date: date,
    occurrences: _occurrences,
    dayTargets: _dayTargetXp,
  );

  /// Task XP completed on [date]; excludes the perfect-day bonus.
  int completedXpForDate(DateTime date) => workloadForDate(date).completedXp;

  /// Total XP possible on [date] (all non-skipped task XP + perfect bonus).
  int possibleXpForDate(DateTime date) {
    final base = workloadForDate(date).plannedXp;
    return base + (_perfectDayBonus > 0 && base > 0 ? _perfectDayBonus : 0);
  }

  /// The Mon–Sun days for [weekOffset] (0 = this week, 1 = next week).
  List<DateTime> weekDays(int weekOffset) {
    final monday = weekStart(today).add(Duration(days: 7 * weekOffset));
    return daysInRange(monday, monday.add(const Duration(days: 6)));
  }

  StreakInfo streakFor(String definitionId) {
    final definition = _definitions
        .where((d) => d.id == definitionId)
        .firstOrNull;
    if (definition == null) return const StreakInfo.empty();
    return computeStreak(
      definition: definition,
      occurrences: _occurrences,
      today: today,
      graceLimit: _graceLimit,
    );
  }

  StatsSnapshot get statsSnapshot => buildStatsSnapshot(
    occurrences: _occurrences,
    definitions: _definitions,
    today: today,
    perfectDayBonus: _perfectDayBonus,
    graceLimit: _graceLimit,
    levelCurve: _levelCurve,
  );

  PeriodStats periodStats(StatsPeriod period) => computePeriodStats(
    occurrences: _occurrences,
    today: today,
    period: period,
    perfectDayBonus: _perfectDayBonus,
  );

  /// Weekly completion count for a `timesPerWeek` definition, current week.
  int quotaProgress(String definitionId) {
    final def = _definitions.where((d) => d.id == definitionId).firstOrNull;
    if (def == null) return 0;
    return _occurrences
        .where(
          (o) =>
              o.sourceDefinitionId == definitionId &&
              o.isFullyCompleted &&
              isSameWeek(o.date, today),
        )
        .length;
  }

  int quotaPlaced(String definitionId, int weekOffset) {
    final week = weekDays(weekOffset);
    return _occurrences
        .where(
          (o) =>
              o.sourceDefinitionId == definitionId &&
              week.any((day) => isSameDay(day, o.date)),
        )
        .length;
  }

  /// Overload hint for [date], or null if the day is fine or was dismissed.
  OverloadHint? overloadHintFor(DateTime date) {
    if (_dismissedOverloadHints.contains(dayKey(date))) return null;
    final workload = workloadForDate(date);
    if (!workload.isOverloaded) return null;
    final lightest = lightestOtherDayInWeek(
      from: date,
      today: today,
      occurrences: _occurrences,
      dayTargets: _dayTargetXp,
    );
    return OverloadHint(date: date, lightestDay: lightest);
  }

  void dismissOverloadHint(DateTime date) {
    _dismissedOverloadHints.add(dayKey(date));
    notifyListeners();
  }

  bool canCompleteOn(DateTime date) => isSameDay(date, today);
  bool isPast(DateTime date) => date.isBefore(today);

  // ---- Writes (all via PlanService) --------------------------------------

  Future<void> addOneOff({
    required DateTime date,
    required String title,
    required String categoryId,
    required int xp,
    String note = '',
    String section = '',
    Difficulty? difficulty,
    HabitTarget? target,
    Priority priority = Priority.normal,
    bool isBonus = false,
  }) async {
    await _plan.addOneOff(
      date: date,
      title: title,
      categoryId: categoryId,
      xp: xp,
      note: note,
      section: section,
      difficulty: difficulty,
      target: target,
      priority: priority,
      isBonus: isBonus,
    );
    await _afterWrite();
  }

  Future<void> createRecurring({
    required String title,
    required String categoryId,
    required int xp,
    required RecurrenceRule recurrence,
    String note = '',
    String section = '',
    Difficulty? difficulty,
    HabitTarget? target,
    Priority priority = Priority.normal,
    bool? isFocus,
    bool isBonus = false,
  }) async {
    await _plan.createRecurring(
      title: title,
      categoryId: categoryId,
      xp: xp,
      recurrence: recurrence,
      note: note,
      section: section,
      difficulty: difficulty,
      target: target,
      priority: priority,
      isFocus: isFocus,
      isBonus: isBonus,
    );
    await _afterWrite();
  }

  Future<void> editDefinition(
    String id, {
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
    bool? isPaused,
    bool? isArchived,
  }) async {
    await _plan.editDefinition(
      id,
      title: title,
      note: note,
      section: section,
      categoryId: categoryId,
      difficulty: difficulty,
      clearDifficulty: clearDifficulty,
      xp: xp,
      target: target,
      clearTarget: clearTarget,
      priority: priority,
      isFocus: isFocus,
      clearIsFocus: clearIsFocus,
      isBonus: isBonus,
      recurrence: recurrence,
      isPaused: isPaused,
      isArchived: isArchived,
    );
    await _afterWrite();
  }

  Future<void> deleteDefinition(String id) async {
    await _plan.deleteDefinition(id);
    await _afterWrite();
  }

  Future<void> attachDefinitionToDate({
    required String definitionId,
    required DateTime date,
    required AttachScope scope,
  }) async {
    await _plan.attachDefinitionToDate(
      definitionId: definitionId,
      date: date,
      scope: scope,
    );
    await _afterWrite();
  }

  Future<void> placeQuotaOccurrence({
    required String definitionId,
    required DateTime date,
  }) async {
    await _plan.placeQuotaOccurrence(definitionId: definitionId, date: date);
    await _afterWrite();
  }

  Future<void> editOccurrence(
    String id, {
    String? title,
    String? note,
    String? section,
    String? categoryId,
    Difficulty? difficulty,
    bool clearDifficulty = false,
    int? xp,
    HabitTarget? target,
    bool clearTarget = false,
  }) async {
    await _plan.editOccurrence(
      id,
      title: title,
      note: note,
      section: section,
      categoryId: categoryId,
      difficulty: difficulty,
      clearDifficulty: clearDifficulty,
      xp: xp,
      target: target,
      clearTarget: clearTarget,
    );
    await _afterWrite();
  }

  Future<void> removeOccurrence(String id) async {
    await _plan.removeOccurrence(id);
    await _afterWrite();
  }

  Future<void> skipOccurrence(String id) async {
    await _plan.skipOccurrence(id);
    await _afterWrite();
  }

  Future<void> unskipOccurrence(String id) async {
    await _plan.unskipOccurrence(id);
    await _afterWrite();
  }

  Future<void> moveOccurrence(String id, DateTime toDate) async {
    await _plan.moveOccurrence(id, toDate);
    await _afterWrite();
  }

  Future<void> copyOccurrence(String id, DateTime toDate) async {
    await _plan.copyOccurrence(id, toDate);
    await _afterWrite();
  }

  Future<void> completeQuest(
    String id, {
    double fraction = 1.0,
    String note = '',
  }) async {
    final wasPerfect = isPerfectDay(todaysQuests);
    await _plan.complete(
      id,
      fraction: fraction,
      note: note,
      xpMultiplier: _xpMultiplier,
    );
    if (_perfectDayBonus > 0 &&
        !wasPerfect &&
        isPerfectDay(todaysQuests) &&
        _lastPerfectToastKey != dayKey(today)) {
      _lastPerfectToastKey = dayKey(today);
      _pendingPerfectToast = true;
      await _database.saveSetting('lastPerfectToastKey', _lastPerfectToastKey);
    }
    await _afterWrite();
  }

  Future<void> undoComplete(String id) async {
    await _plan.undoComplete(id);
    await _afterWrite();
  }

  /// Logs progress against a quantity-target habit (e.g. "6h59min of 7h
  /// sleep"). Reaching the target auto-completes it for full XP.
  Future<void> logProgress(String id, double amount) async {
    final wasPerfect = isPerfectDay(todaysQuests);
    await _plan.logProgress(id, amount, xpMultiplier: _xpMultiplier);
    if (_perfectDayBonus > 0 &&
        !wasPerfect &&
        isPerfectDay(todaysQuests) &&
        _lastPerfectToastKey != dayKey(today)) {
      _lastPerfectToastKey = dayKey(today);
      _pendingPerfectToast = true;
      await _database.saveSetting('lastPerfectToastKey', _lastPerfectToastKey);
    }
    await _afterWrite();
  }

  Future<void> editAwardedXp(String id, int xp) async {
    await _plan.editAwardedXp(id, xp);
    await _afterWrite();
  }

  Future<TemplateApplyResult> applyTemplate({
    required String templateId,
    required int weekOffset,
  }) async {
    final result = await _plan.applyTemplate(
      templateId: templateId,
      weekStartDate: weekStart(today).add(Duration(days: 7 * weekOffset)),
    );
    await _afterWrite();
    return result;
  }

  Future<void> saveWeekAsTemplate({
    required String name,
    required int weekOffset,
  }) async {
    await _plan.saveWeekAsTemplate(
      name: name,
      weekStartDate: weekStart(today).add(Duration(days: 7 * weekOffset)),
    );
    await _afterWrite();
  }

  Future<void> setDefaultWeekTemplate(String? templateId) async {
    _defaultWeekTemplateId = templateId ?? '';
    await _database.saveSetting('defaultWeekTemplateId', templateId);
    await _afterWrite();
  }

  Future<TemplateApplyResult> applyDefaultWeekTemplate({
    required int weekOffset,
  }) async {
    final templateId = _defaultWeekTemplateId;
    if (templateId.isEmpty) {
      return const TemplateApplyResult(added: 0, skipped: 0);
    }
    final result = await applyTemplate(
      templateId: templateId,
      weekOffset: weekOffset,
    );
    return result;
  }

  Future<void> deleteTemplate(String id) async {
    await _plan.deleteTemplate(id);
    await _afterWrite();
  }

  // ---- Categories --------------------------------------------------------

  Future<void> addCategory({
    required String name,
    required int colorValue,
    required String iconKey,
  }) async {
    await _plan.addCategory(
      name: name,
      colorValue: colorValue,
      iconKey: iconKey,
    );
    await _afterWrite();
  }

  Future<void> updateCategory(
    String id, {
    String? name,
    int? colorValue,
    String? iconKey,
    bool? isArchived,
    bool? isFocusArea,
  }) async {
    await _plan.updateCategory(
      id,
      name: name,
      colorValue: colorValue,
      iconKey: iconKey,
      isArchived: isArchived,
      isFocusArea: isFocusArea,
    );
    await _afterWrite();
  }

  Future<void> deleteCategory(String id) async {
    await _plan.deleteCategory(id);
    await _afterWrite();
  }

  // ---- Proposals --------------------------------------------------------

  Future<void> approveProposal(String id) async {
    await _plan.apply(id);
    await _afterWrite();
  }

  Future<void> rejectProposal(String id) async {
    await _plan.rejectProposal(id);
    await _afterWrite();
  }

  // ---- Settings --------------------------------------------------------

  Future<void> setUserName(String value) async {
    final normalized = value.trim();
    if (_userName == normalized) return;
    _userName = normalized;
    await _setAndSave('userName', _userName);
  }

  Future<void> setUserBirthday(DateTime? value) async {
    if (value == null && _userBirthday == null) return;
    if (value != null &&
        _userBirthday != null &&
        _userBirthday!.isAtSameMomentAs(value)) {
      return;
    }
    _userBirthday = value;
    await _database.saveSetting('userBirthday', value?.toIso8601String());
    notifyListeners();
  }

  String greetingFor(DateTime now) {
    final name = userName;
    final birthday = _birthdayMatches(now);

    if (birthday) {
      return name.isEmpty ? 'Happy Birthday!' : 'Happy Birthday, $name!';
    }

    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return name.isEmpty ? '$greeting!' : '$greeting, $name!';
  }

  bool isBirthdayToday() => _birthdayMatches(DateTime.now());

  bool _birthdayMatches(DateTime now) {
    if (_userBirthday == null) return false;
    return _userBirthday!.month == now.month && _userBirthday!.day == now.day;
  }

  String _formatBirthday(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> setDarkMode(bool value) async {
    if (_darkMode == value) return;
    _darkMode = value;
    notifyListeners();
    await _database.saveSetting('darkMode', value);
  }

  Future<void> setDayTargetXp(int weekdayIndex, int value) async {
    if (weekdayIndex < 0 || weekdayIndex > 6) return;
    _dayTargetXp = List.of(_dayTargetXp)
      ..[weekdayIndex] = value.clamp(0, 100000);
    notifyListeners();
    await _database.saveSetting('dayTargetXp', _dayTargetXp);
  }

  Future<void> _setAndSave(String key, Object? value) async {
    notifyListeners();
    await _database.saveSetting(key, value);
  }

  Future<void> setXpMultiplier(double value) async {
    _xpMultiplier = double.parse(value.clamp(0.1, 5.0).toStringAsFixed(1));
    await _setAndSave('xpMultiplier', _xpMultiplier);
  }

  Future<void> setLevelCurve(LevelCurve value) async {
    _levelCurve = value;
    await _setAndSave('levelCurve', value.name);
  }

  Future<void> setPerfectDayBonus(int value) async {
    _perfectDayBonus = value.clamp(0, 500);
    await _setAndSave('perfectDayBonus', _perfectDayBonus);
  }

  Future<void> setStreakProtection(bool value) async {
    _streakProtection = value;
    await _setAndSave('streakProtection', value);
  }

  Future<void> setDailyReminder(bool value) async {
    _dailyReminder = value;
    await _setAndSave('dailyReminder', value);
  }

  Future<void> setReminderTime(String value) async {
    _reminderTime = value;
    await _setAndSave('reminderTime', value);
  }

  Future<void> setMotivationMessages(bool value) async {
    _motivationMessages = value;
    await _setAndSave('motivationMessages', value);
  }

  Future<void> setShowAtmosphere(bool value) async {
    _showAtmosphere = value;
    await _setAndSave('showAtmosphere', value);
  }

  Future<void> setDailyGoalPercent(int value) async {
    _dailyGoalPercent = value.clamp(1, 100);
    await _setAndSave('dailyGoalPercent', _dailyGoalPercent);
  }

  Future<void> setWeeklyReviewDay(int value) async {
    final normalized = value.clamp(1, 7);
    if (_weeklyReviewDay == normalized) return;
    _weeklyReviewDay = normalized;
    await _setAndSave('weeklyReviewDay', normalized);
  }

  Future<void> markWeeklyReviewDone({
    required String wins,
    required String misses,
    required String nextFocus,
  }) async {
    final weekKey = dayKey(weekStart(today));
    _weeklyReviewCompletedWeekKey = weekKey;

    final payload = <String, String>{
      'wins': wins.trim(),
      'misses': misses.trim(),
      'nextFocus': nextFocus.trim(),
    };

    await _database.saveSetting('weeklyReviewDoneKey', weekKey);
    await _database.saveSetting('weeklyReview-$weekKey', jsonEncode(payload));
    notifyListeners();
  }

  Future<Map<String, String>> weeklyReviewSnapshotForWeek(DateTime date) async {
    final key = dayKey(weekStart(date));
    final raw = await _database.loadSetting('weeklyReview-$key');
    if (raw == null) return const {'wins': '', 'misses': '', 'nextFocus': ''};
    try {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      return {
        'wins': (decoded['wins'] as String?) ?? '',
        'misses': (decoded['misses'] as String?) ?? '',
        'nextFocus': (decoded['nextFocus'] as String?) ?? '',
      };
    } catch (_) {
      return const {'wins': '', 'misses': '', 'nextFocus': ''};
    }
  }

  // ---- Backup --------------------------------------------------------

  Future<String> exportBackupJson() => _backup.exportJson();

  Future<void> importBackupJson(String raw) async {
    final envelope = _backup.parseAndValidate(raw);
    await _backup.importValidated(envelope);
    await initialize();
  }

  Future<void> clearAllData() async {
    await _database.clearAll();
    _definitions.clear();
    _occurrences.clear();
    _templates.clear();
    _proposals.clear();
    _milestones.clear();
    _weightEntries.clear();
    _achievementUnlocks.clear();
    _categories.clear();
    for (final category in TaskCategory.defaults()) {
      _categories.add(category);
      await _database.saveCategory(category);
    }
    _dayTargetXp = List.of(defaultDayTargetXp);
    notifyListeners();
  }

  // ---- Internals --------------------------------------------------------

  Future<void> _afterWrite() async {
    await _checkAchievements();
    notifyListeners();
  }

  Future<void> _checkAchievements() async {
    final unlocked = newlyUnlockedAchievements(
      snapshot: statsSnapshot,
      alreadyUnlocked: _achievementUnlocks.keys.toSet(),
    );
    if (unlocked.isEmpty) return;
    final now = DateTime.now();
    for (final id in unlocked) {
      _achievementUnlocks[id] = now;
      _pendingAchievementToasts.add(id);
      await _database.saveAchievementUnlock(id, now);
    }
  }
}

/// A rule-based nudge shown when a day is planned over its target.
class OverloadHint {
  const OverloadHint({required this.date, required this.lightestDay});
  final DateTime date;
  final DateTime? lightestDay;
}
