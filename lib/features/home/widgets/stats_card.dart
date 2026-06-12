import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StatsCard extends StatelessWidget {
  final double todayDistanceKm;
  final double totalDistanceKm;
  final int currentCoins;

  const StatsCard({
    super.key,
    required this.todayDistanceKm,
    required this.totalDistanceKm,
    required this.currentCoins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: '今日',
            value: '${todayDistanceKm.toStringAsFixed(2)} km',
            icon: Icons.today,
          ),
          Container(width: 1, height: 40, color: AppColors.surfaceLight),
          _StatItem(
            label: '累計',
            value: '${totalDistanceKm.toStringAsFixed(1)} km',
            icon: Icons.route,
          ),
          Container(width: 1, height: 40, color: AppColors.surfaceLight),
          _StatItem(
            label: 'コイン',
            value: currentCoins.toString(),
            icon: Icons.monetization_on,
            iconColor: AppColors.gold,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
