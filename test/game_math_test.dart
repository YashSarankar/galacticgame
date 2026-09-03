import 'package:flutter_test/flutter_test.dart';
import 'package:galacticgame/models/game_state.dart';
import 'package:galacticgame/models/ship_model.dart';
import 'package:galacticgame/models/roulette_reward_model.dart';
import 'package:galacticgame/models/store_item_model.dart';
import 'package:galacticgame/models/mystery_card_model.dart';
import 'package:galacticgame/models/sector_theme_model.dart';
import 'package:galacticgame/models/cosmic_weather_model.dart';
import 'package:galacticgame/models/boss_model.dart';
import 'package:galacticgame/models/mission_model.dart';
import 'package:galacticgame/services/user_growth_service.dart';
import 'package:galacticgame/services/sound_service.dart';
import 'package:galacticgame/providers/game_economy_provider.dart';










import 'package:galacticgame/services/storage_service.dart';
import 'package:galacticgame/services/localized_pricing_service.dart';
import 'package:galacticgame/services/razorpay_payment_service.dart';
import 'package:galacticgame/utils/number_formatter.dart';




import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('NumberFormatter Tests', () {
    test('Formats standard small numbers and decimals', () {
      expect(NumberFormatter.formatCurrency(0), '0');
      expect(NumberFormatter.formatCurrency(500), '500');
      expect(NumberFormatter.formatCurrency(999.5), '999.50');
    });

    test('Formats huge idle numbers with correct suffixes', () {
      expect(NumberFormatter.formatCurrency(1000), '1.00K');
      expect(NumberFormatter.formatCurrency(1500000), '1.50M');
      expect(NumberFormatter.formatCurrency(2500000000), '2.50B');
      expect(NumberFormatter.formatCurrency(4800000000000), '4.80T');
      expect(NumberFormatter.formatCredits(1250000), '\$1.25M');
      expect(NumberFormatter.formatDarkMatter(50), '50 DM');
      expect(NumberFormatter.formatDarkMatter(1500), '1.5K DM');
      expect(NumberFormatter.formatDarkMatter(1500000), '1.5M DM');
    });



    test('Formats duration correctly', () {
      expect(NumberFormatter.formatSeconds(45), '00m 45s');
      expect(NumberFormatter.formatSeconds(125), '02m 05s');
      expect(NumberFormatter.formatSeconds(3665), '01h 01m 05s');
    });
  });

  group('Economy & Ship Mathematical Formulas', () {
    test('Exponential purchase cost scales correctly', () {
      final cost0 = ShipModel.calculatePurchaseCost(0, 1);
      final cost1 = ShipModel.calculatePurchaseCost(1, 1);
      final cost5 = ShipModel.calculatePurchaseCost(5, 1);

      expect(cost0, 100.0);
      expect(cost1, closeTo(125.0, 0.01));
      expect(cost5 > cost1, true);

      // Test discount
      final costWithDiscount = ShipModel.calculatePurchaseCost(0, 1, discount: 0.2);
      expect(costWithDiscount, closeTo(80.0, 0.01));

      // Test extreme long-term purchases (never overflows to Infinity or NaN)
      final cost1000 = ShipModel.calculatePurchaseCost(1000, 50);
      expect(cost1000.isFinite, true);
      expect(cost1000.isNaN, false);
      expect(cost1000 > 0, true);
    });

    test('Income payout formula scales with calibrated 1.85 factor', () {
      final ship1 = ShipModel.create(1);
      final ship2 = ShipModel.create(2);
      final ship3 = ShipModel.create(3);

      expect(ship1.calculateIncomePayout(), 4.0);
      expect(ship2.calculateIncomePayout(), 4.0 * 1.85);
      expect(ship3.calculateIncomePayout(), closeTo(4.0 * 1.85 * 1.85, 0.01));
    });


    test('Ship laser strike damage scales exponentially with ship tier', () {
      final ship1 = ShipModel.create(1);
      final ship2 = ShipModel.create(2);
      final ship3 = ShipModel.create(3);
      final ship5 = ShipModel.create(5);

      // T1 = 15 base
      expect(ship1.calculateLaserDamage(), 15.0);
      // T2 = 15 * 1.6 = 24
      expect(ship2.calculateLaserDamage(), 24.0);
      // T3 = 15 * 1.6^2 = 38.4
      expect(ship3.calculateLaserDamage(), closeTo(38.4, 0.01));
      // T5 = 15 * 1.6^4 = 98.304
      expect(ship5.calculateLaserDamage(), closeTo(98.30, 0.01));

      // With 2.5x Fever boost
      expect(ship1.calculateLaserDamage(multiplier: 2.5), 37.5);
    });


    test('Prestige Dark Matter yield formula', () {
      final stateLow = GameState.initial().copyWith(lifetimeCredits: 100000);
      expect(stateLow.potentialPrestigeDarkMatter, 0.0);

      final state10M = GameState.initial().copyWith(lifetimeCredits: 10000000);
      expect(state10M.potentialPrestigeDarkMatter, 150.0);

      final state40M = GameState.initial().copyWith(lifetimeCredits: 40000000);
      expect(state40M.potentialPrestigeDarkMatter, 300.0);
    });


    test('Offline income calculation clamps to cap', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      // 10 hours ago
      final past = now - (10 * 3600 * 1000);
      final state = GameState.initial().copyWith(lastSaveTimestamp: past);

      final result = StorageService.calculateOfflineEarnings(state);

      expect(result.elapsedSeconds, closeTo(36000, 5));
      // Base cap is 2 hours = 7200s
      expect(result.cappedSeconds, 7200);
      expect(result.coinsEarned > 0, true);
    });
  });

  group('Game State & Merging Flow', () {
    test('Merging two Tier 1 ships produces a Tier 2 ship', () {
      final notifier = GameEconomyNotifier(GameState.initial());
      expect(notifier.state.gridSlots[0]?.tier, 1);

      // Buy another ship to put it in slot 1
      notifier.state = notifier.state.copyWith(credits: 10000);
      final bought = notifier.purchaseShip();
      expect(bought, true);
      expect(notifier.state.gridSlots[1]?.tier, 1);

      // Merge slot 0 onto slot 1
      final merged = notifier.handleGridMergeOrMove(0, 1);
      expect(merged, true);
      expect(notifier.state.gridSlots[0], isNull);
      expect(notifier.state.gridSlots[1]?.tier, 2);
      expect(notifier.state.totalMergesCount, 1);
    });

    test('Skill upgrades consume Dark Matter and increase levels', () {
      final notifier = GameEconomyNotifier(GameState.initial().copyWith(darkMatter: 100));
      final skillId = notifier.state.career.skills.first.id;

      final success = notifier.upgradeSkill(skillId);
      expect(success, true);
      expect(notifier.state.darkMatter < 100, true);
      expect(notifier.state.career.skills.first.level, 1);
    });

    test('Boss Incursion spawns, receives damage, and awards bounty on defeat', () {
      final notifier = GameEconomyNotifier(GameState.initial());
      expect(notifier.state.activeBoss, isNull);

      notifier.spawnAlienBoss();
      expect(notifier.state.activeBoss, isNotNull);
      final initialHp = notifier.state.activeBoss!.maxHealth;
      expect(notifier.state.activeBoss!.currentHealth, initialHp);

      // Deal partial damage
      notifier.damageBoss(50.0);
      expect(notifier.state.activeBoss!.currentHealth, initialHp - 50.0);

      // Deal lethal damage
      final double prevDm = notifier.state.darkMatter;
      notifier.damageBoss(initialHp);
      expect(notifier.state.activeBoss, isNull); // Defeated and cleared
      expect(notifier.state.darkMatter > prevDm, true); // Awarded bounty Dark Matter
    });

    test('Relic Matrix tracks shards, levels up, and applies passive multipliers', () {
      final notifier = GameEconomyNotifier(GameState.initial());
      expect(notifier.state.relics.isNotEmpty, true);

      final chronosRelic = notifier.state.relics.firstWhere((r) => r.id == 'relic_chronos_core');
      expect(chronosRelic.level, 1);
      expect(notifier.relicSpeedMultiplier, 1.15); // +15%

      // Award shards
      notifier.awardRelicShards('relic_chronos_core', 6);
      final updatedRelic = notifier.state.relics.firstWhere((r) => r.id == 'relic_chronos_core');
      expect(updatedRelic.shards, 6);
      expect(updatedRelic.canUpgrade, true);

      // Upgrade to Level 2
      final upgraded = notifier.upgradeRelic('relic_chronos_core');
      expect(upgraded, true);
      expect(notifier.state.relics.firstWhere((r) => r.id == 'relic_chronos_core').level, 2);
      expect(notifier.relicSpeedMultiplier, 1.30); // +30%
    });

    test('Wormhole Roulette: 1 Free + 2 Ad spins per 24h daily cycle limit', () {
      final notifier = GameEconomyNotifier(GameState.initial());
      expect(notifier.state.effectiveDailySpinsUsed, 0);
      expect(notifier.state.canSpinFree, true);
      expect(notifier.state.canSpinAd, false);
      expect(notifier.state.canSpinAny, true);

      final segments = RouletteRewardModel.getSegments();
      final dmReward = segments.firstWhere((s) => s.type == RouletteRewardType.darkMatter);

      // Spin 1: Free Spin
      final double prevDm = notifier.state.darkMatter;
      notifier.claimRouletteReward(dmReward);
      expect(notifier.state.darkMatter > prevDm, true);
      expect(notifier.state.effectiveDailySpinsUsed, 1);
      expect(notifier.state.canSpinFree, false);
      expect(notifier.state.canSpinAd, true);

      // Spin 2: 1st Ad Spin
      notifier.claimRouletteReward(dmReward);
      expect(notifier.state.effectiveDailySpinsUsed, 2);
      expect(notifier.state.canSpinFree, false);
      expect(notifier.state.canSpinAd, true);

      // Spin 3: 2nd Ad Spin (Cap of 3 reached)
      notifier.claimRouletteReward(dmReward);
      expect(notifier.state.effectiveDailySpinsUsed, 3);
      expect(notifier.state.canSpinFree, false);
      expect(notifier.state.canSpinAd, false);
      expect(notifier.state.isDailySpinsExhausted, true);
      expect(notifier.state.canSpinAny, false);
    });

    test('Wormhole Roulette: All 8 reward types execute accurately and reliably', () {
      final segments = RouletteRewardModel.getSegments();
      expect(segments.length, 8);

      // 1. Supernova Jackpot (100x credits)
      final notifier1 = GameEconomyNotifier(GameState.initial());
      final jackpot = segments.firstWhere((s) => s.type == RouletteRewardType.supernovaJackpot);
      final prevCreds1 = notifier1.state.credits;
      notifier1.claimRouletteReward(jackpot);
      expect(notifier1.state.credits > prevCreds1, true);

      // 2. Dark Matter (+50 DM)
      final notifier2 = GameEconomyNotifier(GameState.initial());
      final dm = segments.firstWhere((s) => s.type == RouletteRewardType.darkMatter);
      final prevDm = notifier2.state.darkMatter;
      notifier2.claimRouletteReward(dm);
      expect(notifier2.state.darkMatter, prevDm + 50.0);

      // 3. High-Tier Ship Drop
      final notifier3 = GameEconomyNotifier(GameState.initial());
      final shipDrop = segments.firstWhere((s) => s.type == RouletteRewardType.shipDrop);
      notifier3.claimRouletteReward(shipDrop);
      expect(notifier3.state.gridSlots.any((s) => s != null && s.tier >= 1 && !s.isBox), true);

      // 4. 2-Hour Time Warp
      final notifier4 = GameEconomyNotifier(GameState.initial());
      final warp = segments.firstWhere((s) => s.type == RouletteRewardType.timeWarp);
      final prevCreds4 = notifier4.state.credits;
      notifier4.claimRouletteReward(warp);
      expect(notifier4.state.credits > prevCreds4, true);

      // 5. Hyperspace Fever Rush (30s)
      final notifier5 = GameEconomyNotifier(GameState.initial());
      final fever = segments.firstWhere((s) => s.type == RouletteRewardType.feverRush);
      notifier5.claimRouletteReward(fever);
      expect(notifier5.state.isFeverActive, true);
      expect(notifier5.state.feverTimeRemaining, 30.0);

      // 6. Relic Shards (+5)
      final notifier6 = GameEconomyNotifier(GameState.initial());
      final relics = segments.firstWhere((s) => s.type == RouletteRewardType.relicShards);
      notifier6.claimRouletteReward(relics);
      final totalShards = notifier6.state.relics.fold<int>(0, (sum, r) => sum + r.shards);
      expect(totalShards >= 5, true);

      // 7. 25X Credits Multiplier
      final notifier7 = GameEconomyNotifier(GameState.initial());
      final credits25x = segments.firstWhere((s) => s.type == RouletteRewardType.creditsMultiplier);
      final prevCreds7 = notifier7.state.credits;
      notifier7.claimRouletteReward(credits25x);
      expect(notifier7.state.credits > prevCreds7, true);

      // 8. Mystery Supply Crate
      final notifier8 = GameEconomyNotifier(GameState.initial());
      final crate = segments.firstWhere((s) => s.type == RouletteRewardType.mysteryCrate);
      notifier8.claimRouletteReward(crate);
      expect(notifier8.state.gridSlots.any((s) => s != null && s.isBox), true);
    });

    test('Fleet Dispatch Validation: Track capacity (4 max), duplicate prevention, and tier replacement', () {
      final notifier = GameEconomyNotifier(GameState.initial());

      // 1. Initial track is empty in tutorial step 0
      expect(notifier.state.trackShips.length, 0);

      // Dispatch slot 0 -> successAdded
      expect(notifier.dispatchShipToTrack(0), DispatchResult.successAdded);
      expect(notifier.state.trackShips.length, 1);

      // 2. Trying to dispatch slot 0 again -> alreadyOnTrack
      final dupResult = notifier.dispatchShipToTrack(0);
      expect(dupResult, DispatchResult.alreadyOnTrack);

      // 3. Add Tier 2, Tier 3, Tier 4 ships to grid
      final newSlots = List<ShipModel?>.from(notifier.state.gridSlots);
      newSlots[1] = ShipModel.create(2);
      newSlots[2] = ShipModel.create(3);
      newSlots[3] = ShipModel.create(4);
      newSlots[4] = ShipModel.create(1); // Another Tier 1
      newSlots[5] = ShipModel.create(5); // Tier 5
      notifier.state = notifier.state.copyWith(gridSlots: newSlots);

      // Dispatch Tier 2 -> successAdded (Fleet 2/4)
      expect(notifier.dispatchShipToTrack(1), DispatchResult.successAdded);
      expect(notifier.state.trackShips.length, 2);

      // Dispatch Tier 3 -> successAdded (Fleet 3/4)
      expect(notifier.dispatchShipToTrack(2), DispatchResult.successAdded);
      expect(notifier.state.trackShips.length, 3);

      // Dispatch Tier 4 -> successAdded (Fleet 4/4 FULL)
      expect(notifier.dispatchShipToTrack(3), DispatchResult.successAdded);
      expect(notifier.state.trackShips.length, 4);

      // 4. Try to dispatch another Tier 1 when fleet has [1, 2, 3, 4] -> fleetFullLowerTier (Cannot add!)
      expect(notifier.dispatchShipToTrack(4), DispatchResult.fleetFullLowerTier);
      expect(notifier.state.trackShips.length, 4);

      // 5. Try to dispatch Tier 5 when fleet has [1, 2, 3, 4] -> successReplaced (Replaces lowest Tier 1 with Tier 5!)
      expect(notifier.dispatchShipToTrack(5), DispatchResult.successReplaced);
      expect(notifier.state.trackShips.length, 4);
      expect(notifier.state.trackShips.any((s) => s.tier == 5), true);
      expect(notifier.state.trackShips.any((s) => s.tier == 1), false);
    });

    test('Defensive Validations: Cannot scrap last remaining active ship and cannot merge crates', () {

      final notifier = GameEconomyNotifier(GameState.initial());
      // Initially 1 active ship on slot 0
      final int activeCount = notifier.state.gridSlots.where((s) => s != null && !s.isBox).length;
      expect(activeCount, 1);

      // Attempt to scrap the only ship -> must be rejected with -1.0
      final scrapResult = notifier.recycleShip(0);
      expect(scrapResult, -1.0);
      expect(notifier.state.gridSlots[0] != null, true);

      // Add second ship
      notifier.state = notifier.state.copyWith(
        credits: 10000,
      );
      notifier.purchaseShip();
      expect(notifier.state.gridSlots.where((s) => s != null && !s.isBox).length, 2);

      // Now scrapping one ship is allowed
      final scrapAllowed = notifier.recycleShip(1);
      expect(scrapAllowed > 0, true);
    });

    test('Constellation Expeditions: Launch, tier validation, speedup, and claim bounty', () {
      final notifier = GameEconomyNotifier(GameState.initial());
      expect(notifier.state.expeditions.isEmpty, true);
      expect(notifier.state.readyExpeditionsCount, 0);

      // Attempt to launch Orion (requires Tier 3) with Tier 1 -> must fail
      final failedLaunch = notifier.launchExpedition('sector_orion', 1);
      expect(failedLaunch, false);
      expect(notifier.state.expeditions.isEmpty, true);

      // Launch Andromeda (requires Tier 1) with Tier 1 -> must succeed
      final successLaunch = notifier.launchExpedition('sector_andromeda', 1);
      expect(successLaunch, true);
      expect(notifier.state.expeditions.length, 1);

      final mission = notifier.state.expeditions.first;
      expect(mission.sectorId, 'sector_andromeda');
      expect(mission.isClaimed, false);
      expect(mission.isInProgress, true);

      // Cannot launch the same sector concurrently
      final duplicateLaunch = notifier.launchExpedition('sector_andromeda', 2);
      expect(duplicateLaunch, false);

      // Speed up expedition by 300 seconds (completes 5-min sortie)
      notifier.speedUpExpeditionWithAd(mission.id, secondsReduced: 400);
      final updatedMission = notifier.state.expeditions.first;
      expect(updatedMission.isReadyToClaim, true);
      expect(notifier.state.readyExpeditionsCount, 1);

      // Claim Bounty
      final double prevCredits = notifier.state.credits;
      final claimed = notifier.claimExpeditionReward(updatedMission.id);
      expect(claimed, true);
      expect(notifier.state.credits > prevCredits, true);
      expect(notifier.state.expeditions.isEmpty, true);
      expect(notifier.state.readyExpeditionsCount, 0);
    });

    test('Daily Commander Login Calendar: Claim rewards, streak progression, and cooldown', () {
      final notifier = GameEconomyNotifier(GameState.initial());
      expect(notifier.state.canClaimDailyReward, true);
      expect(notifier.state.currentLoginDay, 1);

      // Claim Day 1
      final prevCoins = notifier.state.credits;
      final claimed = notifier.claimDailyLoginReward();
      expect(claimed, true);
      expect(notifier.state.credits, prevCoins + 150.0);
      expect(notifier.state.currentLoginDay, 2);

      expect(notifier.state.canClaimDailyReward, false); // On cooldown

      // Cannot claim again immediately
      final secondClaim = notifier.claimDailyLoginReward();
      expect(secondClaim, false);

      // Simulate 24 hours later
      final pastClaimTime = DateTime.now().millisecondsSinceEpoch - (24 * 3600 * 1000);
      notifier.state = notifier.state.copyWith(lastLoginClaimEpoch: pastClaimTime);
      expect(notifier.state.canClaimDailyReward, true);

      // Claim Day 2 with Double Reward (Ad)
      final prevShards = notifier.state.relics.first.shards;
      final doubleClaim = notifier.claimDailyLoginReward(doubleWithAd: true);
      expect(doubleClaim, true);
      expect(notifier.state.currentLoginDay, 3);
      // Awarded 5 * 2 = 10 relic shards
      final totalShardsNow = notifier.state.relics.fold<int>(0, (s, r) => s + r.shards);
      expect(totalShardsNow > prevShards, true);
    });

    test('Cosmic Store: Time Warp, Dark Matter conversion, and VIP Drone Auto-Collector', () {
      final notifier = GameEconomyNotifier(GameState.initial().copyWith(
        credits: 1000000.0,
        darkMatter: 250.0,
      ));


      // 1. Dark Matter Transmutation (250K credits -> 10 DM)
      final dmItem = StoreItem.catalog.firstWhere((i) => i.id == 'dm_cache_soft');
      final buyDm = notifier.purchaseStoreItem(dmItem);
      expect(buyDm, true);
      expect(notifier.state.credits, 750000.0);
      expect(notifier.state.darkMatter, 260.0);


      // 2. Permanent Quantum Overdrive (+50% income)
      final overdriveItem = StoreItem.catalog.firstWhere((i) => i.id == 'perm_quantum_overdrive');
      final buyOverdrive = notifier.purchaseStoreItem(overdriveItem);
      expect(buyOverdrive, true);
      expect(notifier.state.permanentIncomeMultiplier, 1.50);

      // 3. VIP Drone Lifetime License
      expect(notifier.state.isDroneCurrentlyActive, false);
      final droneItem = StoreItem.catalog.firstWhere((i) => i.id == 'drone_permanent');
      final buyDrone = notifier.purchaseStoreItem(droneItem);
      expect(buyDrone, true);
      expect(notifier.state.isDronePermanent, true);
      expect(notifier.state.isDroneCurrentlyActive, true);

      // 4. VIP Drone Auto-Collector automatically opens delivery crates!
      notifier.dropMysteryCargo(tier: 4);
      final hasCrate = notifier.state.gridSlots.any((s) => s != null && s.isBox);
      expect(hasCrate, true);

      // Run Drone auto-collector
      final opened = notifier.checkAndRunDroneCollector();
      expect(opened, true);
      final crateRemaining = notifier.state.gridSlots.any((s) => s != null && s.isBox);
      expect(crateRemaining, false); // Opened into a ship!
    });

    test('Milestone Trophy Achievements: Evaluation, progress tracking, and claiming Dark Matter', () {
      final notifier = GameEconomyNotifier(GameState.initial());
      expect(notifier.state.achievements.length, 20);
      expect(notifier.state.unclaimedAchievementsCount, 0);

      // 1. Trigger merge achievement (Novice Commander: 10 merges)
      // Manually set 10 merges and evaluate
      notifier.state = notifier.state.copyWith(totalMergesCount: 10);
      notifier.claimDailyLoginReward(); // Triggers auto-evaluation / save
      
      // Set progress to target to test claim
      final updatedList = notifier.state.achievements.map((a) {
        if (a.id == 'merge_10') return a.copyWith(currentProgress: 10);
        return a;
      }).toList();
      notifier.state = notifier.state.copyWith(achievements: updatedList);


      expect(notifier.state.unclaimedAchievementsCount, 1);
      final initialDm = notifier.state.darkMatter;
      final claimed = notifier.claimAchievement('merge_10');
      expect(claimed, true);
      expect(notifier.state.darkMatter, initialDm + 5.0); // +5 DM reward
      expect(notifier.state.unclaimedAchievementsCount, 0);

      // Cannot claim twice
      final secondClaim = notifier.claimAchievement('merge_10');
      expect(secondClaim, false);
    });

    test('Live Events: Golden UFO 3-Card Mystery Pick payouts', () {
      final notifier = GameEconomyNotifier(GameState.initial().copyWith(credits: 500.0));

      // 1. UFO Card Pick: Generate 3 cards & apply coin card
      final cards = MysteryCardReward.generateThreeCards(
        fleetIncomePerLap: 50.0,
        highestTierUnlocked: 3,
      );
      expect(cards.length, 3);

      const coinCard = MysteryCardReward(
        type: MysteryRewardType.coinSurge,
        title: 'Mega Coin Surge',
        description: 'Instant Cash',
        iconAsset: '',
        colorValue: 0,
        creditsValue: 1000.0,
      );

      final prevCredits = notifier.state.credits;
      notifier.applyMysteryCardReward(coinCard);
      expect(notifier.state.credits, prevCredits + 1000.0);

      // 2. UFO Card Pick: Dark Matter with 2X Double Claim (Ad)
      final dmCard = const MysteryCardReward(
        type: MysteryRewardType.darkMatterGems,
        title: 'DM Pouch',
        description: 'Free Gems',
        iconAsset: '',
        colorValue: 0,
        darkMatterValue: 10.0,
      );
      final prevDm = notifier.state.darkMatter;
      notifier.applyMysteryCardReward(dmCard, doubleWithAd: true);
      expect(notifier.state.darkMatter, prevDm + 20.0); // Doubled from 10 to 20!
    });

    test('SectorThemeModel: Dynamic theme progression across planetary sectors', () {
      final themeS1 = SectorThemeModel.getThemeForSector(1);
      final themeS3 = SectorThemeModel.getThemeForSector(3);
      final themeS5 = SectorThemeModel.getThemeForSector(5);
      final themeS7 = SectorThemeModel.getThemeForSector(7);
      final themeS9 = SectorThemeModel.getThemeForSector(9);

      expect(themeS1.sectorName.contains('Orion'), true);
      expect(themeS3.sectorName.contains('Solar'), true);
      expect(themeS5.sectorName.contains('Cygnus'), true);
      expect(themeS7.sectorName.contains('Hyperion'), true);
      expect(themeS9.sectorName.contains('Cosmic'), true);

      // Verify colors evolve distinctly
      expect(themeS1.trackPrimaryGlow != themeS3.trackPrimaryGlow, true);
      expect(themeS3.trackPrimaryGlow != themeS5.trackPrimaryGlow, true);
    });

    test('SoundService: Sound & Haptic toggle preference mutations', () async {
      final soundService = SoundService();
      await soundService.setMuted(true);
      expect(soundService.isMuted, true);

      await soundService.setMuted(false);
      expect(soundService.isMuted, false);

      await soundService.setHapticsEnabled(false);
      expect(soundService.isHapticsEnabled, false);

      await soundService.setHapticsEnabled(true);
      expect(soundService.isHapticsEnabled, true);
    });

    test('Grid Auto-Sort: Rearranges cluttered ships ascending by tier with crates at the end', () {
      final notifier = GameEconomyNotifier(GameState.initial());
      final mixedSlots = List<ShipModel?>.filled(16, null);
      mixedSlots[0] = ShipModel.create(5);
      mixedSlots[1] = ShipModel.create(1, null, true); // crate
      mixedSlots[2] = ShipModel.create(2);
      mixedSlots[3] = ShipModel.create(1);
      mixedSlots[4] = ShipModel.create(4);

      notifier.state = notifier.state.copyWith(gridSlots: mixedSlots);
      final sorted = notifier.sortGridSlots();
      expect(sorted, true);

      // Verify sorted order: T1 -> T2 -> T4 -> T5 -> Crate -> nulls
      expect(notifier.state.gridSlots[0]!.tier, 1);
      expect(notifier.state.gridSlots[0]!.isBox, false);
      expect(notifier.state.gridSlots[1]!.tier, 2);
      expect(notifier.state.gridSlots[2]!.tier, 4);
      expect(notifier.state.gridSlots[3]!.tier, 5);
      expect(notifier.state.gridSlots[4]!.isBox, true); // Crate moved to end
      expect(notifier.state.gridSlots[5], isNull);
    });

    test('CosmicWeatherModel: Daily space weather modifiers cycle correctly', () {
      final monday = CosmicWeatherModel.getTodaysWeather(DateTime(2026, 9, 7)); // Monday
      expect(monday.weekday, DateTime.monday);
      expect(monday.speedMultiplier, 1.5);

      final wednesday = CosmicWeatherModel.getTodaysWeather(DateTime(2026, 9, 9)); // Wednesday
      expect(wednesday.weekday, DateTime.wednesday);
      expect(wednesday.bossDarkMatterMultiplier, 2.0);

      final saturday = CosmicWeatherModel.getTodaysWeather(DateTime(2026, 9, 12)); // Saturday
      expect(saturday.weekday, DateTime.saturday);
      expect(saturday.incomeMultiplier, 1.5);
    });

    test('Nitro Overdrive: Charging, Activation, and Expiration', () {
      final notifier = GameEconomyNotifier(GameState.initial());
      expect(notifier.state.nitroCharge, 1.0); // Starts fully charged
      expect(notifier.state.isNitroActive, false);

      // Activate Nitro
      final activated = notifier.activateNitroOverdrive();
      expect(activated, true);
      expect(notifier.state.isNitroActive, true);
      expect(notifier.state.nitroSecondsRemaining, 12.0);

      // Tick 5 seconds
      notifier.tickNitro(5.0);
      expect(notifier.state.isNitroActive, true);
      expect(notifier.state.nitroSecondsRemaining, 7.0);

      // Tick remaining 8 seconds to expire
      notifier.tickNitro(8.0);
      expect(notifier.state.isNitroActive, false);
      expect(notifier.state.nitroSecondsRemaining, 0.0);

      // Passive recharge
      notifier.tickNitro(22.5); // Recharges half of 45s
      expect((notifier.state.nitroCharge - 0.5).abs() < 0.05, true);
    });

    test('Prestige Mastery Perks: Starter ship tier and Dark Matter scaling', () {
      final state0 = GameState.initial();
      expect(state0.prestigeStarterShipTier, 1);
      expect(state0.prestigeDarkMatterMultiplier, 1.0);

      final stateP1 = state0.copyWith(
        career: state0.career.copyWith(prestigeCount: 1),
      );
      expect(stateP1.prestigeStarterShipTier, 2);

      final stateP5 = state0.copyWith(
        career: state0.career.copyWith(prestigeCount: 5),
      );
      expect(stateP5.prestigeLuckyCloneBonus, 0.10);
      expect(stateP5.prestigeBossDamageMultiplier, 1.50);
      expect(stateP5.prestigeDarkMatterMultiplier, 2.0);
    });

    test('Remove Ads & VIP License: Purchase awards Dark Matter and spins, and restores only when purchased', () {
      final notifier = GameEconomyNotifier(GameState.initial());
      final initialDm = notifier.state.darkMatter;
      final initialSpins = notifier.state.extraSpinsCount;

      // When no purchase has been made -> restorePurchases returns false
      final unpurchasedRestore = notifier.restorePurchases();
      expect(unpurchasedRestore, false);
      expect(notifier.state.hasRemovedAds, false);

      // Purchase Remove Ads
      notifier.purchaseRemoveAds();
      expect(notifier.state.hasRemovedAds, true);
      expect(notifier.state.darkMatter, initialDm + 500.0);
      expect(notifier.state.extraSpinsCount, initialSpins + 5);

      // Restore purchases after actual purchase -> returns true
      final restored = notifier.restorePurchases();
      expect(restored, true);
      expect(notifier.state.hasRemovedAds, true);
    });

    test('Localized Pricing Service: Returns non-empty price string and country code', () {
      final price = LocalizedPricingService.removeAdsPriceString;
      expect(price.isNotEmpty, true);
      final country = LocalizedPricingService.userCountryCode;
      expect(country.isNotEmpty, true);
    });

    test('User Growth Arc: Feature gating unlocks systems progressively across 13 tiers', () {
      // Tier 1: Fresh Cadet (Fleet speed)
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.fleetSpeedUpgrade, highestTier: 1), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.codex, highestTier: 1), false);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.autoMerge, highestTier: 1), false);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.techTree, highestTier: 1), false);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.bossBeacon, highestTier: 1), false);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.relics, highestTier: 1), false);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.prestige, highestTier: 1), false);

      // Tier 2: Spacecraft Codex unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.codex, highestTier: 2), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.autoSort, highestTier: 2), false);

      // Tier 3: Daily Calendar & Auto-Sort
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.dailyCalendar, highestTier: 3), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.autoSort, highestTier: 3), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.multiLaserGates, highestTier: 3), false);

      // Tier 4: Multi-Laser Gates
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.multiLaserGates, highestTier: 4), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.hyperPads, highestTier: 4), false);

      // Tier 5: Hyper-Pads & Roulette
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.hyperPads, highestTier: 5), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.roulette, highestTier: 5), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.autoMerge, highestTier: 5), false);

      // Tier 6: Auto-Merge Superpower
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.autoMerge, highestTier: 6), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.techTree, highestTier: 6), false);

      // Tier 7: Tech Tree
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.techTree, highestTier: 7), true);

      // Tier 8: Track Evolution
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.trackEvolution, highestTier: 8), true);

      // Tier 9: Achievements
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.achievements, highestTier: 9), true);

      // Tier 10: Boss Beacon
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.bossBeacon, highestTier: 10), true);

      // Tier 11: Relics & Expeditions
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.relics, highestTier: 11), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.expeditions, highestTier: 11), true);

      // Tier 12: Cosmic Store
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.cosmicStore, highestTier: 12), true);

      // Tier 13+: Prestige
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.prestige, highestTier: 13), true);

      // Verify "How It Works" metadata is populated for all features
      for (final feat in GameFeature.values) {
        final info = UserGrowthService.getFeatureInfo(feat);
        expect(info.title.isNotEmpty, true);
        expect(info.description.isNotEmpty, true);
        expect(info.howItWorks.isNotEmpty, true);
        expect(info.proTip.isNotEmpty, true);
      }

      // Prestige unlocked early if lifetime coins >= 5M
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.prestige, highestTier: 3, lifetimeCredits: 6000000.0), true);
    });

    test('Cadet Tutorial Progression: Advances from Step 0 (Dispatch) -> Step 1 (Speed) -> Step 2 (Buy) -> Step 3 (Merge) -> Step 4 (Circuit) -> Step 5 (Complete)', () {
      final notifier = GameEconomyNotifier(GameState.initial().copyWith(credits: 500.0));
      expect(notifier.state.tutorialStep, 0);

      // 1. Dispatching ship to track advances to Step 1 (Speed Tap)
      notifier.dispatchShipToTrack(0);
      expect(notifier.state.tutorialStep, 1);

      // 2. Tapping the circuit 3 times for turbo speed advances to Step 2 (Buy Ship)
      notifier.tapRacetrackBoost();
      notifier.tapRacetrackBoost();
      notifier.tapRacetrackBoost();
      expect(notifier.state.tutorialStep, 2);

      // 3. Purchasing a ship advances to Step 3 (Merge Ships)
      notifier.purchaseShip();
      expect(notifier.state.tutorialStep, 3);

      // 4. Merging two Tier 1 ships advances to Step 4 (Circuit Upgrade)
      notifier.state = notifier.state.copyWith(
        gridSlots: [ShipModel.create(1), ShipModel.create(1), ...List.generate(14, (_) => null)],
      );
      notifier.handleGridMergeOrMove(0, 1);
      expect(notifier.state.tutorialStep, 4);

      // 5. Upgrading Circuit Laser Gate or Fleet Speed completes the tutorial (Step 5) and awards bonus
      notifier.upgradeFleetSpeed();
      expect(notifier.state.tutorialStep, 5);
    });

    test('Circuit Engineering: Fleet Engine Speed upgrades scale cost and multiplier', () {
      final notifier = GameEconomyNotifier(GameState.initial().copyWith(credits: 1000.0));
      expect(notifier.state.fleetSpeedLevel, 1);
      expect(notifier.state.fleetSpeedMultiplier, 1.0);
      final initialCost = notifier.state.fleetSpeedUpgradeCost;
      expect(initialCost, 150.0);

      // Upgrade Speed Level 1 -> 2
      final upgraded = notifier.upgradeFleetSpeed();
      expect(upgraded, true);
      expect(notifier.state.fleetSpeedLevel, 2);
      expect(notifier.state.fleetSpeedMultiplier, 1.02); // +2% per level
      expect(notifier.state.credits, 1000.0 - 150.0);
      expect(notifier.state.fleetSpeedUpgradeCost > initialCost, true);
    });

    test('Circuit Engineering: Multi-Laser Finish Gates unlock up to 4 gates on the circuit', () {
      final notifier = GameEconomyNotifier(GameState.initial().copyWith(credits: 600000.0));
      expect(notifier.state.finishLinesCount, 1);
      expect(notifier.state.nextFinishLineCost, 5000.0);

      // Unlock Gate 2 (Dual-Gate Circuit)
      expect(notifier.unlockNextFinishLine(), true);
      expect(notifier.state.finishLinesCount, 2);
      expect(notifier.state.nextFinishLineCost, 50000.0);

      // Unlock Gate 3 (Tri-Gate Circuit)
      expect(notifier.unlockNextFinishLine(), true);
      expect(notifier.state.finishLinesCount, 3);
      expect(notifier.state.nextFinishLineCost, 500000.0);

      // Unlock Gate 4 (Quad-Gate Singularity Circuit)
      expect(notifier.unlockNextFinishLine(), true);
      expect(notifier.state.finishLinesCount, 4);
      expect(notifier.state.nextFinishLineCost, null); // Maxed out!

      // Cannot unlock beyond Gate 4
      expect(notifier.unlockNextFinishLine(), false);
    });

    test('Circuit Ascension: Evolving Track morphs circuit tier, resets gates to 1, and multiplies income', () {
      final notifier = GameEconomyNotifier(
        GameState.initial().copyWith(
          credits: 20000000.0, // 20M credits
          finishLinesCount: 4, // Max gates unlocked on Tier 1
          circuitTier: 1,
        ),
      );

      expect(notifier.state.circuitTier, 1);
      expect(notifier.state.circuitIncomeMultiplier, 1.0);
      expect(notifier.state.trackEvolutionCost, 1500000.0);
      expect(notifier.state.canEvolveTrack, true);

      // Evolve to Track Tier 2 (Hyper-Elliptical Superhighway)
      final evolved = notifier.evolveTrackCircuit();
      expect(evolved, true);
      expect(notifier.state.circuitTier, 2);
      expect(notifier.state.circuitIncomeMultiplier, 1.5);
      expect(notifier.state.finishLinesCount, 1); // Reset for new tier
      expect(notifier.state.credits, 20000000.0 - 1500000.0);
      expect(notifier.state.circuitTierName, 'Hyper-Elliptical Superhighway');
      expect(notifier.state.trackEvolutionCost, 15000000.0); // 15M for Tier 3
    });

    test('Circuit Engineering: Hyper-Pads Boost upgrade scales impulse multiplier and cost', () {
      final notifier = GameEconomyNotifier(GameState.initial().copyWith(credits: 5000.0));
      expect(notifier.state.boostPadLevel, 1);
      expect(notifier.state.boostPadMultiplier, 1.50);
      expect(notifier.state.boostPadUpgradeCost, 1000.0);

      // Upgrade to Level 2
      final upgraded = notifier.upgradeBoostPad();
      expect(upgraded, true);
      expect(notifier.state.boostPadLevel, 2);
      expect(notifier.state.boostPadMultiplier, 1.65);
      expect(notifier.state.credits, 5000.0 - 1000.0);
      expect(notifier.state.boostPadUpgradeCost, 1600.0);
    });

    test('Economy Calibration: Calibrated payout scales harmoniously with tier', () {
      final shipT1 = ShipModel.create(1);
      expect(shipT1.calculateIncomePayout(), 4.0);

      final shipT2 = ShipModel.create(2);
      expect(shipT2.calculateIncomePayout(), 4.0 * 1.85);

      final shipT3 = ShipModel.create(3);
      expect(shipT3.calculateIncomePayout(), 4.0 * 1.85 * 1.85);
    });

    test('User Growth System: Commander Ranks map accurately across ship tiers', () {
      expect(UserGrowthService.getCommanderRank(1).title, 'Novice Cadet');
      expect(UserGrowthService.getCommanderRank(2).title, 'Space Scout');
      expect(UserGrowthService.getCommanderRank(3).title, 'Flight Officer');
      expect(UserGrowthService.getCommanderRank(4).title, 'Fleet Navigator');
      expect(UserGrowthService.getCommanderRank(5).title, 'Operations Specialist');
      expect(UserGrowthService.getCommanderRank(6).title, 'Flight Captain');
      expect(UserGrowthService.getCommanderRank(7).title, 'Quantum Engineer');
      expect(UserGrowthService.getCommanderRank(8).title, 'Battle Commander');
      expect(UserGrowthService.getCommanderRank(9).title, 'Fleet Vanguard');
      expect(UserGrowthService.getCommanderRank(10).title, 'Starfleet Marshal');
      expect(UserGrowthService.getCommanderRank(11).title, 'Galactic Archaeologist');
      expect(UserGrowthService.getCommanderRank(12).title, 'Cosmic Admiral');
      expect(UserGrowthService.getCommanderRank(13).title, 'Galactic Overlord');
      expect(UserGrowthService.getCommanderRank(16).title, 'Galactic Overlord');
    });

    test('User Growth System: Progressive feature unlock gating across all 13 stages', () {
      // Tier 1: Speed upgrades unlocked, Auto-merge/gates/pads locked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.fleetSpeedUpgrade, highestTier: 1), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.codex, highestTier: 1), false);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.autoMerge, highestTier: 1), false);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.multiLaserGates, highestTier: 1), false);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.hyperPads, highestTier: 1), false);

      // Tier 2: Spacecraft Codex unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.codex, highestTier: 2), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.dailyCalendar, highestTier: 2), false);

      // Tier 3: Daily Calendar & Auto-Sort unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.dailyCalendar, highestTier: 3), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.autoSort, highestTier: 3), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.multiLaserGates, highestTier: 3), false);

      // Tier 4: Multi-Laser Gates unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.multiLaserGates, highestTier: 4), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.hyperPads, highestTier: 4), false);

      // Tier 5: Hyper-Pads & Roulette unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.hyperPads, highestTier: 5), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.roulette, highestTier: 5), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.autoMerge, highestTier: 5), false);

      // Tier 6: Auto-Merge unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.autoMerge, highestTier: 6), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.techTree, highestTier: 6), false);

      // Tier 7: Tech Tree unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.techTree, highestTier: 7), true);

      // Tier 8: Track Evolution unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.trackEvolution, highestTier: 8), true);

      // Tier 9: Milestone Trophies (Achievements) unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.achievements, highestTier: 9), true);

      // Tier 10: Boss Beacon unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.bossBeacon, highestTier: 10), true);

      // Tier 11: Relics & Expeditions unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.relics, highestTier: 11), true);
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.expeditions, highestTier: 11), true);

      // Tier 12: Cosmic Store unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.cosmicStore, highestTier: 12), true);

      // Tier 13: Prestige unlocked
      expect(UserGrowthService.isFeatureUnlocked(GameFeature.prestige, highestTier: 13), true);
    });

    test('User Growth System: Learning Milestone Quests progression and rewards', () {
      final notifier = GameEconomyNotifier(GameState.initial().copyWith(
        highestTierUnlocked: 2,
        credits: 0.0,
        darkMatter: 0.0,
      ));

      final activeQuest = UserGrowthService.getActiveMilestone(notifier.state);
      expect(activeQuest, isNotNull);
      expect(activeQuest!.id, 1);
      expect(activeQuest.checkCompleted(notifier.state), true);

      // Claim Quest 1 reward
      final claimed = notifier.claimLearningMilestone(1);
      expect(claimed, true);
      expect(notifier.state.claimedLearningMilestones, contains(1));
      expect(notifier.state.credits, 500.0);
      expect(notifier.state.darkMatter, 5.0);

      // Next active milestone should be Quest 2
      final nextQuest = UserGrowthService.getActiveMilestone(notifier.state);
      expect(nextQuest?.id, 2);
    });

    test('Combat Mechanics: Boss Archetypes and Kinetic Shield absorption', () {
      final boss = const BossModel(
        id: 'test_shielded',
        name: 'Shielded Titan Mk.1',
        spriteAsset: 'assets/kenney_space-shooter-remastered/PNG/Enemies/enemyBlack3.png',
        archetype: BossArchetype.shieldedTitan,
        maxHealth: 500.0,
        currentHealth: 500.0,
        maxShieldHealth: 200.0,
        currentShieldHealth: 200.0,
        timeRemaining: 30.0,
        bountyCredits: 10000.0,
        bountyDarkMatter: 10.0,
      );

      expect(boss.hasShield, true);
      expect(boss.shieldPercentage, 1.0);

      // 1. Partial shield hit
      final hit1 = boss.applyDamage(80.0);
      expect(hit1.currentShieldHealth, 120.0);
      expect(hit1.currentHealth, 500.0); // Hull unharmed

      // 2. Shield break & breakthrough damage
      final hit2 = hit1.applyDamage(150.0);
      expect(hit2.currentShieldHealth, 0.0);
      expect(hit2.hasShield, false);
      expect(hit2.currentHealth, 500.0 - 30.0); // 30 dmg pierced into hull
    });

    test('Razorpay Payment Service: Test key configuration and checkout callback handling', () async {
      final service = RazorpayPaymentService();
      expect(RazorpayPaymentService.testKeyId, 'rzp_test_jX0oGdLK69tv2V');

      String? recordedPaymentId;
      service.startVipPassPayment(
        onSuccess: (paymentId) {
          recordedPaymentId = paymentId;
        },
        onFailure: (_) {},
      );

      // Wait for test fallback resolution
      await Future.delayed(const Duration(milliseconds: 700));
      expect(recordedPaymentId != null, true);
      expect(recordedPaymentId!.contains('test'), true);
      service.dispose();
    });

    test('Contextual Auto-Sort Tutorial: Detects cluttered grid, triggers guided tutorial, awards bonus rewards on sort', () {
      // 1. Clean / few ships: isGridUnsorted is false
      final cleanState = GameState.initial();
      expect(cleanState.isGridUnsorted, false);
      expect(cleanState.hasSeenSortTutorial, false);

      // 2. Cluttered grid with 5 ships out of order
      final clutteredState = cleanState.copyWith(
        gridSlots: [
          ShipModel.create(3),
          ShipModel.create(1),
          ShipModel.create(2),
          ShipModel.create(1),
          ShipModel.create(2),
          ...List.generate(11, (_) => null),
        ],
        tutorialStep: 5,
        highestTierUnlocked: 3,
      );
      expect(clutteredState.isGridUnsorted, true);

      // 3. Executing sort organizes grid, awards +50 credits & +5 Dark Matter, and sets hasSeenSortTutorial true
      final notifier = GameEconomyNotifier(clutteredState);
      final sorted = notifier.sortGridSlots();
      expect(sorted, true);
      expect(notifier.state.hasSeenSortTutorial, true);
      expect(notifier.state.credits, 50.0);
      expect(notifier.state.darkMatter, 5.0);
      expect(notifier.state.isGridUnsorted, false);

      // Verify sorted order: T1, T1, T2, T2, T3
      expect(notifier.state.gridSlots[0]!.tier, 1);
      expect(notifier.state.gridSlots[1]!.tier, 1);
      expect(notifier.state.gridSlots[2]!.tier, 2);
      expect(notifier.state.gridSlots[3]!.tier, 2);
      expect(notifier.state.gridSlots[4]!.tier, 3);
    });

    test('Sector Directives: Canonical normalization on load and dynamic tier scaling on claim', () {
      // 1. Saved JSON with outdated 15000 / 50000 rewards automatically normalizes to canonical base values
      final legacyJson = {
        'id': 'm1_merge_3',
        'title': 'Fleet Assembly',
        'description': 'Merge ships 3 times on the grid',
        'type': 'mergeCount',
        'targetValue': 3,
        'currentProgress': 3,
        'rewardCoins': 15000, // Legacy outdated value
        'rewardDarkMatter': 1,
        'isClaimed': false,
      };

      final normalized = MissionModel.fromJson(legacyJson);
      expect(normalized.rewardCoins, 100.0); // Calibrated to 100!
      expect(normalized.isCompleted, true);

      // 2. Dynamic Claim Scaling at Tier 1 vs Tier 5
      final stateT1 = GameState.initial().copyWith(
        highestTierUnlocked: 1,
        career: GameState.initial().career.copyWith(missions: [normalized]),
      );
      final notifierT1 = GameEconomyNotifier(stateT1);
      notifierT1.claimMission('m1_merge_3');
      expect(notifierT1.state.credits, 100.0);

      final stateT5 = GameState.initial().copyWith(
        highestTierUnlocked: 5,
        career: GameState.initial().career.copyWith(missions: [normalized]),
      );
      final notifierT5 = GameEconomyNotifier(stateT5);
      notifierT5.claimMission('m1_merge_3');
      // Scaled by 1.5^4 = 5.0625 -> 506.25 coins
      expect(notifierT5.state.credits > 500.0, true);
    });

    test('Daily Commander Calendar: Dynamic progression tier scaling', () {
      // Tier 1: Day 1 base 150 coins
      final stateT1 = GameState.initial().copyWith(highestTierUnlocked: 1);
      final notifierT1 = GameEconomyNotifier(stateT1);
      notifierT1.claimDailyLoginReward();
      expect(notifierT1.state.credits, 150.0);

      // Tier 6: Day 1 scaled by 1.6^5 = 10.48576 -> 1572.86 coins
      final stateT6 = GameState.initial().copyWith(highestTierUnlocked: 6);
      final notifierT6 = GameEconomyNotifier(stateT6);
      notifierT6.claimDailyLoginReward();
      expect(notifierT6.state.credits > 1500.0, true);
    });
  });
}


















