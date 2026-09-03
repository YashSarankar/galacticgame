import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Neon Acceleration Hyper-Pad placed on track apexes to propel ships forward.
class BoostPadComponent extends PositionComponent {
  final double trackWidth;
  double _animPhase = 0.0;
  bool isTriggered = false;
  double _flashTimer = 0.0;

  BoostPadComponent({
    required Vector2 position,
    this.trackWidth = 44.0,
    double angle = 0.0,
  }) : super(position: position, angle: angle, anchor: Anchor.center);

  void triggerBoost() {
    isTriggered = true;
    _flashTimer = 0.4;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animPhase += dt * 6.0;

    if (_flashTimer > 0) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) {
        isTriggered = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final double halfW = trackWidth / 2.0;

    // Glowing chevron colors
    final Color padColor = isTriggered
        ? const Color(0xFFFFD700)
        : const Color(0xFF00F0FF);

    // 1. Outer Glow Plate
    final platePaint = Paint()
      ..color = padColor.withAlpha((isTriggered ? 0.8 * 255 : 0.25 * 255).round())
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: trackWidth * 0.9, height: 16.0),
        const Radius.circular(6),
      ),
      platePaint,
    );

    // 2. Draw 3 Forward Velocity Chevrons
    final chevronPaint = Paint()
      ..color = isTriggered ? Colors.white : padColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double pulse = (sin(_animPhase) + 1.0) / 2.0;

    for (int i = -1; i <= 1; i++) {
      final double offsetY = i * 4.5 + (pulse * 2.0 - 1.0);
      final path = Path()
        ..moveTo(-10.0, offsetY + 3.0)
        ..lineTo(0.0, offsetY - 3.0)
        ..lineTo(10.0, offsetY + 3.0);
      canvas.drawPath(path, chevronPaint);
    }

    // 3. Side Emitters
    final pylonPaint = Paint()
      ..color = padColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-halfW, 0), 3.5, pylonPaint);
    canvas.drawCircle(Offset(halfW, 0), 3.5, pylonPaint);
  }
}
