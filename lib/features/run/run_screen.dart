import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/haptic_service.dart';
import 'run_notifier.dart';
import 'widgets/run_stats_panel.dart';
import 'widgets/route_map.dart';

class RunScreen extends ConsumerWidget {
  const RunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('ラン',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _BouncingRunnerIcon(),
              const SizedBox(height: 32),
              const Text('走る準備はできていますか？',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('GPS精度のため屋外でお試しください',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticService.runStart();
                    context.push('/run/active');
                  },
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text('ランを開始',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _RunTips(),
            ],
          ),
        ),
      ),
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
          child: Text('🏃', style: TextStyle(fontSize: 60)),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          _TipRow(icon: Icons.wb_sunny, text: '朝ラン (6〜9時): EXP×1.1'),
          _TipRow(icon: Icons.nights_stay, text: '夜ラン (21〜24時): EXP×1.1'),
          _TipRow(icon: Icons.directions_run, text: '10km以上: EXP×1.5'),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
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

class _RunActiveScreenState extends ConsumerState<RunActiveScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPaused
                          ? AppColors.accent
                          : (gpsAcquired ? AppColors.primary : Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPaused
                        ? '一時停止中'
                        : (gpsAcquired ? '記録中...' : 'GPS取得中...'),
                    style: TextStyle(
                      color: isPaused
                          ? AppColors.accent
                          : (gpsAcquired ? AppColors.primary : Colors.orange),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
