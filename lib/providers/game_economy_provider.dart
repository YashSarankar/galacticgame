import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/ship_model.dart';


import '../models/mission_model.dart';
import '../models/skill_node_model.dart';
import '../models/career_model.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';

class GameEconomyNotifier extends StateNotifier<GameState> {
  final SoundService _soundService = SoundService();

  GameEconomyNotifier(super.initialState);

  /// Load state from persistent storage
  void loadFromState(GameState loadedState) {
    state = loadedState;
  }

  /// Adds crossing income whenever a ship crosses the laser income line on track
  void recordIncomeLineCrossing(ShipModel ship, {double adMultiplier = 1.0}) {
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

    final double permanentMultiplier = 1.0 + incomeSkill.currentBonusValue;
    final double totalPayout = ship.calculateIncomePayout(
      multiplier: permanentMultiplier * adMultiplier,
    );

    final int newCrossings = state.totalLineCrossings + 1;
    final double newCredits = state.credits + totalPayout;
    final double newLifetime = state.lifetimeCredits + totalPayout;

    // Update missions reacting to crossings
    final updatedMissions = _evaluateMissions(
      state.career.missions,
      crossingsIncrement: 1,
      coinsIncrement: totalPayout,
    );

    state = state.copyWith(
      credits: newCredits,
      lifetimeCredits: newLifetime,
      totalLineCrossings: newCrossings,
      career: state.career.copyWith(missions: updatedMissions),
    );

    _soundService.playIncomeSound();
    _autoSaveDebounced();
  }

  /// Buys base ship from shipyard
  bool purchaseShip() {
    final discountSkill = state.career.skills.firstWhere(
      (s) => s.effectType == SkillEffectType.shipDiscount,
      orElse: () => const SkillNodeModel(
        id: '',
        title: '',
        description: '',
        iconAsset: '',
        effectType: SkillEffectType.shipDiscount,
        level: 0,
        maxLevel: 8,
        baseCost: 0,
        costMultiplier: 1,
        valuePerLevel: 0.05,
      ),
    );

    final int dropTier = activeStoreBuyTier;
    final double cost = ShipModel.calculatePurchaseCost(

      state.totalShipsPurchased,
      dropTier,
      discount: discountSkill.currentBonusValue,
    );

    if (state.credits < cost) {
      return false; // Not enough credits
    }

    final int unlockedLimit = maxUnlockedGridSlots;

    // Find first empty grid slot within unlocked hangar bays
    int emptyIndex = -1;
    for (int i = 0; i < unlockedLimit; i++) {
      if (state.gridSlots[i] == null) {
        emptyIndex = i;
        break;
      }
    }
    if (emptyIndex == -1) {
      return false; // Unlocked grid capacity full
    }

    final newSlots = List<ShipModel?>.from(state.gridSlots);
    final newShip = ShipModel.create(dropTier);
    newSlots[emptyIndex] = newShip;

    final int newPurchased = state.totalShipsPurchased + 1;
    final double newCredits = state.credits - cost;
    final int newHighest = max(state.highestTierUnlocked, dropTier);

    // Update missions
    final updatedMissions = _evaluateMissions(
      state.career.missions,
      buyCountIncrement: 1,
      unlockedTier: dropTier,
    );

    state = state.copyWith(
      credits: newCredits,
      totalShipsPurchased: newPurchased,
      highestTierUnlocked: newHighest,
      gridSlots: newSlots,
      trackShips: computeTrackFleet(newSlots),
      career: state.career.copyWith(missions: updatedMissions),
    );

    _soundService.playPurchaseSound();
    _autoSaveDebounced();
    return true;
  }

  /// Calculates dynamic purchasable ship tier (evolves with highest tier unlocked and tech tree)
  int get activeStoreBuyTier {
    final baseTierSkill = state.career.skills.firstWhere(
      (s) => s.effectType == SkillEffectType.baseDropTier,
      orElse: () => const SkillNodeModel(
        id: '',
        title: '',
        description: '',
        iconAsset: '',
        effectType: SkillEffectType.baseDropTier,
        level: 0,
        maxLevel: 5,
        baseCost: 0,
        costMultiplier: 1,
        valuePerLevel: 1,
      ),
    );

    final int techBase = 1 + baseTierSkill.level;
    final int milestoneTier = max(1, state.highestTierUnlocked - 2);
    return max(techBase, milestoneTier);
  }

