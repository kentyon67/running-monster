import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/evolution_tree.dart';
import '../../data/repositories/providers.dart';
import '../../services/haptic_service.dart';
import '../../data/models/monster.dart';
import '../../data/models/gacha_item.dart';
import '../home/home_notifier.dart';
import '../home/widgets/animated_monster_display.dart';
import '../home/widgets/exp_bar.dart';
import '../home/widgets/monster_painter.dart';

class MonsterScreen extends ConsumerStatefulWidget {
  const MonsterScreen({super.key});

  @override
  ConsumerState<MonsterScreen> createState() => _MonsterScreenState();
}

class _MonsterScreenState extends ConsumerState<MonsterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        final monster = state.monster;
        if (monster == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text('まずホームでモンスターを作成してください',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(monster.name,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'ステータス'),
                Tab(text: '進化'),
                Tab(text: 'アイテム'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _StatusTab(monster: monster),
              _EvolutionTab(monster: monster),
              _ItemsTab(monster: monster),
            ],
          ),
        );
      },
    );
  }
}

// ─── Status Tab ──────────────────────────────────────────────────────────────

class _StatusTab extends StatelessWidget {
  final Monster monster;
  const _StatusTab({required this.monster});

  @override
  Widget build(BuildContext context) {
    final node = kEvolutionTree[monster.currentEvolutionId];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Full animated monster display with glow ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Container(
                width: 185,
                height: 185,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryGlow.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              AnimatedMonsterDisplay(monster: monster),
            ],
          ),
          if (node?.description != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                node!.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 20),
          // EXP progress card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.expBar.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(color: AppColors.expBar.withValues(alpha: 0.12), blurRadius: 12),
              ],
            ),
            child: ExpBar(totalExp: monster.exp, level: monster.level),
          ),
          const SizedBox(height: 12),
          // Monster color badge
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('タイプ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: monster.color == 'red'
                            ? AppColors.red
                            : monster.color == 'blue'
                                ? AppColors.blue
                                : AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      monster.color == 'red' ? '赤タイプ' : monster.color == 'blue' ? '青タイプ' : '緑タイプ',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _StatRow(label: '累計EXP', value: '${monster.exp} EXP', color: AppColors.expBar),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

// ─── Evolution Tab ────────────────────────────────────────────────────────────

class _EvolutionTab extends ConsumerWidget {
  final Monster monster;
  const _EvolutionTab({required this.monster});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choices = getEvolutionChoices(monster.currentEvolutionId);
    final canEvolve = monster.isEvolutionAvailable && choices.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current form
          _EvolutionNodeCard(
            node: kEvolutionTree[monster.currentEvolutionId]!,
            monsterColor: monster.color,
            isCurrent: true,
            isUnlocked: true,
          ),
          if (choices.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Center(
              child: Icon(Icons.arrow_downward, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            if (canEvolve) ...[
              const Text('進化先を選択してください',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              const SizedBox(height: 12),
            ],
            for (final choice in choices)
              _EvolutionChoiceCard(
                node: choice,
                monsterColor: monster.color,
                canEvolve: canEvolve,
                onEvolve: () => _confirmEvolve(context, ref, choice),
              ),
          ] else ...[
            const SizedBox(height: 24),
            const Center(
              child: Text('最終進化形態です',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ],
          const SizedBox(height: 32),
          const Text('進化ルート',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          _EvolutionPathDisplay(evolutionPath: monster.evolutionPath),
        ],
      ),
    );
  }

  void _confirmEvolve(
      BuildContext context, WidgetRef ref, EvolutionNode choice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${choice.name}に進化',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '${choice.description}\n\nこの進化は取り消せません。よろしいですか？',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              HapticService.evolution();
    await _doEvolve(context, ref, choice);
            },
            child: const Text('進化！', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _doEvolve(
      BuildContext context, WidgetRef ref, EvolutionNode choice) async {
    final monsterRepo = ref.read(monsterRepositoryProvider);
    await monsterRepo.load();
    final m = monsterRepo.current!;
    m.evolutionPath.add(choice.id);
    m.currentEvolutionId = choice.id;
    m.isEvolutionAvailable = false;
    await monsterRepo.save(m);
    ref.invalidate(homeProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${choice.name}に進化しました！'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }
}

class _EvolutionNodeCard extends StatelessWidget {
  final EvolutionNode node;
  final String monsterColor;
  final bool isCurrent;
  final bool isUnlocked;

  const _EvolutionNodeCard({
    required this.node,
    required this.monsterColor,
    this.isCurrent = false,
    this.isUnlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.surfaceLight,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ] : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: buildMonsterWidget(node.id, monsterColor, size: 52),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(node.name,
                        style: TextStyle(
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('現在',
                            style: TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(node.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionChoiceCard extends StatelessWidget {
  final EvolutionNode node;
  final String monsterColor;
  final bool canEvolve;
  final VoidCallback onEvolve;

  const _EvolutionChoiceCard({
    required this.node,
    required this.monsterColor,
    required this.canEvolve,
    required this.onEvolve,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canEvolve
              ? AppColors.accent.withValues(alpha: 0.6)
              : AppColors.surfaceLight,
        ),
        boxShadow: canEvolve ? [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ] : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: buildMonsterWidget(node.id, monsterColor, size: 52),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(node.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text('Lv${node.requiredLevel}〜',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          if (canEvolve)
            ElevatedButton(
              onPressed: onEvolve,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              child: const Text('進化'),
            ),
        ],
      ),
    );
  }
}

class _EvolutionPathDisplay extends StatelessWidget {
  final List<String> evolutionPath;
  const _EvolutionPathDisplay({required this.evolutionPath});

  @override
  Widget build(BuildContext context) {
    final stages = ['ランモン', ...evolutionPath.map((id) {
      final n = kEvolutionTree[id];
      return n != null ? n.name : id;
    })];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: stages.isEmpty
          ? const Text('まだ進化していません',
              style: TextStyle(color: AppColors.textSecondary))
          : Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (int i = 0; i < stages.length; i++) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: i == stages.length - 1
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: i == stages.length - 1
                            ? AppColors.primary
                            : AppColors.surfaceLight,
                      ),
                    ),
                    child: Text(stages[i],
                        style: TextStyle(
                            color: i == stages.length - 1
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 12)),
                  ),
                  if (i < stages.length - 1)
                    const Icon(Icons.arrow_forward,
                        size: 14, color: AppColors.textSecondary),
                ],
              ],
            ),
    );
  }
}

// ─── Items Tab ────────────────────────────────────────────────────────────────

class _ItemsTab extends ConsumerStatefulWidget {
  final Monster monster;
  const _ItemsTab({required this.monster});

  @override
  ConsumerState<_ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends ConsumerState<_ItemsTab> {
  List<GachaItem> _items = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(gachaRepositoryProvider);
    await repo.load();
    if (mounted) {
      setState(() {
        _items = repo.ownedItems;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text('アイテムがありません',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            SizedBox(height: 8),
            Text('ガチャでアイテムをゲットしよう',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    final types = ['aura', 'banner', 'frame', 'skin'];
    final typeLabels = {
      'aura': 'オーラ',
      'banner': 'バナー',
      'frame': 'フレーム',
      'skin': 'スキン',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final type in types)
          if (_items.any((i) => i.type == type)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(typeLabels[type]!,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
            ),
            ..._items
                .where((i) => i.type == type)
                .map((item) => _ItemCard(item: item)),
          ],
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final GachaItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final rc = _rarityColor(item.rarity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: rc.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: rc.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: rc),
            ),
            child: Text(item.rarity,
                style: TextStyle(
                    color: rc,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text(item.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _rarityColor(String r) {
    switch (r) {
      case 'SSR':
        return const Color(0xFFFFD700);
      case 'SR':
        return const Color(0xFFE040FB);
      case 'R':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
