import '../constants/exp_constants.dart';

class RunValidator {
  /// Returns true if the speed between two GPS points exceeds the limit.
  /// [distanceMeters] is the straight-line distance, [durationSeconds] the elapsed time.
  static bool isAbnormalSpeed(double distanceMeters, double durationSeconds) {
    if (durationSeconds <= 0) return true;
    final speedKmh = (distanceMeters / durationSeconds) * 3.6;
    return speedKmh > kMaxSpeedKmh;
  }

  /// Returns null if run is valid; otherwise an error message.
  static String? validate(double distanceKm, int durationSeconds) {
    if (distanceKm < kMinRunDistanceKm) {
      return '記録には${kMinRunDistanceKm}km以上走る必要があります';
    }
    if (durationSeconds < kMinRunDurationSeconds) {
      return '記録には${kMinRunDurationSeconds ~/ 60}分以上走る必要があります';
    }
    return null;
  }
}
