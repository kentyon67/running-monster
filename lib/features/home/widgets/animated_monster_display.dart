import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/evolution_tree.dart';
import '../../../core/utils/monster_asset_resolver.dart';
import '../../../data/models/monster.dart';
import 'monster_painter.dart';

class AnimatedMonsterDisplay extends StatefulWidget {
  final Monster monster;
  final double size;

  const AnimatedMonsterDisplay({
    super.key,
    required this.monster,
    this.size = 200,
  });

  @override
  State<AnimatedMonsterDisplay> createState() => _AnimatedMonsterDisplayState();
}

class _AnimatedMonsterDisplayState extends State<AnimatedMonsterDisplay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  // Tap reaction
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _breathCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _breathAnim = Tween<double>(begin: 0.0, end: math.pi * 2).animate(_breathCtrl);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _breathCtrl.stop();
    } else if (state == AppLifecycleState.resumed) {
      _breathCtrl.repeat();
    }
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

  void _handleTap() {
    setState(() => _isTapped = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isTapped = false);
    });
  }

  Widget _buildMonsterImage(double size) {
    final assetPath = MonsterAssetResolver.resolvePath(
      widget.monster.currentEvolutionId,
      widget.monster.color,
      selectedSkin: widget.monster.selectedSkin,
    );
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return buildMonsterWidget(
      widget.monster.currentEvolutionId,
      widget.monster.color,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = kEvolutionTree[widget.monster.currentEvolutionId];
    final size = widget.size;

    return Column(
      children: [
        GestureDetector(
          onTap: _handleTap,
          child: AnimatedScale(
            scale: _isTapped ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: RepaintBoundary(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.elasticOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: SizedBox(
                  key: ValueKey(widget.monster.currentEvolutionId),
                  width: size,
                  height: size,
                  child: AnimatedBuilder(
                    animation: _breathAnim,
                    builder: (_, __) => _buildMonsterImage(size),
                  ),
                ),
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
    _anim = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.accent, width: 1.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 14),
            SizedBox(width: 5),
            Text(
              '進化できる！',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
