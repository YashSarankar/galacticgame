import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../models/ship_model.dart';
import '../../providers/ad_state_provider.dart';
import '../../services/user_growth_service.dart';
import '../../utils/number_formatter.dart';

/// Streamlined Command Dock containing Sell Bin, Auto & Sort tools, BUY SHIP Hero CTA, 2X Speed Boost, and Command Hub.
class BottomCommandDock extends StatelessWidget {
  final GameState gameState;
  final AdBoostState adState;
  final bool canAffordShip;
  final double nextBuyCost;
  final int dropTier;
  final GlobalKey? buyShipKey;
  final GlobalKey? sortButtonKey;
  final int hubBadgeCount;
  final Function(int slotIndex) onRecycleShip;
  final VoidCallback onAutoMergeTap;
  final VoidCallback onSortTap;
  final VoidCallback onBuyShipTap;
  final VoidCallback onSpeedBoostTap;
  final VoidCallback onCommandHubTap;

  const BottomCommandDock({
    super.key,
    required this.gameState,
    required this.adState,
    required this.canAffordShip,
    required this.nextBuyCost,
    required this.dropTier,
    this.buyShipKey,
    this.sortButtonKey,
    required this.hubBadgeCount,
    required this.onRecycleShip,
    required this.onAutoMergeTap,
    required this.onSortTap,
    required this.onBuyShipTap,
    required this.onSpeedBoostTap,
    required this.onCommandHubTap,
  });

  @override
  Widget build(BuildContext context) {
    final rank =
        UserGrowthService.getCommanderRank(gameState.highestTierUnlocked);

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
            onAcceptWithDetails: (details) => onRecycleShip(details.data),
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
                requiredTier:
                    UserGrowthService.getRequiredTier(GameFeature.autoMerge),
                onTap: onAutoMergeTap,
              ),
              const SizedBox(height: 3),
              _buildMiniDockButton(
                key: sortButtonKey,
                icon: Icons.sort_rounded,
                label: 'SORT',
                color: const Color(0xFF00F0FF),
                isUnlocked: UserGrowthService.isFeatureUnlocked(
                  GameFeature.autoSort,
                  highestTier: gameState.highestTierUnlocked,
                ),
                requiredTier:
                    UserGrowthService.getRequiredTier(GameFeature.autoSort),
                onTap: onSortTap,
              ),
            ],
          ),
          const SizedBox(width: 6),

          // 3. Center Hero CTA: BUY SHIP (Evolves with Ship Tier & Upgrades)
          Builder(builder: (context) {
            final shipDef = ShipModel.create(dropTier);
            final Color tierColor =
                canAffordShip ? shipDef.glowColor : Colors.grey.shade800;
            final Color textColor = canAffordShip
                ? (tierColor.computeLuminance() > 0.4
                    ? Colors.black
                    : Colors.white)
                : Colors.white54;

            return Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  key: buyShipKey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tierColor,
                    foregroundColor: textColor,
                    elevation: canAffordShip ? 6 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: canAffordShip ? onBuyShipTap : null,
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
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.rocket_rounded,
                            size: 18,
                          ),
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

          // 4. Stackable 2X Speed Boost Button (Video Ad Rewarded, +15m up to 60m)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onSpeedBoostTap,
            child: Container(
              width: 52,
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
                            ? adState.formattedBoostTime
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
                  if (adState.canStackBoost)
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Colors.black, size: 7),
                            Text(
                              adState.isSpeedBoostActive ? '+15m' : 'AD',
                              style: const TextStyle(
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
            onTap: onCommandHubTap,
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
                      Icon(Icons.grid_view_rounded,
                          color: rank.color, size: 18),
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
                              color: const Color(0xFFFF0055)
                                  .withAlpha((0.6 * 255).round()),
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
              // Lock hint handled by parent
            },
      child: Container(
        width: 38,
        height: 20,
        decoration: BoxDecoration(
          color: isUnlocked
              ? color.withAlpha((0.15 * 255).round())
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isUnlocked
                ? color.withAlpha((0.5 * 255).round())
                : Colors.white12,
            width: 0.8,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUnlocked ? icon : Icons.lock_outline_rounded,
                  color: isUnlocked ? color : Colors.white24,
                  size: 10,
                ),
                const SizedBox(width: 2),
                Text(
                  isUnlocked ? label : 'T$requiredTier',
                  style: TextStyle(
                    color: isUnlocked ? color : Colors.white24,
                    fontSize: 7.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
