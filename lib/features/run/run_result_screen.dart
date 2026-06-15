import 'dart:math' as math;
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
import '../../services/notification_service.dart';
import '../run/run_notifier.dart';
import '../../data/models/monster.dart';
import '../home/home_notifier.dart';
import '../home/widgets/monster_painter.dart';
import 'widgets/route_map.dart';

class RunResultScreen extends ConsumerStatefulWidget {
  final RunRecord record;

  const RunResultScreen({super.key, required this.record});

  @override
  ConsumerState<RunResultScreen> createState() => _RunResultScreenState();
}

class _RunResultScreenState extends ConsumerState<RunResultScreen>
    with TickerProviderStateMixin {
  bool _saved = false;
  bool _didLevelUp = false;
  int _newLevel = 1;
  late AnimationController _levelUpCtrl;
  late Animation<double> _levelUpScale;
  late Animation<double> _levelUpFade;
  late AnimationController _monsterCtrl;
  late Animation<double> _monsterAnim;
  late AnimationController _counterCtrl;
  late Animation<int> _expCounter;
  late Animation<int> _coinCounter;

  @override
  void initState() {
    super.initState();
    _levelUpCtrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _levelUpScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _levelUpCtrl, curve: Curves.elasticOut));
    _levelUpFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _levelUpCtrl, curve: Curves.easeIn));
    _monsterCtrl = AnimationController(
        duration: const Duration(seconds: 3), vsync: this)..repeat();
    _monsterAnim = Tween<double>(begin: 0.0, end: math.pi * 2).animate(_monsterCtrl);
    _counterCtrl = AnimationController(
        duration: const Duration(milliseconds: 1400), vsync: this);
    _expCounter = IntTween(begin: 0, end: widget.record.expGained)
        .animate(CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    _coinCounter = IntTween(begin: 0, end: widget.record.coinsGained)
        .animate(CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _counterCtrl.forward();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _saveResult());
  }

  @override
  void dispose() {
    _levelUpCtrl.dispose();
    _monsterCtrl.dispose();
    _counterCtrl.dispose();
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

    try {
      await runRepo.save(widget.record);
    } catch (e) {
      debugPrint('RunResultScreen: run save failed — $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ランデータの保存に失敗しました'),
            action: SnackBarAction(
              label: '再試行',
              onPressed: () async {
                try { await runRepo.save(widget.record); } catch (_) {}
              },
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }

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
          await NotificationService.showLevelUpNotification(newLevel);
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
      todayRunCount: runRepo.todayRunCount(),
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
    final monster = ref.watch(homeProvider).valueOrNull?.monster;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.accentLight],
          ).createShader(bounds),
          child: const Text('ラン結果',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Monster victory display
            if (monster != null) ...[
              _MonsterVictorySection(
                monster: monster,
                monsterAnim: _monsterAnim,
                didLevelUp: _didLevelUp,
                distanceKm: r.distanceKm,
              ),
              const SizedBox(height: 16),
            ],

            // Level-up banner
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
                        const Text('LEVEL UP!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                        const SizedBox(height: 4),
                        Text('Lv $_newLevel に上がりました！',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16)),
                        if (LevelCalculator.isEvolutionLevel(_newLevel))
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome,
                                    color: AppColors.accent, size: 16),
                                SizedBox(width: 6),
                                Text('進化できます！モンスター画面へ',
                                    style: TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // Route map
            if (r.routePoints.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RouteMap(points: r.routePoints, isLive: false),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Distance / time / pace card
            _ResultCard(children: [
              _ResultRow(label: '距離', value: '${r.distanceKm.toStringAsFixed(2)} km'),
              _ResultRow(label: '時間', value: _timeStr(r.durationSeconds)),
              _ResultRow(label: '平均ペース', value: '${_paceStr(r.averagePace)} /km'),
            ]),
            const SizedBox(height: 12),

            // Rewards card with animated counters
            AnimatedBuilder(
              animation: _counterCtrl,
              builder: (_, __) => _ResultCard(children: [
                _ResultRow(
                    label: '獲得EXP',
                    value: '+${_expCounter.value} EXP',
                    valueColor: AppColors.expBar),
                if (bonus != null)
                  _ResultRow(
                      label: 'ボーナス', value: bonus, valueColor: AppColors.accent),
                _ResultRow(
                    label: '獲得コイン',
                    value: '+${_coinCounter.value}',
                    icon: Icons.monetization_on,
                    iconColor: AppColors.gold),
              ]),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/run'),
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('もう一度走る'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
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

// ---------------------------------------------------------------------------
// Monster victory display at the top of result screen
// ---------------------------------------------------------------------------
class _MonsterVictorySection extends StatelessWidget {
  final Monster monster;
  final Animation<double> monsterAnim;
  final bool didLevelUp;
  final double distanceKm;

  const _MonsterVictorySection({
    required this.monster,
    required this.monsterAnim,
    required this.didLevelUp,
    required this.distanceKm,
  });

  Color get _glowColor {
    switch (monster.color) {
      case 'red': return AppColors.red;
      case 'blue': return AppColors.blue;
      default: return AppColors.green;
    }
  }

  String get _message {
    if (didLevelUp) return 'レベルアップ！';
    if (distanceKm >= 42.195) return 'フルマラソン完走！伝説の走者！';
    if (distanceKm >= 21.1) return 'ハーフマラソン達成！圧巻の走り！';
    if (distanceKm >= 10.0) return '10km突破！マスターランナー！';
    if (distanceKm >= 5.0) return '5kmクリア！素晴らしいラン！';
    if (distanceKm >= 3.0) return '3km達成！いい調子です！';
    if (distanceKm >= 1.0) return 'ランを完走！よくやった！';
    return 'おつかれさまでした！';
  }

  String get _subMessage {
    if (didLevelUp) return '${monster.name}がさらに強くなった！';
    if (distanceKm >= 10.0) return '${monster.name}も大喜び！';
    if (distanceKm >= 3.0) return '${monster.name}がうれしそう！';
    return '${monster.name}と一緒に走れた！';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _glowColor.withValues(alpha: 0.14),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _glowColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: _glowColor.withValues(alpha: 0.15), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _glowColor.withValues(alpha: 0.22),
                      _glowColor.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _glowColor.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: _glowColor.withValues(alpha: 0.35), blurRadius: 28, spreadRadius: 4),
                  ],
                ),
              ),
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: monsterAnim,
                  builder: (_, __) => buildMonsterWidget(
                    monster.currentEvolutionId,
                    monster.color,
                    size: 114,
                    animValue: monsterAnim.value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [_glowColor, _glowColor.withValues(alpha: 0.75)],
            ).createShader(bounds),
            child: Text(
              _message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subMessage,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
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
