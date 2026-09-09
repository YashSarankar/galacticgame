import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'main_game_screen.dart';

/// Ultra-premium, AAA cosmic splash screen with deep space nebula gradients,
/// shimmering starfield particles, rotating neon orbital rings, floating flagship starship,
/// and smooth cyber-HUD telemetry loading sequence.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final AnimationController _orbitController;
  late final AnimationController _shimmerController;
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  final List<_StarParticle> _starfield = [];
  final Random _random = Random();
  String _telemetryText = 'Initializing orbital telemetry...';

  @override
  void initState() {
    super.initState();

    // Generate random starfield particles
    for (int i = 0; i < 65; i++) {
      _starfield.add(
        _StarParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: _random.nextDouble() * 1.8 + 0.6,
          opacity: _random.nextDouble() * 0.7 + 0.3,
          twinkleSpeed: _random.nextDouble() * 3.0 + 1.0,
          color: _random.nextBool()
              ? const Color(0xFF00F0FF)
              : (_random.nextBool()
                  ? const Color(0xFFBD00FF)
                  : const Color(0xFFFFD700)),
        ),
      );
    }

    // Floating levitation animation for the flagship
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Subtle breathing pulse for halo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Orbital ring continuous rotation
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Holographic title shimmer controller
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Progress Controller (Smooth 2.4s loading sequence)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.addListener(() {
      final val = _progressAnimation.value;
      String newText;
      if (val >= 0.90) {
        newText = '🚀 Commander Panda is ready! Launching fleet...';
      } else if (val >= 0.65) {
        newText = '⚡ Calibrating orbital laser gates & hyper-pads...';
      } else if (val >= 0.35) {
        newText = '🌌 Powering starships & dark matter matrix...';
      } else {
        newText = '✨ Initializing Galactic Merge Tycoon...';
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
        transitionDuration: const Duration(milliseconds: 700),
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
    _floatController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    _shimmerController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF060919),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF060919),
        body: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Deep Space Cosmic Nebula Gradient Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.2),
                    radius: 1.3,
                    colors: [
                      Color(0xFF131B3A),
                      Color(0xFF090D22),
                      Color(0xFF050814),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // 2. Cosmic Ambient Nebulae (Cyan & Purple Glowing Orbs)
            Positioned(
              top: size.height * 0.12,
              left: -size.width * 0.25,
              child: Container(
                width: size.width * 1.1,
                height: size.width * 1.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00F0FF).withAlpha((0.14 * 255).round()),
                      const Color(0xFF4F46E5).withAlpha((0.06 * 255).round()),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.08,
              right: -size.width * 0.25,
              child: Container(
                width: size.width * 1.1,
                height: size.width * 1.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFBD00FF).withAlpha((0.12 * 255).round()),
                      const Color(0xFF00F0FF).withAlpha((0.04 * 255).round()),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Shimmering Starfield & Concentric Telemetry Rings Custom Painter
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseController, _orbitController]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CosmicSplashPainter(
                      stars: _starfield,
                      pulseValue: _pulseController.value,
                      orbitAngle: _orbitController.value * 2 * pi,
                    ),
                  );
                },
              ),
            ),

            // 4. Main Foreground UI
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Top Brand Header Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B3A).withAlpha((0.75 * 255).round()),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00F0FF).withAlpha((0.35 * 255).round()),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withAlpha((0.15 * 255).round()),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.rocket_launch_rounded,
                            size: 13,
                            color: Color(0xFF00F0FF),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'NEXT-GEN IDLE SPACE TYCOON',
                            style: TextStyle(
                              color: Color(0xFF00F0FF),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Grand Title with Metallic Holographic Shimmer
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) {
                        return ShaderMask(
                          shaderCallback: (bounds) {
                            final shimmerPos = _shimmerController.value * 2.0 - 0.5;
                            return LinearGradient(
                              colors: const [
                                Color(0xFFFFFFFF),
                                Color(0xFF00F0FF),
                                Color(0xFFBD00FF),
                                Color(0xFF00F0FF),
                                Color(0xFFFFFFFF),
                              ],
                              stops: [
                                (shimmerPos - 0.3).clamp(0.0, 1.0),
                                (shimmerPos - 0.1).clamp(0.0, 1.0),
                                shimmerPos.clamp(0.0, 1.0),
                                (shimmerPos + 0.1).clamp(0.0, 1.0),
                                (shimmerPos + 0.3).clamp(0.0, 1.0),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'GALACTIC MERGE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.0,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF00F0FF),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ORBITAL FLEET COMMAND & SYNTHESIS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Flagship Centerpiece inside Aerospace Neon Ring
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _floatController,
                        _pulseController,
                        _orbitController,
                      ]),
                      builder: (context, _) {
                        final floatY = sin(_floatController.value * pi) * 10.0;
                        final pulse = _pulseController.value;

                        return Transform.translate(
                          offset: Offset(0, -floatY),
                          child: SizedBox(
                            width: 220,
                            height: 220,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 1. Outer Neon Breathing Halo Glow
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF00F0FF).withAlpha(
                                            ((0.28 + pulse * 0.18) * 255).round()),
                                        const Color(0xFFBD00FF).withAlpha(
                                            ((0.14 + pulse * 0.10) * 255).round()),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.65, 1.0],
                                    ),
                                  ),
                                ),

                                // 2. Cyber Glassmorphism Avatar Pod
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF0E1630).withAlpha(
                                        (0.85 * 255).round()),
                                    border: Border.all(
                                      color: const Color(0xFF00F0FF).withAlpha(
                                          ((0.45 + pulse * 0.25) * 255).round()),
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00F0FF).withAlpha(
                                            (0.35 * 255).round()),
                                        blurRadius: 28,
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFFBD00FF).withAlpha(
                                            (0.20 * 255).round()),
                                        blurRadius: 36,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: ClipOval(
                                    child: Lottie.asset(
                                      'assets/lottie/panda_gamer.json',
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, err, st) {
                                        return Lottie.asset(
                                          'assets/Cute Panda Playing Game.json',
                                          width: 140,
                                          height: 140,
                                          fit: BoxFit.contain,
                                          errorBuilder: (c, e, s) => Image.asset(
                                            'assets/icon/splash_logo.png',
                                            width: 95,
                                            height: 95,
                                            fit: BoxFit.contain,
                                            errorBuilder: (cx, er, st2) => const Icon(
                                              Icons.rocket_launch_rounded,
                                              size: 68,
                                              color: Color(0xFF00F0FF),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                // 3. Dual Counter-Rotating Satellite Orbit Beacons
                                Transform.rotate(
                                  angle: _orbitController.value * 2 * pi,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF00F0FF),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00F0FF)
                                                .withAlpha((0.9 * 255).round()),
                                            blurRadius: 10,
                                            spreadRadius: 2.5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Transform.rotate(
                                  angle: -(_orbitController.value * 2 * pi),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFFFD700),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFD700)
                                                .withAlpha((0.9 * 255).round()),
                                            blurRadius: 9,
                                            spreadRadius: 2.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 3),

                    // Dynamic Telemetry HUD Terminal
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: Row(
                        key: ValueKey(_telemetryText),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF00FF88),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF00FF88),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Text(
                              _telemetryText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ultra-Sleek Neon Laser Progress Bar
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, _) {
                        final progress = _progressAnimation.value.clamp(0.0, 1.0);
                        final barWidth = size.width * 0.78;

                        return Column(
                          children: [
                            Container(
                              width: barWidth,
                              height: 10,
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E1630),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00F0FF)
                                      .withAlpha((0.35 * 255).round()),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00F0FF)
                                        .withAlpha((0.10 * 255).round()),
                                    blurRadius: 10,
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
                                        width: (barWidth - 3) * progress,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF00F0FF),
                                              Color(0xFF4F46E5),
                                              Color(0xFFBD00FF),
                                              Color(0xFF00FF88),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00F0FF)
                                                  .withAlpha((0.7 * 255).round()),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'SYS.VER 1.0.0 (RELEASE)',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const Spacer(flex: 3),

                    // Footer Signature
                    const Text(
                      'FLAME 2D ENGINE • 60 FPS ORBITAL PHYSICS',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Starfield Particle Model
class _StarParticle {
  final double x;
  final double y;
  final double radius;
  final double opacity;
  final double twinkleSpeed;
  final Color color;

  _StarParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.twinkleSpeed,
    required this.color,
  });
}

