import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A premium glowing action button with pulse animation on press.
class GlowButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool isLarge;

  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color = AppColors.primary,
    this.isLarge = false,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _glowAnim = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = true);
    _ctrl.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _release();
    widget.onPressed?.call();
  }

  void _handleTapCancel() => _release();

  void _release() {
    if (!mounted) return;
    setState(() => _pressed = false);
    _ctrl.reverse();
  }

  Color get _lighterColor {
    final hsl = HSLColor.fromColor(widget.color);
    return hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final double height = widget.isLarge ? 64 : 52;
    final double fontSize = widget.isLarge ? 18 : 16;
    final double iconSize = widget.isLarge ? 24 : 20;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _lighterColor,
                    widget.color,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(
                      alpha: _pressed ? 0.7 : 0.5,
                    ),
                    blurRadius: _pressed ? 28 * _glowAnim.value : 18,
                    spreadRadius: _pressed ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: SizedBox(
          width: double.infinity,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: iconSize,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
