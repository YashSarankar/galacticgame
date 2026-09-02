import 'dart:math';
import 'ship_model.dart';
import 'career_model.dart';


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
  final int lastSaveTimestamp; // Epoch milliseconds for offline earnings math
  final List<ShipModel?> gridSlots; // 16 items for 4x4 matrix
  final List<ShipModel> trackShips; // Active ships racing on Flame track
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
    required this.lastSaveTimestamp,
    required this.gridSlots,
    required this.trackShips,
    required this.career,
  });

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
      gridSlots: slots,
      trackShips: [ShipModel.create(1)],
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
    int? lastSaveTimestamp,
    List<ShipModel?>? gridSlots,
    List<ShipModel>? trackShips,
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
      lastSaveTimestamp: lastSaveTimestamp ?? this.lastSaveTimestamp,
      gridSlots: gridSlots ?? this.gridSlots,
      trackShips: trackShips ?? this.trackShips,
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
      'lastSaveTimestamp': lastSaveTimestamp,
      'gridSlots': gridSlots.map((s) => s?.toJson()).toList(),
      'trackShips': trackShips.map((s) => s.toJson()).toList(),
      'career': career.toJson(),
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
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
      lastSaveTimestamp: json['lastSaveTimestamp'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
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
      career: json['career'] != null
          ? CareerModel.fromJson(json['career'] as Map<String, dynamic>)
          : CareerModel.initial(),
    );
  }
}


