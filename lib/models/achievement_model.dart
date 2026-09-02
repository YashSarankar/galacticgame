enum AchievementCategory {
  merges,
  shipTier,
  bossDefeat,
  coinsEarned,
  wheelSpins,
  expeditions,
  prestige,
  relics,
}

/// A milestone achievement rewarding Dark Matter and special prizes
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final AchievementCategory category;
  final double targetValue;
  final double currentProgress;
  final double rewardDarkMatter;
  final double rewardCredits;
  final int rewardRelicShards;
  final bool isClaimed;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.category,
    required this.targetValue,
    this.currentProgress = 0.0,
    this.rewardDarkMatter = 0.0,
    this.rewardCredits = 0.0,
    this.rewardRelicShards = 0,
    this.isClaimed = false,
  });

  bool get isCompleted => currentProgress >= targetValue;
  bool get canClaim => isCompleted && !isClaimed;
  double get progressRatio => (currentProgress / targetValue).clamp(0.0, 1.0);

  AchievementModel copyWith({
    double? currentProgress,
    bool? isClaimed,
  }) {
    return AchievementModel(
      id: id,
      title: title,
      description: description,
      iconAsset: iconAsset,
      category: category,
      targetValue: targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      rewardDarkMatter: rewardDarkMatter,
      rewardCredits: rewardCredits,
      rewardRelicShards: rewardRelicShards,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'currentProgress': currentProgress,
        'isClaimed': isClaimed,
      };

  static List<AchievementModel> createInitialList() => [
        // 1. Merges
        const AchievementModel(
          id: 'merge_10',
          title: 'Apprentice Builder',
          description: 'Merge spacecraft 10 times.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/star_gold.png',
          category: AchievementCategory.merges,
          targetValue: 10,
          rewardDarkMatter: 5,
        ),
        const AchievementModel(
          id: 'merge_100',
          title: 'Master Shipwright',
          description: 'Merge spacecraft 100 times.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/things_gold.png',
          category: AchievementCategory.merges,
          targetValue: 100,
          rewardDarkMatter: 15,
        ),
        const AchievementModel(
          id: 'merge_500',
          title: 'Galactic Industrialist',
          description: 'Merge spacecraft 500 times.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/bolt_gold.png',
          category: AchievementCategory.merges,
          targetValue: 500,
          rewardDarkMatter: 40,
        ),

        // 2. Ship Tiers
        const AchievementModel(
          id: 'tier_5',
          title: 'Pulsar Corvette',
          description: 'Unlock your first Tier 5 Spacecraft.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip1_orange.png',
          category: AchievementCategory.shipTier,
          targetValue: 5,
          rewardDarkMatter: 10,
        ),
        const AchievementModel(
          id: 'tier_10',
          title: 'Nebula Dreadnought',
          description: 'Unlock your first Tier 10 Spacecraft.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip3_blue.png',
          category: AchievementCategory.shipTier,
          targetValue: 10,
          rewardDarkMatter: 25,
        ),
        const AchievementModel(
          id: 'tier_15',
          title: 'Cosmic Titan',
          description: 'Unlock a legendary Tier 15 Spacecraft.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip2_red.png',
          category: AchievementCategory.shipTier,
          targetValue: 15,
          rewardDarkMatter: 60,
        ),

        // 3. Boss Incursions
        const AchievementModel(
          id: 'boss_1',
          title: 'First Blood',
          description: 'Defeat your first Alien Dreadnought Boss.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyRed1.png',
          category: AchievementCategory.bossDefeat,
          targetValue: 1,
          rewardDarkMatter: 10,
        ),
        const AchievementModel(
          id: 'boss_5',
          title: 'Sector Defender',
          description: 'Defeat 5 Alien Dreadnought Bosses.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack2.png',
          category: AchievementCategory.bossDefeat,
          targetValue: 5,
          rewardDarkMatter: 25,
          rewardRelicShards: 5,
        ),
        const AchievementModel(
          id: 'boss_20',
          title: 'Alien Annihilator',
          description: 'Defeat 20 Alien Dreadnought Bosses.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyGreen3.png',
          category: AchievementCategory.bossDefeat,
          targetValue: 20,
          rewardDarkMatter: 75,
          rewardRelicShards: 15,
        ),

        // 4. Lifetime Coins
        const AchievementModel(
          id: 'coins_100k',
          title: 'Wealthy Merchant',
          description: 'Earn 100,000 Lifetime Coins.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/star_gold.png',
          category: AchievementCategory.coinsEarned,
          targetValue: 100000,
          rewardDarkMatter: 10,
        ),
        const AchievementModel(
          id: 'coins_1m',
          title: 'Cosmic Millionaire',
          description: 'Earn 1,000,000 Lifetime Coins.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/star_bronze.png',
          category: AchievementCategory.coinsEarned,
          targetValue: 1000000,
          rewardDarkMatter: 30,
        ),
        const AchievementModel(
          id: 'coins_100m',
          title: 'Galactic Tycoon',
          description: 'Earn 100,000,000 Lifetime Coins.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/star_silver.png',
          category: AchievementCategory.coinsEarned,
          targetValue: 100000000,
          rewardDarkMatter: 100,
        ),

        // 5. Wheel Spins
        const AchievementModel(
          id: 'spin_5',
          title: 'Lucky Gambler',
          description: 'Spin the Lucky Wheel 5 times.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/shield_gold.png',
          category: AchievementCategory.wheelSpins,
          targetValue: 5,
          rewardDarkMatter: 10,
        ),
        const AchievementModel(
          id: 'spin_25',
          title: 'High Roller',
          description: 'Spin the Lucky Wheel 25 times.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/shield_silver.png',
          category: AchievementCategory.wheelSpins,
          targetValue: 25,
          rewardDarkMatter: 35,
        ),

        // 6. Expeditions
        const AchievementModel(
          id: 'expedition_3',
          title: 'Space Pioneer',
          description: 'Complete 3 Deep Space Expeditions.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/pill_blue.png',
          category: AchievementCategory.expeditions,
          targetValue: 3,
          rewardDarkMatter: 10,
        ),
        const AchievementModel(
          id: 'expedition_15',
          title: 'Deep Space Admiral',
          description: 'Complete 15 Deep Space Expeditions.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/pill_red.png',
          category: AchievementCategory.expeditions,
          targetValue: 15,
          rewardDarkMatter: 40,
        ),

        // 7. Prestige & Relics
        const AchievementModel(
          id: 'prestige_1',
          title: 'Dimensional Reset',
          description: 'Perform your first Galactic Prestige Reset.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/powerupYellow_bolt.png',
          category: AchievementCategory.prestige,
          targetValue: 1,
          rewardDarkMatter: 25,
        ),
        const AchievementModel(
          id: 'prestige_5',
          title: 'Multiverse Traveler',
          description: 'Perform 5 Galactic Prestige Resets.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/powerupYellow_shield.png',
          category: AchievementCategory.prestige,
          targetValue: 5,
          rewardDarkMatter: 80,
        ),
        const AchievementModel(
          id: 'relic_1',
          title: 'Relic Seeker',
          description: 'Unlock or upgrade your first Ancient Relic.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/things_bronze.png',
          category: AchievementCategory.relics,
          targetValue: 1,
          rewardDarkMatter: 15,
        ),
        const AchievementModel(
          id: 'relic_4',
          title: 'Artifact Master',
          description: 'Unlock all 4 Ancient Relics in the Matrix.',
          iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/things_gold.png',
          category: AchievementCategory.relics,
          targetValue: 4,
          rewardDarkMatter: 50,
        ),
      ];
}
