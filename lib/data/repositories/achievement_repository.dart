import 'package:flutter/foundation.dart';
import '../local/hive_boxes.dart';
import '../models/achievement.dart';
import '../../core/constants/achievement_data.dart';

class AchievementRepository {
  List<Achievement> _cache = [];

  Future<void> load() async {
    final box = HiveBoxes.achievements;
    final stored = <String, Achievement>{};
    for (final key in box.keys) {
      try {
        final raw = box.get(key);
        if (raw == null) continue;
        final a = Achievement.fromMap(raw as Map);
        stored[a.id] = a;
      } catch (e) {
        debugPrint('AchievementRepository: corrupted entry $key — $e');
      }
    }
    _cache = kAchievementDefs.map((def) {
      if (stored.containsKey(def['id'])) return stored[def['id']]!;
      return Achievement(
        id: def['id'] as String,
        category: def['category'] as String,
        title: def['title'] as String,
        description: def['description'] as String,
        condition: Map<String, dynamic>.from(def['condition'] as Map),
        rewardType: def['rewardType'] as String,
        rewardValue: def['rewardValue'],
      );
    }).toList();
  }

  List<Achievement> get all => _cache;
  List<Achievement> get completed => _cache.where((a) => a.isCompleted).toList();
  List<Achievement> get incomplete => _cache.where((a) => !a.isCompleted).toList();

  Future<List<Achievement>> checkAll({
    required double totalDistanceKm,
    required int monsterLevel,
    required int gachaCount,
    required int streak,
    double? singleRunDistanceKm,
  }) async {
    final newlyCompleted = <Achievement>[];
    for (final ach in _cache) {
      if (ach.isCompleted) continue;
      bool done = false;
      final cond = ach.condition;
      final type = cond['type'] as String;

      try {
        switch (type) {
          case 'total_distance':
            done = totalDistanceKm >= (cond['value'] as num).toDouble();
          case 'single_distance':
            if (singleRunDistanceKm != null) {
              done = singleRunDistanceKm >= (cond['value'] as num).toDouble();
            }
          case 'level':
            done = monsterLevel >= (cond['value'] as int);
          case 'gacha_count':
            done = gachaCount >= (cond['value'] as int);
          case 'streak':
            done = streak >= (cond['value'] as int);
        }
      } catch (e) {
        debugPrint('AchievementRepository: error evaluating ${ach.id} — $e');
      }

      if (done) {
        ach.isCompleted = true;
        ach.completedAt = DateTime.now();
        try {
          await HiveBoxes.achievements.put(ach.id, ach.toMap());
        } catch (e) {
          debugPrint('AchievementRepository: failed to save ${ach.id} — $e');
        }
        newlyCompleted.add(ach);
      }
    }
    return newlyCompleted;
  }
}
