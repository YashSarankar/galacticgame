import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_providers.dart';
import '../../utils/number_formatter.dart';
import '../../utils/game_theme.dart';
import '../../models/mission_model.dart';

/// Modal for checking and claiming Sector Missions.
class MissionsModal extends ConsumerWidget {
  const MissionsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final allMissions = gameState.career.missions;

    // Sort: Unclaimed (completed first, then in-progress), then claimed
    final List<MissionModel> sortedMissions = List.from(allMissions)
      ..sort((a, b) {
        if (a.isClaimed != b.isClaimed) {
          return a.isClaimed ? 1 : -1;
        }
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? -1 : 1;
        }
        return 0;
      });

    final int unclaimedCount =
        allMissions.where((m) => m.isCompleted && !m.isClaimed).length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: GameTheme.glassCard(
          borderColor: GameTheme.neonGreen,
          backgroundColor: const Color(0xFF0F172A).withAlpha((0.96 * 255).round()),
          radius: 24,
          glow: true,
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GameTheme.neonGreen.withAlpha((0.2 * 255).round()),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: GameTheme.neonGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'SECTOR DIRECTIVES',
                          style: TextStyle(
                            color: GameTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unclaimedCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: GameTheme.neonGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unclaimedCount READY',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: GameTheme.textSecondary,
                    size: 22,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Missions List
            Expanded(
              child: ListView.separated(
                itemCount: sortedMissions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final mission = sortedMissions[index];
                  final bool isDone = mission.isCompleted;
                  final bool isClaimed = mission.isClaimed;

                  final double dynamicReward = (mission.rewardCoins *
                          ref.read(gameStateProvider.notifier).relicIncomeMultiplier)
                      .floorToDouble();

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isClaimed
                          ? GameTheme.backgroundVoid
                              .withAlpha((0.6 * 255).round())
                          : GameTheme.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isClaimed
                            ? GameTheme.cardBorder
                                .withAlpha((0.4 * 255).round())
                            : (isDone
                                ? GameTheme.neonGreen
                                : GameTheme.cardBorder),
                        width: (isDone && !isClaimed) ? 1.5 : 1.0,
                      ),
                      boxShadow: (isDone && !isClaimed)
                          ? [
                              BoxShadow(
                                color: GameTheme.neonGreen
                                    .withAlpha((0.2 * 255).round()),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                mission.title,
                                style: TextStyle(
                                  color: isClaimed
                                      ? GameTheme.textMuted
                                      : GameTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  decoration: isClaimed
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${NumberFormatter.formatCredits(dynamicReward)} / +${NumberFormatter.formatDarkMatter(mission.rewardDarkMatter)}',
                              style: TextStyle(
                                color: isClaimed
                                    ? GameTheme.textMuted
                                    : GameTheme.neonGold,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mission.description,
                          style: TextStyle(
                            color: isClaimed
                                ? GameTheme.textMuted
                                : GameTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Progress Bar & Claim Button
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: mission.progressRatio,
                                    backgroundColor: GameTheme.backgroundVoid,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isClaimed
                                          ? Colors.grey.shade700
                                          : (isDone
                                              ? GameTheme.neonGreen
                                              : GameTheme.neonCyan),
                                    ),
                                    minHeight: 5,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isClaimed
                                        ? 'COMPLETED'
                                        : '${mission.currentProgress.toInt()} / ${mission.targetValue.toInt()}',
                                    style: TextStyle(
                                      color: isClaimed
                                          ? GameTheme.textMuted
                                          : GameTheme.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Claim CTA
                            SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isClaimed
                                      ? Colors.grey.shade900
                                      : (isDone
                                          ? GameTheme.neonGreen
                                          : Colors.grey.shade800),
                                  foregroundColor: (isDone && !isClaimed)
                                      ? Colors.black
                                      : Colors.white38,
                                  elevation: (isDone && !isClaimed) ? 4 : 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: (isDone && !isClaimed)
                                    ? () {
                                        ref
                                            .read(gameStateProvider.notifier)
                                            .claimMission(mission.id);
                                      }
                                    : null,
                                child: Text(
                                  isClaimed
                                      ? 'CLAIMED'
                                      : (isDone ? 'CLAIM' : 'LOCKED'),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}
