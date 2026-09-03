import 'dart:math';
import 'package:flutter/material.dart';

/// Controller to trigger Flying Coins, Floating Arcade Texts, and Shockwave VFX
class IdleVfxController extends ChangeNotifier {
  final List<_FlyingCoin> _coins = [];
  final List<_FloatingText> _floatingTexts = [];
  final List<_Shockwave> _shockwaves = [];

  bool get hasActiveEffects =>
      _coins.isNotEmpty || _floatingTexts.isNotEmpty || _shockwaves.isNotEmpty;

  /// Spawns a fountain of coins/gems that burst outward and fly in a parabolic curve to targetKey
  void spawnCoins({
    required Offset origin,
    required GlobalKey targetKey,
    int count = 5,
    Color color = const Color(0xFFFFD700),
    bool isGem = false,
    VoidCallback? onTargetHit,
  }) {
    // Resolve target position in screen coordinates
    Offset targetPos = const Offset(60, 45); // Safe fallback
    try {
      final renderBox =
          targetKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        targetPos = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
      }
    } catch (_) {}

    final random = Random();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < count; i++) {
      final double burstAngle = (random.nextDouble() * 2 * pi);
      final double burstDist = 20.0 + random.nextDouble() * 45.0;
      final Offset burstOffset = Offset(
        cos(burstAngle) * burstDist,
        sin(burstAngle) * burstDist - 15.0, // slight upward bias
      );

      final Offset p0 = origin;
      final Offset pInitial = origin + burstOffset;

      // Arc control point curving high into the screen
      final double midX = (pInitial.dx + targetPos.dx) / 2 +
          (random.nextDouble() * 60.0 - 30.0);
      final double midY = min(pInitial.dy, targetPos.dy) -
          (60.0 + random.nextDouble() * 60.0);
      final Offset pControl = Offset(midX, midY);

      _coins.add(_FlyingCoin(
        id: '${now}_${i}_$random',
        startPos: p0,
        burstPos: pInitial,
        controlPos: pControl,
        targetPos: targetPos,
        startTimeMs: now + (i * 40), // Staggered release
        durationMs: 550 + random.nextInt(120),
        color: color,
        isGem: isGem,
        onArrived: i == 0 ? onTargetHit : null, // Trigger hit on first/lead coin
      ));
    }
    notifyListeners();
  }

  /// Spawns floating arcade combo text rising and fading
  void spawnFloatingText({
    required Offset origin,
    required String text,
    Color color = const Color(0xFFFFD700),
    double fontSize = 13.0,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _floatingTexts.add(_FloatingText(
      id: '${now}_${Random().nextInt(9999)}',
      origin: origin,
      text: text,
      color: color,
      fontSize: fontSize,
      startTimeMs: now,
      durationMs: 850,
    ));
    notifyListeners();
  }

  /// Spawns an expanding radial neon shockwave ring
  void spawnShockwave({
    required Offset origin,
    Color color = const Color(0xFF00F0FF),
    double maxRadius = 45.0,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _shockwaves.add(_Shockwave(
      id: '${now}_${Random().nextInt(9999)}',
      origin: origin,
      color: color,
      maxRadius: maxRadius,
      startTimeMs: now,
      durationMs: 400,
    ));
    notifyListeners();
  }

  /// Updates state and cleans up expired particles
  void update(int nowMs) {
    bool changed = false;

    // Coins
    _coins.removeWhere((c) {
      if (nowMs >= c.startTimeMs + c.durationMs) {
        c.onArrived?.call();
        changed = true;
        return true;
      }
      return false;
    });

    // Floating text
    _floatingTexts.removeWhere((t) {
      if (nowMs >= t.startTimeMs + t.durationMs) {
        changed = true;
        return true;
      }
      return false;
    });

    // Shockwaves
    _shockwaves.removeWhere((s) {
      if (nowMs >= s.startTimeMs + s.durationMs) {
        changed = true;
        return true;
      }
      return false;
    });

    if (changed || hasActiveEffects) {
      notifyListeners();
    }
  }
}

class _FlyingCoin {
  final String id;
  final Offset startPos;
  final Offset burstPos;
  final Offset controlPos;
  final Offset targetPos;
  final int startTimeMs;
  final int durationMs;
  final Color color;
  final bool isGem;
  final VoidCallback? onArrived;

  _FlyingCoin({
    required this.id,
    required this.startPos,
    required this.burstPos,
    required this.controlPos,
    required this.targetPos,
    required this.startTimeMs,
    required this.durationMs,
    required this.color,
    required this.isGem,
    this.onArrived,
  });

  /// Evaluates current position using a 2-phase cubic/quadratic bezier curve
  Offset getPosition(int nowMs) {
    if (nowMs < startTimeMs) return startPos;
    final double t =
        ((nowMs - startTimeMs) / durationMs).clamp(0.0, 1.0);

    // Initial 20% burst outward
    if (t < 0.20) {
      final double burstT = Curves.easeOutQuad.transform(t / 0.20);
      return Offset.lerp(startPos, burstPos, burstT)!;
    }

    // Remaining 80% smooth homing curve into target
    final double curveT =
        Curves.easeInOutCubic.transform((t - 0.20) / 0.80);
    final double oneMinusT = 1.0 - curveT;

    final double x = (oneMinusT * oneMinusT * burstPos.dx) +
        (2 * oneMinusT * curveT * controlPos.dx) +
        (curveT * curveT * targetPos.dx);
    final double y = (oneMinusT * oneMinusT * burstPos.dy) +
        (2 * oneMinusT * curveT * controlPos.dy) +
        (curveT * curveT * targetPos.dy);

    return Offset(x, y);
  }

  double getScale(int nowMs) {
    if (nowMs < startTimeMs) return 0.0;
    final double t =
        ((nowMs - startTimeMs) / durationMs).clamp(0.0, 1.0);
    if (t < 0.2) return t / 0.2 * 1.25;
    if (t > 0.8) return (1.0 - (t - 0.8) / 0.2) * 0.7 + 0.5;
    return 1.15;
  }
}

class _FloatingText {
  final String id;
  final Offset origin;
  final String text;
  final Color color;
  final double fontSize;
  final int startTimeMs;
  final int durationMs;

  _FloatingText({
    required this.id,
    required this.origin,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.startTimeMs,
    required this.durationMs,
  });

  Offset getPosition(int nowMs) {
    final double t =
        ((nowMs - startTimeMs) / durationMs).clamp(0.0, 1.0);
    final double easeY = Curves.easeOutCubic.transform(t);
    return Offset(origin.dx, origin.dy - (easeY * 50.0));
  }

  double getOpacity(int nowMs) {
    final double t =
        ((nowMs - startTimeMs) / durationMs).clamp(0.0, 1.0);
    if (t > 0.65) {
      return (1.0 - (t - 0.65) / 0.35).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  double getScale(int nowMs) {
    final double t =
        ((nowMs - startTimeMs) / durationMs).clamp(0.0, 1.0);
    if (t < 0.2) return 0.6 + (t / 0.2) * 0.6;
    return 1.0;
  }
}

class _Shockwave {
  final String id;
  final Offset origin;
  final Color color;
  final double maxRadius;
  final int startTimeMs;
  final int durationMs;

  _Shockwave({
    required this.id,
    required this.origin,
    required this.color,
    required this.maxRadius,
    required this.startTimeMs,
    required this.durationMs,
  });

  double getProgress(int nowMs) {
    return ((nowMs - startTimeMs) / durationMs).clamp(0.0, 1.0);
  }
}

/// Overlay widget that renders GPU-accelerated flying particles, floating text, and shockwaves
class IdleVfxOverlay extends StatefulWidget {
  final IdleVfxController controller;

  const IdleVfxOverlay({super.key, required this.controller});

  @override
  State<IdleVfxOverlay> createState() => _IdleVfxOverlayState();
}

class _IdleVfxOverlayState extends State<IdleVfxOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);

    widget.controller.addListener(_onControllerChanged);
    if (widget.controller.hasActiveEffects) {
      _ticker.repeat();
    }
  }

  void _onControllerChanged() {
    if (widget.controller.hasActiveEffects) {
      if (!_ticker.isAnimating) {
        _ticker.repeat();
      }
    }
  }

  void _onTick() {
    final now = DateTime.now().millisecondsSinceEpoch;
    widget.controller.update(now);
    if (!widget.controller.hasActiveEffects && _ticker.isAnimating) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (!widget.controller.hasActiveEffects) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _IdleVfxPainter(
              coins: widget.controller._coins,
              floatingTexts: widget.controller._floatingTexts,
              shockwaves: widget.controller._shockwaves,
              nowMs: DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        );
      },
    );
  }
}

