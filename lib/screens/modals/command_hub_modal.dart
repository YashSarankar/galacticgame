import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_state.dart';
import '../../providers/game_providers.dart';
import '../../services/user_growth_service.dart';
import '../../utils/game_theme.dart';
import 'fleet_codex_modal.dart';
import 'expeditions_modal.dart';
import 'skill_tree_modal.dart';
import 'relics_modal.dart';
import 'achievements_modal.dart';
import 'daily_calendar_modal.dart';
import 'wormhole_roulette_modal.dart';
import 'cosmic_store_modal.dart';
import 'prestige_modal.dart';
import 'missions_modal.dart';

/// Holographic Starfleet Command Hub
/// Centralizes all secondary tycoon systems into an organized, high-tech command center.
class CommandHubModal extends ConsumerWidget {
  const CommandHubModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final rank = UserGrowthService.getCommanderRank(gameState.highestTierUnlocked);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFF090D1A).withAlpha(250),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: rank.color.withAlpha(200), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: rank.color.withAlpha(60),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withAlpha(220),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Holographic Command Header
            _buildCommandHeader(context, gameState, rank),

            // Scrollable Hub System Grid
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category 1: Spaceships & Missions
                    _buildCategoryHeader(
                      'SPACESHIPS & MISSIONS',
                      Icons.rocket_launch_rounded,
                      const Color(0xFF00F0FF),
                    ),
                    const SizedBox(height: 8),
                    _buildHubGrid([
                      _HubItemData(
                        title: 'Daily Tasks',
                        subtitle: 'Earn Easy Rewards',
                        icon: Icons.flag_rounded,
                        color: GameTheme.neonGreen,
                        isUnlocked: true,
                        badgeCount: gameState.career.missions
                            .where((m) => m.isCompleted && !m.isClaimed)
                            .length,
                        onTap: () => _openModal(context, const MissionsModal()),
                      ),
                      _HubItemData(
                        title: 'Ship Collection',
                        subtitle: 'All 16 Spaceships',
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF00FF88),
                        isUnlocked: UserGrowthService.isFeatureUnlocked(
                          GameFeature.codex,
                          highestTier: gameState.highestTierUnlocked,
                        ),
                        requiredTier: 3,
                        onTap: () => _openModal(context, const FleetCodexModal()),
                      ),
                      _HubItemData(
                        title: 'Treasure Hunts',
                        subtitle: 'Send Ships for Loot',
                        icon: Icons.travel_explore_rounded,
                        color: const Color(0xFF00F0FF),
                        isUnlocked: UserGrowthService.isFeatureUnlocked(
                          GameFeature.expeditions,
                          highestTier: gameState.highestTierUnlocked,
                        ),
                        requiredTier: 6,
                        badgeCount: gameState.readyExpeditionsCount,
                        onTap: () => _openModal(context, const ExpeditionsModal()),
                      ),
                      _HubItemData(
                        title: 'Boss Battle',
                        subtitle: gameState.activeBoss != null
                            ? 'Boss Fight in Progress!'
                            : 'Fight Giant Alien',
                        icon: Icons.radar_rounded,
                        color: const Color(0xFFFF0055),
                        isUnlocked: UserGrowthService.isFeatureUnlocked(
                          GameFeature.bossBeacon,
                          highestTier: gameState.highestTierUnlocked,
                        ),
                        requiredTier: 5,
                        badgeText: gameState.activeBoss != null ? 'FIGHT!' : null,
                        onTap: () {
                          Navigator.of(context).pop();
                          if (gameState.activeBoss == null ||
                              gameState.activeBoss!.isDead) {
                            ref.read(gameStateProvider.notifier).spawnAlienBoss();
                          }
                        },
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Category 2: Upgrades & Trophies
                    _buildCategoryHeader(
                      'UPGRADES & TROPHIES',
                      Icons.auto_awesome_rounded,
                      const Color(0xFFBD00FF),
                    ),
                    const SizedBox(height: 8),
                    _buildHubGrid([
                      _HubItemData(
                        title: 'Super Upgrades',
                        subtitle: 'Spend Purple Gems',
                        icon: Icons.account_tree_rounded,
                        color: GameTheme.neonPurple,
                        isUnlocked: UserGrowthService.isFeatureUnlocked(
                          GameFeature.techTree,
                          highestTier: gameState.highestTierUnlocked,
                        ),
                        requiredTier: 4,
                        onTap: () => _openModal(context, const SkillTreeModal()),
                      ),
                      _HubItemData(
                        title: 'Artifacts Vault',
                        subtitle: 'Permanent Super Buffs',
                        icon: Icons.auto_awesome_rounded,
                        color: const Color(0xFFBD00FF),
                        isUnlocked: UserGrowthService.isFeatureUnlocked(
                          GameFeature.relics,
                          highestTier: gameState.highestTierUnlocked,
                        ),
                        requiredTier: 6,
                        onTap: () => _openModal(context, const RelicsModal()),
                      ),
                      _HubItemData(
                        title: 'Trophies',
                        subtitle: 'Claim Free Gems',
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFFFFD700),
                        isUnlocked: UserGrowthService.isFeatureUnlocked(
                          GameFeature.achievements,
                          highestTier: gameState.highestTierUnlocked,
                        ),
                        requiredTier: 5,
                        badgeCount: gameState.unclaimedAchievementsCount,
                        onTap: () => _openModal(context, const AchievementsModal()),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // Category 3: Free Gifts & Shop
                    _buildCategoryHeader(
                      'FREE GIFTS & SHOP',
                      Icons.card_giftcard_rounded,
                      const Color(0xFFFFD700),
                    ),
                    const SizedBox(height: 8),
                    _buildHubGrid([
                      _HubItemData(
                        title: 'Free Daily Gifts',
                        subtitle: 'Day 1 - 7 Streak',
                        icon: Icons.calendar_month_rounded,
                        color: const Color(0xFFFFD700),
                        isUnlocked: UserGrowthService.isFeatureUnlocked(
                          GameFeature.dailyCalendar,
                          highestTier: gameState.highestTierUnlocked,
                        ),
                        requiredTier: 3,
                        badgeText: gameState.canClaimDailyReward ? 'CLAIM' : null,
                        onTap: () => _openModal(context, const DailyCalendarModal()),
                      ),
                      _HubItemData(
                        title: 'Lucky Wheel',
                        subtitle: 'Spin for Free Prizes',
                        icon: Icons.blur_circular_rounded,
                        color: const Color(0xFF00F5FF),
                        isUnlocked: UserGrowthService.isFeatureUnlocked(
                          GameFeature.roulette,
                          highestTier: gameState.highestTierUnlocked,
                        ),
                        requiredTier: 4,
                        badgeText: gameState.canSpinFree ? 'FREE!' : null,
                        onTap: () => _openModal(context, const WormholeRouletteModal()),
                      ),
                      _HubItemData(
                        title: 'Item Shop',
                        subtitle: 'Boosters & Gem Packs',
                        icon: Icons.storefront_rounded,
                        color: const Color(0xFFFF9900),
                        isUnlocked: UserGrowthService.isFeatureUnlocked(
                          GameFeature.cosmicStore,
                          highestTier: gameState.highestTierUnlocked,
                        ),
                        requiredTier: 7,
                        onTap: () => _openModal(context, const CosmicStoreModal()),
                      ),
                      _HubItemData(
                        title: 'Restart for 2X',
                        subtitle: 'Permanent Double Money',
                        icon: Icons.restart_alt_rounded,
                        color: GameTheme.neonMagenta,
                        isUnlocked: UserGrowthService.isFeatureUnlocked(
                          GameFeature.prestige,
                          highestTier: gameState.highestTierUnlocked,
                          lifetimeCredits: gameState.lifetimeCredits,
                        ),
                        requiredTier: 7,
                        onTap: () {
                          _openModal(
                            context,
                            PrestigeModal(
                              state: gameState,
                              onPrestige: () {
                                ref.read(gameStateProvider.notifier).performGalacticPrestige();
                              },
                              onPrestigeDoubled: () {
                                ref.read(gameStateProvider.notifier).performGalacticPrestige(doubleYield: true);
                              },
                            ),
                          );
                        },
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            // Bottom Dismiss Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'RETURN TO FLIGHT CIRCUIT',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openModal(BuildContext context, Widget modal) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => modal,
    );
  }

  Widget _buildCommandHeader(
      BuildContext context, GameState state, CommanderRankInfo rank) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha(180),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(20))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rank.color.withAlpha(40),
              border: Border.all(color: rank.color, width: 1.4),
            ),
            child: Icon(rank.icon, color: rank.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'STARFLEET COMMAND HUB',
                      style: TextStyle(
                        color: rank.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Rank ${rank.rank} • ${rank.title} | Highest Fleet: Tier ${state.highestTierUnlocked}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildHubGrid(List<_HubItemData> items) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 68,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isUnlocked = item.isUnlocked;
        final Color themeColor = isUnlocked ? item.color : Colors.white24;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isUnlocked ? item.onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFF131B32).withAlpha(220)
                  : Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUnlocked
                    ? themeColor.withAlpha(90)
                    : Colors.white12,
                width: 1.1,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: themeColor.withAlpha(25),
                        blurRadius: 10,
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Icon Badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColor.withAlpha(35),
                    border: Border.all(color: themeColor.withAlpha(120), width: 1.1),
                  ),
                  child: Icon(
                    isUnlocked ? item.icon : Icons.lock_outline_rounded,
                    color: themeColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isUnlocked
                            ? item.subtitle
                            : 'Unlocks Tier ${item.requiredTier}',
                        style: TextStyle(
                          color: isUnlocked ? Colors.white60 : Colors.white24,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Notification Badge
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0055),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0055).withAlpha(140),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: Text(
                      '${item.badgeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else if (item.badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withAlpha(120),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: Text(
                      item.badgeText!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
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
}

class _HubItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final int requiredTier;
  final int? badgeCount;
  final String? badgeText;
  final VoidCallback onTap;

  const _HubItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    this.requiredTier = 1,
    this.badgeCount,
    this.badgeText,
    required this.onTap,
  });
}
