import 'package:flutter/foundation.dart';

import '../data/motivation_database.dart';
import '../domain/achievements.dart';
import '../domain/difficulty.dart';
import '../domain/progression.dart';
import '../domain/statistics.dart';
import '../domain/streaks.dart';
import '../domain/workload.dart';
import '../models/proposal.dart';
import '../models/recurrence_rule.dart';
import '../models/task_category.dart';
import '../models/task_definition.dart';
import '../models/task_occurrence.dart';
import '../models/week_template.dart';
import '../services/backup_service.dart';
import '../services/plan_service.dart';
import '../util/dates.dart';

/// The single in-memory hub. Holds the loaded lists, exposes read selectors
/// backed by `lib/domain/`, and forwards every write to [PlanService].
class MotivationController extends ChangeNotifier {
  MotivationController(this._database)
      : _backup = BackupService(_database);

  final MotivationDatabase _database;
  final BackupService _backup;
  late final PlanService _plan;

  final List<TaskCategory> _categories = [];
  final List<TaskDefinition> _definitions = [];
  final List<TaskOccurrence> _occurrences = [];
  final List<WeekTemplate> _templates = [];
  final List<Proposal> _proposals = [];
  final Map<String, DateTime> _achievementUnlocks = {};

  bool _darkMode = true;
  List<int> _dayTargetXp = List.of(defaultDayTargetXp);
  String _lastRolloverKey = '';
  final Set<String> _dismissedOverloadHints = {};

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
    _achievementUnlocks
      ..clear()
      ..addAll(snapshot.achievementUnlocks);

    _darkMode = snapshot.settings['darkMode'] as bool? ?? true;
    final storedTargets = snapshot.settings['dayTargetXp'];
    if (storedTargets is List && storedTargets.length == 7) {
      _dayTargetXp = [for (final t in storedTargets) (t as num).toInt()];
    }
    _lastRolloverKey = snapshot.settings['lastRolloverKey'] as String? ?? '';

    if (_categories.isEmpty) {
      for (final category in TaskCategory.defaults()) {
        _categories.add(category);
        await _database.saveCategory(category);
      }
    }

    _plan = PlanService(
      database: _database,
      categories: _categories,
      definitions: _definitions,
      occurrences: _occurrences,
      templates: _templates,
      proposals: _proposals,
    );

    await _plan.refreshMaterialisation();
    await _runRollover();

    _ready = true;
    notifyListeners();
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
  String get languageCode => 'de';

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
        name: 'Ohne Kategorie',
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
      _definitions.where((d) => !d.isArchived).toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  /// Fixed-weekday and paused definitions the "add existing" picker offers.
  List<TaskDefinition> get attachableDefinitions => activeDefinitions
      .where((d) => d.recurrence.kind == RecurrenceKind.fixedWeekdays)
      .toList();

  List<TaskDefinition> get quotaDefinitions => _definitions
      .where((d) => d.isActive && d.recurrence.kind == RecurrenceKind.timesPerWeek)
      .toList();

  List<Proposal> get pendingProposals => _proposals
      .where((p) => p.status == ProposalStatus.pending)
      .toList();

  List<WeekTemplate> get templates => List.unmodifiable(_templates);

  Map<String, DateTime> get achievementUnlocks =>
      Map.unmodifiable(_achievementUnlocks);

  List<String> takeAchievementToasts() {
    final toasts = List<String>.from(_pendingAchievementToasts);
    _pendingAchievementToasts.clear();
    return toasts;
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

    final byCategory = categoryById(a.categoryId)
        .sortOrder
        .compareTo(categoryById(b.categoryId).sortOrder);
    if (byCategory != 0) return byCategory;

    final byXp = b.xp.compareTo(a.xp);
    if (byXp != 0) return byXp;
    return a.createdAt.compareTo(b.createdAt);
  }

  List<TaskOccurrence> get todaysQuests => occurrencesForDay(today);

  int get totalXp => statsSnapshot.totalXp;

  LevelProgress get levelProgress => levelProgressFor(totalXp);

  DayWorkload workloadForDate(DateTime date) => workloadForDay(
        date: date,
        occurrences: _occurrences,
        dayTargets: _dayTargetXp,
      );

