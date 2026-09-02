import 'package:flutter_test/flutter_test.dart';
import 'package:galacticgame/models/game_state.dart';
import 'package:galacticgame/models/ship_model.dart';
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
      final shipTier1 = ShipModel.create(1);
      final shipTier2 = ShipModel.create(2);
      final shipTier3 = ShipModel.create(3);

      final income1 = shipTier1.calculateIncomePayout();
      final income2 = shipTier2.calculateIncomePayout();
      final income3 = shipTier3.calculateIncomePayout();

      expect(income1, 10.0);
      expect(income2, closeTo(21.0, 0.01));
      expect(income3, closeTo(44.1, 0.01));
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
  });
}


