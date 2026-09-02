import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Single dynamic particle for thruster exhaust or laser bursts
class SparkParticle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double life;
  double maxLife;
  double size;

  SparkParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.maxLife,
    required this.size,
  }) : life = maxLife;

  bool update(double dt) {
    life -= dt;
    position += velocity * dt;
    velocity *= 0.94; // Air/plasma drag
    return life > 0;
  }
}

/// Particle Emitter Component for laser gate crossing sparkles
class SparkBurstComponent extends PositionComponent {
  final List<SparkParticle> _particles = [];
  final Color baseColor;
  final int count;
  final Random _rng = Random();

  SparkBurstComponent({
    required Vector2 position,
    this.baseColor = const Color(0xFF00F0FF),
    this.count = 24,
  }) : super(position: position);

  @override
  void onLoad() {
    super.onLoad();
    for (int i = 0; i < count; i++) {
      final double angle = _rng.nextDouble() * 2 * pi;
      final double speed = 40.0 + _rng.nextDouble() * 120.0;
      final double life = 0.4 + _rng.nextDouble() * 0.5;
      final double size = 2.0 + _rng.nextDouble() * 3.5;

      _particles.add(
        SparkParticle(
          position: Vector2.zero(),
          velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
          color: baseColor,
          maxLife: life,
          size: size,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _particles.removeWhere((p) => !p.update(dt));
    if (_particles.isEmpty) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      final double progress = (p.life / p.maxLife).clamp(0.0, 1.0);
      final double alpha = progress;

      final paint = Paint()
        ..color = p.color.withAlpha((alpha * 255).round())
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);

      canvas.drawCircle(Offset(p.position.x, p.position.y), p.size * progress, paint);
    }
  }
}

/// Radial shockwave expanding on merge or prestige
class RadialShockwaveComponent extends PositionComponent {
  final Color color;
  final double maxRadius;
  final double duration;
  double _elapsed = 0.0;

  RadialShockwaveComponent({
    required Vector2 position,
    this.color = const Color(0xFF00F0FF),
    this.maxRadius = 70.0,
    this.duration = 0.6,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final double progress = (_elapsed / duration).clamp(0.0, 1.0);
    final double currentRadius = maxRadius * progress;
    final double opacity = (1.0 - progress).clamp(0.0, 1.0);

    final ringPaint = Paint()
      ..color = color.withAlpha((opacity * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * (1.0 - progress * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    canvas.drawCircle(Offset.zero, currentRadius, ringPaint);
  }
}
