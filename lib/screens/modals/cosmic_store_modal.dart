import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/game_state.dart';
import '../../models/store_item_model.dart';
import '../../providers/game_providers.dart';
import '../../services/ad_manager.dart';
import '../../utils/game_theme.dart';
import '../../utils/number_formatter.dart';


/// Modal bottom sheet displaying the In-Game Cosmic Store & Black Market
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF070914),
          borderRadius: BorderRadius.all(Radius.circular(24)),
          border: Border.fromBorderSide(
            BorderSide(color: Color(0xFFFFD700), width: 2.0),
          ),
        ),
        child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: Color(0xFFFFD700),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'COSMIC VAULT & BLACK MARKET',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          // Currency Balance Summary Bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: GameTheme.backgroundVoid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withAlpha((0.3 * 255).round()),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: GameTheme.neonGold, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      NumberFormatter.formatCredits(gameState.credits),
                      style: const TextStyle(
                        color: GameTheme.neonGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 16, color: Colors.white24),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: GameTheme.neonPurple, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      NumberFormatter.formatDarkMatter(gameState.darkMatter),
                      style: const TextStyle(
                        color: GameTheme.neonPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Store Category Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFFFD700),
            indicatorWeight: 2,
            labelColor: const Color(0xFFFFD700),
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            tabs: const [
              Tab(text: 'TIME WARPS'),
              Tab(text: 'DARK MATTER'),
              Tab(text: 'VIP & BOOSTS'),
            ],
          ),
          const SizedBox(height: 8),

          // Tab Views
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

                // 2. Dark Matter
                _buildCategoryList(
                  items: StoreItem.catalog
                      .where((i) => i.category == StoreCategory.darkMatter)
                      .toList(),
                  gameState: gameState,
                  notifier: notifier,
                ),

                // 3. VIP Drone & Permanent Boosts
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
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isAlreadyOwned =
            gameState.unlockedPermanentBoosters.contains(item.id) ||
                (item.id == 'drone_permanent' && gameState.isDronePermanent);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1224),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(item.colorValue).withAlpha((0.35 * 255).round()),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // Item Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(item.colorValue).withAlpha((0.15 * 255).round()),
                  border: Border.all(color: Color(item.colorValue), width: 1.0),
                ),
                child: Center(
                  child: Image.asset(
                    item.iconAsset,
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.shopping_bag_rounded,
                      color: Color(item.colorValue),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Buy / Claim CTA Button
              if (isAlreadyOwned) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFF00FF88), width: 1.0),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ] else if (item.isAdRewarded) ...[
                ElevatedButton.icon(
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
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    final success = notifier.purchaseStoreItem(item);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0B2418),
                          content: Text(
                            '✨ Purchased ${item.title}!',
                            style: const TextStyle(
                              color: Color(0xFF00FF88),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF2A0D15),
                          content: Text(
                            '⚠️ Insufficient funds for this purchase!',
                            style: TextStyle(
                              color: Color(0xFFFF0055),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.costDarkMatter > 0
                        ? GameTheme.neonPurple
                        : GameTheme.neonGold,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.costDarkMatter > 0
                            ? Icons.auto_awesome_rounded
                            : Icons.monetization_on_rounded,
                        size: 13,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.costDarkMatter > 0
                            ? '${item.costDarkMatter.toInt()} DM'
                            : NumberFormatter.formatCredits(item.costCredits),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

