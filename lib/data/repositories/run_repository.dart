import 'package:flutter/foundation.dart';
import '../local/hive_boxes.dart';
import '../models/run_record.dart';

class RunRepository {
  List<RunRecord>? _cache;

  Future<List<RunRecord>> loadAll() async {
    final box = HiveBoxes.runRecords;
    final records = <RunRecord>[];
    for (final v in box.values) {
      try {
        if (v == null) continue;
        records.add(RunRecord.fromMap(v as Map));
      } catch (e) {
        debugPrint('RunRepository: corrupted record — $e');
      }
    }
    records.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    _cache = records;
    return _cache!;
  }

  List<RunRecord> get all => _cache ?? [];

  Future<void> save(RunRecord record) async {
    await HiveBoxes.runRecords.put(record.id, record.toMap());
    _cache = null;
  }

  int todayRunCount() {
    final today = DateTime.now();
    return all.where((r) =>
      r.startedAt.year == today.year &&
      r.startedAt.month == today.month &&
      r.startedAt.day == today.day).length;
  }

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
