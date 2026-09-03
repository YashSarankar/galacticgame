import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/ship_model.dart';
import '../models/boss_model.dart';
import '../models/sector_theme_model.dart';
import '../utils/number_formatter.dart';
import 'cosmic_biome_component.dart';
import 'track_component.dart';

import 'income_line_component.dart';
import 'boost_pad_component.dart';
import 'moving_ship_component.dart';
import 'boss_dreadnought_component.dart';
import 'asteroid_hazard_component.dart';
import 'floating_text_component.dart';
import 'laser_bolt_component.dart';
import 'particle_effects.dart';

/// Callback when a ship crosses any of the active laser gates
typedef OnIncomeEarned = void Function(ShipModel ship);

/// Interactive Flame Game Engine Canvas for Galactic Racing & Boss Incursions.
class GalacticFlameGame extends FlameGame with TapCallbacks {
  final OnIncomeEarned onIncomeEarned;
  final VoidCallback? onCanvasTapped;
  final Function(double damage, {bool isTap})? onBossDamaged;
  final Function(bool isDarkMatter, double reward)? onAsteroidDestroyed;

  late CosmicBiomeComponent _biomeComponent;
  late TrackComponent _track;
  final List<IncomeLineComponent> _incomeLines = [];
  final List<BoostPadComponent> _boostPads = [];
  int _finishLinesCount = 1;
  int _circuitTier = 1;
  double _boostPadMultiplier = 1.50;

  final List<MovingShipComponent> _activeShipComponents = [];
  List<ShipModel> _currentShips = [];
  double _globalSpeedMultiplier = 1.0;
  bool _isFeverActive = false;
  bool _isInitialized = false;

  BossDreadnoughtComponent? _bossComponent;
  BossModel? _activeBoss;

  double _asteroidTimer = 0.0;
  SectorThemeModel _currentTheme = SectorThemeModel.getThemeForSector(1);

  GalacticFlameGame({
    required this.onIncomeEarned,
    this.onCanvasTapped,
    this.onBossDamaged,
    this.onAsteroidDestroyed,
  });

  @override
  Color backgroundColor() => const Color(0xFF04060E);

  bool _isTutorialActive = false;

  void updateTutorialActive(bool isTutorial) {
    _isTutorialActive = isTutorial;
  }

