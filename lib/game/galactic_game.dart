import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/ship_model.dart';
import '../models/sector_theme_model.dart';
import '../utils/number_formatter.dart';
import 'track_component.dart';
import 'income_line_component.dart';
import 'moving_ship_component.dart';
import 'particle_effects.dart';
import 'floating_text_component.dart';

import 'asteroid_hazard_component.dart';
import 'boss_dreadnought_component.dart';
import 'laser_bolt_component.dart';
import '../models/boss_model.dart';

typedef OnIncomeCallback = void Function(ShipModel ship);
typedef OnAsteroidCallback = void Function(bool isDarkMatter, double rewardCredits);
typedef OnBossDamagedCallback = void Function(double damage, {bool isTap});

/// Core Flame Game engine orchestrating the 60 FPS neon track simulation.
class GalacticGame extends FlameGame with TapCallbacks {
  final OnIncomeCallback onIncomeEarned;
  final OnAsteroidCallback? onAsteroidDestroyed;
  final VoidCallback? onCanvasTapped;
  final OnBossDamagedCallback? onBossDamaged;

  late TrackComponent _track;
  late IncomeLineComponent _incomeLine;
  final List<MovingShipComponent> _activeShipComponents = [];
  BossDreadnoughtComponent? _bossComponent;
  BossModel? _activeBoss;
  SectorThemeModel _currentTheme = SectorThemeModel.getThemeForSector(1);

  List<ShipModel> _currentShips = [];
  double _globalSpeedMultiplier = 1.0;
  bool _isFeverActive = false;
  bool _isInitialized = false;
  double _asteroidTimer = 0.0;

  GalacticGame({
    required this.onIncomeEarned,
    this.onAsteroidDestroyed,
    this.onCanvasTapped,
    this.onBossDamaged,
  });

  @override
  Color backgroundColor() => const Color(0xFF070913);

  void updateSectorTheme(SectorThemeModel theme) {
    _currentTheme = theme;
    if (_isInitialized) {
      _track.updateTheme(theme);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    onCanvasTapped?.call();

    // Spawn touch ripple & dynamic sector sparks
    add(RadialShockwaveComponent(
      position: event.canvasPosition,
      color: _currentTheme.trackPrimaryGlow,
      maxRadius: 32.0,
      duration: 0.35,
    ));
    add(SparkBurstComponent(
      position: event.canvasPosition,
      baseColor: _currentTheme.particleSparkColor,
      count: 14,
    ));
  }


  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 1. Build the neon track
    _track = TrackComponent(size: size);
    await add(_track);

    // 2. Add income laser checkpoint
    _incomeLine = IncomeLineComponent(
      position: Vector2(size.x / 2, size.y * 0.14),
      trackWidth: 40.0,
      angle: 0.0,
    );
    await add(_incomeLine);

    _isInitialized = true;
    _syncShipsToTrack();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isInitialized) return;

