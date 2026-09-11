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
import '../models/sector_theme_model.dart';
import '../providers/game_providers.dart';
import '../services/ad_manager.dart';
import '../services/localized_pricing_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/user_growth_service.dart';
import '../utils/game_theme.dart';
import '../utils/number_formatter.dart';

// Modals
import 'modals/achievements_modal.dart';
import 'modals/command_hub_modal.dart';
import 'modals/cosmic_store_modal.dart';
import 'modals/daily_calendar_modal.dart';
import 'modals/dark_matter_intro_modal.dart';
import 'modals/discovery_modal.dart';
import 'modals/expeditions_modal.dart';
import 'modals/feature_unlocked_modal.dart';
import 'modals/fleet_codex_modal.dart';
import 'modals/membership_plans_modal.dart';
import 'modals/offline_earnings_modal.dart';
import 'modals/relics_modal.dart';
import 'modals/settings_modal.dart';
import 'modals/skill_tree_modal.dart';
import 'modals/track_ascension_modal.dart';
import 'modals/wormhole_roulette_modal.dart';

// Modular Screen Widgets
import 'widgets/bottom_command_dock.dart';
import 'widgets/flight_ops_strip.dart';
import 'widgets/idle_vfx_overlay.dart';
import 'widgets/merge_grid_view.dart';
import 'widgets/objective_mission_ticker.dart';
import 'widgets/streamlined_header_bar.dart';
import 'widgets/tutorial_guide_overlay.dart';

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

    // Periodic Mystery Cosmic Cargo Crate Drops (Every 180 seconds / 3 minutes)
    _cargoDropTimer = Timer.periodic(const Duration(seconds: 180), (_) {
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
            )).then((_) {
          if (!mounted) return;
          if (discoveredTier == 3 &&
              !ref.read(gameStateProvider).hasSeenDarkMatterIntro) {
            _openGameModal((ctx) => DarkMatterIntroModal(
                  onOpenTechTree: () {
                    ref
                        .read(gameStateProvider.notifier)
                        .acknowledgeDarkMatterIntro();
                    _openGameModal((c) => const SkillTreeModal());
                  },
                  onDismiss: () {
                    ref
                        .read(gameStateProvider.notifier)
                        .acknowledgeDarkMatterIntro();
                  },
                )).then((_) {
              if (mounted &&
                  !ref.read(gameStateProvider).hasSeenDarkMatterIntro) {
                ref
                    .read(gameStateProvider.notifier)
                    .acknowledgeDarkMatterIntro();
              }
            });
          }
        });
      }
    };

    // Hook progressive system unlock ceremony
    ref.read(gameStateProvider.notifier).onFeatureUnlocked = (tier, features) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && !_isModalOpen) {
            if (tier == 3 &&
                !ref.read(gameStateProvider).hasSeenDarkMatterIntro) {
              _openGameModal((ctx) => DarkMatterIntroModal(
                    onOpenTechTree: () {
                      ref
                          .read(gameStateProvider.notifier)
                          .acknowledgeDarkMatterIntro();
                      _openGameModal((c) => const SkillTreeModal());
                    },
                    onDismiss: () {
                      ref
                          .read(gameStateProvider.notifier)
                          .acknowledgeDarkMatterIntro();
                    },
                  )).then((_) {
                if (mounted &&
                    !ref.read(gameStateProvider).hasSeenDarkMatterIntro) {
                  ref
                      .read(gameStateProvider.notifier)
                      .acknowledgeDarkMatterIntro();
                }
              });
              return;
            }
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _galacticGame.pauseEngine();
      SoundService().pauseBgm();
      ref.read(gameStateProvider.notifier).stampSaveTimestamp();
    } else if (state == AppLifecycleState.resumed) {
      _galacticGame.resumeEngine();
      SoundService().resumeBgm();

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
                isVip: currentGameState.hasRemovedAds,
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

        // Always stamp timestamp after processing resume so notification pulls don't trigger offline earnings
        if (mounted) {
          ref.read(gameStateProvider.notifier).stampSaveTimestamp();
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
      final currentGameState = ref.read(gameStateProvider);
      AdManager().showSmartInterstitial(
        hasRemovedAds: currentGameState.hasRemovedAds,
        tutorialStep: currentGameState.tutorialStep,
      );
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
        if (gameState.tutorialStep < 5) return;

        if (offlineResult != null && offlineResult.hasSignificantEarnings) {
          bool hasClaimed = false;
          await _openGameModal((ctx) => OfflineEarningsModal(
                result: offlineResult,
                isVip: gameState.hasRemovedAds,
                onClaimRegular: () {
                  hasClaimed = true;
                  ref
                      .read(gameStateProvider.notifier)
                      .claimOfflineEarnings(offlineResult.coinsEarned);
                  _triggerRewardFlyingCoins(count: 10);
                },
                onClaimDoubled: () {
                  hasClaimed = true;
                  ref.read(gameStateProvider.notifier).claimOfflineEarnings(
                        offlineResult.coinsEarned,
                        doubleReward: true,
                      );
                  _triggerRewardFlyingCoins(count: 14);
                },
              ));
          if (!hasClaimed && mounted) {
            ref
                .read(gameStateProvider.notifier)
                .claimOfflineEarnings(offlineResult.coinsEarned);
            _triggerRewardFlyingCoins(count: 8);
          }
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

  int _getHubBadgeCount(GameState state) {
    int count = 0;
    if (state.canClaimDailyReward &&
        UserGrowthService.isFeatureUnlocked(
          GameFeature.dailyCalendar,
          highestTier: state.highestTierUnlocked,
        )) {
      count++;
    }
    if (state.canSpinAny &&
        UserGrowthService.isFeatureUnlocked(
          GameFeature.roulette,
          highestTier: state.highestTierUnlocked,
        )) {
      count++;
    }
    final claimableAchievements = state.achievements
        .where((a) => a.isCompleted && !a.isClaimed)
        .length;
    if (claimableAchievements > 0 &&
        UserGrowthService.isFeatureUnlocked(
          GameFeature.achievements,
          highestTier: state.highestTierUnlocked,
        )) {
      count += claimableAchievements;
    }
    if (state.readyExpeditionsCount > 0 &&
        UserGrowthService.isFeatureUnlocked(
          GameFeature.expeditions,
          highestTier: state.highestTierUnlocked,
        )) {
      count += state.readyExpeditionsCount;
    }
    return count;
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
                  color:
                      const Color(0xFFFFD700).withAlpha((0.2 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFFFFD700), size: 28),
              ),
              const SizedBox(height: 12),
              const Text(
                'FLEET AUTO-MERGE & DRONE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Auto-Merge organizes & combines matching ships instantly! Upgrade to VIP for permanent 1-tap auto-merge, or watch a transmission ad to rent the Auto-Merge Drone for 30 minutes!',
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
                    side:
                        const BorderSide(color: Color(0xFF00F0FF), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.smart_display_rounded,
                      color: Color(0xFF00F0FF), size: 16),
                  label: const Text(
                    'WATCH AD: 30m DRONE + AUTO-MERGE',
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
                        // Grant 30 minutes drone rental & do immediate auto-merge
                        ref
                            .read(gameStateProvider.notifier)
                            .grantTempDroneRental(durationMinutes: 30);
                        final count = ref
                            .read(gameStateProvider.notifier)
                            .autoMergeGrid();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF131B3A),
                            content: Text(
                              '⚡ Auto-Drone activated for 30m! Merged $count matching pairs!',
                              style: const TextStyle(
                                color: Color(0xFF00FF88),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
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

  void _handleDeployShipToTrack(int slotIndex, [Offset? dropOffset]) {
    final gameState = ref.read(gameStateProvider);
    if (slotIndex < 0 || slotIndex >= gameState.gridSlots.length) return;
    final ship = gameState.gridSlots[slotIndex];
    if (ship == null || ship.isBox) return;

    final result =
        ref.read(gameStateProvider.notifier).dispatchShipToTrack(slotIndex);

    final trackBox =
        _trackGlobalKey.currentContext?.findRenderObject() as RenderBox?;
    final trackCenter = (trackBox != null && trackBox.hasSize)
        ? trackBox.localToGlobal(trackBox.size.center(Offset.zero))
        : (dropOffset ?? Offset.zero);

    switch (result) {
      case DispatchResult.successAdded:
        HapticFeedback.heavyImpact();
        SoundService().playPurchaseSound();
        _vfxController.spawnFloatingText(
          origin: trackCenter,
          text: gameState.tutorialStep == 0
              ? '🚀 Starfighter Deployed! +25 💰'
              : '🚀 Starfighter Deployed to Orbit!',
          color: const Color(0xFF00FF88),
        );
        _vfxController.spawnCoins(
          origin: trackCenter,
          targetKey: _coinCounterGlobalKey,
          count: 8,
          color: const Color(0xFFFFD700),
          onTargetHit: _triggerCoinWalletBounce,
        );
        break;

      case DispatchResult.successReplaced:
        HapticFeedback.heavyImpact();
        SoundService().playPurchaseSound();
        _vfxController.spawnFloatingText(
          origin: trackCenter,
          text: '⚡ Orbit Fleet Upgraded to Tier ${ship.tier}!',
          color: const Color(0xFFFFD700),
        );
        _vfxController.spawnCoins(
          origin: trackCenter,
          targetKey: _coinCounterGlobalKey,
          count: 6,
          color: const Color(0xFFFFD700),
          onTargetHit: _triggerCoinWalletBounce,
        );
        break;

      case DispatchResult.alreadyOnTrack:
        HapticFeedback.selectionClick();
        _vfxController.spawnFloatingText(
          origin: trackCenter,
          text: '⚡ Starship is already cruising orbit!',
          color: const Color(0xFF00F0FF),
        );
        break;

      case DispatchResult.fleetFullLowerTier:
        HapticFeedback.mediumImpact();
        _vfxController.spawnFloatingText(
          origin: trackCenter,
          text: '⚠️ Orbit Full (4/4)! Deploy higher tier to upgrade',
          color: const Color(0xFFFF9900),
        );
        break;

      case DispatchResult.invalidShip:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkOfflineEarningsOnStartup(ref);

    // Listen for boss spawn & defeat events
    ref.listen(gameStateProvider, (prev, next) {
      // Boss Incursion Warning Alert
      if (prev != null && prev.activeBoss == null && next.activeBoss != null) {
        final boss = next.activeBoss!;
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E0A1E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFFF0055), width: 1.8),
            ),
            content: Row(
              children: [
                const Text('🚨', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WARNING: ${boss.name.toUpperCase()} HAS SPAWNED!',
                        style: const TextStyle(
                          color: Color(0xFFFF0055),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        'Tap the Dreadnought to strike with your fleet!',
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
      }

      // Boss Defeat Supernova Celebration
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

      // Cadet Graduation (Step 4 -> Step 5)
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

    final int dropTier =
        ref.watch(gameStateProvider.notifier).activeStoreBuyTier;
    final double nextBuyCost =
        ref.watch(gameStateProvider.notifier).nextShipBuyCost;
    final bool canAffordShip = gameState.credits >= nextBuyCost;
    final int maxUnlocked =
        ref.watch(gameStateProvider.notifier).maxUnlockedGridSlots;

    // Sync game simulation parameters
    _galacticGame.updateHighestTier(gameState.highestTierUnlocked);
    _galacticGame.updateFinishLines(gameState.finishLinesCount);
    _galacticGame.updateCircuitTier(gameState.circuitTier);
    _galacticGame.updateBoostPadCount(gameState.boostPadCount);
    _galacticGame.updateBoostPadMultiplier(gameState.boostPadMultiplier);
    _galacticGame.updateSectorTheme(
        SectorThemeModel.getThemeForSector(gameState.highestTierUnlocked));
    _galacticGame.updateShips(gameState.trackShips);
    _galacticGame.syncBoss(gameState.activeBoss);

    final double speedMultiplier = gameState.fleetSpeedMultiplier *
        (adState.isSpeedBoostActive ? 2.0 : 1.0) *
        (gameState.isFeverActive ? 3.0 : 1.0) *
        (gameState.isNitroActive ? 2.0 : 1.0);
    _galacticGame.setSpeedMultiplier(speedMultiplier,
        isFever: gameState.isFeverActive);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF030712), Color(0xFF0B0F19), Color(0xFF030712)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // 1. Top Banner Ad Slot
                  _buildTopBannerSlot(gameState),

                  // 2. Streamlined Currency & Status Header Bar
                  StreamlinedHeaderBar(
                    state: gameState,
                    adState: adState,
                    coinCounterKey: _coinCounterGlobalKey,
                    darkMatterCounterKey: _darkMatterCounterGlobalKey,
                    coinBounceAnimation: _coinBounceAnimation,
                    onOpenMembership: () {
                      _openGameModal((ctx) => const MembershipPlansModal());
                    },
                    onOpenSettings: () {
                      _openGameModal((ctx) => const SettingsModal());
                    },
                    onOpenTechTree: () {
                      _openGameModal((ctx) => const SkillTreeModal());
                    },
                  ),

                  // 3. Contextual Objective / Mission / Boss / Warp Ticker
                  ObjectiveMissionTicker(
                    gameState: gameState,
                    onClaimQuest: (questId) {
                      final quest =
                          UserGrowthService.learningQuests.firstWhere(
                        (m) => m.id == questId,
                      );
                      ref
                          .read(gameStateProvider.notifier)
                          .claimLearningMilestone(questId);
                      _triggerRewardFlyingCoins(
                        count: quest.rewardDarkMatter > 0 ? 12 : 8,
                        isGem: quest.rewardDarkMatter > 0,
                      );
                    },
                    onClaimMission: (missionId) {
                      ref
                          .read(gameStateProvider.notifier)
                          .claimMission(missionId);
                    },
                  ),

                  // 4. Flame Interactive Space Track Canvas with DragTarget
                  Expanded(
                    flex: 9,
                    child: DragTarget<int>(
                      onWillAcceptWithDetails: (details) {
                        final int slotIndex = details.data;
                        if (slotIndex < 0 ||
                            slotIndex >= gameState.gridSlots.length) {
                          return false;
                        }
                        final ship = gameState.gridSlots[slotIndex];
                        return ship != null && !ship.isBox;
                      },
                      onAcceptWithDetails: (details) {
                        _handleDeployShipToTrack(details.data, details.offset);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final bool isHovered = candidateData.isNotEmpty;
                        return Container(
                          key: _trackGlobalKey,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: isHovered
                                ? const Color(0xFF00F0FF)
                                    .withAlpha((0.15 * 255).round())
                                : Colors.black.withAlpha(200),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isHovered
                                  ? const Color(0xFF00FF88)
                                  : (gameState.isFeverActive
                                      ? const Color(0xFFFF0055)
                                      : const Color(0xFF00F0FF).withAlpha(60)),
                              width: isHovered
                                  ? 2.5
                                  : (gameState.isFeverActive ? 1.8 : 1.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isHovered
                                    ? const Color(0xFF00FF88)
                                        .withAlpha((0.55 * 255).round())
                                    : (gameState.isFeverActive
                                        ? const Color(0xFFFF0055).withAlpha(
                                            (0.35 * 255).round())
                                        : const Color(0xFF00F0FF).withAlpha(
                                            (0.15 * 255).round())),
                                blurRadius: isHovered ? 20 : 12,
                                spreadRadius: isHovered ? 2 : 0,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: Stack(
                              children: [
                                GameWidget(game: _galacticGame),

                                // Racing telemetry indicator
                                Positioned(
                                  top: 8,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withAlpha((0.65 * 255).round()),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: gameState.trackShips.length >= 4
                                            ? const Color(0xFFFFD700)
                                            : const Color(0xFF00F0FF)
                                                .withAlpha(100),
                                        width: 0.8,
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

                                // Prompt if 0 ships racing
                                if (gameState.trackShips.isEmpty)
                                  Center(
                                    child: IgnorePointer(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A)
                                              .withAlpha((0.92 * 255).round()),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF00F0FF),
                                            width: 1.6,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00F0FF)
                                                  .withAlpha(
                                                      (0.55 * 255).round()),
                                              blurRadius: 18,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('👇',
                                                style: TextStyle(fontSize: 18)),
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

                                // Hyperspace Nitro Overdrive Activation Pill
                                Positioned(
                                  top: 8,
                                  right: 10,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      final activated = ref
                                          .read(gameStateProvider.notifier)
                                          .activateNitroOverdrive();
                                      if (!activated &&
                                          !gameState.isNitroActive) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            backgroundColor:
                                                const Color(0xFF131B3A),
                                            content: Text(
                                              '⚡ Nitro Energy: ${(gameState.nitroCharge * 100).toInt()}%',
                                              style: const TextStyle(
                                                  color: Color(0xFF00F0FF),
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            duration: const Duration(
                                                milliseconds: 600),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: gameState.isNitroActive
                                            ? const Color(0xFFFF0055).withAlpha(
                                                (0.85 * 255).round())
                                            : (gameState.nitroCharge >= 0.99
                                                ? const Color(0xFF00F0FF)
                                                    .withAlpha(
                                                        (0.25 * 255).round())
                                                : Colors.black.withAlpha(
                                                    (0.6 * 255).round())),
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
                                                  .withAlpha(
                                                      (0.45 * 255).round()),
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
                                                  : (gameState.nitroCharge >=
                                                          0.99
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
                        );
                      },
                    ),
                  ),

                  // 5. Flight Ops Console (Speed Upgrades + Boost Pads + Laser Gates)
                  FlightOpsStrip(
                    gameState: gameState,
                    fleetSpeedKey: _fleetSpeedGlobalKey,
                    onUpgradeFleetSpeed: () {
                      if (gameState.isFleetSpeedMaxed) {
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
                      final success = ref
                          .read(gameStateProvider.notifier)
                          .upgradeFleetSpeed();
                      if (success) {
                        SoundService().playUpgradeSound();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF1E293B),
                            content: Text(
                              '⚡ Need ${NumberFormatter.formatCredits(gameState.fleetSpeedUpgradeCost)} credits to upgrade Speed!',
                              style: const TextStyle(color: Color(0xFFFFD700)),
                            ),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      }
                    },
                    onUnlockBoostPad: () {
                      final nextPadNumber = gameState.boostPadCount + 1;
                      final success = ref
                          .read(gameStateProvider.notifier)
                          .unlockNextBoostPad();
                      if (success) {
                        SoundService().playUpgradeSound();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF0B2418),
                            content: Text(
                              '🚀 Installed On-Track Hyper Boost Pad #$nextPadNumber!',
                              style: const TextStyle(color: Color(0xFF00FF88)),
                            ),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      }
                    },
                    onUpgradeBoostPad: () {
                      final success = ref
                          .read(gameStateProvider.notifier)
                          .upgradeBoostPad();
                      if (success) {
                        SoundService().playUpgradeSound();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF0B2418),
                            content: Text(
                              '🚀 Hyper-Pads upgraded to Lv.${gameState.boostPadLevel + 1}!',
                              style: const TextStyle(color: Color(0xFF00FF88)),
                            ),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      }
                    },
                    onUnlockFinishLine: () {
                      final success = ref
                          .read(gameStateProvider.notifier)
                          .unlockNextFinishLine();
                      if (success) {
                        SoundService().playUpgradeSound();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF0B2418),
                            content: Text(
                              '🏁 Laser Finish Line #${gameState.finishLinesCount + 1} Unlocked!',
                              style: const TextStyle(color: Color(0xFF00FF88)),
                            ),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      }
                    },
                    onEvolveTrack: () {
                      final nextTier = gameState.circuitTier + 1;
                      final tierName = 'Circuit Tier $nextTier';
                      final success = ref
                          .read(gameStateProvider.notifier)
                          .evolveTrackCircuit();
                      if (success) {
                        SoundService().playPrestigeSound();
                        _openGameModal((c) => TrackAscensionModal(
                              newTier: nextTier,
                              tierName: tierName,
                              incomeMultiplier: 1.5,
                              onContinue: () {
                                Navigator.of(c).pop();
                              },
                            ));
                      }
                    },
                  ),

                  // 6. Interactive 4x4 Merge Grid UI with Deadlock Relief
                  Expanded(
                    flex: 10,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      child: MergeGridView(
                        state: gameState,
                        maxUnlockedGridSlots: maxUnlocked,
                        slot0Key: _slot0GlobalKey,
                        slot1Key: _slot1GlobalKey,
                        onMergeOrMove: (from, to) {
                          ref
                              .read(gameStateProvider.notifier)
                              .handleGridMergeOrMove(from, to);
                        },
                        onOpenCrate: (index) {
                          final ship = gameState.gridSlots[index];
                          if (ship == null || !ship.isBox) return;

                          void performUnbox() {
                            SoundService().playCrateOpenSound();
                            ref
                                .read(gameStateProvider.notifier)
                                .openCrate(index);
                            _vfxController.spawnFloatingText(
                              origin: const Offset(180, 420),
                              text: ship.isAdBox
                                  ? 'GOLDEN CARGO UNBOXED! 🎁⭐'
                                  : 'CRATE UNBOXED! 📦✨',
                              color: ship.isAdBox
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF00FF88),
                              fontSize: 14.0,
                            );
                            _vfxController.spawnShockwave(
                              origin: const Offset(180, 420),
                              color: ship.isAdBox
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF00F0FF),
                              maxRadius: 65.0,
                            );
                          }

                          if (ship.isAdBox && !gameState.hasRemovedAds) {
                            AdManager().showRewardedAd(
                              onUserEarnedReward: () {
                                performUnbox();
                              },
                              onAdClosed: () {},
                            );
                          } else {
                            performUnbox();
                          }
                        },
                        onQuickClearDeadlock: () {
                          final refund = ref
                              .read(gameStateProvider.notifier)
                              .recycleLowestTierShip();
                          if (refund > 0) {
                            SoundService().playPurchaseSound();
                            _vfxController.spawnCoins(
                              origin: const Offset(180, 420),
                              targetKey: _coinCounterGlobalKey,
                              count: 6,
                              color: const Color(0xFFFFD700),
                              onTargetHit: _triggerCoinWalletBounce,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF131B3A),
                                content: Text(
                                  '♻️ Recycled ship for +${NumberFormatter.formatCredits(refund)} credits! Deck space freed up!',
                                  style: const TextStyle(
                                      color: Color(0xFF00FF88),
                                      fontWeight: FontWeight.bold),
                                ),
                                duration: const Duration(milliseconds: 900),
                              ),
                            );
                          }
                        },
                        onMergeVfx: (from, to, targetShip, dropPos) {
                          final int newTier = targetShip.tier + 1;
                          final Color tierColor =
                              ShipModel.create(newTier).glowColor;
                          SoundService().playMergeSound();
                          SoundService().playMergeHaptic();

                          _vfxController.spawnShockwave(
                            origin: dropPos,
                            color: tierColor,
                            maxRadius: 65.0,
                          );
                          _vfxController.spawnFloatingText(
                            origin: dropPos,
                            text: 'TIER $newTier FUSION! 🚀✨',
                            color: tierColor,
                            fontSize: 15.0,
                          );
                          _vfxController.spawnCoins(
                            origin: dropPos,
                            targetKey: _coinCounterGlobalKey,
                            count: 7,
                            color: const Color(0xFFFFD700),
                            onTargetHit: _triggerCoinWalletBounce,
                          );
                        },
                      ),
                    ),
                  ),

                  // 7. Bottom Command Dock
                  BottomCommandDock(
                    gameState: gameState,
                    adState: adState,
                    canAffordShip: canAffordShip,
                    nextBuyCost: nextBuyCost,
                    dropTier: dropTier,
                    buyShipKey: _buyShipGlobalKey,
                    sortButtonKey: _sortButtonGlobalKey,
                    hubBadgeCount: _getHubBadgeCount(gameState),
                    onRecycleShip: (slotIndex) {
                      final refund = ref
                          .read(gameStateProvider.notifier)
                          .recycleShip(slotIndex);
                      if (refund == -1.0) {
                        SoundService().playButtonHaptic();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFFFF0055),
                            content: Text(
                              '😄 Keep at least 1 spaceship so you can keep racing!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else if (refund > 0) {
                        SoundService().playPurchaseSound();
                        _vfxController.spawnCoins(
                          origin: const Offset(180, 520),
                          targetKey: _coinCounterGlobalKey,
                          count: 6,
                          color: const Color(0xFFFFD700),
                          onTargetHit: _triggerCoinWalletBounce,
                        );
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
                    onAutoMergeTap: () {
                      if (!gameState.hasRemovedAds &&
                          !gameState.isDroneCurrentlyActive) {
                        _showAutoMergePremiumDialog(context);
                        return;
                      }
                      final count = ref
                          .read(gameStateProvider.notifier)
                          .autoMergeGrid();
                      if (count == 0) {
                        SoundService().playButtonHaptic();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF1E293B),
                            content: Text(
                                'No matching spaceship pairs to merge right now!'),
                            duration: Duration(milliseconds: 700),
                          ),
                        );
                      } else {
                        SoundService().playComboSound(count);
                        _vfxController.spawnFloatingText(
                          origin: const Offset(180, 420),
                          text: '⚡ $count AUTO-MERGES! ✨',
                          color: const Color(0xFF00FF88),
                          fontSize: 14.0,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF131B3A),
                            content: Text(
                              '⚡ Auto-Merged & Organized $count pairs!',
                              style: const TextStyle(
                                color: Color(0xFF00FF88),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            duration: const Duration(milliseconds: 700),
                          ),
                        );
                      }
                    },
                    onSortTap: () {
                      SoundService().playButtonHaptic();
                      final sorted =
                          ref.read(gameStateProvider.notifier).sortGridSlots();
                      if (sorted) {
                        _vfxController.spawnFloatingText(
                          origin: const Offset(180, 420),
                          text: '✨ DECK ORGANIZED!',
                          color: const Color(0xFF00F0FF),
                          fontSize: 13.0,
                        );
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
                    onBuyShipTap: () {
                      final hasEmptySlot = gameState.gridSlots
                          .take(maxUnlocked)
                          .any((s) => s == null);

                      if (!hasEmptySlot) {
                        HapticFeedback.heavyImpact();
                        _vfxController.spawnFloatingText(
                          origin: const Offset(180, 500),
                          text: '🚫 DECK FULL! MERGE FIRST',
                          color: const Color(0xFFFF3366),
                          fontSize: 13.0,
                        );
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF2A0815),
                            content: Text(
                              '🚫 Hangar Deck is full! Merge ships or recycle to make space!',
                              style: TextStyle(
                                color: Color(0xFFFF5588),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            duration: Duration(milliseconds: 900),
                          ),
                        );
                        return;
                      }

                      final success =
                          ref.read(gameStateProvider.notifier).purchaseShip();
                      if (success) {
                        _vfxController.spawnFloatingText(
                          origin: const Offset(180, 520),
                          text: '+T$dropTier STARSHIP 🛸',
                          color: const Color(0xFF00FF88),
                          fontSize: 13.0,
                        );
                      } else {
                        SoundService().playButtonHaptic();
                      }
                    },
                    onSpeedBoostTap: () {
                      SoundService().playFeverSound();
                      if (!adState.canStackBoost) return;
                      if (gameState.hasRemovedAds) {
                        ref
                            .read(adStateProvider.notifier)
                            .activateSpeedBoost();
                        _triggerRewardFlyingCoins(
                            count: 8, color: const Color(0xFFFF9900));
                        return;
                      }
                      AdManager().showRewardedAd(
                        onUserEarnedReward: () {
                          ref
                              .read(adStateProvider.notifier)
                              .activateSpeedBoost();
                          _triggerRewardFlyingCoins(
                              count: 8, color: const Color(0xFFFF9900));
                        },
                      );
                    },
                    onCommandHubTap: () {
                      _openGameModal((ctx) => const CommandHubModal());
                    },
                  ),
                ],
              ),
            ),

            // GPU-Accelerated Flying Coins Magnet & Floating Arcade Texts
            IdleVfxOverlay(controller: _vfxController),

            // Cadet Tutorial & Micro-Tutorial Overlays
            if (gameState.tutorialStep < 5)
              TutorialGuideOverlay(
                tutorialStep: gameState.tutorialStep,
                targetKey: _getTutorialTargetKey(gameState.tutorialStep),
                destinationKey:
                    _getTutorialDestinationKey(gameState.tutorialStep),
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

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: GameTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: GameTheme.neonGold.withAlpha((0.35 * 255).round()),
          width: 0.8,
        ),
      ),
      child: InkWell(
        onTap: () => _openGameModal((ctx) => const MembershipPlansModal()),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: GameTheme.neonGold,
                size: 14,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'GO VIP: Remove All Ads + Auto-Merge Drone!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: GameTheme.neonGold,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: GameTheme.neonGold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'UPGRADE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
