import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import '../models/ship_model.dart';
import 'particle_effects.dart';

/// Callback when a ship crosses a laser gate checkpoint
typedef OnShipCrossGate = void Function(
    ShipModel ship, Vector2 position, int gateIndex);

/// Callback when a ship flies over an on-track Hyper Boost Pad
typedef OnShipCrossBoostPad = void Function(
    ShipModel ship, Vector2 position, int padIndex);

/// Moving spacecraft component along a closed loop track metric.
class MovingShipComponent extends PositionComponent {
  ShipModel ship;
  ui.PathMetric pathMetric;
  double trackTotalLength;
  List<double> gateOffsets;
  List<double> boostPadOffsets;
  final OnShipCrossGate onCrossGate;
  final OnShipCrossBoostPad? onCrossBoostPad;

  double currentDistance;
  double speedMultiplier = 1.0;
  double boostPadMultiplier = 1.50;
  double _boostTimer = 0.0;
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
    required this.gateOffsets,
    this.boostPadOffsets = const [],
    required this.onCrossGate,
    this.onCrossBoostPad,
    this.currentDistance = 0.0,
  }) : super(size: Vector2(36, 36), anchor: Anchor.center);

  /// Updates the track geometry and metric when resizing or evolving tracks
  void updateTrackMetric(ui.PathMetric newMetric, double newLength) {
    pathMetric = newMetric;
    trackTotalLength = newLength;
    if (trackTotalLength > 0) {
      currentDistance = currentDistance % trackTotalLength;
    }
  }

  /// Updates active gate offsets dynamically (e.g. when buying new finish lines)
  void updateGateOffsets(List<double> newOffsets) {
    gateOffsets = List.from(newOffsets);
  }

  /// Updates active boost pad offsets dynamically (e.g. when evolving track)
  void updateBoostPadOffsets(List<double> newOffsets) {
    boostPadOffsets = List.from(newOffsets);
  }

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

  /// Triggers an immediate +50% speed surge impulse on tap
  void triggerTapSurge() {
    _boostTimer = max(_boostTimer, 0.45);
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
        final ui.Image fireImage = await Flame.images.load(
            'assets/kenney_space-shooter-remastered/PNG/Effects/fire00.png');
        _fireSprite = Sprite(fireImage);
        _cachedSprites['fire00'] = _fireSprite!;
      }
    } catch (e) {
      debugPrint(
          '[MovingShipComponent] Error loading sprite ${ship.spriteAsset}: $e');
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

    if (_boostTimer > 0) {
      _boostTimer -= dt;
    }

    final double effectiveBoost = _boostTimer > 0 ? boostPadMultiplier : 1.0;
    final double effectiveSpeed =
        ship.baseSpeed * speedMultiplier * effectiveBoost * _penaltyFactor;
    final double prevDist = currentDistance;
    final double newDist = currentDistance + (effectiveSpeed * dt);

    final double wrappedDist = (newDist >= trackTotalLength)
        ? (newDist % trackTotalLength)
        : newDist;

    // 1. Check crossing for each active gate on the circuit
    for (int i = 0; i < gateOffsets.length; i++) {
      final double gateOffset = gateOffsets[i];
      bool crossed = false;

      if (newDist >= trackTotalLength) {
        // Lap wrapped around the finish line
        if (gateOffset == 0.0) {
          crossed = true; // start/finish line passed on lap wrap
        } else if (prevDist < gateOffset) {
          crossed = true; // gate was ahead before wrap
        } else if (wrappedDist >= gateOffset) {
          crossed = true; // wrapped past gate on new lap
        }
      } else {
        // Linear segment progression
        if (prevDist < gateOffset && newDist >= gateOffset) {
          crossed = true;
        }
      }

      if (crossed) {
        final ui.Tangent? lineTangent =
            pathMetric.getTangentForOffset(gateOffset);
        final Vector2 gatePos = lineTangent != null
            ? Vector2(lineTangent.position.dx, lineTangent.position.dy)
            : position;
        onCrossGate(ship, gatePos, i);
      }
    }

    // 2. Check crossing for on-track Hyper Boost Pads
    for (int i = 0; i < boostPadOffsets.length; i++) {
      final double padOffset = boostPadOffsets[i];
      bool crossedPad = false;

      if (newDist >= trackTotalLength) {
        if (padOffset == 0.0) {
          crossedPad = true;
        } else if (prevDist < padOffset) {
          crossedPad = true;
        } else if (wrappedDist >= padOffset) {
          crossedPad = true;
        }
      } else {
        if (prevDist < padOffset && newDist >= padOffset) {
          crossedPad = true;
        }
      }

      if (crossedPad) {
        _boostTimer = 1.0; // 1.0 second hyper-thrust impulse
        final ui.Tangent? padTangent =
            pathMetric.getTangentForOffset(padOffset);
        final Vector2 padPos = padTangent != null
            ? Vector2(padTangent.position.dx, padTangent.position.dy)
            : position;
        onCrossBoostPad?.call(ship, padPos, i);
      }
    }

    if (newDist >= trackTotalLength) {
      currentDistance = newDist % trackTotalLength;
    } else {
      currentDistance = newDist;
    }

    // Compute tangent and position along path
    final ui.Tangent? tangent = pathMetric.getTangentForOffset(currentDistance);
    if (tangent != null) {
      position = Vector2(tangent.position.dx, tangent.position.dy);
      angle = tangent.angle + (pi / 2);
    }

    // Update flame animation frame
    _fireAnimTimer += dt;
    if (_fireAnimTimer >= 0.08) {
      _fireAnimTimer = 0.0;
      _fireFrame = (_fireFrame + 1) % 4;
    }

    // Spawn trailing cosmic engine sparks (boost streaks when hyper active!)
    _trailTimer += dt;
    final double trailInterval = _boostTimer > 0 ? 0.05 : 0.12;
    if (_trailTimer >= trailInterval) {
      _trailTimer = 0.0;
      _spawnExhaustSparks();
    }
  }

  void _spawnExhaustSparks() {
    if (parent == null) return;
    final double backAngle = angle + (pi / 2);
    final offset = Vector2(cos(backAngle), sin(backAngle)) * 14.0;
    parent!.add(SparkBurstComponent(
      position: position + offset,
      baseColor: _boostTimer > 0 ? const Color(0xFF00F0FF) : ship.glowColor,
      count: _boostTimer > 0 ? 6 : 3,
    ));
  }

  @override
  void render(Canvas canvas) {
    if (_boostTimer > 0) {
      // Radiant supersonic speed trail glow behind ship
      final glowPaint = Paint()
        ..color = const Color(0xFF00F0FF).withAlpha((0.6 * 255).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8.0);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 24.0, glowPaint);
    }

    if (_fireSprite != null) {
      canvas.save();
      canvas.translate(size.x / 2, size.y - 2);
      canvas.scale(_boostTimer > 0 ? 1.1 : 0.7, _boostTimer > 0 ? 1.3 : 0.7);
      _fireSprite!.render(canvas, anchor: Anchor.topCenter);
      canvas.restore();
    }

    if (_shipSprite != null) {
      _shipSprite!.render(
        canvas,
        size: size,
      );
    }
  }
}
