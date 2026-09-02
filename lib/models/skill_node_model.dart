enum SkillEffectType {
  baseDropTier,      // Increases tier of ships bought from store
  offlineCapHours,   // Extends offline earnings cap from 2h to up to 24h
  globalIncomeBoost, // Permanent % boost to all track income
  shipDiscount,      // % discount on buying ships
  trackSpeedBoost,   // Permanent speed increase for all ships on track
  gridExpansion,     // Expands active merge slots from 8 up to 16
}

/// Skill Tree Node for permanent Dark Matter meta-progression.
class SkillNodeModel {
  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final SkillEffectType effectType;
  final int level;
  final int maxLevel;
  final double baseCost;
  final double costMultiplier;
  final double valuePerLevel;

  const SkillNodeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.effectType,
    required this.level,
    required this.maxLevel,
    required this.baseCost,
    required this.costMultiplier,
    required this.valuePerLevel,
  });

  bool get isMaxed => level >= maxLevel;

  /// Upgrade cost in Dark Matter for the current level.
  double get currentUpgradeCost {
    if (isMaxed) return double.infinity;
    return baseCost * (level == 0 ? 1.0 : (level * costMultiplier));
  }

  /// Current calculated bonus value.
  double get currentBonusValue {
    return level * valuePerLevel;
  }

  SkillNodeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconAsset,
    SkillEffectType? effectType,
    int? level,
    int? maxLevel,
    double? baseCost,
    double? costMultiplier,
    double? valuePerLevel,
  }) {
    return SkillNodeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      effectType: effectType ?? this.effectType,
      level: level ?? this.level,
      maxLevel: maxLevel ?? this.maxLevel,
      baseCost: baseCost ?? this.baseCost,
      costMultiplier: costMultiplier ?? this.costMultiplier,
      valuePerLevel: valuePerLevel ?? this.valuePerLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconAsset': iconAsset,
      'effectType': effectType.name,
      'level': level,
      'maxLevel': maxLevel,
      'baseCost': baseCost,
      'costMultiplier': costMultiplier,
      'valuePerLevel': valuePerLevel,
    };
  }

  factory SkillNodeModel.fromJson(Map<String, dynamic> json) {
    return SkillNodeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconAsset: json['iconAsset'] as String,
      effectType: SkillEffectType.values.firstWhere(
        (e) => e.name == json['effectType'],
        orElse: () => SkillEffectType.baseDropTier,
      ),
      level: json['level'] as int,
      maxLevel: json['maxLevel'] as int,
      baseCost: (json['baseCost'] as num).toDouble(),
      costMultiplier: (json['costMultiplier'] as num).toDouble(),
      valuePerLevel: (json['valuePerLevel'] as num).toDouble(),
    );
  }

  /// Initial Default Skill Tree
  static List<SkillNodeModel> getInitialSkills() {
    return [
      const SkillNodeModel(
        id: 'skill_grid_expansion',
        title: 'Hangar Bay Expansion',
        description: 'Expands active merge flight deck (+2 Slots per Lv, from 8 up to 16)',
        iconAsset: 'assets/kenney_space-shooter-remastered/PNG/UI/buttonBlue.png',
        effectType: SkillEffectType.gridExpansion,
        level: 0,
        maxLevel: 4, // 8 + 4*2 = 16 slots
        baseCost: 5,
        costMultiplier: 2.0,
        valuePerLevel: 2.0,
      ),
      const SkillNodeModel(
        id: 'skill_base_tier',
        title: 'Quantum Shipyard',
        description: 'Increases starting tier of purchased ships (+1 Tier per Lv)',
        iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/things_gold.png',
        effectType: SkillEffectType.baseDropTier,
        level: 0,
        maxLevel: 5,
        baseCost: 8,
        costMultiplier: 2.5,
        valuePerLevel: 1.0,
      ),
      const SkillNodeModel(
        id: 'skill_income_boost',
        title: 'Tachyon Grid Core',
        description: 'Multiplies all track crossing income (+25% per Lv)',
        iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/star_gold.png',
        effectType: SkillEffectType.globalIncomeBoost,
        level: 0,
        maxLevel: 20,
        baseCost: 4,
        costMultiplier: 1.8,
        valuePerLevel: 0.25,
      ),
      const SkillNodeModel(
        id: 'skill_offline_cap',
        title: 'Cryo-Vault Storage',
        description: 'Extends maximum offline earnings duration (+2 Hours per Lv)',
        iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/pill_blue.png',
        effectType: SkillEffectType.offlineCapHours,
        level: 0,
        maxLevel: 11,
        baseCost: 4,
        costMultiplier: 2.0,
        valuePerLevel: 2.0,
      ),
      const SkillNodeModel(
        id: 'skill_track_speed',
        title: 'Overdrive Thrusters',
        description: 'Permanently increases ship orbital speed (+15% per Lv)',
        iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/bolt_gold.png',
        effectType: SkillEffectType.trackSpeedBoost,
        level: 0,
        maxLevel: 10,
        baseCost: 6,
        costMultiplier: 2.0,
        valuePerLevel: 0.15,
      ),
      const SkillNodeModel(
        id: 'skill_cost_discount',
        title: 'Replication Subsidies',
        description: 'Reduces shipyard purchase costs by 5% per Lv (Max 40%)',
        iconAsset: 'assets/kenney_space-shooter-remastered/PNG/Power-ups/shield_gold.png',
        effectType: SkillEffectType.shipDiscount,
        level: 0,
        maxLevel: 8,
        baseCost: 5,
        costMultiplier: 1.9,
        valuePerLevel: 0.05,
      ),
    ];
  }
}
