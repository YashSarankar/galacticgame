import 'package:flutter/material.dart';

enum RouletteRewardType {
  supernovaJackpot,
  darkMatter,
  shipDrop,
  feverRush,
  relicShards,
  timeWarp,
  creditsMultiplier,
  mysteryCrate,
}

/// Represents one of the 8 reward wedges on the Wormhole Roulette Wheel
class RouletteRewardModel {
  final String id;
  final String title;
  final String description;
  final RouletteRewardType type;
  final IconData icon;
  final Color color;
  final double valueMultiplier;
  final int count;

  const RouletteRewardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
    this.valueMultiplier = 1.0,
    this.count = 1,
  });

  /// The 8 canonical sectors on the Wormhole Roulette Wheel
  static List<RouletteRewardModel> getSegments() {
    return const [
      // 0. Supernova Jackpot (100x Top-Tier Ship Lap Income)
      RouletteRewardModel(
        id: 'spin_jackpot',
        title: 'SUPERNOVA 100X',
        description: 'Instant 100X top ship lap income explosion!',
        type: RouletteRewardType.supernovaJackpot,
        icon: Icons.star_rounded,
        color: Color(0xFFFFD700), // Gold
        valueMultiplier: 100.0,
      ),

      // 1. Dark Matter Stash (+50 DM)
      RouletteRewardModel(
        id: 'spin_dark_matter',
        title: '+50 DARK MATTER',
        description: 'Cosmic singularity crystals for Quantum Skill Tree upgrades.',
        type: RouletteRewardType.darkMatter,
        icon: Icons.diamond_rounded,
        color: Color(0xFFBD00FF), // Neon Purple
        count: 50,
      ),

      // 2. High-Tier Fleet Ship Drop
      RouletteRewardModel(
        id: 'spin_ship_drop',
        title: 'HIGH-TIER SHIP',
        description: 'Instant top-tier combat spacecraft deployed directly to deck!',
        type: RouletteRewardType.shipDrop,
        icon: Icons.rocket_launch_rounded,
        color: Color(0xFF00F5FF), // Neon Cyan
      ),

      // 3. 2-Hour Time Warp
      RouletteRewardModel(
        id: 'spin_time_warp',
        title: '2-HR TIME WARP',
        description: 'Instantly fast-forward 2 hours of idle fleet revenue!',
        type: RouletteRewardType.timeWarp,
        icon: Icons.timelapse_rounded,
        color: Color(0xFF00FF88), // Neon Green
        count: 7200, // 2 hours in seconds
      ),

      // 4. Hyperspace Fever Rush (30s)
      RouletteRewardModel(
        id: 'spin_fever',
        title: '30s HYPER FEVER',
        description: 'Instant 30-second hyperspace warp boost (2x speed + 2x credits)!',
        type: RouletteRewardType.feverRush,
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFF9900), // Neon Orange
        count: 30,
      ),

      // 5. Ancient Relic Shards (+5 Shards)
      RouletteRewardModel(
        id: 'spin_relics',
        title: '+5 RELIC SHARDS',
        description: 'Ancient alien relic shards to level up permanent multipliers.',
        type: RouletteRewardType.relicShards,
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFFFF0055), // Crimson
        count: 5,
      ),

      // 6. Galactic Treasury (25x Lap Income)
      RouletteRewardModel(
        id: 'spin_credits',
        title: '25X CREDITS',
        description: 'Instant 25X top ship lap payout windfall!',
        type: RouletteRewardType.creditsMultiplier,
        icon: Icons.monetization_on_rounded,
        color: Color(0xFF00E5FF),
        valueMultiplier: 25.0,
      ),

      // 7. Mystery Cargo Crate
      RouletteRewardModel(
        id: 'spin_crate',
        title: 'AD GIFT CRATE',
        description: 'A glowing cosmic supply drop packed with high-tier spacecraft!',
        type: RouletteRewardType.mysteryCrate,
        icon: Icons.card_giftcard_rounded,
        color: Color(0xFFFFE600),
      ),
    ];
  }
}
