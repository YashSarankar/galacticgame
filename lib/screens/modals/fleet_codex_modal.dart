import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_providers.dart';
import '../../models/ship_model.dart';
import '../../utils/game_theme.dart';
import '../../utils/number_formatter.dart';

/// Spacecraft Fleet Codex & 15-Tier Ship Encyclopedia Modal
class FleetCodexModal extends ConsumerStatefulWidget {
  const FleetCodexModal({super.key});

  @override
  ConsumerState<FleetCodexModal> createState() => _FleetCodexModalState();
}

class _FleetCodexModalState extends ConsumerState<FleetCodexModal> {
  int _selectedFilter = 0; // 0: All, 1: Discovered, 2: Locked
  int? _inspectedTier;

  static const List<String> _shipLoreDescriptions = [
    'Light reconnaissance scout equipped with standard ion propulsion.',
    'Agile star interceptor fitted with dual plasma thrusters for rapid maneuvers.',
    'Heavy escort vessel capable of enduring extreme asteroid density.',
    'Advanced stealth phantom with radar-absorbing dark matter plating.',
    'Tactical battle cruiser with high-efficiency warp coils.',
    'Heavy plasma frigate engineered for sector blockade breaches.',
    'Devastating orbital destroyer armed with pulse laser batteries.',
    'Frontline dreadnought class with reinforced energy shields.',
    'Dimensional flagship powered by sub-atomic quantum reactors.',
    'Colossal planetary titan with graviton-stabilized flight lanes.',
    'Apex predator of the deep void with hyper-charged ion accelerators.',
    'Legendary celestial war vessel capable of shattering rogue moons.',
    'Extraterrestrial scout retrieved from an ancient wormhole singularity.',
    'Pulsing magnetic saucer utilizing dark energy levitation.',
    'God-tier chronal flagship bending space-time to maximize fleet profits.',
  ];

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final highestTier = gameState.highestTierUnlocked;

    // Generate specs for all 15 catalog ships
    final allShips = List.generate(15, (index) => ShipModel.getTierSpec(index + 1));
    final discoveredCount = allShips.where((s) => s.tier <= highestTier).length;
    final double completionPercent = (discoveredCount / allShips.length) * 100;

    final filteredShips = allShips.where((s) {
      final isDiscovered = s.tier <= highestTier;
      if (_selectedFilter == 1) return isDiscovered;
      if (_selectedFilter == 2) return !isDiscovered;
      return true;
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GameTheme.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF00F0FF).withAlpha((0.5 * 255).round()),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withAlpha((0.15 * 255).round()),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.menu_book_rounded,
                    color: Color(0xFF00F0FF), size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'FLEET SPACECRAFT CODEX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon:
                      const Icon(Icons.close, color: Colors.white60, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress Header Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: GameTheme.backgroundVoid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00F0FF)
                        .withAlpha((0.25 * 255).round())),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'COLLECTION COMPLETION',
                              style: TextStyle(
                                color: Colors.white.withAlpha((0.7 * 255).round()),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$discoveredCount / 15 (${completionPercent.toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: discoveredCount / 15.0,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF00F0FF)),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Filter Tabs (ALL, DISCOVERED, LOCKED)
            Row(
              children: [
                _buildFilterTab(0, 'ALL (15)'),
                const SizedBox(width: 6),
                _buildFilterTab(1, 'UNLOCKED ($discoveredCount)'),
                const SizedBox(width: 6),
                _buildFilterTab(2, 'LOCKED (${15 - discoveredCount})'),
              ],
            ),
            const SizedBox(height: 10),

            // Ships Grid List
            Expanded(
              child: ListView.separated(
                itemCount: filteredShips.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {

                  final ship = filteredShips[index];
                  final isDiscovered = ship.tier <= highestTier;
                  final isInspected = _inspectedTier == ship.tier;
                  final lore = _shipLoreDescriptions[
                      (ship.tier - 1).clamp(0, _shipLoreDescriptions.length - 1)];

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: isDiscovered
                        ? () {
                            setState(() {
                              _inspectedTier =
                                  isInspected ? null : ship.tier;
                            });
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDiscovered
                            ? (isInspected
                                ? ship.glowColor.withAlpha((0.2 * 255).round())
                                : GameTheme.backgroundVoid)
                            : Colors.black.withAlpha((0.4 * 255).round()),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDiscovered
                              ? (isInspected
                                  ? ship.glowColor
                                  : ship.glowColor.withAlpha((0.35 * 255).round()))
                              : Colors.white10,
                          width: isInspected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Ship Sprite Preview
                              Container(
                                width: 44,
                                height: 44,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDiscovered
                                      ? ship.glowColor
                                          .withAlpha((0.15 * 255).round())
                                      : Colors.white.withAlpha((0.05 * 255).round()),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: isDiscovered
                                    ? Image.asset(
                                        ship.spriteAsset,
                                        fit: BoxFit.contain,
                                      )
                                    : const Icon(
                                        Icons.lock_rounded,
                                        color: Colors.white30,
                                        size: 20,
                                      ),
                              ),
                              const SizedBox(width: 10),

                              // Ship Name & Tier
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: isDiscovered
                                                ? ship.glowColor
                                                    .withAlpha((0.25 * 255).round())
                                                : Colors.white10,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'T${ship.tier}',
                                            style: TextStyle(
                                              color: isDiscovered
                                                  ? ship.glowColor
                                                  : Colors.white38,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            isDiscovered
                                                ? ship.name
                                                : 'Classified Titan',
                                            style: TextStyle(
                                              color: isDiscovered
                                                  ? Colors.white
                                                  : Colors.white38,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // Quick Stats Strip
                                    if (isDiscovered) ...[
                                      Row(
                                        children: [
                                          _buildStatBadge(
                                            Icons.monetization_on_rounded,
                                            const Color(0xFFFFD700),
                                            '${NumberFormatter.formatCredits(ship.calculateIncomePayout())}/lap',
                                          ),
                                          const SizedBox(width: 8),
                                          _buildStatBadge(
                                            Icons.speed_rounded,
                                            const Color(0xFF00F0FF),
                                            '${ship.baseSpeed.toInt()} km/s',
                                          ),
                                          const SizedBox(width: 8),
                                          _buildStatBadge(
                                            Icons.flash_on_rounded,
                                            const Color(0xFFFF0055),
                                            '${ship.calculateLaserDamage().toInt()} DPS',
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      Text(
                                        'Unlock by merging two Tier ${ship.tier - 1} ships',
                                        style: const TextStyle(
                                          color: Colors.white30,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              if (isDiscovered)
                                Icon(
                                  isInspected
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                            ],
                          ),

                          // Expanded Lore View when tapped
                          if (isInspected && isDiscovered) ...[
                            const SizedBox(height: 8),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 6),
                            Text(
                              lore,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final bool isSelected = _selectedFilter == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedFilter = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00F0FF).withAlpha((0.25 * 255).round())
                : GameTheme.backgroundVoid,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF00F0FF) : Colors.white12,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00F0FF) : Colors.white54,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 10.5),
        const SizedBox(width: 2.5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
