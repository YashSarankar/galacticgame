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
      // Requires sustained play — tutorial does ~3–5 merges, player needs 30 more
      const MissionModel(
        id: 'm1_merge_3',
        title: 'Fleet Assembly',
        description: 'Merge ships 30 times on the grid',
        type: MissionType.mergeCount,
        targetValue: 30,
        currentProgress: 0,
        rewardCoins: 2500,
        rewardDarkMatter: 0,
      ),
      // 200 crossings = roughly 5–10 mins of active play with a small fleet
      const MissionModel(
        id: 'm2_cross_20',
        title: 'Orbital Speedrun',
        description: 'Cross the income line 200 times',
        type: MissionType.crossCount,
        targetValue: 200,
        currentProgress: 0,
        rewardCoins: 8000,
        rewardDarkMatter: 0,
      ),
      // Requires earning enough to unlock T3 — introduces Dark Matter!
      const MissionModel(
        id: 'm3_tier_3',
        title: 'Solar Upgrade',
        description: 'Unlock a Tier 3 Solar Falcon',
        type: MissionType.unlockTier,
        targetValue: 3,
        currentProgress: 1,
        rewardCoins: 15000,
        rewardDarkMatter: 10,
      ),
      // Buying 30 ships means repeated trips to shipyard over many sessions
      const MissionModel(
        id: 'm4_buy_10',
        title: 'Shipyard Contractor',
        description: 'Purchase 30 ships from the shipyard',
        type: MissionType.buyShipCount,
        targetValue: 30,
        currentProgress: 0,
        rewardCoins: 25000,
        rewardDarkMatter: 12,
      ),
      // 1000 crossings = solid idle progression milestone
      const MissionModel(
        id: 'm5_cross_100',
        title: 'Hyperdrive Warp',
        description: 'Cross the income line 1,000 times',
        type: MissionType.crossCount,
        targetValue: 1000,
        currentProgress: 0,
        rewardCoins: 75000,
        rewardDarkMatter: 20,
      ),
      // Reaching T5 requires significant fleet building and coin accumulation
      const MissionModel(
        id: 'm6_tier_5',
        title: 'Cruiser Class',
        description: 'Unlock a Tier 5 Plasma Cruiser',
        type: MissionType.unlockTier,
        targetValue: 5,
        currentProgress: 1,
        rewardCoins: 200000,
        rewardDarkMatter: 40,
      ),
      // 100 merges is a long-term mastery goal
      const MissionModel(
        id: 'm7_merge_25',
        title: 'Nanite Synthesis',
        description: 'Merge ships 100 times',
        type: MissionType.mergeCount,
        targetValue: 100,
        currentProgress: 0,
        rewardCoins: 500000,
        rewardDarkMatter: 75,
      ),
    ];
  }
}
