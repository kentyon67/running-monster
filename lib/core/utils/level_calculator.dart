import '../constants/exp_constants.dart';

class LevelCalculator {
  static final _sortedMilestoneKeys = (kLevelMilestones.keys.toList()..sort());

  /// Total EXP required to reach [level] (1-indexed).
  static int expRequiredForLevel(int level) {
    if (level <= 1) return 0;
    final maxLevel = _sortedMilestoneKeys.last;
    if (level >= maxLevel) return kLevelMilestones[maxLevel]!;

    // Find surrounding milestone keys
    int lower = 1, upper = maxLevel;
    for (int i = 0; i < _sortedMilestoneKeys.length - 1; i++) {
      final a = _sortedMilestoneKeys[i];
      final b = _sortedMilestoneKeys[i + 1];
      if (level >= a && level <= b) {
        lower = a;
        upper = b;
        break;
      }
    }

    if (level == lower) return kLevelMilestones[lower]!;
    if (level == upper) return kLevelMilestones[upper]!;

    final lowerExp = kLevelMilestones[lower]!;
    final upperExp = kLevelMilestones[upper]!;
    final t = (level - lower) / (upper - lower);
    return lowerExp + (t * (upperExp - lowerExp)).round();
  }

  /// Current level from [totalExp].
  static int levelFromExp(int totalExp) {
    final maxLevel = _sortedMilestoneKeys.last;
    for (int lv = maxLevel; lv >= 1; lv--) {
      if (totalExp >= expRequiredForLevel(lv)) return lv;
    }
    return 1;
  }

  /// EXP needed to reach the NEXT level from [currentLevel].
  static int expToNextLevel(int currentLevel) {
    if (currentLevel >= _sortedMilestoneKeys.last) return 0;
    return expRequiredForLevel(currentLevel + 1) - expRequiredForLevel(currentLevel);
  }

  /// EXP within the current level (progress bar numerator).
  static int expInCurrentLevel(int totalExp) {
    final lv = levelFromExp(totalExp);
    return totalExp - expRequiredForLevel(lv);
  }

  /// Progress within current level as 0.0–1.0.
  static double levelProgress(int totalExp) {
    final lv = levelFromExp(totalExp);
    final maxLevel = _sortedMilestoneKeys.last;
    if (lv >= maxLevel) return 1.0;
    final inLevel = totalExp - expRequiredForLevel(lv);
    final needed = expToNextLevel(lv);
    if (needed <= 0) return 1.0;
    return (inLevel / needed).clamp(0.0, 1.0);
  }

  /// Whether [level] is an evolution checkpoint.
  static bool isEvolutionLevel(int level) => kEvolutionLevels.contains(level);
}
