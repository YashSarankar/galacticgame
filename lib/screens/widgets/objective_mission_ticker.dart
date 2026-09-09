import 'package:flutter/material.dart';
import '../../models/game_state.dart';
import '../../services/user_growth_service.dart';
import '../../utils/game_theme.dart';
import '../../utils/number_formatter.dart';

/// Contextual ticker displaying Boss Siege Alert, Commander Learning Quest, Hyperspace Fever Meter, or Career Directive.
class ObjectiveMissionTicker extends StatelessWidget {
  final GameState gameState;
  final ValueChanged<int> onClaimQuest;
  final ValueChanged<String> onClaimMission;

  const ObjectiveMissionTicker({
    super.key,
    required this.gameState,
    required this.onClaimQuest,
    required this.onClaimMission,
  });

  @override
  Widget build(BuildContext context) {
    // Priority 1: Combat Alert if an Alien Boss Incursion is active
    if (gameState.activeBoss != null && !gameState.activeBoss!.isDead) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: _buildBossSiegeHUD(gameState),
      );
    }

    // Priority 2: Cadet Onboarding Tutorial (Steps 0-4)
    if (gameState.tutorialStep < 5 && gameState.highestTierUnlocked <= 1) {
      return _buildCommanderLearningQuestHud(context, gameState);
    }

    // Priority 3: Active Commander Learning Quest / Milestone
    final activeQuest = UserGrowthService.getActiveMilestone(gameState);
    if (activeQuest != null) {
      return _buildCommanderLearningQuestHud(context, gameState);
    }

    // Priority 4: Standard Career Mission fallback
    return _buildActiveMissionBar(gameState);
  }

  Widget _buildCommanderLearningQuestHud(
      BuildContext context, GameState gameState) {
    // 1. Initial Cadet Steps (0, 1, 2, 3, 4)
    if (gameState.tutorialStep < 5) {
      String title;
      String instruction;
      IconData icon;
      Color color;

      switch (gameState.tutorialStep) {
        case 0:
          title = 'STEP 1/5: LAUNCH YOUR SHIP! 🚀';
          instruction =
              'Drag your spaceship up onto the track to start making coins! 💰';
          icon = Icons.flight_takeoff_rounded;
          color = const Color(0xFF00F0FF);
          break;
        case 1:
          title = 'STEP 2/5: TURBO TAP SPEED! ⚡';
          instruction =
              'Tap the racetrack 3 times fast to boost your speed and earn rapid coins!';
          icon = Icons.bolt_rounded;
          color = const Color(0xFFFF0055);
          break;
        case 2:
          title = 'STEP 3/5: BUY SECOND SHIP! 🛸';
          instruction =
              'Tap the green BUY SHIP button at the bottom to add another ship!';
          icon = Icons.add_circle_outline_rounded;
          color = const Color(0xFF00FF88);
          break;
        case 3:
          title = 'STEP 4/5: MERGE TO EVOLVE! 💥';
          instruction =
              'Drag matching Tier 1 spaceships onto each other to create Tier 2!';
          icon = Icons.auto_awesome_rounded;
          color = const Color(0xFFFF9900);
          break;
        case 4:
          title = 'STEP 5/5: FLEET ENGINE SPEED! ⚡';
          instruction =
              'Tap the SPEED button in the strip below to upgrade your engine power!';
          icon = Icons.speed_rounded;
          color = const Color(0xFFFFD700);
          break;
        default:
          title = 'CADET TRAINING';
          instruction = 'Follow on-screen instructions';
          icon = Icons.rocket_launch_rounded;
          color = const Color(0xFF00F0FF);
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1024),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withAlpha((0.6 * 255).round()),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha((0.15 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withAlpha((0.2 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    instruction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2. Active Milestone Quest
    final activeQuest = UserGrowthService.getActiveMilestone(gameState);
    if (activeQuest == null) {
      return _buildActiveMissionBar(gameState);
    }

    final bool isCompleted = activeQuest.checkCompleted(gameState);
    final String rewardText = activeQuest.rewardDarkMatter > 0
        ? '+${NumberFormatter.formatCredits(activeQuest.rewardCredits)} 💰  +${NumberFormatter.formatDarkMatter(activeQuest.rewardDarkMatter)} DM 💎'
        : '+${NumberFormatter.formatCredits(activeQuest.rewardCredits)} 💰';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1024),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF00FF88)
              : const Color(0xFF00F0FF).withAlpha((0.5 * 255).round()),
          width: isCompleted ? 1.4 : 1.0,
        ),
        boxShadow: [
          if (isCompleted)
            BoxShadow(
              color: const Color(0xFF00FF88).withAlpha((0.3 * 255).round()),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: (isCompleted
                      ? const Color(0xFF00FF88)
                      : const Color(0xFF00F0FF))
                  .withAlpha((0.2 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : activeQuest.icon,
              color: isCompleted
                  ? const Color(0xFF00FF88)
                  : const Color(0xFF00F0FF),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${activeQuest.title.toUpperCase()} (DIRECTIVE #${activeQuest.id})',
                  style: TextStyle(
                    color: isCompleted
                        ? const Color(0xFF00FF88)
                        : const Color(0xFF00F0FF),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  isCompleted
                      ? 'Goal Complete! Tap CLAIM to collect: $rewardText'
                      : activeQuest.objective,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isCompleted) ...[
            const SizedBox(width: 6),
            SizedBox(
              height: 28,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                onPressed: () => onClaimQuest(activeQuest.id),
                child: const Text(
                  'CLAIM',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveMissionBar(GameState state) {
    final unclaimedMissions =
        state.career.missions.where((m) => !m.isClaimed).toList();
    final bool allDone = unclaimedMissions.isEmpty;
    final activeMission = !allDone ? unclaimedMissions.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final bool isCurrent =
              child.key == ValueKey(activeMission?.id ?? 'all_completed');
          final inTween = Tween<Offset>(
            begin: isCurrent ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0),
            end: Offset.zero,
          );

          return SlideTransition(
            position: inTween.animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: allDone
            ? Container(
                key: const ValueKey('all_completed'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: GameTheme.neonPurple.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: GameTheme.neonPurple.withAlpha((0.5 * 255).round()),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: GameTheme.neonPurple,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'ALL DIRECTIVES COMPLETED • PRESTIGE FOR NEW SECTORS',
                        style: TextStyle(
                          color: GameTheme.neonPurple,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                key: ValueKey(activeMission!.id),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GameTheme.backgroundSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: activeMission.isCompleted
                        ? GameTheme.neonGreen.withAlpha((0.6 * 255).round())
                        : GameTheme.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      activeMission.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radar_rounded,
                      color: activeMission.isCompleted
                          ? GameTheme.neonGreen
                          : GameTheme.neonCyan,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activeMission.title,
                                  style: const TextStyle(
                                    color: GameTheme.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${activeMission.currentProgress.toInt()}/${activeMission.targetValue.toInt()}',
                                style: TextStyle(
                                  color: activeMission.isCompleted
                                      ? GameTheme.neonGreen
                                      : GameTheme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          LinearProgressIndicator(
                            value: activeMission.progressRatio,
                            backgroundColor: GameTheme.backgroundVoid,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              activeMission.isCompleted
                                  ? GameTheme.neonGreen
                                  : GameTheme.neonCyan,
                            ),
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    ),
                    if (activeMission.isCompleted &&
                        !activeMission.isClaimed) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GameTheme.neonGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () => onClaimMission(activeMission.id),
                          child: const Text(
                            'CLAIM',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBossSiegeHUD(GameState state) {
    final boss = state.activeBoss;
    if (boss == null || boss.isDead) {
      return _buildWarpMeterBar(state);
    }

    final double hpPercent = boss.healthPercentage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.85 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF0055),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFFF0055),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF0055),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '⚠️ ${boss.name.toUpperCase()} SIEGE',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '⏱️ ${boss.timeRemaining.toStringAsFixed(1)}s  |  HP: ${(hpPercent * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFFFF0055),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: hpPercent,
              minHeight: 4,
              backgroundColor: Colors.white10,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFF0055)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarpMeterBar(GameState state) {
    final bool isFever = state.isFeverActive;
    final double progress = isFever
        ? (state.feverTimeRemaining / 10.0).clamp(0.0, 1.0)
        : state.feverCharge.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.75 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFever
              ? const Color(0xFFFFD700)
              : GameTheme.neonCyan.withAlpha((0.5 * 255).round()),
          width: isFever ? 1.5 : 1.0,
        ),
        boxShadow: isFever
            ? [
                const BoxShadow(
                  color: Color(0xFFFF0055),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isFever
                          ? Icons.local_fire_department_rounded
                          : Icons.bolt_rounded,
                      color: isFever
                          ? const Color(0xFFFF0055)
                          : GameTheme.neonCyan,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFever
                          ? 'HYPERSPACE FEVER (3X SPEED)'
                          : 'WARP FRENZY CHARGE',
                      style: TextStyle(
                        color: isFever
                            ? const Color(0xFFFFD700)
                            : GameTheme.neonCyan,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isFever
                    ? '${state.feverTimeRemaining.toStringAsFixed(1)}s'
                    : '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: isFever ? const Color(0xFFFFD700) : Colors.white,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFever ? const Color(0xFFFF0055) : GameTheme.neonCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
