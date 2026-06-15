import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/evolution_tree.dart';
import '../../../data/models/monster.dart';
import 'monster_painter.dart';

class AnimatedMonsterDisplay extends StatefulWidget {
  final Monster monster;

  const AnimatedMonsterDisplay({super.key, required this.monster});

  @override
  State<AnimatedMonsterDisplay> createState() => _AnimatedMonsterDisplayState();
}

class _AnimatedMonsterDisplayState extends State<AnimatedMonsterDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _breathAnim = Tween<double>(begin: 0.0, end: math.pi * 2).animate(_breathCtrl);
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  Color get _monsterColor {
    switch (widget.monster.color) {
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
    final node = kEvolutionTree[widget.monster.currentEvolutionId];
    return Column(
      children: [
        AnimatedBuilder(
          animation: _breathAnim,
          builder: (_, __) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.elasticOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: SizedBox(
              key: ValueKey(widget.monster.currentEvolutionId),
              width: 180,
              height: 180,
              child: buildMonsterWidget(
                widget.monster.currentEvolutionId,
                widget.monster.color,
                size: 180,
                animValue: _breathAnim.value,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.monster.name,
            key: ValueKey(widget.monster.name),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          node?.name ?? widget.monster.currentEvolutionId,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        if (widget.monster.isEvolutionAvailable) ...[
          const SizedBox(height: 8),
          _PulsingBadge(color: _monsterColor),
        ],
      ],
    );
  }
}

class _PulsingBadge extends StatefulWidget {
  final Color color;
  const _PulsingBadge({required this.color});

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: AppColors.accent, size: 14),
            SizedBox(width: 4),
            Text('進化できる！',
                style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
