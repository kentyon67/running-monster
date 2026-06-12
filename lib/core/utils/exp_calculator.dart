import 'dart:math';
import '../constants/exp_constants.dart';

class ExpCalculator {
  /// Returns the highest applicable EXP multiplier.
  /// Only the single maximum multiplier applies (per spec).
  static double getBonusMultiplier(DateTime startTime, double distanceKm) {
    double best = 1.0;

    // Distance-based bonuses
    if (distanceKm >= 10) {
      best = max(best, kTenKmBonus);
    } else if (distanceKm >= 5) {
      best = max(best, kFiveKmBonus);
    }

    // Time-based bonuses (use start time hour)
    final h = startTime.hour;
    final isMorning = h >= 5 && h < 8;
    final isNight = h >= 20; // 20:00–23:59
    if (isMorning || isNight) {
      best = max(best, kNightBonus); // morning and night share same 1.1x rate
    }

    return best;
  }

  /// EXP gained for [distanceKm] run started at [startTime].
  static int calcExp(double distanceKm, DateTime startTime) {
    final multiplier = getBonusMultiplier(startTime, distanceKm);
    return (distanceKm * kExpPerKm * multiplier).floor();
  }

  /// Coins gained (no multiplier per spec).
  static int calcCoins(double distanceKm) {
    return (distanceKm * kCoinsPerKm).floor();
  }

  /// Human-readable bonus description, or null if no bonus.
  static String? bonusLabel(DateTime startTime, double distanceKm) {
    final m = getBonusMultiplier(startTime, distanceKm);
    if (m <= 1.0) return null;
    if (m >= kTenKmBonus) return '10km以上ボーナス ×$kTenKmBonus';
    if (m >= kFiveKmBonus) return '5km以上ボーナス ×$kFiveKmBonus';
    final h = startTime.hour;
    if (h >= 5 && h < 8) return '朝ランボーナス ×$kMorningBonus';
    if (h >= 20) return '夜ランボーナス ×$kNightBonus';
    return null;
  }
}
