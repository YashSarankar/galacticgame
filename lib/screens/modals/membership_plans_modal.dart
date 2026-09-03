import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_providers.dart';
import '../../services/localized_pricing_service.dart';
import '../../utils/game_theme.dart';

/// Advanced, Engaging & High-Conversion Commission Plans Comparison Modal
class MembershipPlansModal extends ConsumerStatefulWidget {
  const MembershipPlansModal({super.key});

  @override
  ConsumerState<MembershipPlansModal> createState() =>
      _MembershipPlansModalState();
}

class _MembershipPlansModalState extends ConsumerState<MembershipPlansModal>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 1; // 0 = Cadet, 1 = VIP Commander (Default to VIP for conversion)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final bool isVip = gameState.hasRemovedAds;
    final String priceText = LocalizedPricingService.removeAdsPriceString;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 720),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1224),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isVip ? const Color(0xFF00FF88) : const Color(0xFFFFD700),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: (isVip ? const Color(0xFF00FF88) : const Color(0xFFFFD700))
                  .withAlpha((0.35 * 255).round()),
              blurRadius: 36,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Holographic Header Banner
            _buildTopHeader(isVip),

            // Custom Segmented Pill Switcher (Zero Underline!)
            _buildCustomSegmentedBar(isVip),

            const SizedBox(height: 6),

            // Main Content Area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _selectedTab == 0
                    ? _buildCadetPlanView(context)
                    : _buildVipPlanView(context, isVip, priceText),
              ),
            ),

            // Bottom Interactive CTA Deck
            _buildBottomCtaDeck(context, isVip, priceText),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool isVip) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
      decoration: BoxDecoration(
        color: GameTheme.backgroundVoid.withAlpha((0.6 * 255).round()),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _selectedTab == 1 ? _pulseAnimation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isVip
                        ? [const Color(0xFF00FF88), const Color(0xFF008855)]
                        : [const Color(0xFFFFD700), const Color(0xFFFF8800)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isVip
                              ? const Color(0xFF00FF88)
                              : const Color(0xFFFFD700))
                          .withAlpha((0.5 * 255).round()),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  isVip ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'COMMISSION PLANS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700)
                            .withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: const Color(0xFFFFD700), width: 0.8),
                      ),
                      child: const Text(
                        'LIFETIME',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                const Text(
                  'No Monthly Fees • One-Time Pass',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 9.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.close_rounded,
                color: Colors.white54, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }


  /// Custom Cyber Pill Switcher that completely avoids TabBar default underline artifacts
  Widget _buildCustomSegmentedBar(bool isVip) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF070B16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1.0),
      ),
      child: Row(
        children: [
          // Tab 0: Free Cadet
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? const Color(0xFF1E293B)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTab == 0
                        ? const Color(0xFF3B82F6)
                        : Colors.transparent,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: _selectedTab == 0
                          ? const Color(0xFF60A5FA)
                          : Colors.white38,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'FREE CADET',
                      style: TextStyle(
                        color: _selectedTab == 0 ? Colors.white : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Tab 1: VIP Commander
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? const Color(0xFFFFD700)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFD700)
                                .withAlpha((0.4 * 255).round()),
                            blurRadius: 12,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 15,
                      color: _selectedTab == 1 ? Colors.black : Colors.white38,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isVip ? 'VIP (ACTIVE)' : 'VIP COMMANDER',
                      style: TextStyle(
                        color: _selectedTab == 1 ? Colors.black : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
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

  Widget _buildCadetPlanView(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('cadet_view'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanSummaryBanner(
            title: 'CADET RECRUIT BASE TIER',
            subtitle: 'Standard intergalactic commission with ad support.',
            color: const Color(0xFF3B82F6),
            badge: 'ACTIVE BY DEFAULT',
          ),
          const SizedBox(height: 10),
          _buildPerkCard(
            icon: Icons.rocket_launch_rounded,
            color: const Color(0xFF3B82F6),
            title: '15 Spacecraft Tiers & Merging',
            subtitle: 'Standard manual drag-and-merge grid access.',
            statusText: 'INCLUDED',
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.radar_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Alien Boss Battles & Relics Vault',
            subtitle: 'Summon dreadnoughts and explore constellations.',
            statusText: 'INCLUDED',
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.smart_display_rounded,
            color: Colors.amber,
            title: 'Ad-Supported Universe Experience',
            subtitle: 'Standard banner ads and video transmissions.',
            statusText: 'STANDARD ADS',
            isWarning: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.auto_awesome_rounded,
            color: Colors.amber,
            title: 'Fleet Auto-Merge Logistics',
            subtitle: 'Requires watching rewarded ad per auto-merge.',
            statusText: 'AD PER MERGE',
            isWarning: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.timer_rounded,
            color: Colors.amber,
            title: '2-Hour Offline Income Cap',
            subtitle: 'Halts coin accumulation after 2 hours away.',
            statusText: '2H LIMIT',
            isWarning: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.smart_toy_outlined,
            color: Colors.white38,
            title: 'Support Drone Auto-Collector',
            subtitle: 'Requires manual store rental for temporary use.',
            statusText: 'LOCKED',
            isIncluded: false,
          ),
        ],
      ),
    );
  }

  Widget _buildVipPlanView(
      BuildContext context, bool isVip, String priceText) {
    return SingleChildScrollView(
      key: const ValueKey('vip_view'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanSummaryBanner(
            title: '👑 SUPREME VIP COMMANDER PASS',
            subtitle: 'One-time unlock for permanent lifetime supremacy.',
            color: const Color(0xFFFFD700),
            badge: '$priceText • FOREVER',
          ),
          const SizedBox(height: 10),
          _buildPerkCard(
            icon: Icons.block_rounded,
            color: const Color(0xFFFF0055),
            title: '100% Ad-Free Interstellar Universe',
            subtitle: 'Zero banner ads, zero interstitial interruptions forever.',
            statusText: 'ZERO ADS',
            isHighlight: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFFFFD700),
            title: 'Unlimited 1-Tap Fleet Auto-Merge',
            subtitle: 'Instantly combine matching spacecraft with zero ads.',
            statusText: 'UNLIMITED',
            isHighlight: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFF00FF88),
            title: '12-Hour Offline Earnings (6X Cap)',
            subtitle: 'Collect massive coin wealth while away from the game.',
            statusText: '6X INCOME',
            isHighlight: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.smart_toy_rounded,
            color: const Color(0xFF00F0FF),
            title: 'Permanent Lifetime Support Drone',
            subtitle: 'Automated AI opens delivery crates continuously.',
            statusText: 'LIFETIME AI',
            isHighlight: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.bolt_rounded,
            color: const Color(0xFFFFD700),
            title: 'Instant 1-Tap 2X Multipliers',
            subtitle: 'Claim double offline & prestige yields with no ads.',
            statusText: 'INSTANT 2X',
            isHighlight: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.card_giftcard_rounded,
            color: const Color(0xFFBD00FF),
            title: 'Instant Welcome Bounty (+500 DM + 5 Spins)',
            subtitle: 'Immediate VIP starter package credited to your hangar.',
            statusText: '+500 DM',
            isHighlight: true,
            isIncluded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummaryBanner({
    required String title,
    required String subtitle,
    required Color color,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha((0.4 * 255).round()), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerkCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String statusText,
    required bool isIncluded,
    bool isHighlight = false,
    bool isWarning = false,
  }) {
    final statusColor = isHighlight
        ? const Color(0xFF00FF88)
        : (isWarning ? Colors.amber : (isIncluded ? const Color(0xFF3B82F6) : Colors.white24));

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlight
            ? color.withAlpha((0.10 * 255).round())
            : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight
              ? color.withAlpha((0.4 * 255).round())
              : Colors.white10,
          width: 0.9,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isIncluded ? Colors.white : Colors.white38,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isIncluded ? Colors.white60 : Colors.white24,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withAlpha((0.18 * 255).round()),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withAlpha((0.6 * 255).round()), width: 0.8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCtaDeck(BuildContext context, bool isVip, String priceText) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: GameTheme.backgroundVoid,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVip) ...[
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
                  Icon(Icons.verified_rounded,
                      color: Color(0xFF00FF88), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'VIP COMMANDER ACTIVE • LIFETIME PASS',
                    style: TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shadowColor: const Color(0xFFFFD700).withAlpha((0.6 * 255).round()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  final razorpay = ref.read(razorpayServiceProvider);
                  razorpay.startVipPassPayment(
                    onSuccess: (paymentId) {
                      if (!mounted) return;
                      ref.read(gameStateProvider.notifier).purchaseRemoveAds();
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF131B3A),
                          content: Text(
                            '🎉 Payment Verified ($paymentId)! Welcome VIP Commander! All ads removed + 500 DM + Lifetime Drone!',
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
                      if (!mounted) return;
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
                      const Icon(Icons.workspace_premium_rounded,
                          color: Colors.black, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'UPGRADE TO VIP COMMANDER • $priceText',
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
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    ref
                        .read(gameStateProvider.notifier)
                        .restorePurchases();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF131B3A),
                        content: Text(
                          '✅ Purchases Restored Successfully!',
                          style: TextStyle(color: Color(0xFF00FF88)),
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
                    'Keep Free Cadet Plan',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
