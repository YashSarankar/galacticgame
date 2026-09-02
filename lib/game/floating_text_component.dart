import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Floating, scaling, glowing neon text that rises and fades out.
class FloatingTextComponent extends PositionComponent {
  final String text;
  final Color glowColor;
  final double duration;
  double _elapsed = 0.0;

  FloatingTextComponent({
    required this.text,
    required Vector2 position,
    this.glowColor = const Color(0xFF00F0FF),
    this.duration = 1.2,
  }) : super(position: position, anchor: Anchor.center);


  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    if (_elapsed >= duration) {
      removeFromParent();
      return;
    }

    final double progress = _elapsed / duration;

    // Rise upward smoothly
    position.y -= 35.0 * dt;

    // Scale pop then subtle drift
    if (progress < 0.2) {
      final double s = 0.6 + (progress / 0.2) * 0.6; // Scale up to 1.2
      scale = Vector2.all(s);
    } else {
      scale = Vector2.all(1.2 - (progress - 0.2) * 0.2);
    }
  }

  @override
  void render(Canvas canvas) {
    final double progress = (_elapsed / duration).clamp(0.0, 1.0);
    final double opacity = (1.0 - progress).clamp(0.0, 1.0);

    final dynamicPaint = TextPaint(
      style: TextStyle(
        color: Colors.white.withAlpha((opacity * 255).round()),
        fontSize: 16.0,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            color: glowColor.withAlpha((opacity * 255).round()),
            blurRadius: 12.0,
          ),
        ],
      ),
    );

    dynamicPaint.render(canvas, text, Vector2.zero(), anchor: Anchor.center);
  }
}
