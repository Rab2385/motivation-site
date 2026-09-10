/// Optional difficulty rating for a task.
///
/// Difficulty only ever *suggests* an XP value; once a task has an XP number
/// that number is authoritative and independent of the difficulty.
enum Difficulty {
  leicht(defaultXp: 20, label: 'Leicht'),
  mittel(defaultXp: 40, label: 'Mittel'),
  schwer(defaultXp: 60, label: 'Schwer'),
  episch(defaultXp: 100, label: 'Episch');

  const Difficulty({required this.defaultXp, required this.label});

  /// XP pre-filled in the editor when this difficulty is picked.
  final int defaultXp;

  /// German label for the UI.
  final String label;

  static Difficulty? fromName(String? name) {
    if (name == null) return null;
    for (final value in Difficulty.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
