import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the primary Color for a monster color string.
Color getMonsterPrimaryColor(String monsterColor) {
  switch (monsterColor.toLowerCase()) {
    case 'red':
      return const Color(0xFFE53935);
    case 'blue':
      return const Color(0xFF1565C0);
    case 'green':
      return const Color(0xFF2E7D32);
    default:
      return const Color(0xFFE53935);
  }
}

/// Builds the correct monster widget for the given evolution ID and color.
Widget buildMonsterWidget(
  String evolutionId,
  String monsterColor, {
  double size = 180,
  double animValue = 0.0,
}) {
  final color = getMonsterPrimaryColor(monsterColor);
  final id = evolutionId.toLowerCase();

  CustomPainter painter;

  // ── Base form: 1 species 'runmon', visual differentiated by color only ───────
  if (id == 'runmon') {
    painter = _buildRunmonPainter(color, monsterColor, animValue);
  }
  // Legacy backward-compat for Hive data before lazy migration runs
  else if (id == 'runmon_red') {
    painter = FoxMonsterPainter(color, animValue: animValue);
  } else if (id == 'runmon_blue') {
    painter = DolphinMonsterPainter(color, animValue: animValue);
  } else if (id == 'runmon_green') {
    painter = FrogMonsterPainter(color, animValue: animValue);
  }

  // ── Lv10 evolutions ─────────────────────────────────────────────────────────
  else if (id == 'beastmon') {
    painter = BeastMonPainter(color, animValue: animValue);
  } else if (id == 'spiritmon') {
    painter = SpiritMonPainter(color, animValue: animValue);
  }

  // ── Advanced lion/leo ────────────────────────────────────────────────────────
  else if (id.contains('lion') || id.contains('leo')) {
    painter = LionMonsterPainter(color, animValue: animValue);
  }

  // ── Advanced wolf/arctic/fenrir ──────────────────────────────────────────────
  else if (id.contains('wolf') || id.contains('arctic') || id.contains('fenrir')) {
    painter = WolfMonsterPainter(color, animValue: animValue);
  }

  // ── Phoenix / blaze / sun ────────────────────────────────────────────────────
  else if (id.contains('phoenix') || id.contains('blaze') || id.contains('sun')) {
    painter = PhoenixMonsterPainter(color, animValue: animValue);
  }

  // ── Dragon / storm / crystal / sky ──────────────────────────────────────────
  else if (id.contains('dragon') ||
      id.contains('storm') ||
      id.contains('crystal') ||
      id.contains('sky')) {
    painter = DragonMonsterPainter(color, animValue: animValue);
  }

  // ── Shadow / void ────────────────────────────────────────────────────────────
  else if (id.contains('shadow') || id.contains('void')) {
    painter = ShadowMonsterPainter(color, animValue: animValue);
  }

  // ── King / emperor / god / ragnarok / glacier / prism ───────────────────────
  else if (id.contains('king') ||
      id.contains('emperor') ||
      id.contains('god') ||
      id.contains('ragnarok') ||
      id.contains('glacier') ||
      id.contains('prism')) {
    painter = GodMonsterPainter(color, animValue: animValue);
  }

  // ── Fallback: pick by color ──────────────────────────────────────────────────
  else {
    switch (monsterColor.toLowerCase()) {
      case 'blue':
        painter = DolphinMonsterPainter(color, animValue: animValue);
        break;
      case 'green':
        painter = FrogMonsterPainter(color, animValue: animValue);
        break;
      default:
        painter = FoxMonsterPainter(color, animValue: animValue);
    }
  }

  return SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: painter, size: Size(size, size)),
  );
}

