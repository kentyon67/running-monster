import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const userBox = 'user';
  static const monsterBox = 'monster';
  static const runRecordBox = 'run_records';
  static const gachaItemBox = 'gacha_items';
  static const achievementBox = 'achievements';
  static const dailyMissionBox = 'daily_missions';
  static const friendCardBox = 'friend_cards';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(userBox);
    await Hive.openBox(monsterBox);
    await Hive.openBox(runRecordBox);
    await Hive.openBox(gachaItemBox);
    await Hive.openBox(achievementBox);
    await Hive.openBox(dailyMissionBox);
    await Hive.openBox(friendCardBox);
  }

  static Box get user => Hive.box(userBox);
  static Box get monster => Hive.box(monsterBox);
  static Box get runRecords => Hive.box(runRecordBox);
  static Box get gachaItems => Hive.box(gachaItemBox);
  static Box get achievements => Hive.box(achievementBox);
  static Box get dailyMissions => Hive.box(dailyMissionBox);
  static Box get friendCards => Hive.box(friendCardBox);
}
