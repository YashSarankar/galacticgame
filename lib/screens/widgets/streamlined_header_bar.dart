import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../providers/ad_state_provider.dart';
import '../../services/user_growth_service.dart';
import '../../utils/game_theme.dart';
import '../../utils/number_formatter.dart';

/// Clean top header displaying Credits with live telemetry, Dark Matter (Tier 3+), VIP Status, and Settings.
class StreamlinedHeaderBar extends StatelessWidget {
  final GameState state;
  final AdBoostState adState;
  final GlobalKey coinCounterKey;
  final GlobalKey darkMatterCounterKey;
  final Animation<double> coinBounceAnimation;
  final VoidCallback onOpenMembership;
  final VoidCallback onOpenSettings;

  const StreamlinedHeaderBar({
    super.key,
    required this.state,
    required this.adState,
    required this.coinCounterKey,
    required this.darkMatterCounterKey,
    required this.coinBounceAnimation,
    required this.onOpenMembership,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    const double approxTrackLength = 1400.0;
    final double speedMult =
        state.fleetSpeedMultiplier * (adState.isSpeedBoostActive ? 2.0 : 1.0);
    final double incomeMult = (adState.isSpeedBoostActive ? 2.0 : 1.0);

    final double estimatedIncomePerSecond = state.trackShips.fold<double>(
      0.0,
      (sum, s) =>
          sum +
          (s.calculateIncomePayout(multiplier: incomeMult) *
              state.finishLinesCount *
              (s.baseSpeed * speedMult / approxTrackLength)),
    );

    final bool isDarkMatterUnlocked = UserGrowthService.isFeatureUnlocked(
          GameFeature.techTree,
          highestTier: state.highestTierUnlocked,
        ) ||
        state.darkMatter > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1024).withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F0FF).withAlpha(45),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(180),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Credits Pill (Soft Currency + Live Income Telemetry)
          Expanded(
            flex: isDarkMatterUnlocked ? 5 : 1,
            child: ScaleTransition(
              scale: coinBounceAnimation,
              child: Container(
                key: coinCounterKey,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GameTheme.neonGold.withAlpha(45),
                      const Color(0xFF1B180A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GameTheme.neonGold.withAlpha(110),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: GameTheme.neonGold.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.monetization_on_rounded,
                        color: GameTheme.neonGold,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            NumberFormatter.formatCredits(state.credits),
                            style: const TextStyle(
                              color: GameTheme.neonGold,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (estimatedIncomePerSecond > 0)
                            Text(
                              '+${NumberFormatter.formatCredits(estimatedIncomePerSecond)}/s',
                              style: const TextStyle(
                                color: Color(0xFF00FF88),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isDarkMatterUnlocked) ...[
            const SizedBox(width: 6),
            // 2. Dark Matter Pill (Hard Currency)
            Expanded(
              flex: 4,
              child: Container(
                key: darkMatterCounterKey,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GameTheme.neonPurple.withAlpha(45),
                      const Color(0xFF190C28),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GameTheme.neonPurple.withAlpha(100),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: GameTheme.neonPurple.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.diamond_rounded,
                        color: GameTheme.neonPurple,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            NumberFormatter.formatDarkMatter(state.darkMatter),
                            style: const TextStyle(
                              color: GameTheme.neonPurple,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'DARK MATTER',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 7.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(width: 6),

          // 3. VIP / Membership Plans Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onOpenMembership,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: state.hasRemovedAds
                        ? [
                            const Color(0xFF00FF88).withAlpha(50),
                            const Color(0xFF004D28),
                          ]
                        : [
                            const Color(0xFFFFD700).withAlpha(55),
                            const Color(0xFF4A3800),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.hasRemovedAds
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFFD700),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (state.hasRemovedAds
                              ? const Color(0xFF00FF88)
                              : const Color(0xFFFFD700))
                          .withAlpha(40),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.hasRemovedAds
                          ? Icons.verified_rounded
                          : Icons.workspace_premium_rounded,
                      color: state.hasRemovedAds
                          ? const Color(0xFF00FF88)
                          : const Color(0xFFFFD700),
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.hasRemovedAds ? 'VIP' : 'PLANS',
                      style: TextStyle(
                        color: state.hasRemovedAds
                            ? const Color(0xFF00FF88)
                            : const Color(0xFFFFD700),
                        fontSize: 10.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 4. Settings Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onOpenSettings,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withAlpha(40),
                    width: 1.0,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.settings_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
