/// Motivational one-liners sprinkled through the UI, and the time-of-day
/// greeting. German, in keeping with the rest of the app.
library;

const List<String> motivationalQuotes = [
  'Jede gute Entscheidung ist ein Schritt in deine Legende.',
  'Kleine Schritte. Große Abenteuer.',
  'Fortschritt ist die Summe kleiner Anstrengungen, die Tag für Tag zählen.',
  'Disziplin heute. Ein stärkeres Ich morgen.',
  'Du wirst nicht scheitern. Du lernst nur den Weg.',
  'Der beste Zeitpunkt war gestern. Der zweitbeste ist jetzt.',
  'Wer jeden Tag ein wenig besser wird, wird irgendwann unaufhaltbar.',
  'Motivation bringt dich in Gang. Gewohnheit hält dich am Laufen.',
];

/// Deterministic pick so a given [slot] shows the same quote for a day.
String quoteOfTheDay(DateTime date, {int slot = 0}) {
  final index = (date.year * 366 + date.month * 31 + date.day + slot * 7) %
      motivationalQuotes.length;
  return motivationalQuotes[index];
}

String greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour < 5) return 'Gute Nacht!';
  if (hour < 11) return 'Guten Morgen!';
  if (hour < 17) return 'Guten Tag!';
  if (hour < 22) return 'Guten Abend!';
  return 'Gute Nacht!';
}

const List<String> weekdayLong = [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];

const List<String> monthLong = [
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];

String longDate(DateTime date) =>
    '${weekdayLong[date.weekday - 1]}, ${date.day}. ${monthLong[date.month - 1]} ${date.year}';
