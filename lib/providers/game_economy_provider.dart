import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/ship_model.dart';
import '../models/boss_model.dart';
import '../models/relic_model.dart';
import '../models/roulette_reward_model.dart';
import '../models/mission_model.dart';
import '../models/expedition_model.dart';
import '../models/daily_login_model.dart';
import '../models/store_item_model.dart';
import '../models/skill_node_model.dart';
import '../models/achievement_model.dart';
import '../models/mystery_card_model.dart';
import '../models/career_model.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/user_growth_service.dart';
import '../services/iap_service.dart';


enum DispatchResult {
  successAdded,
  successReplaced,
  alreadyOnTrack,
  fleetFullLowerTier,
  invalidShip,
}

class GameEconomyNotifier extends StateNotifier<GameState> {
  final SoundService _soundService = SoundService();
  void Function(int newTierDiscovered)? onShipDiscovered;
  void Function(int tier, List<UnlockedFeatureInfo> features)? onFeatureUnlocked;
  int _tutorialTapCount = 0;

  GameEconomyNotifier(super.initialState) {
    _initIap();
  }

  void _initIap() {
    final iap = InAppPurchaseService();
    iap.onVipPurchased = () {
      purchaseRemoveAds();
    };
    iap.onDarkMatterPurchased = (dm) {
      state = state.copyWith(darkMatter: state.darkMatter + dm);
      _soundService.playPrestigeSound();
      _autoSaveDebounced();
    };
    iap.onCreditsPurchased = (cr) {
      state = state.copyWith(
        credits: state.credits + cr,
        lifetimeCredits: state.lifetimeCredits + cr,
      );
      _soundService.playPurchaseSound();
      _autoSaveDebounced();
    };
  }

