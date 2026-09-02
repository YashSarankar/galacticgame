import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'particle_effects.dart';

typedef OnLaserHit = void Function(double damage);

/// Fast plasma laser bolt projectile traveling from a ship towards the Alien Boss.
class LaserBoltComponent extends PositionComponent {
  final Vector2 startPos;
  final Vector2 targetPos;
  final double damage;
  final Color laserColor;
  final OnLaserHit onHit;

  final double speed = 520.0;
  Sprite? _laserSprite;
  bool _hit = false;

  LaserBoltComponent({
    required this.startPos,
    required this.targetPos,
    required this.damage,
    required this.laserColor,
    required this.onHit,
  }) : super(
          position: startPos.clone(),
          size: Vector2(10, 24),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    try {
      Flame.images.prefix = '';
      final ui.Image laserImage = await Flame.images
          .load('assets/kenney_space-shooter-remastered/PNG/Lasers/laserRed01.png');
      _laserSprite = Sprite(laserImage);
    } catch (_) {}

    // Calculate angle towards target
    final diff = targetPos - startPos;
    angle = atan2(diff.y, diff.x) + (pi / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hit) return;

    final diff = targetPos - position;
    final distance = diff.length;

    if (distance <= speed * dt || distance < 12.0) {
      _hit = true;
      onHit(damage);

      // Impact sparks
      if (parent != null) {
        parent!.add(SparkBurstComponent(
          position: targetPos.clone(),
          baseColor: laserColor,
          count: 4,
        ));
      }
      removeFromParent();
      return;
    }

    final direction = diff.normalized();
    position += direction * (speed * dt);
  }

  @override
  void render(Canvas canvas) {
    if (_laserSprite != null) {
      _laserSprite!.render(canvas, size: size);
    } else {
      final paint = Paint()
        ..color = laserColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.x, size.y),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }
}
