import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../services/user_growth_service.dart';
import '../../utils/number_formatter.dart';

/// Compact circuit engineering console for Speed Upgrades, On-Track Hyper Boost Pads, and Multi-Laser Gates.
class FlightOpsStrip extends StatelessWidget {
  final GameState gameState;
  final GlobalKey? fleetSpeedKey;
  final VoidCallback onUpgradeFleetSpeed;
  final VoidCallback onUnlockBoostPad;
  final VoidCallback onUpgradeBoostPad;
  final VoidCallback onUnlockFinishLine;
  final VoidCallback onEvolveTrack;

  const FlightOpsStrip({
    super.key,
    required this.gameState,
    this.fleetSpeedKey,
    required this.onUpgradeFleetSpeed,
    required this.onUnlockBoostPad,
    required this.onUpgradeBoostPad,
    required this.onUnlockFinishLine,
    required this.onEvolveTrack,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSpeedMaxed = gameState.isFleetSpeedMaxed;
    final bool canAffordSpeed = !isSpeedMaxed &&
        gameState.credits >= gameState.fleetSpeedUpgradeCost;

    final bool isPadsUnlocked = UserGrowthService.isFeatureUnlocked(
      GameFeature.hyperPads,
      highestTier: gameState.highestTierUnlocked,
    );
    final double? nextPadInstallCost = gameState.nextBoostPadInstallCost;
    final bool canAffordInstallPad = isPadsUnlocked &&
        nextPadInstallCost != null &&
        gameState.credits >= nextPadInstallCost;
    final bool canAffordUpgradePad = isPadsUnlocked &&
        gameState.isBoostPadCountMaxed &&
        gameState.boostPadLevel < 10 &&
        gameState.credits >= gameState.boostPadUpgradeCost;

    final bool isGatesUnlocked = UserGrowthService.isFeatureUnlocked(
      GameFeature.multiLaserGates,
      highestTier: gameState.highestTierUnlocked,
    );
    final double? nextGateCost = gameState.nextFinishLineCost;
    final bool canAffordGate = isGatesUnlocked &&
        nextGateCost != null &&
        gameState.credits >= nextGateCost;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 0.9),
      ),
      child: Row(
        children: [
          // 1. Fleet Engine Speed Upgrade Button (Tier 1)
          Expanded(
            child: InkWell(
              key: fleetSpeedKey,
              borderRadius: BorderRadius.circular(8),
              onTap: onUpgradeFleetSpeed,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isSpeedMaxed
                      ? const Color(0xFFFFD700).withAlpha((0.15 * 255).round())
                      : (canAffordSpeed
                          ? const Color(0xFF00F0FF)
                              .withAlpha((0.15 * 255).round())
                          : Colors.white.withAlpha((0.04 * 255).round())),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSpeedMaxed
                        ? const Color(0xFFFFD700)
                        : (canAffordSpeed
                            ? const Color(0xFF00F0FF)
                            : Colors.white12),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      color: isSpeedMaxed
                          ? const Color(0xFFFFD700)
                          : (canAffordSpeed
                              ? const Color(0xFF00F0FF)
                              : Colors.white38),
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSpeedMaxed
                                ? 'SPEED MAX'
                                : 'SPEED Lv.${gameState.fleetSpeedLevel}',
                            style: TextStyle(
                              color: isSpeedMaxed
                                  ? const Color(0xFFFFD700)
                                  : (canAffordSpeed
                                      ? const Color(0xFF00F0FF)
                                      : Colors.white60),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isSpeedMaxed
                                ? 'MAX LEVEL'
                                : NumberFormatter.formatCredits(
                                    gameState.fleetSpeedUpgradeCost),
                            style: TextStyle(
                              color: isSpeedMaxed
                                  ? const Color(0xFFFFD700)
                                  : (canAffordSpeed
                                      ? const Color(0xFFFFD700)
                                      : Colors.white38),
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
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
            ),
          ),

          const SizedBox(width: 5),

          // 2. Hyper-Pads Install (Pad 1 & 2) & Power Upgrade Button
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (!isPadsUnlocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF131B3A),
                      content: Text(
                        '🔒 Hyper-Pads unlock at Ship Tier ${UserGrowthService.getRequiredTier(GameFeature.hyperPads)}!',
                        style: const TextStyle(color: Color(0xFFFFB703)),
                      ),
                      duration: const Duration(milliseconds: 900),
                    ),
                  );
                  return;
                }
                if (!gameState.isBoostPadCountMaxed) {
                  onUnlockBoostPad();
                } else {
                  onUpgradeBoostPad();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                decoration: BoxDecoration(
                  color: !isPadsUnlocked
                      ? Colors.white.withAlpha((0.02 * 255).round())
                      : (!gameState.isBoostPadCountMaxed
                          ? (canAffordInstallPad
                              ? const Color(0xFF00F0FF)
                                  .withAlpha((0.20 * 255).round())
                              : Colors.white.withAlpha((0.04 * 255).round()))
                          : (gameState.boostPadLevel >= 10
                              ? const Color(0xFF00FF88)
                                  .withAlpha((0.15 * 255).round())
                              : (canAffordUpgradePad
                                  ? const Color(0xFF00F0FF)
                                      .withAlpha((0.20 * 255).round())
                                  : Colors.white
                                      .withAlpha((0.04 * 255).round())))),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: !isPadsUnlocked
                        ? Colors.white12
                        : (!gameState.isBoostPadCountMaxed
                            ? (canAffordInstallPad
                                ? const Color(0xFF00F0FF)
                                : Colors.white12)
                            : (gameState.boostPadLevel >= 10
                                ? const Color(0xFF00FF88)
                                : (canAffordUpgradePad
                                    ? const Color(0xFF00F0FF)
                                    : Colors.white12))),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      !isPadsUnlocked
                          ? Icons.lock_outline_rounded
                          : (gameState.boostPadCount > 0
                              ? Icons.flash_on_rounded
                              : Icons.add_circle_outline_rounded),
                      color: !isPadsUnlocked
                          ? Colors.white24
                          : (gameState.boostPadLevel >= 10
                              ? const Color(0xFF00FF88)
                              : (canAffordInstallPad || canAffordUpgradePad
                                  ? const Color(0xFF00F0FF)
                                  : Colors.white38)),
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !isPadsUnlocked
                                ? 'PADS [T${UserGrowthService.getRequiredTier(GameFeature.hyperPads)}]'
                                : (!gameState.isBoostPadCountMaxed
                                    ? 'INSTALL PAD #${gameState.boostPadCount + 1}'
                                    : (gameState.boostPadLevel >= 10
                                        ? 'PADS MAX'
                                        : 'PADS Lv.${gameState.boostPadLevel}')),
                            style: TextStyle(
                              color: !isPadsUnlocked
                                  ? Colors.white38
                                  : (gameState.boostPadLevel >= 10
                                      ? const Color(0xFF00FF88)
                                      : (canAffordInstallPad ||
                                              canAffordUpgradePad
                                          ? const Color(0xFF00F0FF)
                                          : Colors.white60)),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            !isPadsUnlocked
                                ? 'TIER ${UserGrowthService.getRequiredTier(GameFeature.hyperPads)}'
                                : (!gameState.isBoostPadCountMaxed
                                    ? (nextPadInstallCost != null
                                        ? NumberFormatter.formatCredits(
                                            nextPadInstallCost)
                                        : 'MAX')
                                    : (gameState.boostPadLevel >= 10
                                        ? 'MAX BOOST'
                                        : NumberFormatter.formatCredits(
                                            gameState.boostPadUpgradeCost))),
                            style: TextStyle(
                              color: !isPadsUnlocked
                                  ? Colors.white24
                                  : (gameState.boostPadLevel >= 10
                                      ? const Color(0xFF00FF88)
                                      : (canAffordInstallPad ||
                                              canAffordUpgradePad
                                          ? const Color(0xFFFFD700)
                                          : Colors.white38)),
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
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
            ),
          ),

          const SizedBox(width: 5),

          // 3. Laser Finish Lines / Track Ascension Evolution Button
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (!isGatesUnlocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF131B3A),
                      content: Text(
                        '🔒 Laser Gates unlock at Ship Tier ${UserGrowthService.getRequiredTier(GameFeature.multiLaserGates)}!',
                        style: const TextStyle(color: Color(0xFFFFB703)),
                      ),
                      duration: const Duration(milliseconds: 900),
                    ),
                  );
                  return;
                }
                if (gameState.finishLinesCount >= 4) {
                  onEvolveTrack();
                } else {
                  onUnlockFinishLine();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                decoration: BoxDecoration(
                  color: !isGatesUnlocked
                      ? Colors.white.withAlpha((0.02 * 255).round())
                      : (gameState.finishLinesCount >= 4
                          ? (gameState.credits >=
                                  gameState.trackEvolutionCost
                              ? const Color(0xFFFFD700)
                                  .withAlpha((0.25 * 255).round())
                              : const Color(0xFF00FF88)
                                  .withAlpha((0.15 * 255).round()))
                          : (canAffordGate
                              ? const Color(0xFFFFD700)
                                  .withAlpha((0.18 * 255).round())
                              : Colors.white
                                  .withAlpha((0.04 * 255).round()))),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: !isGatesUnlocked
                        ? Colors.white12
                        : (gameState.finishLinesCount >= 4
                            ? (gameState.credits >=
                                    gameState.trackEvolutionCost
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF00FF88))
                            : (canAffordGate
                                ? const Color(0xFFFFD700)
                                : Colors.white12)),
                    width: gameState.finishLinesCount >= 4 &&
                            gameState.credits >=
                                gameState.trackEvolutionCost
                        ? 1.5
                        : 0.9,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      !isGatesUnlocked
                          ? Icons.lock_outline_rounded
                          : (gameState.finishLinesCount >= 4
                              ? Icons.auto_awesome_rounded
                              : Icons.flag_rounded),
                      color: !isGatesUnlocked
                          ? Colors.white24
                          : (gameState.finishLinesCount >= 4
                              ? const Color(0xFFFFD700)
                              : (canAffordGate
                                  ? const Color(0xFFFFD700)
                                  : Colors.white38)),
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !isGatesUnlocked
                                ? 'GATES [T${UserGrowthService.getRequiredTier(GameFeature.multiLaserGates)}]'
                                : (gameState.finishLinesCount >= 4
                                    ? 'EVOLVE T${gameState.circuitTier + 1}'
                                    : 'GATES ${gameState.finishLinesCount}/4'),
                            style: TextStyle(
                              color: !isGatesUnlocked
                                  ? Colors.white38
                                  : (gameState.finishLinesCount >= 4
                                      ? const Color(0xFFFFD700)
                                      : (canAffordGate
                                          ? const Color(0xFFFFD700)
                                          : Colors.white60)),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            !isGatesUnlocked
                                ? 'TIER ${UserGrowthService.getRequiredTier(GameFeature.multiLaserGates)}'
                                : (gameState.finishLinesCount >= 4
                                    ? NumberFormatter.formatCredits(
                                        gameState.trackEvolutionCost)
                                    : (nextGateCost != null
                                        ? NumberFormatter.formatCredits(
                                            nextGateCost)
                                        : 'MAX')),
                            style: TextStyle(
                              color: !isGatesUnlocked
                                  ? Colors.white24
                                  : (gameState.finishLinesCount >= 4
                                      ? (gameState.credits >=
                                              gameState.trackEvolutionCost
                                          ? const Color(0xFFFFD700)
                                          : Colors.white60)
                                      : (canAffordGate
                                          ? const Color(0xFFFFD700)
                                          : Colors.white38)),
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
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
            ),
          ),
        ],
      ),
    );
  }
}
