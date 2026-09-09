import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_state.dart';
import '../../models/store_item_model.dart';
import '../../providers/game_providers.dart';
import '../../services/ad_manager.dart';
import '../../utils/number_formatter.dart';

/// Modern Futuristic Cosmic Store & Black Market Modal
class CosmicStoreModal extends ConsumerStatefulWidget {
  const CosmicStoreModal({super.key});

  @override
  ConsumerState<CosmicStoreModal> createState() => _CosmicStoreModalState();
}

class _CosmicStoreModalState extends ConsumerState<CosmicStoreModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: const Color(0xFF080C1B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD700).withAlpha((0.65 * 255).round()),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withAlpha((0.15 * 255).round()),
              blurRadius: 28,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFF9D4EDD).withAlpha((0.12 * 255).round()),
              blurRadius: 36,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFFD700), Color(0xFF9D4EDD)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withAlpha((0.4 * 255).round()),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BLACK MARKET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Direct singularity dark market uplink',
                          style: TextStyle(
                            color: Colors.white.withAlpha((0.5 * 255).round()),
                            fontSize: 10.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Holographic Currency Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1226),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withAlpha((0.1 * 255).round()),
                  ),
                ),
                child: Row(
                  children: [
                    // Credits Chip
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on_rounded,
                              color: Color(0xFFFFD700), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CREDITS',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 8.5, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  NumberFormatter.formatCredits(gameState.credits),
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
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
                    Container(width: 1, height: 24, color: Colors.white12),
                    const SizedBox(width: 10),
                    // Dark Matter Chip
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              color: Color(0xFFBD00FF), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DARK MATTER',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 8.5, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  NumberFormatter.formatDarkMatter(gameState.darkMatter),
                                  style: const TextStyle(
                                    color: Color(0xFFBD00FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Tab Bar Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0F22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFFFFD700).withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFFFFD700),
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                  labelPadding: EdgeInsets.zero,
                  tabs: const [
                    Tab(text: 'TIME WARPS'),
                    Tab(text: 'DARK MATTER'),
                    Tab(text: 'VIP & BOOSTS'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Tab Views with Vault Products
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. Time Warps
                  _buildCategoryList(
                    items: StoreItem.catalog
                        .where((i) => i.category == StoreCategory.timeWarp)
                        .toList(),
                    gameState: gameState,
                    notifier: notifier,
                  ),

                  // 2. Dark Matter Conversion
                  _buildCategoryList(
                    items: StoreItem.catalog
                        .where((i) => i.category == StoreCategory.darkMatter)
                        .toList(),
                    gameState: gameState,
                    notifier: notifier,
                  ),

                  // 3. VIP Drone & Permanent Boosters
                  _buildCategoryList(
                    items: StoreItem.catalog
                        .where((i) =>
                            i.category == StoreCategory.vipDrone ||
                            i.category == StoreCategory.permanentBooster)
                        .toList(),
                    gameState: gameState,
                    notifier: notifier,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList({
    required List<StoreItem> items,
    required GameState gameState,
    required GameEconomyNotifier notifier,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isAlreadyOwned =
            gameState.unlockedPermanentBoosters.contains(item.id) ||
                (item.id == 'drone_permanent' && gameState.isDronePermanent);

        final Color itemColor = Color(item.colorValue);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F152E),
                itemColor.withAlpha((0.08 * 255).round()),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: itemColor.withAlpha((0.35 * 255).round()),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: itemColor.withAlpha((0.06 * 255).round()),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Glowing Icon Asset Container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      itemColor.withAlpha((0.3 * 255).round()),
                      itemColor.withAlpha((0.05 * 255).round()),
                    ],
                  ),
                  border: Border.all(color: itemColor, width: 1.2),
                ),
                child: Center(
                  child: Image.asset(
                    item.iconAsset,
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.star_rounded,
                      color: itemColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.category == StoreCategory.permanentBooster)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withAlpha((0.2 * 255).round()),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFFD700), width: 0.6),
                            ),
                            child: const Text(
                              'PERMANENT',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Buy CTA Action Button
              _buildCtaButton(
                context: context,
                item: item,
                isOwned: isAlreadyOwned,
                gameState: gameState,
                notifier: notifier,
                itemColor: itemColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCtaButton({
    required BuildContext context,
    required StoreItem item,
    required bool isOwned,
    required GameState gameState,
    required GameEconomyNotifier notifier,
    required Color itemColor,
  }) {
    if (isOwned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00FF88).withAlpha((0.15 * 255).round()),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF00FF88), width: 1.0),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF00FF88), size: 12),
            SizedBox(width: 4),
            Text(
              'ACTIVE',
              style: TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    if (item.isAdRewarded) {
      return ElevatedButton.icon(
        onPressed: () {
          AdManager().showRewardedAd(
            onUserEarnedReward: () {
              notifier.purchaseStoreItem(item);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF0B2418),
                  content: Text(
                    '✨ Activated ${item.title}!',
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
        icon: const Icon(Icons.play_circle_fill_rounded,
            color: Colors.black, size: 14),
        label: const Text(
          'FREE (AD)',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    // Google Play In-App Purchase item
    if (item.isIap && item.iapSku != null) {
      final iap = ref.read(iapServiceProvider);
      final String formattedPrice = iap.getPrice(
        item.iapSku!,
        fallback: item.iapFallbackPrice ?? '₹99.00',
      );

      return ElevatedButton.icon(
        onPressed: () {
          iap.purchaseConsumable(
            item.iapSku!,
            onSuccess: () {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF0F172A),
                  content: Text(
                    '🎉 Purchase Complete: ${item.title} delivered!',
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
            onFailure: (err) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF2A0F15),
                  content: Text(
                    '❌ Purchase failed: $err',
                    style: const TextStyle(
                      color: Color(0xFFFF0055),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.shopping_bag_rounded, size: 13, color: Colors.black),
        label: Text(
          formattedPrice,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    // Cost in Dark Matter or Credits
    final bool canAfford = item.costDarkMatter > 0
        ? gameState.darkMatter >= item.costDarkMatter
        : gameState.credits >= item.costCredits;

    final String priceLabel = item.costDarkMatter > 0
        ? '${item.costDarkMatter.toInt()} DM'
        : NumberFormatter.formatCredits(item.costCredits);

    final IconData priceIcon = item.costDarkMatter > 0
        ? Icons.auto_awesome_rounded
        : Icons.monetization_on_rounded;

    return ElevatedButton.icon(
      onPressed: canAfford
          ? () {
              final success = notifier.purchaseStoreItem(item);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0F172A),
                    content: Text(
                      '🎉 Purchased ${item.title}!',
                      style: const TextStyle(
                        color: Color(0xFF00FF88),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF2A0F15),
                  content: Text(
                    '❌ Insufficient ${item.costDarkMatter > 0 ? 'Dark Matter' : 'Credits'}!',
                    style: const TextStyle(
                      color: Color(0xFFFF0055),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
      icon: Icon(priceIcon, size: 12, color: canAfford ? Colors.black : Colors.white38),
      label: Text(
        priceLabel,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: canAfford ? Colors.black : Colors.white38,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford ? itemColor : Colors.white12,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
