import '../local/hive_boxes.dart';
import '../models/run_record.dart';

class RunRepository {
  List<RunRecord>? _cache;

  Future<List<RunRecord>> loadAll() async {
    final box = HiveBoxes.runRecords;
    _cache = box.values
        .map((v) => RunRecord.fromMap(v as Map))
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return _cache!;
  }

  List<RunRecord> get all => _cache ?? [];

  Future<void> save(RunRecord record) async {
    await HiveBoxes.runRecords.put(record.id, record.toMap());
    _cache = null; // invalidate cache
  }

  /// Returns total distance run today.
  double todayDistanceKm() {
    final today = DateTime.now();
    return all
        .where((r) =>
            r.startedAt.year == today.year &&
            r.startedAt.month == today.month &&
            r.startedAt.day == today.day)
        .fold(0.0, (sum, r) => sum + r.distanceKm);
  }
}
