import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Interactive Foolproof Guided Onboarding Overlay with animated pulsing hand pointer,
/// dynamic spotlight cutout highlighting targets, and Panda Commander holographic speech bubble.
class TutorialGuideOverlay extends StatefulWidget {
  final int tutorialStep;
  final GlobalKey? targetKey;
  final VoidCallback onSkip;
  final VoidCallback? onStepAction;

  const TutorialGuideOverlay({
    super.key,
    required this.tutorialStep,
    this.targetKey,
    required this.onSkip,
    this.onStepAction,
  });

  @override
  State<TutorialGuideOverlay> createState() => _TutorialGuideOverlayState();
}

class _TutorialGuideOverlayState extends State<TutorialGuideOverlay>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: -8.0, end: 12.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveTargetRect());
  }

  @override
  void didUpdateWidget(TutorialGuideOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tutorialStep != widget.tutorialStep ||
        oldWidget.targetKey != widget.targetKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveTargetRect());
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _resolveTargetRect() {
    if (!mounted) return;
    if (widget.targetKey != null &&
        widget.targetKey!.currentContext != null) {
      final renderBox = widget.targetKey!.currentContext!
          .findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        setState(() {
          _targetRect = position & size;
        });
        return;
      }
    }

    // Fallback based on step if key is not attached yet
    final screenSize = MediaQuery.of(context).size;
    Rect? fallback;
    switch (widget.tutorialStep) {
      case 0: // Drag ship / Track
        fallback = Rect.fromCenter(
          center: Offset(screenSize.width * 0.22, screenSize.height * 0.65),
          width: 76,
          height: 76,
        );
        break;
      case 1: // Buy Ship
        fallback = Rect.fromCenter(
          center: Offset(screenSize.width * 0.5, screenSize.height * 0.92),
          width: screenSize.width * 0.88,
          height: 52,
        );
        break;
      case 2: // Merge Ships
        fallback = Rect.fromCenter(
          center: Offset(screenSize.width * 0.35, screenSize.height * 0.65),
          width: 140,
          height: 76,
        );
        break;
      case 3: // Tap Track
        fallback = Rect.fromCenter(
          center: Offset(screenSize.width * 0.5, screenSize.height * 0.35),
          width: screenSize.width * 0.85,
          height: 140,
        );
        break;
      case 4: // Fleet Speed
        fallback = Rect.fromCenter(
          center: Offset(screenSize.width * 0.25, screenSize.height * 0.48),
          width: 110,
          height: 48,
        );
        break;
      default:
        fallback = null;
    }
    setState(() {
      _targetRect = fallback;
    });
  }

  TutorialStepData _getStepData() {
    switch (widget.tutorialStep) {
      case 0:
        return const TutorialStepData(
          stepNumber: 1,
          totalSteps: 5,
          title: 'LET\'S RACE! 🏎️',
          instruction:
              'Drag your spaceship up onto the track to start making coins! 💰',
          actionHint: 'DRAG SHIP TO TRACK 👆',
          icon: Icons.flight_takeoff_rounded,
          themeColor: Color(0xFF00F0FF),
        );
      case 1:
        return const TutorialStepData(
          stepNumber: 2,
          totalSteps: 5,
          title: 'GET MORE SHIPS! 🚀',
          instruction:
              'Tap the big green button below to buy your second ship! Easy peasy!',
          actionHint: 'TAP BUY SHIP 👇',
          icon: Icons.shopping_cart_rounded,
          themeColor: Color(0xFFFFD700),
        );
      case 2:
        return const TutorialStepData(
          stepNumber: 3,
          totalSteps: 5,
          title: 'SMASH TO UPGRADE! 💥',
          instruction:
              'Drag identical ships together to merge into a faster, cooler spaceship! 🚀+🚀=🛸',
          actionHint: 'DRAG TO MERGE 🚀+🚀',
          icon: Icons.auto_awesome_rounded,
          themeColor: Color(0xFFBD00FF),
        );
      case 3:
        return const TutorialStepData(
          stepNumber: 4,
          totalSteps: 5,
          title: 'TURBO SPEED! ⚡',
          instruction:
              'Tap the racetrack fast! Watch your ships zoom and fly in turbo mode!',
          actionHint: 'TAP TRACK FAST ⚡',
          icon: Icons.bolt_rounded,
          themeColor: Color(0xFFFF0055),
        );
      case 4:
      default:
        return const TutorialStepData(
          stepNumber: 5,
          totalSteps: 5,
          title: 'BOOST ENGINE SPEED! 🏁',
          instruction:
              'Tap [SPEED] to permanently make all your ships fly faster forever!',
          actionHint: 'TAP SPEED ⚡',
          icon: Icons.speed_rounded,
          themeColor: Color(0xFF00FF88),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tutorialStep >= 5) {
      return const SizedBox.shrink();
    }

    final stepData = _getStepData();
    final screenSize = MediaQuery.of(context).size;
    final target = _targetRect;

    // Calculate pointer position relative to target
    Offset pointerPos = Offset(screenSize.width * 0.5, screenSize.height * 0.7);
    bool pointUpwards = false;

    if (target != null) {
      if (target.top > screenSize.height * 0.6) {
        // Target is in bottom area (e.g. Buy button) -> point downwards from above
        pointerPos = Offset(target.center.dx, target.top - 44);
        pointUpwards = false;
      } else if (target.bottom < screenSize.height * 0.35) {
        // Target is high -> point upwards from below
        pointerPos = Offset(target.center.dx, target.bottom + 12);
        pointUpwards = true;
      } else {
        // Middle target (e.g. grid slot or speed button) -> point from above
        pointerPos = Offset(target.center.dx, target.top - 46);
        pointUpwards = false;
      }
    }

    return Stack(
      children: [
        // 1. Dimmed Spotlight Cutout (Passes touch events through to target)
        if (target != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: CustomPaint(
                painter: _SpotlightHolePainter(
                  targetRect: target.inflate(8),
                  spotlightColor: stepData.themeColor,
                  pulseScale: _pulseAnimation.value,
                ),
              ),
            ),
          ),

        // 2. Animated Bouncing Hand Pointer
        Positioned(
          left: pointerPos.dx - 28,
          top: pointerPos.dy + (pointUpwards ? -_bounceAnimation.value : _bounceAnimation.value),
          child: IgnorePointer(
            ignoring: true,
            child: _BouncingPointerWidget(
              color: stepData.themeColor,
              pointUpwards: pointUpwards,
              pulseScale: _pulseAnimation.value,
            ),
          ),
        ),

        // 3. Panda Commander Holographic Speech Bubble (Positioned intelligently)
        Positioned(
          left: 14,
          right: 14,
          top: (target != null && target.top < screenSize.height * 0.45)
              ? screenSize.height * 0.58
              : 80,
          child: _PandaCommanderDialogBubble(
            stepData: stepData,
            onSkip: widget.onSkip,
          ),
        ),
      ],
    );
  }
}

