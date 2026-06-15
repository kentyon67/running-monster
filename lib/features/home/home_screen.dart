import 'dart:math' as math;
import 'dart:ui';
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
// Star particle data — fixed positions so they don't re-randomise on rebuild
// ---------------------------------------------------------------------------
final _starSeeds = List.generate(
  56,
  (i) => _StarSeed(
    x: (i * 17 + 31) % 100 / 100.0,
    y: (i * 23 + 7) % 100 / 100.0,
    size: ((i * 13 + 3) % 3 + 1).toDouble(),
    opacity: ((i * 7 + 11) % 60 + 20) / 100.0,
  ),
);

class _StarSeed {
  final double x;
  final double y;
  final double size;
  final double opacity;
  const _StarSeed({required this.x, required this.y, required this.size, required this.opacity});
}

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
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center,
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
          appBar: _PremiumAppBar(coins: user.currentCoins),
          body: Stack(
            children: [
              // Nebula + star background
              const _NebulaBackground(),
              // Main content
              RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: () => ref.read(homeProvider.notifier).refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 104),

                        // Time-based greeting
                        _GreetingRow(username: user.username),
                        const SizedBox(height: 12),

                        // Evolution banner
                        if (monster.isEvolutionAvailable) ...[
                          _EvolutionBanner(onTap: () => context.go('/monster')),
                          const SizedBox(height: 16),
                        ],

                        // Monster display
                        _MonsterArea(monster: monster),
                        const SizedBox(height: 20),

                        // EXP bar
                        _GlowingExpBar(totalExp: monster.exp, level: monster.level),
                        const SizedBox(height: 14),

                        // Stat chips row (today / total / coins)
                        _StatChipsRow(
                          todayDistanceKm: state.todayDistanceKm,
                          totalDistanceKm: user.totalDistanceKm,
                          currentCoins: user.currentCoins,
                        ),
                        const SizedBox(height: 10),

                        // Streak + weekly goal combined card
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
                          icon: Icons.directions_run,
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
// Time-based greeting row
// ---------------------------------------------------------------------------
class _GreetingRow extends StatelessWidget {
  final String username;
  const _GreetingRow({required this.username});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 10) return 'おはようございます';
    if (h >= 10 && h < 17) return 'こんにちは';
    if (h >= 17 && h < 21) return 'こんばんは';
    return 'おつかれさまです';
  }

  String get _subtext {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 10) return '朝ランでEXPボーナス獲得中！';
    if (h >= 10 && h < 17) return 'モンスターが走るのを待っています';
    if (h >= 17 && h < 21) return '夜ランでEXPボーナス獲得中！';
    return '深夜もモンスターは元気です';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$_greeting、',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              TextSpan(
                text: username,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: '！',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _subtext,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly goal + streak combined card
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
      glowColor: hasStreak ? AppColors.accent : AppColors.info,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Streak badge
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: hasStreak
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.surfaceLight.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasStreak
                    ? AppColors.accent.withValues(alpha: 0.45)
                    : AppColors.surfaceBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: hasStreak ? AppColors.accent : AppColors.textMuted,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  '$streak',
                  style: TextStyle(
                    color: hasStreak ? AppColors.accent : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.0,
                  ),
                ),
                Text(
                  '日連続',
                  style: TextStyle(
                    color: hasStreak ? AppColors.accent.withValues(alpha: 0.8) : AppColors.textMuted,
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isGoalMet ? AppColors.success : AppColors.info,
                          ),
                          minHeight: 7,
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
                      Icon(Icons.check_circle, color: AppColors.success, size: 12),
                      const SizedBox(width: 4),
                      const Text('週間目標クリア！',
                          style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
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
// Nebula + starfield background
// ---------------------------------------------------------------------------
class _NebulaBackground extends StatelessWidget {
  const _NebulaBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _NebulaStarPainter()),
    );
  }
}

