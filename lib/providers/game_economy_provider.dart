import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/ship_model.dart';
import '../models/boss_model.dart';
import '../models/relic_model.dart';
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
    final double feverMultiplier = state.isFeverActive ? 3.0 : 1.0;
    final double totalPayout = ship.calculateIncomePayout(
      multiplier: permanentMultiplier *
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

  /// Tapping the racetrack charges the Hyperspace Warp Meter (+4% per tap)
  void tapRacetrackBoost() {
    if (state.isFeverActive) return; // Already maxed in fever mode

    final double newCharge = min(1.0, state.feverCharge + 0.04);
    if (newCharge >= 1.0) {
      // Trigger Hyperspace Fever Rush!
      state = state.copyWith(
        feverCharge: 1.0,
        isFeverActive: true,
        feverTimeRemaining: 10.0,
      );
      _soundService.playFeverSound();
    } else {
      state = state.copyWith(feverCharge: newCharge);
      _soundService.playCrossingHaptic();
    }
  }

  /// Ticks down active fever timer or slowly decays idle charge
  void tickFever(double dt) {
    if (state.isFeverActive) {
      final double remaining = state.feverTimeRemaining - dt;
      if (remaining <= 0) {
        state = state.copyWith(
          isFeverActive: false,
          feverTimeRemaining: 0.0,
          feverCharge: 0.0,
        );
      } else {
        state = state.copyWith(
          feverTimeRemaining: remaining,
          feverCharge: remaining / 10.0,
        );
      }
    } else if (state.feverCharge > 0) {
      // Slow passive decay (2.5% per second) if not tapping
      final double decayed = max(0.0, state.feverCharge - (dt * 0.025));
      state = state.copyWith(feverCharge: decayed);
    }
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

  /// Spawns a mystery cosmic supply crate directly onto an empty grid slot (waiting to be tapped!)
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
    newSlots[targetSlot] = ShipModel.create(awardedTier, null, true); // isBox: true!

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

      final int now = DateTime.now().millisecondsSinceEpoch;
      final bool isCombo = (now - state.lastMergeTimestamp) < 2500;
      final int newComboCount = isCombo ? (state.comboCount + 1) : 1;

      // Combo Credit Payout Bonus
      double bonusCredits = 0.0;
      String comboMessage = '';
      if (newComboCount >= 2) {
        final double comboMultiplier = 1.0 + (newComboCount * 0.5);
        bonusCredits = mergedShip.calculateIncomePayout() * comboMultiplier * 3;
        comboMessage = '$newComboCount' 'X MERGE COMBO!';
      }

      // 15% Chance on Combo >= 2 for Lucky Ship Duplication
      bool luckyDuplicated = false;
      if (newComboCount >= 2 && Random().nextDouble() < 0.18) {
        // Find empty slot to spawn a free clone!
        for (int i = 0; i < unlockedLimit; i++) {
          if (newSlots[i] == null) {
            newSlots[i] = ShipModel.create(newTier);
            luckyDuplicated = true;
            comboMessage = '$comboMessage ⚡ LUCKY CLONE!';
            break;
          }
        }
      }

      final updatedMissions = _evaluateMissions(
        state.career.missions,
        mergesIncrement: 1,
        unlockedTier: newTier,
        coinsIncrement: bonusCredits,
      );

      state = state.copyWith(
        credits: state.credits + bonusCredits,
        lifetimeCredits: state.lifetimeCredits + bonusCredits,
        gridSlots: newSlots,
        trackShips: computeTrackFleet(newSlots),
        totalMergesCount: newMergeCount,
        highestTierUnlocked: newHighest,
        comboCount: newComboCount,
        lastMergeTimestamp: now,
        lastComboMessage: comboMessage,
        career: state.career.copyWith(missions: updatedMissions),
      );

      if (luckyDuplicated) {
        _soundService.playPrestigeSound();
      } else if (newComboCount >= 2) {
        _soundService.playComboSound(newComboCount);
      } else {
        _soundService.playMergeSound();
      }
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
  double recycleShip(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= state.gridSlots.length) return 0.0;
    final ship = state.gridSlots[slotIndex];
    if (ship == null || ship.isBox) return 0.0;

    final double refund =
        ShipModel.calculatePurchaseCost(state.totalShipsPurchased, ship.tier) *
            0.7;

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

  /// Automatically merges all available pairs on the flight deck with one tap
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
      state = state.copyWith(
        gridSlots: newSlots,
        trackShips: computeTrackFleet(newSlots),
        totalMergesCount: state.totalMergesCount + totalMergesMade,
        highestTierUnlocked: newHighest,
        comboCount: totalMergesMade,
        lastComboMessage: '⚡ $totalMergesMade MERGES AUTO-COMPLETED!',
      );
      _soundService.playMergeSound();
      _autoSaveDebounced();
    }
    return totalMergesMade;
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

  /// Spawns an Alien Dreadnought Boss Incursion in the center of the track

  void spawnAlienBoss() {
    if (state.activeBoss != null && !state.activeBoss!.isDead) return;

    final double highestIncome = state.trackShips.isNotEmpty
        ? state.trackShips.first.calculateIncomePayout()
        : 50.0;

    final newBoss = BossModel.createForSector(
      state.career.sectorLevel,
      highestIncome,
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
    final double newHp = max(0.0, boss.currentHealth - effectiveDmg);
    final updatedBoss = boss.copyWith(currentHealth: newHp);

    if (newHp <= 0.0) {
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
      state = state.copyWith(activeBoss: boss.copyWith(timeRemaining: newTime));
    }
  }

  /// Handles Boss Defeat: Supernova payout (Dark Matter, massive credits, relic shard, and high-tier crate)
  void recordBossDefeated() {
    final boss = state.activeBoss;
    if (boss == null) return;

    final double rewardCoins = boss.bountyCredits;
    final double rewardDm = boss.bountyDarkMatter * relicDarkMatterMultiplier;

    state = state.copyWith(
      credits: state.credits + rewardCoins,
      lifetimeCredits: state.lifetimeCredits + rewardCoins,
      darkMatter: state.darkMatter + rewardDm,
      clearActiveBoss: true,
    );

    // 60% chance to drop an Ancient Alien Relic Shard
    if (Random().nextDouble() < 0.60 && state.relics.isNotEmpty) {
      final randomRelic = state.relics[Random().nextInt(state.relics.length)];
      awardRelicShards(randomRelic.id, 1);
    }

    // Drop free high-tier mystery crate on flight deck
    dropMysteryCargo();

    _soundService.playPrestigeSound();
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
