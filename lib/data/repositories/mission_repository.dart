import 'dart:math';
import 'package:uuid/uuid.dart';
import '../local/hive_boxes.dart';
import '../models/daily_mission.dart';
import '../models/run_record.dart';
import '../../core/constants/mission_data.dart';

class MissionRepository {
  List<DailyMission> _cache = [];

  static const _dateKey = 'mission_date';

  Future<List<DailyMission>> loadOrRefresh() async {
    final box = HiveBoxes.dailyMissions;
    final today = _todayStr();
    final savedDate = box.get(_dateKey) as String?;

    if (savedDate == today) {
      _cache = box.keys
          .where((k) => k != _dateKey)
          .map((k) => DailyMission.fromMap(box.get(k) as Map))
          .toList();
    } else {
      // New day — pick 3 random missions
      await box.clear();
      final rng = Random();
      final pool = List<Map<String, dynamic>>.from(kMissionTemplates);
      pool.shuffle(rng);
      final selected = pool.take(3).toList();
      final now = DateTime.now();
      _cache = selected.map((t) {
        return DailyMission(
          id: const Uuid().v4(),
          date: now,
          title: t['title'] as String,
          condition: Map<String, dynamic>.from(t['condition'] as Map),
          rewardCoins: t['rewardCoins'] as int,
        );
      }).toList();
      await box.put(_dateKey, today);
      for (final m in _cache) {
        await box.put(m.id, m.toMap());
      }
    }
    return _cache;
  }

  List<DailyMission> get missions => _cache;

  Future<List<DailyMission>> checkAndComplete(
      RunRecord? record, double totalDistanceKm, int monsterLevel) async {
    final completed = <DailyMission>[];
    for (final mission in _cache) {
      if (mission.isCompleted) continue;
      bool done = false;
      final cond = mission.condition;
      final type = cond['type'] as String;

      switch (type) {
        case 'login':
          done = true;
        case 'distance':
          if (record != null) {
            done = record.distanceKm >= (cond['value'] as num).toDouble();
          }
        case 'run_count':
          // Simplified: any run counts as 1 for now
          if (record != null) done = true;
        case 'duration':
          if (record != null) {
            done = record.durationSeconds >= (cond['seconds'] as int);
          }
        case 'exp_single':
          if (record != null) {
            done = record.expGained >= (cond['value'] as int);
          }
        case 'coins_single':
          if (record != null) {
            done = record.coinsGained >= (cond['value'] as int);
          }
        case 'pace':
          if (record != null && record.averagePace > 0) {
            done = record.averagePace <= (cond['max_pace'] as num).toDouble();
          }
        case 'time_of_day':
          if (record != null) {
            final h = record.startedAt.hour;
            done = h >= (cond['start_hour'] as int) && h < (cond['end_hour'] as int);
          }
        case 'distance_under_time':
          if (record != null) {
            done = record.distanceKm >= (cond['min_km'] as num).toDouble() &&
                record.durationSeconds <= (cond['max_seconds'] as int);
          }
      }

      if (done) {
        mission.isCompleted = true;
        await HiveBoxes.dailyMissions.put(mission.id, mission.toMap());
        completed.add(mission);
      }
    }
    return completed;
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
