import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/daily_login_model.dart';
import '../../providers/game_providers.dart';
import '../../services/ad_manager.dart';
import '../../utils/game_theme.dart';
import '../../utils/number_formatter.dart';

/// Modal bottom sheet displaying the 7-Day Commander Login Calendar
class DailyCalendarModal extends ConsumerStatefulWidget {
  const DailyCalendarModal({super.key});

  @override
  ConsumerState<DailyCalendarModal> createState() => _DailyCalendarModalState();
}

class _DailyCalendarModalState extends ConsumerState<DailyCalendarModal> {
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final notifier = ref.read(gameStateProvider.notifier);

    final bool canClaim = gameState.canClaimDailyReward;
    final int activeDay = gameState.currentLoginDay;

    // Remaining cooldown until next daily claim
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int elapsedSinceClaim = now - gameState.lastLoginClaimEpoch;
    final int cooldownTotal = 20 * 60 * 60 * 1000;
    final int remainingCooldownMs = (cooldownTotal - elapsedSinceClaim).clamp(0, cooldownTotal);
    final String countdownStr = NumberFormatter.formatDurationMs(remainingCooldownMs);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF070914),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Color(0xFFFFD700), width: 2.0),
          ),
        ),
        child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
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
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFFFFD700),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'COMMANDER LOGIN CALENDAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          // Subtitle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: GameTheme.backgroundVoid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withAlpha((0.3 * 255).round()),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Log in daily to claim escalating interstellar supplies.',
                    style: TextStyle(
                      color: GameTheme.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.0),
                  ),
                  child: Text(
                    'DAY $activeDay/7',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 7-Day Grid Cards
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

                  // Day 7: Grand Supernova Prize Featured Card
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

          // Action Button Deck
          if (canClaim) ...[
            Row(
              children: [
                // Single Claim Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      final success = notifier.claimDailyLoginReward();
                      if (success) {
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
                      'CLAIM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2X Double Claim (Watch Ad)
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      AdManager().showRewardedAd(
                        onUserEarnedReward: () {
                          notifier.claimDailyLoginReward(doubleWithAd: true);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF1F1804),
                              content: Text(
                                '🎁 2X DOUBLE REWARDS COLLECTED!',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.play_circle_fill_rounded,
                        color: Colors.black, size: 16),
                    label: const Text(
                      'DOUBLE REWARD (AD)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.05 * 255).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_rounded,
                      color: Color(0xFF00F0FF), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'NEXT DAILY REWARD IN: $countdownStr',
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }


  Widget _buildDayCard({
    required DailyRewardDay day,
    required bool isPastClaimed,
    required bool isCurrentDay,
    required bool canClaim,
  }) {
    final color = Color(day.colorValue);
    final bool isReady = isCurrentDay && canClaim;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isReady
            ? color.withAlpha((0.15 * 255).round())
            : const Color(0xFF0D1224),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReady
              ? color
              : isPastClaimed
                  ? const Color(0xFF00FF88)
                  : Colors.white12,
          width: isReady ? 2.0 : 1.0,
        ),
        boxShadow: isReady
            ? [
                BoxShadow(
                  color: color.withAlpha((0.4 * 255).round()),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Day Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAY ${day.dayNumber}',
                style: TextStyle(
                  color: isReady ? color : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (isPastClaimed)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF00FF88), size: 14)
              else if (isReady)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),

          // Icon
          Image.asset(
            day.iconAsset,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.card_giftcard_rounded,
              color: color,
              size: 28,
            ),
          ),

          // Title
          Text(
            day.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDay7FeaturedCard({
    required DailyRewardDay day,
    required bool isPastClaimed,
    required bool isCurrentDay,
    required bool canClaim,
  }) {
    const color = Color(0xFFFF0055);
    final bool isReady = isCurrentDay && canClaim;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isReady
            ? color.withAlpha((0.20 * 255).round())
            : const Color(0xFF150B1B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReady
              ? color
              : isPastClaimed
                  ? const Color(0xFF00FF88)
                  : const Color(0xFFFF0055).withAlpha((0.5 * 255).round()),
          width: isReady ? 2.0 : 1.2,
        ),
        boxShadow: isReady
            ? const [
                BoxShadow(
                  color: Color(0xFFFF0055),
                  blurRadius: 14,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha((0.2 * 255).round()),
              border: Border.all(color: color, width: 1.2),
            ),
            child: Center(
              child: Image.asset(
                day.iconAsset,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.auto_awesome_rounded,
                  color: color,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DAY 7 • GRAND PRIZE',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (isPastClaimed)
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF00FF88), size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  day.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