CustomPainter _buildRunmonPainter(Color color, String monsterColor, double animValue) {
  switch (monsterColor.toLowerCase()) {
    case 'blue':
      return DolphinMonsterPainter(color, animValue: animValue);
    case 'green':
      return FrogMonsterPainter(color, animValue: animValue);
    default:
      return FoxMonsterPainter(color, animValue: animValue);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Base class
// ─────────────────────────────────────────────────────────────────────────────

abstract class BaseMonsterPainter extends CustomPainter {
  final Color primaryColor;
  final double animValue;
  const BaseMonsterPainter(this.primaryColor, {this.animValue = 0.0});

  @override
  bool shouldRepaint(covariant BaseMonsterPainter oldDelegate) =>
      oldDelegate.animValue != animValue || oldDelegate.primaryColor != primaryColor;

  /// Draw a soft radial glow behind the monster (pulses with animValue).
  void drawAura(Canvas canvas, Size size, List<Color> colors, {double radius = 0.46}) {
    final pulse = 1.0 + 0.06 * math.sin(animValue);
    final center = Offset(size.width / 2, size.height / 2 + 4 * math.sin(animValue));
    final r = size.width * radius * pulse;
    final paint = Paint()
      ..shader = RadialGradient(colors: colors).createShader(
        Rect.fromCircle(center: center, radius: r),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, r, paint);
  }

  /// Utility: draw a filled oval with a linear gradient.
  void drawGradientOval(
    Canvas canvas,
    Rect rect,
    List<Color> colors, {
    Alignment begin = Alignment.topCenter,
    Alignment end = Alignment.bottomCenter,
    double blurSigma = 0,
  }) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      ).createShader(rect);
    if (blurSigma > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    }
    canvas.drawOval(rect, paint);
  }

  /// Utility: draw a gradient-filled circle.
  void drawGradientCircle(
    Canvas canvas,
    Offset center,
    double radius,
    List<Color> colors, {
    double blurSigma = 0,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: colors,
        stops: const [0.0, 1.0],
      ).createShader(rect);
    if (blurSigma > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    }
    canvas.drawCircle(center, radius, paint);
  }

  /// Draw a layered expressive eye at [center] with radius [r].
  void drawEye(
    Canvas canvas,
    Offset center,
    double r, {
    Color irisColor = const Color(0xFF4CAF50),
    Color highlightColor = const Color(0xFF00BCD4),
  }) {
    // Sclera (white)
    canvas.drawCircle(center, r, Paint()..color = Colors.white);
    // Iris
    drawGradientCircle(canvas, center, r * 0.72, [irisColor, irisColor.withAlpha(180)]);
    // Pupil
    canvas.drawCircle(center, r * 0.38, Paint()..color = Colors.black);
    // Cyan highlight
    canvas.drawCircle(
      Offset(center.dx + r * 0.2, center.dy - r * 0.25),
      r * 0.2,
      Paint()..color = highlightColor,
    );
    // White sparkle
    canvas.drawCircle(
      Offset(center.dx - r * 0.18, center.dy - r * 0.3),
      r * 0.12,
      Paint()..color = Colors.white,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOX MONSTER (runmon_red)
// ─────────────────────────────────────────────────────────────────────────────

class FoxMonsterPainter extends BaseMonsterPainter {
  const FoxMonsterPainter(super.primaryColor, {super.animValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Whole-body float: bobs gently up/down
    canvas.save();
    canvas.translate(0, math.sin(animValue) * 3.5);
    _drawAura(canvas, size);
    _drawFlameParticles(canvas, size);
    _drawTail(canvas, size);
    _drawBody(canvas, size);
    _drawBelly(canvas, size);
    _drawHead(canvas, size);
    _drawEars(canvas, size);
    _drawEyes(canvas, size);
    _drawNoseAndMouth(canvas, size);
    canvas.restore();
  }

  void _drawAura(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Petal flame shapes
    final petalPaint = Paint()
      ..color = const Color(0xFFFF6B35).withAlpha(60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 2 + math.pi / 4);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(size.width * 0.15, -size.height * 0.18, 0, -size.height * 0.44)
        ..quadraticBezierTo(-size.width * 0.15, -size.height * 0.18, 0, 0);
      canvas.drawPath(path, petalPaint);
      canvas.restore();
    }
    drawAura(canvas, size, [
      const Color(0xFFFF6B35).withAlpha(120),
      const Color(0xFFE53935).withAlpha(60),
      Colors.transparent,
    ]);
  }

  void _drawFlameParticles(Canvas canvas, Size size) {
    final flames = [
      Offset(size.width * 0.14, size.height * 0.38),
      Offset(size.width * 0.82, size.height * 0.42),
      Offset(size.width * 0.22, size.height * 0.70),
      Offset(size.width * 0.78, size.height * 0.68),
      Offset(size.width * 0.50, size.height * 0.15),
      Offset(size.width * 0.35, size.height * 0.85),
    ];
    final flamePaint = Paint()
      ..color = const Color(0xFFFF8A50).withAlpha(200)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (final f in flames) {
      final path = Path()
        ..moveTo(f.dx, f.dy)
        ..quadraticBezierTo(f.dx + size.width * 0.025, f.dy - size.height * 0.04,
            f.dx, f.dy - size.height * 0.065)
        ..quadraticBezierTo(f.dx - size.width * 0.025, f.dy - size.height * 0.04,
            f.dx, f.dy);
      canvas.drawPath(path, flamePaint);
    }
  }

  void _drawTail(Canvas canvas, Size size) {
    // Tail wags with animValue
    canvas.save();
    canvas.translate(size.width * 0.62, size.height * 0.72);
    canvas.rotate(math.sin(animValue) * 0.14);
    canvas.translate(-size.width * 0.62, -size.height * 0.72);
    final tailPath = Path()
      ..moveTo(size.width * 0.62, size.height * 0.72)
      ..cubicTo(
        size.width * 0.92, size.height * 0.58,
        size.width * 1.02, size.height * 0.32,
        size.width * 0.88, size.height * 0.18,
      )
      ..cubicTo(
        size.width * 0.78, size.height * 0.10,
        size.width * 0.68, size.height * 0.22,
        size.width * 0.72, size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.74, size.height * 0.44,
        size.width * 0.68, size.height * 0.54,
        size.width * 0.60, size.height * 0.68,
      )
      ..close();
    final tailPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFFF8A50), const Color(0xFFE53935)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(tailPath, tailPaint);

    // White tail tip
    final tipPath = Path()
      ..moveTo(size.width * 0.82, size.height * 0.12)
      ..cubicTo(
        size.width * 0.90, size.height * 0.10,
        size.width * 0.96, size.height * 0.16,
        size.width * 0.88, size.height * 0.22,
      )
      ..cubicTo(
        size.width * 0.82, size.height * 0.18,
        size.width * 0.76, size.height * 0.14,
        size.width * 0.82, size.height * 0.12,
      )
      ..close();
    canvas.drawPath(tipPath, Paint()..color = Colors.white.withAlpha(220));
    canvas.restore(); // end tail wag rotation
  }

  void _drawBody(Canvas canvas, Size size) {
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.46, size.height * 0.73),
      width: size.width * 0.58,
      height: size.height * 0.52,
    );
    drawGradientOval(
      canvas, bodyRect,
      [const Color(0xFFFF6B35), const Color(0xFFE53935)],
    );
    // Body glow outline
    canvas.drawOval(
      bodyRect,
      Paint()
        ..color = const Color(0xFFFF8A50).withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _drawBelly(Canvas canvas, Size size) {
    final bellyRect = Rect.fromCenter(
      center: Offset(size.width * 0.44, size.height * 0.77),
      width: size.width * 0.30,
      height: size.height * 0.28,
    );
    drawGradientOval(canvas, bellyRect, [
      const Color(0xFFFFF9C4),
      const Color(0xFFFFE0B2),
    ]);
  }

  void _drawHead(Canvas canvas, Size size) {
    drawGradientCircle(
      canvas,
      Offset(size.width * 0.44, size.height * 0.44),
      size.width * 0.26,
      [const Color(0xFFFF8A50), const Color(0xFFE53935)],
    );
    // Head highlight
    drawGradientCircle(
      canvas,
      Offset(size.width * 0.38, size.height * 0.38),
      size.width * 0.10,
      [Colors.white.withAlpha(60), Colors.transparent],
    );
  }

  void _drawEars(Canvas canvas, Size size) {
    // Left ear
    final leftEar = Path()
      ..moveTo(size.width * 0.22, size.height * 0.36)
      ..lineTo(size.width * 0.16, size.height * 0.16)
      ..lineTo(size.width * 0.34, size.height * 0.26)
      ..close();
    canvas.drawPath(leftEar, Paint()..color = const Color(0xFFFF6B35));
    final leftInner = Path()
      ..moveTo(size.width * 0.23, size.height * 0.33)
      ..lineTo(size.width * 0.19, size.height * 0.20)
      ..lineTo(size.width * 0.31, size.height * 0.27)
      ..close();
    canvas.drawPath(leftInner, Paint()..color = const Color(0xFFFF8A80));

    // Right ear
    final rightEar = Path()
      ..moveTo(size.width * 0.58, size.height * 0.30)
      ..lineTo(size.width * 0.62, size.height * 0.12)
      ..lineTo(size.width * 0.70, size.height * 0.28)
      ..close();
    canvas.drawPath(rightEar, Paint()..color = const Color(0xFFFF6B35));
    final rightInner = Path()
      ..moveTo(size.width * 0.59, size.height * 0.28)
      ..lineTo(size.width * 0.63, size.height * 0.16)
      ..lineTo(size.width * 0.68, size.height * 0.27)
      ..close();
    canvas.drawPath(rightInner, Paint()..color = const Color(0xFFFF8A80));
  }

  void _drawEyes(Canvas canvas, Size size) {
    drawEye(
      canvas,
      Offset(size.width * 0.33, size.height * 0.42),
      size.width * 0.075,
      irisColor: const Color(0xFF4CAF50),
      highlightColor: const Color(0xFF00BCD4),
    );
    drawEye(
      canvas,
      Offset(size.width * 0.55, size.height * 0.40),
      size.width * 0.075,
      irisColor: const Color(0xFF4CAF50),
      highlightColor: const Color(0xFF00BCD4),
    );
  }

  void _drawNoseAndMouth(Canvas canvas, Size size) {
    // Nose
    final nosePath = Path()
      ..moveTo(size.width * 0.42, size.height * 0.51)
      ..lineTo(size.width * 0.44, size.height * 0.53)
      ..lineTo(size.width * 0.46, size.height * 0.51)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = Colors.black87);

    // Smile
    final smilePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(size.width * 0.36, size.height * 0.55)
      ..quadraticBezierTo(
          size.width * 0.44, size.height * 0.60, size.width * 0.52, size.height * 0.55);
    canvas.drawPath(smilePath, smilePaint);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOLPHIN MONSTER (runmon_blue)
// ─────────────────────────────────────────────────────────────────────────────

class DolphinMonsterPainter extends BaseMonsterPainter {
  const DolphinMonsterPainter(super.primaryColor, {super.animValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Dolphin undulates: slight tilt + vertical bob
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(math.sin(animValue) * 0.06);
    canvas.translate(-size.width / 2, -size.height / 2 + math.cos(animValue) * 2.5);
    _drawAura(canvas, size);
    _drawBubbles(canvas, size);
    _drawTailFin(canvas, size);
    _drawBody(canvas, size);
    _drawBelly(canvas, size);
    _drawDorsalFin(canvas, size);
    _drawSideFins(canvas, size);
    _drawEyes(canvas, size);
    _drawMouth(canvas, size);
    canvas.restore();
  }

  void _drawAura(Canvas canvas, Size size) {
    drawAura(canvas, size, [
      const Color(0xFF29B6F6).withAlpha(130),
      const Color(0xFF0288D1).withAlpha(60),
      Colors.transparent,
    ]);
  }

  void _drawBubbles(Canvas canvas, Size size) {
    // Bubbles drift upward based on animValue phase
    final drift = math.sin(animValue) * size.height * 0.025;
    final bubbles = [
      (Offset(size.width * 0.12, size.height * 0.25 + drift * 0.8), size.width * 0.045),
      (Offset(size.width * 0.85, size.height * 0.22 - drift * 0.5), size.width * 0.035),
      (Offset(size.width * 0.08, size.height * 0.58 + drift), size.width * 0.030),
      (Offset(size.width * 0.88, size.height * 0.55 - drift * 0.7), size.width * 0.050),
      (Offset(size.width * 0.18, size.height * 0.80 + drift * 0.3), size.width * 0.028),
      (Offset(size.width * 0.80, size.height * 0.78 - drift * 0.9), size.width * 0.038),
      (Offset(size.width * 0.50, size.height * 0.10 + drift * 0.6), size.width * 0.025),
      (Offset(size.width * 0.68, size.height * 0.12 - drift * 0.4), size.width * 0.032),
    ];
    for (final (center, r) in bubbles) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = Colors.white.withAlpha(50)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = const Color(0xFF80DEEA).withAlpha(160)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      // Highlight inside bubble
      canvas.drawCircle(
        Offset(center.dx - r * 0.3, center.dy - r * 0.3),
        r * 0.25,
        Paint()..color = Colors.white.withAlpha(120),
      );
    }
  }

  void _drawTailFin(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF1565C0), const Color(0xFF0D47A1)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Left lobe
    final leftLobe = Path()
      ..moveTo(size.width * 0.40, size.height * 0.88)
      ..cubicTo(
        size.width * 0.26, size.height * 0.86,
        size.width * 0.18, size.height * 0.96,
        size.width * 0.24, size.height * 0.98,
      )
      ..cubicTo(
        size.width * 0.30, size.height * 1.00,
        size.width * 0.36, size.height * 0.94,
        size.width * 0.40, size.height * 0.88,
      )
      ..close();
    canvas.drawPath(leftLobe, paint);

    // Right lobe
    final rightLobe = Path()
      ..moveTo(size.width * 0.50, size.height * 0.88)
      ..cubicTo(
        size.width * 0.64, size.height * 0.86,
        size.width * 0.72, size.height * 0.96,
        size.width * 0.66, size.height * 0.98,
      )
      ..cubicTo(
        size.width * 0.60, size.height * 1.00,
        size.width * 0.54, size.height * 0.94,
        size.width * 0.50, size.height * 0.88,
      )
      ..close();
    canvas.drawPath(rightLobe, paint);
  }

  void _drawBody(Canvas canvas, Size size) {
    // Streamlined teardrop body
    final bodyPath = Path()
      ..moveTo(size.width * 0.45, size.height * 0.18)
      ..cubicTo(
        size.width * 0.68, size.height * 0.18,
        size.width * 0.76, size.height * 0.44,
        size.width * 0.72, size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.68, size.height * 0.82,
        size.width * 0.56, size.height * 0.90,
        size.width * 0.45, size.height * 0.90,
      )
      ..cubicTo(
        size.width * 0.34, size.height * 0.90,
        size.width * 0.22, size.height * 0.82,
        size.width * 0.18, size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.14, size.height * 0.44,
        size.width * 0.22, size.height * 0.18,
        size.width * 0.45, size.height * 0.18,
      )
      ..close();

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF4FC3F7), const Color(0xFF1565C0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(bodyPath, bodyPaint);

    // Highlight shimmer
    final shimmerPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.22)
      ..cubicTo(
        size.width * 0.50, size.height * 0.20,
        size.width * 0.62, size.height * 0.30,
        size.width * 0.58, size.height * 0.46,
      )
      ..cubicTo(
        size.width * 0.50, size.height * 0.36,
        size.width * 0.38, size.height * 0.30,
        size.width * 0.35, size.height * 0.22,
      )
      ..close();
    canvas.drawPath(
      shimmerPath,
      Paint()..color = Colors.white.withAlpha(45),
    );
  }

  void _drawBelly(Canvas canvas, Size size) {
    final bellyPath = Path()
      ..moveTo(size.width * 0.45, size.height * 0.32)
      ..cubicTo(
        size.width * 0.56, size.height * 0.32,
        size.width * 0.60, size.height * 0.56,
        size.width * 0.55, size.height * 0.76,
      )
      ..cubicTo(
        size.width * 0.50, size.height * 0.84,
        size.width * 0.40, size.height * 0.84,
        size.width * 0.35, size.height * 0.76,
      )
      ..cubicTo(
        size.width * 0.30, size.height * 0.56,
        size.width * 0.34, size.height * 0.32,
        size.width * 0.45, size.height * 0.32,
      )
      ..close();
    canvas.drawPath(
      bellyPath,
      Paint()..color = const Color(0xFFE0F7FA).withAlpha(200),
    );
  }

  void _drawDorsalFin(Canvas canvas, Size size) {
    final finPath = Path()
      ..moveTo(size.width * 0.52, size.height * 0.26)
      ..cubicTo(
        size.width * 0.64, size.height * 0.20,
        size.width * 0.70, size.height * 0.28,
        size.width * 0.66, size.height * 0.38,
      )
      ..lineTo(size.width * 0.58, size.height * 0.36)
      ..close();
    canvas.drawPath(
      finPath,
      Paint()..color = const Color(0xFF1976D2),
    );
  }

  void _drawSideFins(Canvas canvas, Size size) {
    final finPaint = Paint()..color = const Color(0xFF29B6F6).withAlpha(200);

    // Left fin
    final leftFin = Path()
      ..moveTo(size.width * 0.22, size.height * 0.54)
      ..cubicTo(
        size.width * 0.08, size.height * 0.52,
        size.width * 0.06, size.height * 0.66,
        size.width * 0.14, size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.18, size.height * 0.64,
        size.width * 0.20, size.height * 0.60,
        size.width * 0.22, size.height * 0.54,
      )
      ..close();
    canvas.drawPath(leftFin, finPaint);

    // Right fin
    final rightFin = Path()
      ..moveTo(size.width * 0.68, size.height * 0.54)
      ..cubicTo(
        size.width * 0.82, size.height * 0.52,
        size.width * 0.84, size.height * 0.66,
        size.width * 0.76, size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.72, size.height * 0.64,
        size.width * 0.70, size.height * 0.60,
        size.width * 0.68, size.height * 0.54,
      )
      ..close();
    canvas.drawPath(rightFin, finPaint);
  }

  void _drawEyes(Canvas canvas, Size size) {
    drawEye(
      canvas,
      Offset(size.width * 0.35, size.height * 0.40),
      size.width * 0.072,
      irisColor: const Color(0xFF7C4DFF),
      highlightColor: const Color(0xFFFF4081),
    );
    drawEye(
      canvas,
      Offset(size.width * 0.55, size.height * 0.38),
      size.width * 0.072,
      irisColor: const Color(0xFF7C4DFF),
      highlightColor: const Color(0xFFFF4081),
    );
  }

  void _drawMouth(Canvas canvas, Size size) {
    final mouthPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final mouthPath = Path()
      ..moveTo(size.width * 0.37, size.height * 0.52)
      ..quadraticBezierTo(
          size.width * 0.45, size.height * 0.57, size.width * 0.53, size.height * 0.52);
    canvas.drawPath(mouthPath, mouthPaint);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FROG MONSTER (runmon_green)
// ─────────────────────────────────────────────────────────────────────────────

class FrogMonsterPainter extends BaseMonsterPainter {
  const FrogMonsterPainter(super.primaryColor, {super.animValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Frog bounces — fast up-down
    canvas.save();
    canvas.translate(0, math.sin(animValue * 1.5) * 4.0);
    _drawAura(canvas, size);
    _drawBody(canvas, size);
    _drawBelly(canvas, size);
    _drawLegs(canvas, size);
    _drawEyes(canvas, size);
    _drawMouth(canvas, size);
    _drawLeafParticles(canvas, size);
    canvas.restore();
  }

  void _drawAura(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Leaf shapes rotate with animValue
    final leafPaint = Paint()
      ..color = const Color(0xFF66BB6A).withAlpha(70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 2 + math.pi / 8 + animValue * 0.3);
      final leaf = Path()
        ..moveTo(0, 0)
        ..cubicTo(
          size.width * 0.10, -size.height * 0.14,
          size.width * 0.16, -size.height * 0.28,
          0, -size.height * 0.42,
        )
        ..cubicTo(
          -size.width * 0.16, -size.height * 0.28,
          -size.width * 0.10, -size.height * 0.14,
          0, 0,
        );
      canvas.drawPath(leaf, leafPaint);
      canvas.restore();
    }
    drawAura(canvas, size, [
      const Color(0xFF66BB6A).withAlpha(100),
      const Color(0xFF2E7D32).withAlpha(40),
      Colors.transparent,
    ]);
  }

  void _drawBody(Canvas canvas, Size size) {
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.65),
      width: size.width * 0.70,
      height: size.height * 0.50,
    );
    drawGradientOval(canvas, bodyRect,
        [const Color(0xFF81C784), const Color(0xFF2E7D32)]);
    canvas.drawOval(
      bodyRect,
      Paint()
        ..color = const Color(0xFF4CAF50).withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  void _drawBelly(Canvas canvas, Size size) {
    final bellyRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.68),
      width: size.width * 0.38,
      height: size.height * 0.30,
    );
    drawGradientOval(canvas, bellyRect,
        [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]);
  }

  void _drawLegs(Canvas canvas, Size size) {
    final legPaint = Paint()..color = const Color(0xFF388E3C);
    // Left foot
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.20, size.height * 0.86),
        width: size.width * 0.18,
        height: size.height * 0.10,
      ),
      legPaint,
    );
    // Right foot
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.80, size.height * 0.86),
        width: size.width * 0.18,
        height: size.height * 0.10,
      ),
      legPaint,
    );
    // Toe dividers
    final toePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * (0.16 + i * 0.03), size.height * 0.84),
        Offset(size.width * (0.14 + i * 0.03), size.height * 0.90),
        toePaint,
      );
      canvas.drawLine(
        Offset(size.width * (0.76 + i * 0.03), size.height * 0.84),
        Offset(size.width * (0.74 + i * 0.03), size.height * 0.90),
        toePaint,
      );
    }
  }

  void _drawEyes(Canvas canvas, Size size) {
    // Bulge sockets on top of head
    for (final cx in [size.width * 0.36, size.width * 0.64]) {
      drawGradientCircle(
        canvas,
        Offset(cx, size.height * 0.36),
        size.width * 0.115,
        [const Color(0xFF81C784), const Color(0xFF388E3C)],
      );
    }
    drawEye(
      canvas,
      Offset(size.width * 0.36, size.height * 0.36),
      size.width * 0.082,
      irisColor: const Color(0xFFF9A825),
      highlightColor: const Color(0xFF69F0AE),
    );
    drawEye(
      canvas,
      Offset(size.width * 0.64, size.height * 0.36),
      size.width * 0.082,
      irisColor: const Color(0xFFF9A825),
      highlightColor: const Color(0xFF69F0AE),
    );
  }

  void _drawMouth(Canvas canvas, Size size) {
    final mouthPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final mouthPath = Path()
      ..moveTo(size.width * 0.32, size.height * 0.60)
      ..quadraticBezierTo(
          size.width * 0.50, size.height * 0.70, size.width * 0.68, size.height * 0.60);
    canvas.drawPath(mouthPath, mouthPaint);
  }

  void _drawLeafParticles(Canvas canvas, Size size) {
    // Leaves orbit around the body
    final basePositions = [
      Offset(size.width * 0.10, size.height * 0.30),
      Offset(size.width * 0.86, size.height * 0.28),
      Offset(size.width * 0.12, size.height * 0.70),
      Offset(size.width * 0.84, size.height * 0.72),
    ];
    for (int i = 0; i < basePositions.length; i++) {
      final base = basePositions[i];
      final phase = animValue + i * math.pi / 2;
      final pos = Offset(
        base.dx + math.cos(phase) * size.width * 0.03,
        base.dy + math.sin(phase) * size.height * 0.03,
      );
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(phase);
      canvas.translate(-pos.dx, -pos.dy);
      final leaf = Path()
        ..moveTo(pos.dx, pos.dy)
        ..cubicTo(
          pos.dx + size.width * 0.04, pos.dy - size.height * 0.04,
          pos.dx + size.width * 0.08, pos.dy,
          pos.dx + size.width * 0.06, pos.dy + size.height * 0.04,
        )
        ..cubicTo(
          pos.dx + size.width * 0.02, pos.dy + size.height * 0.06,
          pos.dx - size.width * 0.02, pos.dy + size.height * 0.02,
          pos.dx, pos.dy,
        );
      canvas.drawPath(
        leaf,
        Paint()..color = const Color(0xFF66BB6A).withAlpha(180),
      );
      canvas.restore();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BEAST MON (beastmon) - Lv10 evolved beast
// ─────────────────────────────────────────────────────────────────────────────

class BeastMonPainter extends BaseMonsterPainter {
  const BeastMonPainter(super.primaryColor, {super.animValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Beast menacingly leans forward then back
    canvas.translate(math.sin(animValue) * 2.5, math.cos(animValue * 0.7) * 3.0);
    _drawAura(canvas, size);
    _drawTail(canvas, size);
    _drawBody(canvas, size);
    _drawChestMark(canvas, size);
    _drawHead(canvas, size);
    _drawEars(canvas, size);
    _drawEyes(canvas, size);
    _drawNoseAndMouth(canvas, size);
    _drawClawMarks(canvas, size);
    canvas.restore();
  }

  void _drawAura(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final fierPaint = Paint()
      ..color = const Color(0xFFFF6B35).withAlpha(80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(center, size.width * 0.50, fierPaint);
    // Flame spikes
    for (int i = 0; i < 6; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 3);
      final spike = Path()
        ..moveTo(0, -size.height * 0.30)
        ..lineTo(size.width * 0.06, -size.height * 0.20)
        ..lineTo(0, -size.height * 0.48)
        ..lineTo(-size.width * 0.06, -size.height * 0.20)
        ..close();
      canvas.drawPath(
        spike,
        Paint()..color = const Color(0xFFFF8A50).withAlpha(100),
      );
      canvas.restore();
    }
  }

  void _drawTail(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.64, size.height * 0.70)
      ..cubicTo(
        size.width * 0.88, size.height * 0.54,
        size.width * 0.98, size.height * 0.26,
        size.width * 0.84, size.height * 0.10,
      )
      ..cubicTo(
        size.width * 0.76, size.height * 0.04,
        size.width * 0.68, size.height * 0.14,
        size.width * 0.74, size.height * 0.28,
      )
      ..cubicTo(
        size.width * 0.78, size.height * 0.42,
        size.width * 0.70, size.height * 0.56,
        size.width * 0.62, size.height * 0.66,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFFFF8A50), const Color(0xFFBF360C)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _drawBody(Canvas canvas, Size size) {
    // Wider, more muscular body shape
    final bodyPath = Path()
      ..moveTo(size.width * 0.30, size.height * 0.56)
      ..cubicTo(
        size.width * 0.22, size.height * 0.62,
        size.width * 0.20, size.height * 0.82,
        size.width * 0.28, size.height * 0.92,
      )
      ..lineTo(size.width * 0.62, size.height * 0.92)
      ..cubicTo(
        size.width * 0.70, size.height * 0.82,
        size.width * 0.68, size.height * 0.62,
        size.width * 0.60, size.height * 0.56,
      )
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFFFF7043), const Color(0xFFBF360C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    // Body outline glow
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFFFF8A50).withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _drawChestMark(Canvas canvas, Size size) {
    // Star-like marking on chest
    final starPaint = Paint()..color = const Color(0xFFFFCC02).withAlpha(200);
    final cx = size.width * 0.44;
    final cy = size.height * 0.74;
    final r = size.width * 0.06;
    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * math.pi / 5 - math.pi / 2;
      canvas.drawCircle(
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        size.width * 0.018,
        starPaint,
      );
    }
    canvas.drawCircle(Offset(cx, cy), size.width * 0.022, starPaint);
  }

  void _drawHead(Canvas canvas, Size size) {
    drawGradientCircle(
      canvas,
      Offset(size.width * 0.44, size.height * 0.42),
      size.width * 0.28,
      [const Color(0xFFFF7043), const Color(0xFFBF360C)],
    );
  }

  void _drawEars(Canvas canvas, Size size) {
    // Sharper, more angular ears
    for (final (x, tipX) in [(0.20, 0.12), (0.62, 0.72)]) {
      final ear = Path()
        ..moveTo(size.width * x, size.height * 0.30)
        ..lineTo(size.width * tipX, size.height * 0.10)
        ..lineTo(size.width * (x + 0.14), size.height * 0.26)
        ..close();
      canvas.drawPath(ear, Paint()..color = const Color(0xFFE64A19));
      final inner = Path()
        ..moveTo(size.width * (x + 0.02), size.height * 0.28)
        ..lineTo(size.width * (tipX + 0.03), size.height * 0.14)
        ..lineTo(size.width * (x + 0.11), size.height * 0.26)
        ..close();
      canvas.drawPath(inner, Paint()..color = const Color(0xFFFF8A80));
    }
  }

  void _drawEyes(Canvas canvas, Size size) {
    // Red slit pupils for fierce look
    for (final cx in [size.width * 0.32, size.width * 0.56]) {
      final center = Offset(cx, size.height * 0.40);
      canvas.drawCircle(center, size.width * 0.075, Paint()..color = Colors.white);
      // Red iris
      canvas.drawCircle(
        center,
        size.width * 0.055,
        Paint()..color = const Color(0xFFE53935),
      );
      // Slit pupil (narrow vertical ellipse)
      canvas.drawOval(
        Rect.fromCenter(center: center, width: size.width * 0.016, height: size.width * 0.065),
        Paint()..color = Colors.black,
      );
      // Highlight
      canvas.drawCircle(
        Offset(cx + size.width * 0.025, size.height * 0.376),
        size.width * 0.016,
        Paint()..color = Colors.white.withAlpha(200),
      );
    }
  }

  void _drawNoseAndMouth(Canvas canvas, Size size) {
    final nosePath = Path()
      ..moveTo(size.width * 0.41, size.height * 0.50)
      ..lineTo(size.width * 0.44, size.height * 0.53)
      ..lineTo(size.width * 0.47, size.height * 0.50)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = Colors.black87);

    // Fiercer smile with fangs
    final mouthPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.34, size.height * 0.55)
        ..quadraticBezierTo(
            size.width * 0.44, size.height * 0.62, size.width * 0.54, size.height * 0.55),
      mouthPaint,
    );
    // Fang hints
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.59),
      Offset(size.width * 0.38, size.height * 0.64),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(size.width * 0.50, size.height * 0.59),
      Offset(size.width * 0.50, size.height * 0.64),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawClawMarks(Canvas canvas, Size size) {
    final clawPaint = Paint()
      ..color = const Color(0xFFFF8A50).withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    // Three claw marks across body
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * (0.28 + i * 0.06), size.height * 0.66),
        Offset(size.width * (0.30 + i * 0.06), size.height * 0.76),
        clawPaint,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPIRIT MON (spiritmon) - Spirit eagle