  int completedXpForDate(DateTime date) => workloadForDate(date).completedXp;

  /// The Mon–Sun days for [weekOffset] (0 = this week, 1 = next week).
  List<DateTime> weekDays(int weekOffset) {
    final monday = weekStart(today).add(Duration(days: 7 * weekOffset));
    return daysInRange(monday, monday.add(const Duration(days: 6)));
  }

  StreakInfo streakFor(String definitionId) {
    final definition =
        _definitions.where((d) => d.id == definitionId).firstOrNull;
    if (definition == null) return const StreakInfo.empty();
    return computeStreak(
      definition: definition,
      occurrences: _occurrences,
      today: today,
    );
  }

  StatsSnapshot get statsSnapshot => buildStatsSnapshot(
        occurrences: _occurrences,
        definitions: _definitions,
        today: today,
      );

  /// Weekly completion count for a `timesPerWeek` definition, current week.
  int quotaProgress(String definitionId) {
    final def = _definitions.where((d) => d.id == definitionId).firstOrNull;
    if (def == null) return 0;
    return _occurrences
        .where((o) =>
            o.sourceDefinitionId == definitionId &&
            o.isFullyCompleted &&
            isSameWeek(o.date, today))
        .length;
  }

  int quotaPlaced(String definitionId, int weekOffset) {
    final week = weekDays(weekOffset);
    return _occurrences
        .where((o) =>
            o.sourceDefinitionId == definitionId &&
            week.any((day) => isSameDay(day, o.date)))
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
    Difficulty? difficulty,
  }) async {
    await _plan.addOneOff(
      date: date,
      title: title,
      categoryId: categoryId,
      xp: xp,
      note: note,
      difficulty: difficulty,
    );
    await _afterWrite();
  }

  Future<void> createRecurring({
    required String title,
    required String categoryId,
    required int xp,
    required RecurrenceRule recurrence,
    String note = '',
    Difficulty? difficulty,
  }) async {
    await _plan.createRecurring(
      title: title,
      categoryId: categoryId,
      xp: xp,
      recurrence: recurrence,
      note: note,
      difficulty: difficulty,
    );
    await _afterWrite();
  }

  Future<void> editDefinition(
    String id, {
    String? title,
    String? note,
    String? categoryId,
    Difficulty? difficulty,
    bool clearDifficulty = false,
    int? xp,
    RecurrenceRule? recurrence,
    bool? isPaused,
    bool? isArchived,
  }) async {
    await _plan.editDefinition(
      id,
      title: title,
      note: note,
      categoryId: categoryId,
      difficulty: difficulty,
      clearDifficulty: clearDifficulty,
      xp: xp,
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
    String? categoryId,
    Difficulty? difficulty,
    bool clearDifficulty = false,
    int? xp,
  }) async {
    await _plan.editOccurrence(
      id,
      title: title,
      note: note,
      categoryId: categoryId,
      difficulty: difficulty,
      clearDifficulty: clearDifficulty,
      xp: xp,
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
    await _plan.complete(id, fraction: fraction, note: note);
    await _afterWrite();
  }

  Future<void> undoComplete(String id) async {
    await _plan.undoComplete(id);
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
    await _plan.addCategory(name: name, colorValue: colorValue, iconKey: iconKey);
    await _afterWrite();
  }

  Future<void> updateCategory(
    String id, {
    String? name,
    int? colorValue,
    String? iconKey,
    bool? isArchived,
  }) async {
    await _plan.updateCategory(
      id,
      name: name,
      colorValue: colorValue,
      iconKey: iconKey,
      isArchived: isArchived,
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

  Future<void> setDarkMode(bool value) async {
    if (_darkMode == value) return;
    _darkMode = value;
    notifyListeners();
    await _database.saveSetting('darkMode', value);
  }

  Future<void> setDayTargetXp(int weekdayIndex, int value) async {
    if (weekdayIndex < 0 || weekdayIndex > 6) return;
    _dayTargetXp = List.of(_dayTargetXp)..[weekdayIndex] = value.clamp(0, 100000);
    notifyListeners();
    await _database.saveSetting('dayTargetXp', _dayTargetXp);
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
