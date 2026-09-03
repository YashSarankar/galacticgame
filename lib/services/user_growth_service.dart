import 'package:flutter/material.dart';
import '../models/game_state.dart';

/// Game Features progressively unlocked across the 7-Stage Commander Learning Arc
enum GameFeature {
  fleetSpeedUpgrade,
  multiLaserGates,
  autoMerge,
  autoSort,
  codex,
  dailyCalendar,
  hyperPads,
  techTree,
  roulette,
  trackEvolution,
  bossBeacon,
  achievements,
  relics,
  expeditions,
  prestige,
  cosmicStore,
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

/// Feature metadata describing unlocked systems
class UnlockedFeatureInfo {
  final GameFeature feature;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int requiredTier;

  const UnlockedFeatureInfo({
    required this.feature,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredTier,
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

  /// 7 Commander Ranks across the player progression arc
  static const List<CommanderRankInfo> ranks = [
    CommanderRankInfo(
      rank: 1,
      title: 'Novice Cadet',
      subtitle: 'Flight School & Basic Fleet Mechanics',
      icon: Icons.school_rounded,
      color: Color(0xFF00F0FF),
      requiredTier: 1,
    ),
    CommanderRankInfo(
      rank: 2,
      title: 'Flight Officer',
      subtitle: 'Circuit Automation & Multi-Gate Circuits',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF06D6A0),
      requiredTier: 2,
    ),
    CommanderRankInfo(
      rank: 3,
      title: 'Fleet Navigator',
      subtitle: 'Interstellar Logistics & Hyper-Pads',
      icon: Icons.explore_rounded,
      color: Color(0xFFFFB703),
      requiredTier: 3,
    ),
    CommanderRankInfo(
      rank: 4,
      title: 'Quantum Engineer',
      subtitle: 'Quantum Matrices & Track Evolution',
      icon: Icons.memory_rounded,
      color: Color(0xFFBD00FF),
      requiredTier: 4,
    ),
    CommanderRankInfo(
      rank: 5,
      title: 'Battle Commander',
      subtitle: 'Deep Space Warfare & Dreadnought Incursions',
      icon: Icons.military_tech_rounded,
      color: Color(0xFFFF0055),
      requiredTier: 5,
    ),
    CommanderRankInfo(
      rank: 6,
      title: 'Starfleet Marshal',
      subtitle: 'Ancient Relic Archeology & Expeditions',
      icon: Icons.stars_rounded,
      color: Color(0xFF7000FF),
      requiredTier: 6,
    ),
    CommanderRankInfo(
      rank: 7,
      title: 'Galactic Overlord',
      subtitle: 'Singularity Mastery & Dimensional Prestige',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFFFD700),
      requiredTier: 7,
    ),
  ];

  /// Gets current commander rank info based on highest tier
  static CommanderRankInfo getCommanderRank(int highestTier) {
    if (highestTier >= 7) return ranks[6];
    if (highestTier >= 6) return ranks[5];
    if (highestTier >= 5) return ranks[4];
    if (highestTier >= 4) return ranks[3];
    if (highestTier >= 3) return ranks[2];
    if (highestTier >= 2) return ranks[1];
    return ranks[0];
  }

  /// Gets minimum spacecraft tier required to unlock a specific feature
  static int getRequiredTier(GameFeature feature) {
    switch (feature) {
      case GameFeature.fleetSpeedUpgrade:
        return 1; // Unlocked at Tier 1 (Core engineering)
      case GameFeature.multiLaserGates:
      case GameFeature.autoMerge:
      case GameFeature.autoSort:
        return 2; // Unlocked at Tier 2 (Circuit Automation)
      case GameFeature.codex:
      case GameFeature.dailyCalendar:
      case GameFeature.hyperPads:
        return 3; // Unlocked at Tier 3 (Logistics & Boost Pads)
      case GameFeature.techTree:
      case GameFeature.roulette:
      case GameFeature.trackEvolution:
        return 4; // Unlocked at Tier 4 (Quantum Tech & Track Evolution)
      case GameFeature.bossBeacon:
      case GameFeature.achievements:
        return 5; // Unlocked at Tier 5 (Boss Warfare)
      case GameFeature.relics:
      case GameFeature.expeditions:
        return 6; // Unlocked at Tier 6 (Relics & Expeditions)
      case GameFeature.prestige:
      case GameFeature.cosmicStore:
        return 7; // Unlocked at Tier 7 (Prestige & VIP Store)
    }
  }

