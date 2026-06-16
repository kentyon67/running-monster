import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/glow_button.dart';
import '../../data/models/monster.dart';
import '../../data/repositories/providers.dart';
import '../../services/haptic_service.dart';
import 'home_notifier.dart';
import 'widgets/animated_monster_display.dart';
import 'widgets/exp_bar.dart';
import 'widgets/monster_painter.dart';

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'データの読み込みに失敗しました',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(homeProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
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
          extendBodyBehindAppBar: true,
          appBar: _HomeAppBar(coins: user.currentCoins),
          body: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () => ref.read(homeProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monster hero zone — full-width lavender area
                  _MonsterHeroZone(monster: monster, username: user.username),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Evolution banner
                        if (monster.isEvolutionAvailable) ...[
                          _EvolutionBanner(onTap: () => context.go('/monster')),
                          const SizedBox(height: 16),
                        ],

                        // EXP bar
                        _GlowingExpBar(totalExp: monster.exp, level: monster.level),
                        const SizedBox(height: 14),

                        // Stat chips row
                        _StatChipsRow(
                          todayDistanceKm: state.todayDistanceKm,
                          totalDistanceKm: user.totalDistanceKm,
                          currentCoins: user.currentCoins,
                        ),
                        const SizedBox(height: 10),

                        // Streak + weekly goal
                        _WeeklyGoalCard(
                          weeklyKm: user.weeklyDistanceKm,
                          streak: state.streak,
                        ),
                        const SizedBox(height: 14),

                        // Daily missions
                        const _DailyMissionsCard(),
                        const SizedBox(height: 28),

                        // Run CTA
                        GlowButton(
                          label: '走る',
                          icon: Icons.directions_run_rounded,
                          isLarge: true,
                          color: AppColors.primary,
                          onPressed: () {
                            HapticService.runStart();
                            context.go('/run');
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
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

// ---------------------------------------------------------------------------
// AppBar — clean light style
// ---------------------------------------------------------------------------
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int coins;
  const _HomeAppBar({required this.coins});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background.withValues(alpha: 0.95),
      elevation: 0,
      title: const Text(
        'ランニングモンスター',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded, color: AppColors.accent, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Monster hero zone — big monster centered on lavender bg
// ---------------------------------------------------------------------------
class _MonsterHeroZone extends StatelessWidget {
  final Monster monster;
  final String username;

  const _MonsterHeroZone({required this.monster, required this.username});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 10) return 'おはようございます！';
    if (h >= 10 && h < 17) return 'こんにちは！';
    if (h >= 17 && h < 21) return 'こんばんは！';
    return 'おつかれさまです！';
  }

  Color get _monsterAccent {
    switch (monster.color) {
      case 'red': return AppColors.red;
      case 'blue': return AppColors.blue;
      default: return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final monsterSize = screenWidth * 0.72;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 100, bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.surfaceLight,
            AppColors.background,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Greeting
          Text(
            '$_greeting $username',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Monster — hero display
          RepaintBoundary(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft color circle behind monster
                Container(
                  width: monsterSize * 0.88,
                  height: monsterSize * 0.88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _monsterAccent.withValues(alpha: 0.07),
                  ),
                ),
                AnimatedMonsterDisplay(monster: monster, size: monsterSize),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly goal + streak card
// ---------------------------------------------------------------------------
class _WeeklyGoalCard extends StatelessWidget {
  final double weeklyKm;
  final int streak;
  const _WeeklyGoalCard({required this.weeklyKm, required this.streak});

  static const double _weeklyGoalKm = 30.0;

  @override
  Widget build(BuildContext context) {
    final progress = (weeklyKm / _weeklyGoalKm).clamp(0.0, 1.0);
    final isGoalMet = weeklyKm >= _weeklyGoalKm;
    final hasStreak = streak > 0;

    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Streak badge
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: hasStreak
                  ? AppColors.accent.withValues(alpha: 0.10)
                  : AppColors.surfaceBorder.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: hasStreak ? AppColors.accent : AppColors.textMuted,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  '$streak',
                  style: TextStyle(
                    color: hasStreak ? AppColors.accent : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    height: 1.0,
                  ),
                ),
                Text(
                  '日連続',
                  style: TextStyle(
                    color: hasStreak
                        ? AppColors.accent.withValues(alpha: 0.8)
                        : AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Weekly progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '今週の走行距離',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    Text(
                      isGoalMet ? '目標達成！' : '目標 ${_weeklyGoalKm.toInt()}km',
                      style: TextStyle(
                        color: isGoalMet ? AppColors.success : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: isGoalMet ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.expBarBg,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isGoalMet ? AppColors.success : AppColors.primary,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${weeklyKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (isGoalMet) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
                      const SizedBox(width: 4),
                      const Text(
                        '週間目標クリア！',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EXP bar card
// ---------------------------------------------------------------------------
class _GlowingExpBar extends StatelessWidget {
  final int totalExp;
  final int level;
  const _GlowingExpBar({required this.totalExp, required this.level});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: ExpBar(totalExp: totalExp, level: level),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat chips row
// ---------------------------------------------------------------------------
class _StatChipsRow extends StatelessWidget {
  final double todayDistanceKm;
  final double totalDistanceKm;
  final int currentCoins;

  const _StatChipsRow({
    required this.todayDistanceKm,
    required this.totalDistanceKm,
    required this.currentCoins,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.today_rounded,
            iconColor: AppColors.info,
            value: todayDistanceKm.toStringAsFixed(2),
            unit: 'km',
            label: '今日',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.route_rounded,
            iconColor: AppColors.success,
            value: totalDistanceKm.toStringAsFixed(1),
            unit: 'km',
            label: '累計',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.monetization_on_rounded,
            iconColor: AppColors.accent,
            value: '$currentCoins',
            unit: 'G',
            label: 'コイン',
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String unit;
  final String label;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily Missions card
// ---------------------------------------------------------------------------
class _DailyMissionsCard extends ConsumerWidget {
  const _DailyMissionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(dailyMissionsProvider);

    return PremiumCard(
      onTap: () => context.push('/missions'),
      child: missionsAsync.when(
        loading: () => const SizedBox(
          height: 60,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          ),
        ),
        error: (_, __) => _MissionsHeader(done: 0, total: 0),
        data: (missions) {
          final done = missions.where((m) => m.isCompleted).length;
          final total = missions.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MissionsHeader(done: done, total: total),
              if (total > 0) ...[
                const SizedBox(height: 10),
                _GradientProgressBar(value: total > 0 ? done / total : 0),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MissionsHeader extends StatelessWidget {
  final int done;
  final int total;
  const _MissionsHeader({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bolt_rounded, color: AppColors.success, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'デイリーミッション',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                total > 0 ? '$done / $total 完了' : '読み込み中...',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      ],
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  final double value;
  const _GradientProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.expBarBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                width: constraints.maxWidth * value.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.success],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Evolution banner
// ---------------------------------------------------------------------------
class _EvolutionBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _EvolutionBanner({required this.onTap});

  @override
  State<_EvolutionBanner> createState() => _EvolutionBannerState();
}

class _EvolutionBannerState extends State<_EvolutionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryGlow],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '進化できます！モンスター画面へ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  ],
                ),
              ),
              // Shimmer
              AnimatedBuilder(
                animation: _shimmerCtrl,
                builder: (context, _) {
                  final pos = _shimmerCtrl.value * 2 - 0.5;
                  return Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment(pos - 0.8, 0),
                        end: Alignment(pos + 0.8, 0),
                      ).createShader(bounds),
                      child: Container(color: Colors.white),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monster Select Screen — light style
// ---------------------------------------------------------------------------
class _MonsterSelectScreen extends StatelessWidget {
  final Future<void> Function(String color) onSelect;
  const _MonsterSelectScreen({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Title
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.catching_pokemon, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'ランモンを選んでください',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '色の違いだけ。能力差はありません',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: _MonsterCard(
                      color: 'red',
                      label: '赤モン',
                      description: '情熱の走者',
                      accentColor: AppColors.red,
                      onTap: onSelect,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MonsterCard(
                      color: 'blue',
                      label: '青モン',
                      description: '冷静の疾走',
                      accentColor: AppColors.blue,
                      onTap: onSelect,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MonsterCard(
                      color: 'green',
                      label: '緑モン',
                      description: '大自然の力',
                      accentColor: AppColors.green,
                      onTap: onSelect,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonsterCard extends StatefulWidget {
  final String color;
  final String label;
  final String description;
  final Color accentColor;
  final Future<void> Function(String) onTap;

  const _MonsterCard({
    required this.color,
    required this.label,
    required this.description,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_MonsterCard> createState() => _MonsterCardState();
}

class _MonsterCardState extends State<_MonsterCard> with TickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;
  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        duration: const Duration(milliseconds: 120), vsync: this);
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
    _breathCtrl = AnimationController(
        duration: const Duration(seconds: 3), vsync: this)
      ..repeat();
    _breathAnim =
        Tween<double>(begin: 0.0, end: math.pi * 2).animate(_breathCtrl);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap(widget.color);
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              children: [
                // Monster preview
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accentColor.withValues(alpha: 0.08),
                  ),
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _breathAnim,
                      builder: (_, __) => buildMonsterWidget(
                        'runmon',
                        widget.color,
                        size: 80,
                        animValue: _breathAnim.value,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'えらぶ',
                    style: TextStyle(
                      color: widget.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
