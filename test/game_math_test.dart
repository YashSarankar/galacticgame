import 'package:flutter_test/flutter_test.dart';
import 'package:galacticgame/models/game_state.dart';
import 'package:galacticgame/models/ship_model.dart';
import 'package:galacticgame/models/roulette_reward_model.dart';
import 'package:galacticgame/models/store_item_model.dart';
import 'package:galacticgame/models/mystery_card_model.dart';
import 'package:galacticgame/models/sector_theme_model.dart';
import 'package:galacticgame/services/sound_service.dart';
import 'package:galacticgame/providers/game_economy_provider.dart';








import 'package:galacticgame/services/storage_service.dart';
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
    });

    test('Income payout formula scales with 2.1 factor', () {
      final ship1 = ShipModel.create(1);
      final ship2 = ShipModel.create(2);
      final ship3 = ShipModel.create(3);

      expect(ship1.calculateIncomePayout(), 10.0);
      expect(ship2.calculateIncomePayout(), 21.0);
      expect(ship3.calculateIncomePayout(), closeTo(44.1, 0.01));
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

    test('Wormhole Roulette claims rewards, consumes spins, and awards bonuses', () {
      final notifier = GameEconomyNotifier(GameState.initial());
      expect(notifier.state.canSpinFree, true);
      expect(notifier.state.extraSpinsCount, 1);

      final segments = RouletteRewardModel.getSegments();
      final dmReward = segments.firstWhere((s) => s.type == RouletteRewardType.darkMatter);

      final double prevDm = notifier.state.darkMatter;
      notifier.claimRouletteReward(dmReward);

      // Dark Matter awarded and extra spin consumed
      expect(notifier.state.darkMatter > prevDm, true);
      expect(notifier.state.extraSpinsCount, 0);

      // Award extra spin
      notifier.addExtraSpin(count: 2);
      expect(notifier.state.extraSpinsCount, 2);
      expect(notifier.state.canSpinFree, true);
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
      expect(notifier.state.credits, prevCoins + 1500.0);
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

    test('Live Events: Golden UFO 3-Card Mystery Pick and Comet Rush mini-game session payouts', () {
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

      // 3. Comet Rush Session Completion: 30 Taps + High Score
      final preCometCredits = notifier.state.credits;
      final preCometSpins = notifier.state.extraSpinsCount;
      notifier.completeCometRushSession(
        taps: 30,
        scoreMultiplier: 2.5,
        doubleWithAd: true,
      );
      expect(notifier.state.credits > preCometCredits, true);
      expect(notifier.state.extraSpinsCount > preCometSpins, true); // Earned bonus wheel spin!
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
  });
}








