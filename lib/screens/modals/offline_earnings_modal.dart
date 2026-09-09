import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/storage_service.dart';
import '../../services/ad_manager.dart';
import '../../services/sound_service.dart';
import '../../utils/number_formatter.dart';
import '../../utils/game_theme.dart';

/// Modal popup welcoming back the player with animated ticker and 2X boost rewards.
class OfflineEarningsModal extends StatefulWidget {
  final OfflineEarningsResult result;
  final bool isVip;
  final VoidCallback onClaimRegular;
  final VoidCallback onClaimDoubled;

  const OfflineEarningsModal({
    super.key,
    required this.result,
    this.isVip = false,
    required this.onClaimRegular,
    required this.onClaimDoubled,
  });

  @override
  State<OfflineEarningsModal> createState() => _OfflineEarningsModalState();
}

class _OfflineEarningsModalState extends State<OfflineEarningsModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    SoundService().playPrestigeSound();
    HapticFeedback.mediumImpact();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _countAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double baseCoins = widget.result.coinsEarned;
    final double doubledCoins = baseCoins * 2;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF090D1C),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: widget.isVip
                ? const Color(0xFF00FF88)
                : const Color(0xFFFFD700),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.isVip
                      ? const Color(0xFF00FF88)
                      : const Color(0xFFFFD700))
                  .withAlpha((0.35 * 255).round()),
              blurRadius: 36,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withAlpha(220),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Glowing Cosmic Header Icon
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.isVip
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFFD700),
                    const Color(0xFF0F172A),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isVip
                            ? const Color(0xFF00FF88)
                            : const Color(0xFFFFD700))
                        .withAlpha((0.5 * 255).round()),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                widget.isVip
                    ? Icons.workspace_premium_rounded
                    : Icons.hourglass_bottom_rounded,
                color: Colors.black,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),

            // 2. Title & Mission Dossier
            const Text(
              'WELCOME BACK, COMMANDER!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              'While you were offline for ${NumberFormatter.formatSeconds(widget.result.elapsedSeconds)}, your active fleet accumulated massive circuit revenue!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // 3. Animated Income Vault Display Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: GameTheme.backgroundVoid,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFFD700).withAlpha((0.35 * 255).round()),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded,
                          color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        'OFFLINE REVENUE HARVESTED',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _countAnimation,
                    builder: (context, child) {
                      final currentCoins = baseCoins * _countAnimation.value;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.monetization_on_rounded,
                              color: Color(0xFFFFD700), size: 24),
                          const SizedBox(width: 6),
                          Text(
                            NumberFormatter.formatCredits(currentCoins),
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Color(0xFFFFD700),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.06 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Vault Capacity Used: ${NumberFormatter.formatSeconds(widget.result.cappedSeconds)} (Efficiency: ${widget.isVip ? '40% VIP' : '20% Cadet'})',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. 2X Bounty CTA Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isVip
                      ? const Color(0xFF00FF88)
                      : const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shadowColor: (widget.isVip
                          ? const Color(0xFF00FF88)
                          : const Color(0xFFFFD700))
                      .withAlpha((0.6 * 255).round()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  SoundService().playPurchaseSound();
                  if (widget.isVip) {
                    widget.onClaimDoubled();
                    if (context.mounted) Navigator.of(context).pop(true);
                  } else {
                    AdManager().showRewardedAd(
                      onUserEarnedReward: () {
                        widget.onClaimDoubled();
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                    );
                  }
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isVip
                            ? Icons.stars_rounded
                            : Icons.play_circle_fill_rounded,
                        size: 20,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isVip
                            ? 'CLAIM 2X (VIP BONUS): +${NumberFormatter.formatCredits(doubledCoins)}'
                            : 'WATCH AD & 2X: +${NumberFormatter.formatCredits(doubledCoins)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 5. Regular Claim Button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white60,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  SoundService().playPurchaseSound();
                  widget.onClaimRegular();
                  Navigator.of(context).pop(true);
                },
                child: Text(
                  'Claim 1X (+${NumberFormatter.formatCredits(baseCoins)})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
