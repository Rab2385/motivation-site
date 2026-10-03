/// Time-of-day grouping for habits (the "Morning / Deep Work / Wind Down"
/// sections). Free-text on the task so users can name their own, with a
/// small set of well-known presets that get an emoji and a fixed sort rank.
library;

const String generalSection = 'General';

const Map<String, String> _knownSectionEmoji = {
  'morning': '🌅',
  'afternoon': '☀️',
  'deep work': '💻',
  'evening': '🌆',
  'wind down': '🌙',
  'night': '🌙',
  'life grid': '🧭',
  'general': '📌',
};

const List<String> _sectionOrder = [
  'morning',
  'afternoon',
  'deep work',
  'evening',
  'wind down',
  'night',
  'life grid',
];

const List<String> sectionPresets = [
  'Morning',
  'Afternoon',
  'Night',
  'Deep Work',
  'Evening',
  'Wind Down',
  'Life Grid',
  'General',
];

String emojiForSection(String section) =>
    _knownSectionEmoji[section.trim().toLowerCase()] ?? '▸';

/// Sort key for a section name: known sections in their canonical order,
/// everything else after (alphabetically), 'General'/'' always last.
int sectionSortRank(String section) {
  final key = section.trim().toLowerCase();
  if (key.isEmpty) return 1000;
  if (key == 'general') return 2000;
  final known = _sectionOrder.indexOf(key);
  return known == -1 ? 500 : known;
}

/// Groups [items] by [sectionOf], sorted by [sectionSortRank] then by
/// first-seen order for unknown names.
List<MapEntry<String, List<T>>> groupBySection<T>(
  List<T> items,
  String Function(T) sectionOf,
) {
  final groups = <String, List<T>>{};
  for (final item in items) {
    final section = sectionOf(item).trim();
    final key = section.isEmpty ? generalSection : section;
    groups.putIfAbsent(key, () => []).add(item);
  }
  final entries = groups.entries.toList()
    ..sort((a, b) {
      final rank = sectionSortRank(a.key).compareTo(sectionSortRank(b.key));
      if (rank != 0) return rank;
      return a.key.toLowerCase().compareTo(b.key.toLowerCase());
    });
  return entries;
}
