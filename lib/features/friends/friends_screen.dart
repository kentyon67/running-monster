import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/evolution_tree.dart';
import '../../data/models/friend_card.dart';
import '../../data/repositories/providers.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<FriendCard> _friends = [];
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
    final repo = ref.read(friendRepositoryProvider);
    await repo.load();
    if (mounted) {
      setState(() {
        _friends = repo.all;
        _loaded = true;
      });
    }
  }

  void _openQrScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _QrScanSheet(
        onScanned: (data) async {
          Navigator.pop(ctx);
          await _importFriend(data);
        },
      ),
    );
  }

  Future<void> _importFriend(String qrData) async {
    try {
      final Map<String, dynamic> data = json.decode(qrData);
      final repo = ref.read(friendRepositoryProvider);
      await repo.load();

      final id = data['id'] as String;
      if (repo.isDuplicate(id)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('すでに登録済みのフレンドです'),
              backgroundColor: AppColors.surface,
            ),
          );
        }
        return;
      }

      final card = FriendCard(
        id: id,
        username: data['username'] as String? ?? '?',
        monsterName: data['monsterName'] as String? ?? '?',
        monsterLevel: data['monsterLevel'] as int? ?? 1,
        monsterImageId: data['monsterImageId'] as String? ?? 'runmon_green',
        totalDistanceKm: (data['totalDistanceKm'] as num?)?.toDouble() ?? 0,
        weeklyDistanceKm: (data['weeklyDistanceKm'] as num?)?.toDouble() ?? 0,
        title: data['title'] as String?,
        banner: data['banner'] as String?,
        frame: data['frame'] as String?,
        aura: data['aura'] as String?,
        qrData: qrData,
        importedAt: DateTime.now(),
      );

      await repo.add(card);
      setState(() => _friends = repo.all);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${card.username} をフレンドに追加しました！'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QRコードの読み取りに失敗しました'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _removeFriend(String id) async {
    final repo = ref.read(friendRepositoryProvider);
    await repo.remove(id);
    setState(() => _friends = repo.all);
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
        title: const Text('フレンド',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            tooltip: 'QRスキャン',
            onPressed: _openQrScanner,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'フレンド一覧'),
            Tab(text: 'ランキング'),
          ],
        ),
      ),
      body: !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tab,
              children: [
                _FriendListTab(
                    friends: _friends, onRemove: _removeFriend),
                _RankingTab(friends: _friends),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQrScanner,
        backgroundColor: AppColors.primary,
        tooltip: 'フレンドを追加',
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }
}

// ─── Friend List Tab ──────────────────────────────────────────────────────────

class _FriendListTab extends StatelessWidget {
  final List<FriendCard> friends;
  final Future<void> Function(String id) onRemove;

  const _FriendListTab({required this.friends, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('フレンドがいません',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('QRコードをスキャンしてフレンドを追加しよう',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/profile'),
              icon: const Icon(Icons.qr_code, size: 18),
              label: const Text('自分のQRを共有する'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (_, i) => _FriendTile(
        card: friends[i],
        onRemove: () => onRemove(friends[i].id),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendCard card;
  final VoidCallback onRemove;

  const _FriendTile({required this.card, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final node = kEvolutionTree[card.monsterImageId];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(node?.emoji ?? '✨', style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.username,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text('${card.monsterName}  Lv${card.monsterLevel}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text(
                    '累計 ${card.totalDistanceKm.toStringAsFixed(1)}km  '
                    '週間 ${card.weeklyDistanceKm.toStringAsFixed(1)}km',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textSecondary, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

// ─── Ranking Tab ─────────────────────────────────────────────────────────────

class _RankingTab extends StatefulWidget {
  final List<FriendCard> friends;
  const _RankingTab({required this.friends});

  @override
  State<_RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<_RankingTab> {
  bool _byWeekly = true;

  @override
  Widget build(BuildContext context) {
    final sorted = List<FriendCard>.from(widget.friends)
      ..sort((a, b) => _byWeekly
          ? b.weeklyDistanceKm.compareTo(a.weeklyDistanceKm)
          : b.totalDistanceKm.compareTo(a.totalDistanceKm));

    return Column(
      children: [
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('週間')),
            ButtonSegment(value: false, label: Text('累計')),
          ],
          selected: {_byWeekly},
          onSelectionChanged: (s) =>
              setState(() => _byWeekly = s.first),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.surface,
            ),
            foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          const Expanded(
            child: Center(
              child: Text('フレンドがいません',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              itemBuilder: (_, i) {
                final c = sorted[i];
                final dist = _byWeekly
                    ? c.weeklyDistanceKm
                    : c.totalDistanceKm;
                final node = kEvolutionTree[c.monsterImageId];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: i == 0
                        ? Border.all(color: AppColors.gold, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          i == 0
                              ? '🥇'
                              : i == 1
                                  ? '🥈'
                                  : i == 2
                                      ? '🥉'
                                      : '${i + 1}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: i < 3
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(node?.emoji ?? '✨',
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(c.username,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold)),
                      ),
                      Text('${dist.toStringAsFixed(1)} km',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── QR Scan Sheet ────────────────────────────────────────────────────────────

class _QrScanSheet extends StatefulWidget {
  final void Function(String data) onScanned;
  const _QrScanSheet({required this.onScanned});

  @override
  State<_QrScanSheet> createState() => _QrScanSheetState();
}

class _QrScanSheetState extends State<_QrScanSheet> {
  final _ctrl = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
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
          const Text('QRコードをスキャン',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                controller: _ctrl,
                onDetect: (capture) {
                  if (_scanned) return;
                  final barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final value = barcode.rawValue;
                    if (value != null) {
                      _scanned = true;
                      widget.onScanned(value);
                      return;
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
