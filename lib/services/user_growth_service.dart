import 'package:flutter/material.dart';
import '../models/game_state.dart';

/// Game Features progressively unlocked across the Commander Learning Arc
enum GameFeature {
  fleetSpeedUpgrade,
  codex,
  dailyCalendar,
  autoSort,
  multiLaserGates,
  hyperPads,
  roulette,
  autoMerge,
  techTree,
  trackEvolution,
  achievements,
  bossBeacon,
  relics,
  expeditions,
  cosmicStore,
  prestige,
}

/// Metadata for a Commander Rank
class CommanderRankInfo {
  final int rank;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int requiredTier;

  const CommanderRankInfo({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.requiredTier,
  });
}

/// Feature metadata describing unlocked systems with comprehensive "How It Works" instructions
class UnlockedFeatureInfo {
  final GameFeature feature;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int requiredTier;
  final String category;
  final String howItWorks;
  final List<String> steps;
  final String proTip;
  final String location;
  final String actionLabel;

  const UnlockedFeatureInfo({
    required this.feature,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredTier,
    this.category = 'System Protocol',
    this.howItWorks = '',
    this.steps = const [],
    this.proTip = '',
    this.location = 'Command Hub',
    this.actionLabel = 'VIEW SYSTEM',
  });
}

/// A guided milestone quest in the Commander Learning Arc
class LearningMilestoneQuest {
  final int id;
  final String title;
  final String objective;
  final IconData icon;
  final double rewardCredits;
  final double rewardDarkMatter;
  final bool Function(GameState state) checkCompleted;

  const LearningMilestoneQuest({
    required this.id,
    required this.title,
    required this.objective,
    required this.icon,
    required this.rewardCredits,
    required this.rewardDarkMatter,
    required this.checkCompleted,
  });
}

/// Service managing the progressive feature unlock gates & learning arc
class UserGrowthService {
  static final UserGrowthService _instance = UserGrowthService._internal();
  factory UserGrowthService() => _instance;
  UserGrowthService._internal();