// ─────────────────────────────────────────────────────────────────────────────

class SpiritMonPainter extends BaseMonsterPainter {
  const SpiritMonPainter(super.primaryColor, {super.animValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Spirit floats ethereally — slow gentle rise
    canvas.translate(math.cos(animValue * 0.8) * 1.5, math.sin(animValue * 0.6) * 4.5);
    _drawAura(canvas, size);
    _drawWings(canvas, size);
    _drawBody(canvas, size);
    _drawHead(canvas, size);
    _drawEyes(canvas, size);
    _drawEnergyWisps(canvas, size);
    _drawStarPatterns(canvas, size);
    canvas.restore();
  }

  void _drawAura(Canvas canvas, Size size) {
    drawAura(canvas, size, [
      const Color(0xFF7C4DFF).withAlpha(120),
      const Color(0xFF3F51B5).withAlpha(50),
      Colors.transparent,
    ]);
  }

  void _drawWings(Canvas canvas, Size size) {
    final wingPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF7E57C2), const Color(0xFF1A237E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Left wing
    final leftWing = Path()
      ..moveTo(size.width * 0.42, size.height * 0.46)
      ..cubicTo(
        size.width * 0.28, size.height * 0.30,
        size.width * 0.04, size.height * 0.34,
        size.width * 0.04, size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.04, size.height * 0.70,
        size.width * 0.18, size.height * 0.74,
        size.width * 0.36, size.height * 0.64,
      )
      ..close();
    canvas.drawPath(leftWing, wingPaint);

    // Right wing
    final rightWing = Path()
      ..moveTo(size.width * 0.58, size.height * 0.46)
      ..cubicTo(
        size.width * 0.72, size.height * 0.30,
        size.width * 0.96, size.height * 0.34,
        size.width * 0.96, size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.96, size.height * 0.70,
        size.width * 0.82, size.height * 0.74,
        size.width * 0.64, size.height * 0.64,
      )
      ..close();
    canvas.drawPath(rightWing, wingPaint);

    // Wing feather details
    final featherPaint = Paint()
      ..color = const Color(0xFF9575CD).withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(size.width * (0.38 - i * 0.08), size.height * (0.54 + i * 0.04)),
        Offset(size.width * (0.14 - i * 0.01), size.height * (0.58 + i * 0.02)),
        featherPaint,
      );
      canvas.drawLine(
        Offset(size.width * (0.62 + i * 0.08), size.height * (0.54 + i * 0.04)),
        Offset(size.width * (0.86 + i * 0.01), size.height * (0.58 + i * 0.02)),
        featherPaint,
      );
    }
  }

  void _drawBody(Canvas canvas, Size size) {
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.64),
      width: size.width * 0.38,
      height: size.height * 0.44,
    );
    drawGradientOval(canvas, bodyRect,
        [const Color(0xFF9575CD), const Color(0xFF4527A0)]);
    // Ethereal glow
    canvas.drawOval(
      bodyRect.inflate(4),
      Paint()
        ..color = const Color(0xFFB39DDB).withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _drawHead(Canvas canvas, Size size) {
    drawGradientCircle(
      canvas,
      Offset(size.width * 0.50, size.height * 0.40),
      size.width * 0.24,
      [const Color(0xFFAB47BC), const Color(0xFF4A148C)],
    );
    // Crown-like ridges
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(size.width * (0.50 + i * 0.10), size.height * 0.18),
        Offset(size.width * (0.50 + i * 0.06), size.height * 0.26),
        Paint()
          ..color = const Color(0xFFCE93D8)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawEyes(Canvas canvas, Size size) {
    // Glowing ethereal eyes
    for (final cx in [size.width * 0.40, size.width * 0.60]) {
      final center = Offset(cx, size.height * 0.40);
      canvas.drawCircle(
        center,
        size.width * 0.070,
        Paint()
          ..color = const Color(0xFF80DEEA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(center, size.width * 0.070, Paint()..color = Colors.white);
      canvas.drawCircle(
        center,
        size.width * 0.050,
        Paint()..color = const Color(0xFF00E5FF),
      );
      canvas.drawCircle(center, size.width * 0.028, Paint()..color = Colors.black);
      canvas.drawCircle(
        Offset(cx + size.width * 0.022, size.height * 0.386),
        size.width * 0.018,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawEnergyWisps(Canvas canvas, Size size) {
    final wispPaint = Paint()
      ..color = const Color(0xFF80DEEA).withAlpha(140)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final wisps = [
      [Offset(size.width * 0.10, size.height * 0.36),
       Offset(size.width * 0.06, size.height * 0.28),
       Offset(size.width * 0.10, size.height * 0.20)],
      [Offset(size.width * 0.90, size.height * 0.36),
       Offset(size.width * 0.94, size.height * 0.28),
       Offset(size.width * 0.90, size.height * 0.20)],
      [Offset(size.width * 0.22, size.height * 0.82),
       Offset(size.width * 0.16, size.height * 0.76),
       Offset(size.width * 0.20, size.height * 0.68)],
    ];
    for (final pts in wisps) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      path.quadraticBezierTo(pts[1].dx, pts[1].dy, pts[2].dx, pts[2].dy);
      canvas.drawPath(path, wispPaint);
    }
  }

  void _drawStarPatterns(Canvas canvas, Size size) {
    final starPaint = Paint()..color = const Color(0xFFE8EAF6).withAlpha(200);
    final stars = [
      Offset(size.width * 0.15, size.height * 0.48),
      Offset(size.width * 0.82, size.height * 0.46),
      Offset(size.width * 0.50, size.height * 0.14),
      Offset(size.width * 0.26, size.height * 0.88),
      Offset(size.width * 0.72, size.height * 0.86),
    ];
    for (final s in stars) {
      for (int i = 0; i < 4; i++) {
        final angle = i * math.pi / 2;
        canvas.drawLine(
          Offset(s.dx + size.width * 0.022 * math.cos(angle),
              s.dy + size.width * 0.022 * math.sin(angle)),
          Offset(s.dx - size.width * 0.022 * math.cos(angle),
              s.dy - size.width * 0.022 * math.sin(angle)),
          Paint()
            ..color = starPaint.color
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LION MONSTER - Majestic lion
// ─────────────────────────────────────────────────────────────────────────────

class LionMonsterPainter extends BaseMonsterPainter {
  const LionMonsterPainter(super.primaryColor, {super.animValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Lion sways regally side to side
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(math.sin(animValue * 0.5) * 0.04);
    canvas.translate(-size.width / 2, -size.height / 2 + math.sin(animValue) * 2.5);
    drawAura(canvas, size, [
      const Color(0xFFFFD54F).withAlpha(140),
      const Color(0xFFFFA000).withAlpha(60),
      Colors.transparent,
    ]);
    _drawMane(canvas, size);
    _drawBody(canvas, size);
    _drawTail(canvas, size);
    _drawHead(canvas, size);
    _drawCrown(canvas, size);
    _drawEyes(canvas, size);
    _drawNoseAndMouth(canvas, size);
    canvas.restore();
  }

  void _drawMane(Canvas canvas, Size size) {
    final manePaint = Paint()
      ..color = const Color(0xFFFF8F00).withAlpha(220)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      Offset(size.width * 0.46, size.height * 0.46),
      size.width * 0.32,
      manePaint,
    );
    // Mane spikes
    final spikePaint = Paint()..color = const Color(0xFFF57F17);
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final cx = size.width * 0.46 + size.width * 0.26 * math.cos(angle);
      final cy = size.height * 0.46 + size.height * 0.26 * math.sin(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.10,
          height: size.height * 0.14,
        ),
        spikePaint,
      );
    }
  }

  void _drawBody(Canvas canvas, Size size) {
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.46, size.height * 0.72),
      width: size.width * 0.56,
      height: size.height * 0.46,
    );
    drawGradientOval(canvas, bodyRect,
        [const Color(0xFFFFCA28), const Color(0xFFF57F17)]);
  }

  void _drawTail(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.62, size.height * 0.78)
      ..cubicTo(
        size.width * 0.84, size.height * 0.70,
        size.width * 0.94, size.height * 0.52,
        size.width * 0.86, size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.82, size.height * 0.28,
        size.width * 0.76, size.height * 0.34,
        size.width * 0.78, size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.80, size.height * 0.50,
        size.width * 0.74, size.height * 0.64,
        size.width * 0.60, size.height * 0.74,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFFFB300),
    );
    // Fluffy tail tip
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.34),
      size.width * 0.06,
      Paint()..color = const Color(0xFFF57F17),
    );
  }

  void _drawHead(Canvas canvas, Size size) {
    drawGradientCircle(
      canvas,
      Offset(size.width * 0.46, size.height * 0.44),
      size.width * 0.24,
      [const Color(0xFFFFEE58), const Color(0xFFFFB300)],
    );
  }

  void _drawCrown(Canvas canvas, Size size) {
    final crownPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFFFD700), const Color(0xFFFFA000)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final crown = Path()
      ..moveTo(size.width * 0.30, size.height * 0.24)
      ..lineTo(size.width * 0.34, size.height * 0.12)
      ..lineTo(size.width * 0.40, size.height * 0.20)
      ..lineTo(size.width * 0.46, size.height * 0.08)
      ..lineTo(size.width * 0.52, size.height * 0.20)
      ..lineTo(size.width * 0.58, size.height * 0.12)
      ..lineTo(size.width * 0.62, size.height * 0.24)
      ..close();
    canvas.drawPath(crown, crownPaint);
    // Jewel on crown
    canvas.drawCircle(
      Offset(size.width * 0.46, size.height * 0.18),
      size.width * 0.028,
      Paint()..color = const Color(0xFFE53935),
    );
  }

  void _drawEyes(Canvas canvas, Size size) {
    drawEye(
      canvas,
      Offset(size.width * 0.36, size.height * 0.42),
      size.width * 0.068,
      irisColor: const Color(0xFF43A047),
      highlightColor: const Color(0xFFFFD54F),
    );
    drawEye(
      canvas,
      Offset(size.width * 0.56, size.height * 0.42),
      size.width * 0.068,
      irisColor: const Color(0xFF43A047),
      highlightColor: const Color(0xFFFFD54F),
    );
  }

  void _drawNoseAndMouth(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.46, size.height * 0.52),
        width: size.width * 0.06,
        height: size.height * 0.032,
      ),
      Paint()..color = const Color(0xFFE91E63),
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.36, size.height * 0.56)
        ..quadraticBezierTo(
            size.width * 0.46, size.height * 0.62, size.width * 0.56, size.height * 0.56),
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WOLF MONSTER - Ice/lightning wolf
// ─────────────────────────────────────────────────────────────────────────────