  void updateSectorTheme(SectorThemeModel theme) {
    _currentTheme = theme;
    if (_isInitialized) {
      _biomeComponent.updateTheme(theme);
      _track.updateTheme(theme);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    onCanvasTapped?.call();

    // Give active racing ships an instant supersonic speed surge impulse
    for (final shipComp in _activeShipComponents) {
      shipComp.triggerTapSurge();
    }

    // Spawn touch ripple, supersonic warp speed streaks & dynamic sector sparks
    add(RadialShockwaveComponent(
      position: event.canvasPosition,
      color: _currentTheme.trackPrimaryGlow,
      maxRadius: 36.0,
      duration: 0.35,
    ));
    add(SparkBurstComponent(
      position: event.canvasPosition,
      baseColor: _currentTheme.particleSparkColor,
      count: 14,
    ));
    add(WarpSpeedLinesComponent(
      position: event.canvasPosition,
      color: _currentTheme.trackPrimaryGlow,
      duration: 0.35,
      lineCount: 16,
    ));
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 1. Mount Cosmic Biome Background (Parallax starfield & orbiting planets)
    _biomeComponent =
        CosmicBiomeComponent(size: size, theme: _currentTheme);
    await add(_biomeComponent);

    // 2. Build the neon track
    _track = TrackComponent(size: size, circuitTier: _circuitTier);
    await add(_track);

    _isInitialized = true;
    _rebuildGateComponents();
    _rebuildBoostPads();
    _syncShipsToTrack();
  }


  @override
  void update(double dt) {
    super.update(dt);
    if (!_isInitialized) return;

    // Suppress asteroid hazards during new player tutorial to avoid distraction
    if (!_isTutorialActive) {
      _asteroidTimer += dt;
      if (_asteroidTimer >= 13.0) {
        _asteroidTimer = 0.0;
        _spawnAsteroidHazard();
      }
    }
  }

  void _spawnAsteroidHazard() {
    if (size.x <= 0 || size.y <= 0) return;
    final random = Random();
    final bool isDM = random.nextDouble() < 0.25;

    final double startX = 20.0 + random.nextDouble() * (size.x - 40.0);
    final double startY = random.nextBool() ? 0.0 : size.y * 0.85;
    final Vector2 target = Vector2(
        size.x / 2 + (random.nextDouble() * 60 - 30), size.y * 0.45);
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
      _rebuildGateComponents();
      _rebuildBoostPads();
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

  /// Updates the number of active Laser Finish Gates (1 to 4)
  void updateFinishLines(int count) {
    if (_finishLinesCount == count) return;
    _finishLinesCount = count.clamp(1, 4);
    if (_isInitialized) {
      _rebuildGateComponents();
      _syncShipsToTrack();
    }
  }

  /// Updates the Track Circuit Tier (morphs geometry & rebuilds gates & boost pads)
  void updateCircuitTier(int tier) {
    if (_circuitTier == tier) return;
    _circuitTier = tier;
    if (_isInitialized) {
      _track.updateCircuitTier(tier);
      _rebuildGateComponents();
      _rebuildBoostPads();
      _syncShipsToTrack();
    }
  }

  /// Updates the Hyper Boost Pad speed impulse multiplier
  void updateBoostPadMultiplier(double mult) {
    _boostPadMultiplier = mult;
    for (final comp in _activeShipComponents) {
      comp.boostPadMultiplier = mult;
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

  /// Updates global speed multiplier (fleet upgrades, 2x boosts, fever mode)
  void setSpeedMultiplier(double multiplier, {bool isFever = false}) {
    _isFeverActive = isFever;
    final double effectiveMultiplier = multiplier * (isFever ? 3.0 : 1.0);
    _globalSpeedMultiplier = effectiveMultiplier;
    for (final shipComp in _activeShipComponents) {
      shipComp.speedMultiplier = effectiveMultiplier;
    }
  }

  List<double> _getGateOffsets(double totalLen, int gateCount) {
    if (totalLen <= 0) return [0.0];
    switch (gateCount) {
      case 2:
        return [0.0, totalLen * 0.50];
      case 3:
        return [0.0, totalLen * 0.333, totalLen * 0.667];
      case 4:
        return [0.0, totalLen * 0.25, totalLen * 0.50, totalLen * 0.75];
      case 1:
      default:
        return [totalLen * 0.50];
    }
  }

  List<double> _getBoostPadOffsets(double totalLen, int tier) {
    if (totalLen <= 0) return [];
    switch (tier) {
      case 3:
        // Infinity Figure-8: Outer corner apexes
        return [totalLen * 0.20, totalLen * 0.70];
      case 4:
        // Tri-Loop: 3 apex turns
        return [totalLen * 0.166, totalLen * 0.50, totalLen * 0.833];
      case 5:
        // Quad-Spiral: 4 apex turns
        return [
          totalLen * 0.125,
          totalLen * 0.375,
          totalLen * 0.625,
          totalLen * 0.875
        ];
      case 1:
      case 2:
      default:
        // Stadium Oval / Ellipse apexes
        return [totalLen * 0.25, totalLen * 0.75];
    }
  }

  void _rebuildGateComponents() {
    if (_track.pathMetric == null || _track.trackLength <= 0) return;

    for (final line in _incomeLines) {
      line.removeFromParent();
    }
    _incomeLines.clear();

    final double totalLen = _track.trackLength;
    final List<double> offsets = _getGateOffsets(totalLen, _finishLinesCount);

    for (final offset in offsets) {
      final ui.Tangent? lineTangent =
          _track.pathMetric!.getTangentForOffset(offset);
      final pos = lineTangent != null
          ? Vector2(lineTangent.position.dx, lineTangent.position.dy)
          : Vector2(size.x / 2, size.y * 0.14);
      final angle = lineTangent != null ? lineTangent.angle + (pi / 2) : 0.0;

      final gate = IncomeLineComponent(
        position: pos,
        trackWidth: 40.0,
        angle: angle,
      );
      _incomeLines.add(gate);
      add(gate);
    }
  }

  void _rebuildBoostPads() {
    if (_track.pathMetric == null || _track.trackLength <= 0) return;

    for (final pad in _boostPads) {
      pad.removeFromParent();
    }
    _boostPads.clear();

    final double totalLen = _track.trackLength;
    final List<double> padOffsets = _getBoostPadOffsets(totalLen, _circuitTier);

    for (final offset in padOffsets) {
      final ui.Tangent? padTangent =
          _track.pathMetric!.getTangentForOffset(offset);
      final pos = padTangent != null
          ? Vector2(padTangent.position.dx, padTangent.position.dy)
          : Vector2(size.x / 2, size.y * 0.5);
      final angle = padTangent != null ? padTangent.angle + (pi / 2) : 0.0;

      final pad = BoostPadComponent(
        position: pos,
        trackWidth: 40.0,
        angle: angle,
      );
      _boostPads.add(pad);
      add(pad);
    }
  }

  void _syncShipsToTrack() {
    if (_track.pathMetric == null || _track.trackLength <= 0) return;

    final double totalLen = _track.trackLength;
    final List<double> gateOffsets =
        _getGateOffsets(totalLen, _finishLinesCount);
    final List<double> boostPadOffsets =
        _getBoostPadOffsets(totalLen, _circuitTier);

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
        _activeShipComponents[i].updateTrackMetric(_track.pathMetric!, totalLen);
        _activeShipComponents[i].updateGateOffsets(gateOffsets);
        _activeShipComponents[i].updateBoostPadOffsets(boostPadOffsets);
        _activeShipComponents[i].boostPadMultiplier = _boostPadMultiplier;
        _activeShipComponents[i].speedMultiplier = _globalSpeedMultiplier;
      }
      return;
    }

    // Preserve existing continuous distances for ships so they NEVER jump!
    final List<double> existingDistances =
        _activeShipComponents.map((c) => c.currentDistance).toList();

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
        gateOffsets: gateOffsets,
        boostPadOffsets: boostPadOffsets,
        currentDistance: dist,
        onCrossGate: _handleShipCrossing,
        onCrossBoostPad: _handleBoostPadCrossing,
      );
      shipComp.boostPadMultiplier = _boostPadMultiplier;
      shipComp.speedMultiplier = _globalSpeedMultiplier;

      _activeShipComponents.add(shipComp);
      add(shipComp);
    }
  }

