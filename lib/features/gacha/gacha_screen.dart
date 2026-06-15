import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/gacha_data.dart';
import '../../data/models/gacha_item.dart';
import '../../data/repositories/providers.dart';
import '../../services/ad_service.dart';
import '../../services/haptic_service.dart';
import '../home/home_notifier.dart';
import 'widgets/gacha_machine_widget.dart';

Color rarityColor(String rarity) {
  switch (rarity) {
    case 'SSR':
      return AppColors.raritySSR;
    case 'SR':
      return AppColors.raritySR;
    case 'R':
      return AppColors.rarityR;
    default:
      return AppColors.rarityN;
  }
}

class GachaScreen extends ConsumerStatefulWidget {
  const GachaScreen({super.key});

  @override
  ConsumerState<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends ConsumerState<GachaScreen> {
  bool _pulling = false;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    await _adService.loadRewardedAd();
    if (mounted) setState(() {});
  }

  Future<void> _pull(int count) async {
    final homeState = ref.read(homeProvider).valueOrNull;
    if (homeState == null) return;
    final user = homeState.user;
    if (user == null) return;

    final cost = count == 1 ? kGachaCost1x : kGachaCost10x;
    if (user.currentCoins < cost) {
      _showInsufficientCoins(cost);
      return;
    }

    HapticService.gacha();
    setState(() => _pulling = true);

    // Small delay so machine animation starts visibly
    await Future.delayed(const Duration(milliseconds: 200));

    final gachaRepo = ref.read(gachaRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    await gachaRepo.load();
    await userRepo.loadOrCreate();

    final u = userRepo.current;
    if (u.currentCoins < cost) {
      setState(() => _pulling = false);
      if (mounted) _showInsufficientCoins(cost);
      return;
    }

    final results = await gachaRepo.pullGacha(count);

    u.currentCoins -= cost;
    await userRepo.save(u);

    ref.invalidate(homeProvider);

    // Wait for machine animation to complete (1.2s total)
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _pulling = false);

    if (mounted) _showResults(results);
  }

