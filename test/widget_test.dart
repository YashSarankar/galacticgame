import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:galactic_merge/main.dart';
import 'package:galactic_merge/models/game_state.dart';
import 'package:galactic_merge/models/ship_model.dart';
import 'package:galactic_merge/providers/ad_state_provider.dart';
import 'package:galactic_merge/screens/widgets/streamlined_header_bar.dart';
import 'package:galactic_merge/screens/widgets/bottom_command_dock.dart';
import 'package:galactic_merge/screens/widgets/flight_ops_strip.dart';
import 'package:galactic_merge/screens/widgets/merge_grid_view.dart';
import 'package:galactic_merge/screens/modals/discovery_modal.dart';
import 'package:galactic_merge/screens/modals/offline_earnings_modal.dart';
import 'package:galactic_merge/screens/modals/membership_plans_modal.dart';
import 'package:galactic_merge/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Galactic Merge UI & Widget Test Suite', () {
    testWidgets('GalacticMergeApp App Launch & Splash Screen Transition', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: GalacticMergeApp(),
        ),
      );

      expect(find.byType(GalacticMergeApp), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('StreamlinedHeaderBar renders currencies, VIP button, and responds to taps', (WidgetTester tester) async {
      final state = GameState.initial().copyWith(
        credits: 987654.0,
        darkMatter: 42.0,
        highestTierUnlocked: 5,
      );
      const adState = AdBoostState();
      final coinKey = GlobalKey();
      final dmKey = GlobalKey();

      bool openedMembership = false;
      bool openedSettings = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamlinedHeaderBar(
              state: state,
              adState: adState,
              coinCounterKey: coinKey,
              darkMatterCounterKey: dmKey,
              coinBounceAnimation: const AlwaysStoppedAnimation(1.0),
              onOpenMembership: () => openedMembership = true,
              onOpenSettings: () => openedSettings = true,
            ),
          ),
        ),
      );

      // Verify Currency Labels
      expect(find.textContaining('987.65K'), findsOneWidget);
      expect(find.textContaining('42 DM'), findsOneWidget);

      // Tap VIP / Plans button
      await tester.tap(find.byIcon(Icons.workspace_premium_rounded));
      await tester.pump();
      expect(openedMembership, true);

      // Tap Settings button
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pump();
      expect(openedSettings, true);
    });

    testWidgets('BottomCommandDock renders Buy, Sort, Sell and handles actions', (WidgetTester tester) async {
      final state = GameState.initial().copyWith(
        credits: 500.0,
        highestTierUnlocked: 3,
      );
      const adState = AdBoostState();

      bool bought = false;
      bool sorted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomCommandDock(
              gameState: state,
              adState: adState,
              canAffordShip: true,
              nextBuyCost: 100.0,
              dropTier: 1,
              hubBadgeCount: 0,
              onBuyShipTap: () => bought = true,
              onSortTap: () => sorted = true,
              onAutoMergeTap: () {},
              onSpeedBoostTap: () {},
              onCommandHubTap: () {},
              onRecycleShip: (idx) {},
            ),
          ),
        ),
      );

      // Verify buttons exist
      expect(find.textContaining('BUY T1'), findsOneWidget);
      expect(find.text('SORT'), findsOneWidget);
      expect(find.text('SELL'), findsOneWidget);

      // Tap Buy button
      await tester.tap(find.textContaining('BUY T1'));
      await tester.pump();
      expect(bought, true);

      // Tap Auto-Sort button
      await tester.tap(find.text('SORT'));
      await tester.pump();
      expect(sorted, true);
    });

    testWidgets('FlightOpsStrip renders speed, laser gate, boost pads buttons', (WidgetTester tester) async {
      final state = GameState.initial().copyWith(
        credits: 50000.0,
        highestTierUnlocked: 6,
        fleetSpeedLevel: 2,
        finishLinesCount: 1,
        boostPadCount: 0,
      );

      bool speedUpgraded = false;
      bool gateUnlocked = false;
      bool padUnlocked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlightOpsStrip(
              gameState: state,
              onUpgradeFleetSpeed: () => speedUpgraded = true,
              onUnlockFinishLine: () => gateUnlocked = true,
              onUnlockBoostPad: () => padUnlocked = true,
              onUpgradeBoostPad: () {},
              onEvolveTrack: () {},
            ),
          ),
        ),
      );

      // Verify strip controls
      expect(find.textContaining('SPEED'), findsOneWidget);
      expect(find.textContaining('GATES'), findsOneWidget);
      expect(find.textContaining('PAD'), findsOneWidget);

      // Tap Speed upgrade
      await tester.tap(find.textContaining('SPEED'));
      await tester.pump();
      expect(speedUpgraded, true);

      // Tap Gate
      await tester.tap(find.textContaining('GATES'));
      await tester.pump();
      expect(gateUnlocked, true);

      // Tap Pad
      await tester.tap(find.textContaining('PAD'));
      await tester.pump();
      expect(padUnlocked, true);
    });

    testWidgets('MergeGridView renders 16 slots with ships and mystery crates', (WidgetTester tester) async {
      final slots = List<ShipModel?>.filled(16, null);
      slots[0] = ShipModel.create(1); // Normal ship
      slots[1] = ShipModel.create(2, null, true); // Mystery box crate

      final state = GameState.initial().copyWith(
        gridSlots: slots,
        highestTierUnlocked: 3,
      );

      int? openedCrateIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MergeGridView(
              state: state,
              maxUnlockedGridSlots: 16,
              onMergeOrMove: (from, to) {},
              onOpenCrate: (idx) => openedCrateIndex = idx,
              onQuickClearDeadlock: () {},
              onMergeVfx: (from, to, ship, offset) {},
            ),
          ),
        ),
      );

      // Verify grid rendered
      expect(find.text('TAP OPEN'), findsOneWidget);

      // Tap on mystery crate to unbox
      await tester.tap(find.text('TAP OPEN'));
      await tester.pump();
      expect(openedCrateIndex, 1);
    });

    testWidgets('DiscoveryModal renders new tier unlock celebration and claim bounty', (WidgetTester tester) async {
      final ship = ShipModel.create(5);
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveryModal(
              ship: ship,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Verify discovery UI
      expect(find.text('NEW DISCOVERY UNLOCKED!'), findsOneWidget);
      expect(find.textContaining('TIER 5'), findsOneWidget);
      expect(find.text('COLLECT BOUNTY & DEPLOY'), findsOneWidget);

      // Tap claim button to dismiss
      await tester.tap(find.text('COLLECT BOUNTY & DEPLOY'));
      await tester.pump();
      expect(dismissed, true);
    });

    testWidgets('OfflineEarningsModal displays earnings ticker and triggers claims', (WidgetTester tester) async {
      const result = OfflineEarningsResult(
        elapsedSeconds: 3600,
        cappedSeconds: 3600,
        coinsEarned: 5000.0,
        ratePerSecond: 1.38,
      );

      bool claimedRegular = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineEarningsModal(
              result: result,
              isVip: false,
              onClaimRegular: () => claimedRegular = true,
              onClaimDoubled: () {},
            ),
          ),
        ),
      );

      // Advance ticker animation
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('WELCOME BACK, COMMANDER!'), findsOneWidget);
      expect(find.textContaining('WATCH AD & 2X'), findsOneWidget);

      // Tap regular claim
      await tester.tap(find.textContaining('Claim 1X'));
      await tester.pump();
      expect(claimedRegular, true);
    });

    testWidgets('MembershipPlansModal renders VIP Pass and feature cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MembershipPlansModal(),
            ),
          ),
        ),
      );

      expect(find.text('COMMANDER COMMISSION'), findsOneWidget);
      expect(find.text('VIP PASS'), findsOneWidget);
    });
  });
}
