enum StoreCategory {
  timeWarp,
  darkMatter,
  permanentBooster,
  vipDrone,
  iapVault,
}

/// An item available for purchase in the In-Game Cosmic Store & Black Market
class StoreItem {
  final String id;
  final String title;
  final String description;
  final StoreCategory category;
  final double costCredits;
  final double costDarkMatter;
  final bool isAdRewarded;
  final bool isIap;
  final String? iapSku;
  final String? iapFallbackPrice;
  final String iconAsset;
  final int colorValue;

  // Custom properties
  final int warpDurationHours;
  final double grantedDarkMatter;
  final double grantedCredits;
  final double incomeMultiplierBonus;
  final double speedMultiplierBonus;
  final int droneRentalDurationMinutes;

  const StoreItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.costCredits = 0.0,
    this.costDarkMatter = 0.0,
    this.isAdRewarded = false,
    this.isIap = false,
    this.iapSku,
    this.iapFallbackPrice,
    required this.iconAsset,
    required this.colorValue,
    this.warpDurationHours = 0,
    this.grantedDarkMatter = 0.0,
    this.grantedCredits = 0.0,
    this.incomeMultiplierBonus = 0.0,
    this.speedMultiplierBonus = 0.0,
    this.droneRentalDurationMinutes = 0,
  });

  static const List<StoreItem> catalog = [
    // 1. Time Warps (Skip Time)
    StoreItem(
      id: 'warp_1h',
      title: '1 Hour Fast Forward',
      description: 'Instantly collect 1 hour of free coins from your active fleet.',
      category: StoreCategory.timeWarp,
      isAdRewarded: true,
      warpDurationHours: 1,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/pill_blue.png',
      colorValue: 0xFF00F0FF, // Cyan
    ),
    StoreItem(
      id: 'warp_4h',
      title: '4 Hours Fast Forward',
      description: 'Instantly collect 4 hours of massive coin income right now.',
      category: StoreCategory.timeWarp,
      costDarkMatter: 35.0,
      warpDurationHours: 4,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/pill_yellow.png',
      colorValue: 0xFFFFD700, // Gold
    ),
    StoreItem(
      id: 'warp_12h',
      title: '12 Hours Fast Forward',
      description: 'Massive skip: Instantly get half a day of huge coin earnings.',
      category: StoreCategory.timeWarp,
      costDarkMatter: 90.0,
      warpDurationHours: 12,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/pill_red.png',
      colorValue: 0xFFFF0055, // Crimson
    ),
    StoreItem(
      id: 'warp_24h',
      title: '24 Hours Hyper Warp',
      description: 'Ultimate skip: Collect a full 24 hours of maximum circuit revenue.',
      category: StoreCategory.timeWarp,
      costDarkMatter: 160.0,
      warpDurationHours: 24,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/star_gold.png',
      colorValue: 0xFFBD00FF, // Purple
    ),

    // 2. Dark Matter Conversion & IAP Packs
    StoreItem(
      id: 'dm_cache_soft',
      title: 'Dark Matter Cache (15 DM)',
      description: 'Exchange 1,000,000 Coins into 15 Dark Matter Gems for tech research.',
      category: StoreCategory.darkMatter,
      costCredits: 1000000.0,
      grantedDarkMatter: 15.0,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/bolt_gold.png',
      colorValue: 0xFF9D4EDD, // Purple
    ),
    StoreItem(
      id: 'dm_cache_large',
      title: 'Singularity Core (100 DM)',
      description: 'Exchange 10,000,000 Coins into 100 Dark Matter Gems.',
      category: StoreCategory.darkMatter,
      costCredits: 10000000.0,
      grantedDarkMatter: 100.0,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/things_gold.png',
      colorValue: 0xFF00F0FF, // Cyan
    ),
    StoreItem(
      id: 'iap_dm_100',
      title: 'Dark Matter Stash (100 DM)',
      description: 'Official Google Play pack: Instantly grants 100 Dark Matter Gems.',
      category: StoreCategory.darkMatter,
      isIap: true,
      iapSku: 'dm_pack_small',
      iapFallbackPrice: '₹99.00',
      grantedDarkMatter: 100.0,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/star_gold.png',
      colorValue: 0xFFFFD700, // Gold
    ),
    StoreItem(
      id: 'iap_dm_500',
      title: 'Dark Matter Vault (500 DM)',
      description: 'Official Google Play pack: Best value 500 Dark Matter bundle.',
      category: StoreCategory.darkMatter,
      isIap: true,
      iapSku: 'dm_pack_medium',
      iapFallbackPrice: '₹399.00',
      grantedDarkMatter: 500.0,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/powerupYellow_star.png',
      colorValue: 0xFFBD00FF, // Purple
    ),
    StoreItem(
      id: 'iap_dm_1500',
      title: 'Singularity Armada (1,500 DM)',
      description: 'Official Google Play pack: Ultimate mega cache of 1,500 Dark Matter.',
      category: StoreCategory.darkMatter,
      isIap: true,
      iapSku: 'dm_pack_large',
      iapFallbackPrice: '₹999.00',
      grantedDarkMatter: 1500.0,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/bolt_gold.png',
      colorValue: 0xFFFF0055, // Crimson
    ),

    // 3. VIP Auto-Bot Support Drone
    StoreItem(
      id: 'drone_rental_ad',
      title: 'Auto-Open Drone (30 Min Free)',
      description: 'Helper drone automatically opens all dropped delivery boxes for you!',
      category: StoreCategory.vipDrone,
      isAdRewarded: true,
      droneRentalDurationMinutes: 30,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/ufoYellow.png',
      colorValue: 0xFF06D6A0, // Emerald Green
    ),
    StoreItem(
      id: 'drone_permanent',
      title: 'Auto-Open Drone (Permanent)',
      description: 'Helper drone permanently opens every single delivery box automatically.',
      category: StoreCategory.vipDrone,
      costDarkMatter: 150.0,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/ufoRed.png',
      colorValue: 0xFFFF0055, // Crimson Red
    ),

    // 4. Permanent Fleet Boosters
    StoreItem(
      id: 'perm_quantum_overdrive',
      title: 'Permanent +50% Coins Boost',
      description: 'Permanently increases all ship coin earnings by +50% forever.',
      category: StoreCategory.permanentBooster,
      costDarkMatter: 200.0,
      incomeMultiplierBonus: 0.50,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/star_gold.png',
      colorValue: 0xFFFFD700, // Gold
    ),
    StoreItem(
      id: 'perm_sublight_thrusters',
      title: 'Permanent +25% Speed Boost',
      description: 'Permanently makes all your ships fly +25% faster on the track.',
      category: StoreCategory.permanentBooster,
      costDarkMatter: 150.0,
      speedMultiplierBonus: 0.25,
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Effects/fire08.png',
      colorValue: 0xFF00F0FF, // Cyan
    ),
  ];
}
