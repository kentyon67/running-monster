import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glow_button.dart';
import '../../data/models/monster.dart';
import '../../services/haptic_service.dart';
import '../home/home_notifier.dart';
import '../home/widgets/monster_painter.dart';
import 'run_notifier.dart';
import 'widgets/run_stats_panel.dart';
import 'widgets/route_map.dart';

// Star seeds — deterministic positions for the run prep screen
final _runStarSeeds = List.generate(
  36,
  (i) => _RunStar(
    x: (i * 19 + 13) % 100 / 100.0,
    y: (i * 31 + 7) % 100 / 100.0,
    size: ((i * 11 + 5) % 3 + 1).toDouble(),
    opacity: ((i * 7 + 17) % 55 + 15) / 100.0,
  ),
);

class _RunStar {
  final double x, y, size, opacity;
  const _RunStar({required this.x, required this.y, required this.size, required this.opacity});
}

class RunScreen extends ConsumerWidget {
  const RunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);
    final monster = homeAsync.value?.monster;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.accentLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'RUN',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 4,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // Star field
          Positioned.fill(
            child: CustomPaint(painter: _RunStarPainter()),
          ),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background, AppColors.backgroundGradientEnd],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                // Monster or fallback icon
                monster != null
                    ? _RunMonsterDisplay(monster: monster)
                    : const _BouncingRunnerIcon(),
                const SizedBox(height: 28),
                // Hero text — time-based motivation
                _RunMotivationText(),
                const Spacer(),
                // EXP multiplier tips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const _RunTips(),
                ),
                const SizedBox(height: 20),
                // Premium CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlowButton(
                    label: 'ランを開始',
                    icon: Icons.play_arrow,
                    isLarge: true,
                    color: AppColors.primary,
                    onPressed: () {
                      HapticService.runStart();
                      context.push('/run/active');
                    },
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time-based motivation text widget
// ---------------------------------------------------------------------------
class _RunMotivationText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final String headline;
    final String sub;

    if (h >= 5 && h < 9) {
      headline = '朝ランで最高のスタートを！';
      sub = '朝ランEXPボーナス × 1.1 獲得中';
    } else if (h >= 9 && h < 12) {
      headline = 'モンスターとともに走ろう！';
      sub = '1km走るごとにモンスターが成長します';
    } else if (h >= 12 && h < 17) {
      headline = '今日もいっしょに走りましょう！';
      sub = '10km走ればEXPボーナス × 1.5';
    } else if (h >= 17 && h < 21) {
      headline = '夕暮れランでEXPボーナス！';
      sub = '夜ランEXPボーナス × 1.1 獲得中';
    } else {
      headline = '夜もモンスターは待っています！';
      sub = '深夜ランでもEXPはちゃんと貯まります';
    }

    return Column(
      children: [
        Text(
          headline,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Text(
            sub,
            style: const TextStyle(color: AppColors.accent, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Run screen star painter
// ---------------------------------------------------------------------------
class _RunStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in _runStarSeeds) {
      p.color = Colors.white.withValues(alpha: s.opacity);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.size, p);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ---------------------------------------------------------------------------
// Monster display on run prep screen
// ---------------------------------------------------------------------------
class _RunMonsterDisplay extends StatefulWidget {
  final Monster monster;
  const _RunMonsterDisplay({required this.monster});

  @override
  State<_RunMonsterDisplay> createState() => _RunMonsterDisplayState();
}

class _RunMonsterDisplayState extends State<_RunMonsterDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _anim = Tween<double>(begin: 0.0, end: math.pi * 2).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _glowColor {
    switch (widget.monster.color) {
      case 'red': return AppColors.red;
      case 'blue': return AppColors.blue;
      default: return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Radial glow
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _glowColor.withValues(alpha: 0.18),
                _glowColor.withValues(alpha: 0.06),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Pulsing ring
        Container(
          width: 168,
          height: 168,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _glowColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _glowColor.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // Animated monster
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => buildMonsterWidget(
            widget.monster.currentEvolutionId,
            widget.monster.color,
            size: 160,
            animValue: _anim.value,
          ),
        ),
      ],
    );
  }
}

class _BouncingRunnerIcon extends StatefulWidget {
  const _BouncingRunnerIcon();

  @override
  State<_BouncingRunnerIcon> createState() => _BouncingRunnerIconState();
}

class _BouncingRunnerIconState extends State<_BouncingRunnerIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: -8, end: 8).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: child,
      ),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.directions_run, size: 60, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _RunTips extends StatelessWidget {
  const _RunTips();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.bolt,
                    size: 14, color: AppColors.accent),
              ),
              const SizedBox(width: 8),
              const Text('EXPボーナス',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 10),
          const _TipRow(icon: Icons.wb_sunny_outlined,
              text: '朝ラン (6〜9時)',
              bonus: '×1.1'),
          const _TipRow(icon: Icons.nights_stay_outlined,
              text: '夜ラン (21〜24時)',
              bonus: '×1.1'),
          const _TipRow(icon: Icons.route_outlined,
              text: '10km以上',
              bonus: '×1.5'),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String bonus;
  const _TipRow({required this.icon, required this.text, required this.bonus});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(bonus,
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Full-screen active run view ──────────────────────────────────────────────

class RunActiveScreen extends ConsumerStatefulWidget {
  const RunActiveScreen({super.key});

  @override
  ConsumerState<RunActiveScreen> createState() => _RunActiveScreenState();
}

class _RunActiveScreenState extends ConsumerState<RunActiveScreen>
    with SingleTickerProviderStateMixin {
  bool _started = false;
  late AnimationController _monsterCtrl;
  late Animation<double> _monsterAnim;

  @override
  void initState() {
    super.initState();
    _monsterCtrl = AnimationController(
        duration: const Duration(seconds: 3), vsync: this)..repeat();
    _monsterAnim = Tween<double>(begin: 0.0, end: math.pi * 2).animate(_monsterCtrl);
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  @override
  void dispose() {
    _monsterCtrl.dispose();
    super.dispose();
  }

  Future<void> _begin() async {
    if (_started) return;
    _started = true;
    await ref.read(runProvider.notifier).startRun();

    if (!mounted) return;
    final runState = ref.read(runProvider);
    if (runState.errorMessage != null) {
      _showGpsErrorDialog(runState.errorMessage!, runState.gpsErrorType);
    }
  }

  void _showGpsErrorDialog(String message, GpsErrorType? errorType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(
              errorType == GpsErrorType.permissionDeniedForever
                  ? Icons.lock_outline
                  : Icons.location_off,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 8),
            const Text('GPS エラー',
                style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(message,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          if (errorType == GpsErrorType.permissionDeniedForever)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openAppSettings();
                context.go('/home');
              },
              child: const Text('設定を開く',
                  style: TextStyle(color: AppColors.primary)),
            )
          else if (errorType == GpsErrorType.serviceDisabled)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openLocationSettings();
                context.go('/home');
              },
              child: const Text('位置情報設定へ',
                  style: TextStyle(color: AppColors.primary)),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/home');
              },
              child: const Text('戻る',
                  style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Future<void> _onFinish() async {
    HapticService.runStop();
    final record = ref.read(runProvider.notifier).finishRun();
    if (record != null) {
      if (mounted) context.go('/run/result', extra: record);
    } else {
      final error = ref.read(runProvider).errorMessage;
      if (mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        context.go('/home');
      }
    }
  }

  void _togglePause() {
    final status = ref.read(runProvider).status;
    if (status == RunStatus.running) {
      HapticService.medium();
      ref.read(runProvider.notifier).pauseRun();
    } else if (status == RunStatus.paused) {
      HapticService.medium();
      ref.read(runProvider.notifier).resumeRun();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use select() to avoid rebuilding the whole tree on every GPS tick
    final status = ref.watch(runProvider.select((s) => s.status));
    final gpsAcquired = ref.watch(runProvider.select((s) => s.gpsAcquired));
    final isPaused = status == RunStatus.paused;
    final monster = ref.watch(homeProvider).valueOrNull?.monster;

    final statusColor = isPaused
        ? AppColors.accent
        : (gpsAcquired ? AppColors.primary : Colors.orange);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header bar with GPS status + mini monster
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Status dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPaused
                        ? '一時停止中'
                        : (gpsAcquired ? '記録中...' : 'GPS取得中...'),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  // Mini monster in header
                  if (monster != null)
                    AnimatedBuilder(
                      animation: _monsterAnim,
                      builder: (_, __) => Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: buildMonsterWidget(
                          monster.currentEvolutionId,
                          monster.color,
                          size: 36,
                          animValue: _monsterAnim.value,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Map area — only rebuilds when routePoints changes
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: _RouteMapWatcher(),
              ),
            ),

            // Stats + controls
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                children: [
                  _LargeDistanceDisplay(),
                  const SizedBox(height: 12),
                  _RunStatsPanelWatcher(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _togglePause,
                          icon: Icon(
                              isPaused ? Icons.play_arrow : Icons.pause),
                          label: Text(isPaused ? '再開' : '一時停止'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(
                                color: AppColors.surfaceLight),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _onFinish,
                          icon: const Icon(Icons.stop_circle),
                          label: const Text('終了',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Isolated widget — only rebuilds when routePoints change
class _RouteMapWatcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(runProvider.select((s) => s.routePoints));
    return RouteMap(points: points);
  }
}

/// Isolated widget — only rebuilds when distance/elapsed/pace change
class _RunStatsPanelWatcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distanceKm = ref.watch(runProvider.select((s) => s.distanceKm));
    final elapsedSeconds =
        ref.watch(runProvider.select((s) => s.elapsedSeconds));
    final paceMinPerKm =
        ref.watch(runProvider.select((s) => s.paceMinPerKm));
    return RunStatsPanel(
      distanceKm: distanceKm,
      elapsedSeconds: elapsedSeconds,
      paceMinPerKm: paceMinPerKm,
      compact: true,
    );
  }
}

/// Isolated widget — only rebuilds when distanceKm changes
class _LargeDistanceDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distanceKm = ref.watch(runProvider.select((s) => s.distanceKm));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            distanceKm.toStringAsFixed(2),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 56,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8, left: 6),
            child: Text('km',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 20)),
          ),
        ],
      ),
    );
  }
}
