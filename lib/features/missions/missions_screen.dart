import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/daily_mission.dart';
import '../../data/models/achievement.dart';
import '../../data/repositories/providers.dart';
import '../home/home_notifier.dart';

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<DailyMission> _missions = [];
  List<Achievement> _achievements = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final missionRepo = ref.read(missionRepositoryProvider);
    final achievementRepo = ref.read(achievementRepositoryProvider);

    final missions = await missionRepo.loadOrRefresh();

    // Auto-complete login mission
    final loginMissions = missions.where(
        (m) => m.condition['type'] == 'login' && !m.isCompleted);
    if (loginMissions.isNotEmpty) {
      final completed = await missionRepo.checkAndComplete(null, 0, 0);
      if (completed.isNotEmpty) {
        final userRepo = ref.read(userRepositoryProvider);
        await userRepo.loadOrCreate();
        final u = userRepo.current;
        for (final m in completed) {
          u.currentCoins += m.rewardCoins;
        }
        await userRepo.save(u);
        ref.invalidate(homeProvider);
      }
    }

    await achievementRepo.load();

    if (mounted) {
      setState(() {
        _missions = missionRepo.missions;
        _achievements = achievementRepo.all;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('ミッション・実績',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'デイリーミッション'),
            Tab(text: '実績'),
          ],
        ),
      ),
      body: !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tab,
              children: [
                _MissionsTab(missions: _missions),
                _AchievementsTab(achievements: _achievements),
              ],
            ),
    );
  }
}

// ─── Daily Missions Tab ───────────────────────────────────────────────────────

class _MissionsTab extends StatelessWidget {
  final List<DailyMission> missions;
  const _MissionsTab({required this.missions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.refresh, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 6),
              const Text('毎日0時にリセット',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 16),
              Text(
                '${missions.where((m) => m.isCompleted).length}/${missions.length} 完了',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: missions.length,
            itemBuilder: (_, i) => _MissionCard(mission: missions[i]),
          ),
        ),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  final DailyMission mission;
  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final done = mission.isCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.surfaceLight,
          width: done ? 1.5 : 1.0,
        ),
        boxShadow: done
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              height: 72,
              color: done ? AppColors.primary : AppColors.surfaceLight,
            ),
            const SizedBox(width: 12),
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surfaceLight.withValues(alpha: 0.5),
              ),
              child: Icon(
                done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: done ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: TextStyle(
                        color: done ? AppColors.textSecondary : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on,
                            color: AppColors.gold, size: 13),
                        const SizedBox(width: 3),
                        Text('+${mission.rewardCoins} コイン',
                            style: const TextStyle(
                                color: AppColors.gold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Done badge
            if (done)
              Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                child: const Text('完了',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Achievements Tab ─────────────────────────────────────────────────────────

class _AchievementsTab extends StatelessWidget {
  final List<Achievement> achievements;
  const _AchievementsTab({required this.achievements});

  static const _categoryOrder = ['distance', 'level', 'gacha', 'streak'];
  static const _categoryLabels = {
    'distance': '距離',
    'level': 'レベル',
    'gacha': 'ガチャ',
    'streak': '連続ラン',
  };

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, List<Achievement>>{};
    for (final a in achievements) {
      (byCategory[a.category] ??= []).add(a);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final cat in _categoryOrder)
          if (byCategory.containsKey(cat)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(_categoryLabels[cat]!,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
            ),
            ...byCategory[cat]!.map((a) => _AchievementCard(achievement: a)),
          ],
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final done = achievement.isCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: done
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.gold.withValues(alpha: 0.08),
                  AppColors.surface,
                ],
              )
            : null,
        color: done ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done
              ? AppColors.gold.withValues(alpha: 0.4)
              : AppColors.surfaceLight,
        ),
        boxShadow: done
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.gold.withValues(alpha: 0.15)
                    : AppColors.surfaceLight.withValues(alpha: 0.5),
              ),
              child: Icon(
                done ? Icons.emoji_events_rounded : Icons.lock_outline,
                size: 24,
                color: done ? AppColors.gold : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(achievement.title,
                      style: TextStyle(
                        color: done
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 2),
                  Text(achievement.description,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  _RewardBadge(
                      type: achievement.rewardType,
                      value: achievement.rewardValue),
                ],
              ),
            ),
            if (done && achievement.completedAt != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.gold, size: 16),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(achievement.completedAt!),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.month}/${d.day}';
}

class _RewardBadge extends StatelessWidget {
  final String type;
  final dynamic value;
  const _RewardBadge({required this.type, required this.value});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    if (type == 'coins') {
      label = '+$value コイン';
      color = AppColors.gold;
    } else {
      label = '$type 獲得';
      color = AppColors.accent;
    }
    return Row(
      children: [
        Icon(
          type == 'coins' ? Icons.monetization_on : Icons.card_giftcard,
          color: color,
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}
