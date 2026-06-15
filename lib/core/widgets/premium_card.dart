import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A premium-styled card with optional glow border and gradient background.
///
/// Use this as a drop-in replacement for Card/Container wherever a
/// visually elevated, game-style surface is desired.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? glowColor;
  final double borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.glowColor,
    this.borderRadius = 16,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = glowColor ?? AppColors.primary;

    final container = Container(
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.surface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveGlow.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveGlow.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }
    return container;
  }
}
