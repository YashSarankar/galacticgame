import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import '../models/ship_model.dart';
import 'particle_effects.dart';

/// Callback when a ship crosses the laser checkpoint
typedef OnShipCrossLine = void Function(ShipModel ship, Vector2 position);

/// Moving spacecraft component along a closed loop track metric.
class MovingShipComponent extends PositionComponent {
  ShipModel ship;
  final ui.PathMetric pathMetric;
  final double trackTotalLength;
  final double incomeLineOffset;
  final OnShipCrossLine onCrossLine;

  double currentDistance;
  double speedMultiplier = 1.0;
  double _trailTimer = 0.0;
  double _penaltyTimer = 0.0;
  double _penaltyFactor = 1.0;
  Sprite? _shipSprite;
  Sprite? _fireSprite;
  int _fireFrame = 0;
  double _fireAnimTimer = 0.0;

  static final Map<String, Sprite> _cachedSprites = {};

  MovingShipComponent({
    required this.ship,
    required this.pathMetric,
    required this.trackTotalLength,
    required this.incomeLineOffset,
    required this.onCrossLine,
    this.currentDistance = 0.0,
  }) : super(size: Vector2(36, 36), anchor: Anchor.center);

  /// Updates the ship tier in-place without removing from the Flame component tree
  void updateShipModel(ShipModel newShip) {
    if (ship.tier == newShip.tier && ship.spriteAsset == newShip.spriteAsset) return;
    ship = newShip;
    if (_cachedSprites.containsKey(newShip.spriteAsset)) {
      _shipSprite = _cachedSprites[newShip.spriteAsset];
    } else {
      _loadSpriteForShip(newShip.spriteAsset);
    }
  }

  Future<void> _loadSpriteForShip(String asset) async {
    try {
      Flame.images.prefix = '';
      final ui.Image shipImage = await Flame.images.load(asset);
      _shipSprite = Sprite(shipImage);
      _cachedSprites[asset] = _shipSprite!;
    } catch (_) {}
  }

  /// Applies a temporary collision penalty (e.g. from hitting an asteroid hazard)
  void applySpeedPenalty(double factor, double duration) {
    _penaltyFactor = factor;
    _penaltyTimer = duration;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    try {
      Flame.images.prefix = '';
      if (_cachedSprites.containsKey(ship.spriteAsset)) {
        _shipSprite = _cachedSprites[ship.spriteAsset];
      } else {
        final ui.Image shipImage = await Flame.images.load(ship.spriteAsset);
        _shipSprite = Sprite(shipImage);
        _cachedSprites[ship.spriteAsset] = _shipSprite!;
      }

      if (_cachedSprites.containsKey('fire00')) {
        _fireSprite = _cachedSprites['fire00'];
      } else {
        final ui.Image fireImage = await Flame.images.load('assets/kenney_space-shooter-remastered/PNG/Effects/fire00.png');
        _fireSprite = Sprite(fireImage);
        _cachedSprites['fire00'] = _fireSprite!;
      }
    } catch (e) {
      debugPrint('[MovingShipComponent] Error loading sprite ${ship.spriteAsset}: $e');
    }
  }


  @override
  void update(double dt) {
    super.update(dt);
    if (trackTotalLength <= 0) return;

    if (_penaltyTimer > 0) {
      _penaltyTimer -= dt;
      if (_penaltyTimer <= 0) {
        _penaltyFactor = 1.0;
      }
    }

    final double effectiveSpeed = ship.baseSpeed * speedMultiplier * _penaltyFactor;
    final double prevDist = currentDistance;
    double newDist = currentDistance + (effectiveSpeed * dt);

    bool crossed = false;

    if (newDist >= trackTotalLength) {
      final double wrappedDist = newDist % trackTotalLength;
      // Crossed before wrap or at wrap
      if (prevDist < incomeLineOffset && (newDist >= incomeLineOffset)) {
        crossed = true;
      }
      currentDistance = wrappedDist;
    } else {
      if (prevDist < incomeLineOffset && newDist >= incomeLineOffset) {
        crossed = true;
      }
      currentDistance = newDist;
    }

    // Compute tangent and position along path FIRST
    final ui.Tangent? tangent = pathMetric.getTangentForOffset(currentDistance);
    if (tangent != null) {
      position = Vector2(tangent.position.dx, tangent.position.dy);
      // Flame uses radians; tangent.angle points in direction of travel
      // Kenney ships face UP by default, so we rotate by angle + pi/2
      angle = tangent.angle + (pi / 2);
    }

    // Trigger crossing callback precisely when passing the checkpoint
    if (crossed) {
      final ui.Tangent? lineTangent = pathMetric.getTangentForOffset(incomeLineOffset);
      final Vector2 gatePos = lineTangent != null
          ? Vector2(lineTangent.position.dx, lineTangent.position.dy)
          : position;
      onCrossLine(ship, gatePos);
    }

    // Update flame animation frame
    _fireAnimTimer += dt;
    if (_fireAnimTimer >= 0.08) {
      _fireAnimTimer = 0.0;
      _fireFrame = (_fireFrame + 1) % 4;
    }

    // Spawn trailing cosmic engine sparks
    _trailTimer += dt;
    if (_trailTimer >= 0.12) {
      _trailTimer = 0.0;
      _spawnExhaustSparks();
    }
  }


  void _spawnExhaustSparks() {
    if (parent == null) return;
    final double rearAngle = angle + (pi / 2);
    final Vector2 rearOffset = Vector2(cos(rearAngle) * 16, sin(rearAngle) * 16);
    final sparkPos = position + rearOffset;

    final spark = SparkBurstComponent(
      position: sparkPos,
      baseColor: ship.glowColor,
      count: 1,
    );
    parent!.add(spark);
  }

  @override
  void render(Canvas canvas) {
    // Smooth layered glow without costly MaskFilter
    final outerAuraPaint = Paint()
      ..color = ship.glowColor.withAlpha((0.15 * 255).round());
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.7, outerAuraPaint);

    final innerAuraPaint = Paint()
      ..color = ship.glowColor.withAlpha((0.35 * 255).round());
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.45, innerAuraPaint);

    // Draw Animated Thruster Flame behind ship
    if (_fireSprite != null) {
      canvas.save();
      canvas.translate(size.x / 2, size.y + 2);
      final double flameScale = 0.6 + (_fireFrame * 0.1);
      final flameSize = Vector2(10 * flameScale, 16 * flameScale);
      _fireSprite!.render(
        canvas,
        position: Vector2(-flameSize.x / 2, 0),
        size: flameSize,
      );
      canvas.restore();
    }

    // Render Main Ship Sprite
    if (_shipSprite != null) {
      _shipSprite!.render(canvas, size: size);
    } else {
      final shipPaint = Paint()
        ..color = ship.glowColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 12, shipPaint);
    }
  }
}

