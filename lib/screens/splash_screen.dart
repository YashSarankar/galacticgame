import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'main_game_screen.dart';

/// Delightful, ultra-cute space tycoon splash screen with floating Commander Panda,
/// twinkling cosmic stars, cute loading telemetry, and automatic smooth transition.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _floatController;
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  final List<_TwinkleStar> _stars = [];
  String _telemetryText = '🚀 Powering up cute starships...';

  @override
  void initState() {
    super.initState();

    // Generate random twinkling stars
    final rng = Random();
    for (int i = 0; i < 30; i++) {
      _stars.add(_TwinkleStar(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 1.5 + rng.nextDouble() * 2.5,
        twinkleSpeed: 0.8 + rng.nextDouble() * 1.5,
        phase: rng.nextDouble() * 2 * pi,
      ));
    }

    // Gentle holographic pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Cute bobbing / floating animation for Panda
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Progress Controller (Smooth automatic loading)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.addListener(() {
      final val = _progressAnimation.value;
      String newText;
      if (val >= 0.85) {
        newText = '🐼 Commander Panda is ready! Launching...';
      } else if (val >= 0.55) {
        newText = '🎋 Feeding Commander Panda bamboo snacks...';
      } else if (val >= 0.25) {
        newText = '✨ Polishing laser gates & boost pads...';
      } else {
        newText = '🚀 Powering up cute starships...';
      }
      if (newText != _telemetryText) {
        setState(() {
          _telemetryText = newText;
        });
      }
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _launchGame();
      }
    });

    _progressController.forward();
  }

  void _launchGame() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
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
    _pulseController.dispose();
    _floatController.dispose();
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
          // 1. Twinkling Cosmic Stars Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _StarfieldPainter(
                    stars: _stars,
                    animationValue: _pulseController.value,
                  ),
                );
              },
            ),
          ),

          // 2. Ambient Pastel Nebula Glow
          Positioned(
            top: size.height * 0.18,
            left: size.width * 0.1,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFBD00FF).withAlpha((0.20 * 255).round()),
                    const Color(0xFF00F0FF).withAlpha((0.10 * 255).round()),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 3. Main Center Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Game Title with Neon Gradient Glow
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF00F0FF),
                                  Color(0xFFFFD700),
                                  Color(0xFFFF70A6),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'GALACTIC MERGE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withAlpha((0.15 * 255).round()),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFFFD700).withAlpha(180),
                                  width: 1.0,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('⭐', style: TextStyle(fontSize: 10)),
                                  SizedBox(width: 4),
                                  Text(
                                    'IDLE SPACE TYCOON',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text('⭐', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const Spacer(flex: 1),

                    // Cute Floating Panda Commander in Holographic Portal
                    AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, child) {
                        final floatOffset = sin(_floatController.value * pi) * 8.0;
                        return Transform.translate(
                          offset: Offset(0, -floatOffset),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glowing Portal Ring
                              Container(
                                width: 210,
                                height: 210,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF00F0FF).withAlpha(
                                      ((0.35 + _pulseController.value * 0.35) * 255).round(),
                                    ),
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFBD00FF).withAlpha(
                                        ((0.20 + _pulseController.value * 0.20) * 255).round(),
                                      ),
                                      blurRadius: 30.0,
                                      spreadRadius: 6.0,
                                    ),
                                  ],
                                ),
                              ),

                              // Lottie Cute Panda Animation
                              SizedBox(
                                width: 190,
                                height: 190,
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
                        );
                      },
                    ),

                    const Spacer(flex: 2),

                    // Cute Telemetry Loading Status
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _telemetryText,
                        key: ValueKey(_telemetryText),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Smooth Holographic Progress Bar Capsule with Glow
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        final progress = _progressAnimation.value.clamp(0.0, 1.0);
                        final barWidth = size.width * 0.70;

                        return Column(
                          children: [
                            Container(
                              width: barWidth,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C132B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF00F0FF).withAlpha(90),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F0FF).withAlpha(25),
                                    blurRadius: 8.0,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: barWidth * progress,
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
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const Spacer(flex: 1),
                    const SizedBox(height: 18),
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

class _TwinkleStar {
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;
  final double phase;

  _TwinkleStar({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.phase,
  });
}

class _StarfieldPainter extends CustomPainter {
  final List<_TwinkleStar> stars;
  final double animationValue;

  _StarfieldPainter({required this.stars, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final double twinkle = (sin(animationValue * 2 * pi * star.twinkleSpeed + star.phase) + 1.0) / 2.0;
      final double opacity = (0.25 + twinkle * 0.75).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = Colors.white.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size * (0.8 + twinkle * 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) => true;
}
