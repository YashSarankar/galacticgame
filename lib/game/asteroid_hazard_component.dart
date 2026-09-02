import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import '../utils/game_theme.dart';
import 'particle_effects.dart';
import 'floating_text_component.dart';
import 'moving_ship_component.dart';

typedef OnAsteroidDestroyed = void Function(bool isDarkMatter, double rewardCredits);

/// Drifting cosmic meteor hazard that can be tapped to destroy for bonus rewards.
/// If a ship hits it, the ship suffers a temporary engine slowdown penalty.
class AsteroidHazardComponent extends PositionComponent with TapCallbacks {
  final Vector2 velocity;
  final double rotationSpeed;
  final bool isDarkMatter;
  final OnAsteroidDestroyed onShattered;
  final List<MovingShipComponent> activeShips;

  Sprite? _meteorSprite;
  double _lifetime = 0.0;
  final double _maxLifetime = 14.0;
  bool _isDestroyed = false;

  static final List<String> _meteorAssets = [
    'assets/kenney_space-shooter-remastered/PNG/Meteors/meteorBrown_med1.png',
    'assets/kenney_space-shooter-remastered/PNG/Meteors/meteorBrown_small1.png',
    'assets/kenney_space-shooter-remastered/PNG/Meteors/meteorGrey_med1.png',
    'assets/kenney_space-shooter-remastered/PNG/Meteors/meteorGrey_small1.png',
  ];

  AsteroidHazardComponent({
    required Vector2 position,
    required this.velocity,
    required this.rotationSpeed,
    required this.isDarkMatter,
    required this.onShattered,
    required this.activeShips,
  }) : super(
          position: position,
          size: Vector2(32, 32),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    try {
      Flame.images.prefix = '';
      final String asset = _meteorAssets[Random().nextInt(_meteorAssets.length)];
      final ui.Image img = await Flame.images.load(asset);
      _meteorSprite = Sprite(img);
    } catch (e) {
      debugPrint('[AsteroidHazardComponent] Error loading meteor sprite: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDestroyed) return;

    _lifetime += dt;
    if (_lifetime >= _maxLifetime) {
      removeFromParent();
      return;
    }

    position += velocity * dt;
    angle += rotationSpeed * dt;

    // Check collisions with active racing ships
    for (final ship in activeShips) {
      final double distance = position.distanceTo(ship.position);
      if (distance < 26.0) {
        _handleShipCollision(ship);
        break;
      }
    }
  }

  /// When a player taps the asteroid
  @override
  void onTapDown(TapDownEvent event) {
    if (_isDestroyed) return;
    _isDestroyed = true;

    // 1. Neon explosion particles
    final Color effectColor = isDarkMatter ? GameTheme.neonPurple : GameTheme.neonGold;
    parent?.add(SparkBurstComponent(
      position: position,
      baseColor: effectColor,
      count: 24,
    ));

    parent?.add(RadialShockwaveComponent(
      position: position,
      color: effectColor,
      maxRadius: 36.0,
      duration: 0.4,
    ));

    // 2. Floating reward badge
    final double creditBonus = isDarkMatter ? 0.0 : 75.0;
    parent?.add(FloatingTextComponent(
      text: isDarkMatter ? '+1 DM' : '+$creditBonus',
      position: position + Vector2(0, -12),
      glowColor: effectColor,
      duration: 1.2,
    ));

    onShattered(isDarkMatter, creditBonus);
    removeFromParent();
  }

  /// When a ship accidentally collides with the asteroid
  void _handleShipCollision(MovingShipComponent ship) {
    if (_isDestroyed) return;
    _isDestroyed = true;

    // Stun / slow down ship engine
    ship.applySpeedPenalty(0.55, 2.5);

    // Impact shockwave
    parent?.add(RadialShockwaveComponent(
      position: position,
      color: GameTheme.neonCrimson,
      maxRadius: 28.0,
      duration: 0.35,
    ));

    parent?.add(SparkBurstComponent(
      position: position,
      baseColor: GameTheme.neonAmber,
      count: 12,
    ));

    parent?.add(FloatingTextComponent(
      text: 'HAZARD -45% SPD',
      position: position + Vector2(0, -10),
      glowColor: GameTheme.neonCrimson,
      duration: 1.0,
    ));

    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw glowing cosmic aura
    final Paint glowPaint = Paint()
      ..color = (isDarkMatter ? GameTheme.neonPurple : GameTheme.neonAmber)
          .withAlpha((0.35 * 255).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 14.0, glowPaint);

    if (_meteorSprite != null) {
      _meteorSprite!.render(canvas, size: size);
    } else {
      final Paint rockPaint = Paint()
        ..color = isDarkMatter
            ? const Color(0xFF9D4EDD)
            : const Color(0xFF8D6E63);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 12.0, rockPaint);
    }
  }
}

