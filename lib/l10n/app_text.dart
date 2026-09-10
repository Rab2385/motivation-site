/// All user-facing copy in one place (German only for V1). Centralised so a
/// later `intl` migration has a single surface to translate.
class AppText {
  const AppText._();

  // App / navigation
  static const appName = 'Motivation';
  static const dashboard = 'Dashboard';
  static const today = 'Heute';
  static const weekPlanning = 'Wochenplanung';
  static const habits = 'Gewohnheiten';
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

  // Settings
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
