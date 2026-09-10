/// All user-facing copy in one place (German only for V1). Centralised so a
/// later `intl` migration has a single surface to translate.
class AppText {
  const AppText._();

  // App / navigation
  static const appName = 'Quest';
  static const appTagline = 'Habit Tracker';
  static const dashboard = 'Dashboard';
  static const today = 'Heute';
  static const weekPlanning = 'Wochenplanung';
  static const habits = 'Gewohnheiten';
  static const rewards = 'Belohnungen';
  static const statistics = 'Statistik';
  static const achievements = 'Erfolge';
  static const settings = 'Einstellungen';

  // Shared actions
  static const save = 'Speichern';
  static const cancel = 'Abbrechen';
  static const delete = 'Löschen';
  static const edit = 'Bearbeiten';
  static const add = 'Hinzufügen';
  static const close = 'Schließen';
  static const apply = 'Übernehmen';
  static const discard = 'Verwerfen';
  static const move = 'Verschieben';
  static const copy = 'Kopieren';
  static const skip = 'Überspringen';
  static const undo = 'Rückgängig';

  // Quests
  static const quest = 'Quest';
  static const quests = 'Quests';
  static const newOneOff = 'Neue Aufgabe';
  static const newRecurring = 'Neue Gewohnheit';
  static const attachExisting = 'Bestehende Gewohnheit hinzufügen';
  static const title = 'Titel';
  static const note = 'Notiz';
  static const category = 'Kategorie';
  static const difficulty = 'Schwierigkeit';
  static const difficultyOptional = 'Schwierigkeit (optional)';
  static const xp = 'XP';
  static const noQuestsToday = 'Heute sind keine Quests geplant.';
  static const planYourWeek = 'Plane deine Woche in der Wochenplanung.';
  static const completed = 'Erledigt';
  static const skipped = 'Übersprungen';
  static const missed = 'Verpasst';
  static const plannedSkip = 'Geplant übersprungen';

  // Completion sheet
  static const completeQuest = 'Quest abschließen';
  static const howMuch = 'Wie viel hast du geschafft?';
  static const fullyDone = 'Komplett erledigt';
  static const partial = 'Teilweise';
  static const optionalNote = 'Notiz (optional)';
  static const partialHint =
      'Teilweise erledigt zählt anteilig für XP, aber nicht für die Streak.';

  // Recurrence
  static const repeat = 'Wiederholung';
  static const fixedWeekdays = 'Feste Wochentage';
  static const timesPerWeek = 'X-mal pro Woche';
  static const everyWeek = 'Jede Woche';
  static const justThisWeek = 'Nur diese Woche';
  static const attachScopeQuestion = 'Wie oft?';
  static const attachOnce = 'Nur an diesem Tag';
  static const attachEvery = 'Ab jetzt jeden ';

  // Week planning
  static const thisWeek = 'Diese Woche';
  static const nextWeek = 'Nächste Woche';
  static const plannedXp = 'Geplante XP';
  static const workload = 'Auslastung';
  static const overloaded = 'Überladen';
  static const dayLooksHeavy = 'Dieser Tag ist voll.';
  static const moveSomethingTo = 'Etwas verschieben nach ';
  static const weeklyChips = 'Wochenziele';
  static const templates = 'Vorlagen';
  static const saveAsTemplate = 'Als Vorlage speichern';
  static const applyTemplate = 'Vorlage anwenden';
  static const templateName = 'Name der Vorlage';

  // Habits
  static const currentStreak = 'Aktuelle Streak';
  static const bestStreak = 'Beste Streak';
  static const completionRate = 'Erfolgsquote';
  static const pause = 'Pausieren';
  static const resume = 'Fortsetzen';
  static const archive = 'Archivieren';
  static const noHabitsYet =
      'Noch keine Gewohnheiten. Erstelle eine wiederkehrende Aufgabe.';

  // Dashboard
  static const level = 'Level';
  static const xpToNext = 'XP bis Level ';
  static const activeStreaks = 'Aktive Streaks';
  static const todaysProgress = 'Heute';
  static const continueJourney = 'Weiter auf deiner Reise';
  static const nextLevelIn = 'Nächstes Level in ';
  static const todaysTasks = 'Heutige Aufgaben';
  static const ofTasksDone = ' Aufgaben erledigt';
  static const earnedToday = 'Heute verdient: ';
  static const oneTaskToPerfect = 'Noch 1 Aufgabe bis zur perfekten Tagesbilanz!';
  static const perfectDayReached = 'Perfekte Tagesbilanz erreicht!';
  static const weekProgress = 'Wochenfortschritt';
  static const totalTasksDone = ' erledigte Tasks gesamt';
  static const youreDoingGreat = 'Du machst das großartig!';
  static const doneTasks = 'Erledigte Tasks';
  static const collectedXp = 'Gesammelte XP';
  static const longestStreak = 'Längste Streak';

  // Rewards
  static const unlockedRewards = 'Freigeschaltete Belohnungen';
  static const allRewards = 'Alle Belohnungen';
  static const redeem = 'Einlösen';
  static const rewardUnlockedYou = 'Du hast diese Belohnung freigeschaltet!';
  static const unlockAtLevel = 'Freischaltung bei Level ';
  static const newReward = 'Neue Belohnung';
  static const requiredLevel = 'Benötigtes Level';
  static const redeemedTimes = ' mal eingelöst';
  static const rewardRedeemed = 'Belohnung eingelöst';
  static const enjoyIt = 'Genieß es – du hast es dir verdient.';

