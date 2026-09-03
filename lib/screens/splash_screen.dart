import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'main_game_screen.dart';

/// Gamified, cinematic space tycoon splash screen with animated Panda Commander,
/// hyperspace starfields, and real-time cybernetic loading telemetry.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  Timer? _loadTimer;
  Timer? _autoLaunchTimer;
  double _loadProgress = 0.0;
  String _telemetryText = '🚀 Initializing Hyperdrive Sub-Systems...';
  bool _isReadyToLaunch = false;

  final List<String> _telemetryLogs = [
    '🚀 Initializing Hyperdrive Sub-Systems...',
    '✨ Calibrating Laser Gates & Boost Pads...',
    '🌌 Linking Starfleet Neural Grid...',
    '🐼 Commander Online! Ready for Launch!',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _startLoadingSequence();
  }

  void _startLoadingSequence() {
    _loadTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _loadProgress += 0.018;
        if (_loadProgress >= 1.0) {
          _loadProgress = 1.0;
          _isReadyToLaunch = true;
          _telemetryText = _telemetryLogs[3];
          timer.cancel();
          // Auto launch after short delay
          _autoLaunchTimer = Timer(const Duration(milliseconds: 500), () {
            if (mounted) _launchGame();
          });
        } else if (_loadProgress > 0.65) {
          _telemetryText = _telemetryLogs[2];
        } else if (_loadProgress > 0.30) {
          _telemetryText = _telemetryLogs[1];
        } else {
          _telemetryText = _telemetryLogs[0];
        }
      });
    });
  }

  void _launchGame() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainGameScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    _autoLaunchTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          // 1. Ambient Nebula Glows
          Positioned(
            top: size.height * 0.15,
            left: size.width * 0.1,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFBD00FF).withAlpha((0.15 * 255).round()),
                    const Color(0xFF00F0FF).withAlpha((0.08 * 255).round()),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Holographic Game Title
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Column(
                          children: [
                            Text(
                              'GALACTIC MERGE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4.0,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF00F0FF).withAlpha(
                                      (0.7 * 255).round(),
                                    ),
                                    blurRadius: 16.0 + _pulseController.value * 8.0,
                                  ),
                                  Shadow(
                                    color: const Color(0xFFBD00FF).withAlpha(
                                      (0.6 * 255).round(),
                                    ),
                                    blurRadius: 24.0,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700)
                                    .withAlpha((0.15 * 255).round()),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFFD700),
                                  width: 1.0,
                                ),
                              ),
                              child: const Text(
                                '⚡ INTERSTELLAR TYCOON ⚡',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const Spacer(flex: 1),

                    // Animated Panda Space Commander
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Holographic Pod Ring
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF00F0FF).withAlpha(
                                    ((0.3 + _pulseController.value * 0.4) * 255)
                                        .round(),
                                  ),
                                  width: 1.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFBD00FF).withAlpha(
                                      ((0.15 + _pulseController.value * 0.15) *
                                              255)
                                          .round(),
                                    ),
                                    blurRadius: 25.0,
                                    spreadRadius: 4.0,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Lottie Panda Animation
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Lottie.asset(
                            'assets/lottie/panda_gamer.json',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Lottie.asset(
                                'assets/Cute Panda Playing Game.json',
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, st) {
                                  return const Icon(
                                    Icons.rocket_launch_rounded,
                                    color: Color(0xFF00F0FF),
                                    size: 72,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // Telemetry Status Text
                    Text(
                      _telemetryText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Glowing Progress Bar
                    Container(
                      width: size.width * 0.72,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B132B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF00F0FF).withAlpha(80),
                          width: 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: (size.width * 0.72) * _loadProgress,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFBD00FF),
                                  Color(0xFF00F0FF),
                                  Color(0xFFFFD700),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Percentage Indicator
                    Text(
                      '${(_loadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Manual Launch Button (If completed)
                    if (_isReadyToLaunch)
                      InkWell(
                        onTap: _launchGame,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00FF88), Color(0xFF00F0FF)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FF88).withAlpha(120),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: Color(0xFF04060E),
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'ENTER FLEET COMMAND',
                                style: TextStyle(
                                  color: Color(0xFF04060E),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
