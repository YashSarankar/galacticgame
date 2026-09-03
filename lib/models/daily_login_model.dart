/// Definition of a single day's reward in the 7-Day Commander Calendar
class DailyRewardDay {
  final int dayNumber; // 1 to 7
  final String title;
  final String description;
  final double creditsReward;
  final double darkMatterReward;
  final int relicShardsReward;
  final int bonusTierCrate;
  final int extraSpins;
  final String iconAsset;
  final int colorValue;

  const DailyRewardDay({
    required this.dayNumber,
    required this.title,
    required this.description,
    this.creditsReward = 0.0,
    this.darkMatterReward = 0.0,
    this.relicShardsReward = 0,
    this.bonusTierCrate = 0,
    this.extraSpins = 0,
    required this.iconAsset,
    required this.colorValue,
  });

  static const List<DailyRewardDay> schedule = [
    DailyRewardDay(
      dayNumber: 1,
      title: 'Cadet Coins Stash',
      description: '+150 Free Coins to boost your hangar fleet.',
      creditsReward: 150.0,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/star_gold.png',
      colorValue: 0xFFFFD700, // Gold
    ),
    DailyRewardDay(
      dayNumber: 2,
      title: 'Relic Shards Pack',
      description: '+2 Relic Shards to power up permanent boosts.',
      relicShardsReward: 2,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/things_gold.png',
      colorValue: 0xFF00F0FF, // Cyan
    ),
    DailyRewardDay(
      dayNumber: 3,
      title: 'Dark Matter Gems',
      description: '+3 Dark Matter Gems for high-tech research.',
      darkMatterReward: 3.0,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/bolt_gold.png',
      colorValue: 0xFF9D4EDD, // Purple
    ),
    DailyRewardDay(
      dayNumber: 4,
      title: 'Lucky Wheel Spin',
      description: '+1 Free Spin for the Lucky Spin Wheel.',
      extraSpins: 1,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/shield_gold.png',
      colorValue: 0xFF06D6A0, // Emerald Green
    ),
    DailyRewardDay(
      dayNumber: 5,
      title: 'Free Tier 2 Ship',
      description: '+1 Free Tier 2 Ship delivery box on your grid.',
      bonusTierCrate: 2,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip1_orange.png',
      colorValue: 0xFFFFB703, // Amber
    ),
    DailyRewardDay(
      dayNumber: 6,
      title: 'Dark Matter Pouch',
      description: '+5 Dark Matter Gems for engine upgrades.',
      darkMatterReward: 5.0,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/powerupYellow_bolt.png',
      colorValue: 0xFFBD00FF, // Neon Magenta
    ),
    DailyRewardDay(
      dayNumber: 7,
      title: 'Day 7 Mega Jackpot!',
      description: '+1.5K Coins • +10 Dark Matter • +5 Shards • Tier 3 Ship • 1 Spin!',
      creditsReward: 1500.0,
      darkMatterReward: 10.0,
      relicShardsReward: 5,
      bonusTierCrate: 3,
      extraSpins: 1,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip3_blue.png',
      colorValue: 0xFFFF0055, // Crimson Red
    ),
  ];


}
