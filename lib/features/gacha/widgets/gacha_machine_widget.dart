import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Rarity helpers
// ---------------------------------------------------------------------------
Color rarityGlowColor(String rarity) {
  switch (rarity) {
    case 'SSR':
      return const Color(0xFFFFD700);
    case 'SR':
      return const Color(0xFFE040FB);
    case 'R':
      return const Color(0xFF42A5F5);
    default:
      return const Color(0xFF9E9E9E);
  }
}

Color _rarityBodyColor(String rarity) {
  switch (rarity) {
    case 'SSR':
      return const Color(0xFFFBBF24);
    case 'SR':
      return const Color(0xFFE040FB);
    case 'R':
      return const Color(0xFF42A5F5);
    default:
      return const Color(0xFF9E9E9E);
  }
}

const _rarities = ['SSR', 'SR', 'R', 'N'];

// ---------------------------------------------------------------------------
// GachaMachineWidget
// ---------------------------------------------------------------------------
class GachaMachineWidget extends StatefulWidget {
  final bool isPulling;
  final VoidCallback? onAnimationComplete;

  const GachaMachineWidget({
    super.key,
    required this.isPulling,
    this.onAnimationComplete,
  });

  @override
  State<GachaMachineWidget> createState() => _GachaMachineState();
}

class _GachaMachineState extends State<GachaMachineWidget>
    with TickerProviderStateMixin {
  // 1. Idle loop – capsule float, glow pulse, gauge oscillation
  late AnimationController _idleCtrl;
  // 2. Power-up – energy gauge fills, machine brightens
  late AnimationController _powerUpCtrl;
  // 3. Spin – capsules spin chaotically, sphere blazes
  late AnimationController _spinCtrl;
  // 4. Flash – full bright overlay
  late AnimationController _flashCtrl;
  // 5. Capsule exit – capsule shoots out of chute
  late AnimationController _capsuleExitCtrl;

  late Animation<double> _idleAnim;
  late Animation<double> _powerUpAnim;
  late Animation<double> _spinAnim;
  late Animation<double> _flashAnim;
  late Animation<double> _capsuleSlideAnim;
  late Animation<double> _capsuleFadeAnim;

  bool _showCapsule = false;
  String _capsuleRarity = 'R';
  bool _isPoweringUp = false;
  bool _isSpinning = false;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();

    // --- 1. Idle loop (3s, repeating) ---
    _idleCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _idleAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_idleCtrl);

    // --- 2. Power-up (0.8s) ---
    _powerUpCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _powerUpAnim = CurvedAnimation(
      parent: _powerUpCtrl,
      curve: Curves.easeInOut,
    );

    // --- 3. Spin (1.2s) ---
    _spinCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _spinAnim = Tween<double>(begin: 0, end: 6 * math.pi).animate(
      CurvedAnimation(parent: _spinCtrl, curve: Curves.easeInOut),
    );

    // --- 4. Flash (0.3s) ---
    _flashCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut),
    );

    // --- 5. Capsule exit (1.0s) ---
    _capsuleExitCtrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _capsuleSlideAnim = Tween<double>(begin: 0, end: 90).animate(
      CurvedAnimation(parent: _capsuleExitCtrl, curve: Curves.easeOut),
    );
    _capsuleFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _capsuleExitCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void didUpdateWidget(GachaMachineWidget old) {
    super.didUpdateWidget(old);
    if (widget.isPulling && !old.isPulling) {
      _triggerPull();
    }
  }

  Future<void> _triggerPull() async {
    // Pick rarity
    final weights = [2, 8, 30, 60];
    final roll = _rng.nextInt(100);
    int cumulative = 0;
    int rarityIndex = 3;
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (roll < cumulative) {
        rarityIndex = i;
        break;
      }
    }
    if (mounted) {
      setState(() {
        _capsuleRarity = _rarities[rarityIndex];
        _showCapsule = false;
        _isPoweringUp = true;
        _isSpinning = false;
      });
    }

    // Phase 1: power-up (0.8s)
    _powerUpCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 800));

    // Phase 2: spin (1.2s)
    if (mounted) setState(() => _isSpinning = true);
    _spinCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1200));

    // Phase 3: flash (0.3s)
    _flashCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 300));

    // Phase 4: capsule exits (1.0s), notify complete quickly
    if (mounted) {
      setState(() {
        _showCapsule = true;
        _isPoweringUp = false;
        _isSpinning = false;
      });
    }
    _capsuleExitCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 400));

    widget.onAnimationComplete?.call();

    await Future.delayed(const Duration(milliseconds: 1400));

    // Reset
    if (mounted) {
      setState(() => _showCapsule = false);
      _capsuleExitCtrl.reset();
      _flashCtrl.reset();
      _powerUpCtrl.reset();
    }
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    _powerUpCtrl.dispose();
    _spinCtrl.dispose();
    _flashCtrl.dispose();
    _capsuleExitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 420,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main machine body
          AnimatedBuilder(
            animation: Listenable.merge([
              _idleAnim,
              _spinAnim,
              _powerUpAnim,
            ]),
            builder: (_, __) => CustomPaint(
              size: const Size(280, 420),
              painter: GachaMachinePainter(
                idlePhase: _idleAnim.value,
                spinPhase: _spinAnim.value,
                powerUpLevel: _powerUpAnim.value,
                isPoweringUp: _isPoweringUp,
                isSpinning: _isSpinning,
              ),
            ),
          ),

          // Flash overlay
          AnimatedBuilder(
            animation: _flashAnim,
            builder: (_, __) {
              final t = _flashAnim.value;
              // Bell curve: bright in middle, fade at ends
              final alpha = (t * (1 - t) * 4).clamp(0.0, 1.0);
              return Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: alpha * 0.65),
                    ),
                  ),
                ),
              );
            },
          ),

          // Capsule exit animation
          if (_showCapsule)
            AnimatedBuilder(
              animation: _capsuleExitCtrl,
              builder: (_, __) {
                final glowColor = rarityGlowColor(_capsuleRarity);
                return Positioned(
                  // Chute center is at ~x:140, y:350 on 280-wide canvas
                  left: 105,
                  top: 346 + _capsuleSlideAnim.value,
                  child: Opacity(
                    opacity: _capsuleFadeAnim.value,
                    child: _ExitCapsule(
                      rarity: _capsuleRarity,
                      glowColor: glowColor,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exit Capsule Widget
// ---------------------------------------------------------------------------
class _ExitCapsule extends StatelessWidget {
  final String rarity;
  final Color glowColor;

  const _ExitCapsule({required this.rarity, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    final bodyColor = _rarityBodyColor(rarity);
    return Container(
      width: 70,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            bodyColor.withValues(alpha: 0.95),
            bodyColor.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.9),
            blurRadius: 22,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 12,
          ),
        ],
        border: Border.all(
          color: glowColor.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          rarity,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GachaMachinePainter  –  280 × 420 canvas
// ---------------------------------------------------------------------------
class GachaMachinePainter extends CustomPainter {
  final double idlePhase;    // 0 → 2π (repeating idle)
  final double spinPhase;    // 0 → 6π during spin sequence
  final double powerUpLevel; // 0 → 1 during power-up
  final bool isPoweringUp;
  final bool isSpinning;

  const GachaMachinePainter({
    required this.idlePhase,
    required this.spinPhase,
    required this.powerUpLevel,
    required this.isPoweringUp,
    required this.isSpinning,
  });

  // Derived glow intensity for reactive drawing
  double get _glowIntensity {
    if (isSpinning) return 1.0;
    if (isPoweringUp) return powerUpLevel;
    return 0.18 + math.sin(idlePhase) * 0.08;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawBase(canvas, size);
    _drawMachineBody(canvas, size);
    _drawExitChute(canvas, size);
    _drawSphere(canvas, size);
    _drawCapsulesInSphere(canvas, size);
    _drawSphereOverlay(canvas, size);
    _drawCrankButton(canvas, size);
    _drawAmbientGlow(canvas, size);
  }

  // =========================================================================
  // 1. BASE PLATFORM  (y: 330–420)
  // =========================================================================
  void _drawBase(Canvas canvas, Size size) {
    // Shadow beneath base
    canvas.drawOval(
      const Rect.fromLTWH(30, 406, 222, 14),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Wide trapezoidal base body
    final basePath = Path()
      ..moveTo(22, 335)
      ..lineTo(258, 335)
      ..lineTo(270, 410)
      ..lineTo(10, 410)
      ..close();

    canvas.drawPath(
      basePath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(10, 335, 260, 75)),
    );

    // Base top-surface highlight band
    final topBand = Path()
      ..moveTo(22, 335)
      ..lineTo(258, 335)
      ..lineTo(262, 347)
      ..lineTo(18, 347)
      ..close();
    canvas.drawPath(
      topBand,
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.25),
    );

    // Base border
    canvas.drawPath(
      basePath,
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // STARTING LINE track markings
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(58, 362), const Offset(108, 362), dashPaint);
    canvas.drawLine(const Offset(172, 362), const Offset(222, 362), dashPaint);

    // "ランニングモンスター" label
    _drawText(
      canvas,
      'ランニングモンスター',
      const Offset(140, 380),
      const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
      TextAlign.center,
    );

    // Left foot
    _drawFoot(canvas, const Rect.fromLTWH(20, 400, 44, 14));
    // Right foot
    _drawFoot(canvas, const Rect.fromLTWH(216, 400, 44, 14));
  }

  void _drawFoot(Canvas canvas, Rect rect) {
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF0D0D1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  // =========================================================================
  // 2. EXIT CHUTE  (y: 318–345)
  // =========================================================================
  void _drawExitChute(Canvas canvas, Size size) {
    const chuteRect = Rect.fromLTWH(95, 322, 90, 26);

    // Outer metal surround
    canvas.drawRRect(
      RRect.fromRectAndRadius(chuteRect, const Radius.circular(8)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2D2D4E), Color(0xFF1A1A2E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(chuteRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chuteRect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner oval opening – glowing amber
    final innerOval = Rect.fromLTWH(104, 327, 72, 16);
    canvas.drawOval(
      innerOval,
      Paint()
        ..color = const Color(0xFF0D0D1A),
    );
    // Amber glow inside chute
    canvas.drawOval(
      innerOval,
      Paint()
        ..color = const Color(0xFFFBBF24).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawOval(
      innerOval,
      Paint()
        ..color = const Color(0xFFFBBF24).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // =========================================================================
  // 3. MACHINE BODY  (y: 180–335)
  // =========================================================================
  void _drawMachineBody(Canvas canvas, Size size) {
    // Trapezoid wider at bottom
    final bodyPath = Path()
      ..moveTo(60, 183)
      ..lineTo(220, 183)
      ..lineTo(246, 330)
      ..lineTo(34, 330)
      ..close();

    // Shadow
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Main body fill
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0D0D1A)],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(const Rect.fromLTWH(34, 183, 212, 147)),
    );

    // Hexagonal panel grid lines
    _drawHexGrid(canvas, const Rect.fromLTWH(34, 183, 212, 147));

    // Edge glow – purple/violet
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(
            alpha: 0.4 + _glowIntensity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFFA855F7).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ---- LEFT PANEL: Energy gauge ----
    _drawEnergyGauge(canvas);

    // ---- RIGHT PANEL: Pull count screen ----
    _drawPullCountScreen(canvas);

    // ---- CENTER BRANDING ----
    // "RUNMON" large amber text
    _drawText(
      canvas,
      'RUNMON',
      const Offset(140, 237),
      TextStyle(
        color: const Color(0xFFFBBF24),
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
        shadows: [
          Shadow(
            color: const Color(0xFFFBBF24).withValues(
                alpha: 0.6 + _glowIntensity * 0.4),
            blurRadius: 16,
          ),
          const Shadow(color: Colors.black87, blurRadius: 4),
        ],
      ),
      TextAlign.center,
    );

    // "GACHA" subtitle
    _drawText(
      canvas,
      'G  A  C  H  A',
      const Offset(140, 262),
      const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 4,
      ),
      TextAlign.center,
    );

    // Running silhouette below text
    _drawRunningSilhouette(canvas, const Offset(140, 295), 22,
        const Color(0xFF7C3AED).withValues(alpha: 0.8 + _glowIntensity * 0.2));

    // Thin separator line above branding
    final sepPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.4)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(80, 215), const Offset(200, 215), sepPaint);
    canvas.drawLine(const Offset(75, 275), const Offset(205, 275), sepPaint);
  }

  void _drawHexGrid(Canvas canvas, Rect bounds) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const hexSize = 20.0;
    final rows = (bounds.height / hexSize).ceil() + 1;
    final cols = (bounds.width / hexSize).ceil() + 1;

    canvas.save();
    canvas.clipRect(bounds);

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cx = bounds.left + col * hexSize * 1.5;
        final cy = bounds.top + row * hexSize * 1.732 +
            (col.isOdd ? hexSize * 0.866 : 0);
        _drawHex(canvas, Offset(cx, cy), hexSize * 0.85, paint);
      }
    }
    canvas.restore();
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawEnergyGauge(Canvas canvas) {
    const panelRect = Rect.fromLTWH(42, 210, 28, 90);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(5)),
      Paint()..color = const Color(0xFF0A0A18),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(5)),
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Fill level
    final fillLevel = isPoweringUp
        ? powerUpLevel
        : (0.55 + math.sin(idlePhase) * 0.12).clamp(0.0, 1.0);
    final fillH = 82.0 * fillLevel;
    final fillTop = 214 + (82 - fillH);
    final fillRect = Rect.fromLTWH(44, fillTop, 24, fillH);

    if (fillH > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, const Radius.circular(3)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFF7C3AED),
              const Color(0xFFFBBF24).withValues(alpha: fillLevel),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ).createShader(fillRect),
      );
      // Glow on gauge
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFFA855F7).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Tick marks
    for (int i = 0; i < 5; i++) {
      final ty = 216.0 + i * 20.0;
      canvas.drawLine(
        Offset(44, ty),
        Offset(68, ty),
        Paint()
          ..color = const Color(0xFF7C3AED).withValues(alpha: 0.35)
          ..strokeWidth = 0.5,
      );
    }

    // "E" label
    _drawText(
      canvas,
      'E',
      const Offset(56, 206),
      const TextStyle(
        color: Color(0xFFA855F7),
        fontSize: 8,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
      TextAlign.center,
    );
  }

  void _drawPullCountScreen(Canvas canvas) {
    const screenRect = Rect.fromLTWH(210, 210, 36, 48);
    canvas.drawRRect(
      RRect.fromRectAndRadius(screenRect, const Radius.circular(5)),
      Paint()..color = const Color(0xFF050510),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(screenRect, const Radius.circular(5)),
      Paint()
        ..color = const Color(0xFF00FFFF).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Screen header
    _drawText(
      canvas,
      'PULL',
      const Offset(228, 222),
      const TextStyle(
        color: Color(0xFF00FFFF),
        fontSize: 7,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
      TextAlign.center,
    );

    // Count display
    _drawText(
      canvas,
      '10x',
      const Offset(228, 237),
      const TextStyle(
        color: Color(0xFFFBBF24),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
      TextAlign.center,
    );

    // Blinking dot indicator
    final dotAlpha = (math.sin(idlePhase * 2) * 0.5 + 0.5).clamp(0.0, 1.0);
    canvas.drawCircle(
      const Offset(228, 252),
      3,
      Paint()
        ..color = const Color(0xFF00FF88).withValues(alpha: dotAlpha),
    );
  }

  // =========================================================================
  // 4. CRYSTAL POWER SPHERE  (center ~(140, 95), radius 120)
  // =========================================================================
  void _drawSphere(Canvas canvas, Size size) {
    const center = Offset(140, 93);
    const radius = 110.0;

    // Outer ambient glow – intensity reacts to state
    canvas.drawCircle(
      center,
      radius + 18,
      Paint()
        ..color = const Color(0xFF7C3AED)
            .withValues(alpha: 0.12 + _glowIntensity * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Main sphere fill – deep purple radial
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0),
          radius: 1.0,
          colors: [
            Color.lerp(const Color(0xFF3D1F6E), const Color(0xFF1A0A3D),
                _glowIntensity * 0.5)!,
            const Color(0xFF1A0A3D),
            const Color(0xFF0D0520),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Sphere rim glow – bright violet
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFA855F7)
            .withValues(alpha: 0.5 + _glowIntensity * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Crisp rim on top
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFD8B4FE).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Mount collar where sphere meets body
    const mountRect = Rect.fromLTWH(75, 182, 130, 22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(mountRect, const Radius.circular(7)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2D1B69), Color(0xFF1A0A3D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(mountRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(mountRect, const Radius.circular(7)),
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // =========================================================================
  // 5. CAPSULES INSIDE SPHERE
  // =========================================================================
  void _drawCapsulesInSphere(Canvas canvas, Size size) {
    const globeCenter = Offset(140, 93);
    const globeRadius = 106.0;

    // Capsule data: [relX, relY, phaseOffset, topColor, bottomColor]
    final capsuleData = [
      [-42.0, -35.0, 0.0, const Color(0xFFFFD700), const Color(0xFFB8860B)],  // SSR gold
      [35.0, -48.0, 0.8, const Color(0xFFE040FB), const Color(0xFF880E4F)],   // SR pink
      [60.0, 8.0, 1.6, const Color(0xFF42A5F5), const Color(0xFF0D47A1)],     // R blue
      [12.0, 55.0, 2.4, const Color(0xFF9E9E9E), const Color(0xFF424242)],    // N gray
      [-60.0, 15.0, 3.2, const Color(0xFFFFD700), const Color(0xFFB8860B)],   // SSR gold
      [-18.0, -62.0, 4.0, const Color(0xFFE040FB), const Color(0xFF880E4F)],  // SR pink
      [48.0, -22.0, 4.8, const Color(0xFF42A5F5), const Color(0xFF0D47A1)],   // R blue
      [-40.0, 48.0, 5.6, const Color(0xFF9E9E9E), const Color(0xFF424242)],   // N gray
    ];

    canvas.save();
    canvas.clipPath(
      Path()
        ..addOval(
            Rect.fromCircle(center: globeCenter, radius: globeRadius)),
    );

    for (int i = 0; i < capsuleData.length; i++) {
      final d = capsuleData[i];
      final relX = d[0] as double;
      final relY = d[1] as double;
      final phaseOff = d[2] as double;
      final topColor = d[3] as Color;
      final bottomColor = d[4] as Color;

      double floatX, floatY, rot;

      if (isSpinning) {
        // Spin chaotically
        final spinOffset = spinPhase + phaseOff;
        final orbitR = (math.sqrt(relX * relX + relY * relY)).clamp(20.0, 80.0);
        floatX = math.cos(spinOffset + phaseOff) * orbitR * 0.4;
        floatY = math.sin(spinOffset * 0.7 + phaseOff) * orbitR * 0.4;
        rot = spinPhase * 0.5 + phaseOff;
      } else {
        // Gentle idle float
        final phase = idlePhase + phaseOff;
        floatY = math.sin(phase) * 5.0;
        floatX = math.cos(phase * 0.6) * 3.0;
        rot = math.sin(phase * 0.4) * 0.2 + phaseOff * 0.05;
      }

      final cx = globeCenter.dx + relX + floatX;
      final cy = globeCenter.dy + relY + floatY;

      _drawCapsule(canvas, Offset(cx, cy), rot, topColor, bottomColor);
    }

    // Inner RUNMON text (always visible in sphere center)
    _drawText(
      canvas,
      'RUNMON',
      const Offset(140, 85),
      TextStyle(
        color: const Color(0xFFFBBF24),
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        shadows: [
          Shadow(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.9),
            blurRadius: 12,
          ),
          const Shadow(color: Colors.black, blurRadius: 3),
        ],
      ),
      TextAlign.center,
    );

    // Running figure inside sphere (below RUNMON text)
    _drawRunningSilhouette(
      canvas,
      const Offset(140, 112),
      14,
      const Color(0xFFFBBF24).withValues(alpha: 0.85),
    );

    canvas.restore();
  }

  void _drawCapsule(
    Canvas canvas,
    Offset center,
    double angle,
    Color topColor,
    Color bottomColor,
  ) {
    const w = 26.0;
    const h = 15.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(1.5, 2.5), width: w, height: h * 0.5),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Paint()
        ..shader = LinearGradient(
          colors: [topColor, bottomColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(
            Rect.fromCenter(center: Offset.zero, width: w, height: h)),
    );

    // Seam
    canvas.drawLine(
      Offset(-w / 2, 0),
      Offset(w / 2, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );

    // Specular
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(-5, -3.5), width: w * 0.38, height: h * 0.32),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.restore();
  }

  // Draws a simple running human silhouette using paths
  void _drawRunningSilhouette(
      Canvas canvas, Offset center, double scale, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = scale * 0.12
      ..strokeCap = StrokeCap.round;

    // Head
    canvas.drawCircle(
      Offset(center.dx + scale * 0.05, center.dy - scale * 0.9),
      scale * 0.2,
      paint,
    );

    // Body & limbs as a path
    final body = Path();
    // Torso
    body.moveTo(center.dx, center.dy - scale * 0.65);
    body.lineTo(center.dx - scale * 0.08, center.dy - scale * 0.1);
    // Right arm forward
    body.moveTo(center.dx, center.dy - scale * 0.55);
    body.lineTo(center.dx + scale * 0.35, center.dy - scale * 0.2);
    // Left arm back
    body.moveTo(center.dx, center.dy - scale * 0.55);
    body.lineTo(center.dx - scale * 0.3, center.dy - scale * 0.45);
    // Right leg back
    body.moveTo(center.dx - scale * 0.08, center.dy - scale * 0.1);
    body.lineTo(center.dx + scale * 0.25, center.dy + scale * 0.35);
    body.lineTo(center.dx + scale * 0.15, center.dy + scale * 0.75);
    // Left leg forward
    body.moveTo(center.dx - scale * 0.08, center.dy - scale * 0.1);
    body.lineTo(center.dx - scale * 0.35, center.dy + scale * 0.3);
    body.lineTo(center.dx - scale * 0.1, center.dy + scale * 0.75);

    canvas.drawPath(body, strokePaint);
  }

  // =========================================================================
  // 6. SPHERE OVERLAY (highlights painted after capsules)
  // =========================================================================
  void _drawSphereOverlay(Canvas canvas, Size size) {
    const center = Offset(140, 93);
    const radius = 110.0;

    // Top-left shine patch
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.52, -0.52),
          radius: 0.52,
          colors: [
            Colors.white.withValues(alpha: 0.38),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Small glint arc upper-left
    canvas.drawOval(
      const Rect.fromLTWH(60, 22, 52, 26),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Bottom-right reflection arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      math.pi * 0.28,
      math.pi * 0.38,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Spin energy ring when spinning
    if (isSpinning) {
      final ringAlpha = (math.sin(spinPhase * 2) * 0.5 + 0.5) * 0.7;
      canvas.drawCircle(
        center,
        radius - 2,
        Paint()
          ..color = const Color(0xFFFBBF24).withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  // =========================================================================
  // 7. CRANK / BUTTON (right side, y ~center of body)
  // =========================================================================
  void _drawCrankButton(Canvas canvas, Size size) {
    // Button is on right side at ~y:256
    const buttonCenter = Offset(258, 256);
    final buttonR = isPoweringUp || isSpinning ? 24.0 : 26.0;

    // Bracket
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(240, 240, 22, 32),
        const Radius.circular(5),
      ),
      Paint()
        ..color = const Color(0xFF1A1A2E)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(240, 240, 22, 32),
        const Radius.circular(5),
      ),
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Button shadow
    canvas.drawCircle(
      buttonCenter.translate(2, 2),
      buttonR,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Button outer glow
    canvas.drawCircle(
      buttonCenter,
      buttonR + 4,
      Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Button fill – red to orange radial
    canvas.drawCircle(
      buttonCenter,
      buttonR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: const [Color(0xFFFF6B6B), Color(0xFFEF4444), Color(0xFFC0392B)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(
            Rect.fromCircle(center: buttonCenter, radius: buttonR)),
    );

    // Button rim
    canvas.drawCircle(
      buttonCenter,
      buttonR,
      Paint()
        ..color = const Color(0xFFFF8A80).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Play arrow icon on button
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final arrowPath = Path()
      ..moveTo(buttonCenter.dx - 6, buttonCenter.dy - 8)
      ..lineTo(buttonCenter.dx + 9, buttonCenter.dy)
      ..lineTo(buttonCenter.dx - 6, buttonCenter.dy + 8)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    // Specular highlight on button
    canvas.drawOval(
      Rect.fromCenter(
          center: buttonCenter.translate(-6, -8), width: 14, height: 8),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  // =========================================================================
  // 8. AMBIENT GLOW (floor, sphere-to-body junction)
  // =========================================================================
  void _drawAmbientGlow(Canvas canvas, Size size) {
    // Sphere to body contact glow
    canvas.drawOval(
      const Rect.fromLTWH(75, 185, 130, 14),
      Paint()
        ..color = const Color(0xFF7C3AED)
            .withValues(alpha: 0.3 + _glowIntensity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Machine floor shadow
    canvas.drawOval(
      const Rect.fromLTWH(40, 407, 202, 12),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  // =========================================================================
  // Helpers
  // =========================================================================
  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style,
    TextAlign align,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(position.dx - tp.width / 2, position.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(GachaMachinePainter old) =>
      old.idlePhase != idlePhase ||
      old.spinPhase != spinPhase ||
      old.powerUpLevel != powerUpLevel ||
      old.isPoweringUp != isPoweringUp ||
      old.isSpinning != isSpinning;
}
