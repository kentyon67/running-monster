import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import 'run_notifier.dart';
import 'widgets/run_stats_panel.dart';
import 'widgets/route_map.dart';

/// Tab screen — shows a "Start Run" button.
class RunScreen extends ConsumerWidget {
  const RunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('ラン', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_run, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text('走る準備はできていますか？',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/run/active'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('ランを開始', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    );
  }
}

/// Full-screen active run view.
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
  }

  Future<void> _onFinish() async {
    final record = ref.read(runProvider.notifier).finishRun();
    if (record != null) {
      if (mounted) {
        context.go('/run/result', extra: record);
      }
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

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Map area
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: RouteMap(points: runState.routePoints),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  RunStatsPanel(
                    distanceKm: runState.distanceKm,
                    elapsedSeconds: runState.elapsedSeconds,
                    paceMinPerKm: runState.paceMinPerKm,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: runState.status == RunStatus.running
                              ? () => ref.read(runProvider.notifier).pauseRun()
                              : runState.status == RunStatus.paused
                                  ? () => ref.read(runProvider.notifier).resumeRun()
                                  : null,
                          icon: Icon(runState.status == RunStatus.paused
                              ? Icons.play_arrow
                              : Icons.pause),
                          label: Text(runState.status == RunStatus.paused ? '再開' : '一時停止'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.surfaceLight),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _onFinish,
                          icon: const Icon(Icons.stop),
                          label: const Text('終了', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
