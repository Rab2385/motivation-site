/// All user-facing copy in one place. Centralised so wording stays
/// consistent and a later i18n pass has a single surface to translate.
class AppText {
  const AppText._();

  // App / navigation (lowercase to match the CLI-menu style: "habits ▾")
  static const appName = 'Quest';
  static const appTagline = 'Habit Tracker';
  static const dashboard = 'dashboard';
  static const today = 'today';
  static const weekPlanning = 'planner';
  static const habits = 'habits';
  static const statistics = 'stats';
  static const achievements = 'achievements';
  static const settings = 'system';
  static const profile = 'profile';
  static const lifeGrid = 'life grid';
  static const help = 'help';

  // Shared actions
  static const save = 'Save';
  static const cancel = 'Cancel';
  static const delete = 'Delete';
  static const edit = 'Edit';
  static const add = 'Add';
  static const close = 'Close';
  static const apply = 'Apply';
  static const discard = 'Discard';
  static const move = 'Move';
  static const copy = 'Copy';
  static const skip = 'Skip';
  static const undo = 'Undo';

  // Habits / quests
  static const quest = 'habit';
  static const quests = 'habits';
  static const newOneOff = 'New task';
  static const newRecurring = 'New habit';
  static const attachExisting = 'Reuse existing habit';
  static const searchHabits = 'Search habits';
  static const all = 'All';
  static const morning = 'Morning';
  static const afternoon = 'Afternoon';
  static const night = 'Night';
  static const general = 'General';
  static const title = 'Title';
  static const note = 'Note';
  static const section = 'Section';
  static const sectionHint = 'e.g. Morning, Deep Work, Wind Down';
  static const category = 'Category';
  static const difficulty = 'Difficulty';
  static const difficultyOptional = 'Difficulty (optional)';
  static const xp = 'XP';
  static const noQuestsToday = 'Nothing scheduled today.';
  static const planYourWeek = 'Add a habit or a one-off task to get started.';
  static const completed = 'Done';
  static const skipped = 'Skipped';
  static const missed = 'Missed';
  static const plannedSkip = 'skipped';

  // Quantity targets
  static const targetLabel = 'Target (optional)';
  static const targetHint = 'e.g. 7 hours, 7000 steps, 30 minutes';
  static const noTarget = 'No target — plain checkbox';
  static const logProgress = 'Log progress';
  static const amount = 'Amount';

  // Completion sheet
  static const completeQuest = 'Complete habit';
  static const howMuch = 'How much did you get done?';
  static const fullyDone = 'Fully done';
  static const partial = 'Partial';
  static const optionalNote = 'Note (optional)';
  static const partialHint =
      'Partial credit awards XP proportionally but does not count for the streak.';

  // Recurrence
  static const repeat = 'Repeats';
  static const fixedWeekdays = 'Fixed weekdays';
  static const timesPerWeek = 'X times a week';
  static const monthly = 'Monthly';
  static const dayOfMonth = 'Day of month';
  static const everyWeek = 'Every week';
  static const justThisWeek = 'Just this week';
  static const attachScopeQuestion = 'How should this be added?';
  static const attachOnce = 'Add once';
  static const attachEvery = 'Repeat from now on';

  // Planner (formerly Wochenplanung)
  static const thisWeek = 'This week';
  static const nextWeek = 'Next week';
  static const plannedXp = 'Planned XP';
  static const workload = 'Load';
  static const overloaded = 'Overloaded';
  static const dayLooksHeavy = 'This day is packed.';
  static const moveSomethingTo = 'Move something to ';
  static const weeklyChips = 'Weekly targets';
  static const templates = 'Templates';
  static const saveAsTemplate = 'Save as template';
  static const applyTemplate = 'Apply template';
  static const setAsDefaultWeek = 'Set as standard week';
  static const useDefaultWeek = 'Use standard week';
  static const templateName = 'Template name';

  // Habits list
  static const currentStreak = 'current streak';
  static const bestStreak = 'best streak';
  static const completionRate = 'completion rate';
  static const pause = 'Pause';
  static const resume = 'Resume';
  static const archive = 'Archive';
  static const noHabitsYet = 'No habits yet — add one below.';

  // Dashboard / home
  static const level = 'level';
  static const xpToNext = 'xp to next level: ';
  static const activeStreaks = 'active streaks';
  static const todaysProgress = 'today';
  static const continueJourney = 'goal';
  static const nextLevelIn = 'xp to next: ';
  static const todaysTasks = 'habits';
  static const ofTasksDone = ' done';
  static const earnedToday = 'earned today: ';
  static const oneTaskToPerfect = '1 left for a perfect day.';
  static const perfectDayReached = 'perfect day!';
  static const weekProgress = 'week';
  static const totalTasksDone = ' total completions';
  static const youreDoingGreat = 'keep going.';
  static const doneTasks = 'done';
  static const collectedXp = 'xp';
  static const longestStreak = 'best streak';

  // Dashboard – misc
  static const dashboardSubline =
      'a bad day with habits beats a good day without them';
  static const daysStreak = ' day streak';
  static const tasksDoneShort = ' done';

