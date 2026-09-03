import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Enum defining the interactive demonstration gesture
enum TutorialGestureType {
  dragToTrack, // Glides smoothly from hangar slot to racetrack with ghost ship
  tapRacetrack, // Energetic rhythmic double-tapping on racetrack with shockwaves
  tapButton, // Tactile tap on target button
  dragToMerge, // Smooth horizontal glide from Slot 0 to Slot 1 with merge burst
}

/// Interactive Foolproof Guided Onboarding Overlay with 100X professional animated finger gestures,
/// dynamic path trajectory, ghost ship flight, rhythmic shockwave tapping, and Panda Commander card.
class TutorialGuideOverlay extends StatefulWidget {
  final int tutorialStep;
  final GlobalKey? targetKey;
  final GlobalKey? destinationKey;
  final VoidCallback onSkip;
  final VoidCallback? onStepAction;

  const TutorialGuideOverlay({
    super.key,
    required this.tutorialStep,
    this.targetKey,
    this.destinationKey,
    required this.onSkip,
    this.onStepAction,
  });

  @override
  State<TutorialGuideOverlay> createState() => _TutorialGuideOverlayState();
}

class _TutorialGuideOverlayState extends State<TutorialGuideOverlay>
    with TickerProviderStateMixin {
  // Drag motion controller (for Step 0 and Step 3)
  late final AnimationController _dragController;

  // Rhythmic double-tap controller (for Step 1)
  late final AnimationController _tapController;

  // Ambient pulsing radar controller (for target highlights)
  late final AnimationController _pulseController;
  late final AnimationController _stepTransitionController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _stepFadeAnimation;
  late final Animation<double> _stepScaleAnimation;

  Rect? _targetRect;
  Rect? _destinationRect;

  @override
  void initState() {
    super.initState();

    // 3.2 seconds total per drag demonstration for clear, relaxed, buttery flight
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );

    _stepTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _stepFadeAnimation = CurvedAnimation(
      parent: _stepTransitionController,
      curve: Curves.easeOutCubic,
    );

    _stepScaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _stepTransitionController,
        curve: Curves.easeOutBack,
      ),
    );

    _stepTransitionController.forward(from: 0.0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRects());
  }

  @override
  void didUpdateWidget(TutorialGuideOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tutorialStep != widget.tutorialStep) {
      _stepTransitionController.forward(from: 0.0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRects());
    } else if (oldWidget.targetKey != widget.targetKey ||
        oldWidget.destinationKey != widget.destinationKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRects());
    }
  }

  @override
  void dispose() {
    _dragController.dispose();
    _tapController.dispose();
    _pulseController.dispose();
    _stepTransitionController.dispose();
    super.dispose();
  }

  void _resolveRects() {
    if (!mounted) return;

    Rect? tRect = _getRectFor(context, widget.targetKey);
    Rect? dRect = _getRectFor(context, widget.destinationKey);

    // Fallbacks if keys are not ready yet
    final screenSize = MediaQuery.of(context).size;
    if (tRect == null) {
      switch (widget.tutorialStep) {
        case 0: // Slot 0
          tRect = Rect.fromCenter(
            center: Offset(screenSize.width * 0.22, screenSize.height * 0.65),
            width: 76,
            height: 76,
          );
          dRect ??= Rect.fromCenter(
            center: Offset(screenSize.width * 0.5, screenSize.height * 0.35),
            width: screenSize.width * 0.85,
            height: 150,
          );
          break;
        case 1: // Track Tap
          tRect = Rect.fromCenter(
            center: Offset(screenSize.width * 0.5, screenSize.height * 0.35),
            width: screenSize.width * 0.85,
            height: 150,
          );
          break;
        case 2: // Buy Ship
          tRect = Rect.fromCenter(
            center: Offset(screenSize.width * 0.5, screenSize.height * 0.92),
            width: screenSize.width * 0.88,
            height: 52,
          );
          break;
        case 3: // Merge: Slot 0 -> Slot 1
          tRect = Rect.fromCenter(
            center: Offset(screenSize.width * 0.22, screenSize.height * 0.65),
            width: 76,
            height: 76,
          );
          dRect ??= Rect.fromCenter(
            center: Offset(screenSize.width * 0.45, screenSize.height * 0.65),
            width: 76,
            height: 76,
          );
          break;
        case 4: // Circuit Laser / Speed
          tRect = Rect.fromCenter(
            center: Offset(screenSize.width * 0.25, screenSize.height * 0.48),
            width: 120,
            height: 48,
          );
          break;
        case 10: // Contextual Sort Button
          tRect = Rect.fromCenter(
            center: Offset(screenSize.width * 0.22, screenSize.height * 0.94),
            width: 52,
            height: 52,
          );
          break;
      }
    }

    setState(() {
      _targetRect = tRect;
      _destinationRect = dRect;
    });
  }

  TutorialStepData _getStepData() {
    switch (widget.tutorialStep) {
      case 0:
        return const TutorialStepData(
          stepNumber: 1,
          totalSteps: 5,
          title: 'MISSION 1: LAUNCH FIGHTER! 🚀',
          instruction:
              'Cadet, your first Starfighter is ready in Hangar Bay 1! Drag it up to the orbit track to start generating credits! 💰',
          actionHint: 'DRAG SHIP UP TO TRACK 👆',
          icon: Icons.flight_takeoff_rounded,
          themeColor: Color(0xFF00F0FF),
          gestureType: TutorialGestureType.dragToTrack,
        );
      case 1:
        return const TutorialStepData(
          stepNumber: 2,
          totalSteps: 5,
          title: 'MISSION 2: TURBO WARP SPEED! ⚡',
          instruction:
              'Cadet, tap the racetrack 3 times fast! Watch your starship enter supersonic boost and earn rapid coins!',
          actionHint: 'TAP 3 TIMES FAST ⚡',
          icon: Icons.bolt_rounded,
          themeColor: Color(0xFFFF0055),
          gestureType: TutorialGestureType.tapRacetrack,
        );
      case 2:
        return const TutorialStepData(
          stepNumber: 3,
          totalSteps: 5,
          title: 'MISSION 3: FLEET EXPANSION! 🛸',
          instruction:
              'You earned credits from your first lap! Tap [BUY SHIP] below to deploy your second spaceship to the hangar!',
          actionHint: 'TAP BUY SHIP 👇',
          icon: Icons.shopping_cart_rounded,
          themeColor: Color(0xFFFFD700),
          gestureType: TutorialGestureType.tapButton,
        );
      case 3:
        return const TutorialStepData(
          stepNumber: 4,
          totalSteps: 5,
          title: 'MISSION 4: FUSION FORGE! 💥',
          instruction:
              'Cadet, smash matching Level 1 fighters together to forge a faster, high-yield Level 2 Cruiser! 🚀+🚀=🛸',
          actionHint: 'DRAG SHIP 1 ONTO SHIP 2 💥',
          icon: Icons.auto_awesome_rounded,
          themeColor: Color(0xFFBD00FF),
          gestureType: TutorialGestureType.dragToMerge,
        );
      case 10: // Contextual Auto-Sort Tutorial
        return const TutorialStepData(
          stepNumber: 1,
          totalSteps: 1,
          title: 'HANGAR PROTOCOL: AUTO-SORT! 🧹',
          instruction:
              'Commander, your fleet is scattered! Tap [SORT] to instantly arrange your spaceships by Tier and earn bonus Dark Matter!',
          actionHint: 'TAP SORT BUTTON 👇',
          icon: Icons.sort_rounded,
          themeColor: Color(0xFF00F0FF),
          gestureType: TutorialGestureType.tapButton,
        );
      case 4:
      default:
        return const TutorialStepData(
          stepNumber: 5,
          totalSteps: 5,
          title: 'MISSION 5: CIRCUIT UPGRADE! 🏁',
          instruction:
              'Cadet, upgrade your racetrack lasers or engine speed below to permanently double your earnings every lap!',
          actionHint: 'TAP SPEED OR LASER GATE 🏁',
          icon: Icons.speed_rounded,
          themeColor: Color(0xFF00FF88),
          gestureType: TutorialGestureType.tapButton,
        );
    }
  }

  Rect? _getRectFor(BuildContext context, GlobalKey? key) {
    if (key?.currentContext == null) return null;
    try {
      final rb = key!.currentContext!.findRenderObject() as RenderBox?;
      final overlayBox = context.findRenderObject() as RenderBox?;
      if (rb != null && rb.hasSize && rb.size.width > 0 && rb.size.height > 0) {
        final globalPos = rb.localToGlobal(Offset.zero);
        final localPos = overlayBox != null
            ? overlayBox.globalToLocal(globalPos)
            : globalPos;
        return localPos & rb.size;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tutorialStep >= 5 && widget.tutorialStep != 10) {
      return const SizedBox.shrink();
    }

    final stepData = _getStepData();
    final screenSize = MediaQuery.of(context).size;
    final target = _getRectFor(context, widget.targetKey) ?? _targetRect;
    final destination = _getRectFor(context, widget.destinationKey) ?? _destinationRect;

    // Dynamically position speech bubble so it NEVER covers target or finger path
    final bool isTargetInBottomHalf =
        target != null && target.center.dy > (screenSize.height * 0.48);
    final double bubbleTop =
        isTargetInBottomHalf ? 54.0 : (screenSize.height - 180.0);

    return FadeTransition(
      opacity: _stepFadeAnimation,
      child: Stack(
        children: [
          // 1. Semi-transparent spotlight cutout over target (and destination if dragging)
          if (target != null)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    targetRect: target.inflate(6),
                    destinationRect: destination?.inflate(6),
                    spotlightColor: stepData.themeColor,
                    pulseScale: _pulseAnimation.value,
                  ),
                ),
              ),
            ),

          // 2. Trajectory Flight Path & Animated Drag Gesture (Steps 0 & 3)
          if ((stepData.gestureType == TutorialGestureType.dragToTrack ||
                  stepData.gestureType == TutorialGestureType.dragToMerge) &&
              target != null &&
              destination != null)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedBuilder(
                  animation: _dragController,
                  builder: (context, child) {
                    return _buildDragGestureOverlay(
                      start: target.center,
                      end: destination.center,
                      progress: _dragController.value,
                      themeColor: stepData.themeColor,
                      isMerge: stepData.gestureType == TutorialGestureType.dragToMerge,
                    );
                  },
                ),
              ),
            ),

          // 3. Rhythmic Double-Tap Shockwave Gesture (Step 1)
          if (stepData.gestureType == TutorialGestureType.tapRacetrack &&
              target != null)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedBuilder(
                  animation: _tapController,
                  builder: (context, child) {
                    return _buildRhythmicTapOverlay(
                      center: target.center,
                      progress: _tapController.value,
                      themeColor: stepData.themeColor,
                    );
                  },
                ),
              ),
            ),

          // 4. Clean Button Tap Indicator (Steps 2 & 4)
          if (stepData.gestureType == TutorialGestureType.tapButton &&
              target != null)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedBuilder(
                  animation: _tapController,
                  builder: (context, child) {
                    return _buildButtonTapOverlay(
                      center: target.center,
                      progress: _tapController.value,
                      themeColor: stepData.themeColor,
                    );
                  },
                ),
              ),
            ),

          // 5. Panda Commander Holographic Speech Card (Smooth Slide & Cross-fade Transitions)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            left: 14,
            right: 14,
            top: bubbleTop,
            child: ScaleTransition(
              scale: _stepScaleAnimation,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.08),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: _PandaCommanderDialogBubble(
                  key: ValueKey(widget.tutorialStep),
                  stepData: stepData,
                  onSkip: widget.onSkip,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a buttery smooth drag trajectory animation with glowing trail, touch ring, and ghost ship
  /// Builds a buttery smooth drag trajectory animation with glowing trail, touch ring, and ghost ship
  Widget _buildDragGestureOverlay({
    required Offset start,
    required Offset end,
    required double progress,
    required Color themeColor,
    required bool isMerge,
  }) {
    final double t = progress.clamp(0.0, 1.0);
    double flightT = 0.0;
    double opacity = 1.0;
    double touchScale = 1.0;
    bool isTouching = false;
    bool isBursting = false;

    if (t < 0.16) {
      flightT = 0.0;
      opacity = (t / 0.14).clamp(0.0, 1.0);
      touchScale = Curves.easeOutBack.transform((t / 0.16).clamp(0.0, 1.0));
      isTouching = true;
    } else if (t < 0.78) {
      final double rawT = (t - 0.16) / 0.62;
      flightT = Curves.easeInOutCubic.transform(rawT.clamp(0.0, 1.0));
      isTouching = true;
      touchScale = 1.0;
      opacity = 1.0;
    } else if (t < 0.88) {
      flightT = 1.0;
      isBursting = true;
      isTouching = false;
      touchScale = 1.0;
      opacity = 1.0;
    } else {
      flightT = 1.0;
      isTouching = false;
      touchScale = 0.0;
      opacity = (1.0 - ((t - 0.88) / 0.12)).clamp(0.0, 1.0);
    }

    // Follow the EXACT quadratic bezier curve matching _TrajectoryPathPainter
    final midX = (start.dx + end.dx) / 2 + (start.dx < end.dx ? -16.0 : 16.0);
    final midY = (start.dy + end.dy) / 2 - 20.0;
    final u = 1.0 - flightT;
    final currentPos = Offset(
      (u * u * start.dx) + (2 * u * flightT * midX) + (flightT * flightT * end.dx),
      (u * u * start.dy) + (2 * u * flightT * midY) + (flightT * flightT * end.dy),
    );

    return Stack(
      children: [
        // Dotted Neon Trajectory Guide Path
        CustomPaint(
          size: Size.infinite,
          painter: _TrajectoryPathPainter(
            start: start,
            end: end,
            color: themeColor,
            animProgress: progress,
          ),
        ),

        // Touch Ring at current finger position
        if (isTouching)
          Positioned(
            left: currentPos.dx - 22,
            top: currentPos.dy - 22,
            child: Transform.scale(
              scale: touchScale,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: themeColor.withAlpha(220),
                    width: 2.0,
                  ),
                  color: themeColor.withAlpha(40),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withAlpha(120),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Ghost Spaceship carrying along the finger
        Positioned(
          left: currentPos.dx - 18,
          top: currentPos.dy - 36,
          child: Opacity(
            opacity: opacity * 0.9,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0F172A).withAlpha(200),
                border: Border.all(color: themeColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withAlpha(180),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isMerge ? Icons.auto_awesome_rounded : Icons.rocket_launch_rounded,
                  color: themeColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        // Destination Sparkle Burst
        if (isBursting)
          Positioned(
            left: end.dx - 30,
            top: end.dy - 30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00FF88),
                  width: 2.5,
                ),
                color: const Color(0xFF00FF88).withAlpha(50),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF00FF88),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '✨',
                  style: TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),

        // Professional Animated Finger Pointer
        Positioned(
          left: currentPos.dx - 8,
          top: currentPos.dy - 6,
          child: Opacity(
            opacity: opacity,
            child: _buildProfessionalFinger(themeColor),
          ),
        ),
      ],
    );
  }

  /// Builds a rhythmic double-tap demonstration overlay with expanding shockwaves
  Widget _buildRhythmicTapOverlay({
    required Offset center,
    required double progress,
    required Color themeColor,
  }) {
    double fingerOffsetY = 0.0;
    bool isShockwave1 = progress >= 0.20 && progress <= 0.50;
    bool isShockwave2 = progress >= 0.60 && progress <= 0.90;

    if (progress < 0.20) {
      fingerOffsetY = -16.0 * (1.0 - (progress / 0.20));
    } else if (progress < 0.35) {
      fingerOffsetY = 0.0; // Contact
    } else if (progress < 0.55) {
      fingerOffsetY = -14.0 * ((progress - 0.35) / 0.20); // Lift up
    } else if (progress < 0.70) {
      fingerOffsetY = 0.0; // Contact 2
    } else {
      fingerOffsetY = -16.0 * ((progress - 0.70) / 0.30); // Lift up
    }

    return Stack(
      children: [
        // Shockwave 1
        if (isShockwave1)
          Positioned(
            left: center.dx - 32,
            top: center.dy - 32,
            child: _buildShockwaveRing(
              radius: 64 * ((progress - 0.20) / 0.30),
              color: themeColor,
              opacity: (1.0 - ((progress - 0.20) / 0.30)).clamp(0.0, 1.0),
            ),
          ),

        // Shockwave 2
        if (isShockwave2)
          Positioned(
            left: center.dx - 38,
            top: center.dy - 38,
            child: _buildShockwaveRing(
              radius: 76 * ((progress - 0.60) / 0.30),
              color: const Color(0xFFFFD700),
              opacity: (1.0 - ((progress - 0.60) / 0.30)).clamp(0.0, 1.0),
            ),
          ),

        // Floating "TAP FAST! ⚡" Badge
        Positioned(
          left: center.dx - 54,
          top: center.dy - 65 + fingerOffsetY * 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF04060E).withAlpha(230),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withAlpha(120),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: themeColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  'TAP 3 TIMES! ⚡',
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Finger Pointer executing rhythmic tap
        Positioned(
          left: center.dx - 8,
          top: center.dy - 8 + fingerOffsetY,
          child: _buildProfessionalFinger(themeColor),
        ),
      ],
    );
  }

  /// Builds a button tap overlay with gentle tactile pulse
  Widget _buildButtonTapOverlay({
    required Offset center,
    required double progress,
    required Color themeColor,
  }) {
    final double tapDrop = progress < 0.4 ? (progress / 0.4) * 12.0 : 12.0 * (1.0 - ((progress - 0.4) / 0.6));
    final bool isTouching = progress > 0.35 && progress < 0.55;

    return Stack(
      children: [
        if (isTouching)
          Positioned(
            left: center.dx - 25,
            top: center.dy - 25,
            child: _buildShockwaveRing(
              radius: 50,
              color: themeColor,
              opacity: 0.8,
            ),
          ),

        // Floating "TAP HERE! 👇" Badge
        Positioned(
          left: center.dx - 48,
          top: center.dy - 68,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF04060E).withAlpha(230),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withAlpha(120),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              'TAP HERE! 👇',
              style: TextStyle(
                color: themeColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        // Finger Pointer hovering and tapping
        Positioned(
          left: center.dx - 8,
          top: center.dy - 32 + tapDrop,
          child: _buildProfessionalFinger(themeColor),
        ),
      ],
    );
  }

  Widget _buildShockwaveRing({
    required double radius,
    required Color color,
    required double opacity,
  }) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withAlpha((opacity * 255).round()),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((opacity * 140).round()),
            blurRadius: 12,
          ),
        ],
      ),
    );
  }

  /// Renders an ultra-clean, realistic gradient hand pointer
  Widget _buildProfessionalFinger(Color themeColor) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        border: Border.all(
          color: themeColor,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withAlpha(180),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(200),
            blurRadius: 10,
            offset: const Offset(2, 6),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.touch_app_rounded,
          color: themeColor,
          size: 26,
        ),
      ),
    );
  }
}

