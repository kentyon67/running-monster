import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/exp_calculator.dart';
import '../../core/utils/level_calculator.dart';
import '../../core/utils/streak_calculator.dart';
import '../../data/models/run_record.dart';
import '../../data/repositories/providers.dart';
import '../../services/haptic_service.dart';
import '../run/run_notifier.dart';
import '../home/home_notifier.dart';
import 'widgets/route_map.dart';

class RunResultScreen extends ConsumerStatefulWidget {
  final RunRecord record;

  const RunResultScreen({super.key, required this.record});

  @override
  ConsumerState<RunResultScreen> createState() => _RunResultScreenState();
}

class _RunResultScreenState extends ConsumerState<RunResultScreen>
    with SingleTickerProviderStateMixin {
  bool _saved = false;
  bool _didLevelUp = false;
  int _newLevel = 1;
  late AnimationController _levelUpCtrl;
  late Animation<double> _levelUpScale;
  late Animation<double> _levelUpFade;

  @override
  void initState() {
    super.initState();
    _levelUpCtrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _levelUpScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _levelUpCtrl, curve: Curves.elasticOut));
    _levelUpFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _levelUpCtrl, curve: Curves.easeIn));
    WidgetsBinding.instance.addPostFrameCallback((_) => _saveResult());
  }

  @override
  void dispose() {
    _levelUpCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveResult() async {
    if (_saved) return;
    _saved = true;

    final runRepo = ref.read(runRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final monsterRepo = ref.read(monsterRepositoryProvider);

    await runRepo.loadAll();
    await userRepo.loadOrCreate();
    await monsterRepo.load();

    await runRepo.save(widget.record);

    final user = userRepo.current;
    user.totalDistanceKm += widget.record.distanceKm;
    user.weeklyDistanceKm += widget.record.distanceKm;
    user.currentCoins += widget.record.coinsGained;
    await userRepo.save(user);

    if (monsterRepo.current != null) {
      final (newLevel, leveledUp) = await monsterRepo.addExp(widget.record.expGained);
      if (mounted) {
        setState(() {
          _didLevelUp = leveledUp;
          _newLevel = newLevel;
        });
        if (leveledUp) {
          HapticService.levelUp();
          _levelUpCtrl.forward();
        }
      }
    }

    // Check missions
    final missionRepo = ref.read(missionRepositoryProvider);
    await missionRepo.loadOrRefresh();
    final completedMissions = await missionRepo.checkAndComplete(
      widget.record,
      userRepo.current.totalDistanceKm,
      monsterRepo.current?.level ?? 1,
    );
    for (final m in completedMissions) {
      userRepo.current.currentCoins += m.rewardCoins;
    }
    if (completedMissions.isNotEmpty) await userRepo.save(userRepo.current);

    // Check achievements
    final achievementRepo = ref.read(achievementRepositoryProvider);
    await achievementRepo.load();
    final runRepo2 = ref.read(runRepositoryProvider);
    await runRepo2.loadAll();
    final streak = StreakCalculator.calculate(runRepo2.all);
    final gachaRepo = ref.read(gachaRepositoryProvider);
    await gachaRepo.load();
    final newAchievements = await achievementRepo.checkAll(
      totalDistanceKm: userRepo.current.totalDistanceKm,
      monsterLevel: monsterRepo.current?.level ?? 1,
      gachaCount: gachaRepo.totalPulls,
      streak: streak,
      singleRunDistanceKm: widget.record.distanceKm,
    );
    // Award achievement rewards
    for (final a in newAchievements) {
      if (a.rewardType == 'coins') {
        userRepo.current.currentCoins += a.rewardValue as int;
      } else if (['aura', 'banner', 'frame', 'skin'].contains(a.rewardType)) {
        await gachaRepo.awardItem(a.rewardValue as String, 'achievement');
      }
    }
    if (newAchievements.isNotEmpty) await userRepo.save(userRepo.current);

    ref.invalidate(homeProvider);
    ref.read(runProvider.notifier).reset();
  }

  String _paceStr(double pace) {
    if (pace <= 0) return "--'--\"";
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }

  String _timeStr(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '$h時間 ${m.toString().padLeft(2, '0')}分 ${sec.toString().padLeft(2, '0')}秒';
    return '$m分 ${sec.toString().padLeft(2, '0')}秒';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final bonus = ExpCalculator.bonusLabel(r.startedAt, r.distanceKm);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('ラン結果',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_didLevelUp)
              FadeTransition(
                opacity: _levelUpFade,
                child: ScaleTransition(
                  scale: _levelUpScale,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B1FA2).withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('✨ LEVEL UP! ✨',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Lv $_newLevel に上がりました！',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16)),
                        if (LevelCalculator.isEvolutionLevel(_newLevel))
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('🎉 進化できます！モンスター画面へ',
                                style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            if (r.routePoints.isNotEmpty)
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RouteMap(points: r.routePoints, isLive: false),
                ),
              ),
            const SizedBox(height: 16),
            _ResultCard(children: [
              _ResultRow(label: '距離', value: '${r.distanceKm.toStringAsFixed(2)} km'),
              _ResultRow(label: '時間', value: _timeStr(r.durationSeconds)),
              _ResultRow(label: '平均ペース', value: '${_paceStr(r.averagePace)} /km'),
            ]),
            const SizedBox(height: 12),
            _ResultCard(children: [
              _ResultRow(
                  label: '獲得EXP',
                  value: '+${r.expGained} EXP',
                  valueColor: AppColors.expBar),
              if (bonus != null)
                _ResultRow(
                    label: 'ボーナス', value: bonus, valueColor: AppColors.accent),
              _ResultRow(
                  label: '獲得コイン',
                  value: '+${r.coinsGained}',
                  icon: Icons.monetization_on,
                  iconColor: AppColors.gold),
            ]),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('ホームへ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final List<Widget> children;
  const _ResultCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;
  final Color iconColor;

  const _ResultRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    this.icon,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          Row(
            children: [
              if (icon != null) Icon(icon, color: iconColor, size: 16),
              if (icon != null) const SizedBox(width: 4),
              Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
