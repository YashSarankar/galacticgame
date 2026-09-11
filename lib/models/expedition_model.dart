import 'dart:math';

/// Predefined Constellation Star Sectors for Deep Space Expeditions
class ExpeditionSector {
  final String id;
  final String name;
  final String description;
  final String iconAsset;
  final int minShipTier;
  final int durationSeconds;
  final double baseCreditsMultiplier;
  final double darkMatterReward;
  final int relicShardsReward;
  final int bonusBlueprintTier;
  final String hazardRating; // 'LOW', 'MODERATE', 'SEVERE', 'EXTREME'
  final int sectorColorValue;

  const ExpeditionSector({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.minShipTier,
    required this.durationSeconds,
    required this.baseCreditsMultiplier,
    required this.darkMatterReward,
    required this.relicShardsReward,
    this.bonusBlueprintTier = 0,
    required this.hazardRating,
    required this.sectorColorValue,
  });

  static const List<ExpeditionSector> catalog = [
    ExpeditionSector(
      id: 'sector_andromeda',
      name: 'Andromeda Moon (5 Min)',
      description: 'Quick 5-minute trip to collect easy bonus coins.',
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Meteors/meteorBrown_med1.png',
      minShipTier: 1,
      durationSeconds: 300, // 5 minutes
      baseCreditsMultiplier: 100.0,
      darkMatterReward: 0.0,
      relicShardsReward: 0,
      hazardRating: 'EASY',
      sectorColorValue: 0xFF00F0FF, // Cyan
    ),
    ExpeditionSector(
      id: 'sector_orion',
      name: 'Orion Asteroid Belt (15 Min)',
      description: '15-minute mission for coins, Dark Matter, and Relic Shards.',
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Meteors/meteorGrey_med1.png',
      minShipTier: 3,
      durationSeconds: 900, // 15 minutes
      baseCreditsMultiplier: 450.0,
      darkMatterReward: 2.0,
      relicShardsReward: 3,
      hazardRating: 'NORMAL',
      sectorColorValue: 0xFF06D6A0, // Emerald Green
    ),
    ExpeditionSector(
      id: 'sector_cygnus',
      name: 'Cygnus Space Rift (1 Hour)',
      description: '1-hour mission with big Dark Matter rewards and free ships.',
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack1.png',
      minShipTier: 6,
      durationSeconds: 3600, // 1 hour
      baseCreditsMultiplier: 2500.0,
      darkMatterReward: 12.0,
      relicShardsReward: 8,
      bonusBlueprintTier: 4,
      hazardRating: 'HARD',
      sectorColorValue: 0xFF9D4EDD, // Violet Purple
    ),
    ExpeditionSector(
      id: 'sector_centauri',
      name: 'Centauri Supercluster (2 Hours)',
      description: '2-hour expedition with massive credit yield and relic shards.',
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyBlue1.png',
      minShipTier: 8,
      durationSeconds: 7200, // 2 hours
      baseCreditsMultiplier: 6500.0,
      darkMatterReward: 22.0,
      relicShardsReward: 12,
      bonusBlueprintTier: 6,
      hazardRating: 'SEVERE',
      sectorColorValue: 0xFFFFB703, // Amber Gold
    ),
    ExpeditionSector(
      id: 'sector_sirius',
      name: 'Sirius Star Core (4 Hours)',
      description: '4-hour deep space mission with huge Jackpot rewards!',
      iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyRed1.png',
      minShipTier: 10,
      durationSeconds: 14400, // 4 hours
      baseCreditsMultiplier: 15000.0,
      darkMatterReward: 40.0,
      relicShardsReward: 20,
      bonusBlueprintTier: 8,
      hazardRating: 'EXPERT',
      sectorColorValue: 0xFFFF0055, // Crimson Neon
    ),
  ];

}

/// Active or historical player expedition mission instance
class ExpeditionMission {
  final String id;
  final String sectorId;
  final String sectorName;
  final int durationSeconds;
  final int startTimeEpoch; // Epoch ms when launched
  final int assignedShipTier;
  final double calculatedCredits;
  final double calculatedDarkMatter;
  final int calculatedRelicShards;
  final int bonusBlueprintTier;
  final bool isClaimed;