/// Dotted Neon Trajectory Guide Path Painter
class _TrajectoryPathPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final double animProgress;

  _TrajectoryPathPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final midX = (start.dx + end.dx) / 2 + (start.dx < end.dx ? -16.0 : 16.0);
    final midY = (start.dy + end.dy) / 2 - 20.0;
    path.quadraticBezierTo(midX, midY, end.dx, end.dy);

    final dashPaint = Paint()
      ..color = color.withAlpha(140)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    _drawDashedPath(canvas, path, dashPaint, dashLength: 8, gapLength: 6);

    final arrowPaint = Paint()
      ..color = color.withAlpha(220)
      ..style = PaintingStyle.fill;

    final angle = atan2(end.dy - midY, end.dx - midX);
    const arrowSize = 9.0;

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * cos(angle - pi / 6),
        end.dy - arrowSize * sin(angle - pi / 6),
      )
      ..lineTo(
        end.dx - arrowSize * cos(angle + pi / 6),
        end.dy - arrowSize * sin(angle + pi / 6),
      )
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = (animProgress * (dashLength + gapLength)) % (dashLength + gapLength);
      while (distance < metric.length) {
        final len = min(dashLength, metric.length - distance);
        final segment = metric.extractPath(distance, distance + len);
        canvas.drawPath(segment, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPathPainter oldDelegate) {
    return oldDelegate.animProgress != animProgress ||
        oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.color != color;
  }
}

