import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_providers.dart';
import '../../utils/number_formatter.dart';
import '../../utils/game_theme.dart';

/// Modal displaying the Permanent Dark Matter Tech Tree.
class SkillTreeModal extends ConsumerWidget {
  const SkillTreeModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final darkMatterBalance = gameState.darkMatter;
    final skills = gameState.career.skills;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: GameTheme.glassCard(
          borderColor: GameTheme.neonGold,
          backgroundColor: const Color(0xFF0F172A).withAlpha((0.96 * 255).round()),
          radius: 24,
          glow: true,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header: Dark Matter Balance
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GameTheme.neonGold.withAlpha((0.2 * 255).round()),
                  ),
                  child: const Icon(
                    Icons.account_tree_rounded,
                    color: GameTheme.neonGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'TECH UPGRADE MATRIX',
                    style: TextStyle(
                      color: GameTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

            // Dark Matter Counter Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: GameTheme.backgroundVoid,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: GameTheme.neonPurple.withAlpha((0.5 * 255).round()),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: GameTheme.neonPurple,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Available Dark Matter: ',
                    style: TextStyle(color: GameTheme.textSecondary, fontSize: 13),
                  ),
                  Text(
                    NumberFormatter.formatDarkMatter(darkMatterBalance),
                    style: const TextStyle(
                      color: GameTheme.neonPurple,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Skill List
            Expanded(
              child: ListView.separated(
                itemCount: skills.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final skill = skills[index];
                  final bool isMaxed = skill.isMaxed;
                  final double cost = skill.currentUpgradeCost;
                  final bool canAfford = !isMaxed && darkMatterBalance >= cost;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: GameTheme.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMaxed
                            ? GameTheme.neonGreen.withAlpha((0.6 * 255).round())
                            : GameTheme.cardBorder,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Skill Icon
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: GameTheme.backgroundVoid,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            skill.iconAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.bolt,
                              color: GameTheme.neonGold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Skill Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      skill.title,
                                      style: const TextStyle(
                                        color: GameTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMaxed
                                          ? GameTheme.neonGreen
                                              .withAlpha((0.2 * 255).round())
                                          : GameTheme.backgroundVoid,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isMaxed
                                          ? 'MAX'
                                          : 'Lv. ${skill.level}/${skill.maxLevel}',
                                      style: TextStyle(
                                        color: isMaxed
                                            ? GameTheme.neonGreen
                                            : GameTheme.neonCyan,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),
                              Text(
                                skill.description,
                                style: const TextStyle(
                                  color: GameTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Upgrade CTA
                              Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isMaxed
                                          ? Colors.grey.shade800
                                          : (canAfford ? GameTheme.neonGold : Colors.grey.shade800),
                                      foregroundColor: canAfford ? Colors.black : Colors.white60,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: canAfford
                                        ? () {
                                            ref
                                                .read(gameStateProvider.notifier)
                                                .upgradeSkill(skill.id);
                                          }
                                        : null,
                                    child: Text(
                                      isMaxed
                                          ? 'COMPLETED'
                                          : 'UPGRADE (${NumberFormatter.formatDarkMatter(cost)})',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