class _IdleVfxPainter extends CustomPainter {
  final List<_FlyingCoin> coins;
  final List<_FloatingText> floatingTexts;
  final List<_Shockwave> shockwaves;
  final int nowMs;

  _IdleVfxPainter({
    required this.coins,
    required this.floatingTexts,
    required this.shockwaves,
    required this.nowMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Render Shockwaves
    for (final s in shockwaves) {
      final double progress = s.getProgress(nowMs);
      final double radius = progress * s.maxRadius;
      final double opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = s.color.withAlpha(((opacity * 0.8).clamp(0.0, 1.0) * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.8 * (1.0 - progress)).clamp(0.8, 2.8);

      canvas.drawCircle(s.origin, radius, paint);

      final glowPaint = Paint()
        ..color = s.color.withAlpha(((opacity * 0.3).clamp(0.0, 1.0) * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = (5.0 * (1.0 - progress)).clamp(1.0, 5.0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawCircle(s.origin, radius, glowPaint);
    }

    // 2. Render Flying Coins / Gems
    for (final coin in coins) {
      if (nowMs < coin.startTimeMs) continue;

      final Offset pos = coin.getPosition(nowMs);
      final double scale = coin.getScale(nowMs);
      final double radius = (coin.isGem ? 6.5 : 6.0) * scale;

      // Glow halo
      final glowPaint = Paint()
        ..color = coin.color.withAlpha((0.45 * 255).round())
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawCircle(pos, radius * 1.5, glowPaint);

      // Main Coin Body
      final bodyPaint = Paint()
        ..color = coin.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius, bodyPaint);

      // Inner Emboss Highlight
      final innerPaint = Paint()
        ..color = Colors.white.withAlpha((0.7 * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale;
      canvas.drawCircle(pos, radius * 0.65, innerPaint);

      // Star sparkle center
      final centerDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius * 0.28, centerDotPaint);
    }

    // 3. Render Floating Texts
    for (final t in floatingTexts) {
      final Offset pos = t.getPosition(nowMs);
      final double opacity = t.getOpacity(nowMs);
      final double scale = t.getScale(nowMs);

      final textSpan = TextSpan(
        text: t.text,
        style: TextStyle(
          color: t.color.withAlpha(((opacity).clamp(0.0, 1.0) * 255).round()),
          fontSize: t.fontSize * scale,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(((0.9 * opacity).clamp(0.0, 1.0) * 255).round()),
              offset: const Offset(1.5, 1.5),
              blurRadius: 3.0,
            ),
            Shadow(
              color: t.color.withAlpha(((0.6 * opacity).clamp(0.0, 1.0) * 255).round()),
              offset: Offset.zero,
              blurRadius: 6.0,
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset drawOffset = Offset(
        pos.dx - (textPainter.width / 2),
        pos.dy - (textPainter.height / 2),
      );

      textPainter.paint(canvas, drawOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _IdleVfxPainter oldDelegate) => true;
}