class WolfMonsterPainter extends BaseMonsterPainter {
  const WolfMonsterPainter(super.primaryColor, {super.animValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Wolf in predatory alert — slight forward lean + charge bob
    canvas.translate(math.sin(animValue * 1.2) * 1.8, math.sin(animValue) * 3.0);
    drawAura(canvas, size, [
      const Color(0xFF80D8FF).withAlpha(130),
      const Color(0xFF01579B).withAlpha(50),
      Colors.transparent,
    ]);
    _drawLightning(canvas, size);
    _drawBody(canvas, size);
    _drawHead(canvas, size);
    _drawEars(canvas, size);
    _drawEyes(canvas, size);
    _drawMuzzle(canvas, size);
    _drawIceCrystals(canvas, size);
    canvas.restore();
  }

  void _drawLightning(Canvas canvas, Size size) {
    final boltPaint = Paint()
      ..color = const Color(0xFFB3E5FC).withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final bolt = Path()
      ..moveTo(size.width * 0.10, size.height * 0.20)
      ..lineTo(size.width * 0.20, size.height * 0.36)
      ..lineTo(size.width * 0.14, size.height * 0.36)
      ..lineTo(size.width * 0.24, size.height * 0.54);
    canvas.drawPath(bolt, boltPaint);
    final bolt2 = Path()
      ..moveTo(size.width * 0.86, size.height * 0.22)
      ..lineTo(size.width * 0.76, size.height * 0.38)
      ..lineTo(size.width * 0.82, size.height * 0.38)
      ..lineTo(size.width * 0.70, size.height * 0.56);
    canvas.drawPath(bolt2, boltPaint);
  }

  void _drawBody(Canvas canvas, Size size) {
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.46, size.height * 0.70),
      width: size.width * 0.54,
      height: size.height * 0.48,
    );
    drawGradientOval(canvas, bodyRect,
        [const Color(0xFF90CAF9), const Color(0xFF1565C0)]);
    // Fur texture stripes
    final furPaint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(size.width * (0.30 + i * 0.06), size.height * 0.58),
        Offset(size.width * (0.32 + i * 0.06), size.height * 0.74),
        furPaint,
      );
    }
  }

  void _drawHead(Canvas canvas, Size size) {
    // Slightly elongated wolf head
    drawGradientOval(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.46, size.height * 0.42),
        width: size.width * 0.48,
        height: size.height * 0.40,
      ),
      [const Color(0xFFB3E5FC), const Color(0xFF1976D2)],
    );
  }

  void _drawEars(Canvas canvas, Size size) {
    for (final (bx, tx) in [(0.24, 0.18), (0.62, 0.68)]) {
      final ear = Path()
        ..moveTo(size.width * bx, size.height * 0.26)
        ..lineTo(size.width * tx, size.height * 0.08)
        ..lineTo(size.width * (bx + 0.16), size.height * 0.24)
        ..close();
      canvas.drawPath(ear, Paint()..color = const Color(0xFF42A5F5));
      final inner = Path()
        ..moveTo(size.width * (bx + 0.02), size.height * 0.24)
        ..lineTo(size.width * (tx + 0.02), size.height * 0.12)
        ..lineTo(size.width * (bx + 0.12), size.height * 0.23)
        ..close();
      canvas.drawPath(inner, Paint()..color = const Color(0xFFB3E5FC));
    }
  }

  void _drawEyes(Canvas canvas, Size size) {
    drawEye(
      canvas,
      Offset(size.width * 0.34, size.height * 0.40),
      size.width * 0.072,
      irisColor: const Color(0xFF00B0FF),
      highlightColor: const Color(0xFFFFFFFF),
    );
    drawEye(
      canvas,
      Offset(size.width * 0.58, size.height * 0.40),
      size.width * 0.072,
      irisColor: const Color(0xFF00B0FF),
      highlightColor: const Color(0xFFFFFFFF),
    );
  }

  void _drawMuzzle(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.46, size.height * 0.54),
        width: size.width * 0.24,
        height: size.height * 0.14,
      ),
      Paint()..color = const Color(0xFFE3F2FD),
    );
    // Nose
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.46, size.height * 0.50),
        width: size.width * 0.058,
        height: size.height * 0.032,
      ),
      Paint()..color = Colors.black87,
    );
    // Smile
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.38, size.height * 0.56)
        ..quadraticBezierTo(
            size.width * 0.46, size.height * 0.62, size.width * 0.54, size.height * 0.56),
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawIceCrystals(Canvas canvas, Size size) {
    final crystalPaint = Paint()
      ..color = const Color(0xFFE1F5FE).withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final positions = [
      Offset(size.width * 0.08, size.height * 0.60),
      Offset(size.width * 0.84, size.height * 0.62),
      Offset(size.width * 0.20, size.height * 0.88),
      Offset(size.width * 0.72, size.height * 0.86),
    ];
    for (final p in positions) {
      for (int i = 0; i < 3; i++) {
        final angle = i * math.pi / 3;
        canvas.drawLine(
          Offset(p.dx + size.width * 0.028 * math.cos(angle),
              p.dy + size.width * 0.028 * math.sin(angle)),
          Offset(p.dx - size.width * 0.028 * math.cos(angle),
              p.dy - size.width * 0.028 * math.sin(angle)),
          crystalPaint,
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHOENIX MONSTER - Fire bird
// ─────────────────────────────────────────────────────────────────────────────

class PhoenixMonsterPainter extends BaseMonsterPainter {
  const PhoenixMonsterPainter(super.primaryColor, {super.animValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Phoenix soars — slow wing-cycle tilt + rise
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(math.sin(animValue * 0.7) * 0.07);
    canvas.translate(-size.width / 2, -size.height / 2 + math.cos(animValue * 0.9) * 4.0);
    drawAura(canvas, size, [
      const Color(0xFFFF6D00).withAlpha(140),
      const Color(0xFFFFD600).withAlpha(60),
      Colors.transparent,
    ]);
    _drawTailFeathers(canvas, size);
    _drawWings(canvas, size);
    _drawBody(canvas, size);
    _drawHead(canvas, size);
    _drawCrest(canvas, size);
    _drawEyes(canvas, size);
    _drawBeak(canvas, size);
    _drawEmbers(canvas, size);
    canvas.restore();
  }

  void _drawTailFeathers(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFFF6D00),
      const Color(0xFFFFD600),
      const Color(0xFFFF3D00),
    ];
    for (int i = 0; i < 3; i++) {
      final path = Path()
        ..moveTo(size.width * 0.46, size.height * 0.78)
        ..cubicTo(
          size.width * (0.30 + i * 0.16), size.height * 0.86,
          size.width * (0.16 + i * 0.22), size.height * 0.96,
          size.width * (0.14 + i * 0.22), size.height * 1.02,
        )
        ..cubicTo(
          size.width * (0.20 + i * 0.20), size.height * 0.98,
          size.width * (0.34 + i * 0.12), size.height * 0.90,
          size.width * 0.46, size.height * 0.78,
        );
      canvas.drawPath(path, Paint()..color = colors[i % 3].withAlpha(220));
    }
  }

  void _drawWings(Canvas canvas, Size size) {
    final leftWingPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFFFCA28), const Color(0xFFE65100)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Left wing spread
    final leftWing = Path()
      ..moveTo(size.width * 0.40, size.height * 0.50)
      ..cubicTo(
        size.width * 0.22, size.height * 0.32,
        size.width * 0.02, size.height * 0.28,
        size.width * 0.02, size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.02, size.height * 0.64,
        size.width * 0.22, size.height * 0.70,
        size.width * 0.36, size.height * 0.62,
      )
      ..close();
    canvas.drawPath(leftWing, leftWingPaint);

    final rightWingPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFFFCA28), const Color(0xFFE65100)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    // Right wing
    final rightWing = Path()
      ..moveTo(size.width * 0.60, size.height * 0.50)
      ..cubicTo(
        size.width * 0.78, size.height * 0.32,
        size.width * 0.98, size.height * 0.28,
        size.width * 0.98, size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.98, size.height * 0.64,
        size.width * 0.78, size.height * 0.70,
        size.width * 0.64, size.height * 0.62,
      )
      ..close();
    canvas.drawPath(rightWing, rightWingPaint);

    // Feather lines
    final featherPaint = Paint()
      ..color = const Color(0xFFFFD54F).withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(size.width * (0.38 - i * 0.07), size.height * (0.52 + i * 0.03)),
        Offset(size.width * (0.12 - i * 0.01), size.height * (0.50 + i * 0.02)),
        featherPaint,
      );
      canvas.drawLine(
        Offset(size.width * (0.62 + i * 0.07), size.height * (0.52 + i * 0.03)),
        Offset(size.width * (0.88 + i * 0.01), size.height * (0.50 + i * 0.02)),
        featherPaint,
      );
    }
  }

  void _drawBody(Canvas canvas, Size size) {
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.46, size.height * 0.64),
      width: size.width * 0.40,
      height: size.height * 0.40,
    );
    drawGradientOval(canvas, bodyRect,
        [const Color(0xFFFF8F00), const Color(0xFFE65100)]);
  }

  void _drawHead(Canvas canvas, Size size) {
    drawGradientCircle(
      canvas,
      Offset(size.width * 0.46, size.height * 0.38),
      size.width * 0.22,
      [const Color(0xFFFFCA28), const Color(0xFFFF6D00)],
    );
  }

  void _drawCrest(Canvas canvas, Size size) {
    final crestColors = [const Color(0xFFFF3D00), const Color(0xFFFFD600)];
    for (int i = 0; i < 3; i++) {
      final path = Path()
        ..moveTo(size.width * (0.38 + i * 0.08), size.height * 0.20)
        ..cubicTo(
          size.width * (0.34 + i * 0.08), size.height * 0.14,
          size.width * (0.36 + i * 0.08), size.height * 0.06,
          size.width * (0.42 + i * 0.06), size.height * 0.02,
        )
        ..cubicTo(
          size.width * (0.46 + i * 0.04), size.height * 0.06,
          size.width * (0.46 + i * 0.06), size.height * 0.14,
          size.width * (0.42 + i * 0.08), size.height * 0.20,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = crestColors[i % 2].withAlpha(220),
      );
    }
  }

  void _drawEyes(Canvas canvas, Size size) {
    drawEye(
      canvas,
      Offset(size.width * 0.36, size.height * 0.36),
      size.width * 0.065,
      irisColor: const Color(0xFFFF6D00),
      highlightColor: const Color(0xFFFFFF00),
    );
    drawEye(
      canvas,
      Offset(size.width * 0.56, size.height * 0.36),
      size.width * 0.065,
      irisColor: const Color(0xFFFF6D00),
      highlightColor: const Color(0xFFFFFF00),
    );
  }

  void _drawBeak(Canvas canvas, Size size) {
    final beak = Path()
      ..moveTo(size.width * 0.40, size.height * 0.46)
      ..lineTo(size.width * 0.46, size.height * 0.52)
      ..lineTo(size.width * 0.52, size.height * 0.46)
      ..lineTo(size.width * 0.46, size.height * 0.50)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFF8F00));
  }

  void _drawEmbers(Canvas canvas, Size size) {
    final emberPaint = Paint()
      ..color = const Color(0xFFFFD54F).withAlpha(200)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final positions = [
      Offset(size.width * 0.12, size.height * 0.32),
      Offset(size.width * 0.80, size.height * 0.30),
      Offset(size.width * 0.06, size.height * 0.60),
      Offset(size.width * 0.88, size.height * 0.58),
      Offset(size.width * 0.50, size.height * 0.10),
      Offset(size.width * 0.26, size.height * 0.84),
      Offset(size.width * 0.68, size.height * 0.86),
    ];
    for (final p in positions) {
      canvas.drawCircle(p, size.width * 0.016, emberPaint);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DRAGON MONSTER - Blue-purple dragon
// ─────────────────────────────────────────────────────────────────────────────

class DragonMonsterPainter extends BaseMonsterPainter {
  const DragonMonsterPainter(super.primaryColor, {super.animValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Dragon breathes power — chest expansion + slight lean back
    final breathScale = 1.0 + math.sin(animValue) * 0.025;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(breathScale, breathScale);
    canvas.translate(-size.width / 2, -size.height / 2);
    drawAura(canvas, size, [
      const Color(0xFF7C4DFF).withAlpha(130),
      const Color(0xFF1A237E).withAlpha(60),
      Colors.transparent,
    ]);
    _drawWings(canvas, size);
    _drawBody(canvas, size);
    _drawScales(canvas, size);
    _drawHead(canvas, size);
    _drawHorns(canvas, size);
    _drawEyes(canvas, size);
    _drawMouth(canvas, size);
    _drawClaws(canvas, size);
    canvas.restore();
  }

  void _drawWings(Canvas canvas, Size size) {
    final wingPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF512DA8), const Color(0xFF0D47A1)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final leftWing = Path()
      ..moveTo(size.width * 0.36, size.height * 0.42)
      ..cubicTo(
        size.width * 0.14, size.height * 0.22,
        size.width * 0.02, size.height * 0.40,
        size.width * 0.06, size.height * 0.62,
      )
      ..cubicTo(
        size.width * 0.10, size.height * 0.74,
        size.width * 0.24, size.height * 0.72,
        size.width * 0.34, size.height * 0.60,
      )
      ..close();
    canvas.drawPath(leftWing, wingPaint);

    final rightWing = Path()
      ..moveTo(size.width * 0.64, size.height * 0.42)
      ..cubicTo(
        size.width * 0.86, size.height * 0.22,
        size.width * 0.98, size.height * 0.40,
        size.width * 0.94, size.height * 0.62,
      )
      ..cubicTo(
        size.width * 0.90, size.height * 0.74,
        size.width * 0.76, size.height * 0.72,
        size.width * 0.66, size.height * 0.60,
      )
      ..close();
    canvas.drawPath(rightWing, wingPaint);

    // Wing membrane ribs
    final ribPaint = Paint()
      ..color = const Color(0xFF9575CD).withAlpha(140)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * (0.36 - i * 0.04), size.height * (0.44 + i * 0.06)),
        Offset(size.width * (0.10 + i * 0.02), size.height * (0.60 + i * 0.04)),
        ribPaint,
      );
      canvas.drawLine(
        Offset(size.width * (0.64 + i * 0.04), size.height * (0.44 + i * 0.06)),
        Offset(size.width * (0.90 - i * 0.02), size.height * (0.60 + i * 0.04)),
        ribPaint,
      );
    }
  }

  void _drawBody(Canvas canvas, Size size) {
    final bodyPath = Path()
      ..moveTo(size.width * 0.34, size.height * 0.54)
      ..cubicTo(
        size.width * 0.26, size.height * 0.62,
        size.width * 0.26, size.height * 0.82,
        size.width * 0.36, size.height * 0.90,
      )
      ..lineTo(size.width * 0.60, size.height * 0.90)
      ..cubicTo(
        size.width * 0.70, size.height * 0.82,
        size.width * 0.70, size.height * 0.62,
        size.width * 0.62, size.height * 0.54,
      )
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFF7E57C2), const Color(0xFF283593)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _drawScales(Canvas canvas, Size size) {
    final scalePaint = Paint()
      ..color = const Color(0xFF9575CD).withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 4; col++) {
        final x = size.width * (0.34 + col * 0.08 + (row % 2) * 0.04);
        final y = size.height * (0.60 + row * 0.08);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, y), width: size.width * 0.08, height: size.height * 0.06),
          0, math.pi,
          false,
          scalePaint,
        );
      }
    }
  }

  void _drawHead(Canvas canvas, Size size) {
    // Slightly angular dragon head
    final headPath = Path()
      ..moveTo(size.width * 0.30, size.height * 0.44)
      ..cubicTo(
        size.width * 0.28, size.height * 0.30,
        size.width * 0.38, size.height * 0.20,
        size.width * 0.48, size.height * 0.20,
      )
      ..cubicTo(
        size.width * 0.62, size.height * 0.20,
        size.width * 0.72, size.height * 0.30,
        size.width * 0.70, size.height * 0.44,
      )
      ..cubicTo(
        size.width * 0.68, size.height * 0.54,
        size.width * 0.58, size.height * 0.60,
        size.width * 0.48, size.height * 0.60,
      )
      ..cubicTo(
        size.width * 0.34, size.height * 0.60,
        size.width * 0.30, size.height * 0.52,
        size.width * 0.30, size.height * 0.44,
      )
      ..close();
    canvas.drawPath(
      headPath,
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFF9575CD), const Color(0xFF4527A0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _drawHorns(Canvas canvas, Size size) {
    for (final (bx, tx) in [(0.36, 0.28), (0.60, 0.70)]) {
      final horn = Path()
        ..moveTo(size.width * bx, size.height * 0.24)
        ..lineTo(size.width * tx, size.height * 0.06)
        ..lineTo(size.width * (bx + 0.08), size.height * 0.22)
        ..close();
      canvas.drawPath(horn, Paint()..color = const Color(0xFFB39DDB));
    }
  }

  void _drawEyes(Canvas canvas, Size size) {
    drawEye(
      canvas,
      Offset(size.width * 0.38, size.height * 0.38),
      size.width * 0.070,
      irisColor: const Color(0xFF00E5FF),
      highlightColor: const Color(0xFFFFFFFF),
    );
    drawEye(
      canvas,
      Offset(size.width * 0.60, size.height * 0.38),
      size.width * 0.070,
      irisColor: const Color(0xFF00E5FF),
      highlightColor: const Color(0xFFFFFFFF),
    );
  }

  void _drawMouth(Canvas canvas, Size size) {
    // Open maw with slight glow
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.36, size.height * 0.50)
        ..cubicTo(
          size.width * 0.40, size.height * 0.56,
          size.width * 0.56, size.height * 0.56,
          size.width * 0.60, size.height * 0.50,
        )
        ..cubicTo(
          size.width * 0.56, size.height * 0.53,
          size.width * 0.40, size.height * 0.53,
          size.width * 0.36, size.height * 0.50,
        )
        ..close(),
      Paint()..color = const Color(0xFF1A237E),
    );
    // Energy glow in mouth
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.48, size.height * 0.53),
        width: size.width * 0.14,
        height: size.height * 0.04,
      ),
      Paint()
        ..color = const Color(0xFF00E5FF).withAlpha(140)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _drawClaws(Canvas canvas, Size size) {
    final clawPaint = Paint()..color = const Color(0xFFB39DDB);
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * (0.34 + i * 0.06), size.height * 0.88),
        Offset(size.width * (0.32 + i * 0.06), size.height * 0.94),
        Paint()
          ..color = clawPaint.color
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(size.width * (0.56 + i * 0.06), size.height * 0.88),
        Offset(size.width * (0.54 + i * 0.06), size.height * 0.94),
        Paint()
          ..color = clawPaint.color
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHADOW MONSTER - Dark mystical
// ─────────────────────────────────────────────────────────────────────────────

