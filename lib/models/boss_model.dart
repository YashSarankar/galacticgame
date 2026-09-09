import 'dart:math';

/// Distinct alien dreadnought archetypes with unique combat behaviors
enum BossArchetype {
  juggernaut,
  shieldedTitan,
  swarmCarrier,
  voidPhantom,
}

/// Representation of an active Alien Boss Incursion event.
class BossModel {
  final String id;
  final String name;
  final String spriteAsset;
  final BossArchetype archetype;
  final double maxHealth;
  final double currentHealth;
  final double maxShieldHealth;
  final double currentShieldHealth;
  final double timeRemaining;
  final double bountyCredits;
  final double bountyDarkMatter;
  final bool isDefeated;
  final bool isActive;

  const BossModel({
    required this.id,
    required this.name,
    required this.spriteAsset,
    this.archetype = BossArchetype.juggernaut,
    required this.maxHealth,
    required this.currentHealth,
    this.maxShieldHealth = 0.0,
    this.currentShieldHealth = 0.0,
    required this.timeRemaining,
    required this.bountyCredits,
    required this.bountyDarkMatter,
    this.isDefeated = false,
    this.isActive = true,
  });

  bool get isDead => currentHealth <= 0.0;
  bool get hasShield => currentShieldHealth > 0.0;
  double get healthPercentage => (currentHealth / maxHealth).clamp(0.0, 1.0);
  double get shieldPercentage =>
      maxShieldHealth > 0.0 ? (currentShieldHealth / maxShieldHealth).clamp(0.0, 1.0) : 0.0;

  /// Regenerates kinetic shield over time up to maximum
  BossModel regenerateShield(double amount) {
    if (maxShieldHealth <= 0.0 || currentHealth <= 0.0) return this;
    final newShield = min(maxShieldHealth, currentShieldHealth + amount);
    return copyWith(currentShieldHealth: newShield);
  }

  /// Applies damage through kinetic shield first, then passes remaining to hull
  BossModel applyDamage(double damage) {
    if (currentShieldHealth > 0.0) {
      if (damage <= currentShieldHealth) {
        return copyWith(currentShieldHealth: currentShieldHealth - damage);
      } else {
        final remaining = damage - currentShieldHealth;
        final newHp = max(0.0, currentHealth - remaining);
        return copyWith(
          currentShieldHealth: 0.0,
          currentHealth: newHp,
          isDefeated: newHp <= 0.0,
        );
      }
    }

    final newHp = max(0.0, currentHealth - damage);
    return copyWith(
      currentHealth: newHp,
      isDefeated: newHp <= 0.0,
    );
  }

  factory BossModel.createForSector({
    required int sectorLevel,
    int highestTierUnlocked = 1,
    int totalBossesDefeated = 0,
    double baseIncomePerLap = 50.0,
  }) {
    const bossSprites = [
      'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyRed1.png',
      'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack3.png',
      'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue3.png',
      'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen3.png',
    ];
    const bossNames = [
      'Void Dreadnought Titan',
      'Crimson Swarm Carrier',
      'Hyperion Gatekeeper',
      'Antimatter Leviathan',
    ];

    // Effective Boss Level upgrades after every single boss victory!
    final int effectiveLevel = 1 +
        totalBossesDefeated +
        (sectorLevel - 1) * 2 +
        ((highestTierUnlocked - 1) ~/ 2);
    final index = (effectiveLevel - 1) % bossSprites.length;

    // Determine archetype based on level
    final archetypes = [
      BossArchetype.juggernaut,
      BossArchetype.shieldedTitan,
      BossArchetype.swarmCarrier,
      BossArchetype.voidPhantom,
    ];
    final archetype = archetypes[(effectiveLevel - 1) % archetypes.length];

    // HP scales exponentially after every boss defeat and tier unlock
    final double hp =
        (250.0 * pow(1.30, max(0, effectiveLevel - 1))).floorToDouble();
    // Every Dreadnought has a fortified Kinetic Energy Shield (40% of HP, 60% for Shielded Titans)
    final double shieldMultiplier =
        archetype == BossArchetype.shieldedTitan ? 0.60 : 0.40;
    final double shieldHp = (hp * shieldMultiplier).floorToDouble();
    final double credits =
        max(5000.0, baseIncomePerLap * 50.0 * pow(1.25, max(0, effectiveLevel - 1)));
    final double dm = 5.0 + (effectiveLevel * 2.5);

    return BossModel(
      id: 'boss_${DateTime.now().millisecondsSinceEpoch}',
      name: '${bossNames[index]} Mk.$effectiveLevel',
      spriteAsset: bossSprites[index],
      archetype: archetype,
      maxHealth: hp,
      currentHealth: hp,
      maxShieldHealth: shieldHp,
      currentShieldHealth: shieldHp,
      timeRemaining: 30.0,
      bountyCredits: credits,
      bountyDarkMatter: dm,
    );
  }

  BossModel copyWith({
    String? id,
    String? name,
    String? spriteAsset,
    BossArchetype? archetype,
    double? maxHealth,
    double? currentHealth,
    double? maxShieldHealth,
    double? currentShieldHealth,
    double? timeRemaining,
    double? bountyCredits,
    double? bountyDarkMatter,
    bool? isDefeated,
    bool? isActive,
  }) {
    return BossModel(
      id: id ?? this.id,
      name: name ?? this.name,
      spriteAsset: spriteAsset ?? this.spriteAsset,
      archetype: archetype ?? this.archetype,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      maxShieldHealth: maxShieldHealth ?? this.maxShieldHealth,
      currentShieldHealth: currentShieldHealth ?? this.currentShieldHealth,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      bountyCredits: bountyCredits ?? this.bountyCredits,
      bountyDarkMatter: bountyDarkMatter ?? this.bountyDarkMatter,
      isDefeated: isDefeated ?? this.isDefeated,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'spriteAsset': spriteAsset,
      'archetype': archetype.name,
      'maxHealth': maxHealth,
      'currentHealth': currentHealth,
      'maxShieldHealth': maxShieldHealth,
      'currentShieldHealth': currentShieldHealth,
      'timeRemaining': timeRemaining,
      'bountyCredits': bountyCredits,
      'bountyDarkMatter': bountyDarkMatter,
      'isDefeated': isDefeated,
      'isActive': isActive,
    };
  }

  factory BossModel.fromJson(Map<String, dynamic> json) {
    BossArchetype arch = BossArchetype.juggernaut;
    if (json['archetype'] != null) {
      arch = BossArchetype.values.firstWhere(
        (a) => a.name == json['archetype'],
        orElse: () => BossArchetype.juggernaut,
      );
    }

    return BossModel(
      id: json['id'] as String,
      name: json['name'] as String,
      spriteAsset: json['spriteAsset'] as String,
      archetype: arch,
      maxHealth: (json['maxHealth'] as num).toDouble(),
      currentHealth: (json['currentHealth'] as num).toDouble(),
      maxShieldHealth: (json['maxShieldHealth'] as num?)?.toDouble() ?? 0.0,
      currentShieldHealth: (json['currentShieldHealth'] as num?)?.toDouble() ?? 0.0,
      timeRemaining: (json['timeRemaining'] as num).toDouble(),
      bountyCredits: (json['bountyCredits'] as num).toDouble(),
      bountyDarkMatter: (json['bountyDarkMatter'] as num).toDouble(),
      isDefeated: json['isDefeated'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