    _asteroidTimer += dt;
    if (_asteroidTimer >= 13.0) {
      _asteroidTimer = 0.0;
      _spawnAsteroidHazard();
    }
  }

  void _spawnAsteroidHazard() {
    if (size.x <= 0 || size.y <= 0) return;
    final random = Random();
    final bool isDM = random.nextDouble() < 0.25;

    final double startX = 20.0 + random.nextDouble() * (size.x - 40.0);
    final double startY = random.nextBool() ? 0.0 : size.y * 0.85;
    final Vector2 target = Vector2(size.x / 2 + (random.nextDouble() * 60 - 30), size.y * 0.45);
    final Vector2 direction = (target - Vector2(startX, startY)).normalized();
    final double speed = 30.0 + random.nextDouble() * 25.0;

    final meteor = AsteroidHazardComponent(
      position: Vector2(startX, startY),
      velocity: direction * speed,
      rotationSpeed: (random.nextDouble() - 0.5) * 2.5,
      isDarkMatter: isDM,
      activeShips: _activeShipComponents,
      onShattered: (isDarkMatter, reward) {
        onAsteroidDestroyed?.call(isDarkMatter, reward);
      },
    );

    add(meteor);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_isInitialized) {
      _syncShipsToTrack();
    }
  }


  /// Updates active ships from Riverpod state
  void updateShips(List<ShipModel> ships) {
    if (_isSameFleet(_currentShips, ships)) {
      return;
    }
    _currentShips = List.from(ships);
    if (_isInitialized) {
      _syncShipsToTrack();
    }
  }

  bool _isSameFleet(List<ShipModel> a, List<ShipModel> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].tier != b[i].tier) return false;
    }
    return true;
  }


  /// Updates global speed multiplier (e.g. 2x boost active, fever mode)
  void setSpeedMultiplier(double multiplier, {bool isFever = false}) {
    _isFeverActive = isFever;
    final double effectiveMultiplier = multiplier * (isFever ? 3.5 : 1.0);
    _globalSpeedMultiplier = effectiveMultiplier;
    for (final shipComp in _activeShipComponents) {
      shipComp.speedMultiplier = effectiveMultiplier;
    }
  }

  void _syncShipsToTrack() {
    if (_track.pathMetric == null || _track.trackLength <= 0) return;

    final double totalLen = _track.trackLength;
    final double lineOffset = totalLen * 0.5;

    // Position laser checkpoint precisely on the track path perpendicular to travel
    final ui.Tangent? lineTangent = _track.pathMetric!.getTangentForOffset(lineOffset);
    if (lineTangent != null) {
      _incomeLine.position = Vector2(lineTangent.position.dx, lineTangent.position.dy);
      _incomeLine.angle = lineTangent.angle + (pi / 2);
    }

    if (_currentShips.isEmpty) {
      for (final comp in _activeShipComponents) {
        comp.removeFromParent();
      }
      _activeShipComponents.clear();
      return;
    }

    // In-place update: if component count matches fleet count, update models directly without teardown!
    if (_activeShipComponents.length == _currentShips.length) {
      for (int i = 0; i < _currentShips.length; i++) {
        _activeShipComponents[i].updateShipModel(_currentShips[i]);
        _activeShipComponents[i].speedMultiplier = _globalSpeedMultiplier;
      }
      return;
    }

    // Preserve existing continuous distances for ships so they NEVER jump!
    final List<double> existingDistances = _activeShipComponents
        .map((c) => c.currentDistance)
        .toList();

    for (final comp in _activeShipComponents) {
      comp.removeFromParent();
    }
    _activeShipComponents.clear();

    final double spacing = totalLen / _currentShips.length;

    for (int i = 0; i < _currentShips.length; i++) {
      final ship = _currentShips[i];
      final double dist = (i < existingDistances.length)
          ? existingDistances[i]
          : (i * spacing) % totalLen;

      final shipComp = MovingShipComponent(
        ship: ship,
        pathMetric: _track.pathMetric!,
        trackTotalLength: totalLen,
        incomeLineOffset: lineOffset,
        currentDistance: dist,
        onCrossLine: _handleShipCrossing,
      );
      shipComp.speedMultiplier = _globalSpeedMultiplier;

      _activeShipComponents.add(shipComp);
      add(shipComp);
    }
  }


  /// Updates active Alien Boss incursion component
  void updateBoss(BossModel? boss) {
    _activeBoss = boss;
    if (boss == null || boss.isDead) {
      if (_bossComponent != null) {
        _bossComponent!.removeFromParent();
        _bossComponent = null;
      }
      return;
    }

    if (_bossComponent == null) {
      final center = Vector2(size.x / 2, size.y / 2);
      _bossComponent = BossDreadnoughtComponent(
        boss: boss,
        centerPosition: center,
        onBossDamaged: (dmg, {bool isTap = false}) {
          onBossDamaged?.call(dmg, isTap: isTap);
        },
      );
      add(_bossComponent!);
    } else {
      _bossComponent!.updateBossModel(boss);
    }
  }

  /// Called when any ship crosses the income laser line
  void _handleShipCrossing(ShipModel ship, Vector2 position) {
    // 1. Flash laser gate
    _incomeLine.triggerFlash();

    // 2. Radial shockwave
    add(RadialShockwaveComponent(
      position: position,
      color: _isFeverActive ? const Color(0xFFFFD700) : ship.glowColor,
      maxRadius: _isFeverActive ? 48.0 : 36.0,
      duration: _isFeverActive ? 0.6 : 0.45,
    ));

    // 3. Spark burst
    add(SparkBurstComponent(
      position: position,
      baseColor: _isFeverActive ? const Color(0xFFFF0055) : ship.glowColor,
      count: _isFeverActive ? 24 : 16,
    ));

    // 4. Floating Income Badge ("+$10.5M" or "3X CRIT! +$31.5M")
    final double feverBonus = _isFeverActive ? 3.0 : 1.0;
    final double payout = ship.calculateIncomePayout(multiplier: _globalSpeedMultiplier * feverBonus);
    final String formatted = _isFeverActive
        ? '3X CRIT! +${NumberFormatter.formatCredits(payout, decimals: 1)}'
        : '+${NumberFormatter.formatCredits(payout, decimals: 1)}';

    add(FloatingTextComponent(
      text: formatted,
      position: position + Vector2(0, -10),
      glowColor: _isFeverActive ? const Color(0xFFFFD700) : ship.glowColor,
      duration: _isFeverActive ? 1.5 : 1.2,
    ));

    // 5. Fire Fleet Laser Bolt at Alien Boss if active
    if (_bossComponent != null && _activeBoss != null && !_activeBoss!.isDead) {
      final double feverMultiplier = _isFeverActive ? 2.5 : 1.0;
      final double laserDamage =
          ship.calculateLaserDamage(multiplier: feverMultiplier);
      final laser = LaserBoltComponent(
        startPos: position.clone(),
        targetPos: _bossComponent!.position.clone(),
        damage: laserDamage,
        laserColor: _isFeverActive ? const Color(0xFFFF0055) : ship.glowColor,
        onHit: (dmg) {
          _bossComponent?.receiveDamage(dmg, isTap: false);
        },
      );
      add(laser);
    }


    // 6. Notify Riverpod State
    onIncomeEarned(ship);
  }
}