  // Dashboard – misc
  static const dashboardSubline = 'Bleib dran. Große Ziele brauchen Zeit.';
  static const unlockedRewardsChip = ' Freigeschaltete Belohnungen';
  static const daysStreak = ' Tage Streak';
  static const tasksDoneShort = ' Erledigte Tasks';

  // Heute
  static const addTask = 'Aufgabe hinzufügen';
  static const tasksDoneOf = ' Aufgaben erledigt';
  static const xpPossible = ' XP möglich';
  static const notPerfectJustConsistent =
      'Du musst nicht perfekt sein. Nur konsequent.';
  static const previousDay = 'Vorheriger Tag';
  static const nextDay = 'Nächster Tag';
  static const backToToday = 'Zurück zu heute';
  static const pastDayReadOnly = 'Vergangene Tage sind schreibgeschützt.';

  // Gewohnheiten
  static const myHabits = 'Meine Gewohnheiten';
  static const habitsSubline = 'Forme heute die Person, die du morgen sein willst.';
  static const filterAll = 'Alle';
  static const filterDaily = 'Täglich';
  static const filterWeekly = 'Wöchentlich';
  static const filterOnce = 'Einmalig';
  static const filterInactive = 'Inaktiv';
  static const daily = 'Täglich';
  static const weekly = 'Wöchentlich';
  static const once = 'Einmalig';

  // Belohnungen
  static const rewardsSubline = 'Verdiene dir, was sich gut anfühlt.';
  static const ownReward = 'Eigene Belohnung';
  static const createOwnReward = 'Eigene Belohnung erstellen';
  static const filterUnlocked = 'Freigeschaltet';
  static const filterLocked = 'Gesperrt';
  static const unlockedLabel = 'Freigeschaltet';
  static const levelRequired = ' erforderlich';
  static const rewardsAreProgress =
      'Belohnungen sind kein Luxus – sie sind Teil der Reise.';

  // Statistik
  static const statisticsSubline =
      'Fortschritt ist die Summe kleiner Anstrengungen.';
  static const xpHistory = 'XP-Verlauf';
  static const tasksCompleted = 'Aufgaben erledigt';
  static const weeklyOverview = 'Wöchentliche Übersicht';
  static const currentStreakLabel = 'Aktuelle Streak';
  static const longestStreakLabel = 'Tage längste Streak';
  static const vsPrevious = ' vs. Vorwoche';
  static const betterNightByNight =
      'Du wirst nicht über Nacht besser. Aber du wirst besser – Nacht für Nacht.';

  // Settings
  static const settingsSubline = 'Gestalte die App so, wie sie zu dir passt.';
  static const tabGeneral = 'Allgemein';
  static const tabGamification = 'Gamification';
  static const tabAppearance = 'Darstellung';
  static const tabData = 'Daten';
  static const tabAbout = 'Über';
  static const xpAndLeveling = 'XP & Leveling';
  static const xpMultiplier = 'XP-Multiplikator';
  static const xpMultiplierHint = 'Alle XP-Werte mit einem Faktor multiplizieren.';
  static const levelCurveLabel = 'Level-Kurve';
  static const levelCurveHint =
      'Bestimmt, wie viel XP für das nächste Level benötigt wird.';
  static const perfectDayBonusLabel = 'Perfekter Tag Bonus';
  static const perfectDayBonusHint =
      'Zusätzliche XP, wenn alle Aufgaben erledigt sind.';
  static const streakProtectionLabel = 'Streak-Schutz';
  static const streakProtectionHint =
      'Ein verpasster Tag unterbricht den Streak nicht sofort.';
  static const notifications = 'Benachrichtigungen';
  static const dailyReminderLabel = 'Tägliche Erinnerung';
  static const dailyReminderHint = 'Erinnere mich an meine Aufgaben.';
  static const motivationMessagesLabel = 'Motivationsnachrichten';
  static const motivationMessagesHint = 'Zeige zufällige motivierende Sprüche.';
  static const notificationsUnavailable =
      'Hinweis: Web-Benachrichtigungen werden noch nicht ausgeliefert – die Einstellung wird gespeichert.';
  static const showAtmosphereLabel = 'Hintergrund-Atmosphäre';
  static const showAtmosphereHint =
      'Die gemalte Berglandschaft hinter den Karten anzeigen.';
  static const aboutText =
      'Quest ist ein lokaler, gamifizierter Habit-Tracker. Deine Daten bleiben auf deinem Gerät. Kein Konto, keine Cloud, offline nutzbar.';
  static const perfectDayBonusToast = 'Perfekter Tag!';

  static const dayTargets = 'Tagesziele (XP)';
  static const darkMode = 'Dunkles Design';
  static const categoriesTitle = 'Kategorien';
  static const backup = 'Backup';
  static const exportBackup = 'Backup exportieren';
  static const importBackup = 'Backup importieren';
  static const clearData = 'Alle Daten löschen';
  static const clearDataWarning =
      'Das löscht alle Aufgaben, Gewohnheiten und den Fortschritt. Vorher ein Backup exportieren.';

  // Proposals (AI seam)
  static const assistantProposal = 'Vorschlag des Assistenten';
  static const proposalIntro =
      'Der Assistent schlägt folgende Änderungen vor. Nichts wird gespeichert, bevor du zustimmst.';

  static const weekdayShort = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  static const weekdayLong = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];
}