/// Dynamic Spotlight Background with Cutout & Glowing Pulsing Ring
class _SpotlightHolePainter extends CustomPainter {
  final Rect targetRect;
  final Color spotlightColor;
  final double pulseScale;

  _SpotlightHolePainter({
    required this.targetRect,
    required this.spotlightColor,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(targetRect, const Radius.circular(16));

    final backgroundPaint = Paint()
      ..color = Colors.black.withAlpha(120)
      ..style = PaintingStyle.fill;

    // Dark backdrop with transparent hole over target
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // Glowing Neon Target Border
    final glowPaint = Paint()
      ..color = spotlightColor.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(rrect, glowPaint);

    // Expanding Radar Pulse Wave
    final double expandWidth = (targetRect.width * (pulseScale - 1.0)) * 0.5;
    final double expandHeight = (targetRect.height * (pulseScale - 1.0)) * 0.5;
    final pulseRect = targetRect.inflate(max(expandWidth, expandHeight));
    final pulseRRect = RRect.fromRectAndRadius(pulseRect, const Radius.circular(20));

    final pulsePaint = Paint()
      ..color = spotlightColor.withAlpha(((1.4 - pulseScale).clamp(0.0, 1.0) * 160).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawRRect(pulseRRect, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightHolePainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.spotlightColor != spotlightColor ||
        oldDelegate.pulseScale != pulseScale;
  }
}

/// Glowing Bouncing Hand Pointer
class _BouncingPointerWidget extends StatelessWidget {
  final Color color;
  final bool pointUpwards;
  final double pulseScale;

  const _BouncingPointerWidget({
    required this.color,
    required this.pointUpwards,
    required this.pulseScale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pointUpwards)
          _buildFingerIcon()
        else ...[
          _buildRadarRings(),
          const SizedBox(height: 2),
          _buildFingerIcon(),
        ],
      ],
    );
  }

  Widget _buildFingerIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0F172A).withAlpha(220),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(160),
            blurRadius: 18,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Transform.rotate(
        angle: pointUpwards ? pi : 0,
        child: Icon(
          Icons.touch_app_rounded,
          color: color,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildRadarRings() {
    return Container(
      width: 24 * pulseScale,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withAlpha(((1.4 - pulseScale).clamp(0.0, 1.0) * 180).toInt()),
      ),
    );
  }
}

/// Panda Commander Holographic Speech Bubble
class _PandaCommanderDialogBubble extends StatelessWidget {
  final TutorialStepData stepData;
  final VoidCallback onSkip;

  const _PandaCommanderDialogBubble({
    required this.stepData,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A).withAlpha(240),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stepData.themeColor.withAlpha(200), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: stepData.themeColor.withAlpha(70),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(180),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Holographic Panda Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: stepData.themeColor, width: 1.8),
              color: const Color(0xFF131B3A),
              boxShadow: [
                BoxShadow(
                  color: stepData.themeColor.withAlpha(90),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipOval(
              child: Lottie.asset(
                'assets/lottie/panda_gamer.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Lottie.asset(
                    'assets/Cute Panda Playing Game.json',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) {
                      return Icon(
                        Icons.smart_toy_rounded,
                        color: stepData.themeColor,
                        size: 28,
                      );
                    },
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Speech Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Step Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: stepData.themeColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: stepData.themeColor.withAlpha(120),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'STEP ${stepData.stepNumber}/${stepData.totalSteps} • ${stepData.title}',
                        style: TextStyle(
                          color: stepData.themeColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Skip Button
                    GestureDetector(
                      onTap: onSkip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SKIP',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  stepData.instruction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(stepData.icon, color: stepData.themeColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      stepData.actionHint,
                      style: TextStyle(
                        color: stepData.themeColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Metadata model for a tutorial step
class TutorialStepData {
  final int stepNumber;
  final int totalSteps;
  final String title;
  final String instruction;
  final String actionHint;
  final IconData icon;
  final Color themeColor;

  const TutorialStepData({
    required this.stepNumber,
    required this.totalSteps,
    required this.title,
    required this.instruction,
    required this.actionHint,
    required this.icon,
    required this.themeColor,
  });
}
