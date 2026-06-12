import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/gacha_data.dart';
import '../../data/models/gacha_item.dart';
import '../../data/repositories/providers.dart';
import '../../services/ad_service.dart';
import '../home/home_notifier.dart';

class GachaScreen extends ConsumerStatefulWidget {
  const GachaScreen({super.key});

  @override
  ConsumerState<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends ConsumerState<GachaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;
  late Animation<double> _spinAnim;
  bool _pulling = false;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _spinAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _spinCtrl, curve: Curves.easeInOut));
    _loadAd();
  }

  Future<void> _loadAd() async {
    await _adService.loadRewardedAd();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
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

    setState(() => _pulling = true);
    await _spinCtrl.forward(from: 0);

    final gachaRepo = ref.read(gachaRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    await gachaRepo.load();
    await userRepo.loadOrCreate();

    final results = await gachaRepo.pullGacha(count);

    final u = userRepo.current;
    u.currentCoins -= cost;
    await userRepo.save(u);

    ref.invalidate(homeProvider);
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
        await _spinCtrl.forward(from: 0);

        final gachaRepo = ref.read(gachaRepositoryProvider);
        await gachaRepo.load();
        final results = await gachaRepo.pullGacha(1);

        ref.invalidate(homeProvider);
        setState(() {
          _pulling = false;
        });
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => _ResultsSheet(results: results),
    );
  }

  void _showRates() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('排出率', style: TextStyle(color: AppColors.textPrimary)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RateRow(rarity: 'SSR', rate: '2%',
                color: Color(0xFFFFD700)),
            _RateRow(rarity: 'SR', rate: '8%',
                color: Color(0xFFE040FB)),
            _RateRow(rarity: 'R', rate: '30%',
                color: Color(0xFF42A5F5)),
            _RateRow(rarity: 'N', rate: '60%',
                color: Color(0xFF9E9E9E)),
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('ガチャ',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _showRates,
            child: const Text('排出率',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Coin display
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on,
                      color: AppColors.gold, size: 28),
                  const SizedBox(width: 8),
                  Text('$coins コイン',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Gacha animation area
            AnimatedBuilder(
              animation: _spinAnim,
              builder: (_, __) => Transform.rotate(
                angle: _spinAnim.value * 6.28,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.8),
                        AppColors.surfaceLight,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _pulling
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3)
                        : const Text('🎲',
                            style: TextStyle(fontSize: 64)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Pull buttons
            _PullButton(
              label: '1回ガチャ',
              sublabel: '$kGachaCost1x コイン',
              color: AppColors.primary,
              onTap: _pulling ? null : () => _pull(1),
            ),
            const SizedBox(height: 12),
            _PullButton(
              label: '10回ガチャ',
              sublabel: '$kGachaCost10x コイン (お得)',
              color: AppColors.accent,
              textColor: Colors.black,
              onTap: _pulling ? null : () => _pull(10),
            ),
            const SizedBox(height: 12),
            _PullButton(
              label: '動画広告ガチャ',
              sublabel: '無料で1回',
              color: const Color(0xFF7B1FA2),
              icon: Icons.play_circle_outline,
              onTap: _pulling ? null : _pullWithAd,
            ),
            const SizedBox(height: 32),

            // Owned items count
            _OwnedItemsPreview(),
          ],
        ),
      ),
    );
  }
}

class _PullButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const _PullButton({
    required this.label,
    required this.sublabel,
    required this.color,
    this.textColor = Colors.white,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor),
              const SizedBox(width: 8),
            ],
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(sublabel,
                    style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
                        fontSize: 11)),
              ],
            ),
          ],
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(gachaRepositoryProvider);
    await repo.load();
    if (mounted) setState(() => _count = repo.ownedItems.length);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('所持アイテム: $_count種',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const Text('合計ガチャ回数: ',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ResultsSheet extends StatelessWidget {
  final List<GachaItem> results;
  const _ResultsSheet({required this.results});

  @override
  Widget build(BuildContext context) {
    final hasSSR = results.any((r) => r.rarity == 'SSR');
    final hasSR = results.any((r) => r.rarity == 'SR');

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          if (hasSSR)
            const Text('⭐ SSR獲得！ ⭐',
                style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 20,
                    fontWeight: FontWeight.bold))
          else if (hasSR)
            const Text('✨ SR獲得！ ✨',
                style: TextStyle(
                    color: Color(0xFFE040FB),
                    fontSize: 18,
                    fontWeight: FontWeight.bold))
          else
            const Text('ガチャ結果',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: results.length,
              itemBuilder: (_, i) {
                final item = results[i];
                final rc = rarityColor(item.rarity);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: rc.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: rc.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('閉じる',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
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
            width: 36,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
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