/// Dynamic Spotlight Background with Cutout & Glowing Pulsing Ring
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final Rect? destinationRect;
  final Color spotlightColor;
  final double pulseScale;

  _SpotlightPainter({
    required this.targetRect,
    this.destinationRect,
    required this.spotlightColor,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final targetRRect =
        RRect.fromRectAndRadius(targetRect, const Radius.circular(16));

    final backgroundPaint = Paint()
      ..color = Colors.black.withAlpha(150)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(fullRect)
      ..addRRect(targetRRect);

    if (destinationRect != null) {
      path.addRRect(
        RRect.fromRectAndRadius(destinationRect!, const Radius.circular(16)),
      );
    }

    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, backgroundPaint);

    final glowPaint = Paint()
      ..color = spotlightColor.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(targetRRect, glowPaint);

    final double expandWidth = (targetRect.width * (pulseScale - 1.0)) * 0.5;
    final double expandHeight = (targetRect.height * (pulseScale - 1.0)) * 0.5;
    final pulseRect = targetRect.inflate(max(expandWidth, expandHeight));
    final pulseRRect =
        RRect.fromRectAndRadius(pulseRect, const Radius.circular(20));

    final pulsePaint = Paint()
      ..color = spotlightColor
          .withAlpha(((1.4 - pulseScale).clamp(0.0, 1.0) * 160).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawRRect(pulseRRect, pulsePaint);

    if (destinationRect != null) {
      final destRRect =
          RRect.fromRectAndRadius(destinationRect!, const Radius.circular(16));
      final destPaint = Paint()
        ..color = spotlightColor.withAlpha(140)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(destRRect, destPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.destinationRect != destinationRect ||
        oldDelegate.spotlightColor != spotlightColor ||
        oldDelegate.pulseScale != pulseScale;
  }
}

/// Panda Commander Holographic Speech Bubble
class _PandaCommanderDialogBubble extends StatelessWidget {
  final TutorialStepData stepData;
  final VoidCallback onSkip;

  const _PandaCommanderDialogBubble({
    super.key,
    required this.stepData,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080D1A).withAlpha(245),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: stepData.themeColor.withAlpha(220),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: stepData.themeColor.withAlpha(90),
            blurRadius: 22,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(200),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: stepData.themeColor, width: 1.8),
              color: const Color(0xFF131B3A),
              boxShadow: [
                BoxShadow(
                  color: stepData.themeColor.withAlpha(100),
                  blurRadius: 12,
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

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: stepData.themeColor.withAlpha(45),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: stepData.themeColor.withAlpha(140),
                            width: 0.9,
                          ),
                        ),
                        child: Text(
                          'STEP ${stepData.stepNumber}/${stepData.totalSteps} • ${stepData.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: stepData.themeColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onSkip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(18),
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

                const SizedBox(height: 6),

                Text(
                  stepData.instruction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Icon(stepData.icon, color: stepData.themeColor, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        stepData.actionHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: stepData.themeColor,
                          fontSize: 10.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
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
  final TutorialGestureType gestureType;

  const TutorialStepData({
    required this.stepNumber,
    required this.totalSteps,
    required this.title,
    required this.instruction,
    required this.actionHint,
    required this.icon,
    required this.themeColor,
    required this.gestureType,
  });
}
