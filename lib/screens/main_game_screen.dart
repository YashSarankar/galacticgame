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

class MainGameScreen extends ConsumerStatefulWidget {
  const MainGameScreen({super.key});

  @override
  ConsumerState<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends ConsumerState<MainGameScreen> {
  late final GalacticGame _galacticGame;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _hasCheckedOffline = false;
  int _lastSeenHighestTier = 1;
  Timer? _cargoDropTimer;
  Timer? _feverTimer;
  Timer? _bossIncursionTimer;


  @override
  void initState() {
    super.initState();
    _galacticGame = GalacticGame(
      onIncomeEarned: (ship) {
        final adState = ref.read(adStateProvider);
        final double multiplier = adState.isSpeedBoostActive ? 2.0 : 1.0;
        ref
            .read(gameStateProvider.notifier)
            .recordIncomeLineCrossing(ship, adMultiplier: multiplier);
      },
      onAsteroidDestroyed: (isDM, reward) {
        ref
            .read(gameStateProvider.notifier)
            .recordAsteroidShattered(isDarkMatter: isDM, rewardCredits: reward);
      },
      onCanvasTapped: () {
        ref.read(gameStateProvider.notifier).tapRacetrackBoost();
      },
      onBossDamaged: (damage, {bool isTap = false}) {
        ref.read(gameStateProvider.notifier).damageBoss(damage, isTap: isTap);
      },
    );

    // Periodic Mystery Cosmic Cargo Crate Drops (Every 38 seconds)
    _cargoDropTimer = Timer.periodic(const Duration(seconds: 38), (_) {
      if (mounted) {
        ref.read(gameStateProvider.notifier).dropMysteryCargo();
      }
    });

    // Real-time Fever & Boss ticker (100ms interval for fluid decay & countdown)
    _feverTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        ref.read(gameStateProvider.notifier).tickFever(0.1);
        ref.read(gameStateProvider.notifier).tickBoss(0.1);
      }
    });

    // Periodic Alien Boss Incursion (Every 2 minutes 30 seconds)
    _bossIncursionTimer =
        Timer.periodic(const Duration(minutes: 2, seconds: 30), (_) {
      if (mounted) {
        ref.read(gameStateProvider.notifier).spawnAlienBoss();
      }
    });

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
    _cargoDropTimer?.cancel();
    _feverTimer?.cancel();
    _bossIncursionTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }


  void _checkOfflineEarningsOnStartup(WidgetRef ref) {
    if (_hasCheckedOffline) return;
    _hasCheckedOffline = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offlineAsync = ref.read(initialGameLoaderProvider);
      offlineAsync.whenData((offlineResult) {
        if (offlineResult != null && offlineResult.hasSignificantEarnings) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => OfflineEarningsModal(
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
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _checkOfflineEarningsOnStartup(ref);

    final gameState = ref.watch(gameStateProvider);
    final adState = ref.watch(adStateProvider);

    // Check if player unlocked a brand new highest tier to trigger Discovery Celebration Modal
    if (gameState.highestTierUnlocked > _lastSeenHighestTier) {
      final int discoveredTier = gameState.highestTierUnlocked;
      _lastSeenHighestTier = discoveredTier;
      if (discoveredTier > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => DiscoveryModal(
                ship: ShipModel.create(discoveredTier),
                onDismiss: () {},
              ),
            );
          }
        });
      }
    }

    // Sync active track ships, active boss, and fever mode with Flame Game engine
    _galacticGame.updateShips(gameState.trackShips);
    _galacticGame.updateBoss(gameState.activeBoss);
    _galacticGame.setSpeedMultiplier(
      adState.isSpeedBoostActive ? 2.0 : 1.0,
      isFever: gameState.isFeverActive,
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


            // 5. Center Flame Canvas (Racetrack)
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
                child: GameWidget(
                  key: const ValueKey('galactic_flame_game_canvas'),
                  game: _galacticGame,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Soft Credits Counter
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
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
                padding: const EdgeInsets.all(6),
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

          Row(
            children: [
              // Boss Summon Beacon (if no boss active)
              if (state.activeBoss == null || state.activeBoss!.isDead) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    ref.read(gameStateProvider.notifier).spawnAlienBoss();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0055)
                          .withAlpha((0.25 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFF0055), width: 1.2),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.radar_rounded,
                          color: Color(0xFFFF0055),
                          size: 14,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'BEACON',
                          style: TextStyle(
                            color: Color(0xFFFF0055),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Galactic Prestige Button
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => PrestigeModal(
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
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        GameTheme.neonMagenta.withAlpha((0.25 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: GameTheme.neonMagenta, width: 1.2),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.restart_alt_rounded,
                        color: GameTheme.neonMagenta,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'PRESTIGE',
                        style: TextStyle(
                          color: GameTheme.neonMagenta,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: GameTheme.neonPurple,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ALL DIRECTIVES COMPLETED • PRESTIGE FOR NEW SECTORS',
                      style: TextStyle(
                        color: GameTheme.neonPurple,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                activeMission.title,
                                style: const TextStyle(
                                  color: GameTheme.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white24,
                        size: 14,
                      ),
                      SizedBox(height: 2),
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

    if (state.lastComboMessage.isNotEmpty)
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: GameTheme.glassCard(
        borderColor: GameTheme.cardBorder,
        radius: 16,
      ),
      child: Row(
        children: [
          // 0. DragTarget Scrap / Recycle Bin
          DragTarget<int>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              final refund = ref
                  .read(gameStateProvider.notifier)
                  .recycleShip(details.data);
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
            },
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;
              return Container(
                width: 44,
                height: 48,
                decoration: BoxDecoration(
                  color: isHovered
                      ? const Color(0xFFFF0055).withAlpha((0.35 * 255).round())
                      : GameTheme.cardSurface,
                  borderRadius: BorderRadius.circular(12),
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
                      color:
                          isHovered ? const Color(0xFFFF0055) : Colors.white60,
                      size: 18,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'SCRAP',
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
            label: 'TECH',
            color: GameTheme.neonPurple,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => const SkillTreeModal(),
              );
            },
          ),
          const SizedBox(width: 6),

          // 3. Missions Button
          _buildActionButton(
            icon: Icons.flag_rounded,
            label: 'DIRECTIVES',
            color: GameTheme.neonGreen,
            badgeCount: unclaimedMissions,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => const MissionsModal(),
              );
            },
          ),

          const SizedBox(width: 8),

          // 3. 2X Track Speed Boost Button (Rewarded Ad)
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
                  ref.read(adStateProvider.notifier).activateSpeedBoost();
                },
              );
            },
          ),
          const SizedBox(width: 10),

          // 4. Primary Buy Ship CTA
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canAffordShip ? GameTheme.neonCyan : Colors.grey.shade800,
                  foregroundColor:
                      canAffordShip ? Colors.black : Colors.white54,
                  elevation: canAffordShip ? 6 : 0,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: canAffordShip
                    ? () {
                        ref.read(gameStateProvider.notifier).purchaseShip();
                      }
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BUY SHIP (T$dropTier)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      NumberFormatter.formatCredits(nextBuyCost),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      maxLines: 1,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
    bool isActive = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 60,
            height: 48,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: GameTheme.neonCrimson,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
