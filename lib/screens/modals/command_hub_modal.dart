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
/// Centralizes all tycoon subsystems into an organized, futuristic tactical console.
class CommandHubModal extends ConsumerStatefulWidget {
  const CommandHubModal({super.key});

  @override
  ConsumerState<CommandHubModal> createState() => _CommandHubModalState();
}

class _CommandHubModalState extends ConsumerState<CommandHubModal> {
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'MISSIONS',
    'UPGRADES',
    'REWARDS & SHOP',
  ];

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final rank = UserGrowthService.getCommanderRank(gameState.highestTierUnlocked);

    final allItems = _buildAllHubItems(context, gameState, ref);
    final filteredItems = _getFilteredItems(allItems, _selectedCategoryIndex);

    final bool isLuckySpinUnlocked = UserGrowthService.isFeatureUnlocked(
      GameFeature.roulette,
      highestTier: gameState.highestTierUnlocked,
    );
    final bool isDailyGiftsUnlocked = UserGrowthService.isFeatureUnlocked(
      GameFeature.dailyCalendar,
      highestTier: gameState.highestTierUnlocked,
    );

    final bool showHeroBanner = (isLuckySpinUnlocked && gameState.canSpinFree) ||
        (isDailyGiftsUnlocked && gameState.canClaimDailyReward);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 760),
        decoration: BoxDecoration(
          color: const Color(0xFF090D1A).withAlpha(252),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: rank.color.withAlpha(180), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: rank.color.withAlpha(50),
              blurRadius: 28,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withAlpha(230),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Holographic Command Header
            _buildCommandHeader(context, gameState, rank),

            // Quick Category Filter Tabs with Notification Badges
            _buildCategoryTabs(rank.color, allItems),

            // Scrollable Systems Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured Priority Action Banner (Only displayed on the first primary tab)
                    if (_selectedCategoryIndex == 0 && showHeroBanner)
                      _buildHeroPriorityBanner(
                        context: context,
                        gameState: gameState,
                        isLuckySpinUnlocked: isLuckySpinUnlocked,
                        isDailyGiftsUnlocked: isDailyGiftsUnlocked,
                      ),

                    // List of Systems
                    _buildHubListView(filteredItems),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Bottom Dismiss Bar
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandHeader(
      BuildContext context, GameState state, CommanderRankInfo rank) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha(190),
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
                Text(
                  'STARFLEET COMMAND HUB',
                  style: TextStyle(
                    color: rank.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
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

  int _getCategoryBadgeCount(List<_HubItemData> allItems, int categoryIndex) {
    String categoryKey;
    if (categoryIndex == 0) {
      categoryKey = 'missions';
    } else if (categoryIndex == 1) {
      categoryKey = 'upgrades';
    } else {
      categoryKey = 'rewards';
    }

    final categoryItems =
        allItems.where((item) => item.category == categoryKey && item.isUnlocked);
    int total = 0;
    for (final item in categoryItems) {
      if (item.badgeCount != null && item.badgeCount! > 0) {
        total += item.badgeCount!;
      } else if (item.badgeText != null) {
        total += 1;
      }
    }
    return total;
  }

  Widget _buildCategoryTabs(Color rankColor, List<_HubItemData> allItems) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          final int badgeCount = _getCategoryBadgeCount(allItems, index);

          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? rankColor.withAlpha((0.25 * 255).round())
                    : Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? rankColor : Colors.white12,
                  width: isSelected ? 1.4 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: rankColor.withAlpha((0.3 * 255).round()),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _categories[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (badgeCount > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0055),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF0055).withAlpha(160),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroPriorityBanner({
    required BuildContext context,
    required GameState gameState,
    required bool isLuckySpinUnlocked,
    required bool isDailyGiftsUnlocked,
  }) {
    final List<Widget> banners = [];

    // 1. Daily Calendar Supply Drop Ready Banner
    if (isDailyGiftsUnlocked && gameState.canClaimDailyReward) {
      banners.add(
        _buildPriorityCard(
          context: context,
          title: 'DAILY REWARD READY!',
          badgeText: 'DAY ${gameState.currentLoginDay}',
          subtitle: 'Streak supply drop with credits & gems waiting!',
          buttonText: 'CLAIM',
          primaryColor: const Color(0xFFFFD700),
          gradientColors: const [Color(0xFF382600), Color(0xFF181000)],
          icon: Icons.card_giftcard_rounded,
          onTap: () => _openModal(context, const DailyCalendarModal()),
        ),
      );
    }

    // 2. Lucky Spin Wheel Ready Banner
    if (isLuckySpinUnlocked && gameState.canSpinFree) {
      banners.add(
        _buildPriorityCard(
          context: context,
          title: 'LUCKY WHEEL READY!',
          badgeText: 'FREE SPIN',
          subtitle: 'Win up to 100X credits, ships & dark matter!',
          buttonText: 'SPIN',
          primaryColor: const Color(0xFF00F5FF),
          gradientColors: const [Color(0xFF003049), Color(0xFF001424)],
          icon: Icons.blur_circular_rounded,
          onTap: () => _openModal(context, const WormholeRouletteModal()),
        ),
      );
    }

    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: banners
          .map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: b,
              ))
          .toList(),
    );
  }

  Widget _buildPriorityCard({
    required BuildContext context,
    required String title,
    required String badgeText,
    required String subtitle,
    required String buttonText,
    required Color primaryColor,
    required List<Color> gradientColors,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withAlpha(200), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(70),
            blurRadius: 14,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Left Glowing Circular Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withAlpha(45),
                    border: Border.all(
                      color: primaryColor.withAlpha(160),
                      width: 1.3,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 11),

                // Middle Text & Badge Block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                                letterSpacing: 0.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(40),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: primaryColor.withAlpha(120),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2.5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Right Action Pill Button
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withAlpha(200),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(130),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonText,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.black,
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHubListView(List<_HubItemData> items) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isUnlocked = item.isUnlocked;
        final Color themeColor = isUnlocked ? item.color : Colors.white24;

        return Material(
          color: isUnlocked
              ? const Color(0xFF111728).withAlpha(230)
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked
                    ? themeColor.withAlpha(90)
                    : Colors.white12,
                width: 1.1,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: themeColor.withAlpha(20),
                        blurRadius: 10,
                      )
                    ]
                  : null,
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onTap: isUnlocked
                  ? item.onTap
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF131B3A),
                          content: Text(
                            '🔒 ${item.title} unlocks at Spacecraft Tier ${item.requiredTier}!',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          duration: const Duration(milliseconds: 800),
                        ),
                      );
                    },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColor.withAlpha(35),
                  border: Border.all(
                      color: themeColor.withAlpha(120), width: 1.2),
                ),
                child: Icon(
                  isUnlocked ? item.icon : Icons.lock_outline_rounded,
                  color: themeColor,
                  size: 20,
                ),
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              subtitle: Text(
                isUnlocked
                    ? item.subtitle
                    : 'Unlocks at Spacecraft Tier ${item.requiredTier}',
                style: TextStyle(
                  color: isUnlocked ? Colors.white70 : Colors.white24,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUnlocked &&
                      item.badgeCount != null &&
                      item.badgeCount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
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
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else if (isUnlocked && item.badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
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
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isUnlocked ? Colors.white38 : Colors.white12,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SizedBox(
        width: double.infinity,
        height: 42,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withAlpha(15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  List<_HubItemData> _getFilteredItems(
      List<_HubItemData> allItems, int categoryIndex) {
    if (categoryIndex == 0) {
      return allItems.where((item) => item.category == 'missions').toList();
    }
    if (categoryIndex == 1) {
      return allItems.where((item) => item.category == 'upgrades').toList();
    }
    if (categoryIndex == 2) {
      return allItems.where((item) => item.category == 'rewards').toList();
    }
    return allItems;
  }

  List<_HubItemData> _buildAllHubItems(
      BuildContext context, GameState gameState, WidgetRef ref) {
    return [
      // Missions & Space
      _HubItemData(
        title: 'Daily Tasks',
        subtitle: 'Earn Easy Rewards',
        icon: Icons.flag_rounded,
        color: GameTheme.neonGreen,
        category: 'missions',
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
        category: 'missions',
        isUnlocked: UserGrowthService.isFeatureUnlocked(
          GameFeature.codex,
          highestTier: gameState.highestTierUnlocked,
        ),
        requiredTier: UserGrowthService.getRequiredTier(GameFeature.codex),
        onTap: () => _openModal(context, const FleetCodexModal()),
      ),
      _HubItemData(
        title: 'Treasure Hunts',
        subtitle: 'Send Ships for Loot',
        icon: Icons.travel_explore_rounded,
        color: const Color(0xFF00F0FF),
        category: 'missions',
        isUnlocked: UserGrowthService.isFeatureUnlocked(
          GameFeature.expeditions,
          highestTier: gameState.highestTierUnlocked,
        ),
        requiredTier: UserGrowthService.getRequiredTier(GameFeature.expeditions),
        badgeCount: UserGrowthService.isFeatureUnlocked(
                GameFeature.expeditions,
                highestTier: gameState.highestTierUnlocked)
            ? gameState.readyExpeditionsCount
            : 0,
        onTap: () => _openModal(context, const ExpeditionsModal()),
      ),
      _HubItemData(
        title: 'Boss Battle',
        subtitle: gameState.activeBoss != null
            ? 'Boss Fight in Progress!'
            : 'Fight Giant Alien',
        icon: Icons.radar_rounded,
        color: const Color(0xFFFF0055),
        category: 'missions',
        isUnlocked: UserGrowthService.isFeatureUnlocked(
          GameFeature.bossBeacon,
          highestTier: gameState.highestTierUnlocked,
        ),
        requiredTier: UserGrowthService.getRequiredTier(GameFeature.bossBeacon),
        badgeText: (UserGrowthService.isFeatureUnlocked(
                    GameFeature.bossBeacon,
                    highestTier: gameState.highestTierUnlocked) &&
                gameState.activeBoss != null)
            ? 'FIGHT!'
            : null,
        onTap: () {
          Navigator.of(context).pop();
          if (gameState.activeBoss == null || gameState.activeBoss!.isDead) {
            ref.read(gameStateProvider.notifier).spawnAlienBoss();
          }
        },
      ),

      // Upgrades & Tech
      _HubItemData(
        title: 'Super Upgrades',
        subtitle: 'Spend Purple Gems',
        icon: Icons.account_tree_rounded,
        color: GameTheme.neonPurple,
        category: 'upgrades',
        isUnlocked: UserGrowthService.isFeatureUnlocked(
          GameFeature.techTree,
          highestTier: gameState.highestTierUnlocked,
        ),
        requiredTier: UserGrowthService.getRequiredTier(GameFeature.techTree),
        onTap: () => _openModal(context, const SkillTreeModal()),
      ),
      _HubItemData(
        title: 'Artifacts Vault',
        subtitle: 'Permanent Super Buffs',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFFBD00FF),
        category: 'upgrades',
        isUnlocked: UserGrowthService.isFeatureUnlocked(
          GameFeature.relics,
          highestTier: gameState.highestTierUnlocked,
        ),
        requiredTier: UserGrowthService.getRequiredTier(GameFeature.relics),
        onTap: () => _openModal(context, const RelicsModal()),
      ),
      _HubItemData(
        title: 'Trophies',
        subtitle: 'Claim Free Gems',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFFD700),
        category: 'upgrades',
        isUnlocked: UserGrowthService.isFeatureUnlocked(
          GameFeature.achievements,
          highestTier: gameState.highestTierUnlocked,
        ),
        requiredTier: UserGrowthService.getRequiredTier(GameFeature.achievements),
        badgeCount: UserGrowthService.isFeatureUnlocked(
                GameFeature.achievements,
                highestTier: gameState.highestTierUnlocked)
            ? gameState.unclaimedAchievementsCount
            : 0,
        onTap: () => _openModal(context, const AchievementsModal()),
      ),

      // Rewards & Shop
      _HubItemData(
        title: 'Free Daily Gifts',
        subtitle: 'Day 1 - 7 Streak',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFFFFD700),
        category: 'rewards',
        isUnlocked: UserGrowthService.isFeatureUnlocked(
          GameFeature.dailyCalendar,
          highestTier: gameState.highestTierUnlocked,
        ),
        requiredTier: UserGrowthService.getRequiredTier(GameFeature.dailyCalendar),
        badgeText: (UserGrowthService.isFeatureUnlocked(
                    GameFeature.dailyCalendar,
                    highestTier: gameState.highestTierUnlocked) &&
                gameState.canClaimDailyReward)
            ? 'CLAIM'
            : null,
        onTap: () => _openModal(context, const DailyCalendarModal()),
      ),
      _HubItemData(
        title: 'Lucky Wheel',
        subtitle: 'Spin for Free Prizes',
        icon: Icons.blur_circular_rounded,
        color: const Color(0xFF00F5FF),
        category: 'rewards',
        isUnlocked: UserGrowthService.isFeatureUnlocked(
          GameFeature.roulette,
          highestTier: gameState.highestTierUnlocked,
        ),
        requiredTier: UserGrowthService.getRequiredTier(GameFeature.roulette),
        badgeText: (UserGrowthService.isFeatureUnlocked(
                    GameFeature.roulette,
                    highestTier: gameState.highestTierUnlocked) &&
                gameState.canSpinFree)
            ? 'FREE!'
            : null,
        onTap: () => _openModal(context, const WormholeRouletteModal()),
      ),
      _HubItemData(
        title: 'Item Shop',
        subtitle: 'Boosters & Gem Packs',
        icon: Icons.storefront_rounded,
        color: const Color(0xFFFF9900),
        category: 'rewards',
        isUnlocked: UserGrowthService.isFeatureUnlocked(
          GameFeature.cosmicStore,
          highestTier: gameState.highestTierUnlocked,
        ),
        requiredTier: UserGrowthService.getRequiredTier(GameFeature.cosmicStore),
        onTap: () => _openModal(context, const CosmicStoreModal()),
      ),
      _HubItemData(
        title: 'Restart for 2X',
        subtitle: 'Permanent Double Money',
        icon: Icons.restart_alt_rounded,
        color: GameTheme.neonMagenta,
        category: 'rewards',
        isUnlocked: UserGrowthService.isFeatureUnlocked(
          GameFeature.prestige,
          highestTier: gameState.highestTierUnlocked,
          lifetimeCredits: gameState.lifetimeCredits,
        ),
        requiredTier: UserGrowthService.getRequiredTier(GameFeature.prestige),
        onTap: () {
          _openModal(
            context,
            PrestigeModal(
              state: gameState,
              onPrestige: () {
                ref.read(gameStateProvider.notifier).performGalacticPrestige();
              },
              onPrestigeDoubled: () {
                ref
                    .read(gameStateProvider.notifier)
                    .performGalacticPrestige(doubleYield: true);
              },
            ),
          );
        },
      ),
    ];
  }
}

class _HubItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String category;
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
    required this.category,
    required this.isUnlocked,
    this.requiredTier = 1,
    this.badgeCount,
    this.badgeText,
    required this.onTap,
  });
}
