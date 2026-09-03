import 'dart:async';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../game/galactic_game.dart';
import '../models/game_state.dart';
import '../models/ship_model.dart';
import '../models/skill_node_model.dart';

import '../providers/game_providers.dart';
import '../services/ad_manager.dart';
import '../utils/game_theme.dart';
import '../utils/number_formatter.dart';
import 'modals/offline_earnings_modal.dart';
import 'modals/discovery_modal.dart';

import 'modals/daily_calendar_modal.dart';
import 'modals/settings_modal.dart';
import 'modals/membership_plans_modal.dart';
import 'modals/feature_unlocked_modal.dart';
import 'modals/track_ascension_modal.dart';
import 'modals/fleet_codex_modal.dart';
import 'modals/skill_tree_modal.dart';
import 'modals/wormhole_roulette_modal.dart';
import 'modals/achievements_modal.dart';
import 'modals/relics_modal.dart';
import 'modals/expeditions_modal.dart';
import 'modals/cosmic_store_modal.dart';
import 'widgets/tutorial_guide_overlay.dart';
import 'widgets/idle_vfx_overlay.dart';
import 'modals/command_hub_modal.dart';


import '../services/user_growth_service.dart';
import '../services/localized_pricing_service.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';

import '../models/sector_theme_model.dart';

class MainGameScreen extends ConsumerStatefulWidget {










  const MainGameScreen({super.key});

  @override
  ConsumerState<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends ConsumerState<MainGameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final GalacticFlameGame _galacticGame;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _hasCheckedOffline = false;
  bool _isModalOpen = false;
  Timer? _cargoDropTimer;
  Timer? _feverTimer;
  Timer? _bossIncursionTimer;



  // GlobalKeys for Guided Cadet Onboarding Overlay Targets
  final GlobalKey _trackGlobalKey = GlobalKey();
  final GlobalKey _slot0GlobalKey = GlobalKey();
  final GlobalKey _slot1GlobalKey = GlobalKey();
  final GlobalKey _buyShipGlobalKey = GlobalKey();
  final GlobalKey _fleetSpeedGlobalKey = GlobalKey();
  final GlobalKey _sortButtonGlobalKey = GlobalKey();

  // Currency Wallet Targets & Idle VFX Controller
  final GlobalKey _coinCounterGlobalKey = GlobalKey();
  final GlobalKey _darkMatterCounterGlobalKey = GlobalKey();
  late final AnimationController _coinBounceController;
  late final Animation<double> _coinBounceAnimation;
  final IdleVfxController _vfxController = IdleVfxController();

  void _triggerCoinWalletBounce() {
    if (!mounted) return;
    _coinBounceController.forward(from: 0.0);
    HapticFeedback.selectionClick();
  }

  // Dynamic Matching Merge Target Tracking
  int? _draggingShipTier;
  int? _draggingFromSlotIndex;

  GlobalKey? _getTutorialTargetKey(int step) {
    switch (step) {
      case 0:
        return _slot0GlobalKey;
      case 1:
        return _trackGlobalKey;
      case 2:
        return _buyShipGlobalKey;
      case 3:
        return _slot0GlobalKey;
      case 4:
        return _fleetSpeedGlobalKey;
      case 10:
        return _sortButtonGlobalKey;
      default:
        return null;
    }
  }

  GlobalKey? _getTutorialDestinationKey(int step) {
    switch (step) {
      case 0:
        return _trackGlobalKey;
      case 3:
        return _slot1GlobalKey;
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Coin Wallet Bouncy Scale Animation
    _coinBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _coinBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.20)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.20, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_coinBounceController);

    _galacticGame = GalacticFlameGame(

      onIncomeEarned: (ship) {
        Future.microtask(() {
          if (!mounted) return;
          final adState = ref.read(adStateProvider);
          final double multiplier = adState.isSpeedBoostActive ? 2.0 : 1.0;
          ref
              .read(gameStateProvider.notifier)
              .recordIncomeLineCrossing(ship, adMultiplier: multiplier);
        });
      },
      onAsteroidDestroyed: (isDM, reward) {
        Future.microtask(() {
          if (!mounted) return;
          ref.read(gameStateProvider.notifier).recordAsteroidShattered(
                isDarkMatter: isDM,
                rewardCredits: reward,
              );

          final trackBox =
              _trackGlobalKey.currentContext?.findRenderObject() as RenderBox?;
          if (trackBox != null && trackBox.hasSize) {
            final trackCenter =
                trackBox.localToGlobal(trackBox.size.center(Offset.zero));
            _vfxController.spawnCoins(
              origin: trackCenter,
              targetKey:
                  isDM ? _darkMatterCounterGlobalKey : _coinCounterGlobalKey,
              count: isDM ? 6 : 5,
              color: isDM
                  ? const Color(0xFFBD00FF)
                  : const Color(0xFFFFD700),
              isGem: isDM,
              onTargetHit: _triggerCoinWalletBounce,
            );
            _vfxController.spawnFloatingText(
              origin: trackCenter,
              text: isDM
                  ? '+10 DM! 💎'
                  : '+${NumberFormatter.formatCredits(reward)}! 💰',
              color: isDM
                  ? const Color(0xFFBD00FF)
                  : const Color(0xFFFFD700),
            );
          }
        });
      },
      onCanvasTapped: () {
        Future.microtask(() {
          if (!mounted) return;
          ref.read(gameStateProvider.notifier).tapRacetrackBoost();
        });
      },
      onBossDamaged: (damage, {bool isTap = false}) {
        Future.microtask(() {
          if (!mounted) return;
          ref.read(gameStateProvider.notifier).damageBoss(damage, isTap: isTap);

          if (isTap) {
            final trackBox =
                _trackGlobalKey.currentContext?.findRenderObject() as RenderBox?;
            if (trackBox != null && trackBox.hasSize) {
              final trackCenter =
                  trackBox.localToGlobal(trackBox.size.center(Offset.zero));
              _vfxController.spawnFloatingText(
                origin: trackCenter +
                    Offset((Random().nextDouble() - 0.5) * 60,
                        (Random().nextDouble() - 0.5) * 40),
                text: '-${damage.toStringAsFixed(0)} 💥',
                color: const Color(0xFFFF0055),
              );
            }
          }
        });
      },
    );



    // Periodic Mystery Cosmic Cargo Crate Drops (Every 90 seconds)
    _cargoDropTimer = Timer.periodic(const Duration(seconds: 90), (_) {
      final tutorialStep = ref.read(gameStateProvider).tutorialStep;
      if (tutorialStep < 5) return;
      if (mounted && !_isModalOpen) {
        ref.read(gameStateProvider.notifier).dropMysteryCargo();
      }
    });

