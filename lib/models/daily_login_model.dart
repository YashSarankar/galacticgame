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
      title: 'Free Coins Stash',
      description: '+1,500 Free Coins to get your fleet started.',
      creditsReward: 1500.0,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/star_gold.png',
      colorValue: 0xFFFFD700, // Gold
    ),
    DailyRewardDay(
      dayNumber: 2,
      title: 'Relic Shards Pack',
      description: '+3 Relic Shards to power up your permanent boosts.',
      relicShardsReward: 3,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/things_gold.png',
      colorValue: 0xFF00F0FF, // Cyan
    ),
    DailyRewardDay(
      dayNumber: 3,
      title: 'Dark Matter Gems',
      description: '+5 Dark Matter Gems to unlock permanent tech.',
      darkMatterReward: 5.0,
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
      title: 'Free Tier 3 Ship',
      description: '+1 Free Tier 3 Ship delivery box ready on your grid.',
      bonusTierCrate: 3,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip1_orange.png',
      colorValue: 0xFFFFB703, // Amber
    ),
    DailyRewardDay(
      dayNumber: 6,
      title: 'Dark Matter Mega Pouch',
      description: '+15 Dark Matter Gems for huge upgrades.',
      darkMatterReward: 15.0,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/powerupYellow_bolt.png',
      colorValue: 0xFFBD00FF, // Neon Magenta
    ),
    DailyRewardDay(
      dayNumber: 7,
      title: 'Day 7 Mega Jackpot!',
      description: '+25K Coins • +25 Dark Matter • +10 Shards • Tier 5 Ship • 2 Spins!',
      creditsReward: 25000.0,
      darkMatterReward: 25.0,
      relicShardsReward: 10,
      bonusTierCrate: 5,
      extraSpins: 2,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/playerShip3_blue.png',
      colorValue: 0xFFFF0055, // Crimson Red
    ),
  ];


}