  /// Load state from persistent storage
  void loadFromState(GameState loadedState) {
    state = loadedState.copyWith(
      lastSaveTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Stretches and stamps in-memory save timestamp to current epoch ms to keep offline earnings accurate
  void stampSaveTimestamp() {
    state = state.copyWith(
      lastSaveTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _autoSaveDebounced();
  }

  /// Manually advance tutorial step
  void advanceTutorialStep(int nextStep) {
    state = state.copyWith(tutorialStep: nextStep);
    _autoSaveDebounced();
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
    final double feverMultiplier = state.isFeverActive ? 3.0 : 1.0;
    final double totalPayout = ship.calculateIncomePayout(
      multiplier: permanentMultiplier *
          state.permanentIncomeMultiplier *
          state.circuitIncomeMultiplier *
          adMultiplier *
          feverMultiplier *
          relicIncomeMultiplier,
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

  /// Explicitly dispatches a ship from the grid onto the flight racetrack canvas
  DispatchResult dispatchShipToTrack(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= state.gridSlots.length) {
      return DispatchResult.invalidShip;
    }
    final ship = state.gridSlots[slotIndex];
    if (ship == null || ship.isBox) return DispatchResult.invalidShip;

    // Check if this specific ship is already active on the racetrack
    if (state.trackShips.any((s) => s.id == ship.id)) {
      return DispatchResult.alreadyOnTrack;
    }

    final updatedTrackShips = List<ShipModel>.from(state.trackShips);
    DispatchResult result = DispatchResult.successAdded;

    if (updatedTrackShips.length >= 4) {
      // Find lowest tier currently on track
      updatedTrackShips.sort((a, b) => a.tier.compareTo(b.tier));
      final int lowestTier = updatedTrackShips.first.tier;
      if (ship.tier > lowestTier) {
        // Upgrade fleet: Replace lowest tier with the new higher-tier starship
        updatedTrackShips.removeAt(0);
        updatedTrackShips.add(ship);
        result = DispatchResult.successReplaced;
      } else {
        // Validation: Fleet capacity is full (4/4) and cannot accept lower or equal tier
        return DispatchResult.fleetFullLowerTier;
      }
    } else {
      updatedTrackShips.add(ship);
      result = DispatchResult.successAdded;
    }

    final int nextTutorial = state.tutorialStep == 0 ? 1 : state.tutorialStep;
    final double starterBonus = state.tutorialStep == 0 ? 25.0 : 0.0;

    state = state.copyWith(
      credits: state.credits + starterBonus,
      lifetimeCredits: state.lifetimeCredits + starterBonus,
      tutorialStep: nextTutorial,
      trackShips: updatedTrackShips,
    );

    _soundService.playPurchaseSound();
    _autoSaveDebounced();
    return result;
  }

  /// Upgrade Fleet Engine Speed (+2% speed per level, max Lv.30) using Credits
  bool upgradeFleetSpeed() {
    if (state.isFleetSpeedMaxed) return false;
    final double cost = state.fleetSpeedUpgradeCost;
    if (state.credits < cost) return false;

    // Advance tutorial step 4 (Fleet Speed) -> Step 5 (Completed)
    final int nextTutorial = state.tutorialStep == 4 ? 5 : state.tutorialStep;
    final double rewardBonus = state.tutorialStep == 4 ? 500.0 : 0.0;

    state = state.copyWith(
      credits: state.credits - cost + rewardBonus,
      lifetimeCredits: state.lifetimeCredits + rewardBonus,
      fleetSpeedLevel: state.fleetSpeedLevel + 1,
      tutorialStep: nextTutorial,
    );
    _soundService.playPurchaseSound();
    _autoSaveDebounced();
    return true;
  }

  /// Unlock next Laser Finish Gate on the circuit (up to 4 gates)
  bool unlockNextFinishLine() {
    final double? cost = state.nextFinishLineCost;
    if (cost == null || state.credits < cost || state.finishLinesCount >= 4) {
      return false;
    }

    // Advance tutorial step 4 (Circuit Laser Gates) -> Step 5 (Completed)
    final int nextTutorial = state.tutorialStep == 4 ? 5 : state.tutorialStep;
    final double rewardBonus = state.tutorialStep == 4 ? 500.0 : 0.0;

    state = state.copyWith(
      credits: state.credits - cost + rewardBonus,
      lifetimeCredits: state.lifetimeCredits + rewardBonus,
      finishLinesCount: state.finishLinesCount + 1,
      tutorialStep: nextTutorial,
    );
    _soundService.playPrestigeSound();
    _autoSaveDebounced();
    return true;
  }

  /// Evolve the Racetrack Circuit to the next tier (resets gates to 1 on the new tier with huge multiplier!)
  bool evolveTrackCircuit() {
    final double cost = state.trackEvolutionCost;
    if (state.finishLinesCount < 4 || state.credits < cost) {
      return false;
    }

    state = state.copyWith(
      credits: state.credits - cost,
      circuitTier: state.circuitTier + 1,
      finishLinesCount: 1, // Reset laser gates for the new evolved track
    );
    _soundService.playPrestigeSound();
    _autoSaveDebounced();
    return true;
  }

  /// Installs the next on-track Hyper Boost Pad (Pad 1 or Pad 2, max 2 pads per circuit)
  bool unlockNextBoostPad() {
    if (state.isBoostPadCountMaxed) return false;
    final double? cost = state.nextBoostPadInstallCost;
    if (cost == null || state.credits < cost) return false;

    state = state.copyWith(
      credits: state.credits - cost,
      boostPadCount: state.boostPadCount + 1,
    );
    _soundService.playPurchaseSound();
    _autoSaveDebounced();
    return true;
  }

  /// Upgrade Hyper-Pads Boost multiplier (Lv.1 to 10) using Credits
  bool upgradeBoostPad() {
    if (state.boostPadLevel >= 10) return false;
    final double cost = state.boostPadUpgradeCost;
    if (state.credits < cost) return false;

    state = state.copyWith(
      credits: state.credits - cost,
      boostPadLevel: state.boostPadLevel + 1,
    );
    _soundService.playPurchaseSound();
    _autoSaveDebounced();
    return true;
  }

  /// Claims reward for a completed Commander Learning Quest
  bool claimLearningMilestone(int questId) {
    if (state.claimedLearningMilestones.contains(questId)) return false;

    final quest = UserGrowthService.learningQuests.firstWhere(
      (q) => q.id == questId,
      orElse: () => UserGrowthService.learningQuests.first,
    );

    if (!quest.checkCompleted(state)) return false;

    final updatedClaimed = List<int>.from(state.claimedLearningMilestones)
      ..add(questId);

    state = state.copyWith(
      credits: state.credits + quest.rewardCredits,
      darkMatter: state.darkMatter + quest.rewardDarkMatter,
      claimedLearningMilestones: updatedClaimed,
    );

    _soundService.playClaimSound();
    _autoSaveDebounced();
    return true;
  }

  /// Tapping the racetrack charges the Hyperspace Warp Meter (+4% per tap)




  void tapRacetrackBoost() {
    // If on tutorial step 1 (Turbo Tap Speed), require 3 energetic taps to advance to Step 2!
    if (state.tutorialStep == 1) {
      _tutorialTapCount++;
      const double tapReward = 15.0;
      if (_tutorialTapCount >= 3) {
        state = state.copyWith(
          tutorialStep: 2,
          credits: state.credits + tapReward + 25.0,
          lifetimeCredits: state.lifetimeCredits + tapReward + 25.0,
        );
      } else {
        state = state.copyWith(
          credits: state.credits + tapReward,
          lifetimeCredits: state.lifetimeCredits + tapReward,
        );
      }
    }

    // Tapping directly charges Nitro Overdrive (+3.5% per tap)
    if (!state.isNitroActive && state.nitroCharge < 1.0) {
      final double newCharge = min(1.0, state.nitroCharge + 0.035);
      state = state.copyWith(nitroCharge: newCharge);
    }
    _soundService.playTrackTapSound();
  }

  /// Ticks down active Nitro Warp timer or passively recharges Nitro bar (recharges in 45s)
  void tickNitro(double dt) {
    if (state.isNitroActive) {
      final double remaining = state.nitroSecondsRemaining - dt;
      if (remaining <= 0) {
        state = state.copyWith(
          isNitroActive: false,
          nitroSecondsRemaining: 0.0,
          nitroCharge: 0.0,
        );
      } else {
        state = state.copyWith(
          nitroSecondsRemaining: remaining,
        );
      }
    } else if (state.nitroCharge < 1.0) {
      final double recharged = min(1.0, state.nitroCharge + (dt / 45.0));
      state = state.copyWith(nitroCharge: recharged);
    }

    // Reset combo message after 2.5 seconds of inactivity
    if (state.lastComboMessage.isNotEmpty) {
      final int now = DateTime.now().millisecondsSinceEpoch;
      if (now - state.lastMergeTimestamp > 2500) {
        state = state.copyWith(
          lastComboMessage: '',
          comboCount: 0,
        );
      }
    }
  }

  /// Activates 5-second Hyperspace Nitro Overdrive (2.0x speed boost and coin stream)
  bool activateNitroOverdrive() {
    if (state.nitroCharge < 0.99 || state.isNitroActive) return false;

    state = state.copyWith(
      isNitroActive: true,
      nitroSecondsRemaining: 5.0,
      nitroCharge: 0.0,
    );

    _soundService.playFeverSound();
    return true;
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
    final double rawCost = ShipModel.calculatePurchaseCost(
      state.totalShipsPurchased,
      dropTier,
      discount: discountSkill.currentBonusValue,
    );
    // In Tutorial Step 2 ("Buy Second Ship"), ensure player can afford it with earned coins
    final double cost = state.tutorialStep == 2 ? min(rawCost, state.credits) : rawCost;

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

    // Advance tutorial step 2 (Buy Ship) -> Step 3 (Merge Ships)
    final int nextTutorial =
        state.tutorialStep == 2 ? 3 : state.tutorialStep;

    state = state.copyWith(
      credits: newCredits,
      totalShipsPurchased: newPurchased,
      highestTierUnlocked: newHighest,
      gridSlots: newSlots,
      trackShips: computeTrackFleet(newSlots),
      tutorialStep: nextTutorial,
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
    // Upgrade buy button tier to (highestTierUnlocked - 1) upon discovering higher tiers
    final int milestoneTier = max(1, state.highestTierUnlocked - 1);
    return max(techBase, milestoneTier);
  }

  /// Calculates dynamic cost to purchase the next spaceship
  double get nextShipBuyCost {
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
    final double rawCost = ShipModel.calculatePurchaseCost(
      state.totalShipsPurchased,
      dropTier,
      discount: discountSkill.currentBonusValue,
    );
    return state.tutorialStep == 2 ? min(rawCost, max(10.0, state.credits)) : rawCost;
  }

  /// Spawns a mystery cosmic supply crate directly onto an empty grid slot (waiting to be tapped!)
  /// Keeps exactly 1 crate on the grid at a time to keep merge deck clean and prevent clutter.
  bool dropMysteryCargo({int? tier, bool? isAdBox}) {
    // Only 1 unopened crate on the grid at a time
    final int existingCrates =
        state.gridSlots.where((s) => s != null && s.isBox).length;
    if (existingCrates >= 1) return false;

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

    // 50% chance of being an Ad Crate for players who unlocked Tier 2+
    final bool isAdCrate = isAdBox ??
        (state.highestTierUnlocked >= 2 && random.nextBool());

    final int awardedTier;
    if (tier != null && tier > 0) {
      awardedTier = tier.clamp(1, 50);
    } else {
      final int minTier = activeStoreBuyTier;
      final int bonusBoost = isAdCrate ? 1 : 0;
      final int maxTier = max(minTier, state.highestTierUnlocked + bonusBoost);
      awardedTier = min(50, minTier + random.nextInt(maxTier - minTier + 1));
    }

    final newSlots = List<ShipModel?>.from(state.gridSlots);
    newSlots[targetSlot] =
        ShipModel.create(awardedTier, null, true, isAdCrate); // isBox: true, isAdBox: isAdCrate!

    state = state.copyWith(
      gridSlots: newSlots,
    );

    _soundService.playPurchaseSound();
    _autoSaveDebounced();
    return true;
  }


  /// Taps on a delivery crate to unbox the surprise ship inside!
  bool openCrate(int index) {
    if (index < 0 || index >= state.gridSlots.length) return false;
    final ship = state.gridSlots[index];
    if (ship == null || !ship.isBox) return false;

    final newSlots = List<ShipModel?>.from(state.gridSlots);
    final unboxedShip = ship.copyWith(isBox: false);
    newSlots[index] = unboxedShip;

    final int newHighest = max(state.highestTierUnlocked, unboxedShip.tier);

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
    final bool canEarnDM = state.highestTierUnlocked >= 3;
    if (isDarkMatter && canEarnDM) {
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

    // Defensive Validation: Unopened delivery crates cannot be merged
    if (sourceShip.isBox || targetShip.isBox) {
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

    if (sourceShip.tier == targetShip.tier) {
      // Merge into Tier + 1 (clamped to max tier 50)
      final int newTier = min(50, sourceShip.tier + 1);
      final mergedShip = ShipModel.create(newTier);

      newSlots[toIndex] = mergedShip;
      newSlots[fromIndex] = null;

      final int newMergeCount = state.totalMergesCount + 1;
      final bool isNewDiscovery = newTier > state.highestTierUnlocked;
      final int newHighest = max(state.highestTierUnlocked, newTier);

      final updatedMissions = _evaluateMissions(
        state.career.missions,
        mergesIncrement: 1,
        unlockedTier: newTier,
      );

      final List<int> newAcknowledged =
          List<int>.from(state.acknowledgedUnlockTiers);
      if (isNewDiscovery && !newAcknowledged.contains(newTier)) {
        newAcknowledged.add(newTier);
      }

      // Advance tutorial step 3 (Merge Ships) -> Step 4 (Circuit Laser Gates / Fleet Speed)
      final int nextTutorial =
          state.tutorialStep == 3 ? 4 : state.tutorialStep;
      final double tutorialMergeGrant =
          state.tutorialStep == 3 ? 150.0 : 0.0;

      final double discoveryBountyCredits = (isNewDiscovery && newTier > 1)
          ? (ShipModel.calculatePurchaseCost(0, newTier) * 0.50).floorToDouble()
          : 0.0;
      final double discoveryBountyDm =
          (isNewDiscovery && newTier >= 3) ? (newTier * 2.0) : 0.0;

      final double totalCreditsGained =
          tutorialMergeGrant + discoveryBountyCredits;

      state = state.copyWith(
        credits: state.credits + totalCreditsGained,
        lifetimeCredits: state.lifetimeCredits + totalCreditsGained,
        darkMatter: state.darkMatter + discoveryBountyDm,
        gridSlots: newSlots,
        trackShips: computeTrackFleet(newSlots),
        totalMergesCount: newMergeCount,
        highestTierUnlocked: newHighest,
        comboCount: 0,
        lastComboMessage: '',
        tutorialStep: nextTutorial,
        acknowledgedUnlockTiers: newAcknowledged,
        career: state.career.copyWith(missions: updatedMissions),
      );

      if (isNewDiscovery && newTier > 1) {
        onShipDiscovered?.call(newTier);
        final unlocked = UserGrowthService.getFeaturesUnlockedAtTier(newTier);
        if (unlocked.isNotEmpty) {
          onFeatureUnlocked?.call(newTier, unlocked);
        }
      }

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

  /// Recycles/disassembles a ship from the grid to refund 70% of its base purchase value
  /// Returns:
  /// - `> 0`: refund credit amount awarded
  /// - `0.0`: invalid slot or box
  /// - `-1.0`: defensive protection - cannot scrap the last remaining active ship in the fleet!
  double recycleShip(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= state.gridSlots.length) return 0.0;
    final ship = state.gridSlots[slotIndex];
    if (ship == null || ship.isBox) return 0.0;

    // Defensive Protection: Player must always retain at least 1 active spacecraft!
    final int activeShips =
        state.gridSlots.where((s) => s != null && !s.isBox).length;
    if (activeShips <= 1) {
      return -1.0;
    }

    // Balanced scrap refund: 30% of base tier price (avoids purchase count exponential inflation)
    final double refund =
        (ShipModel.calculatePurchaseCost(0, ship.tier) * 0.30).floorToDouble();

    final newSlots = List<ShipModel?>.from(state.gridSlots);
    newSlots[slotIndex] = null;

    state = state.copyWith(
      credits: state.credits + refund,
      lifetimeCredits: state.lifetimeCredits + refund,
      gridSlots: newSlots,
      trackShips: computeTrackFleet(newSlots),
    );

    _soundService.playPurchaseSound();
    _autoSaveDebounced();
    return refund;
  }


  /// Recycles the lowest tier ship on the grid to instantly resolve grid deadlock
  double recycleLowestTierShip() {
    final int? lowestIndex = state.lowestTierSlotIndex;
    if (lowestIndex == null) return 0.0;
    return recycleShip(lowestIndex);
  }

  /// Automatically merges all available pairs on the flight deck with one tap and compacts the grid
  int autoMergeGrid() {
    final int unlockedLimit = maxUnlockedGridSlots;
    final newSlots = List<ShipModel?>.from(state.gridSlots);
    int totalMergesMade = 0;
    int newHighest = state.highestTierUnlocked;

    bool foundMerge = true;
    while (foundMerge) {
      foundMerge = false;
      for (int i = 0; i < unlockedLimit; i++) {
        final shipA = newSlots[i];
        if (shipA == null || shipA.isBox) continue;

        for (int j = i + 1; j < unlockedLimit; j++) {
          final shipB = newSlots[j];
          if (shipB == null || shipB.isBox) continue;

          if (shipA.tier == shipB.tier && shipA.tier < 30) {
            final int newTier = shipA.tier + 1;
            newSlots[i] = ShipModel.create(newTier);
            newSlots[j] = null;
            newHighest = max(newHighest, newTier);
            totalMergesMade++;
            foundMerge = true;
            break;
          }
        }
        if (foundMerge) break;
      }
    }

    if (totalMergesMade > 0) {
      final int prevHighest = state.highestTierUnlocked;

      // Automatically compact & sort remaining ships to eliminate empty holes
      final List<ShipModel> ships = [];
      final List<ShipModel> crates = [];
      for (int i = 0; i < unlockedLimit; i++) {
        final item = newSlots[i];
        if (item != null) {
          if (item.isBox) {
            crates.add(item);
          } else {
            ships.add(item);
          }
        }
      }
      ships.sort((a, b) => a.tier.compareTo(b.tier));
      final List<ShipModel?> compactedSlots = List<ShipModel?>.filled(16, null);
      int cursor = 0;
      for (final ship in ships) {
        if (cursor < unlockedLimit) compactedSlots[cursor++] = ship;
      }
      for (final crate in crates) {
        if (cursor < unlockedLimit) compactedSlots[cursor++] = crate;
      }
      for (int i = unlockedLimit; i < 16; i++) {
        compactedSlots[i] = newSlots[i];
      }

      state = state.copyWith(
        gridSlots: compactedSlots,
        trackShips: computeTrackFleet(compactedSlots),
        totalMergesCount: state.totalMergesCount + totalMergesMade,
        highestTierUnlocked: newHighest,
        comboCount: 0,
        lastComboMessage: '',
      );

      if (newHighest > prevHighest && newHighest > 1) {
        onShipDiscovered?.call(newHighest);
      }

      _soundService.playMergeSound();
      _autoSaveDebounced();
    }
    return totalMergesMade;
  }

  /// Neatly sorts all ships on the grid from lowest to highest tier, grouping identical tiers together, with crates at the end
  bool sortGridSlots() {
    final int unlockedLimit = maxUnlockedGridSlots;
    final List<ShipModel> ships = [];
    final List<ShipModel> crates = [];

    for (int i = 0; i < unlockedLimit; i++) {
      final item = state.gridSlots[i];
      if (item != null) {
        if (item.isBox) {
          crates.add(item);
        } else {
          ships.add(item);
        }
      }
    }

    if (ships.isEmpty && crates.isEmpty) return false;

    // Sort ships ascending by tier
    ships.sort((a, b) => a.tier.compareTo(b.tier));

    final List<ShipModel?> newSlots = List<ShipModel?>.filled(16, null);
    int cursor = 0;

    for (final ship in ships) {
      if (cursor < unlockedLimit) {
        newSlots[cursor++] = ship;
      }
    }

    for (final crate in crates) {
      if (cursor < unlockedLimit) {
        newSlots[cursor++] = crate;
      }
    }

    // Preserve any slots beyond unlocked limit if any
    for (int i = unlockedLimit; i < 16; i++) {
      newSlots[i] = state.gridSlots[i];
    }

    final double bonusCredits = !state.hasSeenSortTutorial ? 100.0 : 0.0;

    state = state.copyWith(
      credits: state.credits + bonusCredits,
      lifetimeCredits: state.lifetimeCredits + bonusCredits,
      hasSeenSortTutorial: true,
      gridSlots: newSlots,
      trackShips: computeTrackFleet(newSlots),
    );

    _soundService.playButtonHaptic();
    _autoSaveDebounced();
    return true;
  }

  /// Celebratory intro completion for Dark Matter discovery at Tier 3
  void acknowledgeDarkMatterIntro() {
    if (state.hasSeenDarkMatterIntro) return;
    state = state.copyWith(
      hasSeenDarkMatterIntro: true,
      darkMatter: state.darkMatter + 15.0, // Starter Dark Matter grant
    );
    _soundService.playPrestigeSound();
    _autoSaveDebounced();
  }

  /// Dismisses the contextual Sort micro-tutorial
  void skipSortTutorial() {
    state = state.copyWith(hasSeenSortTutorial: true);
    _autoSaveDebounced();
  }

  /// Derives active racing track fleet directly from grid slots (highest tiers first, max 4, ignoring unopened crates)

  static List<ShipModel> computeTrackFleet(List<ShipModel?> gridSlots, {int maxTrackCapacity = 4}) {
    final List<ShipModel> activeGridShips =
        gridSlots.whereType<ShipModel>().where((s) => !s.isBox).toList();
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
    final updatedMission = mission.copyWith(isClaimed: true);
    final updatedMissions = List<MissionModel>.from(state.career.missions);
    updatedMissions[index] = updatedMission;

    final double awardedCredits =
        mission.rewardCoins * relicIncomeMultiplier;

    state = state.copyWith(
      credits: state.credits + awardedCredits,
      lifetimeCredits: state.lifetimeCredits + awardedCredits,
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
    final double actualDarkMatterEarned = baseYield *
        state.prestigeDarkMatterMultiplier *
        (doubleYield ? 2.0 : 1.0);

    final int newPrestigeCount = state.career.prestigeCount + 1;
    final int newSectorLevel = state.career.sectorLevel + 1;

    // Reset grid with upgraded starter ship tier if unlocked
    final int starterTier = state.prestigeStarterShipTier;
    final List<ShipModel?> freshSlots = List.generate(16, (_) => null);
    freshSlots[0] = ShipModel.create(starterTier);

    state = state.copyWith(
      credits: 250.0,
      lifetimeCredits: 250.0,
      darkMatter: state.darkMatter + actualDarkMatterEarned,
      totalShipsPurchased: 0,
      highestTierUnlocked: starterTier,
      gridSlots: freshSlots,
      trackShips: [ShipModel.create(starterTier)],
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
      lastSaveTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _soundService.playPurchaseSound();
    _autoSaveDebounced();
  }

  /// Spawns an Alien Dreadnought Boss Incursion in the center of the track

  void spawnAlienBoss() {
    if (state.activeBoss != null && !state.activeBoss!.isDead) return;

    final double highestIncome = state.trackShips.isNotEmpty
        ? state.trackShips.first.calculateIncomePayout()
        : 50.0;

    final newBoss = BossModel.createForSector(
      sectorLevel: state.career.sectorLevel,
      highestTierUnlocked: state.highestTierUnlocked,
      totalBossesDefeated: state.career.totalBossesDefeated,
      baseIncomePerLap: highestIncome,
    );



    state = state.copyWith(activeBoss: newBoss);
    _soundService.playPrestigeSound();
    _autoSaveDebounced();
  }

  /// Active permanent relic multipliers
  double get relicSpeedMultiplier {
    final relic = state.relics.firstWhere(
      (r) => r.effectType == RelicEffectType.speedBoost,
      orElse: () => const RelicModel(
        id: '',
        name: '',
        description: '',
        iconCodePoint: 0,
        rarity: RelicRarity.rare,
        effectType: RelicEffectType.speedBoost,
        baseBonus: 0,
        bonusPerLevel: 0,
      ),
    );
    return 1.0 + relic.currentBonusValue;
  }

  double get relicIncomeMultiplier {
    final relic = state.relics.firstWhere(
      (r) => r.effectType == RelicEffectType.incomeBoost,
      orElse: () => const RelicModel(
        id: '',
        name: '',
        description: '',
        iconCodePoint: 0,
        rarity: RelicRarity.cosmic,
        effectType: RelicEffectType.incomeBoost,
        baseBonus: 0,
        bonusPerLevel: 0,
      ),
    );
    return 1.0 + relic.currentBonusValue;
  }

  double get relicDarkMatterMultiplier {
    final relic = state.relics.firstWhere(
      (r) => r.effectType == RelicEffectType.darkMatterBoost,
      orElse: () => const RelicModel(
        id: '',
        name: '',
        description: '',
        iconCodePoint: 0,
        rarity: RelicRarity.epic,
        effectType: RelicEffectType.darkMatterBoost,
        baseBonus: 0,
        bonusPerLevel: 0,
      ),
    );
    return 1.0 + relic.currentBonusValue;
  }

  double get relicBossTapDamageBonus {
    final relic = state.relics.firstWhere(
      (r) => r.effectType == RelicEffectType.bossTapDamage,
      orElse: () => const RelicModel(
        id: '',
        name: '',
        description: '',
        iconCodePoint: 0,
        rarity: RelicRarity.epic,
        effectType: RelicEffectType.bossTapDamage,
        baseBonus: 0,
        bonusPerLevel: 0,
      ),
    );
    return 1.0 + relic.currentBonusValue;
  }

  /// Upgrades an Ancient Alien Relic using duplicate shards
  bool upgradeRelic(String relicId) {
    final index = state.relics.indexWhere((r) => r.id == relicId);
    if (index == -1) return false;
    final relic = state.relics[index];
    if (!relic.canUpgrade) return false;

    final cost = relic.shardsNeededForNext;
    final updated = relic.copyWith(
      level: relic.level + 1,
      shards: relic.shards - cost,
    );
    final newRelics = List<RelicModel>.from(state.relics);
    newRelics[index] = updated;

    state = state.copyWith(relics: newRelics);
    _soundService.playPrestigeSound();
    _autoSaveDebounced();
    return true;
  }

  /// Awards shards of a specific artifact
  void awardRelicShards(String relicId, int count) {
    final index = state.relics.indexWhere((r) => r.id == relicId);
    if (index == -1) return;
    final relic = state.relics[index];
    final updated = relic.copyWith(shards: relic.shards + count);
    final newRelics = List<RelicModel>.from(state.relics);
    newRelics[index] = updated;

    state = state.copyWith(relics: newRelics);
    _autoSaveDebounced();
  }

  /// Deals damage to the active Alien Boss (from fleet auto-lasers or player tap-strikes)
  void damageBoss(double damage, {bool isTap = false}) {
    final boss = state.activeBoss;
    if (boss == null || boss.isDead) return;

    final double effectiveDmg =
        isTap ? (damage * relicBossTapDamageBonus) : damage;
    final updatedBoss = boss.applyDamage(effectiveDmg);

    if (updatedBoss.isDead) {
      recordBossDefeated();
    } else {
      state = state.copyWith(activeBoss: updatedBoss);
    }
  }


  /// Ticks down the Boss incursion timer (e.g. called from loop)
  void tickBoss(double dt) {
    final boss = state.activeBoss;
    if (boss == null) return;

    final double newTime = boss.timeRemaining - dt;
    if (newTime <= 0.0) {
      // Boss escaped
      state = state.copyWith(clearActiveBoss: true);
    } else {
      // Kinetic Energy Shield slowly regenerates over time
      final double regenAmount =
          (boss.archetype == BossArchetype.shieldedTitan ? 4.0 : 2.0) * dt;
      final updatedBoss = boss
          .regenerateShield(regenAmount)
          .copyWith(timeRemaining: newTime);
      state = state.copyWith(activeBoss: updatedBoss);
    }
  }

  /// Handles Boss Defeat: Supernova payout (Dark Matter, massive credits, relic shard, and high-tier crate)
  void recordBossDefeated() {
    final boss = state.activeBoss;
    if (boss == null) return;

    final double rewardCoins = boss.bountyCredits;
    final double rewardDm = boss.bountyDarkMatter * relicDarkMatterMultiplier;
    final int updatedBossCount = state.career.totalBossesDefeated + 1;
    final updatedCareer =
        state.career.copyWith(totalBossesDefeated: updatedBossCount);

    state = state.copyWith(
      credits: state.credits + rewardCoins,
      lifetimeCredits: state.lifetimeCredits + rewardCoins,
      darkMatter: state.darkMatter + rewardDm,
      career: updatedCareer,
      clearActiveBoss: true,
    );

    // 60% chance to drop an Ancient Alien Relic Shard
    if (Random().nextDouble() < 0.60 && state.relics.isNotEmpty) {
      final randomRelic = state.relics[Random().nextInt(state.relics.length)];
      awardRelicShards(randomRelic.id, 1);
    }

    // Drop free high-tier mystery crate on flight deck
    dropMysteryCargo();

    // Award 1 extra lucky spin for defeating an alien dreadnought!
    addExtraSpin(count: 1);

    _evaluateAchievements();
    _soundService.playPrestigeSound();
    _autoSaveDebounced();
  }

  /// Adds extra available lucky spins (from ads, boss defeats, etc.)
  void addExtraSpin({int count = 1}) {
    state = state.copyWith(extraSpinsCount: state.extraSpinsCount + count);
    _autoSaveDebounced();
  }

  /// Claims reward from landing on a specific Wormhole Roulette wedge (1 Free + 2 Ad Spins per 24h)
  void claimRouletteReward(RouletteRewardModel reward) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final int currentUsed = state.effectiveDailySpinsUsed;
    final int newUsed = (currentUsed + 1).clamp(0, 3);
    final int newResetTimestamp = (state.lastDailySpinResetTimestamp == 0 ||
            (now - state.lastDailySpinResetTimestamp) >= (24 * 60 * 60 * 1000))
        ? now
        : state.lastDailySpinResetTimestamp;

    final double highestIncome = state.trackShips.isNotEmpty
        ? state.trackShips.first.calculateIncomePayout()
        : 50.0;

    switch (reward.type) {
      case RouletteRewardType.supernovaJackpot:
        final double jackpot =
            highestIncome * reward.valueMultiplier * relicIncomeMultiplier;
        state = state.copyWith(
          credits: state.credits + jackpot,
          lifetimeCredits: state.lifetimeCredits + jackpot,
          dailySpinsUsed: newUsed,
          lastDailySpinResetTimestamp: newResetTimestamp,
          lastFreeSpinTimestamp: newResetTimestamp,
        );
        break;

      case RouletteRewardType.creditsMultiplier:
        final double windfall =
            highestIncome * reward.valueMultiplier * relicIncomeMultiplier;
        state = state.copyWith(
          credits: state.credits + windfall,
          lifetimeCredits: state.lifetimeCredits + windfall,
          dailySpinsUsed: newUsed,
          lastDailySpinResetTimestamp: newResetTimestamp,
          lastFreeSpinTimestamp: newResetTimestamp,
        );
        break;

      case RouletteRewardType.darkMatter:
        final double dm = reward.count * relicDarkMatterMultiplier;
        state = state.copyWith(
          darkMatter: state.darkMatter + dm,
          dailySpinsUsed: newUsed,
          lastDailySpinResetTimestamp: newResetTimestamp,
          lastFreeSpinTimestamp: newResetTimestamp,
        );
        break;

      case RouletteRewardType.timeWarp:
        // Calculate 2 hours of active fleet income
        const double approxTrackLength = 1400.0;
        final double totalFleetPerSec = state.trackShips.fold<double>(
          0.0,
          (sum, s) =>
              sum +
              (s.calculateIncomePayout() * (s.baseSpeed / approxTrackLength)),
        );
        final double effectivePerSec = max(0.24, totalFleetPerSec);
        final double warpEarnings =
            effectivePerSec * reward.count * relicIncomeMultiplier;
        state = state.copyWith(
          credits: state.credits + warpEarnings,
          lifetimeCredits: state.lifetimeCredits + warpEarnings,
          dailySpinsUsed: newUsed,
          lastDailySpinResetTimestamp: newResetTimestamp,
          lastFreeSpinTimestamp: newResetTimestamp,
        );
        break;

      case RouletteRewardType.feverRush:
        state = state.copyWith(
          isFeverActive: true,
          feverTimeRemaining: 30.0,
          dailySpinsUsed: newUsed,
          lastDailySpinResetTimestamp: newResetTimestamp,
          lastFreeSpinTimestamp: newResetTimestamp,
        );
        break;

      case RouletteRewardType.relicShards:
        state = state.copyWith(
          dailySpinsUsed: newUsed,
          lastDailySpinResetTimestamp: newResetTimestamp,
          lastFreeSpinTimestamp: newResetTimestamp,
        );
        if (state.relics.isNotEmpty) {
          final randomRelic =
              state.relics[Random().nextInt(state.relics.length)];
          awardRelicShards(randomRelic.id, reward.count);
        }
        break;

      case RouletteRewardType.shipDrop:
        state = state.copyWith(
          dailySpinsUsed: newUsed,
          lastDailySpinResetTimestamp: newResetTimestamp,
          lastFreeSpinTimestamp: newResetTimestamp,
        );
        final emptyIndex = state.gridSlots.indexWhere((s) => s == null);
        if (emptyIndex != -1) {
          final int awardedTier = max(1, state.highestTierUnlocked);
          final newSlots = List<ShipModel?>.from(state.gridSlots);
          newSlots[emptyIndex] = ShipModel.create(awardedTier, null, false);
          state = state.copyWith(
            gridSlots: newSlots,
            trackShips: computeTrackFleet(newSlots),
          );
        } else {
          // If grid is full, award 50x lap income compensation!
          final double fallbackBonus = highestIncome * 50.0 * relicIncomeMultiplier;
          state = state.copyWith(
            credits: state.credits + fallbackBonus,
            lifetimeCredits: state.lifetimeCredits + fallbackBonus,
          );
        }
        break;

      case RouletteRewardType.mysteryCrate:
        state = state.copyWith(
          dailySpinsUsed: newUsed,
          lastDailySpinResetTimestamp: newResetTimestamp,
          lastFreeSpinTimestamp: newResetTimestamp,
        );
        final bool dropped = dropMysteryCargo();
        if (!dropped) {
          final double fallbackBonus = highestIncome * 25.0 * relicIncomeMultiplier;
          state = state.copyWith(
            credits: state.credits + fallbackBonus,
            lifetimeCredits: state.lifetimeCredits + fallbackBonus,
          );
        }
        break;
    }

    _soundService.playPrestigeSound();
    _autoSaveDebounced();
  }

  /// Dispatches a spacecraft on an interstellar constellation expedition
  bool launchExpedition(String sectorId, int assignedShipTier) {
    final sector = ExpeditionSector.catalog.firstWhere(
      (s) => s.id == sectorId,
      orElse: () => ExpeditionSector.catalog.first,
    );

    // Validate tier requirement
    if (assignedShipTier < sector.minShipTier) return false;

    // Check if sector already has an active expedition
    final bool alreadyActive = state.expeditions.any(
      (e) => e.sectorId == sectorId && !e.isClaimed,
    );
    if (alreadyActive) return false;

    // Base income per lap reference from active fleet
    final double baseFleetIncome = state.trackShips.isNotEmpty
        ? state.trackShips.first.calculateIncomePayout()
        : 4.0;

    // Assigned ship tier bonus: higher tier ships multiply the bounty!
    final double tierMultiplier =
        pow(1.3, max(0, assignedShipTier - sector.minShipTier)).toDouble();

    final double creditsReward = baseFleetIncome *
        sector.baseCreditsMultiplier *
        tierMultiplier *
        relicIncomeMultiplier;
    final double dmReward =
        sector.darkMatterReward * (1.0 + (assignedShipTier * 0.1));
    final int shardReward = sector.relicShardsReward > 0
        ? (sector.relicShardsReward * (1.0 + (assignedShipTier * 0.05))).round()
        : 0;

    final newMission = ExpeditionMission(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      sectorId: sector.id,
      sectorName: sector.name,
      durationSeconds: sector.durationSeconds,
      startTimeEpoch: DateTime.now().millisecondsSinceEpoch,
      assignedShipTier: assignedShipTier,
      calculatedCredits: creditsReward,
      calculatedDarkMatter: dmReward,
      calculatedRelicShards: shardReward,
      bonusBlueprintTier: sector.bonusBlueprintTier,
    );

    final updatedList = List<ExpeditionMission>.from(state.expeditions)
      ..add(newMission);
    state = state.copyWith(expeditions: updatedList);

    _soundService.playPurchaseSound();
    _autoSaveDebounced();
    return true;
  }

  /// Claims reward from a completed expedition
  bool claimExpeditionReward(String missionId) {
    final int index = state.expeditions.indexWhere((e) => e.id == missionId);
    if (index == -1) return false;

    final mission = state.expeditions[index];
    if (!mission.isReadyToClaim) return false;

    // Award currencies
    final double newCredits = state.credits + mission.calculatedCredits;
    final double newLifetime =
        state.lifetimeCredits + mission.calculatedCredits;
    final double newDm = state.darkMatter + mission.calculatedDarkMatter;

    // Award relic shards
    if (mission.calculatedRelicShards > 0 && state.relics.isNotEmpty) {
      final randomRelic = state.relics[Random().nextInt(state.relics.length)];
      awardRelicShards(randomRelic.id, mission.calculatedRelicShards);
    }

    // Award bonus ship blueprint crate if applicable
    if (mission.bonusBlueprintTier > 0) {
      dropMysteryCargo(tier: mission.bonusBlueprintTier);
    }

    // Remove claimed mission from active list
    final updatedList = List<ExpeditionMission>.from(state.expeditions)
      ..removeAt(index);
    state = state.copyWith(
      credits: newCredits,
      lifetimeCredits: newLifetime,
      darkMatter: newDm,
      expeditions: updatedList,
    );

    _soundService.playPrestigeSound();
    _autoSaveDebounced();
    return true;
  }

  /// Speeds up remaining expedition time by 30 minutes via Rewarded Ad
  bool speedUpExpeditionWithAd(String missionId, {int secondsReduced = 1800}) {
    final int index = state.expeditions.indexWhere((e) => e.id == missionId);
    if (index == -1) return false;

    final mission = state.expeditions[index];
    final int newStart = mission.startTimeEpoch - (secondsReduced * 1000);
    final updatedMission = mission.copyWith(startTimeEpoch: newStart);

    final updatedList = List<ExpeditionMission>.from(state.expeditions);
    updatedList[index] = updatedMission;

    state = state.copyWith(expeditions: updatedList);
    _autoSaveDebounced();
    return true;
  }

  /// Claims today's reward from the 7-Day Commander Login Calendar
  bool claimDailyLoginReward({bool doubleWithAd = false, double multiplier = 1.0}) {
    if (!state.canClaimDailyReward) return false;

    final int dayIndex = (state.currentLoginDay - 1).clamp(0, 6);
    final reward = DailyRewardDay.schedule[dayIndex];
    final double effectiveMultiplier =
        doubleWithAd ? 2.0 : (multiplier > 1.0 ? multiplier : 1.0);
    // Scale daily credits dynamically with current fleet progression
    final double tierMultiplier =
        1.0 + (max(0, state.highestTierUnlocked - 1) * 0.35);

    final double addedCredits =
        reward.creditsReward * effectiveMultiplier * relicIncomeMultiplier * tierMultiplier;
    final double addedDarkMatter =
        reward.darkMatterReward * effectiveMultiplier;
    final int addedShards =
        (reward.relicShardsReward * effectiveMultiplier).round();
    final int addedSpins =
        (reward.extraSpins * effectiveMultiplier).round();

    // Advance login streak (loops 1 to 7)
    final int nextDay = (state.currentLoginDay % 7) + 1;

    state = state.copyWith(
      credits: state.credits + addedCredits,
      lifetimeCredits: state.lifetimeCredits + addedCredits,
      darkMatter: state.darkMatter + addedDarkMatter,
      extraSpinsCount: state.extraSpinsCount + addedSpins,
      currentLoginDay: nextDay,
      lastLoginClaimEpoch: DateTime.now().millisecondsSinceEpoch,
    );

    // Award Relic Shards if any
    if (addedShards > 0 && state.relics.isNotEmpty) {
      final randomRelic = state.relics[Random().nextInt(state.relics.length)];
      awardRelicShards(randomRelic.id, addedShards);
    }

    // Drop bonus delivery crate if applicable
    if (reward.bonusTierCrate > 0) {
      dropMysteryCargo(tier: reward.bonusTierCrate);
    }

    _soundService.playPrestigeSound();
    _autoSaveDebounced();
    return true;
  }

  /// Purchases an item from the In-Game Cosmic Store
  bool purchaseStoreItem(StoreItem item) {
    // Validate costs
    if (item.costCredits > 0 && state.credits < item.costCredits) return false;
    if (item.costDarkMatter > 0 && state.darkMatter < item.costDarkMatter) {
      return false;
    }

    // Deduct currency
    double newCredits = state.credits - item.costCredits;
    double newDm = state.darkMatter - item.costDarkMatter;

    switch (item.category) {
      case StoreCategory.timeWarp:
        // Calculate fleet revenue per hour
        const double approxTrackLength = 1400.0;
        final double totalFleetPerSec = state.trackShips.fold<double>(
          0.0,
          (sum, s) =>
              sum +
              (s.calculateIncomePayout() * (s.baseSpeed / approxTrackLength)),
        );
        final double effectivePerSec = max(0.24, totalFleetPerSec);
        final double warpEarnings = effectivePerSec *
            (item.warpDurationHours * 3600) *
            relicIncomeMultiplier *
            state.permanentIncomeMultiplier;

        newCredits += warpEarnings;
        state = state.copyWith(
          credits: newCredits,
          lifetimeCredits: state.lifetimeCredits + warpEarnings,
          darkMatter: newDm,
        );
        break;

      case StoreCategory.darkMatter:
        newDm += item.grantedDarkMatter;
        state = state.copyWith(
          credits: newCredits,
          darkMatter: newDm,
        );
        break;

      case StoreCategory.vipDrone:
        if (item.id == 'drone_permanent') {
          state = state.copyWith(
            credits: newCredits,
            darkMatter: newDm,
            isDronePermanent: true,
          );
        } else {
          // Rental 30 min
          final now = DateTime.now().millisecondsSinceEpoch;
          final int currentBase = max(now, state.droneRentalExpiryEpoch);
          final int newExpiry =
              currentBase + (item.droneRentalDurationMinutes * 60 * 1000);
          state = state.copyWith(
            credits: newCredits,
            darkMatter: newDm,
            droneRentalExpiryEpoch: newExpiry,
          );
        }
        break;

      case StoreCategory.permanentBooster:
        final updatedBoosters =
            List<String>.from(state.unlockedPermanentBoosters);
        if (!updatedBoosters.contains(item.id)) {
          updatedBoosters.add(item.id);
        }
        state = state.copyWith(
          credits: newCredits,
          darkMatter: newDm,
          unlockedPermanentBoosters: updatedBoosters,
        );
        break;

      case StoreCategory.iapVault:
        // In-App purchases are handled via InAppPurchaseService
        break;
    }

    _soundService.playPurchaseSound();
    _autoSaveDebounced();
    return true;
  }

  /// Grants free temporary VIP Auto-Collector Drone rental (from Rewarded Video or bonus drops)
  void grantTempDroneRental({int durationMinutes = 30}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final int currentBase = max(now, state.droneRentalExpiryEpoch);
    final int newExpiry = currentBase + (durationMinutes * 60 * 1000);
    state = state.copyWith(droneRentalExpiryEpoch: newExpiry);
    _soundService.playPurchaseSound();
    _autoSaveDebounced();
  }

  /// Purchases permanent VIP Commander Pass (+500 Dark Matter, +5 Spins & Lifetime Drone)
  void purchaseRemoveAds() {
    state = state.copyWith(
      hasRemovedAds: true,
      isDronePermanent: true,
      darkMatter: state.darkMatter + 500.0,
      extraSpinsCount: state.extraSpinsCount + 5,
    );
    StorageService.recordPurchaseReceipt('remove_ads_vip');
    _soundService.playPrestigeSound();
    _autoSaveDebounced();
  }

  /// Restores In-App Purchases from validated receipt ledger
  bool restorePurchases() {
    final receipts = StorageService.getPurchasedReceipts();
    if (receipts.isEmpty && !state.hasRemovedAds && !state.isDronePermanent) {
      // No purchases on record
      return false;
    }

    final bool hasVipReceipt =
        receipts.contains('remove_ads_vip') || state.hasRemovedAds;
    final bool hasDroneReceipt =
        receipts.contains('perm_vip_drone') || state.isDronePermanent;

    state = state.copyWith(
      hasRemovedAds: hasVipReceipt,
      isDronePermanent: hasDroneReceipt,
    );
    _soundService.playPurchaseSound();
    _autoSaveDebounced();
    return hasVipReceipt || hasDroneReceipt;
  }


  /// Drone Auto-Collector: Automatically opens unopened crates if VIP drone is active

  bool checkAndRunDroneCollector() {
    if (!state.isDroneCurrentlyActive) return false;

    final int crateIndex =
        state.gridSlots.indexWhere((s) => s != null && s.isBox);
    if (crateIndex != -1) {
      return openCrate(crateIndex);
    }
    return false;
  }

  /// Claims reward from an unlocked milestone achievement
  bool claimAchievement(String achievementId) {
    final int index =
        state.achievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return false;

    final achievement = state.achievements[index];
    if (!achievement.canClaim) return false;

    // Award Dark Matter, Credits, Relic Shards
    final double newDm = state.darkMatter + achievement.rewardDarkMatter;
    final double newCredits = state.credits + achievement.rewardCredits;
    final double newLifetime =
        state.lifetimeCredits + achievement.rewardCredits;

    if (achievement.rewardRelicShards > 0 && state.relics.isNotEmpty) {
      final randomRelic = state.relics[Random().nextInt(state.relics.length)];
      awardRelicShards(randomRelic.id, achievement.rewardRelicShards);
    }

    final updatedAchievements = List<AchievementModel>.from(state.achievements);
    updatedAchievements[index] = achievement.copyWith(isClaimed: true);

    state = state.copyWith(
      darkMatter: newDm,
      credits: newCredits,
      lifetimeCredits: newLifetime,
      achievements: updatedAchievements,
    );

    _soundService.playPrestigeSound();
    _autoSaveDebounced();
    return true;
  }

  /// Applies reward chosen from Golden UFO 3-Card Mystery Pick
  void applyMysteryCardReward(MysteryCardReward reward,
      {bool doubleWithAd = false}) {
    final double multiplier = doubleWithAd ? 2.0 : 1.0;

    switch (reward.type) {
      case MysteryRewardType.coinSurge:
        final double earned =
            reward.creditsValue * multiplier * relicIncomeMultiplier;
        state = state.copyWith(
          credits: state.credits + earned,
          lifetimeCredits: state.lifetimeCredits + earned,
        );
        break;

      case MysteryRewardType.crateAirdrop:
        final int totalCrates = (reward.crateCount * multiplier).round();
        for (int i = 0; i < totalCrates; i++) {
          dropMysteryCargo(tier: reward.crateTier);
        }
        break;

      case MysteryRewardType.darkMatterGems:
        final double dm = reward.darkMatterValue * multiplier;
        state = state.copyWith(
          darkMatter: state.darkMatter + dm,
        );
        break;

      case MysteryRewardType.droneOverdrive:
        final now = DateTime.now().millisecondsSinceEpoch;
        final int currentBase = max(now, state.droneRentalExpiryEpoch);
        final int bonusMillis = (reward.droneSeconds * 1000 * multiplier).round();
        state = state.copyWith(
          droneRentalExpiryEpoch: currentBase + bonusMillis,
        );
        break;
    }

    _evaluateAchievements();
    _soundService.playPrestigeSound();
    _autoSaveDebounced();
  }

  /// Automatically updates progress across all 20 Milestone Achievements
  void _evaluateAchievements() {
    final int merges = state.totalMergesCount;
    final int highestTier = state.highestTierUnlocked;
    final double lifetimeCoins = state.lifetimeCredits;
    final int bossKills = state.career.totalBossesDefeated;
    final int spins = state.career.totalWheelSpins;
    final int expeditionsCount = state.career.totalExpeditionsCompleted;
    final int prestige = state.career.prestigeCount;
    final int unlockedRelics =
        state.relics.where((r) => r.level > 0).length;

    final updatedAchievements = state.achievements.map((ach) {
      if (ach.isClaimed) return ach;

      double currentVal = ach.currentProgress;
      switch (ach.category) {
        case AchievementCategory.merges:
          currentVal = merges.toDouble();
          break;
        case AchievementCategory.shipTier:
          currentVal = highestTier.toDouble();
          break;
        case AchievementCategory.bossDefeat:
          currentVal = bossKills.toDouble();
          break;
        case AchievementCategory.coinsEarned:
          currentVal = lifetimeCoins;
          break;
        case AchievementCategory.wheelSpins:
          currentVal = spins.toDouble();
          break;
        case AchievementCategory.expeditions:
          currentVal = expeditionsCount.toDouble();
          break;
        case AchievementCategory.prestige:
          currentVal = prestige.toDouble();
          break;
        case AchievementCategory.relics:
          currentVal = unlockedRelics.toDouble();
          break;
      }

      return ach.copyWith(currentProgress: currentVal);
    }).toList();

    state = state.copyWith(achievements: updatedAchievements);
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