  Future<void> _pullWithAd() async {
    if (!_adService.isAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('広告を読み込み中です。しばらくお待ちください'),
          backgroundColor: AppColors.surface,
        ),
      );
      _loadAd();
      return;
    }

    await _adService.showRewardedAd(
      onRewarded: () async {
        setState(() => _pulling = true);
        await Future.delayed(const Duration(milliseconds: 200));

        final gachaRepo = ref.read(gachaRepositoryProvider);
        await gachaRepo.load();
        final results = await gachaRepo.pullGacha(1);

        ref.invalidate(homeProvider);
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() => _pulling = false);
        _loadAd();
        if (mounted) _showResults(results);
      },
    );
  }

  void _showInsufficientCoins(int cost) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('コインが足りません',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('必要: $costコイン\nランニングでコインを貯めよう！',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showResults(List<GachaItem> results) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => _ResultsSheet(results: results),
    );
  }

  void _showRates() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('排出率', style: TextStyle(color: AppColors.textPrimary)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RateRow(rarity: 'SSR', rate: '2%', color: AppColors.raritySSR),
            _RateRow(rarity: 'SR', rate: '8%', color: AppColors.raritySR),
            _RateRow(rarity: 'R', rate: '30%', color: AppColors.rarityR),
            _RateRow(rarity: 'N', rate: '60%', color: AppColors.rarityN),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(homeProvider);
    final coins = asyncState.valueOrNull?.user?.currentCoins ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF080B14), Color(0xFF120820), Color(0xFF080B14)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text('ガチャ',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      // Coin display
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on,
                                color: AppColors.gold, size: 18),
                            const SizedBox(width: 6),
                            Text('$coins',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _showRates,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text('排出率', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                // Gacha machine — takes up the main area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // The gacha machine widget
                        Center(
                          child: GachaMachineWidget(
                            isPulling: _pulling,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Pull buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _PullButton(
                                label: '1回ガチャ',
                                sublabel: '$kGachaCost1x コイン',
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                                ),
                                glowColor: const Color(0xFF7C3AED),
                                onTap: _pulling ? null : () => _pull(1),
                              ),
                              const SizedBox(height: 12),
                              _PullButton(
                                label: '10回ガチャ',
                                sublabel: '$kGachaCost10x コイン (お得！)',
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                ),
                                glowColor: const Color(0xFFF59E0B),
                                textColor: Colors.black87,
                                onTap: _pulling ? null : () => _pull(10),
                              ),
                              const SizedBox(height: 12),
                              _PullButton(
                                label: '動画ガチャ',
                                sublabel: '広告を見て無料1回',
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                                ),
                                glowColor: const Color(0xFF7B1FA2),
                                icon: Icons.play_circle_outline,
                                onTap: _pulling ? null : _pullWithAd,
                              ),
                              const SizedBox(height: 20),

                              // Stats
                              _OwnedItemsPreview(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PullButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final LinearGradient gradient;
  final Color glowColor;
  final Color textColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const _PullButton({
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.glowColor,
    this.textColor = Colors.white,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            gradient: onTap == null
                ? LinearGradient(
                    colors: gradient.colors
                        .map((c) => c.withValues(alpha: 0.5))
                        .toList(),
                  )
                : gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: onTap == null
                ? []
                : [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 22),
                const SizedBox(width: 8),
              ],
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                  Text(sublabel,
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.8),
                          fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnedItemsPreview extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OwnedItemsPreview> createState() =>
      _OwnedItemsPreviewState();
}

class _OwnedItemsPreviewState extends ConsumerState<_OwnedItemsPreview> {
  int _count = 0;
  int _totalPulls = 0;

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
        _count = repo.ownedItems.length;
        _totalPulls = repo.totalPulls;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: '所持アイテム', value: '$_count種',
              icon: Icons.inventory_2, color: AppColors.primary),
          Container(width: 1, height: 32,
              color: AppColors.surfaceBorder),
          _StatItem(label: '合計ガチャ回数', value: '$_totalPulls回',
              icon: Icons.casino, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _ResultsSheet extends StatefulWidget {
  final List<GachaItem> results;
  const _ResultsSheet({required this.results});

  @override
  State<_ResultsSheet> createState() => _ResultsSheetState();
}

class _ResultsSheetState extends State<_ResultsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        duration: const Duration(milliseconds: 1600), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'aura': return Icons.auto_awesome;
      case 'banner': return Icons.flag_outlined;
      case 'frame': return Icons.crop_square_outlined;
      case 'skin': return Icons.palette_outlined;
      default: return Icons.card_giftcard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSSR = widget.results.any((r) => r.rarity == 'SSR');
    final hasSR = widget.results.any((r) => r.rarity == 'SR');

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          // Golden glow top border on SSR
          border: hasSSR
              ? const Border(
                  top: BorderSide(color: Color(0xFFFFD700), width: 2))
              : null,
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: hasSSR
                    ? const Color(0xFFFFD700)
                    : AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header title with shimmer for SSR
            if (hasSSR)
              AnimatedBuilder(
                animation: _shimmerCtrl,
                builder: (_, __) {
                  final shimmerPos = _shimmerCtrl.value * 2 - 0.5;
                  return ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: const [
                        Color(0xFFB8860B),
                        Color(0xFFFFD700),
                        Color(0xFFFFF9C4),
                        Color(0xFFFFD700),
                        Color(0xFFB8860B),
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                      begin: Alignment(shimmerPos - 1.0, 0),
                      end: Alignment(shimmerPos + 1.0, 0),
                    ).createShader(bounds),
                    child: const Text('★ SSR 獲得！ ★',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3)),
                  );
                },
              )
            else if (hasSR)
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFD946EF), Color(0xFFA855F7), Color(0xFFD946EF)],
                ).createShader(bounds),
                child: const Text('SR 獲得！',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
              )
            else
              const Text('ガチャ結果',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Item list
            Expanded(
              child: ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.results.length,
                itemBuilder: (_, i) {
                  final item = widget.results[i];
                  final rc = rarityColor(item.rarity);
                  final isSSR = item.rarity == 'SSR';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      gradient: isSSR
                          ? LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                const Color(0xFFFFD700).withValues(alpha: 0.12),
                                AppColors.surface,
                              ],
                            )
                          : null,
                      color: isSSR ? null : rc.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: rc.withValues(alpha: isSSR ? 0.8 : 0.45),
                          width: isSSR ? 1.5 : 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: rc.withValues(alpha: isSSR ? 0.25 : 0.12),
                          blurRadius: isSSR ? 16 : 8,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // Type icon in colored circle
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: rc.withValues(alpha: 0.18),
                              border: Border.all(
                                  color: rc.withValues(alpha: 0.6)),
                            ),
                            child: Icon(_typeIcon(item.type),
                                color: rc, size: 20),
                          ),
                          const SizedBox(width: 12),
                          // Name + description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: TextStyle(
                                        color: isSSR
                                            ? const Color(0xFFFFD700)
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(item.description,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          // Rarity badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: rc.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: rc),
                            ),
                            child: Text(item.rarity,
                                style: TextStyle(
                                    color: rc,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: hasSSR
                      ? const LinearGradient(
                          colors: [Color(0xFFB8860B), Color(0xFFFFD700)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                        ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (hasSSR
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF7C3AED))
                          .withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('閉じる',
                      style: TextStyle(
                          color: hasSSR ? Colors.black87 : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  final String rarity;
  final String rate;
  final Color color;

  const _RateRow(
      {required this.rarity, required this.rate, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color),
            ),
            child: Text(rarity,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ),
          const SizedBox(width: 12),
          Text(rate,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 16)),
        ],
      ),
    );
  }
}
