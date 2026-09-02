import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/skill_node_model.dart';

/// Result summary of offline income calculation.
class OfflineEarningsResult {
  final int elapsedSeconds;
  final int cappedSeconds;
  final double coinsEarned;
  final double ratePerSecond;

  const OfflineEarningsResult({
    required this.elapsedSeconds,
    required this.cappedSeconds,
    required this.coinsEarned,
    required this.ratePerSecond,
  });

  bool get hasSignificantEarnings => coinsEarned >= 1.0 && elapsedSeconds >= 10;
}

/// Service handling local storage persistence and offline calculations.
class StorageService {
  static const String _gameStateKey = 'galactic_game_state_v1';
  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences instance
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save current game state
  static Future<void> saveGameState(GameState state) async {
    try {
      final updatedState = state.copyWith(
        lastSaveTimestamp: DateTime.now().millisecondsSinceEpoch,
      );
      final jsonString = jsonEncode(updatedState.toJson());
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(_gameStateKey, jsonString);
    } catch (e) {
      debugPrint('[StorageService] Error saving state: $e');
    }
  }

  /// Load game state from storage
  static Future<GameState> loadGameState() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final jsonString = _prefs!.getString(_gameStateKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return GameState.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('[StorageService] Error loading state: $e');
    }
    return GameState.initial();
  }


  /// Clear all saved data from storage
  static Future<void> clearAll() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.clear();
    } catch (e) {
      debugPrint('[StorageService] Error clearing state: $e');
    }
  }


  /// Calculate offline earnings since last session
  static OfflineEarningsResult calculateOfflineEarnings(GameState state) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int lastSaved = state.lastSaveTimestamp;
    final int elapsedSeconds = max(0, ((now - lastSaved) / 1000).floor());

    // Compute max offline cap from skill tree
    final offlineSkill = state.career.skills.firstWhere(
      (s) => s.effectType == SkillEffectType.offlineCapHours,
      orElse: () => const SkillNodeModel(
        id: '',
        title: '',
        description: '',
        iconAsset: '',
        effectType: SkillEffectType.offlineCapHours,
        level: 0,
        maxLevel: 11,
        baseCost: 0,
        costMultiplier: 1,
        valuePerLevel: 2,
      ),
    );

    final double maxOfflineHours = 2.0 + (offlineSkill.level * 2.0); // 2h up to 24h
    final int maxOfflineCapSeconds = (maxOfflineHours * 3600).round();
    final int cappedSeconds = min(elapsedSeconds, maxOfflineCapSeconds);

    // Calculate approximate earnings per second based on active track ships
    // Standard track loop length is ~1400 units
    const double approxTrackLength = 1400.0;
    double incomePerSec = 0.0;

    // Income boost from skill tree
    final incomeSkill = state.career.skills.firstWhere(
      (s) => s.effectType == SkillEffectType.globalIncomeBoost,
      orElse: () => const SkillNodeModel(
        id: '',
        title: '',
        description: '',
        iconAsset: '',
        effectType: SkillEffectType.globalIncomeBoost,
        level: 0,
        maxLevel: 20,
        baseCost: 0,
        costMultiplier: 1,
        valuePerLevel: 0.25,
      ),
    );
    final double incomeMultiplier = 1.0 + incomeSkill.currentBonusValue;

    for (final ship in state.trackShips) {
      final double crossingFreq = ship.baseSpeed / approxTrackLength;
      incomePerSec += ship.calculateIncomePayout(multiplier: incomeMultiplier) * crossingFreq;
    }

    // Default baseline if no ships
    if (incomePerSec <= 0.0) {
      incomePerSec = 5.0;
    }

    final double totalOfflineCoins = cappedSeconds * incomePerSec;

    return OfflineEarningsResult(
      elapsedSeconds: elapsedSeconds,
      cappedSeconds: cappedSeconds,
      coinsEarned: totalOfflineCoins,
      ratePerSecond: incomePerSec,
    );
  }
}
