import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_providers.dart';
import '../../services/localized_pricing_service.dart';
import '../../utils/game_theme.dart';

/// Premium, High-Conversion VIP Commander Commission Plans Modal
class MembershipPlansModal extends ConsumerStatefulWidget {
  const MembershipPlansModal({super.key});

  @override
  ConsumerState<MembershipPlansModal> createState() =>
      _MembershipPlansModalState();
}

class _MembershipPlansModalState extends ConsumerState<MembershipPlansModal>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0 = VIP Commander (Default for conversion), 1 = Free Cadet, 2 = Side-by-Side Comparison
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 730),
        decoration: BoxDecoration(
          color: const Color(0xFF090D1C),
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
            BoxShadow(
              color: Colors.black.withAlpha(230),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. Top Holographic Header
            _buildTopHeader(isVip),

            // 2. Custom 3-Way Segmented Bar (VIP / Free / Comparison)
            _buildCustomSegmentedBar(isVip),

            const SizedBox(height: 6),

            // 3. Main Content Area with Smooth Transitions
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _buildCurrentView(context, isVip, priceText),
              ),
            ),

            // 4. Bottom Interactive CTA Deck
            _buildBottomCtaDeck(context, isVip, priceText),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView(
      BuildContext context, bool isVip, String priceText) {
    switch (_selectedTab) {
      case 0:
        return _buildVipPlanView(context, isVip, priceText);
      case 1:
        return _buildCadetPlanView(context);
      case 2:
        return _buildComparisonView(context, isVip);
      default:
        return _buildVipPlanView(context, isVip, priceText);
    }
  }

  Widget _buildTopHeader(bool isVip) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      decoration: BoxDecoration(
        color: GameTheme.backgroundVoid.withAlpha((0.7 * 255).round()),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _selectedTab == 0 ? _pulseAnimation.value : 1.0,
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
                  isVip
                      ? Icons.verified_rounded
                      : Icons.workspace_premium_rounded,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'COMMANDER COMMISSION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700)
                            .withAlpha((0.25 * 255).round()),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: const Color(0xFFFFD700), width: 0.8),
                      ),
                      child: const Text(
                        'LIFETIME PASS',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                const Text(
                  'One-Time Payment • Zero Recurring Fees • Forever Active',
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

  Widget _buildCustomSegmentedBar(bool isVip) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF060914),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1.0),
      ),
      child: Row(
        children: [
          // Tab 0: VIP Commander (Default)
          Expanded(
            flex: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? const Color(0xFFFFD700)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFD700)
                                .withAlpha((0.35 * 255).round()),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 14,
                      color: _selectedTab == 0 ? Colors.black : const Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVip ? 'VIP (ACTIVE)' : 'VIP PASS',
                      style: TextStyle(
                        color: _selectedTab == 0 ? Colors.black : Colors.white70,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 3),

          // Tab 1: Free Cadet
          Expanded(
            flex: 3,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? const Color(0xFF1E293B)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTab == 1
                        ? const Color(0xFF3B82F6)
                        : Colors.transparent,
                    width: 1.1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 13,
                      color: _selectedTab == 1
                          ? const Color(0xFF60A5FA)
                          : Colors.white38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'FREE CADET',
                      style: TextStyle(
                        color: _selectedTab == 1 ? Colors.white : Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 3),

          // Tab 2: Full Matrix Comparison
          Expanded(
            flex: 3,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedTab = 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == 2
                      ? const Color(0xFF0F172A)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTab == 2
                        ? const Color(0xFF00F0FF)
                        : Colors.transparent,
                    width: 1.1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.compare_arrows_rounded,
                      size: 14,
                      color: _selectedTab == 2
                          ? const Color(0xFF00F0FF)
                          : Colors.white38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'COMPARE',
                      style: TextStyle(
                        color: _selectedTab == 2 ? Colors.white : Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
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

  // --- 1. VIP Commander Pass View ---
  Widget _buildVipPlanView(
      BuildContext context, bool isVip, String priceText) {
    return SingleChildScrollView(
      key: const ValueKey('vip_view'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instant Bounty Showcase Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1C00), Color(0xFF140D00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withAlpha((0.25 * 255).round()),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.card_giftcard_rounded,
                      color: Color(0xFFFFD700), size: 24),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎁 INSTANT VIP WELCOME BOUNTY',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '+500 Dark Matter + 5 Bonus Wormhole Spins + Lifetime Drone',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FREE',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // VIP Perks Stack
          _buildPerkCard(
            icon: Icons.block_rounded,
            color: const Color(0xFFFF0055),
            title: '100% Ad-Free Galaxy Experience',
            subtitle: 'Zero banner ads, zero popups, and instant ad rewards skip.',
            statusText: 'ZERO ADS',
            isHighlight: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.smart_toy_rounded,
            color: const Color(0xFF00F0FF),
            title: 'Permanent 24/7 AI Auto-Collector Drone',
            subtitle: 'Drone automatically opens all mystery crates & drops.',
            statusText: 'LIFETIME AI',
            isHighlight: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.auto_awesome_rounded,
            color: const Color(0xFFFFD700),
            title: 'Unlimited 1-Tap Fleet Auto-Merge',
            subtitle: 'Instantly merge matching starships with zero ad barriers.',
            statusText: 'UNLIMITED',
            isHighlight: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFF00FF88),
            title: '12-Hour Offline Vault (6X Capacity)',
            subtitle: 'Harvest massive credit wealth overnight while sleeping.',
            statusText: '6X OFFLINE',
            isHighlight: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.bolt_rounded,
            color: const Color(0xFFFFD700),
            title: 'Instant 1-Tap 2X Multipliers',
            subtitle: 'Claim double offline & prestige yields instantly with no ads.',
            statusText: 'INSTANT 2X',
            isHighlight: true,
            isIncluded: true,
          ),
        ],
      ),
    );
  }

  // --- 2. Free Cadet Plan View ---
  Widget _buildCadetPlanView(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('cadet_view'),
      physics: const BouncingScrollPhysics(),
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
            title: '50 Spacecraft Tiers & Merging',
            subtitle: 'Standard manual drag-and-merge grid access.',
            statusText: 'INCLUDED',
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.radar_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Alien Boss Incursions & Relics',
            subtitle: 'Summon dreadnoughts and discover ancient relics.',
            statusText: 'INCLUDED',
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.smart_display_rounded,
            color: Colors.amber,
            title: 'Ad-Supported Galaxy Experience',
            subtitle: 'Banner ads and rewarded video transmissions.',
            statusText: 'STANDARD ADS',
            isWarning: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.auto_awesome_rounded,
            color: Colors.amber,
            title: 'Auto-Merge Gated by Video Ads',
            subtitle: 'Requires watching rewarded ad per auto-merge cycle.',
            statusText: 'AD PER MERGE',
            isWarning: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.timer_rounded,
            color: Colors.amber,
            title: '2-Hour Offline Cap',
            subtitle: 'Halts credit accumulation after 2 hours away.',
            statusText: '2H CAP',
            isWarning: true,
            isIncluded: true,
          ),
          _buildPerkCard(
            icon: Icons.smart_toy_outlined,
            color: Colors.white38,
            title: 'Support Drone Auto-Collector',
            subtitle: 'Requires manual store Dark Matter rental.',
            statusText: 'LOCKED',
            isIncluded: false,
          ),
        ],
      ),
    );
  }

  // --- 3. Full Comparison Matrix View ---
  Widget _buildComparisonView(BuildContext context, bool isVip) {
    return SingleChildScrollView(
      key: const ValueKey('compare_view'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(4.2),
                1: FlexColumnWidth(2.8),
                2: FlexColumnWidth(3.0),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white24, width: 1.0)),
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'FEATURE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                        child: Text(
                          'FREE CADET',
                          style: TextStyle(
                            color: Colors.blue.shade300,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                        child: Text(
                          '👑 VIP PASS',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildMatrixRow('Ad Experience', 'Standard Ads', '🚫 ZERO ADS', highlightVip: true),
                _buildMatrixRow('Auto-Merge', 'Watch Ad', '⚡ Unlimited', highlightVip: true),
                _buildMatrixRow('Offline Cap', '2 Hours', '⏳ 12 Hours', highlightVip: true),
                _buildMatrixRow('Drone Collector', 'Rental Only', '🤖 Permanent', highlightVip: true),
                _buildMatrixRow('2X Claim Multipliers', 'Watch Ad', '✨ 1-Tap Free', highlightVip: true),
                _buildMatrixRow('Starter Bounty', 'None', '🎁 +500 DM + 5 Spins', highlightVip: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildMatrixRow(String feature, String cadet, String vip,
      {bool highlightVip = false}) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            feature,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Center(
            child: Text(
              cadet,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Center(
            child: Text(
              vip,
              style: TextStyle(
                color: highlightVip ? const Color(0xFF00FF88) : const Color(0xFFFFD700),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
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

  Widget _buildBottomCtaDeck(
      BuildContext context, bool isVip, String priceText) {
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
                    'VIP COMMANDER ACTIVE • LIFETIME UNLOCKED',
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
                        'UNLOCK VIP COMMANDER • $priceText (LIFETIME)',
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
