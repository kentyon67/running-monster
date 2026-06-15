import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/streak_calculator.dart';
import '../../data/models/monster.dart';
import '../../data/models/user.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/monster_repository.dart';
import '../../data/repositories/run_repository.dart';
import '../../data/repositories/user_repository.dart';

class HomeState {
  final User? user;
  final Monster? monster;
  final double todayDistanceKm;
  final bool isLoading;
  final int streak;

  const HomeState({
    this.user,
    this.monster,
    this.todayDistanceKm = 0,
    this.isLoading = true,
    this.streak = 0,
  });

  HomeState copyWith({
    User? user,
    Monster? monster,
    double? todayDistanceKm,
    bool? isLoading,
    int? streak,
  }) =>
      HomeState(
        user: user ?? this.user,
        monster: monster ?? this.monster,
        todayDistanceKm: todayDistanceKm ?? this.todayDistanceKm,
        isLoading: isLoading ?? this.isLoading,
        streak: streak ?? this.streak,
      );
}

class HomeNotifier extends AsyncNotifier<HomeState> {
  UserRepository get _userRepo => ref.read(userRepositoryProvider);
  MonsterRepository get _monsterRepo => ref.read(monsterRepositoryProvider);
  RunRepository get _runRepo => ref.read(runRepositoryProvider);

  @override
  Future<HomeState> build() async {
    final user = await _userRepo.loadOrCreate();
    final monster = await _monsterRepo.load();
    await _runRepo.loadAll();

    return HomeState(
      user: user,
      monster: monster,
      todayDistanceKm: _runRepo.todayDistanceKm(),
      streak: StreakCalculator.calculate(_runRepo.all),
      isLoading: false,
    );
  }

  Future<Monster> createMonster(String color) async {
    final monster = await _monsterRepo.createInitial(color: color);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(monster: monster));
    }
    return monster;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final homeProvider = AsyncNotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
