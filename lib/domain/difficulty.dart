/// Optional difficulty rating for a task.
///
/// Difficulty only ever *suggests* an XP value; once a task has an XP number
/// that number is authoritative and independent of the difficulty.
enum Difficulty {
  easy(defaultXp: 20, label: 'Easy'),
  medium(defaultXp: 40, label: 'Medium'),
  hard(defaultXp: 60, label: 'Hard'),
  epic(defaultXp: 100, label: 'Epic');

  const Difficulty({required this.defaultXp, required this.label});

  /// XP pre-filled in the editor when this difficulty is picked.
  final int defaultXp;

  final String label;

  static Difficulty? fromName(String? name) {
    if (name == null) return null;
    for (final value in Difficulty.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
