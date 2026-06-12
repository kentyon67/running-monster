import 'package:flutter_test/flutter_test.dart';
import 'package:running_monster/core/utils/level_calculator.dart';
import 'package:running_monster/core/utils/exp_calculator.dart';

void main() {
  group('LevelCalculator', () {
    test('level 1 requires 0 EXP', () {
      expect(LevelCalculator.expRequiredForLevel(1), 0);
    });

    test('level 10 requires 1000 EXP', () {
      expect(LevelCalculator.expRequiredForLevel(10), 1000);
    });

    test('level 20 requires 5000 EXP', () {
      expect(LevelCalculator.expRequiredForLevel(20), 5000);
    });

    test('level 30 requires 10000 EXP', () {
      expect(LevelCalculator.expRequiredForLevel(30), 10000);
    });

    test('level 40 requires 20000 EXP', () {
      expect(LevelCalculator.expRequiredForLevel(40), 20000);
    });

    test('level 50 requires 40000 EXP', () {
      expect(LevelCalculator.expRequiredForLevel(50), 40000);
    });

    test('1000 EXP = level 10', () {
      expect(LevelCalculator.levelFromExp(1000), 10);
    });

    test('999 EXP = level 9', () {
      expect(LevelCalculator.levelFromExp(999), 9);
    });
  });

  group('ExpCalculator', () {
    test('no bonus at noon for 3km', () {
      final noon = DateTime(2024, 1, 1, 12, 0);
      expect(ExpCalculator.getBonusMultiplier(noon, 3), 1.0);
    });

    test('morning bonus 1.1x', () {
      final morning = DateTime(2024, 1, 1, 6, 0);
      expect(ExpCalculator.getBonusMultiplier(morning, 3), 1.1);
    });

    test('10km+ bonus 1.5x overrides night 1.1x', () {
      final night = DateTime(2024, 1, 1, 21, 0);
      expect(ExpCalculator.getBonusMultiplier(night, 10), 1.5);
    });

    test('coins have no multiplier', () {
      expect(ExpCalculator.calcCoins(5.0), 500);
    });
  });
}
