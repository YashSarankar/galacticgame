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
              // Dark Matter Singularity Icon & Guide Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: GameTheme.neonPurple.withAlpha((0.2 * 255).round()),
                      boxShadow: GameTheme.neonGlow(GameTheme.neonPurple, blur: 20),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: GameTheme.neonPurple,
                      size: 34,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline_rounded,
                        color: Color(0xFF00F0FF), size: 24),
                    tooltip: 'How Prestige Works',
                    onPressed: () => _showPrestigeGuideDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

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
              const SizedBox(height: 6),

              const Text(
                'Collapse your fleet into cosmic Dark Matter gems to permanently supercharge your entire civilization across all sectors!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: GameTheme.textSecondary,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),

              // Visual Keep vs Reset Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF070A14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF00FF88), size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 10.5, color: Colors.white70),
                              children: [
                                TextSpan(
                                  text: 'YOU KEEP PERMANENTLY: ',
                                  style: TextStyle(
                                    color: Color(0xFF00FF88),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      'Dark Matter, Tech Tree Nodes, Ancient Relics, Mastery Perks & Sector Level.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.restart_alt_rounded,
                            color: Color(0xFFFF0055), size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 10.5, color: Colors.white70),
                              children: [
                                TextSpan(
                                  text: 'RESETS FOR REBIRTH: ',
                                  style: TextStyle(
                                    color: Color(0xFFFF0055),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      'Active hangar ships and soft credits (you will re-grow 10x faster!).',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Prestige Stats Overview
              Container(
                padding: const EdgeInsets.all(14),
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
                    const Divider(color: GameTheme.cardBorder, height: 14),
                    _buildStatRow(
                      'Lifetime Earnings',
                      NumberFormatter.formatCredits(state.lifetimeCredits),
                    ),
                    const Divider(color: GameTheme.cardBorder, height: 14),
                    _buildStatRow(
                      'Dark Matter Yield',
                      NumberFormatter.formatDarkMatter(darkMatterYield * state.prestigeDarkMatterMultiplier),
                      highlightColor: GameTheme.neonPurple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Prestige Mastery Perks Roadmap
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GameTheme.backgroundVoid,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withAlpha((0.3 * 255).round()),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            color: Color(0xFFFFD700), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'PRESTIGE MASTERY PERKS',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildMasteryItem('P1: Starter Ship Tier 2',
                        state.career.prestigeCount >= 1),
                    const SizedBox(height: 4),
                    _buildMasteryItem('P2: +10% Lucky Clone Chance',
                        state.career.prestigeCount >= 2),
                    const SizedBox(height: 4),
                    _buildMasteryItem('P3: 1.5x Dark Matter Boost',
                        state.career.prestigeCount >= 3),
                    const SizedBox(height: 4),
                    _buildMasteryItem('P5: Permanent +25% Income Surge',
                        state.career.prestigeCount >= 5),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2X Video Reward Prestige Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canPrestige ? const Color(0xFFFF0055) : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
                  label: Text(
                    canPrestige
                        ? 'WATCH AD & 2X ASCEND (+${NumberFormatter.formatDarkMatter(darkMatterYield * state.prestigeDarkMatterMultiplier * 2.0)})'
                        : 'MINIMUM 1 DARK MATTER REQUIRED',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
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
                height: 42,
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
                    'Standard Reset (+${NumberFormatter.formatDarkMatter(darkMatterYield * state.prestigeDarkMatterMultiplier)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel Protocol',
                  style: TextStyle(color: GameTheme.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrestigeGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Color(0xFF00F0FF), size: 22),
            SizedBox(width: 8),
            Text(
              'PRESTIGE GUIDE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideStep(
                '1. What is Galactic Prestige?',
                'Prestige resets your active fleet and soft credits in exchange for valuable Dark Matter gems based on your lifetime earnings.',
                Icons.autorenew_rounded,
                const Color(0xFF00F0FF),
              ),
              const SizedBox(height: 12),
              _buildGuideStep(
                '2. What Do You Keep Permanently?',
                '• All Dark Matter Gems\n• All Tech Upgrade Matrix Nodes\n• All Ancient Alien Relics\n• All Career Achievements\n• Permanent Store Boosters\n• Prestige Mastery Super Perks',
                Icons.verified_user_rounded,
                const Color(0xFF00FF88),
              ),
              const SizedBox(height: 12),
              _buildGuideStep(
                '3. Strategic Commander Tip',
                'Each Prestige gives you permanent Mastery Perks (like starting with Tier 2 ships). Use the 2X Ad button to double your Dark Matter yield every time!',
                Icons.lightbulb_rounded,
                const Color(0xFFFFD700),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'UNDERSTOOD, COMMANDER',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(
      String title, String body, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF070A14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: GameTheme.textSecondary, fontSize: 12.5),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlightColor ?? GameTheme.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildMasteryItem(String title, bool isUnlocked) {
    return Row(
      children: [
        Icon(
          isUnlocked
              ? Icons.check_circle_rounded
              : Icons.lock_outline_rounded,
          color: isUnlocked ? const Color(0xFF00FF88) : Colors.white30,
          size: 13,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: isUnlocked ? Colors.white : Colors.white38,
            fontSize: 10,
            fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
