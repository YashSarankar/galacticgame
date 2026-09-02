import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/game_theme.dart';
import '../../utils/number_formatter.dart';
import '../../services/sound_service.dart';
import '../../services/ad_manager.dart';


class CometTarget {
  final int id;
  double x;
  double y;
  final double size;
  final String asset;
  final int points;
  final Color glowColor;
  bool isPopped;

  CometTarget({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.asset,
    required this.points,
    required this.glowColor,
    this.isPopped = false,
  });
}

/// 10-Second High-Energy Arcade Tap Frenzy Mini-Game
class CometRushModal extends StatefulWidget {
  final double fleetIncomePerLap;
  final void Function({
    required int taps,
    required double scoreMultiplier,
    bool doubleWithAd,
  }) onSessionComplete;

  const CometRushModal({
    super.key,
    required this.fleetIncomePerLap,
    required this.onSessionComplete,
  });

  @override
  State<CometRushModal> createState() => _CometRushModalState();
}

class _CometRushModalState extends State<CometRushModal> {
  final SoundService _soundService = SoundService();
  final Random _random = Random();

  int _timeRemainingSeconds = 10;
  Timer? _gameTimer;
  Timer? _spawnTimer;

  int _totalTaps = 0;
  int _score = 0;
  bool _isGameOver = false;

  final List<CometTarget> _activeTargets = [];
  int _targetIdCounter = 0;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeRemainingSeconds > 1) {
          _timeRemainingSeconds--;
        } else {
          _timeRemainingSeconds = 0;
          _endGame();
        }
      });
    });

    _spawnTimer =
        Timer.periodic(const Duration(milliseconds: 320), (timer) {
      if (!mounted || _isGameOver) return;
      _spawnTarget();
    });
  }

  void _spawnTarget() {
    if (_activeTargets.length >= 6) return;

    final targetTypes = [
      {
        'asset':
            'assets/kenney_space-shooter-remastered/PNG/Meteors/meteorBrown_med1.png',
        'points': 1,
        'size': 54.0,
        'color': const Color(0xFFFFD700),
      },
      {
        'asset':
            'assets/kenney_space-shooter-remastered/PNG/Power-ups/bolt_gold.png',
        'points': 2,
        'size': 44.0,
        'color': const Color(0xFFBD00FF),
      },
      {
        'asset':
            'assets/kenney_space-shooter-remastered/PNG/Power-ups/shield_gold.png',
        'points': 3,
        'size': 48.0,
        'color': const Color(0xFF00F0FF),
      },
    ];

    final chosen = targetTypes[_random.nextInt(targetTypes.length)];

    setState(() {
      _activeTargets.add(
        CometTarget(
          id: _targetIdCounter++,
          x: 0.15 + (_random.nextDouble() * 0.70),
          y: 0.20 + (_random.nextDouble() * 0.60),
          size: chosen['size'] as double,
          asset: chosen['asset'] as String,
          points: chosen['points'] as int,
          glowColor: chosen['color'] as Color,
        ),
      );
    });
  }

  void _onTargetTap(CometTarget target) {
    if (_isGameOver || target.isPopped) return;

    _soundService.playMergeSound();
    setState(() {
      target.isPopped = true;
      _totalTaps++;
      _score += target.points;
      _activeTargets.removeWhere((t) => t.id == target.id);
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _soundService.playPrestigeSound();
    setState(() {
      _isGameOver = true;
    });
  }

  void _claimRewards({bool doubleWithAd = false}) {
    widget.onSessionComplete(
      taps: _totalTaps,
      scoreMultiplier: max(1.0, _score / 15.0),
      doubleWithAd: doubleWithAd,
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        width: double.infinity,
        height: 520,
        decoration: BoxDecoration(
          color: GameTheme.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFF0055).withAlpha((0.7 * 255).round()),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF0055).withAlpha((0.3 * 255).round()),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Arcade Game Area
            if (!_isGameOver) ...[
              // Floating interactive targets
              ..._activeTargets.map((target) {
                return Positioned(
                  left: target.x * 300,
                  top: target.y * 360,
                  child: GestureDetector(
                    onTap: () => _onTargetTap(target),
                    child: Container(
                      width: target.size,
                      height: target.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: target.glowColor
                                .withAlpha((0.5 * 255).round()),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        target.asset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              }),

              // HUD Bar Top
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Timer Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0055)
                            .withAlpha((0.3 * 255).round()),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFFF0055), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_rounded,
                              color: Color(0xFFFF0055), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '00:${_timeRemainingSeconds.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Color(0xFFFF0055),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700)
                            .withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFFFD700), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded,
                              color: Color(0xFFFFD700), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'SCORE: $_score',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Instructions at bottom
              const Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '⚡ TAP / SLASH TARGETS AS FAST AS YOU CAN! ⚡',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Game Over & Results Payout Screen
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0055)
                            .withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFF0055), width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded,
                              color: Color(0xFFFF0055), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'COMET RUSH COMPLETED!',
                            style: TextStyle(
                              color: Color(0xFFFF0055),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TOTAL SCORE: $_score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_totalTaps Targets Smashed in 10 Seconds!',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Prize Estimation Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: GameTheme.backgroundVoid,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.monetization_on_rounded,
                                  color: Color(0xFFFFD700), size: 22),
                              const SizedBox(height: 4),
                              Text(
                                '+${NumberFormatter.formatCredits(max(500.0, widget.fleetIncomePerLap * 25.0 * (_score / 10.0)))}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'Coins',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 10),
                              ),
                            ],
                          ),
                          if (_totalTaps >= 15)
                            Column(
                              children: [
                                const Icon(Icons.auto_awesome_rounded,
                                    color: Color(0xFFBD00FF), size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  '+${_totalTaps >= 30 ? 7 : 3} DM',
                                  style: const TextStyle(
                                    color: Color(0xFFBD00FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Text(
                                  'Gems',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 10),
                                ),
                              ],
                            ),
                          if (_totalTaps >= 25)
                            const Column(
                              children: [
                                Icon(Icons.shield_rounded,
                                    color: Color(0xFF00F0FF), size: 22),
                                SizedBox(height: 4),
                                Text(
                                  '+1 Spin',
                                  style: TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Wheel',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 10),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2X Double Claim Button
                    ElevatedButton(
                      onPressed: () {
                        AdManager().showRewardedAd(
                          onUserEarnedReward: () {
                            _claimRewards(doubleWithAd: true);
                          },
                          onAdFailed: () {
                            _claimRewards(doubleWithAd: false);
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(

                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '2X DOUBLE BOUNTY (FREE AD)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Normal Claim
                    TextButton(
                      onPressed: () => _claimRewards(doubleWithAd: false),
                      child: const Text(
                        'Claim Normal Bounty',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
}
