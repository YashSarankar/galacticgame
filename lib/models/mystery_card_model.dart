import 'dart:math';

enum MysteryRewardType {
  coinSurge,
  crateAirdrop,
  darkMatterGems,
  droneOverdrive,
}

/// A surprise reward revealed from a Golden UFO 3-Card Pick
class MysteryCardReward {
  final MysteryRewardType type;
  final String title;
  final String description;
  final String iconAsset;
  final int colorValue;
  final double creditsValue;
  final double darkMatterValue;
  final int crateCount;
  final int crateTier;
  final int droneSeconds;

  const MysteryCardReward({
    required this.type,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.colorValue,
    this.creditsValue = 0.0,
    this.darkMatterValue = 0.0,
    this.crateCount = 0,
    this.crateTier = 1,
    this.droneSeconds = 0,
  });

  static List<MysteryCardReward> generateThreeCards({
    required double fleetIncomePerLap,
    required int highestTierUnlocked,
  }) {
    final Random random = Random();
    final List<MysteryCardReward> pool = [
      // 1. Coin Surge
      MysteryCardReward(
        type: MysteryRewardType.coinSurge,
        title: 'MEGA COIN SURGE!',
        description: 'Instant massive coin payout from all active ships.',
        iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/star_gold.png',
        colorValue: 0xFFFFD700,
        creditsValue: max(50.0, fleetIncomePerLap * 15.0),
      ),

      // 2. Crate Airdrop
      MysteryCardReward(
        type: MysteryRewardType.crateAirdrop,
        title: 'SUPPLY CRATE AIRDROP!',
        description: 'Spawns 4 mystery cargo boxes onto empty grid slots.',
        iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/pill_blue.png',
        colorValue: 0xFF00F0FF,
        crateCount: 4,
        crateTier: max(1, highestTierUnlocked - 2),
      ),

      // 3. Dark Matter Gems
      MysteryCardReward(
        type: MysteryRewardType.darkMatterGems,
        title: 'DARK MATTER CACHE!',
        description: 'Free Dark Matter Gems to unlock permanent upgrades.',
        iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/bolt_gold.png',
        colorValue: 0xFFBD00FF,
        darkMatterValue: 5.0 + random.nextInt(10),
      ),

      // 4. Drone Overdrive
      const MysteryCardReward(
        type: MysteryRewardType.droneOverdrive,
        title: 'AUTO-DRONE OVERDRIVE!',
        description: '60 Seconds of Free VIP Auto-Box Collector.',
        iconAsset: 'assets/kenney_space-shooter-remastered/PNG/ufoYellow.png',
        colorValue: 0xFF06D6A0,
        droneSeconds: 60,
      ),
    ];

    pool.shuffle(random);
    return pool.take(3).toList();
  }
}
