/// The wry, code-comment-style one-liners sprinkled through the terminal UI
/// (`// like this`), and the time-of-day greeting.
library;

import 'app_text.dart';

const List<String> motivationalQuotes = [
  "the checkbox doesn't care if you feel like it.",
  'a bad day with habits beats a good day without them.',
  "you won't get better overnight. but you'll get better, night after night.",
  "don't break the chain.",
  'discipline is the bridge between goals and results.',
  'small steps compound into big changes.',
  'you are what you repeatedly do.',
  'progress, not perfection.',
  'consistency beats intensity.',
  'do it even when you do not feel like it — especially then.',
];

/// Deterministic pick so a given [slot] shows the same line for a day.
String quoteOfTheDay(DateTime date, {int slot = 0}) {
  final index = (date.year * 366 + date.month * 31 + date.day + slot * 7) %
      motivationalQuotes.length;
  return motivationalQuotes[index];
}

String greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour < 5) return 'good night';
  if (hour < 11) return 'good morning';
  if (hour < 17) return 'good afternoon';
  if (hour < 22) return 'good evening';
  return 'good night';
}

String longDate(DateTime date) =>
    '${AppText.weekdayLong[date.weekday - 1]}, ${AppText.monthLong[date.month - 1]} '
    '${date.day}, ${date.year}';
