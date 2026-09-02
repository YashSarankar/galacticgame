import 'package:flutter/material.dart';

enum RelicEffectType {
  speedBoost,
  darkMatterBoost,
  feverDuration,
  cloneChance,
  incomeBoost,
  bossTapDamage,
}

enum RelicRarity {
  rare,
  epic,
  legendary,
  cosmic,
}

/// Representation of an Ancient Alien Relic granting permanent passive boosts.
class RelicModel {
  final String id;
  final String name;
  final String description;
  final int iconCodePoint;
  final RelicRarity rarity;
  final int level;
  final int maxLevel;
  final int shards;
  final int shardsPerUpgrade;
  final RelicEffectType effectType;
  final double baseBonus;
  final double bonusPerLevel;

  const RelicModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCodePoint,
    required this.rarity,
    this.level = 0,
    this.maxLevel = 5,
    this.shards = 0,
    this.shardsPerUpgrade = 3,
    required this.effectType,
    required this.baseBonus,
    required this.bonusPerLevel,
  });

  bool get isUnlocked => level > 0;
  bool get canUpgrade => shards >= (shardsPerUpgrade * (level + 1)) && level < maxLevel;
  int get shardsNeededForNext => (shardsPerUpgrade * (level + 1));
  double get currentBonusValue => level == 0 ? 0.0 : baseBonus + (level - 1) * bonusPerLevel;

  IconData get icon {
    switch (effectType) {
      case RelicEffectType.speedBoost:
        return Icons.speed_rounded;
      case RelicEffectType.darkMatterBoost:
        return Icons.diamond_rounded;
      case RelicEffectType.feverDuration:
        return Icons.local_fire_department_rounded;
      case RelicEffectType.cloneChance:
        return Icons.rocket_launch_rounded;
      case RelicEffectType.incomeBoost:
        return Icons.monetization_on_rounded;
      case RelicEffectType.bossTapDamage:
        return Icons.radar_rounded;
    }
  }

  Color get rarityColor {

    switch (rarity) {
      case RelicRarity.rare:
        return const Color(0xFF00F5FF); // Neon Cyan
      case RelicRarity.epic:
        return const Color(0xFFBD00FF); // Neon Purple
      case RelicRarity.legendary:
        return const Color(0xFFFFD700); // Gold
      case RelicRarity.cosmic:
        return const Color(0xFFFF0055); // Crimson Cosmic
    }
  }

  String get rarityTitle {
    switch (rarity) {
      case RelicRarity.rare:
        return 'RARE';
      case RelicRarity.epic:
        return 'EPIC';
      case RelicRarity.legendary:
        return 'LEGENDARY';
      case RelicRarity.cosmic:
        return 'COSMIC';
    }
  }

  RelicModel copyWith({
    String? id,
    String? name,
    String? description,
    int? iconCodePoint,
    RelicRarity? rarity,
    int? level,
    int? maxLevel,
    int? shards,
    int? shardsPerUpgrade,
    RelicEffectType? effectType,
    double? baseBonus,
    double? bonusPerLevel,
  }) {
    return RelicModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      rarity: rarity ?? this.rarity,
      level: level ?? this.level,
      maxLevel: maxLevel ?? this.maxLevel,
      shards: shards ?? this.shards,
      shardsPerUpgrade: shardsPerUpgrade ?? this.shardsPerUpgrade,
      effectType: effectType ?? this.effectType,
      baseBonus: baseBonus ?? this.baseBonus,
      bonusPerLevel: bonusPerLevel ?? this.bonusPerLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': iconCodePoint,
      'rarity': rarity.index,
      'level': level,
      'maxLevel': maxLevel,
      'shards': shards,
      'shardsPerUpgrade': shardsPerUpgrade,
      'effectType': effectType.index,
      'baseBonus': baseBonus,
      'bonusPerLevel': bonusPerLevel,
    };
  }

  factory RelicModel.fromJson(Map<String, dynamic> json) {
    return RelicModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      rarity: RelicRarity.values[json['rarity'] as int],
      level: json['level'] as int? ?? 0,
      maxLevel: json['maxLevel'] as int? ?? 5,
      shards: json['shards'] as int? ?? 0,
      shardsPerUpgrade: json['shardsPerUpgrade'] as int? ?? 3,
      effectType: RelicEffectType.values[json['effectType'] as int],
      baseBonus: (json['baseBonus'] as num).toDouble(),
      bonusPerLevel: (json['bonusPerLevel'] as num).toDouble(),
    );
  }

  /// Default 6 canonical alien artifacts in Galactic Merge
  static List<RelicModel> getInitialRelics() {
    return [
      const RelicModel(
        id: 'relic_chronos_core',
        name: 'Chronos Hyper-Core',
        description: 'Accelerates tachyon thrusters across all active ships.',
        iconCodePoint: 0xe5e1, // Icons.speed
        rarity: RelicRarity.rare,
        level: 1, // Start with 1 unlocked
        effectType: RelicEffectType.speedBoost,
        baseBonus: 0.15, // +15% Speed
        bonusPerLevel: 0.15, // Up to +75%
      ),
      const RelicModel(
        id: 'relic_dm_resonator',
        name: 'Dark Matter Resonator',
        description: 'Harnesses singularity echoes to amplify prestige gems.',
        iconCodePoint: 0xe1af, // Icons.diamond
        rarity: RelicRarity.epic,
        level: 0,
        effectType: RelicEffectType.darkMatterBoost,
        baseBonus: 0.25, // +25% DM
        bonusPerLevel: 0.25, // Up to +125%
      ),
      const RelicModel(
        id: 'relic_flux_capacitor',
        name: 'Quantum Flux Coil',
        description: 'Stabilizes warp fields to extend Hyperspace Fever Rush.',
        iconCodePoint: 0xe3e3, // Icons.local_fire_department
        rarity: RelicRarity.rare,
        level: 0,
        effectType: RelicEffectType.feverDuration,
        baseBonus: 2.0, // +2 seconds
        bonusPerLevel: 2.0, // Up to +10s
      ),
      const RelicModel(
        id: 'relic_antimatter_replicator',
        name: 'Antimatter Replicator',
        description: 'Increases the probability of Lucky Fleet Clones on merge.',
        iconCodePoint: 0xe54d, // Icons.rocket_launch
        rarity: RelicRarity.legendary,
        level: 0,
        effectType: RelicEffectType.cloneChance,
        baseBonus: 0.08, // +8% Clone chance
        bonusPerLevel: 0.06, // Up to +32%
      ),
      const RelicModel(
        id: 'relic_dyson_sphere',
        name: 'Midas Dyson Sphere',
        description: 'Draws stellar energy to permanently multiply lap payouts.',
        iconCodePoint: 0xe3f7, // Icons.monetization_on
        rarity: RelicRarity.cosmic,
        level: 0,
        effectType: RelicEffectType.incomeBoost,
        baseBonus: 0.50, // +50% Cash
        bonusPerLevel: 0.50, // Up to +250%
      ),
      const RelicModel(
        id: 'relic_void_cannon',
        name: 'Void Aegis Cannon',
        description: 'Supercharges player orbital tap strikes against Alien Bosses.',
        iconCodePoint: 0xf1c6, // Icons.radar
        rarity: RelicRarity.epic,
        level: 0,
        effectType: RelicEffectType.bossTapDamage,
        baseBonus: 1.0, // +100% Tap Damage
        bonusPerLevel: 0.75, // Up to +400%
      ),
    ];
  }
}
