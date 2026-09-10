/// XP → level progression.
///
/// Cumulative XP required to *reach* level `L` is `25 * (L - 1) * (L + 2)`:
///
/// | Level | Total XP |
/// |------:|---------:|
/// |     1 |        0 |
/// |     2 |      100 |
/// |     3 |      250 |
/// |     4 |      450 |
/// |     5 |      700 |
/// |     6 |     1000 |
/// |    10 |     2700 |
///
/// One formula, easy to retune later.
library;

int _cumulativeXpForLevel(int level) {
  if (level <= 1) return 0;
  final l = level - 1;
  return 25 * l * (l + 3);
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

LevelProgress levelProgressFor(int totalXp) {
  final xp = totalXp < 0 ? 0 : totalXp;
  var level = 1;
  while (_cumulativeXpForLevel(level + 1) <= xp) {
    level++;
  }
  final base = _cumulativeXpForLevel(level);
  final next = _cumulativeXpForLevel(level + 1);
  return LevelProgress(
    level: level,
    totalXp: xp,
    xpIntoLevel: xp - base,
    xpForThisLevel: next - base,
  );
}
