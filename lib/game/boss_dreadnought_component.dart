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
  double _warpTimer = 0.0;
  final Vector2 _basePosition;


  static final Map<String, Sprite> _cachedBossSprites = {};

  BossDreadnoughtComponent({
    required this.boss,
    required Vector2 centerPosition,
    required this.onBossDamaged,
  })  : _basePosition = centerPosition.clone(),
        super(
          position: centerPosition.clone(),
          size: Vector2(76, 76),
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
    final bool absorbedByShield = boss.hasShield;
    onBossDamaged(damage, isTap: isTap);

    if (parent != null) {
      // Floating damage number
      final text = absorbedByShield
          ? '-${damage.toInt()} SHIELD'
          : '-${damage.toInt()} DMG';
      final glowColor = absorbedByShield
          ? const Color(0xFF00F0FF)
          : (isTap ? const Color(0xFFFF0055) : const Color(0xFFFFD700));

      parent!.add(FloatingTextComponent(
        text: text,
        position: position.clone() +
            Vector2(
              (Random().nextDouble() - 0.5) * 30,
              -25 + (Random().nextDouble() - 0.5) * 15,
            ),
        glowColor: glowColor,
        duration: 0.7,
      ));

      // Hit spark burst
      parent!.add(SparkBurstComponent(
        position: position.clone(),
        baseColor: absorbedByShield
            ? const Color(0xFF00F0FF)
            : const Color(0xFFFF0055),
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
    position.y = _basePosition.y + sin(_hoverTimer) * 4.0;

    // Void Phantom Warp Teleports
    if (boss.archetype == BossArchetype.voidPhantom) {
      _warpTimer += dt;
      if (_warpTimer >= 3.2) {
        _warpTimer = 0.0;
        final random = Random();
        final double warpOffsetX = (random.nextDouble() - 0.5) * 40.0;
        final double warpOffsetY = (random.nextDouble() - 0.5) * 30.0;
        position = _basePosition + Vector2(warpOffsetX, warpOffsetY);

        if (parent != null) {
          parent!.add(RadialShockwaveComponent(
            position: position.clone(),
            color: const Color(0xFFBD00FF),
            maxRadius: 40.0,
            duration: 0.4,
          ));
        }
      }
    }

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
        color: boss.hasShield
            ? const Color(0xFF00F0FF)
            : const Color(0xFFFF0055),
        maxRadius: 36.0,
        duration: 0.35,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isSupernova) return;

    // 1. Kinetic Shield or Crimson Aura
    if (boss.hasShield) {
      final shieldPaint = Paint()
        ..color = const Color(0xFF00F0FF).withAlpha((0.35 * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.58, shieldPaint);
    } else {
      final auraPaint = Paint()
        ..color = const Color(0xFFFF0055).withAlpha((0.25 * 255).round());
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.55, auraPaint);
    }

    // 2. Boss Sprite or Hit Flash
    if (_bossSprite != null) {
      if (_hitFlashTimer > 0) {
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

    // 3. Dual Health & Shield Overhead Bars
    const double barWidth = 64.0;
    const double barHeight = 5.0;
    final double barX = (size.x - barWidth) / 2;
    const double barY = -12.0;

    // A. Hull Health Bar (Red)
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

    // B. Kinetic Shield Bar (Cyan) if active
    if (boss.maxShieldHealth > 0.0) {
      const double shieldBarY = -19.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, shieldBarY, barWidth, 3.5),
          const Radius.circular(2),
        ),
        bgPaint,
      );

      final double shieldFill = barWidth * boss.shieldPercentage;
      if (shieldFill > 0) {
        final shieldFillPaint = Paint()
          ..color = const Color(0xFF00F0FF)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barX, shieldBarY, shieldFill, 3.5),
            const Radius.circular(2),
          ),
          shieldFillPaint,
        );
      }
    }

    // Outer Border
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(3),
      ),
      borderPaint,
    );
  }
}
