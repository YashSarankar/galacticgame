import 'dart:math';

/// Representation of an active Alien Boss Incursion event.
class BossModel {
  final String id;
  final String name;
  final String spriteAsset;
  final double maxHealth;
  final double currentHealth;
  final double timeRemaining;
  final double bountyCredits;
  final double bountyDarkMatter;
  final bool isDefeated;
  final bool isActive;

  const BossModel({
    required this.id,
    required this.name,
    required this.spriteAsset,
    required this.maxHealth,
    required this.currentHealth,
    required this.timeRemaining,
    required this.bountyCredits,
    required this.bountyDarkMatter,
    this.isDefeated = false,
    this.isActive = true,
  });

  bool get isDead => currentHealth <= 0.0;
  double get healthPercentage => (currentHealth / maxHealth).clamp(0.0, 1.0);

  factory BossModel.createForSector({
    required int sectorLevel,
    int highestTierUnlocked = 1,
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

    final int effectiveLevel =
        max(1, sectorLevel + ((highestTierUnlocked - 1) ~/ 2));
    final index = (effectiveLevel - 1) % bossSprites.length;

    // HP scales progressively with sector progression and spacecraft tier
    final double hp = 300.0 * pow(1.35, max(0, effectiveLevel - 1)).toDouble();
    final double credits = max(5000.0, baseIncomePerLap * 50.0);
    final double dm = 5.0 + (effectiveLevel * 3.0);

    return BossModel(
      id: 'boss_${DateTime.now().millisecondsSinceEpoch}',
      name: '${bossNames[index]} Mk.$effectiveLevel',
      spriteAsset: bossSprites[index],
      maxHealth: hp,
      currentHealth: hp,
      timeRemaining: 30.0,
      bountyCredits: credits,
      bountyDarkMatter: dm,
    );
  }


  BossModel copyWith({
    String? id,
    String? name,
    String? spriteAsset,
    double? maxHealth,
    double? currentHealth,
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
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
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
      'maxHealth': maxHealth,
      'currentHealth': currentHealth,
      'timeRemaining': timeRemaining,
      'bountyCredits': bountyCredits,
      'bountyDarkMatter': bountyDarkMatter,
      'isDefeated': isDefeated,
      'isActive': isActive,
    };
  }

  factory BossModel.fromJson(Map<String, dynamic> json) {
    return BossModel(
      id: json['id'] as String,
      name: json['name'] as String,
      spriteAsset: json['spriteAsset'] as String,
      maxHealth: (json['maxHealth'] as num).toDouble(),
      currentHealth: (json['currentHealth'] as num).toDouble(),
      timeRemaining: (json['timeRemaining'] as num).toDouble(),
      bountyCredits: (json['bountyCredits'] as num).toDouble(),
      bountyDarkMatter: (json['bountyDarkMatter'] as num).toDouble(),
      isDefeated: json['isDefeated'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