  /// 13 Progressive Commander Ranks across the 16-Tier spacecraft progression arc
  static const List<CommanderRankInfo> ranks = [
    CommanderRankInfo(
      rank: 1,
      title: 'Novice Cadet',
      subtitle: 'Flight School & Fundamental Fleet Mechanics',
      icon: Icons.school_rounded,
      color: Color(0xFF00F0FF),
      requiredTier: 1,
    ),
    CommanderRankInfo(
      rank: 2,
      title: 'Space Scout',
      subtitle: 'Fleet Encyclopedia & Spacecraft Lore',
      icon: Icons.explore_rounded,
      color: Color(0xFF06D6A0),
      requiredTier: 2,
    ),
    CommanderRankInfo(
      rank: 3,
      title: 'Flight Officer',
      subtitle: 'Daily Transmissions & Bay Organization',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF00FF88),
      requiredTier: 3,
    ),
    CommanderRankInfo(
      rank: 4,
      title: 'Fleet Navigator',
      subtitle: 'Multi-Checkpoint Finish Gates & Lap Payouts',
      icon: Icons.flag_rounded,
      color: Color(0xFFFFB703),
      requiredTier: 4,
    ),
    CommanderRankInfo(
      rank: 5,
      title: 'Operations Specialist',
      subtitle: 'Hyper-Pads & Wormhole Singularity Roulette',
      icon: Icons.blur_circular_rounded,
      color: Color(0xFF9D4EDD),
      requiredTier: 5,
    ),
    CommanderRankInfo(
      rank: 6,
      title: 'Flight Captain',
      subtitle: 'Automated Merge Logistics Superpower',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFFD700),
      requiredTier: 6,
    ),
    CommanderRankInfo(
      rank: 7,
      title: 'Quantum Engineer',
      subtitle: 'Quantum Matrices & Dark Matter Tech Tree',
      icon: Icons.memory_rounded,
      color: Color(0xFFBD00FF),
      requiredTier: 7,
    ),
    CommanderRankInfo(
      rank: 8,
      title: 'Battle Commander',
      subtitle: 'Advanced Track Circuit Geometric Evolution',
      icon: Icons.shape_line_rounded,
      color: Color(0xFFFF5500),
      requiredTier: 8,
    ),
    CommanderRankInfo(
      rank: 9,
      title: 'Fleet Vanguard',
      subtitle: 'Galactic Career Trophies & High Honors',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFFFD700),
      requiredTier: 9,
    ),
    CommanderRankInfo(
      rank: 10,
      title: 'Starfleet Marshal',
      subtitle: 'Alien Dreadnought Boss Incursion Warfare',
      icon: Icons.radar_rounded,
      color: Color(0xFFFF0055),
      requiredTier: 10,
    ),
    CommanderRankInfo(
      rank: 11,
      title: 'Galactic Archaeologist',
      subtitle: 'Ancient Relics Vault & Deep Space Sorties',
      icon: Icons.stars_rounded,
      color: Color(0xFF7000FF),
      requiredTier: 11,
    ),
    CommanderRankInfo(
      rank: 12,
      title: 'Cosmic Admiral',
      subtitle: 'VIP Warps & Autonomous Drone Licensing',
      icon: Icons.storefront_rounded,
      color: Color(0xFFFF9900),
      requiredTier: 12,
    ),
    CommanderRankInfo(
      rank: 13,
      title: 'Galactic Overlord',
      subtitle: 'Trans-Dimensional Singularity & Prestige Mastery',
      icon: Icons.all_inclusive_rounded,
      color: Color(0xFFFFD700),
      requiredTier: 13,
    ),
  ];

  /// Gets current commander rank info based on highest tier
  static CommanderRankInfo getCommanderRank(int highestTier) {
    for (int i = ranks.length - 1; i >= 0; i--) {
      if (highestTier >= ranks[i].requiredTier) {
        return ranks[i];
      }
    }
    return ranks[0];
  }

  /// Gets minimum spacecraft tier required to unlock a specific feature
  static int getRequiredTier(GameFeature feature) {
    switch (feature) {
      case GameFeature.fleetSpeedUpgrade:
        return 1; // Tier 1 (Core engineering)
      case GameFeature.codex:
        return 2; // Tier 2 (Discovered 2nd ship, unlocked encyclopedia)
      case GameFeature.dailyCalendar:
      case GameFeature.autoSort:
        return 3; // Tier 3 (Daily habits & hangar organization)
      case GameFeature.multiLaserGates:
        return 4; // Tier 4 (Multi-gate circuit payouts)
      case GameFeature.hyperPads:
      case GameFeature.roulette:
        return 5; // Tier 5 (Speed pads & lucky wheel)
      case GameFeature.autoMerge:
        return 6; // Tier 6 (Earned Auto-Merge Superpower)
      case GameFeature.techTree:
        return 7; // Tier 7 (Dark Matter Tech Tree)
      case GameFeature.trackEvolution:
        return 8; // Tier 8 (Track Evolution into figure-8 & pulsar)
      case GameFeature.achievements:
        return 9; // Tier 9 (Milestone Trophies)
      case GameFeature.bossBeacon:
        return 10; // Tier 10 (Boss Incursions)
      case GameFeature.relics:
      case GameFeature.expeditions:
        return 11; // Tier 11 (Relics & Constellation Expeditions)
      case GameFeature.cosmicStore:
        return 12; // Tier 12 (Cosmic VIP Store)
      case GameFeature.prestige:
        return 13; // Tier 13 (Galactic Prestige Reset or 5M lifetime credits)
    }
  }

  /// Checks if a feature is unlocked based on highest tier and lifetime earnings
  static bool isFeatureUnlocked(
    GameFeature feature, {
    required int highestTier,
    double lifetimeCredits = 0.0,
  }) {
    if (feature == GameFeature.prestige && lifetimeCredits >= 5000000.0) {
      return true;
    }
    return highestTier >= getRequiredTier(feature);
  }

  /// Returns comprehensive metadata and "How It Works" breakdown for every feature
  static UnlockedFeatureInfo getFeatureInfo(GameFeature feature) {
    switch (feature) {
      case GameFeature.fleetSpeedUpgrade:
        return const UnlockedFeatureInfo(
          feature: GameFeature.fleetSpeedUpgrade,
          title: 'Fleet Engine Tuning',
          category: 'Circuit Engineering',
          description: 'Upgrade the core propulsion engines of all flying spacecraft for faster lap completions.',
          icon: Icons.speed_rounded,
          color: Color(0xFF00F0FF),
          requiredTier: 1,
          location: 'Circuit Engineering Bar (Under Racetrack)',
          actionLabel: 'UPGRADE ENGINES',
          howItWorks:
              'Engine tuning increases the velocity of every spaceship currently racing on the track, drastically reducing lap times.',
          steps: [
            'Locate the "ENGINE SPEED" button on the engineering strip under the racetrack.',
            'Spend Credits to purchase the next engine velocity upgrade.',
            'Watch all active ships immediately accelerate and trigger lap payouts more frequently!',
          ],
          proTip:
              'Upgrading engine speed multiplies the effective income of ALL active track ships simultaneously!',
        );

      case GameFeature.codex:
        return const UnlockedFeatureInfo(
          feature: GameFeature.codex,
          title: 'Spacecraft Codex',
          category: 'Fleet Intelligence',
          description: 'Access the 16-Tier interstellar encyclopedia with full 3D stats, lore, and income multipliers.',
          icon: Icons.menu_book_rounded,
          color: Color(0xFF00FF88),
          requiredTier: 2,
          location: 'Command Hub > Fleet Intelligence',
          actionLabel: 'OPEN CODEX',
          howItWorks:
              'The Codex catalogs every spaceship discovered in the galaxy, previewing higher-tier stats, weapon damage, and lore.',
          steps: [
            'Tap the Command Hub (radar icon) at top-right and select "Ship Collection".',
            'Browse discovered and silhouette classified spacecraft across Tiers 1 through 16.',
            'Inspect base speed, lap payout values, and laser strike damage for each tier.',
          ],
          proTip:
              'Each newly discovered ship provides permanent milestone rewards in the Milestone Trophies vault!',
        );

      case GameFeature.dailyCalendar:
        return const UnlockedFeatureInfo(
          feature: GameFeature.dailyCalendar,
          title: 'Daily Supply Transmissions',
          category: 'Daily Rewards',
          description: 'Claim free daily supply crates, Dark Matter gems, and rare relic shards every 24 hours.',
          icon: Icons.calendar_month_rounded,
          color: Color(0xFFFFD700),
          requiredTier: 3,
          location: 'Command Hub > Free Gifts & Shop',
          actionLabel: 'CLAIM GIFTS',
          howItWorks:
              'High Command broadcasts daily supply drops to your fleet base. Logging in every day escalates your consecutive reward streak.',
          steps: [
            'Check the Daily Calendar in the Command Hub or startup popup each day.',
            'Tap the glowing daily crate to claim free Credits, Gems, and Speed Boosters.',
            'Maintain a 7-day streak to unlock massive Day 7 legendary supply crates!',
          ],
          proTip:
              'Use the 2X Ad Bonus on Day 7 to double your legendary Dark Matter gem yield!',
        );

      case GameFeature.autoSort:
        return const UnlockedFeatureInfo(
          feature: GameFeature.autoSort,
          title: 'Fleet Auto-Sort',
          category: 'Hangar Automation',
          description: 'Neatly reorganizes your hangar grid by descending tier and groups matching pairs together.',
          icon: Icons.sort_rounded,
          color: Color(0xFF00F0FF),
          requiredTier: 3,
          location: 'Bottom Control Bar ("SORT" Button)',
          actionLabel: 'SORT HANGAR',
          howItWorks:
              'Auto-Sort scans your entire hangar grid, arranges ships from highest to lowest tier, and places matching pairs side-by-side.',
          steps: [
            'When your hangar bays get cluttered with mixed tiers, tap the cyan "SORT" button on the bottom bar.',
            'Ships will instantly slide into orderly, optimized positions.',
            'Easily merge adjacent matching ships without searching through cluttered slots.',
          ],
          proTip:
              'Tap SORT right after opening a batch of mystery crates to quickly spot all potential merges!',
        );

      case GameFeature.multiLaserGates:
        return const UnlockedFeatureInfo(
          feature: GameFeature.multiLaserGates,
          title: 'Multi-Laser Finish Gates',
          category: 'Circuit Engineering',
          description: 'Construct up to 4 laser gates across the racetrack, multiplying earnings per completed lap.',
          icon: Icons.flag_rounded,
          color: Color(0xFFFFD700),
          requiredTier: 4,
          location: 'Circuit Engineering Bar ("+ GATE" Button)',
          actionLabel: 'BUILD GATE',
          howItWorks:
              'Adding secondary and tertiary laser checkpoint gates means your ships earn payout credits multiple times in a single loop!',
          steps: [
            'Find the "+ GATE" upgrade button on the circuit engineering bar under the racetrack.',
            'Purchase additional laser gates (up to 4 total gates across the track).',
            'Ships will trigger full crossing payouts at every single gate they pass through!',
          ],
          proTip:
              '4 Laser Gates quadruples your fleet earnings rate without needing any extra track ships!',
        );

      case GameFeature.hyperPads:
        return const UnlockedFeatureInfo(
          feature: GameFeature.hyperPads,
          title: 'On-Track Hyper-Pads',
          category: 'Circuit Engineering',
          description: 'Install neon acceleration pads on circuit corners for supersonic nitro speed bursts.',
          icon: Icons.rocket_launch_rounded,
          color: Color(0xFF9D4EDD),
          requiredTier: 5,
          location: 'Circuit Engineering Bar ("+ PAD" Button)',
          actionLabel: 'UPGRADE PADS',
          howItWorks:
              'Hyper-Pads are positioned at track curves. When any ship glides over a pad, it launches forward with explosive neon velocity.',
          steps: [
            'Tap the purple "HYPER PAD" button on the engineering strip to unlock and level up pads.',
            'Watch neon pads ignite across the track corners.',
            'Higher pad levels give stronger launch speed multipliers and longer boost durations.',
          ],
          proTip:
              'Combine Hyper-Pads with Fleet Speed upgrades for blistering multi-gate credit cascades!',
        );

      case GameFeature.roulette:
        return const UnlockedFeatureInfo(
          feature: GameFeature.roulette,
          title: 'Wormhole Singularity Roulette',
          category: 'Singularity Luck',
          description: 'Spin the spatial singularity wheel for instant jackpot credit, gem, and boost bounties.',
          icon: Icons.blur_circular_rounded,
          color: Color(0xFF00F5FF),
          requiredTier: 5,
          location: 'Command Hub > Free Gifts & Shop',
          actionLabel: 'SPIN WHEEL',
          howItWorks:
              'The Singularity Wheel channels cosmic energy into random jackpot rewards including massive credit caches and Dark Matter.',
          steps: [
            'Open Wormhole Roulette via the Command Hub or when the free spin alert appears.',
            'Tap "SPIN" to start the high-speed orbital wheel.',
            'Claim your jackpot reward instantly, or watch a transmission to spin again!',
          ],
          proTip:
              'Spinning during a Comet Rush or Warp event multiplies credit rewards based on your boosted earning rate!',
        );

      case GameFeature.autoMerge:
        return const UnlockedFeatureInfo(
          feature: GameFeature.autoMerge,
          title: 'Auto-Merge Logistics',
          category: 'Hangar Automation',
          description: 'Instantly merges all matching spaceship pairs across your hangar bays with a single tap!',
          icon: Icons.auto_awesome_rounded,
          color: Color(0xFFFFD700),
          requiredTier: 6,
          location: 'Bottom Control Bar ("AUTO" Button)',
          actionLabel: 'TRY AUTO-MERGE',
          howItWorks:
              'Auto-Merge is the ultimate fleet management superpower! It scans all grid bays and fuses identical ships in rapid cascade.',
          steps: [
            'Fill your empty hangar slots by tapping the "BUY SHIP" button or unboxing delivery crates.',
            'Tap the golden "AUTO" button on the bottom bar.',
            'All identical pairs merge in a satisfying combo chain, granting instant combo bonus credits!',
          ],
          proTip:
              'Fill all 12 bays before tapping AUTO to chain massive 5X+ Merge Combos and score huge credit bonuses!',
        );

      case GameFeature.techTree:
        return const UnlockedFeatureInfo(
          feature: GameFeature.techTree,
          title: 'Quantum Tech Tree',
          category: 'Quantum Research',
          description: 'Invest Dark Matter gems into permanent tech nodes for speed, discount rates, and lucky clones.',
          icon: Icons.account_tree_rounded,
          color: Color(0xFFBD00FF),
          requiredTier: 7,
          location: 'Command Hub > Upgrades & Trophies',
          actionLabel: 'OPEN TECH TREE',
          howItWorks:
              'The Quantum Matrix contains branching research specializations powered by Dark Matter crystals that permanently buff your fleet.',
          steps: [
            'Access "Super Upgrades" from the Command Hub.',
            'Choose between Fleet Velocity, Income Multipliers, Buy Discounts, or Lucky Merge Clones.',
            'Spend Dark Matter to permanently activate and level up powerful research perks.',
          ],
          proTip:
              'Prioritize "Quantum Economy" and "Lucky Clone" early to double high-tier ship generation for free!',
        );

      case GameFeature.trackEvolution:
        return const UnlockedFeatureInfo(
          feature: GameFeature.trackEvolution,
          title: 'Track Circuit Evolution',
          category: 'Track Engineering',
          description: 'Ascend your racetrack into complex figure-8 and pulsar geometries with permanent multipliers!',
          icon: Icons.shape_line_rounded,
          color: Color(0xFFFF5500),
          requiredTier: 8,
          location: 'Track Evolution Button (Racetrack Center)',
          actionLabel: 'EVOLVE TRACK',
          howItWorks:
              'Circuit Evolution reconstructs the spatial track curve into advanced geometries (e.g. Figure-8 Infinity, Pulsar Spiral) with higher base multipliers.',
          steps: [
            'Amass sufficient Credits to meet the Track Evolution threshold.',
            'Tap the glowing Track Evolution emblem in the center of the racetrack.',
            'Watch the circuit transform with neon particle fireworks and enjoy a permanent global income multiplier!',
          ],
          proTip:
              'Higher track tiers provide wider flight paths and extra checkpoint slots for maximum efficiency!',
        );

      case GameFeature.achievements:
        return const UnlockedFeatureInfo(
          feature: GameFeature.achievements,
          title: 'Milestone Trophies',
          category: 'Career & Honors',
          description: 'Complete lifetime career objectives to claim massive Dark Matter gem bounties and prestige medals.',
          icon: Icons.emoji_events_rounded,
          color: Color(0xFFFFD700),
          requiredTier: 9,
          location: 'Command Hub > Upgrades & Trophies',
          actionLabel: 'VIEW TROPHIES',
          howItWorks:
              'Milestone Trophies track your lifetime galactic achievements—total merges, bosses vanquished, credits earned, and high tiers reached.',
          steps: [
            'Open "Trophies" from the Command Hub.',
            'Review active milestones and their requirements.',
            'Tap "CLAIM" on completed achievements to collect rich Dark Matter rewards!',
          ],
          proTip:
              'Save your milestone Dark Matter rewards to unlock high-level Quantum Tech nodes and Relic slots!',
        );

      case GameFeature.bossBeacon:
        return const UnlockedFeatureInfo(
          feature: GameFeature.bossBeacon,
          title: 'Alien Dreadnought Beacon',
          category: 'Galactic Warfare',
          description: 'Summon titanic alien bosses. Your fleet fires automatic laser strikes for massive bounties.',
          icon: Icons.radar_rounded,
          color: Color(0xFFFF0055),
          requiredTier: 10,
          location: 'Command Hub > Boss Battle (or Battle Beacon)',
          actionLabel: 'SUMMON BOSS',
          howItWorks:
              'Activating the Battle Beacon attracts colossal alien dreadnoughts into sector orbit. Active track ships automatically unleash laser salvos each lap!',
          steps: [
            'Summon an alien boss via the Command Hub "Boss Battle" portal.',
            'Deploy your highest-tier ships onto the track to maximize laser strike DPS.',
            'Tap the screen to fire manual orbital cannons and vanquish the boss before the timer expires to claim epic loot!',
          ],
          proTip:
              'Higher tier ships deal exponentially higher laser strike damage. Keep your best ships on track during boss fights!',
        );

      case GameFeature.relics:
        return const UnlockedFeatureInfo(
          feature: GameFeature.relics,
          title: 'Ancient Relics Vault',
          category: 'Alien Archaeology',
          description: 'Socket mysterious alien artifacts into your command matrix for permanent game-changing multipliers.',
          icon: Icons.auto_awesome_rounded,
          color: Color(0xFFBD00FF),
          requiredTier: 11,
          location: 'Command Hub > Artifacts Vault',
          actionLabel: 'VIEW RELICS',
          howItWorks:
              'Relics are legendary artifacts discovered from deep space expeditions. Socketing them provides massive passive multipliers to speed, crit chance, and earnings.',
          steps: [
            'Open the "Artifacts Vault" from the Command Hub.',
            'Socket discovered relics into available artifact resonance slots.',
            'Level up relics using Relic Shards collected from Constellation Expeditions.',
          ],
          proTip:
              'Relic bonuses persist through Galactic Prestige resets, giving you a massive head start on subsequent runs!',
        );

      case GameFeature.expeditions:
        return const UnlockedFeatureInfo(
          feature: GameFeature.expeditions,
          title: 'Constellation Sorties',
          category: 'Deep Space Missions',
          description: 'Deploy idle spacecraft on deep space missions to recover ancient relic shards and rare materials.',
          icon: Icons.travel_explore_rounded,
          color: Color(0xFF00F0FF),
          requiredTier: 11,
          location: 'Command Hub > Treasure Hunts',
          actionLabel: 'START EXPEDITIONS',
          howItWorks:
              'Send spacecraft from your hangar on timed interstellar missions. When they return, they bring back ancient relic shards and cosmic loot.',
          steps: [
            'Select "Treasure Hunts" from the Command Hub.',
            'Choose an expedition destination and assign an idle spacecraft.',
            'Collect your guaranteed reward crates and relic shards when the mission timer finishes!',
          ],
          proTip:
              'Higher tier assigned ships yield higher success probabilities and rarer relic shard drops!',
        );

      case GameFeature.cosmicStore:
        return const UnlockedFeatureInfo(
          feature: GameFeature.cosmicStore,
          title: 'In-Game Cosmic Store',
          category: 'VIP Logistics',
          description: 'Purchase time-warps, permanent quantum boosters, and automated AI drone licenses.',
          icon: Icons.storefront_rounded,
          color: Color(0xFFFF9900),
          requiredTier: 12,
          location: 'Command Hub > Item Shop',
          actionLabel: 'VISIT STORE',
          howItWorks:
              'The Cosmic Store offers high-tier tactical assets, instant time-warp energy cells, and permanent multiplier packs.',
          steps: [
            'Open the Item Shop from the Command Hub.',
            'Browse instant time-warp boosters, credit bundles, and Dark Matter supplies.',
            'Activate boosters during high-multiplier events for insane credit explosions!',
          ],
          proTip:
              'Use Time-Warps when your track is fully populated with your highest-tier spacecraft for maximum payout!',
        );

      case GameFeature.prestige:
        return const UnlockedFeatureInfo(
          feature: GameFeature.prestige,
          title: 'Galactic Prestige',
          category: 'Singularity Ascension',
          description: 'Reset fleet for Dark Matter dimensional cores and unlock permanent Prestige Mastery super perks.',
          icon: Icons.restart_alt_rounded,
          color: Color(0xFFFF0055),
          requiredTier: 13,
          location: 'Command Hub > Restart for 2X',
          actionLabel: 'ASCEND FLEET',
          howItWorks:
              'Galactic Prestige collapses your current fleet into concentrated Dark Matter dimensional cores, permanently doubling base income and unlocking ultimate perks.',
          steps: [
            'Reach Tier 13 (or 5,000,000+ Lifetime Credits) to initialize Prestige clearance.',
            'Review your Dark Matter payout and permanent multiplier boost.',
            'Initiate the singularity collapse to rebirth your fleet with permanent superpower upgrades!',
          ],
          proTip:
              'Use the 2X Ad Multiplier on Prestige to double your dimensional Dark Matter cores on ascension!',
        );
    }
  }

  /// Gets list of features newly unlocked at a specific tier
  static List<UnlockedFeatureInfo> getFeaturesUnlockedAtTier(int tier) {
    final List<UnlockedFeatureInfo> list = [];
    for (final feature in GameFeature.values) {
      if (getRequiredTier(feature) == tier) {
        list.add(getFeatureInfo(feature));
      }
    }
    return list;
  }

  /// Sequential Commander Learning Quests aligned with rebalanced progression
  static final List<LearningMilestoneQuest> learningQuests = [
    LearningMilestoneQuest(
      id: 1,
      title: 'First Flight Fusion',
      objective: 'Merge two Novice Interceptors into a Tier 2 Vanguard Scout.',
      icon: Icons.merge_type_rounded,
      rewardCredits: 500.0,
      rewardDarkMatter: 5.0,
      checkCompleted: (state) => state.highestTierUnlocked >= 2,
    ),
    LearningMilestoneQuest(
      id: 2,
      title: 'Engine Overclock',
      objective: 'Upgrade Fleet Engine Speed to Level 2 in the Circuit Engineering Bar.',
      icon: Icons.speed_rounded,
      rewardCredits: 1000.0,
      rewardDarkMatter: 5.0,
      checkCompleted: (state) => state.fleetSpeedLevel >= 2,
    ),
    LearningMilestoneQuest(
      id: 3,
      title: 'Fleet Officer Promotion',
      objective: 'Reach Spacecraft Tier 3 to unlock Daily Supply Drops & Fleet Auto-Sort.',
      icon: Icons.flight_takeoff_rounded,
      rewardCredits: 2500.0,
      rewardDarkMatter: 10.0,
      checkCompleted: (state) => state.highestTierUnlocked >= 3,
    ),
    LearningMilestoneQuest(
      id: 4,
      title: 'Multi-Laser Checkpoint',
      objective: 'Reach Tier 4 and construct the 2nd Laser Finish Gate to double lap payouts.',
      icon: Icons.flag_rounded,
      rewardCredits: 6000.0,
      rewardDarkMatter: 15.0,
      checkCompleted: (state) =>
          state.highestTierUnlocked >= 4 && state.finishLinesCount >= 2,
    ),
    LearningMilestoneQuest(
      id: 5,
      title: 'Hyperspace Acceleration',
      objective: 'Reach Tier 5 to unlock On-Track Hyper-Pads & Wormhole Singularity Roulette.',
      icon: Icons.rocket_launch_rounded,
      rewardCredits: 15000.0,
      rewardDarkMatter: 20.0,
      checkCompleted: (state) => state.highestTierUnlocked >= 5,
    ),
    LearningMilestoneQuest(
      id: 6,
      title: 'Automated Logistics',
      objective: 'Reach Tier 6 to unlock the golden 1-Tap Auto-Merge Superpower.',
      icon: Icons.auto_awesome_rounded,
      rewardCredits: 35000.0,
      rewardDarkMatter: 30.0,
      checkCompleted: (state) => state.highestTierUnlocked >= 6,
    ),
    LearningMilestoneQuest(
      id: 7,
      title: 'Quantum Research Matrix',
      objective: 'Reach Tier 7 to unlock the Dark Matter Quantum Tech Tree.',
      icon: Icons.account_tree_rounded,
      rewardCredits: 75000.0,
      rewardDarkMatter: 40.0,
      checkCompleted: (state) => state.highestTierUnlocked >= 7,
    ),
    LearningMilestoneQuest(
      id: 8,
      title: 'Circuit Ascension',
      objective: 'Reach Tier 8 and evolve the Racetrack into an advanced geometric circuit.',
      icon: Icons.shape_line_rounded,
      rewardCredits: 150000.0,
      rewardDarkMatter: 50.0,
      checkCompleted: (state) =>
          state.highestTierUnlocked >= 8 && state.circuitTier >= 2,
    ),
    LearningMilestoneQuest(
      id: 9,
      title: 'Orbital Strike Command',
      objective: 'Reach Tier 10 and summon an Alien Dreadnought Boss via the Battle Beacon.',
      icon: Icons.military_tech_rounded,
      rewardCredits: 300000.0,
      rewardDarkMatter: 75.0,
      checkCompleted: (state) =>
          state.highestTierUnlocked >= 10 &&
          (state.activeBoss != null || state.totalLineCrossings >= 200),
    ),
    LearningMilestoneQuest(
      id: 10,
      title: 'Trans-Dimensional Singularity',
      objective: 'Reach Tier 13 (or 5M Lifetime Credits) to perform your first Galactic Prestige Reset.',
      icon: Icons.all_inclusive_rounded,
      rewardCredits: 1000000.0,
      rewardDarkMatter: 150.0,
      checkCompleted: (state) =>
          state.highestTierUnlocked >= 13 || state.lifetimeCredits >= 5000000.0,
    ),
  ];

  /// Gets the next active learning milestone quest
  static LearningMilestoneQuest? getActiveMilestone(GameState state) {
    for (final quest in learningQuests) {
      if (!state.claimedLearningMilestones.contains(quest.id)) {
        return quest;
      }
    }
    return null;
  }
}
