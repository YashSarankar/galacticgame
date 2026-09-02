import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Interactive Neon Laser Income Line / Checkpoint on the circuit.
class IncomeLineComponent extends PositionComponent {
  final double trackWidth;
  double _pulsePhase = 0.0;
  bool isTriggered = false;
  double _flashTimer = 0.0;

  IncomeLineComponent({
    required Vector2 position,
    this.trackWidth = 50.0,
    double angle = 0.0,
  }) : super(position: position, angle: angle, anchor: Anchor.center);

  /// Triggers a localized radiant light flash on ship crossing
  void triggerFlash() {
    isTriggered = true;
    _flashTimer = 0.35;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulsePhase += dt * 5.0;

    if (_flashTimer > 0) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) {
        isTriggered = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final double pulse = (sin(_pulsePhase) + 1.0) / 2.0;
    final double halfWidth = trackWidth / 2.0;

    // Glowing laser beam colors
    final Color beamColor = isTriggered
        ? const Color(0xFFFFFFFF)
        : Color.lerp(const Color(0xFF00F0FF), const Color(0xFF00FF88), pulse)!;

    // Outer Aura Glow
    final glowPaint = Paint()
      ..color = (isTriggered ? const Color(0xFF00F0FF) : beamColor)
          .withAlpha((isTriggered ? 0.9 * 255 : (0.4 + pulse * 0.3) * 255).round())
      ..strokeWidth = isTriggered ? 12.0 : 7.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);

    canvas.drawLine(
      Offset(-halfWidth, 0),
      Offset(halfWidth, 0),
      glowPaint,
    );

    // Inner Core Laser Line
    final corePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = isTriggered ? 4.0 : 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(-halfWidth, 0),
      Offset(halfWidth, 0),
      corePaint,
    );

    // Emitter pylons on both sides
    final pylonPaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(-halfWidth, 0), 4.0, pylonPaint);
    canvas.drawCircle(Offset(halfWidth, 0), 4.0, pylonPaint);

    if (isTriggered) {
      // Radiant diamond flash in center
      final flashPaint = Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 10.0);
      canvas.drawCircle(Offset.zero, 8.0, flashPaint);
    }
  }
}
