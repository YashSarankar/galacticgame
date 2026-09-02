import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/expedition_model.dart';
import '../../providers/game_providers.dart';
import '../../services/ad_manager.dart';
import '../../utils/game_theme.dart';
import '../../utils/number_formatter.dart';


/// Modal bottom sheet for interstellar fleet expeditions and star sector sorties
class ExpeditionsModal extends ConsumerStatefulWidget {
  const ExpeditionsModal({super.key});

  @override
  ConsumerState<ExpeditionsModal> createState() => _ExpeditionsModalState();
}

class _ExpeditionsModalState extends ConsumerState<ExpeditionsModal> {
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    // Live 1-second countdown ticker for expedition timers
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
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
          color: Color(0xFF070A14),
          borderRadius: BorderRadius.all(Radius.circular(24)),
          border: Border.fromBorderSide(
            BorderSide(color: Color(0xFF00F0FF), width: 2.0),
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
                Icons.travel_explore_rounded,
                color: Color(0xFF00F0FF),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'SPACE EXPEDITIONS',
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

          // Overview Tagline
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: GameTheme.backgroundVoid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00F0FF).withAlpha((0.3 * 255).round()),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Send ships on missions for free Coins, Dark Matter & Relics!',
                    style: TextStyle(
                      color: GameTheme.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00F0FF), width: 1.0),
                  ),
                  child: Text(
                    'ACTIVE: ${gameState.expeditions.length}/4',
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),


          // Sector Cards List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: ExpeditionSector.catalog.length,
              itemBuilder: (context, index) {
                final sector = ExpeditionSector.catalog[index];
                final activeMission = gameState.expeditions.cast<ExpeditionMission?>().firstWhere(
                      (e) => e?.sectorId == sector.id,
                      orElse: () => null,
                    );
                return _buildSectorCard(
                  sector: sector,
                  mission: activeMission,
                  highestTierUnlocked: gameState.highestTierUnlocked,
                  onLaunch: (tier) {
                    final success = notifier.launchExpedition(sector.id, tier);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0B1426),
                          content: Text(
                            '🚀 Dispatched Tier $tier fleet on ${sector.name} Expedition!',
                            style: const TextStyle(
                              color: Color(0xFF00F0FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  onClaim: (missionId) {
                    final success = notifier.claimExpeditionReward(missionId);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0B2418),
                          content: Text(
                            '✨ ${sector.name} Expedition Rewards Collected!',
                            style: const TextStyle(
                              color: Color(0xFF00FF88),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  onSpeedUp: (missionId) {
                    AdManager().showRewardedAd(
                      onUserEarnedReward: () {
                        notifier.speedUpExpeditionWithAd(missionId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF15102A),
                            content: Text(
                              '⚡ Hyperdrive Boost! Expedition time reduced by 30 minutes.',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                              ),
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
        ],
      ),
    ),
    );
  }


  Widget _buildSectorCard({
    required ExpeditionSector sector,
    required ExpeditionMission? mission,
    required int highestTierUnlocked,
    required void Function(int tier) onLaunch,
    required void Function(String missionId) onClaim,
    required void Function(String missionId) onSpeedUp,
  }) {
    final bool isUnlocked = highestTierUnlocked >= sector.minShipTier;
    final sectorColor = Color(sector.sectorColorValue);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1224),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sectorColor.withAlpha((0.35 * 255).round()),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: sectorColor.withAlpha((0.08 * 255).round()),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Sector Info Row
          Row(
            children: [
              // Sector Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sectorColor.withAlpha((0.15 * 255).round()),
                  border: Border.all(color: sectorColor, width: 1.0),
                ),
                child: Center(
                  child: Image.asset(
                    sector.iconAsset,
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.star_rounded,
                      color: sectorColor,
                      size: 22,
                    ),

                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title & Hazard
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sector.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: sectorColor.withAlpha((0.2 * 255).round()),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: sectorColor, width: 0.8),
                          ),
                          child: Text(
                            sector.hazardRating,
                            style: TextStyle(
                              color: sectorColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sector.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Rewards Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: GameTheme.backgroundVoid,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRewardBadge(
                    Icons.monetization_on_rounded,
                    '${NumberFormatter.formatCredits(sector.baseCreditsMultiplier, decimals: 0)}x MIN',
                    const Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 8),
                  if (sector.darkMatterReward > 0) ...[
                    _buildRewardBadge(
                      Icons.auto_awesome_rounded,
                      '+${sector.darkMatterReward.toInt()} DM',
                      const Color(0xFF9D4EDD),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (sector.relicShardsReward > 0) ...[
                    _buildRewardBadge(
                      Icons.diamond_rounded,
                      '+${sector.relicShardsReward} Shards',
                      const Color(0xFF00F0FF),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (sector.bonusBlueprintTier > 0)
                    _buildRewardBadge(
                      Icons.inventory_2_rounded,
                      'T${sector.bonusBlueprintTier} Crate',
                      const Color(0xFFFF0055),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Action Status Deck
          if (mission != null) ...[
            if (mission.isReadyToClaim) ...[
              // Ready to Claim
              ElevatedButton(
                onPressed: () => onClaim(mission.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'COLLECT REWARDS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),

              ),
            ] else ...[
              // In Progress with Timer & Speedup
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_rounded,
                            color: Color(0xFF00F0FF),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mission.formattedRemainingTime,
                            style: const TextStyle(
                              color: Color(0xFF00F0FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Assigned: Tier ${mission.assignedShipTier}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: mission.progressRatio,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(sectorColor),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () => onSpeedUp(mission.id),
                    icon: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Color(0xFFFFD700),
                      size: 14,
                    ),
                    label: const Text(
                      'SPEED UP -30 MIN (AD)',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFD700), width: 1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: const Size(double.infinity, 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            if (!isUnlocked) ...[
              // Locked
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.05 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'REQUIRES TIER ${sector.minShipTier} SPACECRAFT',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Available to Launch
              ElevatedButton(
                onPressed: () => onLaunch(highestTierUnlocked),
                style: ElevatedButton.styleFrom(
                  backgroundColor: sectorColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch_rounded, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'START MISSION (TIER $highestTierUnlocked • ${NumberFormatter.formatSeconds(sector.durationSeconds)})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ],
        ],
      ),
    );
  }




  Widget _buildRewardBadge(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
