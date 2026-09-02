import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_providers.dart';
import '../../models/achievement_model.dart';
import '../../utils/game_theme.dart';
import '../../utils/number_formatter.dart';



/// Milestone Achievements & Fleet Trophy Room Modal
class AchievementsModal extends ConsumerStatefulWidget {
  const AchievementsModal({super.key});

  @override
  ConsumerState<AchievementsModal> createState() => _AchievementsModalState();
}

class _AchievementsModalState extends ConsumerState<AchievementsModal> {
  int _selectedFilterIndex = 0; // 0: All, 1: Ready to Claim, 2: Completed

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);
    final achievements = gameState.achievements;

    final completedCount = achievements.where((a) => a.isCompleted).length;
    final claimableCount = achievements.where((a) => a.canClaim).length;

    List<AchievementModel> filteredList = achievements;
    if (_selectedFilterIndex == 1) {
      filteredList = achievements.where((a) => a.canClaim).toList();
    } else if (_selectedFilterIndex == 2) {
      filteredList = achievements.where((a) => a.isClaimed).toList();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        width: double.infinity,
        height: 600,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GameTheme.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD700).withAlpha((0.5 * 255).round()),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withAlpha((0.15 * 255).round()),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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
            const SizedBox(height: 10),

            // Header Row
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFFFFD700), size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'FLEET TROPHY ROOM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
            const SizedBox(height: 10),

            // Overview Stats Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: GameTheme.backgroundVoid,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      const Color(0xFFFFD700).withAlpha((0.3 * 255).round()),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TROPHIES: $completedCount / ${achievements.length}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (claimableCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88)
                            .withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF00FF88), width: 1.0),
                      ),
                      child: Text(
                        'CLAIMABLE: $claimableCount',
                        style: const TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Filter Tabs
            Row(
              children: [
                _buildFilterTab(0, 'ALL (${achievements.length})'),
                const SizedBox(width: 6),
                _buildFilterTab(1, 'READY ($claimableCount)'),
                const SizedBox(width: 6),
                _buildFilterTab(
                    2, 'CLAIMED (${achievements.where((a) => a.isClaimed).length})'),
              ],
            ),
            const SizedBox(height: 10),

            // List of Achievement Cards
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Text(
                        _selectedFilterIndex == 1
                            ? 'No trophies ready to claim yet.\nKeep merging and upgrading!'
                            : 'No completed trophies yet.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final ach = filteredList[index];
                        return _buildAchievementCard(ach, notifier);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFD700).withAlpha((0.25 * 255).round())
                : Colors.white.withAlpha((0.05 * 255).round()),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFD700) : Colors.white12,
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFFD700) : Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(
      AchievementModel ach, GameEconomyNotifier notifier) {
    final isClaimable = ach.canClaim;
    final isClaimed = ach.isClaimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isClaimable
            ? const Color(0xFF00FF88).withAlpha((0.10 * 255).round())
            : GameTheme.backgroundVoid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isClaimable
              ? const Color(0xFF00FF88)
              : (isClaimed ? Colors.white12 : const Color(0xFFFFD700).withAlpha((0.3 * 255).round())),
          width: isClaimable ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isClaimed ? Colors.white24 : const Color(0xFFFFD700),
                width: 1.0,
              ),
            ),
            child: Image.asset(
              ach.iconAsset,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),

          // Details & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ach.title,
                  style: TextStyle(
                    color: isClaimed ? Colors.white54 : Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ach.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: ach.progressRatio,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isClaimable
                                ? const Color(0xFF00FF88)
                                : const Color(0xFFFFD700),
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${NumberFormatter.formatCredits(ach.currentProgress, decimals: 0)} / ${NumberFormatter.formatCredits(ach.targetValue, decimals: 0)}',
                      style: TextStyle(
                        color: isClaimable
                            ? const Color(0xFF00FF88)
                            : Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Claim / Status Button
          if (isClaimable) ...[
            ElevatedButton(
              onPressed: () => notifier.claimAchievement(ach.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'CLAIM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '+${ach.rewardDarkMatter.toInt()} DM',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isClaimed) ...[
            const Icon(Icons.check_circle_rounded,
                color: Colors.white38, size: 22),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFBD00FF).withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFFBD00FF).withAlpha((0.5 * 255).round())),
              ),
              child: Text(
                '+${ach.rewardDarkMatter.toInt()} DM',
                style: const TextStyle(
                  color: Color(0xFFBD00FF),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
