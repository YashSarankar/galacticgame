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
      // 0. Supernova Jackpot (100x Lap Income)
      RouletteRewardModel(
        id: 'spin_jackpot',
        title: '100X JACKPOT',
        description: 'Instant 100X lap income credit explosion!',
        type: RouletteRewardType.supernovaJackpot,
        icon: Icons.star_rounded,
        color: Color(0xFFFFD700), // Gold
        valueMultiplier: 100.0,
      ),

      // 1. Dark Matter Stash (+30 DM)
      RouletteRewardModel(
        id: 'spin_dark_matter',
        title: '+35 DARK MATTER',
        description: 'Cosmic singularity gems for quantum tree upgrades.',
        type: RouletteRewardType.darkMatter,
        icon: Icons.diamond_rounded,
        color: Color(0xFFBD00FF), // Neon Purple
        count: 35,
      ),

      // 2. High-Tier Ship Drop
      RouletteRewardModel(
        id: 'spin_ship_drop',
        title: 'FLEET DROP',
        description: 'Instant high-tier spacecraft delivered to flight deck!',
        type: RouletteRewardType.shipDrop,
        icon: Icons.rocket_launch_rounded,
        color: Color(0xFF00F5FF), // Neon Cyan
      ),

      // 3. 2-Hour Time Warp
      RouletteRewardModel(
        id: 'spin_time_warp',
        title: '2-HR TIME WARP',
        description: 'Instantly fast-forward 2 hours of idle fleet earnings!',
        type: RouletteRewardType.timeWarp,
        icon: Icons.timelapse_rounded,
        color: Color(0xFF00FF88), // Neon Green
        count: 7200, // 2 hours in seconds
      ),

      // 4. Hyperdrive Overload (Fever Rush)
      RouletteRewardModel(
        id: 'spin_fever',
        title: 'FEVER RUSH',
        description: 'Instant 30-second max Hyperspace Fever Rush!',
        type: RouletteRewardType.feverRush,
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFF9900), // Neon Orange
        count: 30,
      ),

      // 5. Ancient Relic Cache (+3 Shards)
      RouletteRewardModel(
        id: 'spin_relics',
        title: '+3 RELIC SHARDS',
        description: 'Ancient alien artifacts to level up permanent passives.',
        type: RouletteRewardType.relicShards,
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFFFF0055), // Crimson
        count: 3,
      ),

      // 6. Galactic Treasury (15x Lap Income)
      RouletteRewardModel(
        id: 'spin_credits',
        title: '15X CREDITS',
        description: 'Massive cash windfall from deep space convoys.',
        type: RouletteRewardType.creditsMultiplier,
        icon: Icons.monetization_on_rounded,
        color: Color(0xFF00E5FF),
        valueMultiplier: 15.0,
      ),

      // 7. Jackpot Mystery Crate
      RouletteRewardModel(
        id: 'spin_crate',
        title: 'MYSTERY CRATE',
        description: 'A glowing cosmic supply drop delivered to the deck.',
        type: RouletteRewardType.mysteryCrate,
        icon: Icons.card_giftcard_rounded,
        color: Color(0xFFFFE600),
      ),
    ];
  }
}