  const ExpeditionMission({
    required this.id,
    required this.sectorId,
    required this.sectorName,
    required this.durationSeconds,
    required this.startTimeEpoch,
    required this.assignedShipTier,
    required this.calculatedCredits,
    required this.calculatedDarkMatter,
    required this.calculatedRelicShards,
    this.bonusBlueprintTier = 0,
    this.isClaimed = false,
  });

  /// Elapsed seconds since expedition launch
  int get elapsedSeconds {
    final now = DateTime.now().millisecondsSinceEpoch;
    final int diff = ((now - startTimeEpoch) / 1000).floor();
    return max(0, diff);
  }

  /// Remaining seconds until completion
  int get remainingSeconds {
    return max(0, durationSeconds - elapsedSeconds);
  }

  /// Progress from 0.0 to 1.0
  double get progressRatio {
    if (durationSeconds <= 0) return 1.0;
    return (elapsedSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  /// Whether expedition has finished its voyage and is awaiting player claim
  bool get isReadyToClaim => !isClaimed && remainingSeconds <= 0;

  /// Whether expedition is actively traveling in deep space
  bool get isInProgress => !isClaimed && remainingSeconds > 0;

  /// Formatted countdown display
  String get formattedRemainingTime {
    final int totalSec = remainingSeconds;
    if (totalSec <= 0) return 'READY TO CLAIM';
    final int hours = totalSec ~/ 3600;
    final int minutes = (totalSec % 3600) ~/ 60;
    final int seconds = totalSec % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  ExpeditionMission copyWith({
    String? id,
    String? sectorId,
    String? sectorName,
    int? durationSeconds,
    int? startTimeEpoch,
    int? assignedShipTier,
    double? calculatedCredits,
    double? calculatedDarkMatter,
    int? calculatedRelicShards,
    int? bonusBlueprintTier,
    bool? isClaimed,
  }) {
    return ExpeditionMission(
      id: id ?? this.id,
      sectorId: sectorId ?? this.sectorId,
      sectorName: sectorName ?? this.sectorName,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startTimeEpoch: startTimeEpoch ?? this.startTimeEpoch,
      assignedShipTier: assignedShipTier ?? this.assignedShipTier,
      calculatedCredits: calculatedCredits ?? this.calculatedCredits,
      calculatedDarkMatter: calculatedDarkMatter ?? this.calculatedDarkMatter,
      calculatedRelicShards: calculatedRelicShards ?? this.calculatedRelicShards,
      bonusBlueprintTier: bonusBlueprintTier ?? this.bonusBlueprintTier,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sectorId': sectorId,
      'sectorName': sectorName,
      'durationSeconds': durationSeconds,
      'startTimeEpoch': startTimeEpoch,
      'assignedShipTier': assignedShipTier,
      'calculatedCredits': calculatedCredits,
      'calculatedDarkMatter': calculatedDarkMatter,
      'calculatedRelicShards': calculatedRelicShards,
      'bonusBlueprintTier': bonusBlueprintTier,
      'isClaimed': isClaimed,
    };
  }

  factory ExpeditionMission.fromJson(Map<String, dynamic> json) {
    return ExpeditionMission(
      id: json['id'] as String,
      sectorId: json['sectorId'] as String,
      sectorName: json['sectorName'] as String,
      durationSeconds: json['durationSeconds'] as int,
      startTimeEpoch: json['startTimeEpoch'] as int,
      assignedShipTier: json['assignedShipTier'] as int? ?? 1,
      calculatedCredits: (json['calculatedCredits'] as num?)?.toDouble() ?? 0.0,
      calculatedDarkMatter: (json['calculatedDarkMatter'] as num?)?.toDouble() ?? 0.0,
      calculatedRelicShards: json['calculatedRelicShards'] as int? ?? 0,
      bonusBlueprintTier: json['bonusBlueprintTier'] as int? ?? 0,
      isClaimed: json['isClaimed'] as bool? ?? false,
    );
  }
}
