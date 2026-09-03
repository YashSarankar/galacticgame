import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_providers.dart';
import '../../services/localized_pricing_service.dart';
import '../../utils/game_theme.dart';



/// Interactive Remove Ads & VIP Commander License Popup Modal
class RemoveAdsModal extends ConsumerWidget {
  const RemoveAdsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final hasRemoved = gameState.hasRemovedAds;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: GameTheme.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD700),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withAlpha((0.3 * 255).round()),
              blurRadius: 28,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close Button Top Right
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white54, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // Holographic VIP Crown & No-Ads Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFFD700),
                    Color(0xFFFF8800),
                    Color(0xFF0F172A),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(0xFFFFD700).withAlpha((0.5 * 255).round()),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(
                Icons.block_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'REMOVE ADS & VIP PASS',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),

            const Text(
              'Unlock pure uninterrupted intergalactic conquest forever.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 18),

            // Benefits Checklist Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: GameTheme.backgroundVoid,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD700).withAlpha((0.25 * 255).round()),
                ),
              ),
              child: Column(
                children: [
                  _buildBenefitRow(
                    Icons.movie_filter_rounded,
                    const Color(0xFFFF0055),
                    'No Banner or Interstitial Ads',
                    'Zero interruptions during merging & racing.',
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  _buildBenefitRow(
                    Icons.bolt_rounded,
                    const Color(0xFF00F0FF),
                    '1-Tap Instant 2X Rewards',
                    'Instantly claim double offline & prestige yields.',
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  _buildBenefitRow(
                    Icons.card_giftcard_rounded,
                    const Color(0xFFFFD700),
                    '+500 Dark Matter & 5 Spins',
                    'Instant VIP welcome gift credited to your account.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (hasRemoved) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00FF88)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: Color(0xFF00FF88), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'VIP AD-FREE ACTIVE',
                      style: TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Purchase Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 6,
                  ),
                  onPressed: () {
                    final razorpay = ref.read(razorpayServiceProvider);
                    razorpay.startVipPassPayment(
                      onSuccess: (paymentId) {
                        if (!context.mounted) return;
                        ref.read(gameStateProvider.notifier).purchaseRemoveAds();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF131B3A),
                            content: Text(
                              '🎉 Payment Verified ($paymentId)! VIP License Unlocked! Ads removed & 500 DM added!',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      onFailure: (errorMessage) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF2D1520),
                            content: Text(
                              '❌ Payment Cancelled: $errorMessage',
                              style: const TextStyle(
                                color: Color(0xFFFF4060),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    );
                  },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.black, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'UNLOCK NO-ADS VIP • ${LocalizedPricingService.removeAdsPriceString}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                ),
              ),
              const SizedBox(height: 8),

              // Restore Purchases & Maybe Later
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      final bool success = ref
                          .read(gameStateProvider.notifier)
                          .restorePurchases();
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF131B3A),
                          content: Text(
                            success
                                ? '✅ Purchases Restored Successfully!'
                                : 'ℹ️ No previous purchases found on this account.',
                            style: TextStyle(
                              color: success
                                  ? const Color(0xFF00FF88)
                                  : const Color(0xFFFFB800),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Restore Purchases',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Maybe Later',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(
      IconData icon, Color color, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha((0.2 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
