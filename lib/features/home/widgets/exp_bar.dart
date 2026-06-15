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
    final isEvolution = LevelCalculator.isEvolutionLevel(level + 1) && !isMaxLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryGlow],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    'Lv $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isEvolution) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      '次Lv進化',
                      style: TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              isMaxLevel
                  ? 'MAX LEVEL'
                  : 'あと ${toNext - inLevel} EXP',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Gradient progress bar
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final fillWidth = isMaxLevel ? barWidth : barWidth * progress.clamp(0.0, 1.0);
            return Stack(
              children: [
                // Background track
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.expBarBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Gradient fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  width: fillWidth,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.expBar, Color(0xFF6EE7B7)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.expBar.withValues(alpha: 0.55),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isMaxLevel ? '最大レベル到達' : '$inLevel / $toNext EXP',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
            if (!isMaxLevel)
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: AppColors.expBar, fontSize: 10, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ],
    );
  }
}
