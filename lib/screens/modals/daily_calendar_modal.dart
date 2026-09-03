import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/daily_login_model.dart';
import '../../providers/game_providers.dart';
import '../../services/ad_manager.dart';
import '../../services/sound_service.dart';
import '../../utils/number_formatter.dart';


/// Enhanced, Holographic 7-Day Commander Login Calendar Modal
class DailyCalendarModal extends ConsumerStatefulWidget {
  const DailyCalendarModal({super.key});

  @override
  ConsumerState<DailyCalendarModal> createState() => _DailyCalendarModalState();
}

class _DailyCalendarModalState extends ConsumerState<DailyCalendarModal>
    with SingleTickerProviderStateMixin {
  Timer? _countdownTicker;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    final bool canClaim = gameState.canClaimDailyReward;
    final int activeDay = gameState.currentLoginDay;
    final bool isVip = gameState.hasRemovedAds;

    // Remaining cooldown calculation (20 hours cycle)
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int elapsedSinceClaim = now - gameState.lastLoginClaimEpoch;
    final int cooldownTotal = 20 * 60 * 60 * 1000;
    final int remainingCooldownMs =
        (cooldownTotal - elapsedSinceClaim).clamp(0, cooldownTotal);
    final String countdownStr =
        NumberFormatter.formatDurationMs(remainingCooldownMs);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF070B18),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: const Border(
            top: BorderSide(color: Color(0xFFFFD700), width: 2.2),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withAlpha((0.25 * 255).round()),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Top Header Bar
            _buildHeader(context, activeDay),

            // Streak & Status Indicator Strip
            _buildStreakBanner(canClaim, countdownStr, activeDay),

            const SizedBox(height: 8),

            // 7-Day Interactive Grid Cards
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Days 1-6 in a 3-column Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        final day = DailyRewardDay.schedule[index];
                        final bool isPastClaimed = day.dayNumber < activeDay;
                        final bool isCurrentDay = day.dayNumber == activeDay;
                        return _buildDayCard(
                          day: day,
                          isPastClaimed: isPastClaimed,
                          isCurrentDay: isCurrentDay,
                          canClaim: canClaim,
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Day 7: Grand Cosmic Singularity Supernova Card
                    _buildDay7FeaturedCard(
                      day: DailyRewardDay.schedule[6],
                      isPastClaimed: 7 < activeDay,
                      isCurrentDay: 7 == activeDay,
                      canClaim: canClaim,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Bottom Interactive Action Button Deck
            _buildActionDeck(context, notifier, canClaim, isVip, countdownStr),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int activeDay) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withAlpha((0.2 * 255).round()),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD700), width: 1.0),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Color(0xFFFFD700),
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMMANDER LOGIN SUPPLY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '7-Day Escalating Galactic Reward Matrix',
                style: TextStyle(
                  color: Colors.white54,
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
          icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildStreakBanner(
      bool canClaim, String countdownStr, int activeDay) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: canClaim
            ? const Color(0xFF00FF88).withAlpha((0.15 * 255).round())
            : const Color(0xFF1E293B).withAlpha((0.6 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canClaim ? const Color(0xFF00FF88) : Colors.white12,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                canClaim
                    ? Icons.card_giftcard_rounded
                    : Icons.hourglass_top_rounded,
                color: canClaim
                    ? const Color(0xFF00FF88)
                    : const Color(0xFF00F0FF),
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                canClaim
                    ? 'SUPPLY READY FOR COLLECTION!'
                    : 'NEXT SUPPLY IN: $countdownStr',
                style: TextStyle(
                  color: canClaim ? const Color(0xFF00FF88) : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
            ),
            child: Text(
              'DAY $activeDay/7',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard({
    required DailyRewardDay day,
    required bool isPastClaimed,
    required bool isCurrentDay,
    required bool canClaim,
  }) {
    final bool isClaimableNow = isCurrentDay && canClaim;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: isClaimableNow ? _pulseAnimation.value : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: isPastClaimed
                ? const Color(0xFF0D1B15)
                : (isClaimableNow
                    ? const Color(0xFF131D38)
                    : const Color(0xFF0F172A)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPastClaimed
                  ? const Color(0xFF00FF88)
                  : (isClaimableNow
                      ? const Color(0xFFFFD700)
                      : Colors.white12),
              width: isClaimableNow ? 1.8 : 1.0,
            ),
            boxShadow: isClaimableNow
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700)
                          .withAlpha((0.45 * 255).round()),
                      blurRadius: 16,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Day Title Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPastClaimed
                      ? const Color(0xFF00FF88).withAlpha((0.2 * 255).round())
                      : (isClaimableNow
                          ? const Color(0xFFFFD700).withAlpha((0.25 * 255).round())
                          : Colors.white10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'DAY ${day.dayNumber}',
                  style: TextStyle(
                    color: isPastClaimed
                        ? const Color(0xFF00FF88)
                        : (isClaimableNow
                            ? const Color(0xFFFFD700)
                            : Colors.white60),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Reward Icon or Checkmark
              if (isPastClaimed)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF00FF88), size: 28)
              else if (day.iconAsset.isNotEmpty)
                Image.asset(
                  day.iconAsset,
                  width: 26,
                  height: 26,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.stars_rounded,
                    color: Color(day.colorValue),
                    size: 26,
                  ),
                )

              else
                Icon(
                  Icons.stars_rounded,
                  color: Color(day.colorValue),
                  size: 26,
                ),


              const SizedBox(height: 6),

              // Reward Label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  day.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isPastClaimed ? Colors.white54 : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDay7FeaturedCard({
    required DailyRewardDay day,
    required bool isPastClaimed,
    required bool isCurrentDay,
    required bool canClaim,
  }) {
    final bool isClaimableNow = isCurrentDay && canClaim;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isClaimableNow
            ? const Color(0xFF1E1538)
            : const Color(0xFF11172E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimableNow
              ? const Color(0xFFFFD700)
              : const Color(0xFFBD00FF).withAlpha((0.6 * 255).round()),
          width: isClaimableNow ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBD00FF).withAlpha((0.3 * 255).round()),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFBD00FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700)
                      .withAlpha((0.5 * 255).round()),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.black, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'DAY 7: SUPERNOVA CACHE',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBD00FF)
                            .withAlpha((0.3 * 255).round()),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'GRAND PRIZE',
                        style: TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '+10,000 Credits • +50 Dark Matter • +3 Spins',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (isPastClaimed)
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF00FF88), size: 24)
          else if (isClaimableNow)
            const Icon(Icons.stars_rounded,
                color: Color(0xFFFFD700), size: 24)
          else
            const Icon(Icons.lock_outline_rounded,
                color: Colors.white38, size: 20),
        ],
      ),
    );
  }

  Widget _buildActionDeck(
    BuildContext context,
    dynamic notifier,
    bool canClaim,
    bool isVip,
    String countdownStr,
  ) {
    if (!canClaim) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1224),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock_rounded,
                color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            Text(
              'COME BACK IN $countdownStr FOR NEXT REWARD',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Standard Claim Button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              final success = notifier.claimDailyLoginReward();
              if (success) {
                SoundService().playPurchaseSound();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF0B2418),
                    content: Text(
                      '✨ Daily Commander Reward Claimed!',
                      style: TextStyle(
                        color: Color(0xFF00FF88),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'CLAIM (1X)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // 2X Double Claim Button (Instant for VIP, Rewarded Ad for Free)
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () {
              if (isVip) {
                final success = notifier.claimDailyLoginReward(multiplier: 2.0);
                if (success) {
                  SoundService().playPurchaseSound();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF131B3A),
                      content: Text(
                        '👑 VIP Commander 2X Reward Claimed!',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return;
              }

              AdManager().showRewardedAd(
                onUserEarnedReward: () {
                  final success =
                      notifier.claimDailyLoginReward(multiplier: 2.0);
                  if (success) {
                    SoundService().playPurchaseSound();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF0B2418),
                        content: Text(
                          '⚡ 2X DOUBLE Daily Reward Claimed!',
                          style: TextStyle(
                            color: Color(0xFF00FF88),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 6,
              shadowColor:
                  const Color(0xFFFFD700).withAlpha((0.5 * 255).round()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              isVip
                  ? Icons.workspace_premium_rounded
                  : Icons.smart_display_rounded,
              size: 16,
              color: Colors.black,
            ),
            label: Text(
              isVip ? 'CLAIM 2X (VIP INSTANT)' : 'CLAIM 2X (WATCH AD)',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
