import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'main_game_screen.dart';

/// Ultra-clean, professional aerospace splash screen with pristine white background,
/// glowing orbital rings, floating flagship starship, and smooth telemetry loading.
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
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  String _telemetryText = 'Initializing orbital telemetry...';

  @override
  void initState() {
    super.initState();

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

    // Progress Controller (Smooth 2.2s loading sequence)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.addListener(() {
      final val = _progressAnimation.value;
      String newText;
      if (val >= 0.88) {
        newText = '🐼 Commander Panda is ready! Launching...';
      } else if (val >= 0.60) {
        newText = '🎋 Calibrating orbital laser gates & telemetry...';
      } else if (val >= 0.30) {
        newText = '🚀 Powering up starships & dark matter matrix...';
      } else {
        newText = '✨ Initializing Galactic Merge...';
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
    _floatController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFFF8FAFC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Subtle Ambient Studio Glows
            Positioned(
              top: -size.height * 0.1,
              child: Container(
                width: size.width * 1.4,
                height: size.height * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00F0FF).withAlpha((0.08 * 255).round()),
                      const Color(0xFF4F46E5).withAlpha((0.04 * 255).round()),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              child: Container(
                width: size.width * 1.4,
                height: size.height * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFBD00FF).withAlpha((0.05 * 255).round()),
                      const Color(0xFF00F0FF).withAlpha((0.02 * 255).round()),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // 2. Background Orbital Grid Pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _CosmicGridPainter(
                  pulseValue: _pulseController.value,
                  orbitAngle: _orbitController.value * 2 * pi,
                ),
              ),
            ),

            // 3. Main Center Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Top Brand Header
                    Column(
                      children: [
                        // Subtitle Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha((0.03 * 255).round()),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.rocket_launch_rounded,
                                size: 12,
                                color: Color(0xFF0284C7),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'NEXT-GEN IDLE TYCOON',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title with Clean Obsidian Gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF0F172A),
                              Color(0xFF1E293B),
                              Color(0xFF0284C7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'GALACTIC MERGE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // Flagship Centerpiece inside Aerospace Halo Ring
                    AnimatedBuilder(
                      animation: Listenable.merge([_floatController, _pulseController, _orbitController]),
                      builder: (context, _) {
                        final floatY = sin(_floatController.value * pi) * 9.0;
                        final pulse = _pulseController.value;

                        return Transform.translate(
                          offset: Offset(0, -floatY),
                          child: SizedBox(
                            width: 200,
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Ambient Halo Glow
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF00F0FF).withAlpha(((0.18 + pulse * 0.12) * 255).round()),
                                        const Color(0xFF4F46E5).withAlpha(((0.08 + pulse * 0.06) * 255).round()),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.6, 1.0],
                                    ),
                                  ),
                                ),

                                // Elevated Aerospace Glass Card with Animated Panda
                                Container(
                                  width: 155,
                                  height: 155,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFFFFFF),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A).withAlpha((0.08 * 255).round()),
                                        blurRadius: 28,
                                        offset: const Offset(0, 12),
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF00F0FF).withAlpha((0.15 * 255).round()),
                                        blurRadius: 20,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: ClipOval(
                                    child: Lottie.asset(
                                      'assets/lottie/panda_gamer.json',
                                      width: 135,
                                      height: 135,
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, err, st) {
                                        return Lottie.asset(
                                          'assets/Cute Panda Playing Game.json',
                                          width: 135,
                                          height: 135,
                                          fit: BoxFit.contain,
                                          errorBuilder: (c, e, s) => Image.asset(
                                            'assets/icon/splash_logo.png',
                                            width: 88,
                                            height: 88,
                                            fit: BoxFit.contain,
                                            errorBuilder: (cx, er, st2) => const Icon(
                                              Icons.rocket_launch_rounded,
                                              size: 64,
                                              color: Color(0xFF0284C7),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                // Orbiting Satellite Beacon
                                Transform.rotate(
                                  angle: _orbitController.value * 2 * pi,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF0284C7),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0284C7).withAlpha((0.6 * 255).round()),
                                            blurRadius: 8,
                                            spreadRadius: 1.5,
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

                    const Spacer(flex: 2),

                    // Dynamic Telemetry Status
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        _telemetryText,
                        key: ValueKey(_telemetryText),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Modern Precision Progress Bar
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, _) {
                        final progress = _progressAnimation.value.clamp(0.0, 1.0);
                        final barWidth = size.width * 0.72;

                        return Column(
                          children: [
                            Container(
                              width: barWidth,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: barWidth * progress,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF0284C7),
                                              Color(0xFF4F46E5),
                                              Color(0xFF00F0FF),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0284C7).withAlpha(100),
                                              blurRadius: 6,
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
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 12.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const Spacer(flex: 3),

                    // Footer Aerospace Signature
                    const Text(
                      'FLAME ENGINE • 60 FPS ORBITAL PHYSICS',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
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

/// Custom painter rendering delicate orbital geometric curves
class _CosmicGridPainter extends CustomPainter {
  final double pulseValue;
  final double orbitAngle;

  _CosmicGridPainter({required this.pulseValue, required this.orbitAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);

    final linePaint = Paint()
      ..color = const Color(0xFF0284C7).withAlpha((0.06 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dashPaint = Paint()
      ..color = const Color(0xFF64748B).withAlpha((0.10 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Concentric orbital guidance rings
    canvas.drawCircle(center, 95.0, linePaint);
    canvas.drawCircle(center, 140.0, dashPaint);
    canvas.drawCircle(center, 190.0, linePaint);
  }

  @override
  bool shouldRepaint(covariant _CosmicGridPainter oldDelegate) => true;
}
