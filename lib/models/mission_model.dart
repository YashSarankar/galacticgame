enum MissionType {
  mergeCount,
  crossCount,
  unlockTier,
  earnCoins,
  buyShipCount,
}

/// Reactive Mission model for career progression.
class MissionModel {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final double targetValue;
  final double currentProgress;
  final double rewardCoins;
  final double rewardDarkMatter;
  final bool isClaimed;

  const MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.currentProgress,
    required this.rewardCoins,
    required this.rewardDarkMatter,
    this.isClaimed = false,
  });

  bool get isCompleted => currentProgress >= targetValue;
  double get progressRatio => (currentProgress / targetValue).clamp(0.0, 1.0);

  MissionModel copyWith({
    String? id,
    String? title,
    String? description,
    MissionType? type,
    double? targetValue,
    double? currentProgress,
    double? rewardCoins,
    double? rewardDarkMatter,
    bool? isClaimed,
  }) {
    return MissionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      rewardDarkMatter: rewardDarkMatter ?? this.rewardDarkMatter,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'targetValue': targetValue,
      'currentProgress': currentProgress,
      'rewardCoins': rewardCoins,
      'rewardDarkMatter': rewardDarkMatter,
      'isClaimed': isClaimed,
    };
  }

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    final String id = json['id'] as String? ?? '';
    final canonicalList = getInitialMissions();
    final canonical = canonicalList.firstWhere(
      (m) => m.id == id,
      orElse: () => const MissionModel(
        id: '',
        title: '',
        description: '',
        type: MissionType.mergeCount,
        targetValue: 1,
        currentProgress: 0.0,
        rewardCoins: 100,
        rewardDarkMatter: 1,
      ),
    );

    return MissionModel(
      id: id,
      title: json['title'] as String? ?? canonical.title,
      description: json['description'] as String? ?? canonical.description,
      type: MissionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => canonical.type,
      ),
      targetValue:
          (json['targetValue'] as num?)?.toDouble() ?? canonical.targetValue,
      currentProgress:
          (json['currentProgress'] as num?)?.toDouble() ?? 0.0,
      rewardCoins: canonical.id.isNotEmpty
          ? canonical.rewardCoins
          : ((json['rewardCoins'] as num?)?.toDouble() ?? 100.0),
      rewardDarkMatter: canonical.id.isNotEmpty
          ? canonical.rewardDarkMatter
          : ((json['rewardDarkMatter'] as num?)?.toDouble() ?? 1.0),
      isClaimed: json['isClaimed'] as bool? ?? false,
    );
  }

  /// Initial starter missions catalog calibrated to player progression.
  static List<MissionModel> getInitialMissions() {
    return [
      const MissionModel(
        id: 'm1_merge_3',
        title: 'Fleet Assembly',
        description: 'Merge ships 3 times on the grid',
        type: MissionType.mergeCount,
        targetValue: 3,
        currentProgress: 0,
        rewardCoins: 100,
        rewardDarkMatter: 1,
      ),
      const MissionModel(
        id: 'm2_cross_20',
        title: 'Orbital Speedrun',
        description: 'Cross the income line 20 times',
        type: MissionType.crossCount,
        targetValue: 20,
        currentProgress: 0,
        rewardCoins: 250,
        rewardDarkMatter: 2,
      ),
      const MissionModel(
        id: 'm3_tier_3',
        title: 'Solar Upgrade',
        description: 'Unlock a Tier 3 Solar Falcon',
        type: MissionType.unlockTier,
        targetValue: 3,
        currentProgress: 1,
        rewardCoins: 600,
        rewardDarkMatter: 3,
      ),
      const MissionModel(
        id: 'm4_buy_10',
        title: 'Shipyard Contractor',
        description: 'Purchase 10 ships from shipyard',
        type: MissionType.buyShipCount,
        targetValue: 10,
        currentProgress: 0,
        rewardCoins: 1200,
        rewardDarkMatter: 5,
      ),
      const MissionModel(
        id: 'm5_cross_100',
        title: 'Hyperdrive Warp',
        description: 'Cross the income line 100 times',
        type: MissionType.crossCount,
        targetValue: 100,
        currentProgress: 0,
        rewardCoins: 3000,
        rewardDarkMatter: 8,
      ),
      const MissionModel(
        id: 'm6_tier_5',
        title: 'Cruiser Class',
        description: 'Unlock a Tier 5 Plasma Cruiser',
        type: MissionType.unlockTier,
        targetValue: 5,
        currentProgress: 1,
        rewardCoins: 7500,
        rewardDarkMatter: 15,
      ),
      const MissionModel(
        id: 'm7_merge_25',
        title: 'Nanite Synthesis',
        description: 'Merge ships 25 times',
        type: MissionType.mergeCount,
        targetValue: 25,
        currentProgress: 0,
        rewardCoins: 15000,
        rewardDarkMatter: 20,
      ),
    ];
  }
}
