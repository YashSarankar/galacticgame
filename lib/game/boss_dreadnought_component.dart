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
  final VoidCallback? onEmpBlast;

  Sprite? _bossSprite;
  double _hoverTimer = 0.0;
  double _hitFlashTimer = 0.0;
  bool _isSupernova = false;
  double _supernovaTimer = 0.0;
  double _warpTimer = 0.0;
  double _empTimer = 0.0;
  double _empChargeTimer = 0.0;
  bool _isChargingEmp = false;
  bool _hadShield = true;
  final Vector2 _basePosition;

  static final Map<String, Sprite> _cachedBossSprites = {};

  BossDreadnoughtComponent({
    required this.boss,
    required Vector2 centerPosition,
    required this.onBossDamaged,
    this.onEmpBlast,
  })  : _basePosition = centerPosition.clone(),
        _hadShield = boss.hasShield,
        super(
          position: centerPosition.clone(),
          size: Vector2(76, 76),
          anchor: Anchor.center,
        );

  void updateBossModel(BossModel newBoss) {
    if (_hadShield && !newBoss.hasShield && parent != null) {
      // Shield Collapsed Event!
      parent!.add(FloatingTextComponent(
        text: '⚡ SHIELD COLLAPSED!',
        position: position.clone() + Vector2(0, -38),
        glowColor: const Color(0xFF00F0FF),
        duration: 1.0,
      ));
      parent!.add(RadialShockwaveComponent(
        position: position.clone(),
        color: const Color(0xFF00F0FF),
        maxRadius: 65.0,
        duration: 0.5,
      ));
      parent!.add(SparkBurstComponent(
        position: position.clone(),
        baseColor: const Color(0xFF00F0FF),
        count: 16,
      ));
    }
    _hadShield = newBoss.hasShield;
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
        count: 36,
      ));
      parent!.add(SparkBurstComponent(
        position: position.clone(),
        baseColor: const Color(0xFF00F0FF),
        count: 24,
      ));

      parent!.add(FloatingTextComponent(
        text: '💥 SUPERNOVA DETONATION!',
        position: position.clone() + Vector2(0, -35),
        glowColor: const Color(0xFFFFD700),
        duration: 1.5,
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
    } catch (e) {
      debugPrint('[BossDreadnought] Error loading sprite: $e');
    }
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

    // Boss EMP Counter-Attack Loop (Every 7.0 seconds)
    _empTimer += dt;
    if (!_isChargingEmp && _empTimer >= 5.8) {
      _isChargingEmp = true;
      _empChargeTimer = 1.2;
      if (parent != null) {
        parent!.add(FloatingTextComponent(
          text: '⚠️ EMP CHARGING...',
          position: position.clone() + Vector2(0, -32),
          glowColor: const Color(0xFFFF0055),
          duration: 1.1,
        ));
      }
    }

    if (_isChargingEmp) {
      _empChargeTimer -= dt;
      if (_empChargeTimer <= 0) {
        _isChargingEmp = false;
        _empTimer = 0.0;
        _fireEmpBlastWave();
      }
    }

    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
    }
  }

  void _fireEmpBlastWave() {
    if (parent == null) return;

    // Massive Expanding Radial EMP Shockwave
    parent!.add(RadialShockwaveComponent(
      position: position.clone(),
      color: const Color(0xFF00F0FF),
      maxRadius: 180.0,
      duration: 0.85,
    ));

    parent!.add(SparkBurstComponent(
      position: position.clone(),
      baseColor: const Color(0xFF00F0FF),
      count: 24,
    ));

    parent!.add(FloatingTextComponent(
      text: '⚡ EMP BLAST WAVE!',
      position: position.clone() + Vector2(0, -30),
      glowColor: const Color(0xFF00F0FF),
      duration: 1.2,
    ));

    onEmpBlast?.call();
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

    // 0. Charging EMP Warning Aura
    if (_isChargingEmp) {
      final chargePaint = Paint()
        ..color = const Color(0xFFFF0055).withAlpha((0.6 * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);
      final double chargeRadius = (size.x * 0.5) + (1.2 - _empChargeTimer) * 20.0;
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), chargeRadius, chargePaint);
    }

    // 1. Kinetic Forcefield Shield or Crimson Hull Aura
    if (boss.hasShield) {
      final double shieldPulse = 1.0 + (sin(_hoverTimer * 3.0) * 0.05);
      final double shieldRad = (size.x * 0.58) * shieldPulse;

      final shieldFill = Paint()
        ..color = const Color(0xFF00F0FF).withAlpha((0.10 * 255).round());
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), shieldRad, shieldFill);

      final shieldPaint = Paint()
        ..color = const Color(0xFF00F0FF).withAlpha((0.65 * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6.0);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), shieldRad, shieldPaint);

      final innerRing = Paint()
        ..color = const Color(0xFFBD00FF).withAlpha((0.40 * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), shieldRad - 4.0, innerRing);
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
        ..color = boss.hasShield
            ? const Color(0xFF00F0FF)
            : const Color(0xFFFF0055);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.45, fallbackPaint);
    }

    // 3. Health & Shield Bars Header
    _renderBossHealthBars(canvas);
  }

  void _renderBossHealthBars(Canvas canvas) {
    const double barWidth = 64.0;
    const double barHeight = 5.0;
    final double left = (size.x - barWidth) / 2;
    final double top = -18.0;

    // Background Container
    final bgPaint = Paint()..color = const Color(0xFF0A0F1D);
    final bgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left - 2, top - 2, barWidth + 4, barHeight + 4),
      const Radius.circular(3),
    );
    canvas.drawRRect(bgRRect, bgPaint);

    // Red Hull HP Bar
    final double fillWidth = barWidth * boss.healthPercentage;
    final hpPaint = Paint()..color = const Color(0xFFFF0055);
    final hpRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, fillWidth, barHeight),
      const Radius.circular(2),
    );
    canvas.drawRRect(hpRRect, hpPaint);

    // Cyan Shield Bar above Hull HP if active
    if (boss.maxShieldHealth > 0.0) {
      final double shieldTop = top - 6.0;
      final shieldBgRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left - 2, shieldTop - 2, barWidth + 4, 4.0),
        const Radius.circular(2),
      );
      canvas.drawRRect(shieldBgRRect, bgPaint);

      final double shieldFill = barWidth * boss.shieldPercentage;
      final shieldPaint = Paint()..color = const Color(0xFF00F0FF);
      final sRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, shieldTop, shieldFill, 3.0),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(sRRect, shieldPaint);
    }
  }
}