/// Custom painter rendering Starfield & Futuristic Orbital HUD Telemetry
class _CosmicSplashPainter extends CustomPainter {
  final List<_StarParticle> stars;
  final double pulseValue;
  final double orbitAngle;

  _CosmicSplashPainter({
    required this.stars,
    required this.pulseValue,
    required this.orbitAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Starfield
    for (final star in stars) {
      final double twinkle =
          (sin(orbitAngle * star.twinkleSpeed + star.x * 10) + 1.0) / 2.0;
      final double alpha = (star.opacity * (0.4 + twinkle * 0.6)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = star.color.withAlpha((alpha * 255).round())
        ..style = PaintingStyle.fill;

      final double px = star.x * size.width;
      final double py = star.y * size.height;

      canvas.drawCircle(Offset(px, py), star.radius, paint);
    }

    // 2. Concentric Orbital Telemetry Rings
    final center = Offset(size.width / 2, size.height * 0.44);

    final cyanRing = Paint()
      ..color = const Color(0xFF00F0FF).withAlpha((0.15 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final purpleRing = Paint()
      ..color = const Color(0xFFBD00FF).withAlpha((0.12 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dashedRing = Paint()
      ..color = const Color(0xFF00FF88).withAlpha((0.10 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 95.0 + pulseValue * 4.0, cyanRing);
    canvas.drawCircle(center, 135.0, dashedRing);
    canvas.drawCircle(center, 175.0 + pulseValue * 6.0, purpleRing);
  }

  @override
  bool shouldRepaint(covariant _CosmicSplashPainter oldDelegate) => true;
}
