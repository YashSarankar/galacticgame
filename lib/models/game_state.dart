import 'dart:math';
import 'ship_model.dart';
import 'career_model.dart';
import 'boss_model.dart';
import 'relic_model.dart';
import 'expedition_model.dart';
import 'achievement_model.dart';

/// Complete persistent state of the Galactic Merge Idle game.
class GameState {
  final double credits; // Soft Currency
  final double lifetimeCredits;
  final double darkMatter; // Hard Currency (Prestige Gems)
  final int totalShipsPurchased;
  final int totalMergesCount;
  final int totalLineCrossings;
  final int highestTierUnlocked;
  final double feverCharge; // 0.0 to 1.0 (Tap Frenzy Meter)
  final bool isFeverActive; // Whether Hyperspace Fever Rush is active
  final double feverTimeRemaining; // Seconds remaining in active fever mode
  final int comboCount; // Merge combo chain counter (e.g. 2x, 3x, 4x)
  final int lastMergeTimestamp; // Milliseconds for chaining combos
  final String lastComboMessage; // e.g. "3X ULTRA COMBO!"
  final BossModel? activeBoss; // Active Alien Dreadnought Incursion
  final int lastSaveTimestamp; // Epoch milliseconds for offline earnings math
  final int lastFreeSpinTimestamp; // Epoch millis of last daily free spin
  final int extraSpinsCount; // Stored extra spins from ads or boss kills
  final List<ShipModel?> gridSlots; // 16 items for 4x4 matrix
  final List<ShipModel> trackShips; // Active ships racing on Flame track
  final List<RelicModel> relics; // Discovered Ancient Alien Relics
  final List<ExpeditionMission> expeditions; // Active & completed deep space sorties
  final List<AchievementModel> achievements; // Milestone trophies
  final int currentLoginDay; // 1 to 7 for Commander Login Track
  final int lastLoginClaimEpoch; // Timestamp of last claimed daily reward
  final bool isDronePermanent; // VIP Drone lifetime AI license
  final int droneRentalExpiryEpoch; // Expiry timestamp for rented VIP Drone
  final List<String> unlockedPermanentBoosters; // e.g. ['perm_quantum_overdrive', 'perm_sublight_thrusters']
  final CareerModel career;

  const GameState({
    required this.credits,
    required this.lifetimeCredits,
    required this.darkMatter,
    required this.totalShipsPurchased,
    required this.totalMergesCount,
    required this.totalLineCrossings,
    required this.highestTierUnlocked,
    this.feverCharge = 0.0,
    this.isFeverActive = false,
    this.feverTimeRemaining = 0.0,
    this.comboCount = 0,
    this.lastMergeTimestamp = 0,
    this.lastComboMessage = '',
    this.activeBoss,
    required this.lastSaveTimestamp,
    this.lastFreeSpinTimestamp = 0,
    this.extraSpinsCount = 1, // 1 free starter spin!
    required this.gridSlots,
    required this.trackShips,
    required this.relics,
    this.expeditions = const [],
    this.achievements = const [],
    this.currentLoginDay = 1,
    this.lastLoginClaimEpoch = 0,
    this.isDronePermanent = false,
    this.droneRentalExpiryEpoch = 0,
    this.unlockedPermanentBoosters = const [],
    required this.career,
  });


