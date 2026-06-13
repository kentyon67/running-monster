import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_mission.dart';
import 'user_repository.dart';
import 'monster_repository.dart';
import 'run_repository.dart';
import 'gacha_repository.dart';
import 'mission_repository.dart';
import 'achievement_repository.dart';
import 'friend_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());
final monsterRepositoryProvider = Provider<MonsterRepository>((ref) => MonsterRepository());
final runRepositoryProvider = Provider<RunRepository>((ref) => RunRepository());
final gachaRepositoryProvider = Provider<GachaRepository>((ref) => GachaRepository());
final missionRepositoryProvider = Provider<MissionRepository>((ref) => MissionRepository());
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) => AchievementRepository());
final friendRepositoryProvider = Provider<FriendRepository>((ref) => FriendRepository());

/// Cached daily missions — auto-refreshes when missionRepositoryProvider changes.
final dailyMissionsProvider = FutureProvider<List<DailyMission>>((ref) async {
  final repo = ref.watch(missionRepositoryProvider);
  return repo.loadOrRefresh();
});
