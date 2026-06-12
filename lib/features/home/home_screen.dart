import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/providers.dart';
import '../../data/models/daily_mission.dart';
import 'home_notifier.dart';
import 'widgets/monster_display.dart';
import 'widgets/exp_bar.dart';
import 'widgets/stats_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(homeProvider);

    return asyncState.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('$e', style: const TextStyle(color: Colors.red))),
      ),
      data: (state) {
        if (state.monster == null) {
          return _MonsterSelectScreen(
            onSelect: (color) => ref.read(homeProvider.notifier).createMonster(color),
          );
        }

        final monster = state.monster!;
        final user = state.user!;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: const Text('ランニングモンスター',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: AppColors.gold, size: 18),
                    const SizedBox(width: 4),
                    Text('${user.currentCoins}',
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => ref.read(homeProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Evolution notification
                  if (monster.isEvolutionAvailable)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text('進化できます！モンスター画面へ',
                              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                  MonsterDisplay(monster: monster),
                  const SizedBox(height: 24),
                  ExpBar(totalExp: monster.exp, level: monster.level),
                  const SizedBox(height: 20),
                  StatsCard(
                    todayDistanceKm: state.todayDistanceKm,
                    totalDistanceKm: user.totalDistanceKm,
                    currentCoins: user.currentCoins,
                  ),
                  const SizedBox(height: 20),
                  _DailyMissionsCard(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/run/active'),
                      icon: const Icon(Icons.directions_run, size: 24),
                      label: const Text('走る', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DailyMissionsCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DailyMissionsCard> createState() =>
      _DailyMissionsCardState();
}

class _DailyMissionsCardState extends ConsumerState<_DailyMissionsCard> {
  List<DailyMission> _missions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(missionRepositoryProvider);
    final ms = await repo.loadOrRefresh();
    if (mounted) setState(() => _missions = ms);
  }

  @override
  Widget build(BuildContext context) {
    final done = _missions.where((m) => m.isCompleted).length;
    final total = _missions.length;
    return GestureDetector(
      onTap: () => context.push('/missions'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('デイリーミッション',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('$done/$total 完了',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: total > 0 ? done / total : 0,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _MonsterSelectScreen extends StatelessWidget {
  final Future<void> Function(String color) onSelect;

  const _MonsterSelectScreen({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ランモンを選んでください',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('色の違いだけで能力差はありません',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ColorOption(color: 'red', label: '赤', emoji: '🔴', onTap: onSelect),
                  _ColorOption(color: 'blue', label: '青', emoji: '🔵', onTap: onSelect),
                  _ColorOption(color: 'green', label: '緑', emoji: '🟢', onTap: onSelect),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final String color;
  final String label;
  final String emoji;
  final Future<void> Function(String) onTap;

  const _ColorOption({
    required this.color,
    required this.label,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        width: 90,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
