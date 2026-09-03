import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/roulette_reward_model.dart';
import '../../providers/game_providers.dart';
import '../../services/ad_manager.dart';

/// Interactive physics-based animated 8-wedge Wormhole Roulette Lucky Wheel

class WormholeRouletteModal extends ConsumerStatefulWidget {
  const WormholeRouletteModal({super.key});

  @override
  ConsumerState<WormholeRouletteModal> createState() =>
      _WormholeRouletteModalState();
}

class _WormholeRouletteModalState extends ConsumerState<WormholeRouletteModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<RouletteRewardModel> _segments;

  double _currentAngle = 0.0;
  double _startAngle = 0.0;
  double _targetAngle = 0.0;
  bool _isSpinning = false;
  int _lastTickSector = -1;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _segments = RouletteRewardModel.getSegments();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    _controller.addListener(() {
      final double progress =
          Curves.easeOutCirc.transform(_controller.value);
      final double angle = _startAngle + (_targetAngle - _startAngle) * progress;
      setState(() {
        _currentAngle = angle;
      });

      // Haptic tick per sector boundary crossing
      final int sectorIndex =
          ((angle % (2 * pi)) / (2 * pi / _segments.length)).floor();
      if (sectorIndex != _lastTickSector) {
        _lastTickSector = sectorIndex;
        HapticFeedback.selectionClick();
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSpinCompleted();
      }
    });

    // 1-second countdown ticker for free daily spin cooldown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }


  void _onSpinTapped() {
    if (_isSpinning) return;
    final gameState = ref.read(gameStateProvider);
    if (gameState.canSpinFree) {
      _spinWheel();
    } else if (gameState.canSpinAd) {
      AdManager().showRewardedAd(
        onUserEarnedReward: () {
          _spinWheel();
        },
      );
    }
  }

  void _spinWheel() {
    if (_isSpinning) return;
    final gameState = ref.read(gameStateProvider);
    if (gameState.isDailySpinsExhausted) return;

    final random = Random();
    final int winningIndex = random.nextInt(_segments.length);

    // Calculate angle to land exactly on winning sector center
    final double segmentAngle = (2 * pi) / _segments.length;
    // Top pointer is at -pi/2
    final double sectorTarget =
        (3 * pi / 2) - (winningIndex * segmentAngle) - (segmentAngle / 2);

    // 6 to 9 full spins for dramatic suspense
    final double fullSpins = (6 + random.nextInt(3)) * 2 * pi;
    _startAngle = _currentAngle % (2 * pi);
    _targetAngle = _startAngle + fullSpins + (sectorTarget - (_startAngle % (2 * pi)));
    if (_targetAngle < _startAngle + fullSpins) {
      _targetAngle += 2 * pi;
    }

    setState(() {
      _isSpinning = true;
    });

    _controller.reset();
    _controller.forward();
  }

  void _onSpinCompleted() {
    setState(() {
      _isSpinning = false;
    });

    // Determine winning sector
    final double normalizedAngle =
        (3 * pi / 2 - (_currentAngle % (2 * pi))) % (2 * pi);
    final double positiveAngle =
        normalizedAngle < 0 ? normalizedAngle + 2 * pi : normalizedAngle;
    final double segmentAngle = 2 * pi / _segments.length;
    final int winningIndex = (positiveAngle / segmentAngle).floor() % _segments.length;
    final winningReward = _segments[winningIndex];

    ref.read(gameStateProvider.notifier).claimRouletteReward(winningReward);

    _showVictoryPopup(winningReward);
  }

  void _showVictoryPopup(RouletteRewardModel reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1127),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: reward.color, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: reward.color.withAlpha((0.5 * 255).round()),
                blurRadius: 30,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: reward.color.withAlpha((0.25 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: reward.color),
                ),
                child: Text(
                  '🎉 REWARD SECURED! 🎉',
                  style: TextStyle(
                    color: reward.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Icon(reward.icon, color: reward.color, size: 56),
              const SizedBox(height: 12),
              Text(
                reward.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                reward.description,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: reward.color,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text(
                    'COLLECT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final int usedSpins = gameState.effectiveDailySpinsUsed;
    final bool canSpinFree = gameState.canSpinFree;
    final bool canSpinAd = gameState.canSpinAd;
    final bool canSpinAny = gameState.canSpinAny && !_isSpinning;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF080B18).withAlpha((0.96 * 255).round()),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: canSpinFree
                ? const Color(0xFF00F5FF)
                : (canSpinAd ? const Color(0xFFFFB800) : Colors.white24),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: (canSpinFree
                      ? const Color(0xFF00F5FF)
                      : (canSpinAd ? const Color(0xFFFFB800) : Colors.white10))
                  .withAlpha((0.35 * 255).round()),
              blurRadius: 24,
              spreadRadius: 2,
            )
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.blur_circular_rounded,
                    color: canSpinFree
                        ? const Color(0xFF00F5FF)
                        : (canSpinAd ? const Color(0xFFFFB800) : Colors.white60),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'WORMHOLE ROULETTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon:
                        const Icon(Icons.close, color: Colors.white60, size: 20),
                    onPressed: _isSpinning
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Daily 3-Spin Progress Track (1 Free, 2 Ad Spins)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSpinBadge(
                      label: '1. FREE',
                      isDone: usedSpins >= 1,
                      isCurrent: usedSpins == 0,
                      color: const Color(0xFF00F5FF),
                    ),
                    Container(width: 12, height: 1, color: Colors.white24),
                    _buildSpinBadge(
                      label: '2. AD',
                      isDone: usedSpins >= 2,
                      isCurrent: usedSpins == 1,
                      color: const Color(0xFFFFB800),
                    ),
                    Container(width: 12, height: 1, color: Colors.white24),
                    _buildSpinBadge(
                      label: '3. AD',
                      isDone: usedSpins >= 3,
                      isCurrent: usedSpins == 2,
                      color: const Color(0xFFFFB800),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Wheel Display with Pointer
              Stack(
                alignment: Alignment.center,
                children: [
                  // Wheel Circle Canvas
                  Transform.rotate(
                    angle: _currentAngle,
                    child: CustomPaint(
                      size: const Size(260, 260),
                      painter: _RouletteWheelPainter(segments: _segments),
                    ),
                  ),

                  // Center Glowing Hub / Spin Action
                  GestureDetector(
                    onTap: canSpinAny ? _onSpinTapped : null,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: canSpinFree
                              ? [const Color(0xFF00F5FF), const Color(0xFF0D1B3E)]
                              : (canSpinAd
                                  ? [
                                      const Color(0xFFFFB800),
                                      const Color(0xFF3E220D)
                                    ]
                                  : [
                                      Colors.grey.shade700,
                                      Colors.grey.shade900
                                    ]),
                        ),
                        border: Border.all(
                          color: canSpinFree
                              ? const Color(0xFF00F5FF)
                              : (canSpinAd
                                  ? const Color(0xFFFFB800)
                                  : Colors.white24),
                          width: 2.5,
                        ),
                        boxShadow: canSpinAny
                            ? [
                                BoxShadow(
                                  color: (canSpinFree
                                          ? const Color(0xFF00F5FF)
                                          : const Color(0xFFFFB800))
                                      .withAlpha((0.6 * 255).round()),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _isSpinning
                              ? 'WARP'
                              : (canSpinFree
                                  ? 'SPIN!'
                                  : (canSpinAd ? 'AD SPIN' : 'LOCKED')),
                          style: TextStyle(
                            color: canSpinAny ? Colors.black : Colors.white54,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top Pointer Needle
                  Positioned(
                    top: 0,
                    child: CustomPaint(
                      size: const Size(22, 26),
                      painter: _PointerPainter(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Spin Status / Action Buttons
              if (canSpinFree) ...[
                const Text(
                  '✨ 100% FREE DAILY SPIN READY! (1/3)',
                  style: TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F5FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'SPIN FOR FREE (1/3)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: _isSpinning ? null : _spinWheel,
                  ),
                ),
              ] else if (canSpinAd) ...[
                Text(
                  '🎬 WATCH AD TO SPIN (${usedSpins + 1}/3)',
                  style: const TextStyle(
                    color: Color(0xFFFFB800),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB800),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                    label: Text(
                      'WATCH AD TO SPIN (${usedSpins + 1}/3)',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onPressed: _isSpinning ? null : _onSpinTapped,
                  ),
                ),
              ] else ...[
                Builder(
                  builder: (context) {
                    final int now = DateTime.now().millisecondsSinceEpoch;
                    final int nextSpinTime =
                        gameState.lastDailySpinResetTimestamp +
                            (24 * 60 * 60 * 1000);
                    final int diffMs = max(0, nextSpinTime - now);
                    final int remainingSeconds = (diffMs / 1000).ceil();
                    final int hours = remainingSeconds ~/ 3600;
                    final int minutes = (remainingSeconds % 3600) ~/ 60;
                    final int seconds = remainingSeconds % 60;
                    final String timerStr =
                        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

                    return Column(
                      children: [
                        const Text(
                          '🔒 ALL 3 DAILY SPINS COMPLETED (3/3)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 13, color: Color(0xFF00F5FF)),
                            const SizedBox(width: 4),
                            Text(
                              'Next Free Spin in: $timerStr',
                              style: const TextStyle(
                                color: Color(0xFF00F5FF),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white38,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: null,
                    child: const Text(
                      'COME BACK TOMORROW (3/3 USED)',
                      style: TextStyle(
                        fontSize: 12,
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

  Widget _buildSpinBadge({
    required String label,
    required bool isDone,
    required bool isCurrent,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDone
            ? const Color(0xFF00FF88).withAlpha(30)
            : (isCurrent ? color.withAlpha(40) : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone
              ? const Color(0xFF00FF88)
              : (isCurrent ? color : Colors.white24),
          width: 1.1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone
                ? Icons.check_circle_rounded
                : (isCurrent
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded),
            size: 11,
            color: isDone
                ? const Color(0xFF00FF88)
                : (isCurrent ? color : Colors.white38),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: isDone
                  ? const Color(0xFF00FF88)
                  : (isCurrent ? color : Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the 8 segmented roulette wheel
class _RouletteWheelPainter extends CustomPainter {
  final List<RouletteRewardModel> segments;

  _RouletteWheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double sweepAngle = (2 * pi) / segments.length;

    // Draw outer glow border
    final outerGlowPaint = Paint()
      ..color = const Color(0xFF00F5FF).withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(center, radius, outerGlowPaint);

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final double startAngle = i * sweepAngle;

      final wedgePaint = Paint()
        ..color = (i % 2 == 0
                ? const Color(0xFF131B3A)
                : const Color(0xFF0E1428))
            .withAlpha(240)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        wedgePaint,
      );

      // Wedge border line
      final borderPaint = Paint()
        ..color = segment.color.withAlpha(120)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw Icon & Label on wedge
      final double midAngle = startAngle + (sweepAngle / 2);
      final double iconDist = radius * 0.65;
      final Offset iconPos = Offset(
        center.dx + iconDist * cos(midAngle),
        center.dy + iconDist * sin(midAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(segment.icon.codePoint),
          style: TextStyle(
            fontSize: 20,
            fontFamily: segment.icon.fontFamily,
            package: segment.icon.fontPackage,
            color: segment.color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(iconPos.dx, iconPos.dy);
      canvas.rotate(midAngle + pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom top pointer needle
class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF0055)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
