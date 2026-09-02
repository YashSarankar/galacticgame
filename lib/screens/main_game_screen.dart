import 'dart:async';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
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
import 'modals/missions_modal.dart';
import 'modals/offline_earnings_modal.dart';
import 'modals/prestige_modal.dart';
import 'modals/skill_tree_modal.dart';
import 'modals/discovery_modal.dart';
import 'modals/relics_modal.dart';
import 'modals/wormhole_roulette_modal.dart';
import 'modals/expeditions_modal.dart';
import 'modals/daily_calendar_modal.dart';
import 'modals/cosmic_store_modal.dart';
import 'modals/mystery_card_modal.dart';
import 'modals/comet_rush_modal.dart';
import 'modals/achievements_modal.dart';
import 'modals/settings_modal.dart';
import '../models/sector_theme_model.dart';

class MainGameScreen extends ConsumerStatefulWidget {







  const MainGameScreen({super.key});

  @override
  ConsumerState<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends ConsumerState<MainGameScreen>
    with TickerProviderStateMixin {
  late final GalacticGame _galacticGame;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _hasCheckedOffline = false;
  bool _isModalOpen = false;
  Timer? _cargoDropTimer;
  Timer? _feverTimer;
  Timer? _bossIncursionTimer;

  // Live In-Game Event: Golden UFO
  late final AnimationController _ufoAnimController;
  late final Animation<double> _ufoAnimation;
  bool _isUfoVisible = false;
  Timer? _ufoSpawnTimer;
  Timer? _initialUfoTimer;

  // Live In-Game Event: Golden Comet
  late final AnimationController _cometAnimController;
  late final Animation<double> _cometAnimation;
  bool _isCometVisible = false;
  Timer? _cometSpawnTimer;
  Timer? _initialCometTimer;

  @override
  void initState() {
    super.initState();
    _galacticGame = GalacticGame(
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
        });
      },
    );

    // Setup Golden UFO Animation & Spawner
    _ufoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
    _ufoAnimation = Tween<double>(begin: -70.0, end: 380.0).animate(
      CurvedAnimation(parent: _ufoAnimController, curve: Curves.easeInOut),
    );
    _ufoAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _isUfoVisible = false);
      }
    });

    _ufoSpawnTimer = Timer.periodic(const Duration(seconds: 80), (_) {
      if (mounted && !_isModalOpen && !_isUfoVisible) {
        setState(() => _isUfoVisible = true);
        _ufoAnimController.forward(from: 0.0);
      }
    });
    // First UFO fly-by after 25s
    _initialUfoTimer = Timer(const Duration(seconds: 25), () {
      if (mounted && !_isModalOpen && !_isUfoVisible) {
        setState(() => _isUfoVisible = true);
        _ufoAnimController.forward(from: 0.0);
      }
    });

    // Setup Golden Comet Animation & Spawner
    _cometAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _cometAnimation = Tween<double>(begin: -80.0, end: 400.0).animate(
      CurvedAnimation(parent: _cometAnimController, curve: Curves.linear),
    );
    _cometAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _isCometVisible = false);
      }
    });

    _cometSpawnTimer = Timer.periodic(const Duration(seconds: 130), (_) {
      if (mounted && !_isModalOpen && !_isCometVisible) {
        setState(() => _isCometVisible = true);
        _cometAnimController.forward(from: 0.0);
      }
    });
    // First Comet streak after 50s
    _initialCometTimer = Timer(const Duration(seconds: 50), () {
      if (mounted && !_isModalOpen && !_isCometVisible) {
        setState(() => _isCometVisible = true);
        _cometAnimController.forward(from: 0.0);
      }
    });

    // Periodic Mystery Cosmic Cargo Crate Drops (Every 90 seconds)
    _cargoDropTimer = Timer.periodic(const Duration(seconds: 90), (_) {
      if (mounted && !_isModalOpen) {
        ref.read(gameStateProvider.notifier).dropMysteryCargo();
      }
    });

    // Real-time Fever, Boss, and VIP Drone Auto-Collector ticker (100ms interval)
    int tickCount = 0;
    _feverTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && !_isModalOpen) {
        ref.read(gameStateProvider.notifier).tickFever(0.1);
        ref.read(gameStateProvider.notifier).tickBoss(0.1);
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

  void _onUfoTapped(GameState gameState) {
    _ufoAnimController.stop();
    setState(() => _isUfoVisible = false);

    const double approxTrackLength = 1400.0;
    final double totalFleetPerSec = gameState.trackShips.fold<double>(
      0.0,
      (sum, s) =>
          sum + (s.calculateIncomePayout() * (s.baseSpeed / approxTrackLength)),
    );

    _openGameModal((ctx) => MysteryCardModal(
          fleetIncomePerLap: max(20.0, totalFleetPerSec),
          highestTierUnlocked: gameState.highestTierUnlocked,
          onRewardChosen: (reward, {bool doubleWithAd = false}) {
            ref
                .read(gameStateProvider.notifier)
                .applyMysteryCardReward(reward, doubleWithAd: doubleWithAd);
          },
        ));
  }

  void _onCometTapped(GameState gameState) {
    _cometAnimController.stop();
    setState(() => _isCometVisible = false);

    const double approxTrackLength = 1400.0;
    final double totalFleetPerSec = gameState.trackShips.fold<double>(
      0.0,
      (sum, s) =>
          sum + (s.calculateIncomePayout() * (s.baseSpeed / approxTrackLength)),
    );

    _openGameModal((ctx) => CometRushModal(
          fleetIncomePerLap: max(20.0, totalFleetPerSec),
          onSessionComplete: ({
            required int taps,
            required double scoreMultiplier,
            bool doubleWithAd = false,
          }) {
            ref.read(gameStateProvider.notifier).completeCometRushSession(
                  taps: taps,
                  scoreMultiplier: scoreMultiplier,
                  doubleWithAd: doubleWithAd,
                );
          },
        ));
  }

  @override
  void dispose() {
    _cargoDropTimer?.cancel();
    _feverTimer?.cancel();
    _bossIncursionTimer?.cancel();
    _ufoSpawnTimer?.cancel();
    _initialUfoTimer?.cancel();
    _cometSpawnTimer?.cancel();
    _initialCometTimer?.cancel();
    _ufoAnimController.dispose();
    _cometAnimController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }



  Future<void> _openGameModal(WidgetBuilder builder) async {
    _isModalOpen = true;
    await showDialog(
      context: context,
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: builder(ctx),
      ),
    );
    if (mounted) {
      _isModalOpen = false;
    }
  }


  void _checkOfflineEarningsOnStartup(WidgetRef ref) {
    if (_hasCheckedOffline) return;
    _hasCheckedOffline = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offlineAsync = ref.read(initialGameLoaderProvider);
      offlineAsync.whenData((offlineResult) {
        if (offlineResult != null && offlineResult.hasSignificantEarnings) {
          _openGameModal((ctx) => OfflineEarningsModal(
                result: offlineResult,
                onClaimRegular: () {
                  ref
                      .read(gameStateProvider.notifier)
                      .claimOfflineEarnings(offlineResult.coinsEarned);
                  Navigator.of(ctx).pop();
                },
                onClaimDoubled: () {
                  ref.read(gameStateProvider.notifier).claimOfflineEarnings(
                        offlineResult.coinsEarned,
                        doubleReward: true,
                      );
                  Navigator.of(ctx).pop();
                },
              ));
        } else {
          // If no offline earnings modal, check if daily login reward is ready!
          final gameState = ref.read(gameStateProvider);
          if (gameState.canClaimDailyReward) {
            _openGameModal((ctx) => const DailyCalendarModal());
          }
        }
      });
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
    });

    final gameState = ref.watch(gameStateProvider);
    final adState = ref.watch(adStateProvider);


    // Sync active track ships, active boss, fever mode, and sector theme with Flame Game engine
    _galacticGame.updateShips(gameState.trackShips);
    _galacticGame.updateBoss(gameState.activeBoss);
    _galacticGame.setSpeedMultiplier(
      adState.isSpeedBoostActive ? 2.0 : 1.0,
      isFever: gameState.isFeverActive,
    );
    _galacticGame.updateSectorTheme(
      SectorThemeModel.getThemeForSector(gameState.career.sectorLevel),
    );



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
    final double nextBuyCost = ShipModel.calculatePurchaseCost(
      gameState.totalShipsPurchased,
      dropTier,
      discount: discountSkill.currentBonusValue,
    );
    final bool canAffordShip =
        gameState.credits >= nextBuyCost && gameState.gridSlots.contains(null);

    final unclimedMissionsCount = gameState.career.missions
        .where((m) => m.isCompleted && !m.isClaimed)
        .length;

    return Scaffold(
      backgroundColor: GameTheme.backgroundVoid,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Banner Ad Slot
            _buildTopBannerSlot(),

            // 2. Top Currency & Sector Bar
            _buildHeaderStatsBar(gameState),

            // 3. Active Mission Strip
            _buildActiveMissionBar(gameState),

            // 4. Hyperdrive Warp Meter / Boss Siege Alert Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _buildBossSiegeHUD(gameState),
            ),


            // 5. Center Flame Canvas (Racetrack with Live In-Game Events)
            Expanded(
              flex: 7,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: gameState.isFeverActive
                        ? const Color(0xFFFFD700)
                        : GameTheme.neonCyan.withAlpha((0.3 * 255).round()),
                    width: gameState.isFeverActive ? 2.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gameState.isFeverActive
                          ? const Color(0xFFFF0055).withAlpha((0.35 * 255).round())
                          : GameTheme.neonCyan.withAlpha((0.15 * 255).round()),
                      blurRadius: gameState.isFeverActive ? 18 : 12,
                      spreadRadius: gameState.isFeverActive ? 2 : 1,
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    GameWidget(
                      key: const ValueKey('galactic_flame_game_canvas'),
                      game: _galacticGame,
                    ),

                    // Live Animated Golden UFO Event
                    if (_isUfoVisible)
                      AnimatedBuilder(
                        animation: _ufoAnimation,
                        builder: (context, child) {
                          return Positioned(
                            left: _ufoAnimation.value,
                            top: 20.0 + sin(_ufoAnimController.value * 4 * pi) * 14.0,
                            child: GestureDetector(
                              onTap: () => _onUfoTapped(gameState),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFFD700)
                                      .withAlpha((0.25 * 255).round()),
                                  border: Border.all(
                                      color: const Color(0xFFFFD700),
                                      width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700)
                                          .withAlpha((0.5 * 255).round()),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/kenney_space-shooter-remastered/PNG/ufoYellow.png',
                                  width: 34,
                                  height: 34,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Live Animated Golden Comet Event
                    if (_isCometVisible)
                      AnimatedBuilder(
                        animation: _cometAnimation,
                        builder: (context, child) {
                          return Positioned(
                            left: _cometAnimation.value,
                            top: 15.0 + (_cometAnimController.value * 70.0),
                            child: GestureDetector(
                              onTap: () => _onCometTapped(gameState),
                              child: Transform.rotate(
                                angle: 0.45,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF0055)
                                            .withAlpha((0.6 * 255).round()),
                                        blurRadius: 20,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/kenney_space-shooter-remastered/PNG/Power-ups/powerupYellow_bolt.png',
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),


            // 6. Interactive 4x4 Merge Grid UI
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: _buildMergeGrid(gameState),
              ),
            ),



            // 6. Bottom Action Deck (Buy Ship, Speed Boost, Tech Tree, Missions)
            _buildBottomActionBar(
              gameState: gameState,
              adState: adState,
              canAffordShip: canAffordShip,
              nextBuyCost: nextBuyCost,
              dropTier: dropTier,
              unclaimedMissions: unclimedMissionsCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBannerSlot() {
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


  Widget _buildHeaderStatsBar(GameState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: GameTheme.glassCard(radius: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Currency Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Soft Credits Counter
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GameTheme.neonGold.withAlpha((0.2 * 255).round()),
                    ),
                    child: const Icon(
                      Icons.monetization_on_rounded,
                      color: GameTheme.neonGold,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    NumberFormatter.formatCredits(state.credits),
                    style: const TextStyle(
                      color: GameTheme.neonGold,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: GameTheme.neonGold, blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),

              // Hard Currency (Dark Matter)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GameTheme.neonPurple.withAlpha((0.2 * 255).round()),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: GameTheme.neonPurple,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    NumberFormatter.formatDarkMatter(state.darkMatter),
                    style: const TextStyle(
                      color: GameTheme.neonPurple,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: GameTheme.neonPurple, blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ),

              // Settings & Lifetime Dossier Button (Gear Icon)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _openGameModal((ctx) => const SettingsModal());
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),


          const SizedBox(height: 8),

          // Row 2: Action CTAs (Beacon, Spin, Prestige)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Boss Summon Beacon (if no boss active)
              if (state.activeBoss == null || state.activeBoss!.isDead)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      ref.read(gameStateProvider.notifier).spawnAlienBoss();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0055)
                            .withAlpha((0.25 * 255).round()),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFFF0055), width: 1.2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.radar_rounded,
                            color: Color(0xFFFF0055),
                            size: 13,
                          ),
                          SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              'BEACON',
                              style: TextStyle(
                                color: Color(0xFFFF0055),
                                fontSize: 9.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (state.activeBoss == null || state.activeBoss!.isDead)
                const SizedBox(width: 4),

              // 2. Daily Login Calendar Button
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    _openGameModal((ctx) => const DailyCalendarModal());
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700)
                          .withAlpha((0.20 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFFD700), width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFFFFD700),
                          size: 13,
                        ),
                        const SizedBox(width: 2),
                        const Flexible(
                          child: Text(
                            'DAILY',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 9.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (state.canClaimDailyReward) ...[
                          const SizedBox(width: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00FF88),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // 3. Wormhole Roulette Button
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    _openGameModal((ctx) => const WormholeRouletteModal());
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F5FF)
                          .withAlpha((0.20 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF00F5FF), width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.blur_circular_rounded,
                          color: Color(0xFF00F5FF),
                          size: 13,
                        ),
                        const SizedBox(width: 2),
                        const Flexible(
                          child: Text(
                            'SPIN',
                            style: TextStyle(
                              color: Color(0xFF00F5FF),
                              fontSize: 9.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (state.canSpinFree) ...[
                          const SizedBox(width: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00FF88),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // 4. Milestone Trophy Achievements Button
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    _openGameModal((ctx) => const AchievementsModal());
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700)
                          .withAlpha((0.20 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFFD700), width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFFFFD700),
                          size: 13,
                        ),
                        const SizedBox(width: 2),
                        const Flexible(
                          child: Text(
                            'TROPHY',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 9.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (state.unclaimedAchievementsCount > 0) ...[
                          const SizedBox(width: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00FF88),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // 5. Galactic Prestige Button
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    _openGameModal((ctx) => PrestigeModal(
                          state: state,
                          onPrestige: () {
                            ref
                                .read(gameStateProvider.notifier)
                                .performGalacticPrestige();
                          },
                          onPrestigeDoubled: () {
                            ref
                                .read(gameStateProvider.notifier)
                                .performGalacticPrestige(doubleYield: true);
                          },
                        ));
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    decoration: BoxDecoration(
                      color: GameTheme.neonMagenta
                          .withAlpha((0.25 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: GameTheme.neonMagenta, width: 1.2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restart_alt_rounded,
                          color: GameTheme.neonMagenta,
                          size: 13,
                        ),
                        SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            'PRESTIGE',
                            style: TextStyle(
                              color: GameTheme.neonMagenta,
                              fontSize: 9.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),


            ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF0055),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '⚠️ ${boss.name.toUpperCase()} SIEGE',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                '⏱️ ${boss.timeRemaining.toStringAsFixed(1)}s  |  HP: ${(hpPercent * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFFFF0055),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                  Text(
                    isFever
                        ? '🔥 HYPERSPACE WARP: 3.5X SPEED & 3X CRITS!'
                        : 'TAP CIRCUIT TO CHARGE WARP RUSH',
                    style: TextStyle(
                      color: isFever
                          ? const Color(0xFFFFD700)
                          : Colors.white70,
                      fontSize: 8.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              Text(
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
                  ref
                      .read(gameStateProvider.notifier)
                      .handleGridMergeOrMove(fromIndex, index);
                },
                builder: (context, candidateData, rejectedData) {
                  final bool isHovered = candidateData.isNotEmpty;

                  return Container(
                    decoration: BoxDecoration(
                      color: isHovered
                          ? GameTheme.neonCyan.withAlpha((0.2 * 255).round())
                          : GameTheme.cardSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isHovered
                            ? GameTheme.neonCyan
                            : (ship != null
                                ? ship.glowColor.withAlpha((0.4 * 255).round())
                                : GameTheme.cardBorder),
                        width: isHovered ? 2.0 : 1.0,
                      ),
                      boxShadow: ship != null
                          ? [
                              BoxShadow(
                                color: ship.glowColor
                                    .withAlpha((0.15 * 255).round()),
                                blurRadius: 4,
                              )
                            ]
                          : null,
                    ),
                    child: ship != null
                        ? (ship.isBox
                            ? GestureDetector(
                                onTap: () => ref
                                    .read(gameStateProvider.notifier)
                                    .openCrate(index),
                                child: _buildCrateTileContent(),
                              )
                            : Draggable<int>(
                                data: index,
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
                        : const Center(
                            child: Icon(
                              Icons.add,
                              color: Color(0xFF334155),
                              size: 14,
                            ),
                          ),
                  );
                },
              );
            },
          );
        },
      ),
    ),

    if (state.lastComboMessage.isNotEmpty &&
        (DateTime.now().millisecondsSinceEpoch - state.lastMergeTimestamp < 2500))
      Positioned(
        top: 8,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((0.88 * 255).round()),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFFF0055),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Text(
              state.lastComboMessage,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
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

                // "TAP OPEN" Badge
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0055),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TAP OPEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
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


  Widget _buildBottomActionBar({
    required GameState gameState,
    required AdBoostState adState,
    required bool canAffordShip,
    required double nextBuyCost,
    required int dropTier,
    required int unclaimedMissions,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: GameTheme.glassCard(
        borderColor: GameTheme.cardBorder,
        radius: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tier 1: Utility & Subsystem Tools (2 clean rows of 4 buttons, no scrolling needed)
          Column(
            children: [

              // Row 1: SCRAP | AUTO | TECH | DIRECTIVES
              Row(
                children: [
                  // 0. DragTarget Scrap / Recycle Bin
                  Expanded(
                    child: DragTarget<int>(
                      onWillAcceptWithDetails: (details) => true,
                      onAcceptWithDetails: (details) {
                        final refund = ref
                            .read(gameStateProvider.notifier)
                            .recycleShip(details.data);
                        if (refund == -1.0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFFFF0055),
                              content: Text(
                                '⚠️ Cannot scrap your last remaining ship! Keep at least 1 ship in your fleet.',
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
                                '♻️ Recycled for +${NumberFormatter.formatCredits(refund)} credits!',
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
                          height: 44,
                          decoration: BoxDecoration(
                            color: isHovered
                                ? const Color(0xFFFF0055)
                                    .withAlpha((0.35 * 255).round())
                                : GameTheme.cardSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isHovered
                                  ? const Color(0xFFFF0055)
                                  : Colors.white24,
                              width: isHovered ? 2.0 : 1.0,
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
                              const SizedBox(height: 1),
                              Text(
                                'SELL',
                                style: TextStyle(
                                  color: isHovered
                                      ? const Color(0xFFFF0055)
                                      : Colors.white54,
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 1. Auto-Merge Button
                  _buildActionButton(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AUTO',
                    color: const Color(0xFFFFD700),
                    onTap: () {
                      final count =
                          ref.read(gameStateProvider.notifier).autoMergeGrid();
                      if (count == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF1E293B),
                            content: Text(
                              'No matching pairs ready to merge!',
                              style: TextStyle(color: Colors.white70),
                            ),
                            duration: Duration(milliseconds: 900),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 6),

                  // 2. Tech Tree Button
                  _buildActionButton(
                    icon: Icons.account_tree_rounded,
                    label: 'UPGRADES',
                    color: GameTheme.neonPurple,
                    onTap: () {
                      _openGameModal((ctx) => const SkillTreeModal());
                    },
                  ),
                  const SizedBox(width: 6),

                  // 3. Missions Button
                  _buildActionButton(
                    icon: Icons.flag_rounded,
                    label: 'MISSIONS',
                    color: GameTheme.neonGreen,
                    badgeCount: unclaimedMissions,
                    onTap: () {
                      _openGameModal((ctx) => const MissionsModal());
                    },
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Row 2: RELICS | EXPEDITIONS | SHOP | 2X SPEED
              Row(
                children: [
                  // 4. Relics Vault Button
                  _buildActionButton(
                    icon: Icons.auto_awesome_rounded,
                    label: 'RELICS',
                    color: const Color(0xFFBD00FF),
                    onTap: () {
                      _openGameModal((ctx) => const RelicsModal());
                    },
                  ),
                  const SizedBox(width: 6),

                  // 5. Constellation Expeditions Button
                  _buildActionButton(
                    icon: Icons.travel_explore_rounded,
                    label: 'EXPEDITIONS',
                    color: const Color(0xFF00F0FF),
                    badgeCount: gameState.readyExpeditionsCount,
                    onTap: () {
                      _openGameModal((ctx) => const ExpeditionsModal());
                    },
                  ),
                  const SizedBox(width: 6),

                  // 6. Shop Button
                  _buildActionButton(
                    icon: Icons.storefront_rounded,
                    label: 'SHOP',
                    color: const Color(0xFFFFD700),
                    onTap: () {
                      _openGameModal((ctx) => const CosmicStoreModal());
                    },
                  ),
                  const SizedBox(width: 6),

                  // 7. 2X Track Speed Boost Button (Rewarded Ad)
                  _buildActionButton(
                    icon: Icons.bolt_rounded,
                    label: adState.isSpeedBoostActive
                        ? NumberFormatter.formatSeconds(
                            adState.speedBoostRemainingSeconds)
                        : '2X SPEED',
                    color: GameTheme.neonAmber,
                    isActive: adState.isSpeedBoostActive,

                    onTap: () {
                      if (adState.isSpeedBoostActive) return;
                      AdManager().showRewardedAd(
                        onUserEarnedReward: () {
                          ref
                              .read(adStateProvider.notifier)
                              .activateSpeedBoost();
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Tier 2: Full-Width Primary Buy Ship CTA
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canAffordShip ? GameTheme.neonCyan : Colors.grey.shade800,
                foregroundColor:
                    canAffordShip ? Colors.black : Colors.white54,
                elevation: canAffordShip ? 6 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: canAffordShip
                  ? () {
                      ref.read(gameStateProvider.notifier).purchaseShip();
                    }
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'BUY SHIP (TIER $dropTier) • ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    NumberFormatter.formatCredits(nextBuyCost),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
    bool isActive = false,
  }) {
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? color.withAlpha((0.3 * 255).round())
                    : GameTheme.cardSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? color : GameTheme.cardBorder,
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 8.0,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameTheme.neonCrimson,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

