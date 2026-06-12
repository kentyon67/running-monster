import '../../data/models/run_record.dart';

class StreakCalculator {
  static int calculate(List<RunRecord> records) {
    if (records.isEmpty) return 0;

    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final runDays = records
        .map((r) => DateTime(r.startedAt.year, r.startedAt.month, r.startedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (runDays.isEmpty) return 0;

    final yesterday = today.subtract(const Duration(days: 1));
    if (!runDays.contains(today) && !runDays.contains(yesterday)) return 0;

    int streak = 0;
    DateTime check = runDays.first;
    for (final day in runDays) {
      if (day == check) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}