  /// Spawns a mystery cosmic supply crate directly onto an empty grid slot
  bool dropMysteryCargo() {
    final int unlockedLimit = maxUnlockedGridSlots;
    final List<int> emptyIndices = [];
    for (int i = 0; i < unlockedLimit; i++) {
      if (state.gridSlots[i] == null) {
        emptyIndices.add(i);
      }
    }
    if (emptyIndices.isEmpty) return false;

    final random = Random();
    final int targetSlot = emptyIndices[random.nextInt(emptyIndices.length)];

    final int minTier = activeStoreBuyTier;
    final int maxTier = max(minTier, state.highestTierUnlocked);
    final int awardedTier = minTier + random.nextInt(maxTier - minTier + 1);

    final newSlots = List<ShipModel?>.from(state.gridSlots);
    newSlots[targetSlot] = ShipModel.create(awardedTier);

    final int newHighest = max(state.highestTierUnlocked, awardedTier);

    state = state.copyWith(
      gridSlots: newSlots,
      trackShips: computeTrackFleet(newSlots),
      highestTierUnlocked: newHighest,
    );

    _soundService.playPrestigeSound();
    _autoSaveDebounced();
    return true;
  }

  /// Calculates max unlocked merge slots (8 base + 2 per Hangar expansion level)
  int get maxUnlockedGridSlots {
    final gridSkill = state.career.skills.firstWhere(
      (s) => s.effectType == SkillEffectType.gridExpansion,
      orElse: () => const SkillNodeModel(
        id: '',
        title: '',
        description: '',
        iconAsset: '',
        effectType: SkillEffectType.gridExpansion,
        level: 0,
        maxLevel: 4,
        baseCost: 0,
        costMultiplier: 1,
        valuePerLevel: 2,
      ),
    );
    return min(16, 8 + (gridSkill.level * 2));
  }

  /// Awards bonus credits / DM when player shatters an asteroid hazard
  void recordAsteroidShattered({bool isDarkMatter = false, double rewardCredits = 50.0}) {
    if (isDarkMatter) {
      state = state.copyWith(darkMatter: state.darkMatter + 1.0);
    } else {
      state = state.copyWith(
        credits: state.credits + rewardCredits,
        lifetimeCredits: state.lifetimeCredits + rewardCredits,
      );
    }
    _soundService.playPurchaseSound();
    _autoSaveDebounced();
  }

  /// Handles 4x4 Grid Slot Merging and Movement
  bool handleGridMergeOrMove(int fromIndex, int toIndex) {
    final int unlockedLimit = maxUnlockedGridSlots;
    if (fromIndex < 0 ||
        fromIndex >= unlockedLimit ||
        toIndex < 0 ||
        toIndex >= unlockedLimit ||
        fromIndex == toIndex) {
      return false;
    }

    final sourceShip = state.gridSlots[fromIndex];
    if (sourceShip == null) return false;

    final targetShip = state.gridSlots[toIndex];
    final newSlots = List<ShipModel?>.from(state.gridSlots);

    if (targetShip == null) {
      // Simple Move
      newSlots[toIndex] = sourceShip;
      newSlots[fromIndex] = null;
      state = state.copyWith(
        gridSlots: newSlots,
        trackShips: computeTrackFleet(newSlots),
      );
      _soundService.playButtonHaptic();
      _autoSaveDebounced();
      return true;
    }

    if (sourceShip.tier == targetShip.tier) {
      // Merge into Tier + 1
      final int newTier = sourceShip.tier + 1;
      final mergedShip = ShipModel.create(newTier);

      newSlots[toIndex] = mergedShip;
      newSlots[fromIndex] = null;

      final int newMergeCount = state.totalMergesCount + 1;
      final int newHighest = max(state.highestTierUnlocked, newTier);

      final updatedMissions = _evaluateMissions(
        state.career.missions,
        mergesIncrement: 1,
        unlockedTier: newTier,
      );

      state = state.copyWith(
        gridSlots: newSlots,
        trackShips: computeTrackFleet(newSlots),
        totalMergesCount: newMergeCount,
        highestTierUnlocked: newHighest,
        career: state.career.copyWith(missions: updatedMissions),
      );

      _soundService.playMergeSound();
      _autoSaveDebounced();
      return true;
    } else {
      // Swap positions
      newSlots[fromIndex] = targetShip;
      newSlots[toIndex] = sourceShip;
      state = state.copyWith(
        gridSlots: newSlots,
        trackShips: computeTrackFleet(newSlots),
      );
      _soundService.playButtonHaptic();
      _autoSaveDebounced();
      return true;
    }
  }


  /// Derives active racing track fleet directly from grid slots (highest tiers first, max 6)
  static List<ShipModel> computeTrackFleet(List<ShipModel?> gridSlots, {int maxTrackCapacity = 6}) {
    final List<ShipModel> activeGridShips = gridSlots.whereType<ShipModel>().toList();
    if (activeGridShips.isEmpty) {
      return [ShipModel.create(1)];
    }
    // Sort descending by tier so the strongest ships race on the track
    activeGridShips.sort((a, b) => b.tier.compareTo(a.tier));
    return activeGridShips.take(maxTrackCapacity).toList();
  }



