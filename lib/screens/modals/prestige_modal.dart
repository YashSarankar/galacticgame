import 'package:flutter/material.dart';
import '../../services/ad_manager.dart';
import '../../utils/number_formatter.dart';
import '../../utils/game_theme.dart';
import '../../models/game_state.dart';

/// Modal for Galactic Reset (Prestige System).
class PrestigeModal extends StatelessWidget {
  final GameState state;
  final VoidCallback onPrestige;
  final VoidCallback onPrestigeDoubled;

  const PrestigeModal({
    super.key,
    required this.state,
    required this.onPrestige,
    required this.onPrestigeDoubled,
  });

  @override
  Widget build(BuildContext context) {
    final double darkMatterYield = state.potentialPrestigeDarkMatter;
    final bool canPrestige = darkMatterYield >= 1.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: GameTheme.glassCard(
          borderColor: GameTheme.neonPurple,
          backgroundColor: const Color(0xFF0F172A).withAlpha((0.95 * 255).round()),
          radius: 24,
          glow: true,
        ),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dark Matter Singularity Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameTheme.neonPurple.withAlpha((0.2 * 255).round()),
                  boxShadow: GameTheme.neonGlow(GameTheme.neonPurple, blur: 20),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: GameTheme.neonPurple,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'GALACTIC RESET PROTOCOL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GameTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'Reset your active fleet and soft credits to harvest cosmic Dark Matter from the singularity. Dark Matter permanently powers up your civilization across all sectors!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GameTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Prestige Stats Overview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GameTheme.backgroundVoid,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: GameTheme.neonPurple.withAlpha((0.4 * 255).round()),
                  ),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Sector Rank',
                      'Sector ${state.career.sectorLevel}',
                    ),
                    const Divider(color: GameTheme.cardBorder, height: 16),
                    _buildStatRow(
                      'Lifetime Earnings',
                      NumberFormatter.formatCredits(state.lifetimeCredits),
                    ),
                    const Divider(color: GameTheme.cardBorder, height: 16),
                    _buildStatRow(
                      'Dark Matter Yield',
                      NumberFormatter.formatDarkMatter(darkMatterYield),
                      highlightColor: GameTheme.neonPurple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (!canPrestige) ...[
                const Text(
                  'Requires at least \$1.00M lifetime earnings to harvest Dark Matter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GameTheme.neonCrimson,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2X Ad Prestige Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canPrestige ? GameTheme.neonMagenta : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.movie_creation_rounded, size: 20),
                  label: Text(
                    'WATCH AD & 2X YIELD (${NumberFormatter.formatDarkMatter(darkMatterYield * 2)})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: canPrestige
                      ? () {
                          AdManager().showRewardedAd(
                            onUserEarnedReward: () {
                              onPrestigeDoubled();
                              Navigator.of(context).pop();
                            },
                          );
                        }
                      : null,
                ),
              ),
              const SizedBox(height: 10),

              // Regular Reset Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: canPrestige ? GameTheme.neonPurple : Colors.grey,
                    side: BorderSide(
                      color: canPrestige ? GameTheme.neonPurple : Colors.grey.shade800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: canPrestige
                      ? () {
                          onPrestige();
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: Text(
                    'Standard Reset (+${NumberFormatter.formatDarkMatter(darkMatterYield)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel Protocol',
                  style: TextStyle(color: GameTheme.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: GameTheme.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlightColor ?? GameTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
