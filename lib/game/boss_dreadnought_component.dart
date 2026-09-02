import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import '../models/boss_model.dart';
import 'particle_effects.dart';
import 'floating_text_component.dart';

typedef OnBossDamaged = void Function(double damage, {bool isTap});

/// Epic Alien Dreadnought Boss hovering in the center of the orbital track.
class BossDreadnoughtComponent extends PositionComponent with TapCallbacks {
  BossModel boss;
  final OnBossDamaged onBossDamaged;

  Sprite? _bossSprite;
  double _hoverTimer = 0.0;
  double _hitFlashTimer = 0.0;
  bool _isSupernova = false;
  double _supernovaTimer = 0.0;

  static final Map<String, Sprite> _cachedBossSprites = {};

  BossDreadnoughtComponent({
    required this.boss,
    required Vector2 centerPosition,
    required this.onBossDamaged,
  }) : super(
          position: centerPosition.clone(),
          size: Vector2(72, 72),
          anchor: Anchor.center,
        );

  void updateBossModel(BossModel newBoss) {
    boss = newBoss;
    if (boss.isDead && !_isSupernova) {
      _triggerSupernovaDeath();
    }
  }

  void receiveDamage(double damage, {bool isTap = false}) {
    if (_isSupernova) return;
    _hitFlashTimer = 0.15;
    onBossDamaged(damage, isTap: isTap);

    if (parent != null) {
      // Floating damage number
      parent!.add(FloatingTextComponent(
        text: '-${damage.toInt()} DMG',
        position: position.clone() +
            Vector2(
              (Random().nextDouble() - 0.5) * 30,
              -25 + (Random().nextDouble() - 0.5) * 15,
            ),
        glowColor: isTap ? const Color(0xFFFF0055) : const Color(0xFFFFD700),
        duration: 0.7,
      ));


      // Hit spark burst
      parent!.add(SparkBurstComponent(
        position: position.clone(),
        baseColor: const Color(0xFFFF0055),
        count: isTap ? 8 : 4,
      ));
    }
  }

  void _triggerSupernovaDeath() {
    _isSupernova = true;
    _supernovaTimer = 1.0;

    if (parent != null) {
      // Massive Supernova Shockwave and Spark Bursts
      parent!.add(RadialShockwaveComponent(
        position: position.clone(),
        color: const Color(0xFFFFD700),
        maxRadius: 80.0,
        duration: 0.9,
      ));
      parent!.add(RadialShockwaveComponent(
        position: position.clone(),
        color: const Color(0xFFFF0055),
        maxRadius: 110.0,
        duration: 1.1,
      ));
      parent!.add(SparkBurstComponent(
        position: position.clone(),
        baseColor: const Color(0xFFFFD700),
        count: 30,
      ));
      parent!.add(FloatingTextComponent(
        text: '💥 SUPERNOVA VICTORY! 💥',
        position: position.clone() + Vector2(0, -35),
        glowColor: const Color(0xFFFFD700),
        duration: 1.8,
      ));

    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    try {
      Flame.images.prefix = '';
      if (_cachedBossSprites.containsKey(boss.spriteAsset)) {
        _bossSprite = _cachedBossSprites[boss.spriteAsset];
      } else {
        final ui.Image img = await Flame.images.load(boss.spriteAsset);
        _bossSprite = Sprite(img);
        _cachedBossSprites[boss.spriteAsset] = _bossSprite!;
      }
    } catch (_) {}
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isSupernova) {
      _supernovaTimer -= dt;
      if (_supernovaTimer <= 0) {
        removeFromParent();
      }
      return;
    }

    // Hover float oscillation
    _hoverTimer += dt * 2.5;
    position.y += sin(_hoverTimer) * 0.35;

    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (_isSupernova) return;

    // Player orbital tap damage: 25 base damage
    receiveDamage(25.0, isTap: true);

    if (parent != null) {
      parent!.add(RadialShockwaveComponent(
        position: event.canvasPosition,
        color: const Color(0xFFFF0055),
        maxRadius: 36.0,
        duration: 0.35,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isSupernova) return;

    // 1. Crimson Shield Aura
    final auraPaint = Paint()
      ..color = const Color(0xFFFF0055).withAlpha((0.25 * 255).round());
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.65, auraPaint);

    // 2. Boss Sprite or Hit Flash
    if (_bossSprite != null) {
      if (_hitFlashTimer > 0) {
        // Red hit flash tint
        final flashPaint = Paint()
          ..colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcATop);
        _bossSprite!.render(canvas, size: size, overridePaint: flashPaint);
      } else {
        _bossSprite!.render(canvas, size: size);
      }
    } else {
      final fallbackPaint = Paint()
        ..color = const Color(0xFFFF0055)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 24, fallbackPaint);
    }

    // 3. Overhead Health Bar
    const double barWidth = 60.0;
    const double barHeight = 6.0;
    final double barX = (size.x - barWidth) / 2;
    const double barY = -14.0;

    // Bar Background
    final bgPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(3),
      ),
      bgPaint,
    );

    // Bar Fill
    final double fillWidth = barWidth * boss.healthPercentage;
    final fillPaint = Paint()
      ..color = const Color(0xFFFF0055)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, fillWidth, barHeight),
        const Radius.circular(3),
      ),
      fillPaint,
    );

    // Bar Border
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(3),
      ),
      borderPaint,
    );
  }
}
