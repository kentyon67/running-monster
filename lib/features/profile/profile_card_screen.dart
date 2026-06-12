import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/evolution_tree.dart';
import '../../data/models/user.dart';
import '../../data/models/monster.dart';
import '../home/home_notifier.dart';

class ProfileCardScreen extends ConsumerStatefulWidget {
  const ProfileCardScreen({super.key});

  @override
  ConsumerState<ProfileCardScreen> createState() => _ProfileCardScreenState();
}

class _ProfileCardScreenState extends ConsumerState<ProfileCardScreen> {
  final _cardKey = GlobalKey();

  String _buildQrData(User user, Monster monster) {
    final data = {
      'id': user.id,
      'username': user.username,
      'monsterName': monster.name,
      'monsterLevel': monster.level,
      'monsterImageId': monster.currentEvolutionId,
      'totalDistanceKm': user.totalDistanceKm,
      'weeklyDistanceKm': user.weeklyDistanceKm,
      'title': user.selectedTitle,
      'banner': user.selectedBanner,
      'frame': user.selectedFrame,
      'aura': monster.selectedAura,
    };
    return json.encode(data);
  }

  Future<void> _shareCard() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/profile_card.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'ランニングモンスター プロフィールカード');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('シェアに失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('プロフィールカード',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: _shareCard,
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
            child: Text('$e', style: const TextStyle(color: Colors.red))),
        data: (state) {
          final user = state.user;
          final monster = state.monster;
          if (user == null || monster == null) {
            return const Center(
              child: Text('データがありません',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          final qrData = _buildQrData(user, monster);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                RepaintBoundary(
                  key: _cardKey,
                  child: _ProfileCard(user: user, monster: monster),
                ),
                const SizedBox(height: 24),
                const Text('QRコード',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('このQRコードをフレンドに読み込んでもらおう',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _shareCard,
                    icon: const Icon(Icons.share),
                    label: const Text('カードをシェア',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final User user;
  final Monster monster;

  const _ProfileCard({required this.user, required this.monster});

  @override
  Widget build(BuildContext context) {
    final node = kEvolutionTree[monster.currentEvolutionId];
    final monsterColor = _monsterColor(monster.color);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            monsterColor.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: monsterColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: monsterColor.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Monster emoji
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: monsterColor.withValues(alpha: 0.15),
                  border: Border.all(color: monsterColor, width: 2),
                ),
                child: Center(
                  child: Text(node?.emoji ?? '✨',
                      style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text(monster.name,
                        style: TextStyle(color: monsterColor, fontSize: 14)),
                    Text('Lv ${monster.level} · ${node?.name ?? ""}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surfaceLight),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CardStat(
                  label: '累計距離',
                  value: '${user.totalDistanceKm.toStringAsFixed(1)} km'),
              _CardStat(
                  label: '週間距離',
                  value: '${user.weeklyDistanceKm.toStringAsFixed(1)} km'),
              _CardStat(label: 'コイン', value: '${user.currentCoins}'),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('ランニングモンスター',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Color _monsterColor(String color) {
    switch (color) {
      case 'red':
        return AppColors.red;
      case 'blue':
        return AppColors.blue;
      default:
        return AppColors.green;
    }
  }
}

class _CardStat extends StatelessWidget {
  final String label;
  final String value;
  const _CardStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
