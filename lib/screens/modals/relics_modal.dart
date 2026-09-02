import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/relic_model.dart';
import '../../providers/game_providers.dart';
import '../../utils/game_theme.dart';

/// Modal bottom sheet displaying the player's Ancient Alien Relic Matrix & Artifact Vault
class RelicsModal extends ConsumerWidget {
  const RelicsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF070913),
          borderRadius: BorderRadius.all(Radius.circular(24)),
          border: Border.fromBorderSide(
            BorderSide(color: GameTheme.neonPurple, width: 2.0),
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
                  Icons.auto_awesome_rounded,
                  color: GameTheme.neonPurple,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ANCIENT RELIC MATRIX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 6),
            const Text(
              'Collect and upgrade cosmic artifacts found in deep space expeditions & boss drops.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),

            const SizedBox(height: 12),

            // Total Artifact Matrix Buffs Summary Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: GameTheme.neonPurple.withAlpha((0.15 * 255).round()),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: GameTheme.neonPurple.withAlpha((0.5 * 255).round()),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBadge(
                    label: 'SPEED',
                    value:
                        '+${((notifier.relicSpeedMultiplier - 1.0) * 100).toInt()}%',
                    color: GameTheme.neonCyan,
                  ),
                  _buildStatBadge(
                    label: 'INCOME',
                    value:
                        '+${((notifier.relicIncomeMultiplier - 1.0) * 100).toInt()}%',
                    color: GameTheme.neonGreen,
                  ),
                  _buildStatBadge(
                    label: 'DARK MATTER',
                    value:
                        '+${((notifier.relicDarkMatterMultiplier - 1.0) * 100).toInt()}%',
                    color: GameTheme.neonPurple,
                  ),
                  _buildStatBadge(
                    label: 'TAP DMG',
                    value:
                        '+${((notifier.relicBossTapDamageBonus - 1.0) * 100).toInt()}%',
                    color: const Color(0xFFFF0055),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 6),

            // Relic List
            Expanded(
              child: ListView.separated(
                itemCount: gameState.relics.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final relic = gameState.relics[index];
                  return _buildRelicCard(context, relic, notifier);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildRelicCard(
    BuildContext context,
    RelicModel relic,
    GameEconomyNotifier notifier,
  ) {
    final bool isUnlocked = relic.isUnlocked;
    final bool canUpgrade = relic.canUpgrade;
    final int needed = relic.shardsNeededForNext;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? GameTheme.cardSurface
            : Colors.black.withAlpha((0.6 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? relic.rarityColor : Colors.white12,
          width: isUnlocked ? 1.5 : 1.0,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: relic.rarityColor.withAlpha((0.15 * 255).round()),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // Relic Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: relic.rarityColor.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUnlocked ? relic.rarityColor : Colors.white24,
                width: 1.2,
              ),
            ),
            child: Icon(
              relic.icon,
              color: isUnlocked ? relic.rarityColor : Colors.white38,
              size: 26,
            ),
          ),

          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        relic.name,
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white54,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color:
                            relic.rarityColor.withAlpha((0.25 * 255).round()),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: relic.rarityColor, width: 0.8),
                      ),
                      child: Text(
                        relic.rarityTitle,
                        style: TextStyle(
                          color: relic.rarityColor,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  relic.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),


                // Shards Progress
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (relic.shards / needed).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            canUpgrade ? GameTheme.neonGreen : relic.rarityColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${relic.shards}/$needed Shards',
                      style: TextStyle(
                        color: canUpgrade ? GameTheme.neonGreen : Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Level / Upgrade Action
          Column(
            children: [
              Text(
                'LVL ${relic.level}/${relic.maxLevel}',
                style: TextStyle(
                  color: isUnlocked ? relic.rarityColor : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canUpgrade ? GameTheme.neonGreen : Colors.white10,
                    foregroundColor:
                        canUpgrade ? Colors.black : Colors.white38,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: canUpgrade ? 4 : 0,
                  ),
                  onPressed: canUpgrade
                      ? () => notifier.upgradeRelic(relic.id)
                      : null,
                  child: Text(
                    canUpgrade ? 'UPGRADE' : (isUnlocked ? 'ACTIVE' : 'LOCKED'),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: canUpgrade ? Colors.black : Colors.white38,
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
}