  /// Synchronizes or removes Dreadnought Boss Incursions
  void syncBoss(BossModel? boss) {
    _activeBoss = boss;

    if (boss == null || boss.isDead) {
      _bossComponent?.removeFromParent();
      _bossComponent = null;
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

  /// Called when any ship crosses any active laser finish gate
  void _handleShipCrossing(
      ShipModel ship, Vector2 position, int gateIndex) {
    // 1. Flash laser gate
    if (gateIndex >= 0 && gateIndex < _incomeLines.length) {
      _incomeLines[gateIndex].triggerFlash();
    }

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
    final double payout = ship.calculateIncomePayout(
        multiplier: _globalSpeedMultiplier * feverBonus);
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

  /// Called when any ship flies over an on-track Hyper Boost Pad
  void _handleBoostPadCrossing(
      ShipModel ship, Vector2 position, int padIndex) {
    if (padIndex >= 0 && padIndex < _boostPads.length) {
      _boostPads[padIndex].triggerBoost();
    }

    add(RadialShockwaveComponent(
      position: position,
      color: const Color(0xFF00F0FF),
      maxRadius: 36.0,
      duration: 0.35,
    ));
    add(SparkBurstComponent(
      position: position,
      baseColor: const Color(0xFF00F0FF),
      count: 12,
    ));
  }
}
