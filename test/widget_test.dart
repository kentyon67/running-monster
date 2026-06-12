import 'package:flutter_test/flutter_test.dart';
import 'package:running_monster/core/utils/level_calculator.dart';
import 'package:running_monster/core/utils/exp_calculator.dart';
import 'package:running_monster/core/utils/gacha_engine.dart';
import 'package:running_monster/core/utils/streak_calculator.dart';
import 'package:running_monster/data/models/run_record.dart';
import 'package:running_monster/core/constants/gacha_data.dart';
import 'package:running_monster/core/constants/evolution_tree.dart';

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

    test('very high EXP caps at level 50', () {
      expect(LevelCalculator.levelFromExp(99999), 50);
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

    test('calcExp returns positive for 1km run', () {
      final now = DateTime(2024, 1, 1, 12, 0);
      expect(ExpCalculator.calcExp(1.0, now), greaterThan(0));
    });
  });

  group('GachaEngine', () {
    test('single pull returns a GachaItem', () {
      final result = GachaEngine.pull();
      expect(result, isNotNull);
    });

    test('10-pull returns exactly 10 items', () {
      final results = GachaEngine.pull10();
      expect(results, hasLength(10));
    });

    test('all items from pull10 have valid rarity', () {
      final valid = {'N', 'R', 'SR', 'SSR'};
      final results = GachaEngine.pull10();
      for (final item in results) {
        expect(valid.contains(item.rarity), isTrue,
            reason: 'Unexpected rarity: ${item.rarity}');
      }
    });

    test('rarity rates sum to 1.0', () {
      const total = kGachaRateN + kGachaRateR + kGachaRateSR + kGachaRateSSR;
      expect(total, closeTo(1.0, 0.0001));
    });

    test('gacha costs are correct', () {
      expect(kGachaCost1x, equals(300));
      expect(kGachaCost10x, equals(2500));
    });

    test('10x cost is cheaper than 10 individual pulls', () {
      expect(kGachaCost10x, lessThan(kGachaCost1x * 10));
    });
  });

  group('StreakCalculator', () {
    RunRecord makeRecord(DateTime date) => RunRecord(
          id: date.toIso8601String(),
          startedAt: date,
          endedAt: date.add(const Duration(minutes: 30)),
          distanceKm: 3.0,
          durationSeconds: 1800,
          averagePace: 6.0,
          expGained: 100,
          coinsGained: 300,
          appliedBonus: 1.0,
          routePoints: [],
        );

    test('empty list gives streak 0', () {
      expect(StreakCalculator.calculate([]), equals(0));
    });

    test('single run today gives streak 1', () {
      final today = DateTime.now();
      expect(StreakCalculator.calculate([makeRecord(today)]), equals(1));
    });

    test('runs on consecutive days give correct streak', () {
      final today = DateTime.now();
      final records = [
        makeRecord(today),
        makeRecord(today.subtract(const Duration(days: 1))),
        makeRecord(today.subtract(const Duration(days: 2))),
      ];
      expect(StreakCalculator.calculate(records), equals(3));
    });

    test('gap in days breaks streak', () {
      final today = DateTime.now();
      final records = [
        makeRecord(today),
        makeRecord(today.subtract(const Duration(days: 3))),
      ];
      expect(StreakCalculator.calculate(records), equals(1));
    });
  });

  group('EvolutionTree', () {
    test('kEvolutionTree contains runmon_red as a base form', () {
      expect(kEvolutionTree.containsKey('runmon_red'), isTrue);
    });

    test('runmon_red has no required parent (is a root)', () {
      final root = kEvolutionTree['runmon_red']!;
      expect(root.requiredParent, isNull);
    });

    test('runmon_red has two evolution choices', () {
      final choices = getEvolutionChoices('runmon_red');
      expect(choices, hasLength(2));
    });

    test('evolution choices are valid nodes', () {
      final choices = getEvolutionChoices('runmon_red');
      for (final choice in choices) {
        expect(kEvolutionTree.containsKey(choice.id), isTrue);
      }
    });

    test('no choices for unknown evolution id', () {
      final choices = getEvolutionChoices('nonexistent_monster');
      expect(choices, isEmpty);
    });

    test('final form nodes have no further evolutions', () {
      // Final forms should have empty nextEvolutions
      final node = kEvolutionTree['runmon_red']!;
      // beastmon and spiritmon have further evolutions
      expect(node.nextEvolutions, isNotEmpty);
    });
  });
}