    // Real-time Boss, Nitro, and VIP Drone Auto-Collector ticker (100ms interval)
    int tickCount = 0;
    _feverTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && !_isModalOpen) {
        ref.read(gameStateProvider.notifier).tickBoss(0.1);
        ref.read(gameStateProvider.notifier).tickNitro(0.1);

        tickCount++;
        if (tickCount % 20 == 0) {
          // Check for unopened crates every 2 seconds if VIP drone is active
          ref.read(gameStateProvider.notifier).checkAndRunDroneCollector();
        }
      }
    });

    // Periodic Alien Boss Incursion (Every 2 minutes 30 seconds)
    _bossIncursionTimer =
        Timer.periodic(const Duration(minutes: 2, seconds: 30), (_) {
      final tutorialStep = ref.read(gameStateProvider).tutorialStep;
      if (tutorialStep < 5) return;
      if (mounted && !_isModalOpen) {
        ref.read(gameStateProvider.notifier).spawnAlienBoss();
      }
    });

    // Hook real-time ship discovery event (only triggers upon actual in-game merge!)
    ref.read(gameStateProvider.notifier).onShipDiscovered = (discoveredTier) {
      if (mounted) {
        _openGameModal((ctx) => DiscoveryModal(
              ship: ShipModel.create(discoveredTier),
              onDismiss: () {},
            ));
      }
    };

    // Hook progressive system unlock ceremony
    ref.read(gameStateProvider.notifier).onFeatureUnlocked = (tier, features) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && !_isModalOpen) {
            _openGameModal((ctx) => FeatureUnlockedModal(
                  features: features,
                  tierUnlocked: tier,
                  onLaunchFeature: (feat) {
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (!mounted) return;
                      switch (feat.feature) {
                        case GameFeature.codex:
                          _openGameModal((c) => const FleetCodexModal());
                          break;
                        case GameFeature.techTree:
                          _openGameModal((c) => const SkillTreeModal());
                          break;
                        case GameFeature.roulette:
                          _openGameModal((c) => const WormholeRouletteModal());
                          break;
                        case GameFeature.dailyCalendar:
                          _openGameModal((c) => const DailyCalendarModal());
                          break;
                        case GameFeature.achievements:
                          _openGameModal((c) => const AchievementsModal());
                          break;
                        case GameFeature.relics:
                          _openGameModal((c) => const RelicsModal());
                          break;
                        case GameFeature.expeditions:
                          _openGameModal((c) => const ExpeditionsModal());
                          break;
                        case GameFeature.cosmicStore:
                          _openGameModal((c) => const CosmicStoreModal());
                          break;
                        case GameFeature.autoMerge:
                          ref.read(gameStateProvider.notifier).autoMergeGrid();
                          break;
                        case GameFeature.autoSort:
                          ref.read(gameStateProvider.notifier).sortGridSlots();
                          break;
                        default:
                          break;
                      }
                    });
                  },
                ));
          }
        });
      }
    };

    // Start atmospheric space synthwave music
    SoundService().startBgm();

    // Initialize AdMob Banner

    _bannerAd = AdManager().createBannerAd(
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        }
      },
    );
    _bannerAd?.load();
  }



  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cargoDropTimer?.cancel();
    _feverTimer?.cancel();
    _bossIncursionTimer?.cancel();
    _coinBounceController.dispose();
    _vfxController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // Pause Flame engine loop, timers & sound to save battery
      _galacticGame.pauseEngine();
      SoundService().pauseBgm();
      // Instantly persist current game state to local storage
      final currentGameState = ref.read(gameStateProvider);
      StorageService.saveGameState(currentGameState);
    } else if (state == AppLifecycleState.resumed) {
      // Resume engine & sound
      _galacticGame.resumeEngine();
      SoundService().resumeBgm();

      // Trigger Offline Earnings Modal automatically on resume if away >= 60s
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _isModalOpen) return;
        final currentGameState = ref.read(gameStateProvider);
        if (currentGameState.tutorialStep < 5) return;

        final offlineResult =
            StorageService.calculateOfflineEarnings(currentGameState);
        if (!mounted || _isModalOpen) return;

        if (offlineResult.hasSignificantEarnings) {
          await _openGameModal((ctx) => OfflineEarningsModal(
                result: offlineResult,
                onClaimRegular: () {
                  ref
                      .read(gameStateProvider.notifier)
                      .claimOfflineEarnings(offlineResult.coinsEarned);
                  _triggerRewardFlyingCoins(count: 10);
                },
                onClaimDoubled: () {
                  ref.read(gameStateProvider.notifier).claimOfflineEarnings(
                        offlineResult.coinsEarned,
                        doubleReward: true,
                      );
                  _triggerRewardFlyingCoins(count: 14);
                },
              ));
        }
      });
    }
  }



  void _triggerRewardFlyingCoins({
    int count = 7,
    bool isGem = false,
    Color? color,
  }) {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final screenCenter = Offset(size.width / 2, size.height / 2);
    _vfxController.spawnCoins(
      origin: screenCenter,
      targetKey: isGem ? _darkMatterCounterGlobalKey : _coinCounterGlobalKey,
      count: count,
      color:
          color ?? (isGem ? const Color(0xFFBD00FF) : const Color(0xFFFFD700)),
      isGem: isGem,
      onTargetHit: _triggerCoinWalletBounce,
    );
  }

  Future<T?> _openGameModal<T>(WidgetBuilder builder) async {
    _isModalOpen = true;
    final result = await showDialog<T>(
      context: context,
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: builder(ctx),
      ),
    );
    if (mounted) {
      _isModalOpen = false;
      if (result == true) {
        _triggerRewardFlyingCoins(count: 8);
      }
    }
    return result;
  }


  void _checkOfflineEarningsOnStartup(WidgetRef ref) {
    if (_hasCheckedOffline) return;
    _hasCheckedOffline = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final offlineResult =
            await ref.read(initialGameLoaderProvider.future);
        if (!mounted) return;

        final gameState = ref.read(gameStateProvider);

        // If onboarding tutorial is still in progress, NEVER interrupt the player with popups!
        if (gameState.tutorialStep < 5) return;

        if (offlineResult != null && offlineResult.hasSignificantEarnings) {
          await _openGameModal((ctx) => OfflineEarningsModal(
                result: offlineResult,
                onClaimRegular: () {
                  ref
                      .read(gameStateProvider.notifier)
                      .claimOfflineEarnings(offlineResult.coinsEarned);
                  _triggerRewardFlyingCoins(count: 10);
                },
                onClaimDoubled: () {
                  ref.read(gameStateProvider.notifier).claimOfflineEarnings(
                        offlineResult.coinsEarned,
                        doubleReward: true,
                      );
                  _triggerRewardFlyingCoins(count: 14);
                },
              ));
        } else if (gameState.canClaimDailyReward &&
            UserGrowthService.isFeatureUnlocked(
              GameFeature.dailyCalendar,
              highestTier: gameState.highestTierUnlocked,
            )) {
          await _openGameModal((ctx) => const DailyCalendarModal());
        }
      } catch (e) {
        debugPrint('[MainGameScreen] Startup sequence exception: $e');
      }
    });
  }






  @override
  Widget build(BuildContext context) {
    _checkOfflineEarningsOnStartup(ref);

    // Listen for boss defeat to celebrate victory with celebratory toast banner
    ref.listen(gameStateProvider, (prev, next) {
      if (prev != null && prev.activeBoss != null && next.activeBoss == null) {
        if (prev.activeBoss!.currentHealth <= 0 || prev.activeBoss!.isDead) {
          final boss = prev.activeBoss!;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF131B3A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFFF0055), width: 1.5),
              ),
              content: Row(
                children: [
                  const Icon(Icons.stars_rounded,
                      color: Color(0xFFFFD700), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👾 ${boss.name.toUpperCase()} DESTROYED!',
                          style: const TextStyle(
                            color: Color(0xFFFF0055),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '+${NumberFormatter.formatCredits(boss.bountyCredits)} • +${NumberFormatter.formatDarkMatter(boss.bountyDarkMatter)} DM • +1 Spin!',
                          style: const TextStyle(
                            color: Color(0xFF00FF88),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      // Priority 2: Cadet Graduation (Step 4 -> Step 5)
      // Priority 2: Cadet Graduation (Step 4 -> Step 5)
      if (prev != null && prev.tutorialStep < 5 && next.tutorialStep == 5) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF00FF88), width: 1.5),
              ),
              content: const Row(
                children: [
                  Text('🎓', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CADET TRAINING COMPLETE! 🎓',
                          style: TextStyle(
                            color: Color(0xFF00FF88),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Flight Academy Passed! Merge spaceships to advance your Fleet!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        });
      }
    });

    final gameState = ref.watch(gameStateProvider);
    final adState = ref.watch(adStateProvider);


    final double nitroMultiplier = gameState.isNitroActive ? 3.0 : 1.0;

    // Sync active track ships, active boss, multi-laser finish lines, circuit tier, speed upgrades, nitro, and sector theme with Flame Game engine
    _galacticGame.updateShips(gameState.trackShips);
    _galacticGame.syncBoss(gameState.activeBoss);
    _galacticGame.updateFinishLines(gameState.finishLinesCount);
    _galacticGame.updateCircuitTier(gameState.circuitTier);
    _galacticGame.updateBoostPadMultiplier(gameState.boostPadMultiplier);
    _galacticGame.setSpeedMultiplier(
      (adState.isSpeedBoostActive ? 2.0 : 1.0) *
          nitroMultiplier *
          gameState.fleetSpeedMultiplier *
          gameState.permanentSpeedMultiplier,
      isFever: gameState.isNitroActive,
    );

    _galacticGame.updateSectorTheme(
      SectorThemeModel.getThemeForSector(gameState.career.sectorLevel),
    );
    _galacticGame.updateTutorialActive(gameState.tutorialStep < 5);






    // Base drop tier & discount calculations for store
    final discountSkill = gameState.career.skills.firstWhere(
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

    // Dynamic evolving purchase tier (scales with max unlocked tier and tech)
    final int dropTier =
        ref.watch(gameStateProvider.notifier).activeStoreBuyTier;
    final double rawNextBuyCost = ShipModel.calculatePurchaseCost(
      gameState.totalShipsPurchased,
      dropTier,
      discount: discountSkill.currentBonusValue,
    );
    // In Tutorial Step 2 ("Buy Second Ship"), ensure it is affordable with earned coins!
    final double nextBuyCost =
        gameState.tutorialStep == 2 ? min(rawNextBuyCost, gameState.credits) : rawNextBuyCost;
    final bool canAffordShip =
        (gameState.credits >= nextBuyCost || gameState.tutorialStep == 2) &&
        gameState.gridSlots.contains(null);

    return Scaffold(
      backgroundColor: GameTheme.backgroundVoid,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
            // 1. Top Banner Ad Slot (Hidden if Remove Ads purchased)
            _buildTopBannerSlot(gameState),

            // 2. Streamlined Top Header (Currencies + VIP + Settings)
            _buildStreamlinedHeader(gameState),

            // 3. Smart Contextual Objective Ticker (1 Dynamic Bar: Combat / Cadet / Milestone)
            _buildSmartContextualObjectiveTicker(gameState),

            // 4. Center Flame Canvas (Generous Expanded Racetrack with Live In-Game Events)
            Expanded(
              flex: 10,
              child: Container(
                key: _trackGlobalKey,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _draggingShipTier != null
                        ? const Color(0xFFFFD700)
                        : (gameState.isFeverActive
                            ? const Color(0xFFFFD700)
                            : GameTheme.neonCyan.withAlpha((0.3 * 255).round())),
                    width: _draggingShipTier != null
                        ? 2.2
                        : (gameState.isFeverActive ? 2.0 : 1.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _draggingShipTier != null
                          ? const Color(0xFFFFD700).withAlpha((0.5 * 255).round())
                          : (gameState.isFeverActive
                              ? const Color(0xFFFF0055).withAlpha((0.35 * 255).round())
                              : GameTheme.neonCyan.withAlpha((0.15 * 255).round())),
                      blurRadius: _draggingShipTier != null
                          ? 20
                          : (gameState.isFeverActive ? 18 : 12),
                      spreadRadius: _draggingShipTier != null
                          ? 2
                          : (gameState.isFeverActive ? 2 : 1),
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    DragTarget<int>(
                      onWillAcceptWithDetails: (details) => true,
                      onAcceptWithDetails: (details) {
                        final int fromSlot = details.data;
                        final ship = gameState.gridSlots[fromSlot];
                        final result = ref
                            .read(gameStateProvider.notifier)
                            .dispatchShipToTrack(fromSlot);

                        String message = '';
                        Color badgeColor = const Color(0xFF00F0FF);
                        IconData icon = Icons.rocket_launch_rounded;

                        switch (result) {
                          case DispatchResult.successAdded:
                            message = ship != null
                                ? '🚀 Tier ${ship.tier} Launched! Active Fleet (${ref.read(gameStateProvider).trackShips.length}/4) 💰'
                                : '🚀 Spaceship on Track! Earning Coins +25 💰';
                            badgeColor = const Color(0xFF00FF88);
                            icon = Icons.rocket_launch_rounded;
                            break;
                          case DispatchResult.successReplaced:
                            message = '⚡ Fleet Upgraded! Tier ${ship?.tier} replaced lower active ship (4/4 Max)';
                            badgeColor = const Color(0xFFFFD700);
                            icon = Icons.upgrade_rounded;
                            break;
                          case DispatchResult.alreadyOnTrack:
                            message = 'ℹ️ Tier ${ship?.tier} is already flying in active fleet!';
                            badgeColor = Colors.white70;
                            icon = Icons.info_outline_rounded;
                            break;
                          case DispatchResult.fleetFullLowerTier:
                            message = '⚠️ Fleet is Full (4/4)! Merge ships on the grid to deploy higher tiers.';
                            badgeColor = const Color(0xFFFF9900);
                            icon = Icons.warning_amber_rounded;
                            break;
                          case DispatchResult.invalidShip:
                            return;
                        }

                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF131B3A),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: badgeColor.withAlpha(120), width: 1.2),
                            ),
                            content: Row(
                              children: [
                                Icon(icon, color: badgeColor, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            duration: const Duration(milliseconds: 1500),
                          ),
                        );
                      },
                      builder: (context, candidateData, rejectedData) {
                        final bool isHovered = candidateData.isNotEmpty;

                        return Stack(
                          children: [
                            GameWidget(
                              key: const ValueKey('galactic_flame_game_canvas'),
                              game: _galacticGame,
                            ),

                            // Interactive Drop-to-Launch Cue
                            if (isHovered)
                              Positioned(
                                bottom: 14,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00FF88),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0xFF00FF88),
                                          blurRadius: 14,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.rocket_launch_rounded,
                                            color: Colors.black, size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'DROP TO LAUNCH INTO RACE! 🚀',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    // Live Track Fleet Capacity Indicator
                    Positioned(
                      top: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0F1D)
                              .withAlpha((0.85 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: gameState.trackShips.length >= 4
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF00F0FF)
                                    .withAlpha((0.5 * 255).round()),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.speed_rounded,
                              color: gameState.trackShips.length >= 4
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF00F0FF),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'RACING: ${gameState.trackShips.length}/4',
                              style: TextStyle(
                                color: gameState.trackShips.length >= 4
                                    ? const Color(0xFFFFD700)
                                    : const Color(0xFF00F0FF),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Friendly Empty Track Prompt if 0 ships racing
                    if (gameState.trackShips.isEmpty)
                      Center(
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A)
                                  .withAlpha((0.92 * 255).round()),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF00F0FF),
                                width: 1.6,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F0FF)
                                      .withAlpha((0.55 * 255).round()),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('👇', style: TextStyle(fontSize: 18)),
                                SizedBox(width: 8),
                                Text(
                                  'DRAG A SHIP HERE TO MAKE MONEY! 💰',
                                  style: TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),



                    // Hyperspace Nitro Overdrive Activation Pill Button
                    Positioned(
                      top: 8,
                      right: 10,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          final activated = ref
                              .read(gameStateProvider.notifier)
                              .activateNitroOverdrive();
                          if (!activated && !gameState.isNitroActive) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF131B3A),
                                content: Text(
                                  '⚡ Nitro Energy: ${(gameState.nitroCharge * 100).toInt()}%',
                                  style: const TextStyle(
                                      color: Color(0xFF00F0FF),
                                      fontWeight: FontWeight.bold),
                                ),
                                duration: const Duration(milliseconds: 600),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: gameState.isNitroActive
                                ? const Color(0xFFFF0055)
                                    .withAlpha((0.85 * 255).round())
                                : (gameState.nitroCharge >= 0.99
                                    ? const Color(0xFF00F0FF)
                                        .withAlpha((0.25 * 255).round())
                                    : Colors.black
                                        .withAlpha((0.6 * 255).round())),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: gameState.isNitroActive
                                  ? const Color(0xFFFF0055)
                                  : (gameState.nitroCharge >= 0.99
                                      ? const Color(0xFF00F0FF)
                                      : Colors.white24),
                              width: 1.5,
                            ),
                            boxShadow: [
                              if (gameState.isNitroActive ||
                                  gameState.nitroCharge >= 0.99)
                                BoxShadow(
                                  color: (gameState.isNitroActive
                                          ? const Color(0xFFFF0055)
                                          : const Color(0xFF00F0FF))
                                      .withAlpha((0.45 * 255).round()),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                color: gameState.isNitroActive
                                    ? Colors.white
                                    : (gameState.nitroCharge >= 0.99
                                        ? const Color(0xFF00F0FF)
                                        : Colors.white54),
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                gameState.isNitroActive
                                    ? '${gameState.nitroSecondsRemaining.toInt()}s WARP'
                                    : (gameState.nitroCharge >= 0.99
                                        ? 'NITRO READY'
                                        : '${(gameState.nitroCharge * 100).toInt()}%'),
                                style: TextStyle(
                                  color: gameState.isNitroActive
                                      ? Colors.white
                                      : (gameState.nitroCharge >= 0.99
                                          ? const Color(0xFF00F0FF)
                                          : Colors.white54),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 7. Track Circuit Engineering Bar (Speed Upgrades + Multi-Laser Gates)
            _buildCircuitEngineeringStrip(gameState),

            // 8. Interactive 4x4 Merge Grid UI
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: _buildMergeGrid(gameState),
              ),
            ),




            // 6. Streamlined Bottom Command Dock (Sell Bin, Auto/Sort, BUY SHIP, 2X Speed, Command Hub)
            _buildStreamlinedCommandDock(
              gameState: gameState,
              adState: adState,
              canAffordShip: canAffordShip,
              nextBuyCost: nextBuyCost,
              dropTier: dropTier,
            ),
          ],
        ),
        // GPU-Accelerated Flying Coins Magnet, Floating Arcade Texts & Merge Shockwaves
        IdleVfxOverlay(controller: _vfxController),

        if (gameState.tutorialStep < 5)
          TutorialGuideOverlay(
            tutorialStep: gameState.tutorialStep,
            targetKey: _getTutorialTargetKey(gameState.tutorialStep),
            destinationKey: _getTutorialDestinationKey(gameState.tutorialStep),
            onSkip: () {
              ref.read(gameStateProvider.notifier).advanceTutorialStep(5);
            },
          )
        else if (!gameState.hasSeenSortTutorial &&
            gameState.isGridUnsorted &&
            UserGrowthService.isFeatureUnlocked(
              GameFeature.autoSort,
              highestTier: gameState.highestTierUnlocked,
            ))
          TutorialGuideOverlay(
            tutorialStep: 10,
            targetKey: _sortButtonGlobalKey,
            onSkip: () {
              ref.read(gameStateProvider.notifier).skipSortTutorial();
            },
          ),
      ],
    ),
  ),
);
  }

  Widget _buildTopBannerSlot(GameState gameState) {
    if (gameState.hasRemovedAds) {
      return const SizedBox.shrink();
    }

    if (_isBannerAdLoaded && _bannerAd != null) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        color: Colors.black,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Sleek Simulated Cyber Banner Slot
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: GameTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: GameTheme.neonCyan.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'SPONSORED',
              style: TextStyle(
                color: GameTheme.neonCyan,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Galactic Hyperdrive Network • Upgrade Fleet Speed',
              style: TextStyle(color: GameTheme.textSecondary, fontSize: 10),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamlinedHeader(GameState state) {
    const double approxTrackLength = 1400.0;
    final adState = ref.watch(adStateProvider);
    final double speedMult = state.fleetSpeedMultiplier *
        (adState.isSpeedBoostActive ? 2.0 : 1.0);
    final double incomeMult = (adState.isSpeedBoostActive ? 2.0 : 1.0);

    final double estimatedIncomePerSecond = state.trackShips.fold<double>(
      0.0,
      (sum, s) =>
          sum +
          (s.calculateIncomePayout(multiplier: incomeMult) *
              state.finishLinesCount *
              (s.baseSpeed * speedMult / approxTrackLength)),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1024).withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F0FF).withAlpha(45),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(180),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Credits Pill (Soft Currency + Live Income Telemetry)
          Expanded(
            flex: 5,
            child: ScaleTransition(
              scale: _coinBounceAnimation,
              child: Container(
                key: _coinCounterGlobalKey,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GameTheme.neonGold.withAlpha(45),
                      const Color(0xFF1B180A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GameTheme.neonGold.withAlpha(110),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: GameTheme.neonGold.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.monetization_on_rounded,
                        color: GameTheme.neonGold,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            NumberFormatter.formatCredits(state.credits),
                            style: const TextStyle(
                              color: GameTheme.neonGold,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (estimatedIncomePerSecond > 0)
                            Text(
                              '+${NumberFormatter.formatCredits(estimatedIncomePerSecond)}/s',
                              style: const TextStyle(
                                color: Color(0xFF00FF88),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 2. Dark Matter Pill (Hard Currency)
          Expanded(
            flex: 4,
            child: Container(
              key: _darkMatterCounterGlobalKey,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    GameTheme.neonPurple.withAlpha(45),
                    const Color(0xFF190C28),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GameTheme.neonPurple.withAlpha(100),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: GameTheme.neonPurple.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.diamond_rounded,
                      color: GameTheme.neonPurple,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          NumberFormatter.formatDarkMatter(state.darkMatter),
                          style: const TextStyle(
                            color: GameTheme.neonPurple,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'DARK MATTER',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 7.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 3. VIP / Membership Plans Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _openGameModal((ctx) => const MembershipPlansModal());
              },
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: state.hasRemovedAds
                        ? [
                            const Color(0xFF00FF88).withAlpha(50),
                            const Color(0xFF004D28),
                          ]
                        : [
                            const Color(0xFFFFD700).withAlpha(55),
                            const Color(0xFF4A3800),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.hasRemovedAds
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFFD700),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (state.hasRemovedAds
                              ? const Color(0xFF00FF88)
                              : const Color(0xFFFFD700))
                          .withAlpha(40),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.hasRemovedAds
                          ? Icons.verified_rounded
                          : Icons.workspace_premium_rounded,
                      color: state.hasRemovedAds
                          ? const Color(0xFF00FF88)
                          : const Color(0xFFFFD700),
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.hasRemovedAds ? 'VIP' : 'PLANS',
                      style: TextStyle(
                        color: state.hasRemovedAds
                            ? const Color(0xFF00FF88)
                            : const Color(0xFFFFD700),
                        fontSize: 10.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 4. Settings Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _openGameModal((ctx) => const SettingsModal());
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withAlpha(40),
                    width: 1.0,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.settings_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartContextualObjectiveTicker(GameState gameState) {
    // Priority 1: Combat Alert if an Alien Boss Incursion is active
    if (gameState.activeBoss != null && !gameState.activeBoss!.isDead) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: _buildBossSiegeHUD(gameState),
      );
    }

    // Priority 2: Cadet Onboarding Tutorial (Steps 0-4)
    if (gameState.tutorialStep < 5 && gameState.highestTierUnlocked <= 1) {
      return _buildCommanderLearningQuestHud(gameState);
    }

    // Priority 3: Active Commander Learning Quest / Milestone
    final activeQuest = UserGrowthService.getActiveMilestone(gameState);
    if (activeQuest != null) {
      return _buildCommanderLearningQuestHud(gameState);
    }

    // Priority 4: Standard Career Mission fallback
    return _buildActiveMissionBar(gameState);
  }

  Widget _buildCommanderLearningQuestHud(GameState gameState) {

    // 1. Initial Cadet Steps (0, 1, 2, 3, 4)
    if (gameState.tutorialStep < 5) {
      String title;
      String instruction;
      IconData icon;
      Color color;

      switch (gameState.tutorialStep) {
        case 0:
          title = 'STEP 1/5: LAUNCH YOUR SHIP! 🚀';
          instruction =
              'Drag your spaceship up onto the track to start making coins! 💰';
          icon = Icons.flight_takeoff_rounded;
          color = const Color(0xFF00F0FF);
          break;
        case 1:
          title = 'STEP 2/5: TURBO TAP SPEED! ⚡';
          instruction =
              'Tap the racetrack 3 times fast to boost your speed and earn rapid coins!';
          icon = Icons.bolt_rounded;
          color = const Color(0xFFFF0055);
          break;
        case 2:
          title = 'STEP 3/5: BUY SECOND SHIP! 🛸';
          instruction =
              'You earned coins! Tap [BUY SHIP] below to add another spaceship!';
          icon = Icons.shopping_cart_rounded;
          color = const Color(0xFFFFD700);
          break;
        case 3:
          title = 'STEP 4/5: SMASH TO MERGE! 💥';
          instruction =
              'Drag matching Level 1 ships together to create a Level 2 ship! 🚀+🚀=🛸';
          icon = Icons.auto_awesome_rounded;
          color = const Color(0xFFBD00FF);
          break;
        case 4:
        default:
          title = 'STEP 5/5: CIRCUIT LASER GATES! 🏁';
          instruction =
              'Tap [SPEED] or [LASER GATE] to double your circuit earnings forever!';
          icon = Icons.speed_rounded;
          color = const Color(0xFF00FF88);
          break;
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: color.withAlpha((0.15 * 255).round()),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    instruction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white38, size: 13),
              onPressed: () {
                ref.read(gameStateProvider.notifier).advanceTutorialStep(5);
              },
            ),
          ],
        ),
      );
    }

    // 2. Progressive 7-Stage Commander Learning Arc
    final rank =
        UserGrowthService.getCommanderRank(gameState.highestTierUnlocked);
    final activeQuest = UserGrowthService.getActiveMilestone(gameState);

    if (activeQuest == null) {
      // All 7 milestones achieved!
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
        decoration: BoxDecoration(
          color: rank.color.withAlpha((0.12 * 255).round()),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: rank.color.withAlpha((0.35 * 255).round())),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(rank.icon, color: rank.color, size: 12),
            const SizedBox(width: 5),
            Text(
              'COMMANDER RANK ${rank.rank}: ${rank.title.toUpperCase()} • 100% LEARNING ARCH COMPLETED',
              style: TextStyle(
                color: rank.color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    final bool isCompleted = activeQuest.checkCompleted(gameState);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFFFFD700).withAlpha((0.18 * 255).round())
            : const Color(0xFF0F172A).withAlpha((0.85 * 255).round()),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFFFD700)
              : rank.color.withAlpha((0.45 * 255).round()),
          width: isCompleted ? 1.4 : 0.9,
        ),
        boxShadow: isCompleted
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700)
                      .withAlpha((0.3 * 255).round()),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank Badge Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 2),
            decoration: BoxDecoration(
              color: rank.color.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: rank.color, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(activeQuest.icon, color: rank.color, size: 10),
                const SizedBox(width: 3),
                Text(
                  'R${rank.rank}',
                  style: TextStyle(
                    color: rank.color,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),

          // Quest Objective
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'OBJECTIVE: ${activeQuest.title.toUpperCase()}',
                  style: TextStyle(
                    color: isCompleted
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF00F0FF),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  activeQuest.objective,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Claim / Reward Badge
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              if (isCompleted) {
                final claimed = ref
                    .read(gameStateProvider.notifier)
                    .claimLearningMilestone(activeQuest.id);
                if (claimed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF131B3A),
                      content: Text(
                        '🌟 Milestone Completed! Earned +${activeQuest.rewardDarkMatter.toInt()} Dark Matter & +${NumberFormatter.formatCredits(activeQuest.rewardCredits)} Credits!',
                        style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.bold),
                      ),
                      duration: const Duration(milliseconds: 1400),
                    ),
                  );
                }
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFFFFD700)
                    : Colors.white.withAlpha((0.08 * 255).round()),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFFFFD700)
                      : Colors.white24,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted
                        ? Icons.card_giftcard_rounded
                        : Icons.auto_awesome_rounded,
                    color: isCompleted
                        ? Colors.black
                        : const Color(0xFFBD00FF),
                    size: 11,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isCompleted
                        ? 'CLAIM +${activeQuest.rewardDarkMatter.toInt()} DM'
                        : '+${activeQuest.rewardDarkMatter.toInt()} DM',
                    style: TextStyle(
                      color: isCompleted ? Colors.black : Colors.white70,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCircuitEngineeringStrip(GameState gameState) {
    final bool isSpeedMaxed = gameState.isFleetSpeedMaxed;
    final bool canAffordSpeed = !isSpeedMaxed &&
        gameState.credits >= gameState.fleetSpeedUpgradeCost;
    final bool isPadsUnlocked = UserGrowthService.isFeatureUnlocked(
        GameFeature.hyperPads,
        highestTier: gameState.highestTierUnlocked);
    final bool canAffordBoostPad = isPadsUnlocked &&
        gameState.boostPadLevel < 10 &&
        gameState.credits >= gameState.boostPadUpgradeCost;

    final bool isGatesUnlocked = UserGrowthService.isFeatureUnlocked(
        GameFeature.multiLaserGates,
        highestTier: gameState.highestTierUnlocked);
    final double? nextGateCost = gameState.nextFinishLineCost;
    final bool canAffordGate = isGatesUnlocked &&
        nextGateCost != null &&
        gameState.credits >= nextGateCost;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 0.9),
      ),
      child: Row(
        children: [
          // 1. Fleet Engine Speed Upgrade Button (Tier 1)
          Expanded(
            child: InkWell(
              key: _fleetSpeedGlobalKey,
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (isSpeedMaxed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF1E293B),
                      content: Text(
                        '⚡ Fleet Engine Speed is at MAX Level (Lv. 30)!',
                        style: TextStyle(color: Color(0xFFFFD700)),
                      ),
                      duration: Duration(milliseconds: 900),
                    ),
                  );
                  return;
                }
                final success =
                    ref.read(gameStateProvider.notifier).upgradeFleetSpeed();
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1E293B),
                      content: Text(
                        '⚡ Need ${NumberFormatter.formatCredits(gameState.fleetSpeedUpgradeCost)} credits to upgrade Fleet Engine Speed!',
                        style: const TextStyle(color: Color(0xFFFFD700)),
                      ),
                      duration: const Duration(milliseconds: 900),
                    ),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isSpeedMaxed
                      ? const Color(0xFFFFD700).withAlpha((0.15 * 255).round())
                      : (canAffordSpeed
                          ? const Color(0xFF00F0FF).withAlpha((0.15 * 255).round())
                          : Colors.white.withAlpha((0.04 * 255).round())),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSpeedMaxed
                        ? const Color(0xFFFFD700)
                        : (canAffordSpeed
                            ? const Color(0xFF00F0FF)
                            : Colors.white12),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.speed_rounded,
                        color: isSpeedMaxed
                            ? const Color(0xFFFFD700)
                            : (canAffordSpeed
                                ? const Color(0xFF00F0FF)
                                : Colors.white38),
                        size: 12),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSpeedMaxed
                                ? 'SPEED MAX'
                                : 'SPEED Lv.${gameState.fleetSpeedLevel}',
                            style: TextStyle(
                              color: isSpeedMaxed
                                  ? const Color(0xFFFFD700)
                                  : (canAffordSpeed
                                      ? const Color(0xFF00F0FF)
                                      : Colors.white60),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isSpeedMaxed
                                ? 'MAX LEVEL'
                                : NumberFormatter.formatCredits(
                                    gameState.fleetSpeedUpgradeCost),
                            style: TextStyle(
                              color: isSpeedMaxed
                                  ? const Color(0xFFFFD700)
                                  : (canAffordSpeed
                                      ? const Color(0xFFFFD700)
                                      : Colors.white38),
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 5),

          // 2. Hyper-Pads Boost Multiplier Upgrade Button (Tier 3)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (!isPadsUnlocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF131B3A),
                      content: Text(
                        '🔒 Hyper-Pads unlock at Ship Tier ${UserGrowthService.getRequiredTier(GameFeature.hyperPads)}!',
                        style: const TextStyle(color: Color(0xFFFFB703)),
                      ),
                      duration: const Duration(milliseconds: 900),
                    ),
                  );
                  return;
                }

                if (gameState.boostPadLevel >= 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF131B3A),
                      content: Text(
                        '🚀 On-track Hyper-Pads are already at Maximum Level (10/10)!',
                        style: TextStyle(color: Color(0xFF00FF88)),
                      ),
                      duration: Duration(milliseconds: 900),
                    ),
                  );
                  return;
                }

                final success =
                    ref.read(gameStateProvider.notifier).upgradeBoostPad();
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1E293B),
                      content: Text(
                        '🚀 Need ${NumberFormatter.formatCredits(gameState.boostPadUpgradeCost)} credits to upgrade Hyper-Pads to Lv.${gameState.boostPadLevel + 1}!',
                        style: const TextStyle(color: Color(0xFFFFD700)),
                      ),
                      duration: const Duration(milliseconds: 900),
                    ),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                decoration: BoxDecoration(
                  color: !isPadsUnlocked
                      ? Colors.white.withAlpha((0.02 * 255).round())
                      : (gameState.boostPadLevel >= 10
                          ? const Color(0xFF00FF88)
                              .withAlpha((0.15 * 255).round())
                          : (canAffordBoostPad
                              ? const Color(0xFF9D4EDD)
                                  .withAlpha((0.20 * 255).round())
                              : Colors.white
                                  .withAlpha((0.04 * 255).round()))),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: !isPadsUnlocked
                        ? Colors.white12
                        : (gameState.boostPadLevel >= 10
                            ? const Color(0xFF00FF88)
                            : (canAffordBoostPad
                                ? const Color(0xFF9D4EDD)
                                : Colors.white12)),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        !isPadsUnlocked
                            ? Icons.lock_outline_rounded
                            : Icons.rocket_launch_rounded,
                        color: !isPadsUnlocked
                            ? Colors.white24
                            : (gameState.boostPadLevel >= 10
                                ? const Color(0xFF00FF88)
                                : (canAffordBoostPad
                                    ? const Color(0xFF9D4EDD)
                                    : Colors.white38)),
                        size: 12),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !isPadsUnlocked
                                ? 'PADS [T3]'
                                : 'PADS Lv.${gameState.boostPadLevel}',
                            style: TextStyle(
                              color: !isPadsUnlocked
                                  ? Colors.white38
                                  : (gameState.boostPadLevel >= 10
                                      ? const Color(0xFF00FF88)
                                      : (canAffordBoostPad
                                          ? const Color(0xFF9D4EDD)
                                          : Colors.white60)),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            !isPadsUnlocked
                                ? 'RANK 3'
                                : (gameState.boostPadLevel >= 10
                                    ? 'MAX'
                                    : NumberFormatter.formatCredits(
                                        gameState.boostPadUpgradeCost)),
                            style: TextStyle(
                              color: !isPadsUnlocked
                                  ? Colors.white24
                                  : (gameState.boostPadLevel >= 10
                                      ? const Color(0xFF00FF88)
                                      : (canAffordBoostPad
                                          ? Colors.white
                                          : Colors.white38)),
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 5),

          // 3. Multi-Laser Finish Line Gates / Track Evolution Button (Tier 2 / Tier 4)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (!isGatesUnlocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF131B3A),
                      content: Text(
                        '🔒 Multi-Laser Gates unlock at Commander Rank 2 (Ship Tier 2)!',
                        style: TextStyle(color: Color(0xFF06D6A0)),
                      ),
                      duration: Duration(milliseconds: 900),
                    ),
                  );
                  return;
                }

                if (gameState.finishLinesCount >= 4) {
                  // Track Evolution Trigger
                  final bool isEvolveUnlocked = UserGrowthService.isFeatureUnlocked(
                      GameFeature.trackEvolution,
                      highestTier: gameState.highestTierUnlocked);

                  if (!isEvolveUnlocked) {
                    final reqTier = UserGrowthService.getRequiredTier(GameFeature.trackEvolution);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF131B3A),
                        content: Text(
                          '🔒 Track Circuit Evolution unlocks at Spacecraft Tier $reqTier!',
                          style: const TextStyle(color: Color(0xFFBD00FF)),
                        ),
                        duration: const Duration(milliseconds: 900),
                      ),
                    );
                    return;
                  }

                  final bool canEvolve =
                      gameState.credits >= gameState.trackEvolutionCost;
                  if (canEvolve) {
                    final int nextTier = gameState.circuitTier + 1;
                    final nextMultiplier = (nextTier == 2
                        ? 1.5
                        : (nextTier == 3
                            ? 2.5
                            : (nextTier == 4 ? 5.0 : 10.0)));
                    final nextName = nextTier == 2
                        ? 'Hyper-Elliptical Superhighway'
                        : (nextTier == 3
                            ? 'Infinity Singularity Ring'
                            : (nextTier == 4
                                ? 'Quantum Pulsar Tri-Loop'
                                : 'Omega Cosmic Hyper-Loop'));

                    final success = ref
                        .read(gameStateProvider.notifier)
                        .evolveTrackCircuit();
                    if (success) {
                      TrackAscensionModal.show(
                        context,
                        newTier: nextTier,
                        tierName: nextName,
                        incomeMultiplier: nextMultiplier,
                        onContinue: () {},
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1E293B),
                        content: Text(
                          '🌟 Need ${NumberFormatter.formatCredits(gameState.trackEvolutionCost)} credits to evolve Track to Tier ${gameState.circuitTier + 1}!',
                          style: const TextStyle(color: Color(0xFFFFD700)),
                        ),
                        duration: const Duration(milliseconds: 1000),
                      ),
                    );
                  }
                  return;
                }

                final success = ref
                    .read(gameStateProvider.notifier)
                    .unlockNextFinishLine();
                if (!success && nextGateCost != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1E293B),
                      content: Text(
                        '🏁 Need ${NumberFormatter.formatCredits(nextGateCost)} credits to unlock Laser Gate #${gameState.finishLinesCount + 1}!',
                        style: const TextStyle(color: Color(0xFFFFD700)),
                      ),
                      duration: const Duration(milliseconds: 900),
                    ),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                decoration: BoxDecoration(
                  color: !isGatesUnlocked
                      ? Colors.white.withAlpha((0.02 * 255).round())
                      : (gameState.finishLinesCount >= 4
                          ? (gameState.credits >=
                                  gameState.trackEvolutionCost
                              ? const Color(0xFFFFD700)
                                  .withAlpha((0.25 * 255).round())
                              : const Color(0xFF00FF88)
                                  .withAlpha((0.15 * 255).round()))
                          : (canAffordGate
                              ? const Color(0xFFFFD700)
                                  .withAlpha((0.18 * 255).round())
                              : Colors.white
                                  .withAlpha((0.04 * 255).round()))),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: !isGatesUnlocked
                        ? Colors.white12
                        : (gameState.finishLinesCount >= 4
                            ? (gameState.credits >=
                                    gameState.trackEvolutionCost
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF00FF88))
                            : (canAffordGate
                                ? const Color(0xFFFFD700)
                                : Colors.white12)),
                    width: gameState.finishLinesCount >= 4 &&
                            gameState.credits >=
                                gameState.trackEvolutionCost
                        ? 1.5
                        : 0.9,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      !isGatesUnlocked
                          ? Icons.lock_outline_rounded
                          : (gameState.finishLinesCount >= 4
                              ? Icons.auto_awesome_rounded
                              : Icons.flag_rounded),
                      color: !isGatesUnlocked
                          ? Colors.white24
                          : (gameState.finishLinesCount >= 4
                              ? const Color(0xFFFFD700)
                              : (canAffordGate
                                  ? const Color(0xFFFFD700)
                                  : Colors.white38)),
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !isGatesUnlocked
                                ? 'GATES [T2]'
                                : (gameState.finishLinesCount >= 4
                                    ? 'EVOLVE T${gameState.circuitTier + 1}'
                                    : 'GATES ${gameState.finishLinesCount}/4'),
                            style: TextStyle(
                              color: !isGatesUnlocked
                                  ? Colors.white38
                                  : (gameState.finishLinesCount >= 4
                                      ? const Color(0xFFFFD700)
                                      : (canAffordGate
                                          ? const Color(0xFFFFD700)
                                          : Colors.white60)),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            !isGatesUnlocked
                                ? 'RANK 2'
                                : (gameState.finishLinesCount >= 4
                                    ? NumberFormatter.formatCredits(
                                        gameState.trackEvolutionCost)
                                    : (nextGateCost != null
                                        ? NumberFormatter.formatCredits(
                                            nextGateCost)
                                        : 'MAX')),
                            style: TextStyle(
                              color: !isGatesUnlocked
                                  ? Colors.white24
                                  : (gameState.finishLinesCount >= 4
                                      ? (gameState.credits >=
                                              gameState.trackEvolutionCost
                                          ? const Color(0xFFFFD700)
                                          : Colors.white60)
                                      : (canAffordGate
                                          ? const Color(0xFFFFD700)
                                          : Colors.white38)),
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMissionBar(GameState state) {




    final unclaimedMissions =
        state.career.missions.where((m) => !m.isClaimed).toList();
    final bool allDone = unclaimedMissions.isEmpty;
    final activeMission = !allDone ? unclaimedMissions.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ...previousChildren,
              ?currentChild,
            ],

          );
        },
        transitionBuilder: (child, animation) {
          final bool isCurrent =
              child.key == ValueKey(activeMission?.id ?? 'all_completed');
          final inTween = Tween<Offset>(
            begin: isCurrent ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
            end: Offset.zero,
          );

          return SlideTransition(
            position: inTween.animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },

        child: allDone
            ? Container(
                key: const ValueKey('all_completed'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: GameTheme.neonPurple.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: GameTheme.neonPurple.withAlpha((0.5 * 255).round()),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: GameTheme.neonPurple,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'ALL DIRECTIVES COMPLETED • PRESTIGE FOR NEW SECTORS',
                        style: TextStyle(
                          color: GameTheme.neonPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                key: ValueKey(activeMission!.id),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GameTheme.backgroundSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: activeMission.isCompleted
                        ? GameTheme.neonGreen.withAlpha((0.6 * 255).round())
                        : GameTheme.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      activeMission.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radar_rounded,
                      color: activeMission.isCompleted
                          ? GameTheme.neonGreen
                          : GameTheme.neonCyan,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activeMission.title,
                                  style: const TextStyle(
                                    color: GameTheme.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${activeMission.currentProgress.toInt()}/${activeMission.targetValue.toInt()}',
                                style: TextStyle(
                                  color: activeMission.isCompleted
                                      ? GameTheme.neonGreen
                                      : GameTheme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 3),
                          LinearProgressIndicator(
                            value: activeMission.progressRatio,
                            backgroundColor: GameTheme.backgroundVoid,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              activeMission.isCompleted
                                  ? GameTheme.neonGreen
                                  : GameTheme.neonCyan,
                            ),
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    ),
                    if (activeMission.isCompleted &&
                        !activeMission.isClaimed) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GameTheme.neonGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () {
                            ref
                                .read(gameStateProvider.notifier)
                                .claimMission(activeMission.id);
                          },
                          child: const Text(
                            'CLAIM',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBossSiegeHUD(GameState state) {

    final boss = state.activeBoss;
    if (boss == null || boss.isDead) {
      return _buildWarpMeterBar(state);
    }

    final double hpPercent = boss.healthPercentage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.85 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF0055),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFFF0055),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF0055),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '⚠️ ${boss.name.toUpperCase()} SIEGE',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '⏱️ ${boss.timeRemaining.toStringAsFixed(1)}s  |  HP: ${(hpPercent * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFFFF0055),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: hpPercent,
              minHeight: 4,
              backgroundColor: Colors.white10,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFF0055)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarpMeterBar(GameState state) {
    final bool isFever = state.isFeverActive;
    final double progress = isFever
        ? (state.feverTimeRemaining / 10.0).clamp(0.0, 1.0)
        : state.feverCharge.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.75 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFever
              ? const Color(0xFFFFD700)
              : GameTheme.neonCyan.withAlpha((0.5 * 255).round()),
          width: isFever ? 1.5 : 1.0,
        ),
        boxShadow: isFever
            ? [
                const BoxShadow(
                  color: Color(0xFFFF0055),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isFever
                          ? Icons.local_fire_department_rounded
                          : Icons.bolt_rounded,
                      color: isFever
                          ? const Color(0xFFFF0055)
                          : GameTheme.neonCyan,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isFever
                            ? '🔥 HYPERSPACE WARP: 3.5X SPEED & 3X CRITS!'
                            : 'TAP CIRCUIT TO CHARGE WARP RUSH',
                        style: TextStyle(
                          color: isFever
                              ? const Color(0xFFFFD700)
                              : Colors.white70,
                          fontSize: 8.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isFever
                      ? '${state.feverTimeRemaining.toStringAsFixed(1)}s'
                      : '${(state.feverCharge * 100).toInt()}%',
                  style: TextStyle(
                    color: isFever
                        ? const Color(0xFFFF0055)
                        : GameTheme.neonCyan,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3.5,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFever ? const Color(0xFFFF0055) : GameTheme.neonCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergeGrid(GameState state) {
    final int maxUnlocked =
        ref.watch(gameStateProvider.notifier).maxUnlockedGridSlots;

    return Stack(
      children: [
        Container(
          decoration: GameTheme.glassCard(
            borderColor: GameTheme.cardBorder,
            radius: 16,
          ),
          padding: const EdgeInsets.all(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double availableW = constraints.maxWidth;
              final double availableH = constraints.maxHeight;
              final double cellW = (availableW - (3 * 6)) / 4;
              final double cellH = (availableH - (3 * 6)) / 4;
              final double aspectRatio =
                  (cellW > 0 && cellH > 0) ? (cellW / cellH) : 1.0;

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 16,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) {
                  final bool isLocked = index >= maxUnlocked;
                  final ShipModel? ship =
                      isLocked ? null : state.gridSlots[index];


              if (isLocked) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0.35 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white10,
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white24,
                            size: 13,
                          ),
                          SizedBox(height: 1),
                          Text(
                            'TECH',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

              }

              return DragTarget<int>(
                onWillAcceptWithDetails: (details) =>
                    !isLocked && details.data != index,
                onAcceptWithDetails: (details) {
                  final int fromIndex = details.data;
                  final fromShip = state.gridSlots[fromIndex];
                  final targetShip = state.gridSlots[index];
                  final bool isMerge = fromShip != null &&
                      targetShip != null &&
                      !fromShip.isBox &&
                      !targetShip.isBox &&
                      fromShip.tier == targetShip.tier;

                  ref
                      .read(gameStateProvider.notifier)
                      .handleGridMergeOrMove(fromIndex, index);

                  if (isMerge) {
                    final ro = context.findRenderObject();
                    final dropPos = (ro is RenderBox && ro.hasSize)
                        ? ro.localToGlobal(ro.size.center(Offset.zero))
                        : details.offset;

                    // 1. Expanding Radial Neon Shockwave Ring
                    _vfxController.spawnShockwave(
                      origin: dropPos,
                      color: targetShip.glowColor,
                      maxRadius: 55.0,
                    );

                    // 2. Floating Arcade Text
                    _vfxController.spawnFloatingText(
                      origin: dropPos,
                      text: 'TIER ${fromShip.tier + 1}! 🚀',
                      color: const Color(0xFF00FF88),
                      fontSize: 14.5,
                    );

                    // 3. Spray of Flying Coins toward Wallet
                    _vfxController.spawnCoins(
                      origin: dropPos,
                      targetKey: _coinCounterGlobalKey,
                      count: 6,
                      onTargetHit: _triggerCoinWalletBounce,
                    );
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  final bool isHovered = candidateData.isNotEmpty;
                  final bool isMatchingTarget = _draggingShipTier != null &&
                      ship != null &&
                      !ship.isBox &&
                      ship.tier == _draggingShipTier &&
                      index != _draggingFromSlotIndex;

                  return Container(
                    key: index == 0
                        ? _slot0GlobalKey
                        : (index == 1 ? _slot1GlobalKey : null),
                    decoration: BoxDecoration(
                      color: isHovered
                          ? const Color(0xFF00FF88).withAlpha((0.35 * 255).round())
                          : (isMatchingTarget
                              ? const Color(0xFF00FF88).withAlpha((0.22 * 255).round())
                              : GameTheme.cardSurface),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (isHovered || isMatchingTarget)
                            ? const Color(0xFF00FF88)
                            : (ship != null
                                ? ship.glowColor.withAlpha((0.4 * 255).round())
                                : GameTheme.cardBorder),
                        width: (isHovered || isMatchingTarget) ? 2.2 : 1.0,
                      ),
                      boxShadow: (isHovered || isMatchingTarget)
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00FF88)
                                    .withAlpha((0.6 * 255).round()),
                                blurRadius: 12,
                                spreadRadius: 1.5,
                              )
                            ]
                          : (ship != null
                              ? [
                                  BoxShadow(
                                    color: ship.glowColor
                                        .withAlpha((0.15 * 255).round()),
                                    blurRadius: 4,
                                  )
                                ]
                              : null),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (ship != null)
                          (ship.isBox
                              ? GestureDetector(
                                  onTap: () {
                                    AdManager().showRewardedAd(
                                      onUserEarnedReward: () {
                                        ref
                                            .read(gameStateProvider.notifier)
                                            .openCrate(index);
                                      },
                                    );
                                  },
                                  child: _buildCrateTileContent(),
                                )
                              : Draggable<int>(
                                  data: index,
                                  onDragStarted: () {
                                    setState(() {
                                      _draggingShipTier = ship.tier;
                                      _draggingFromSlotIndex = index;
                                    });
                                  },
                                  onDragEnd: (_) {
                                    setState(() {
                                      _draggingShipTier = null;
                                      _draggingFromSlotIndex = null;
                                    });
                                  },
                                  onDraggableCanceled: (velocity, offset) {
                                    setState(() {
                                      _draggingShipTier = null;
                                      _draggingFromSlotIndex = null;
                                    });
                                  },
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: _buildShipTileContent(ship,
                                        isDragging: true),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.25,
                                    child: _buildShipTileContent(ship),
                                  ),
                                  child: _buildShipTileContent(ship),
                                ))
                        else
                          const Center(
                            child: Icon(
                              Icons.add,
                              color: Color(0xFF334155),
                              size: 14,
                            ),
                          ),

                        // Animated "MERGE! ⬆️" Badge over matching target slots
                        if (isMatchingTarget)
                          Positioned(
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00FF88),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00FF88)
                                        .withAlpha(180),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'MERGE! ⬆️',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    ),
  ],
);

}



  Widget _buildShipTileContent(ShipModel ship, {bool isDragging = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDim = isDragging
            ? 58.0
            : min(constraints.maxWidth, constraints.maxHeight);
        final double iconSize = max(20.0, maxDim - 6.0);

        return Center(
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow Backing
                Container(
                  width: iconSize * 0.7,
                  height: iconSize * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ship.glowColor.withAlpha((0.18 * 255).round()),
                    boxShadow: [
                      BoxShadow(
                        color: ship.glowColor.withAlpha((0.35 * 255).round()),
                        blurRadius: 6,
                      )
                    ],
                  ),
                ),

                // Kenney Sprite Image
                Image.asset(
                  ship.spriteAsset,
                  width: iconSize * 0.85,
                  height: iconSize * 0.85,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.rocket_launch_rounded,
                    color: ship.glowColor,
                    size: iconSize * 0.5,
                  ),
                ),

                // Tier Badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF070913),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: ship.glowColor, width: 0.8),
                    ),
                    child: Text(
                      'T${ship.tier}',
                      style: TextStyle(
                        color: ship.glowColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCrateTileContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDim = min(constraints.maxWidth, constraints.maxHeight);
        final double iconSize = max(20.0, maxDim - 6.0);

        return Center(
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Gold Aura
                Container(
                  width: iconSize * 0.8,
                  height: iconSize * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD700)
                        .withAlpha((0.25 * 255).round()),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF0055)
                            .withAlpha((0.45 * 255).round()),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),

                // Crate Icon
                Icon(
                  Icons.card_giftcard_rounded,
                  color: const Color(0xFFFFD700),
                  size: iconSize * 0.65,
                ),

                // "▶ AD GIFT" Badge
                Positioned(
                  bottom: -1,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB800).withAlpha(160),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 9,
                        ),
                        SizedBox(width: 1),
                        Text(
                          'AD GIFT',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 6.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  int _getHubBadgeCount(GameState state) {
    final int tier = state.highestTierUnlocked;
    int count = 0;
    count += state.career.missions.where((m) => m.isCompleted && !m.isClaimed).length;
    if (UserGrowthService.isFeatureUnlocked(GameFeature.expeditions, highestTier: tier)) {
      count += state.readyExpeditionsCount;
    }
    if (UserGrowthService.isFeatureUnlocked(GameFeature.achievements, highestTier: tier)) {
      count += state.unclaimedAchievementsCount;
    }
    if (UserGrowthService.isFeatureUnlocked(GameFeature.dailyCalendar, highestTier: tier) && state.canClaimDailyReward) {
      count++;
    }
    if (UserGrowthService.isFeatureUnlocked(GameFeature.roulette, highestTier: tier) && state.canSpinFree) {
      count++;
    }
    if (UserGrowthService.isFeatureUnlocked(GameFeature.bossBeacon, highestTier: tier) && state.activeBoss != null && !state.activeBoss!.isDead) {
      count++;
    }
    return count;
  }

  Widget _buildStreamlinedCommandDock({
    required GameState gameState,
    required AdBoostState adState,
    required bool canAffordShip,
    required double nextBuyCost,
    required int dropTier,
  }) {
    final hubBadgeCount = _getHubBadgeCount(gameState);
    final rank = UserGrowthService.getCommanderRank(gameState.highestTierUnlocked);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF070B16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank.color.withAlpha((0.35 * 255).round()),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.5 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. DragTarget Scrap / Recycle Bin
          DragTarget<int>(
            onWillAcceptWithDetails: (details) {
              final int slotIndex = details.data;
              final ship = gameState.gridSlots[slotIndex];
              return ship != null && !ship.isBox;
            },
            onAcceptWithDetails: (details) {
              final refund = ref
                  .read(gameStateProvider.notifier)
                  .recycleShip(details.data);
              if (refund == -1.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFFFF0055),
                    content: Text(
                      '😄 Hold on! Keep at least 1 spaceship so you can keep racing!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (refund > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1E293B),
                    content: Text(
                      '♻️ Sold spaceship for +${NumberFormatter.formatCredits(refund)} coins! 💰',
                      style: const TextStyle(
                        color: Color(0xFF00F5FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;
              return Container(
                width: 38,
                height: 44,
                decoration: BoxDecoration(
                  color: isHovered
                      ? const Color(0xFFFF0055).withAlpha((0.35 * 255).round())
                      : Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isHovered
                        ? const Color(0xFFFF0055)
                        : Colors.white24,
                    width: isHovered ? 1.8 : 0.9,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_sweep_rounded,
                      color: isHovered
                          ? const Color(0xFFFF0055)
                          : Colors.white60,
                      size: 16,
                    ),
                    Text(
                      'SELL',
                      style: TextStyle(
                        color: isHovered
                            ? const Color(0xFFFF0055)
                            : Colors.white54,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 5),

          // 2. Auto-Merge & Sort Quick Buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniDockButton(
                icon: Icons.auto_awesome_rounded,
                label: 'AUTO',
                color: const Color(0xFFFFD700),
                isUnlocked: UserGrowthService.isFeatureUnlocked(
                  GameFeature.autoMerge,
                  highestTier: gameState.highestTierUnlocked,
                ),
                requiredTier: UserGrowthService.getRequiredTier(GameFeature.autoMerge),
                onTap: () {
                  if (!gameState.hasRemovedAds) {
                    _showAutoMergePremiumDialog(context);
                    return;
                  }
                  final count = ref.read(gameStateProvider.notifier).autoMergeGrid();
                  if (count == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF1E293B),
                        content: Text('No matching spaceship pairs to merge right now!'),
                        duration: Duration(milliseconds: 700),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 3),
              _buildMiniDockButton(
                key: _sortButtonGlobalKey,
                icon: Icons.sort_rounded,
                label: 'SORT',
                color: const Color(0xFF00F0FF),
                isUnlocked: UserGrowthService.isFeatureUnlocked(
                  GameFeature.autoSort,
                  highestTier: gameState.highestTierUnlocked,
                ),
                requiredTier: UserGrowthService.getRequiredTier(GameFeature.autoSort),
                onTap: () {
                  final sorted = ref.read(gameStateProvider.notifier).sortGridSlots();
                  if (sorted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF131B3A),
                        content: Text(
                          '✨ Spaceships neatly organized!',
                          style: TextStyle(
                            color: Color(0xFF00F0FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        duration: Duration(milliseconds: 700),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(width: 6),

          // 3. Center Hero CTA: BUY SHIP (Evolves with Ship Tier & Upgrades)
          Builder(builder: (context) {
            final shipDef = ShipModel.create(dropTier);
            final Color tierColor = canAffordShip ? shipDef.glowColor : Colors.grey.shade800;
            final Color textColor = canAffordShip
                ? (tierColor.computeLuminance() > 0.4 ? Colors.black : Colors.white)
                : Colors.white54;

            return Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  key: _buyShipGlobalKey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tierColor,
                    foregroundColor: textColor,
                    elevation: canAffordShip ? 6 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: canAffordShip
                      ? () {
                          ref.read(gameStateProvider.notifier).purchaseShip();
                        }
                      : null,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          shipDef.spriteAsset,
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BUY T$dropTier • ',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          NumberFormatter.formatCredits(nextBuyCost),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 6),

          // 4. 2X Speed Boost Button (Video Ad Rewarded)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (adState.isSpeedBoostActive) return;
              AdManager().showRewardedAd(
                onUserEarnedReward: () {
                  ref.read(adStateProvider.notifier).activateSpeedBoost();
                },
              );
            },
            child: Container(
              width: 48,
              height: 44,
              decoration: BoxDecoration(
                color: adState.isSpeedBoostActive
                    ? const Color(0xFFFF9900).withAlpha((0.25 * 255).round())
                    : Colors.white.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: adState.isSpeedBoostActive
                      ? const Color(0xFFFF9900)
                      : const Color(0xFFFF9900).withAlpha(120),
                  width: 1.0,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        adState.isSpeedBoostActive
                            ? Icons.bolt_rounded
                            : Icons.smart_display_rounded,
                        color: adState.isSpeedBoostActive
                            ? const Color(0xFFFF9900)
                            : const Color(0xFFFFB703),
                        size: 16,
                      ),
                      Text(
                        adState.isSpeedBoostActive
                            ? NumberFormatter.formatSeconds(
                                adState.speedBoostRemainingSeconds)
                            : '2X SPEED',
                        style: TextStyle(
                          color: adState.isSpeedBoostActive
                              ? const Color(0xFFFF9900)
                              : Colors.white,
                          fontSize: 7.0,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                  if (!adState.isSpeedBoostActive)
                    Positioned(
                      top: -4,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3.5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9900),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9900)
                                  .withAlpha((0.7 * 255).round()),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                color: Colors.black, size: 7),
                            Text(
                              'AD',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 6.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 5. Starfleet Command Hub Button (Menu Bar)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _openGameModal((ctx) => const CommandHubModal());
            },
            child: Container(
              width: 52,
              height: 44,
              decoration: BoxDecoration(
                color: rank.color.withAlpha((0.20 * 255).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: rank.color, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: rank.color.withAlpha((0.35 * 255).round()),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grid_view_rounded, color: rank.color, size: 18),
                      Text(
                        'COMMAND',
                        style: TextStyle(
                          color: rank.color,
                          fontSize: 7.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  if (hubBadgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF0055),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF0055).withAlpha((0.6 * 255).round()),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          '$hubBadgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDockButton({
    GlobalKey? key,
    required IconData icon,
    required String label,
    required Color color,
    required bool isUnlocked,
    required int requiredTier,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(6),
      onTap: isUnlocked
          ? onTap
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF131B3A),
                  content: Text(
                    '🔒 $label unlocks at Tier $requiredTier!',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  duration: const Duration(milliseconds: 700),
                ),
              );
            },
      child: Container(
        width: 42,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isUnlocked ? color.withAlpha((0.20 * 255).round()) : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isUnlocked ? color.withAlpha((0.5 * 255).round()) : Colors.white12,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnlocked ? icon : Icons.lock_outline_rounded,
              color: isUnlocked ? color : Colors.white38,
              size: 9,
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                color: isUnlocked ? color : Colors.white38,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoMergePremiumDialog(BuildContext context) {
    final priceText = LocalizedPricingService.removeAdsPriceString;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: GameTheme.cardSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFD700), width: 1.6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withAlpha((0.35 * 255).round()),
                blurRadius: 24,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withAlpha((0.2 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFFFFD700), size: 28),
              ),
              const SizedBox(height: 12),
              const Text(
                'FLEET AUTO-MERGE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Auto-Merge is a VIP Commander perk! Upgrade to VIP for unlimited 1-tap auto-merging, or watch a quick transmission ad for 1 instant auto-merge.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: Text(
                    'UPGRADE TO VIP ($priceText)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                      letterSpacing: 0.4,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _openGameModal((_) => const MembershipPlansModal());
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00F0FF), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.smart_display_rounded,
                      color: Color(0xFF00F0FF), size: 16),
                  label: const Text(
                    'WATCH AD FOR 1 AUTO-MERGE',
                    style: TextStyle(
                      color: Color(0xFF00F0FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    AdManager().showRewardedAd(
                      onUserEarnedReward: () {
                        final count = ref
                            .read(gameStateProvider.notifier)
                            .autoMergeGrid();
                        if (count > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF131B3A),
                              content: Text(
                                '⚡ Auto-Merged $count matching pairs!',
                                style: const TextStyle(
                                    color: Color(0xFF00FF88),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



