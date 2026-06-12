import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/level_calculator.dart';

class ExpBar extends StatelessWidget {
  final int totalExp;
  final int level;

  const ExpBar({super.key, required this.totalExp, required this.level});

  @override
  Widget build(BuildContext context) {
    final progress = LevelCalculator.levelProgress(totalExp);
    final inLevel = LevelCalculator.expInCurrentLevel(totalExp);
    final toNext = LevelCalculator.expToNextLevel(level);
    final isMaxLevel = level >= 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Lv $level',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(
              isMaxLevel ? 'MAX' : '$inLevel / $toNext EXP',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isMaxLevel ? 1.0 : progress,
            backgroundColor: AppColors.expBarBg,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.expBar),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}
