import '../local/hive_boxes.dart';
import '../models/achievement.dart';
import '../../core/constants/achievement_data.dart';

class AchievementRepository {
  List<Achievement> _cache = [];

  Future<void> load() async {
    final box = HiveBoxes.achievements;
    // Merge stored state with definitions (add new ones if not present)
    final stored = <String, Achievement>{};
    for (final key in box.keys) {
      final a = Achievement.fromMap(box.get(key) as Map);
      stored[a.id] = a;
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

  /// Check achievements against current stats. Returns newly completed ones.
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

      if (done) {
        ach.isCompleted = true;
        ach.completedAt = DateTime.now();
        await HiveBoxes.achievements.put(ach.id, ach.toMap());
        newlyCompleted.add(ach);
      }
    }
    return newlyCompleted;
  }
}