  // Today
  static const addTask = 'add task';
  static const tasksDoneOf = ' done';
  static const xpPossible = ' xp possible';
  static const notPerfectJustConsistent =
      "the checkbox doesn't care if you feel like it.";
  static const previousDay = 'Previous day';
  static const nextDay = 'Next day';
  static const backToToday = 'Back to today';
  static const pastDayReadOnly = 'Past days are read-only.';

  // Habits management
  static const myHabits = 'habits';
  static const habitsSubline =
      'a bad day with habits is still better than a good day without them.';
  static const filterAll = 'all';
  static const filterDaily = 'daily';
  static const filterWeekly = 'weekly';
  static const filterOnce = 'one-time';
  static const filterInactive = 'inactive';
  static const daily = 'Daily';
  static const weekly = 'Weekly';
  static const once = 'One-time';

  // Stats
  static const statisticsSubline = 'progress is the sum of small efforts.';
  static const xpHistory = 'xp history';
  static const tasksCompleted = 'completion rate';
  static const weeklyOverview = 'weekly overview';
  static const currentStreakLabel = 'current streak';
  static const longestStreakLabel = 'best streak';
  static const vsPrevious = ' vs. last period';
  static const betterNightByNight =
      "you won't get better overnight. but you'll get better, night after night.";

  // System / settings
  static const settingsSubline = 'configure the app to fit how you work.';
  static const tabGeneral = 'general';
  static const tabGamification = 'gamification';
  static const tabAppearance = 'appearance';
  static const tabData = 'data';
  static const tabAbout = 'about';
  static const xpAndLeveling = 'xp & leveling';
  static const xpMultiplier = 'xp multiplier';
  static const xpMultiplierHint = 'multiply every xp value by a factor.';
  static const levelCurveLabel = 'level curve';
  static const levelCurveHint = 'how much xp the next level needs.';
  static const perfectDayBonusLabel = 'perfect day bonus';
  static const perfectDayBonusHint =
      'bonus xp when every habit is done for the day.';
  static const streakProtectionLabel = 'streak protection';
  static const streakProtectionHint =
      'a single missed day will not break your streak.';
  static const dailyGoalLabel = 'daily goal';
  static const dailyGoalHint =
      'completion rate that counts as "hit your goal" for the day.';
  static const weeklyReviewDayLabel = 'weekly review day';
  static const weeklyReviewDayHint =
      'which day should trigger your weekly reset and reflection?';
  static const notifications = 'notifications';
  static const dailyReminderLabel = 'daily reminder';
  static const dailyReminderHint = 'remind me to check my habits.';
  static const motivationMessagesLabel = 'motivational quotes';
  static const motivationMessagesHint =
      'show the // comment-style quotes around the app.';
  static const notificationsUnavailable =
      "note: browser notifications aren't wired up yet — the setting is saved for when they are.";
  static const showAtmosphereLabel = 'ambient background';
  static const showAtmosphereHint = 'subtle background texture on cards.';
  static const aboutText =
      'Quest is a local-first, gamified habit tracker. Your data stays on this device — no account, no cloud, works offline.';
  static const perfectDayBonusToast = 'Perfect day!';

  static const dayTargets = 'daily xp targets';
  static const darkMode = 'dark mode';
  static const categoriesTitle = 'categories';
  static const backup = 'backup';
  static const exportBackup = 'export backup';
  static const importBackup = 'import backup';
  static const clearData = 'clear all data';
  static const downloadBackup = 'download backup';
  static const copyBackupJson = 'copy json';
  static const backupDownloadHint = 'save the whole database as a dated .json file.';
  static const backupSavedTo = 'backup saved:';
  static const backupFailed = 'backup failed:';
  static const lastBackupLabel = 'last backup';
  static const neverBackedUp = 'never';
  static const backupReminderLabel = 'backup reminder';
  static const backupReminderHint = 'show a nudge on home when the last backup is older than this.';
  static const persistentStorageLabel = 'persistent storage';
  static const persistentStorageHint =
      'asks the browser not to clear this data when space runs low.';
  static const persistentStorageGranted = '✓ granted';
  static const persistentStorageRequest = 'request';
  static const persistentStorageDenied = 'not granted — keep backups';
  static const backupSizeLabel = 'records';
  static const backupNudgeNever = 'no backup yet';
  static const remindInAWeek = 'remind me in a week';
  static const backupNudgeWeb =
      'your data lives only in this browser. clearing site data erases it.';
  static const backupNudgeNative = 'your data lives only on this computer.';
  static const clearDataWarning =
      'This deletes every habit, task and all progress. Export a backup first.';

  // Proposals (AI seam)
  static const assistantProposal = 'assistant proposal';
  static const proposalIntro =
      'The assistant is proposing these changes. Nothing is saved until you approve.';

  // Keyboard hints
  static const kbdHelp = '? help';
  static const kbdDayNav = '←→ day';
  static const kbdMenu = '1-5 menu';
  static const kbdAddHabit = 'a add habit';
  static const kbdToggle = 'space toggle';

  static const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const weekdayLong = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const monthLong = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}
