import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/game_theme.dart';

/// Representation of a Spacecraft in the Merge and Track system.
class ShipModel {
  final String id;
  final int tier;
  final String name;
  final String spriteAsset;
  final Color glowColor;
  final double baseIncome;
  final double baseSpeed; // pixels per second along path
  final bool isBox; // Delivery Crate waiting to be tapped to unbox

  const ShipModel({
    required this.id,
    required this.tier,
    required this.name,
    required this.spriteAsset,
    required this.glowColor,
    required this.baseIncome,
    required this.baseSpeed,
    this.isBox = false,
  });

  /// Factory to generate a ship by tier with a unique instance ID.
  factory ShipModel.create(int tier, [String? id, bool isBox = false]) {
    final spec = getTierSpec(tier);
    return ShipModel(
      id: id ?? '${spec.tier}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}',
      tier: spec.tier,
      name: spec.name,
      spriteAsset: spec.spriteAsset,
      glowColor: spec.glowColor,
      baseIncome: spec.baseIncome,
      baseSpeed: spec.baseSpeed,
      isBox: isBox,
    );
  }

  /// Calculates calibrated income per crossing: BaseIncome * (1.85 ^ (tier - 1))
  double calculateIncomePayout({double multiplier = 1.0}) {
    final double income = baseIncome * pow(1.85, tier - 1);
    return income * multiplier;
  }


  /// Calculates boss laser strike damage scaling exponentially with ship tier:
  /// Damage = 15.0 * (1.6 ^ (tier - 1)) * multiplier
  /// Higher tier ships deliver devastating orbital strike power to alien bosses!
  double calculateLaserDamage({double multiplier = 1.0}) {
    final double tierFactor = pow(1.6, max(0, tier - 1)).toDouble();
    return 15.0 * tierFactor * multiplier;
  }


  /// Copy with custom parameters
  ShipModel copyWith({
    String? id,
    int? tier,
    String? name,
    String? spriteAsset,
    Color? glowColor,
    double? baseIncome,
    double? baseSpeed,
    bool? isBox,
  }) {
    return ShipModel(
      id: id ?? this.id,
      tier: tier ?? this.tier,
      name: name ?? this.name,
      spriteAsset: spriteAsset ?? this.spriteAsset,
      glowColor: glowColor ?? this.glowColor,
      baseIncome: baseIncome ?? this.baseIncome,
      baseSpeed: baseSpeed ?? this.baseSpeed,
      isBox: isBox ?? this.isBox,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tier': tier,
      'name': name,
      'spriteAsset': spriteAsset,
      'glowColor': glowColor.toARGB32(),
      'baseIncome': baseIncome,
      'baseSpeed': baseSpeed,
      'isBox': isBox,
    };
  }

  factory ShipModel.fromJson(Map<String, dynamic> json) {
    return ShipModel(
      id: json['id'] as String,
      tier: json['tier'] as int,
      name: json['name'] as String,
      spriteAsset: json['spriteAsset'] as String,
      glowColor: Color(json['glowColor'] as int),
      baseIncome: (json['baseIncome'] as num).toDouble(),
      baseSpeed: (json['baseSpeed'] as num).toDouble(),
      isBox: json['isBox'] as bool? ?? false,
    );
  }


  /// Predefined tier catalog leveraging the Kenney Space Shooter Remastered pack.
  static ShipModel getTierSpec(int tier) {
    final int clampedTier = tier < 1 ? 1 : tier;
    final int index = clampedTier - 1;

    if (index < _tierCatalog.length) {
      return _tierCatalog[index];
    }

    // Procedural extrapolation for ultra-high tiers (> 20)
    final double income = 1000.0 * pow(2.1, clampedTier - 1);
    final double speed = 180.0 + (clampedTier * 8.0);
    final Color color = GameTheme.getTierColor(clampedTier);

    return ShipModel(
      id: '',
      tier: clampedTier,
      name: 'Cosmic Overlord Mk.$clampedTier',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack3.png',
      glowColor: color,
      baseIncome: income,
      baseSpeed: speed,
    );
  }

  static const double baseCost = 100.0;
  static const double costScaleFactor = 1.25;

  /// Calculates purchase cost for base ship: Cost = BaseCost * (1.25 ^ totalPurchases) * (1 - discount)
  static double calculatePurchaseCost(int totalPurchases, int tier, {double discount = 0.0}) {
    final double tierMultiplier = pow(2.2, tier - 1).toDouble();
    final double rawCost = baseCost * pow(costScaleFactor, totalPurchases) * tierMultiplier;
    return max(10.0, rawCost * (1.0 - discount.clamp(0.0, 0.8)));
  }


