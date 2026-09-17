/// XP → level progression.
///
/// The base ("standard") curve: cumulative XP to *reach* level `L` is
/// `25 * (L - 1) * (L + 2)` (L1 = 0, L2 = 100, L3 = 250, L4 = 450, L5 = 700,
/// L6 = 1000, L10 = 2700). The [LevelCurve] setting scales the whole curve.
library;

/// How steeply XP requirements grow. Chosen in System → Gamification.
enum LevelCurve {
  gentle(factor: 0.7, label: 'Gentle'),
  standard(factor: 1.0, label: 'Standard (recommended)'),
  steep(factor: 1.4, label: 'Steep');

  const LevelCurve({required this.factor, required this.label});

  final double factor;
  final String label;

  static LevelCurve fromName(String? name) {
    for (final value in LevelCurve.values) {
      if (value.name == name) return value;
    }
    return LevelCurve.standard;
  }
}

int _cumulativeXpForLevel(int level, LevelCurve curve) {
  if (level <= 1) return 0;
  final l = level - 1;
  return (25 * l * (l + 3) * curve.factor).round();
}

/// A snapshot of where the user sits on the curve.
class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpForThisLevel,
  });

  final int level;
  final int totalXp;

  /// XP earned since reaching [level].
  final int xpIntoLevel;

  /// XP span between [level] and the next level.
  final int xpForThisLevel;

  int get xpToNextLevel => xpForThisLevel - xpIntoLevel;

  double get fraction =>
      xpForThisLevel == 0 ? 0 : xpIntoLevel / xpForThisLevel;
}

LevelProgress levelProgressFor(
  int totalXp, {
  LevelCurve curve = LevelCurve.standard,
}) {
  final xp = totalXp < 0 ? 0 : totalXp;
  var level = 1;
  while (_cumulativeXpForLevel(level + 1, curve) <= xp) {
    level++;
  }
  final base = _cumulativeXpForLevel(level, curve);
  final next = _cumulativeXpForLevel(level + 1, curve);
  return LevelProgress(
    level: level,
    totalXp: xp,
    xpIntoLevel: xp - base,
    xpForThisLevel: next - base,
  );
}