  /// Upgrades a Skill Node using Dark Matter
  bool upgradeSkill(String skillId) {
    final int skillIndex =
        state.career.skills.indexWhere((s) => s.id == skillId);
    if (skillIndex == -1) return false;

    final skill = state.career.skills[skillIndex];
    final double cost = skill.currentUpgradeCost;

    if (skill.isMaxed || state.darkMatter < cost) {
      return false;
    }

    final updatedSkill = skill.copyWith(level: skill.level + 1);
    final updatedSkills = List<SkillNodeModel>.from(state.career.skills);
    updatedSkills[skillIndex] = updatedSkill;

    state = state.copyWith(
      darkMatter: state.darkMatter - cost,
      career: state.career.copyWith(skills: updatedSkills),
    );

    _soundService.playPurchaseSound();
    _autoSaveDebounced();
    return true;
  }

  /// Claims reward for a completed mission
  bool claimMission(String missionId) {
    final int index =
        state.career.missions.indexWhere((m) => m.id == missionId);
    if (index == -1) return false;

    final mission = state.career.missions[index];
    if (!mission.isCompleted || mission.isClaimed) return false;

    final updatedMission = mission.copyWith(isClaimed: true);
    final updatedMissions = List<MissionModel>.from(state.career.missions);
    updatedMissions[index] = updatedMission;

    state = state.copyWith(
      credits: state.credits + mission.rewardCoins,
      darkMatter: state.darkMatter + mission.rewardDarkMatter,
      career: state.career.copyWith(missions: updatedMissions),
    );

    _soundService.playPrestigeSound();
    _autoSaveDebounced();
    return true;
  }

  /// Performs Galactic Prestige Reset
  void performGalacticPrestige({bool doubleYield = false}) {
    final double baseYield = state.potentialPrestigeDarkMatter;
    final double actualDarkMatterEarned =
        baseYield * (doubleYield ? 2.0 : 1.0);

    final int newPrestigeCount = state.career.prestigeCount + 1;
    final int newSectorLevel = state.career.sectorLevel + 1;

    // Reset grid with starter ship
    final List<ShipModel?> freshSlots = List.generate(16, (_) => null);
    freshSlots[0] = ShipModel.create(1);

    state = state.copyWith(
      credits: 250.0,
      lifetimeCredits: 250.0,
      darkMatter: state.darkMatter + actualDarkMatterEarned,
      totalShipsPurchased: 0,
      gridSlots: freshSlots,
      trackShips: [ShipModel.create(1)],
      career: state.career.copyWith(
        sectorLevel: newSectorLevel,
        sectorName: CareerModel.getSectorTitle(newSectorLevel),
        prestigeCount: newPrestigeCount,
        missions: MissionModel.getInitialMissions(),
      ),
    );

    _soundService.playPrestigeSound();
    _autoSaveDebounced();
  }

  /// Claims Offline Earnings from Modal
  void claimOfflineEarnings(double amount, {bool doubleReward = false}) {
    final double finalCoins = amount * (doubleReward ? 2.0 : 1.0);
    state = state.copyWith(
      credits: state.credits + finalCoins,
      lifetimeCredits: state.lifetimeCredits + finalCoins,
    );
    _soundService.playPurchaseSound();
    _autoSaveDebounced();
  }

  /// Evaluates and advances missions based on actions
  List<MissionModel> _evaluateMissions(
    List<MissionModel> currentMissions, {
    int mergesIncrement = 0,
    int crossingsIncrement = 0,
    int buyCountIncrement = 0,
    double coinsIncrement = 0,
    int unlockedTier = 0,
  }) {
    return currentMissions.map((mission) {
      if (mission.isClaimed) return mission;

      double newProgress = mission.currentProgress;
      switch (mission.type) {
        case MissionType.mergeCount:
          newProgress += mergesIncrement;
          break;
        case MissionType.crossCount:
          newProgress += crossingsIncrement;
          break;
        case MissionType.buyShipCount:
          newProgress += buyCountIncrement;
          break;
        case MissionType.earnCoins:
          newProgress += coinsIncrement;
          break;
        case MissionType.unlockTier:
          if (unlockedTier > newProgress) {
            newProgress = unlockedTier.toDouble();
          }
          break;
      }

      return mission.copyWith(currentProgress: newProgress);
    }).toList();
  }

  void _autoSaveDebounced() {
    StorageService.saveGameState(state);
  }
}