  /// Checks if a feature is unlocked based on highest tier and lifetime earnings
  static bool isFeatureUnlocked(
    GameFeature feature, {
    required int highestTier,
    double lifetimeCredits = 0.0,
  }) {
    if (feature == GameFeature.prestige && lifetimeCredits >= 500000.0) {
      return true;
    }
    return highestTier >= getRequiredTier(feature);
  }

  /// Returns detailed info for a feature
  static UnlockedFeatureInfo getFeatureInfo(GameFeature feature) {
    switch (feature) {
      case GameFeature.fleetSpeedUpgrade:
        return const UnlockedFeatureInfo(
          feature: GameFeature.fleetSpeedUpgrade,
          title: 'Fleet Engine Tuning',
          description: 'Upgrade fleet velocity with Credits for faster lap times and increased earning frequency.',
          icon: Icons.speed_rounded,
          color: Color(0xFF00F0FF),
          requiredTier: 1,
        );
      case GameFeature.multiLaserGates:
        return const UnlockedFeatureInfo(
          feature: GameFeature.multiLaserGates,
          title: 'Multi-Laser Finish Gates',
          description: 'Construct up to 4 laser gates across the circuit, multiplying payouts per lap.',
          icon: Icons.flag_rounded,
          color: Color(0xFFFFD700),
          requiredTier: 2,
        );
      case GameFeature.autoMerge:
        return const UnlockedFeatureInfo(
          feature: GameFeature.autoMerge,
          title: 'Auto-Merge Logistics',
          description: 'Instantly merges all matching pairs across your hangar bays with 1 tap.',
          icon: Icons.auto_awesome_rounded,
          color: Color(0xFFFFD700),
          requiredTier: 2,
        );
      case GameFeature.autoSort:
        return const UnlockedFeatureInfo(
          feature: GameFeature.autoSort,
          title: 'Fleet Auto-Sort',
          description: 'Neatly organizes your spacecraft grid by tier and groups identical pairs together.',
          icon: Icons.sort_rounded,
          color: Color(0xFF00F0FF),
          requiredTier: 2,
        );
      case GameFeature.codex:
        return const UnlockedFeatureInfo(
          feature: GameFeature.codex,
          title: 'Spacecraft Codex',
          description: 'Access the 16-Tier interstellar fleet encyclopedia with detailed lore and stats.',
          icon: Icons.menu_book_rounded,
          color: Color(0xFF00FF88),
          requiredTier: 3,
        );
      case GameFeature.dailyCalendar:
        return const UnlockedFeatureInfo(
          feature: GameFeature.dailyCalendar,
          title: 'Daily Supply Transmissions',
          description: 'Claim daily login crates, Dark Matter gems, and rare relic shards every 24 hours.',
          icon: Icons.calendar_month_rounded,
          color: Color(0xFFFFD700),
          requiredTier: 3,
        );
      case GameFeature.hyperPads:
        return const UnlockedFeatureInfo(
          feature: GameFeature.hyperPads,
          title: 'On-Track Hyper-Pads',
          description: 'Place and level up neon acceleration pads on circuit corners for supersonic speed bursts.',
          icon: Icons.rocket_launch_rounded,
          color: Color(0xFF9D4EDD),
          requiredTier: 3,
        );
      case GameFeature.techTree:
        return const UnlockedFeatureInfo(
          feature: GameFeature.techTree,
          title: 'Quantum Tech Tree',
          description: 'Upgrade global income, racing velocity, discount rates, and lucky clone probability.',
          icon: Icons.account_tree_rounded,
          color: Color(0xFFBD00FF),
          requiredTier: 4,
        );
      case GameFeature.roulette:
        return const UnlockedFeatureInfo(
          feature: GameFeature.roulette,
          title: 'Wormhole Roulette',
          description: 'Spin the spatial singularity wheel daily for instant jackpot credit & gem bounties.',
          icon: Icons.blur_circular_rounded,
          color: Color(0xFF00F5FF),
          requiredTier: 4,
        );
      case GameFeature.trackEvolution:
        return const UnlockedFeatureInfo(
          feature: GameFeature.trackEvolution,
          title: 'Track Circuit Evolution',
          description: 'Ascend your racetrack into complex figure-8 and pulsar geometries with permanent multipliers!',
          icon: Icons.shape_line_rounded,
          color: Color(0xFFFFD700),
          requiredTier: 4,
        );
      case GameFeature.bossBeacon:
        return const UnlockedFeatureInfo(
          feature: GameFeature.bossBeacon,
          title: 'Alien Dreadnought Beacon',
          description: 'Summon titanic alien bosses. Your fleet fires automatic laser strikes for massive bounties.',
          icon: Icons.radar_rounded,
          color: Color(0xFFFF0055),
          requiredTier: 5,
        );
      case GameFeature.achievements:
        return const UnlockedFeatureInfo(
          feature: GameFeature.achievements,
          title: 'Milestone Trophies',
          description: 'Complete lifetime career objectives to claim Dark Matter and prestige medals.',
          icon: Icons.emoji_events_rounded,
          color: Color(0xFFFFD700),
          requiredTier: 5,
        );
      case GameFeature.relics:
        return const UnlockedFeatureInfo(
          feature: GameFeature.relics,
          title: 'Ancient Relics Vault',
          description: 'Socket alien artifacts to gain permanent multipliers to fleet speed, income, and crits.',
          icon: Icons.auto_awesome_rounded,
          color: Color(0xFFBD00FF),
          requiredTier: 6,
        );
      case GameFeature.expeditions:
        return const UnlockedFeatureInfo(
          feature: GameFeature.expeditions,
          title: 'Constellation Sorties',
          description: 'Deploy idle spacecraft on deep space missions to recover ancient relic shards.',
          icon: Icons.travel_explore_rounded,
          color: Color(0xFF00F0FF),
          requiredTier: 6,
        );
      case GameFeature.prestige:
        return const UnlockedFeatureInfo(
          feature: GameFeature.prestige,
          title: 'Galactic Prestige',
          description: 'Reset fleet for Dark Matter dimensional cores and unlock permanent Prestige Mastery super perks.',
          icon: Icons.restart_alt_rounded,
          color: Color(0xFFFF0055),
          requiredTier: 7,
        );
      case GameFeature.cosmicStore:
        return const UnlockedFeatureInfo(
          feature: GameFeature.cosmicStore,
          title: 'In-Game Cosmic Store',
          description: 'Purchase time-warps, permanent quantum boosters, and automated AI drone licenses.',
          icon: Icons.storefront_rounded,
          color: Color(0xFFFFD700),
          requiredTier: 7,
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

  /// Sequential Commander Learning Quests
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
      title: 'Dual Laser Checkpoint',
      objective: 'Unlock the 2nd Laser Finish Gate to double lap payout frequency.',
      icon: Icons.flag_rounded,
      rewardCredits: 2500.0,
      rewardDarkMatter: 10.0,
      checkCompleted: (state) => state.finishLinesCount >= 2,
    ),
    LearningMilestoneQuest(
      id: 4,
      title: 'Hyperspace Booster',
      objective: 'Reach Tier 3 and upgrade On-Track Hyper-Pads to Level 2.',
      icon: Icons.rocket_launch_rounded,
      rewardCredits: 5000.0,
      rewardDarkMatter: 15.0,
      checkCompleted: (state) =>
          state.highestTierUnlocked >= 3 && state.boostPadLevel >= 2,
    ),
    LearningMilestoneQuest(
      id: 5,
      title: 'Circuit Ascension',
      objective: 'Reach Tier 4 and Evolve the Track Circuit to Tier 2 (Hyper-Elliptical Superhighway).',
      icon: Icons.shape_line_rounded,
      rewardCredits: 25000.0,
      rewardDarkMatter: 25.0,
      checkCompleted: (state) => state.circuitTier >= 2,
    ),
    LearningMilestoneQuest(
      id: 6,
      title: 'Orbital Strike Command',
      objective: 'Reach Tier 5 and summon an Alien Dreadnought Boss via the Battle Beacon.',
      icon: Icons.military_tech_rounded,
      rewardCredits: 100000.0,
      rewardDarkMatter: 50.0,
      checkCompleted: (state) =>
          state.highestTierUnlocked >= 5 &&
          (state.activeBoss != null || state.totalLineCrossings >= 200),
    ),
    LearningMilestoneQuest(
      id: 7,
      title: 'Trans-Dimensional Reset',
      objective: 'Reach Tier 7 (or 500K Lifetime Coins) to initiate your first Galactic Prestige Reset.',
      icon: Icons.auto_awesome_rounded,
      rewardCredits: 500000.0,
      rewardDarkMatter: 100.0,
      checkCompleted: (state) =>
          state.highestTierUnlocked >= 7 || state.lifetimeCredits >= 500000.0,
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