class _NebulaStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Nebula blob 1: subtle purple top-right
    final nebula1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7C3AED).withValues(alpha: 0.09),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width * 0.85, size.height * 0.12),
        width: size.width * 0.6,
        height: size.width * 0.6,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), nebula1);

    // Nebula blob 2: subtle blue bottom-left
    final nebula2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3B82F6).withValues(alpha: 0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(size.width * 0.1, size.height * 0.7),
        width: size.width * 0.5,
        height: size.width * 0.5,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), nebula2);

    // Stars
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final star in _starSeeds) {
      starPaint.color = Colors.white.withValues(alpha: star.opacity);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Premium transparent AppBar with frosted glass + gradient title
// ---------------------------------------------------------------------------
class _PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int coins;
  const _PremiumAppBar({required this.coins});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: AppColors.background.withValues(alpha: 0.7),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.accentLight],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: const Text(
                'ランニングモンスター',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1),
                    boxShadow: [
                      BoxShadow(color: AppColors.gold.withValues(alpha: 0.25), blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: AppColors.gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$coins',
                        style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monster display area
// ---------------------------------------------------------------------------
class _MonsterArea extends StatelessWidget {
  final Monster monster;
  const _MonsterArea({required this.monster});

  Color get _monsterGlow {
    switch (monster.color) {
      case 'red': return AppColors.red;
      case 'blue': return AppColors.blue;
      default: return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial glow — monster-color tinted
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _monsterGlow.withValues(alpha: 0.14),
                  AppColors.primary.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Outer glowing ring
          Container(
            width: 182,
            height: 182,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _monsterGlow.withValues(alpha: 0.28),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _monsterGlow.withValues(alpha: 0.22),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          RepaintBoundary(
            child: AnimatedMonsterDisplay(monster: monster),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EXP bar
// ---------------------------------------------------------------------------
class _GlowingExpBar extends StatelessWidget {
  final int totalExp;
  final int level;
  const _GlowingExpBar({required this.totalExp, required this.level});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      glowColor: AppColors.expBar,
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
            icon: Icons.today,
            iconColor: AppColors.info,
            value: todayDistanceKm.toStringAsFixed(2),
            unit: 'km',
            label: '今日',
            glowColor: AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.route,
            iconColor: AppColors.success,
            value: totalDistanceKm.toStringAsFixed(1),
            unit: 'km',
            label: '累計',
            glowColor: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            icon: Icons.monetization_on,
            iconColor: AppColors.gold,
            value: '$currentCoins',
            unit: 'G',
            label: 'コイン',
            glowColor: AppColors.gold,
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
  final Color glowColor;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.label,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      glowColor: glowColor,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
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
      glowColor: AppColors.success,
      onTap: () => context.push('/missions'),
      child: missionsAsync.when(
        loading: () => const SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator(color: AppColors.success, strokeWidth: 2)),
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
                _GradientProgressBar(
                  value: done / total,
                  gradient: const LinearGradient(
                    colors: [AppColors.success, AppColors.primaryLight],
                  ),
                ),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1),
          ),
          child: const Icon(Icons.bolt, color: AppColors.success, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'デイリーミッション',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                total > 0 ? '$done / $total 完了' : '読み込み中...',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      ],
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  final double value;
  final Gradient gradient;
  const _GradientProgressBar({required this.value, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                width: constraints.maxWidth * value.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 6),
                  ],
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
// Evolution banner with shimmer
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
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF92400E), Color(0xFFB45309), Color(0xFFD97706)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.accentLight, size: 20),
                    SizedBox(width: 8),
                    Icon(Icons.star, color: AppColors.gold, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '進化できます！モンスター画面へ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _shimmerCtrl,
                builder: (context, child) {
                  final shimmerPos = _shimmerCtrl.value * 2 - 0.5;
                  return Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment(shimmerPos - 0.8, 0),
                        end: Alignment(shimmerPos + 0.8, 0),
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
// Monster Select Screen
// ---------------------------------------------------------------------------
class _MonsterSelectScreen extends StatelessWidget {
  final Future<void> Function(String color) onSelect;
  const _MonsterSelectScreen({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _NebulaBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.accentLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'ランモンを選んでください',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '色の違いだけで能力差はありません',
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
                          cardGradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
                          ),
                          glowColor: AppColors.red,
                          onTap: onSelect,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MonsterCard(
                          color: 'blue',
                          label: '青モン',
                          description: '冷静の疾走',
                          cardGradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                          ),
                          glowColor: AppColors.blue,
                          onTap: onSelect,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MonsterCard(
                          color: 'green',
                          label: '緑モン',
                          description: '大自然の力',
                          cardGradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF14532D), Color(0xFF15803D)],
                          ),
                          glowColor: AppColors.green,
                          onTap: onSelect,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonsterCard extends StatefulWidget {
  final String color;
  final String label;
  final String description;
  final Gradient cardGradient;
  final Color glowColor;
  final Future<void> Function(String) onTap;

  const _MonsterCard({
    required this.color,
    required this.label,
    required this.description,
    required this.cardGradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_MonsterCard> createState() => _MonsterCardState();
}

class _MonsterCardState extends State<_MonsterCard> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 120), vsync: this);
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _breathCtrl = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat();
    _breathAnim = Tween<double>(begin: 0.0, end: math.pi * 2).animate(_breathCtrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap(widget.color);
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.glowColor.withValues(alpha: 0.55), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.glowColor.withValues(alpha: 0.4),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _breathAnim,
                      builder: (_, __) => buildMonsterWidget(
                        'runmon_${widget.color}',
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
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                  decoration: BoxDecoration(
                    color: widget.glowColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.glowColor.withValues(alpha: 0.7), width: 1),
                  ),
                  child: Text(
                    'SELECT',
                    style: TextStyle(
                      color: widget.glowColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.0,
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