  bool get canSpinFree {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastFreeSpinTimestamp) >= (24 * 60 * 60 * 1000) ||
        extraSpinsCount > 0;
  }

  /// Whether player is eligible to claim today's Commander Login Reward (20h cooldown)
  bool get canClaimDailyReward {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastLoginClaimEpoch) >= (20 * 60 * 60 * 1000);
  }

  /// Whether the automated VIP support drone is actively running
  bool get isDroneCurrentlyActive {
    if (isDronePermanent) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now < droneRentalExpiryEpoch;
  }

  /// Permanent Income Multiplier from Store purchases
  double get permanentIncomeMultiplier =>
      unlockedPermanentBoosters.contains('perm_quantum_overdrive') ? 1.50 : 1.0;

  /// Permanent Ship Speed Multiplier from Store purchases
  double get permanentSpeedMultiplier =>
      unlockedPermanentBoosters.contains('perm_sublight_thrusters') ? 1.25 : 1.0;

  /// Number of completed expeditions ready for bounty collection
  int get readyExpeditionsCount =>
      expeditions.where((e) => e.isReadyToClaim).length;

  /// Number of unlocked achievements ready for Dark Matter collection
  int get unclaimedAchievementsCount =>
      achievements.where((a) => a.canClaim).length;

  /// Factory for fresh game state
  factory GameState.initial() {
    final List<ShipModel?> slots = List.generate(16, (index) => null);
    // Starter ship in slot 0
    slots[0] = ShipModel.create(1);

    return GameState(
      credits: 0.0,
      lifetimeCredits: 0.0,
      darkMatter: 0.0,
      totalShipsPurchased: 0,
      totalMergesCount: 0,
      totalLineCrossings: 0,
      highestTierUnlocked: 1,
      feverCharge: 0.0,
      isFeverActive: false,
      feverTimeRemaining: 0.0,
      comboCount: 0,
      lastMergeTimestamp: 0,
      lastComboMessage: '',
      lastSaveTimestamp: DateTime.now().millisecondsSinceEpoch,
      lastFreeSpinTimestamp: 0,
      extraSpinsCount: 1,
      currentLoginDay: 1,
      lastLoginClaimEpoch: 0,
      isDronePermanent: false,
      droneRentalExpiryEpoch: 0,
      unlockedPermanentBoosters: const [],
      gridSlots: slots,
      trackShips: [ShipModel.create(1)],
      relics: RelicModel.getInitialRelics(),
      expeditions: const [],
      achievements: AchievementModel.createInitialList(),
      career: CareerModel.initial(),
    );
  }

  /// Calculates potential Dark Matter on Galactic Reset: 150 * sqrt(Lifetime / 1e7)
  double get potentialPrestigeDarkMatter {
    if (lifetimeCredits < 500000.0) return 0.0;
    return max(1.0, (150.0 * sqrt(lifetimeCredits / 10000000.0))).floorToDouble();
  }

  GameState copyWith({
    double? credits,
    double? lifetimeCredits,
    double? darkMatter,
    int? totalShipsPurchased,
    int? totalMergesCount,
    int? totalLineCrossings,
    int? highestTierUnlocked,
    double? feverCharge,
    bool? isFeverActive,
    double? feverTimeRemaining,
    int? comboCount,
    int? lastMergeTimestamp,
    String? lastComboMessage,
    BossModel? activeBoss,
    bool clearActiveBoss = false,
    int? lastSaveTimestamp,
    int? lastFreeSpinTimestamp,
    int? extraSpinsCount,
    List<ShipModel?>? gridSlots,
    List<ShipModel>? trackShips,
    List<RelicModel>? relics,
    List<ExpeditionMission>? expeditions,
    List<AchievementModel>? achievements,
    int? currentLoginDay,
    int? lastLoginClaimEpoch,
    bool? isDronePermanent,
    int? droneRentalExpiryEpoch,
    List<String>? unlockedPermanentBoosters,
    CareerModel? career,
  }) {
    return GameState(
      credits: credits ?? this.credits,
      lifetimeCredits: lifetimeCredits ?? this.lifetimeCredits,
      darkMatter: darkMatter ?? this.darkMatter,
      totalShipsPurchased: totalShipsPurchased ?? this.totalShipsPurchased,
      totalMergesCount: totalMergesCount ?? this.totalMergesCount,
      totalLineCrossings: totalLineCrossings ?? this.totalLineCrossings,
      highestTierUnlocked: highestTierUnlocked ?? this.highestTierUnlocked,
      feverCharge: feverCharge ?? this.feverCharge,
      isFeverActive: isFeverActive ?? this.isFeverActive,
      feverTimeRemaining: feverTimeRemaining ?? this.feverTimeRemaining,
      comboCount: comboCount ?? this.comboCount,
      lastMergeTimestamp: lastMergeTimestamp ?? this.lastMergeTimestamp,
      lastComboMessage: lastComboMessage ?? this.lastComboMessage,
      activeBoss: clearActiveBoss ? null : (activeBoss ?? this.activeBoss),
      lastSaveTimestamp: lastSaveTimestamp ?? this.lastSaveTimestamp,
      lastFreeSpinTimestamp:
          lastFreeSpinTimestamp ?? this.lastFreeSpinTimestamp,
      extraSpinsCount: extraSpinsCount ?? this.extraSpinsCount,
      gridSlots: gridSlots ?? this.gridSlots,
      trackShips: trackShips ?? this.trackShips,
      relics: relics ?? this.relics,
      expeditions: expeditions ?? this.expeditions,
      achievements: achievements ?? this.achievements,
      currentLoginDay: currentLoginDay ?? this.currentLoginDay,
      lastLoginClaimEpoch: lastLoginClaimEpoch ?? this.lastLoginClaimEpoch,
      isDronePermanent: isDronePermanent ?? this.isDronePermanent,
      droneRentalExpiryEpoch:
          droneRentalExpiryEpoch ?? this.droneRentalExpiryEpoch,
      unlockedPermanentBoosters:
          unlockedPermanentBoosters ?? this.unlockedPermanentBoosters,
      career: career ?? this.career,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'credits': credits,
      'lifetimeCredits': lifetimeCredits,
      'darkMatter': darkMatter,
      'totalShipsPurchased': totalShipsPurchased,
      'totalMergesCount': totalMergesCount,
      'totalLineCrossings': totalLineCrossings,
      'highestTierUnlocked': highestTierUnlocked,
      'activeBoss': activeBoss?.toJson(),
      'lastSaveTimestamp': lastSaveTimestamp,
      'lastFreeSpinTimestamp': lastFreeSpinTimestamp,
      'extraSpinsCount': extraSpinsCount,
      'gridSlots': gridSlots.map((s) => s?.toJson()).toList(),
      'trackShips': trackShips.map((s) => s.toJson()).toList(),
      'relics': relics.map((r) => r.toJson()).toList(),
      'expeditions': expeditions.map((e) => e.toJson()).toList(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'currentLoginDay': currentLoginDay,
      'lastLoginClaimEpoch': lastLoginClaimEpoch,
      'isDronePermanent': isDronePermanent,
      'droneRentalExpiryEpoch': droneRentalExpiryEpoch,
      'unlockedPermanentBoosters': unlockedPermanentBoosters,
      'career': career.toJson(),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    // Hydrate achievements with base catalog defaults
    final List<AchievementModel> baseAchievements =
        AchievementModel.createInitialList();
    List<AchievementModel> loadedAchievements = baseAchievements;

    if (json['achievements'] != null) {
      final savedList = (json['achievements'] as List)
          .cast<Map<String, dynamic>>();
      loadedAchievements = baseAchievements.map((base) {
        final saved = savedList.firstWhere(
          (s) => s['id'] == base.id,
          orElse: () => <String, dynamic>{},
        );
        if (saved.isNotEmpty) {
          return base.copyWith(
            currentProgress: (saved['currentProgress'] as num?)?.toDouble() ?? 0.0,
            isClaimed: saved['isClaimed'] as bool? ?? false,
          );
        }
        return base;
      }).toList();
    }

    return GameState(
      credits: (json['credits'] as num?)?.toDouble() ?? 0.0,
      lifetimeCredits: (json['lifetimeCredits'] as num?)?.toDouble() ?? 0.0,
      darkMatter: (json['darkMatter'] as num?)?.toDouble() ?? 0.0,
      totalShipsPurchased: json['totalShipsPurchased'] as int? ?? 0,
      totalMergesCount: json['totalMergesCount'] as int? ?? 0,
      totalLineCrossings: json['totalLineCrossings'] as int? ?? 0,
      highestTierUnlocked: json['highestTierUnlocked'] as int? ?? 1,
      feverCharge: 0.0,
      isFeverActive: false,
      feverTimeRemaining: 0.0,
      comboCount: 0,
      lastMergeTimestamp: 0,
      lastComboMessage: '',
      activeBoss: json['activeBoss'] != null
          ? BossModel.fromJson(json['activeBoss'] as Map<String, dynamic>)
          : null,
      lastSaveTimestamp: json['lastSaveTimestamp'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
      lastFreeSpinTimestamp: json['lastFreeSpinTimestamp'] as int? ?? 0,
      extraSpinsCount: json['extraSpinsCount'] as int? ?? 1,
      gridSlots: json['gridSlots'] != null
          ? (json['gridSlots'] as List)
              .map((s) => s != null ? ShipModel.fromJson(s as Map<String, dynamic>) : null)
              .toList()
          : List.generate(16, (_) => null),
      trackShips: json['trackShips'] != null
          ? (json['trackShips'] as List)
              .map((s) => ShipModel.fromJson(s as Map<String, dynamic>))
              .toList()
          : [ShipModel.create(1)],
      relics: json['relics'] != null
          ? (json['relics'] as List)
              .map((r) => RelicModel.fromJson(r as Map<String, dynamic>))
              .toList()
          : RelicModel.getInitialRelics(),
      expeditions: json['expeditions'] != null
          ? (json['expeditions'] as List)
              .map((e) => ExpeditionMission.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      achievements: loadedAchievements,
      currentLoginDay: json['currentLoginDay'] as int? ?? 1,
      lastLoginClaimEpoch: json['lastLoginClaimEpoch'] as int? ?? 0,
      isDronePermanent: json['isDronePermanent'] as bool? ?? false,
      droneRentalExpiryEpoch: json['droneRentalExpiryEpoch'] as int? ?? 0,
      unlockedPermanentBoosters: json['unlockedPermanentBoosters'] != null
          ? List<String>.from(json['unlockedPermanentBoosters'] as List)
          : const [],
      career: json['career'] != null
          ? CareerModel.fromJson(json['career'] as Map<String, dynamic>)
          : CareerModel.initial(),
    );
  }




}




