import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/monster.dart';

class MonsterDisplay extends StatelessWidget {
  final Monster monster;

  const MonsterDisplay({super.key, required this.monster});

  Color get _monsterColor {
    switch (monster.color) {
      case 'red':
        return AppColors.red;
      case 'blue':
        return AppColors.blue;
      default:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Monster avatar placeholder (replaced with actual sprites in future)
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _monsterColor.withValues(alpha: 0.15),
            border: Border.all(color: _monsterColor, width: 3),
          ),
          child: Center(
            child: Icon(
              _iconForEvolution(monster.currentEvolutionId),
              size: 64,
              color: _monsterColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          monster.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          monster.currentEvolutionId
              .replaceAll('_', ' ')
              .toUpperCase(),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  IconData _iconForEvolution(String id) {
    if (id.startsWith('runmon')) return Icons.catching_pokemon;
    if (id.startsWith('grandmon') || id.startsWith('wingmon')) return Icons.catching_pokemon;
    if (id.startsWith('beast') || id.startsWith('knight') || id.startsWith('bird') || id.startsWith('spiri')) {
      return Icons.catching_pokemon;
    }
    if (id.contains('fenrir') || id.contains('leo')) return Icons.pets;
    if (id.contains('phoenix') || id.contains('bird')) return Icons.flight;
    return Icons.auto_awesome;
  }
}