  static final List<ShipModel> _tierCatalog = [
    const ShipModel(
      id: '',
      tier: 1,
      name: 'Novice Interceptor',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip1_blue.png',
      glowColor: Color(0xFF00F0FF),
      baseIncome: 4.0,
      baseSpeed: 85.0,
    ),
    const ShipModel(
      id: '',
      tier: 2,
      name: 'Vanguard Scout',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip1_green.png',
      glowColor: Color(0xFF06D6A0),
      baseIncome: 4.0,
      baseSpeed: 91.0,
    ),
    const ShipModel(
      id: '',
      tier: 3,
      name: 'Solar Falcon',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip1_orange.png',
      glowColor: Color(0xFFFFB703),
      baseIncome: 4.0,
      baseSpeed: 97.0,
    ),
    const ShipModel(
      id: '',
      tier: 4,
      name: 'Crimson Dart',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip1_red.png',
      glowColor: Color(0xFFFF3366),
      baseIncome: 4.0,
      baseSpeed: 103.0,
    ),
    const ShipModel(
      id: '',
      tier: 5,
      name: 'Plasma Cruiser',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip2_blue.png',
      glowColor: Color(0xFF38BDF8),
      baseIncome: 4.0,
      baseSpeed: 109.0,
    ),
    const ShipModel(
      id: '',
      tier: 6,
      name: 'Hyperion Frigate',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip2_green.png',
      glowColor: Color(0xFF10B981),
      baseIncome: 4.0,
      baseSpeed: 115.0,
    ),
    const ShipModel(
      id: '',
      tier: 7,
      name: 'Nova Destroyer',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip2_orange.png',
      glowColor: Color(0xFFFB8500),
      baseIncome: 4.0,
      baseSpeed: 121.0,
    ),
    const ShipModel(
      id: '',
      tier: 8,
      name: 'Valkyrie Battleship',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip2_red.png',
      glowColor: Color(0xFFF43F5E),
      baseIncome: 4.0,
      baseSpeed: 127.0,
    ),
    const ShipModel(
      id: '',
      tier: 9,
      name: 'Quantum Dreadnought',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip3_blue.png',
      glowColor: Color(0xFF818CF8),
      baseIncome: 4.0,
      baseSpeed: 133.0,
    ),
    const ShipModel(
      id: '',
      tier: 10,
      name: 'Eclipse Titan',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip3_green.png',
      glowColor: Color(0xFF2DD4BF),
      baseIncome: 4.0,
      baseSpeed: 139.0,
    ),
    const ShipModel(
      id: '',
      tier: 11,
      name: 'Apex Leviathan',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip3_orange.png',
      glowColor: Color(0xFFF59E0B),
      baseIncome: 4.0,
      baseSpeed: 145.0,
    ),
    const ShipModel(
      id: '',
      tier: 12,
      name: 'Celestial Behemoth',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip3_red.png',
      glowColor: Color(0xFFEF4444),
      baseIncome: 4.0,
      baseSpeed: 151.0,
    ),
    const ShipModel(
      id: '',
      tier: 13,
      name: 'Void Strider UFO',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/ufoBlue.png',
      glowColor: Color(0xFF60A5FA),
      baseIncome: 4.0,
      baseSpeed: 157.0,
    ),
    const ShipModel(
      id: '',
      tier: 14,
      name: 'Pulsar Saucer',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/ufoGreen.png',
      glowColor: Color(0xFF4ADE80),
      baseIncome: 4.0,
      baseSpeed: 163.0,
    ),
    const ShipModel(
      id: '',
      tier: 15,
      name: 'Chrono Orbiter',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/ufoYellow.png',
      glowColor: Color(0xFFFDE047),
      baseIncome: 4.0,
      baseSpeed: 169.0,
    ),
    const ShipModel(
      id: '',
      tier: 16,
      name: 'Singularity Core',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/ufoRed.png',
      glowColor: Color(0xFFFF007F),
      baseIncome: 4.0,
      baseSpeed: 175.0,
    ),

    const ShipModel(
      id: '',
      tier: 17,
      name: 'Stellar Dominator',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue3.png',
      glowColor: Color(0xFF38BDF8),
      baseIncome: 10.0,
      baseSpeed: 400.0,
    ),
    const ShipModel(
      id: '',
      tier: 18,
      name: 'Omega Carrier',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen3.png',
      glowColor: Color(0xFF10B981),
      baseIncome: 10.0,
      baseSpeed: 415.0,
    ),
    const ShipModel(
      id: '',
      tier: 19,
      name: 'Dark Matter Sovereign',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyRed3.png',
      glowColor: Color(0xFFFF1E56),
      baseIncome: 10.0,
      baseSpeed: 430.0,
    ),
    const ShipModel(
      id: '',
      tier: 20,
      name: 'Galactic Overlord',
      spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack3.png',
      glowColor: Color(0xFF9D4EDD),
      baseIncome: 10.0,
      baseSpeed: 450.0,
    ),
  ];
}
