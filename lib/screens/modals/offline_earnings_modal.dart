import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../services/ad_manager.dart';
import '../../utils/number_formatter.dart';
import '../../utils/game_theme.dart';

/// Modal popup welcoming back the player with calculated offline income.
class OfflineEarningsModal extends StatelessWidget {
  final OfflineEarningsResult result;
  final VoidCallback onClaimRegular;
  final VoidCallback onClaimDoubled;

  const OfflineEarningsModal({
    super.key,
    required this.result,
    required this.onClaimRegular,
    required this.onClaimDoubled,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        decoration: GameTheme.glassCard(
          borderColor: GameTheme.neonCyan,
          backgroundColor: const Color(0xFF0F172A).withAlpha((0.95 * 255).round()),
          radius: 24,
          glow: true,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Cosmic Header Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GameTheme.neonCyan.withAlpha((0.15 * 255).round()),
                boxShadow: GameTheme.neonGlow(GameTheme.neonCyan, blur: 16),
              ),
              child: const Icon(
                Icons.hourglass_bottom_rounded,
                color: GameTheme.neonCyan,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'WELCOME BACK, COMMANDER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GameTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'While you were away for ${NumberFormatter.formatSeconds(result.cappedSeconds)}, your automated fleet was hard at work!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GameTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Income Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: GameTheme.backgroundVoid,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: GameTheme.neonGold.withAlpha((0.4 * 255).round()),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'OFFLINE INCOME GENERATED',
                    style: TextStyle(
                      color: GameTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    NumberFormatter.formatCredits(result.coinsEarned),
                    style: const TextStyle(
                      color: GameTheme.neonGold,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: GameTheme.neonGold, blurRadius: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rewarded 2x Claim CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.neonGold,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.movie_creation_rounded, size: 20),
                label: Text(
                  'WATCH AD & 2X (${NumberFormatter.formatCredits(result.coinsEarned * 2)})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                onPressed: () {
                  AdManager().showRewardedAd(
                    onUserEarnedReward: () {
                      onClaimDoubled();
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Regular Claim Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: GameTheme.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  onClaimRegular();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Claim Regular Amount',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
