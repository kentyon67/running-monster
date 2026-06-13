import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../local/hive_boxes.dart';
import '../models/monster.dart';
import '../../core/utils/level_calculator.dart';
import '../../core/constants/exp_constants.dart';

class MonsterRepository {
  static const _key = 'current_monster';

  Monster? _cache;

  Future<Monster?> load() async {
    final raw = HiveBoxes.monster.get(_key);
    if (raw == null) return null;
    try {
      _cache = Monster.fromMap(raw as Map);
      return _cache;
    } catch (e) {
      debugPrint('MonsterRepository: corrupted monster data — $e. Resetting.');
      await HiveBoxes.monster.delete(_key);
      _cache = null;
      return null;
    }
  }

  Monster? get current => _cache;

  Future<Monster> createInitial({required String color}) async {
    final monster = Monster.initial(id: const Uuid().v4(), color: color);
    await save(monster);
    return monster;
  }

  Future<void> save(Monster monster) async {
    _cache = monster;
    await HiveBoxes.monster.put(_key, monster.toMap());
  }

  Future<(int newLevel, bool didLevelUp)> addExp(int exp) async {
    final monster = _cache;
    if (monster == null) {
      debugPrint('MonsterRepository: addExp called before load()');
      return (0, false);
    }
    final oldLevel = monster.level;
    monster.exp += exp;
    monster.level = LevelCalculator.levelFromExp(monster.exp);
    monster.isEvolutionAvailable =
        kEvolutionLevels.contains(monster.level) && monster.level > oldLevel
            ? true
            : monster.isEvolutionAvailable;
    monster.skinUnlocked = monster.level >= kSkinUnlockLevel;
    await save(monster);
    return (monster.level, monster.level > oldLevel);
  }
}