class ShadowMonsterPainter extends BaseMonsterPainter {
  const ShadowMonsterPainter(super.primaryColor, {super.animValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Shadow warps reality — jittery void displacement
    canvas.translate(
      math.sin(animValue * 2.3) * 1.5,
      math.sin(animValue * 1.7) * 3.5,
    );
    _drawVoidAura(canvas, size);
    _drawShadowTendrils(canvas, size);
    _drawBody(canvas, size);
    _drawEyes(canvas, size);
    _drawVoidSymbols(canvas, size);
    canvas.restore();
  }

  void _drawVoidAura(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      size.width * 0.46,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF4A148C).withAlpha(160),
            const Color(0xFF1A0030).withAlpha(80),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.46))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
  }

  void _drawShadowTendrils(Canvas canvas, Size size) {
    final tendrilPaint = Paint()
      ..color = const Color(0xFF7B1FA2).withAlpha(140)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final center = Offset(size.width * 0.48, size.height * 0.58);
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..cubicTo(
          center.dx + size.width * 0.18 * math.cos(angle + 0.4),
          center.dy + size.height * 0.18 * math.sin(angle + 0.4),
          center.dx + size.width * 0.28 * math.cos(angle - 0.3),
          center.dy + size.height * 0.28 * math.sin(angle - 0.3),
          center.dx + size.width * 0.38 * math.cos(angle),
          center.dy + size.height * 0.38 * math.sin(angle),
        );
      canvas.drawPath(path, tendrilPaint);
    }
  }

  void _drawBody(Canvas canvas, Size size) {
    // Amorphous dark shape
    final bodyPath = Path()
      ..moveTo(size.width * 0.48, size.height * 0.26)
      ..cubicTo(
        size.width * 0.70, size.height * 0.28,
        size.width * 0.74, size.height * 0.50,
        size.width * 0.70, size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.64, size.height * 0.86,
        size.width * 0.50, size.height * 0.90,
        size.width * 0.36, size.height * 0.84,
      )
      ..cubicTo(
        size.width * 0.22, size.height * 0.76,
        size.width * 0.20, size.height * 0.52,
        size.width * 0.26, size.height * 0.38,
      )
      ..cubicTo(
        size.width * 0.30, size.height * 0.24,
        size.width * 0.38, size.height * 0.22,
        size.width * 0.48, size.height * 0.26,
      )
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          colors: [const Color(0xFF6A1B9A), const Color(0xFF1A0030)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    // Purple outline glow
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFFAB47BC).withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _drawEyes(Canvas canvas, Size size) {
    // Eerie glowing purple eyes
    for (final cx in [size.width * 0.38, size.width * 0.58]) {
      final center = Offset(cx, size.height * 0.44);
      canvas.drawCircle(
        center,
        size.width * 0.072,
        Paint()
          ..color = const Color(0xFFE040FB).withAlpha(160)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(center, size.width * 0.055, Paint()..color = const Color(0xFFCE93D8));
      canvas.drawCircle(center, size.width * 0.032, Paint()..color = Colors.black);
      canvas.drawCircle(
        Offset(cx + size.width * 0.020, size.height * 0.424),
        size.width * 0.014,
        Paint()..color = const Color(0xFFE040FB),
      );
    }
  }

  void _drawVoidSymbols(Canvas canvas, Size size) {
    final symbolPaint = Paint()
      ..color = const Color(0xFFCE93D8).withAlpha(130)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    // Draw small rune-like circles
    final runes = [
      Offset(size.width * 0.30, size.height * 0.68),
      Offset(size.width * 0.60, size.height * 0.70),
      Offset(size.width * 0.46, size.height * 0.82),
    ];
    for (final r in runes) {
      canvas.drawCircle(r, size.width * 0.028, symbolPaint);
      canvas.drawLine(
        Offset(r.dx - size.width * 0.020, r.dy),
        Offset(r.dx + size.width * 0.020, r.dy),
        symbolPaint,
      );
      canvas.drawLine(
        Offset(r.dx, r.dy - size.width * 0.020),
        Offset(r.dx, r.dy + size.width * 0.020),
        symbolPaint,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOD MONSTER - Golden supreme form
// ─────────────────────────────────────────────────────────────────────────────

class GodMonsterPainter extends BaseMonsterPainter {
  const GodMonsterPainter(super.primaryColor, {super.animValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // God emanates divine energy — gentle omnidirectional pulse + halo rotation
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(animValue * 0.03); // slow divine rotation
    canvas.translate(-size.width / 2, -size.height / 2 + math.sin(animValue * 0.5) * 3.0);
    _drawRainbowAura(canvas, size);
    _drawRadianceRays(canvas, size);
    _drawWings(canvas, size);
    _drawBody(canvas, size);
    _drawHead(canvas, size);
    _drawHalo(canvas, size);
    _drawEyes(canvas, size);
    _drawGoldenMouth(canvas, size);
    _drawGemStones(canvas, size);
    canvas.restore();
  }

  void _drawRainbowAura(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rainbow = [
      const Color(0xFFFFD700).withAlpha(100),
      const Color(0xFFFF69B4).withAlpha(80),
      const Color(0xFF00BFFF).withAlpha(80),
      Colors.transparent,
    ];
    canvas.drawCircle(
      center,
      size.width * 0.48,
      Paint()
        ..shader = RadialGradient(colors: rainbow)
            .createShader(Rect.fromCircle(center: center, radius: size.width * 0.48))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
  }

  void _drawRadianceRays(Canvas canvas, Size size) {
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha(90)
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final center = Offset(size.width * 0.50, size.height * 0.46);
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      canvas.drawLine(
        Offset(center.dx + size.width * 0.28 * math.cos(angle),
            center.dy + size.height * 0.28 * math.sin(angle)),
        Offset(center.dx + size.width * 0.46 * math.cos(angle),
            center.dy + size.height * 0.46 * math.sin(angle)),
        rayPaint,
      );
    }
  }

  void _drawWings(Canvas canvas, Size size) {
    final wingPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFFFD700), const Color(0xFFFFF9C4), const Color(0xFFFFB300)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final leftWing = Path()
      ..moveTo(size.width * 0.38, size.height * 0.46)
      ..cubicTo(
        size.width * 0.16, size.height * 0.26,
        size.width * 0.02, size.height * 0.38,
        size.width * 0.04, size.height * 0.60,
      )
      ..cubicTo(
        size.width * 0.08, size.height * 0.74,
        size.width * 0.24, size.height * 0.72,
        size.width * 0.36, size.height * 0.62,
      )
      ..close();
    canvas.drawPath(leftWing, wingPaint);

    final rightWing = Path()
      ..moveTo(size.width * 0.62, size.height * 0.46)
      ..cubicTo(
        size.width * 0.84, size.height * 0.26,
        size.width * 0.98, size.height * 0.38,
        size.width * 0.96, size.height * 0.60,
      )
      ..cubicTo(
        size.width * 0.92, size.height * 0.74,
        size.width * 0.76, size.height * 0.72,
        size.width * 0.64, size.height * 0.62,
      )
      ..close();
    canvas.drawPath(rightWing, wingPaint);
  }

  void _drawBody(Canvas canvas, Size size) {
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.70),
      width: size.width * 0.46,
      height: size.height * 0.44,
    );
    drawGradientOval(canvas, bodyRect,
        [const Color(0xFFFFEE58), const Color(0xFFFFA000)]);
    canvas.drawOval(
      bodyRect.inflate(3),
      Paint()
        ..color = const Color(0xFFFFD700).withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _drawHead(Canvas canvas, Size size) {
    drawGradientCircle(
      canvas,
      Offset(size.width * 0.50, size.height * 0.42),
      size.width * 0.26,
      [const Color(0xFFFFF176), const Color(0xFFFF8F00)],
    );
  }

  void _drawHalo(Canvas canvas, Size size) {
    final haloPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.50, size.height * 0.14),
        width: size.width * 0.38,
        height: size.height * 0.10,
      ),
      haloPaint,
    );
  }

  void _drawEyes(Canvas canvas, Size size) {
    // Gold glowing divine eyes
    for (final cx in [size.width * 0.38, size.width * 0.62]) {
      final center = Offset(cx, size.height * 0.40);
      canvas.drawCircle(
        center,
        size.width * 0.078,
        Paint()
          ..color = const Color(0xFFFFD700).withAlpha(140)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(center, size.width * 0.078, Paint()..color = Colors.white);
      canvas.drawCircle(
        center,
        size.width * 0.056,
        Paint()..color = const Color(0xFFFF8F00),
      );
      canvas.drawCircle(center, size.width * 0.030, Paint()..color = Colors.black);
      canvas.drawCircle(
        Offset(cx + size.width * 0.024, size.height * 0.384),
        size.width * 0.018,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(cx - size.width * 0.016, size.height * 0.378),
        size.width * 0.010,
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }
  }

  void _drawGoldenMouth(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.36, size.height * 0.52)
        ..quadraticBezierTo(
            size.width * 0.50, size.height * 0.60, size.width * 0.64, size.height * 0.52),
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawGemStones(Canvas canvas, Size size) {
    final gems = [
      (Offset(size.width * 0.50, size.height * 0.72), const Color(0xFFE53935)),
      (Offset(size.width * 0.38, size.height * 0.78), const Color(0xFF1E88E5)),
      (Offset(size.width * 0.62, size.height * 0.78), const Color(0xFF43A047)),
      (Offset(size.width * 0.44, size.height * 0.84), const Color(0xFFAB47BC)),
      (Offset(size.width * 0.56, size.height * 0.84), const Color(0xFF00ACC1)),
    ];
    for (final (pos, color) in gems) {
      canvas.drawCircle(
        pos,
        size.width * 0.022,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(pos.dx - size.width * 0.008, pos.dy - size.width * 0.008),
        size.width * 0.008,
        Paint()..color = Colors.white.withAlpha(180),
      );
    }
  }
}

