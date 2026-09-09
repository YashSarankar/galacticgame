import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/ship_model.dart';
import '../../services/sound_service.dart';
import '../../utils/game_theme.dart';
import '../../utils/number_formatter.dart';

/// Full-screen celebratory discovery modal celebrating the unlock of a brand-new highest tier ship!
class DiscoveryModal extends StatefulWidget {
  final ShipModel ship;
  final VoidCallback onDismiss;

  const DiscoveryModal({
    super.key,
    required this.ship,
    required this.onDismiss,
  });

  @override
  State<DiscoveryModal> createState() => _DiscoveryModalState();
}

class _DiscoveryModalState extends State<DiscoveryModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    SoundService().playPrestigeSound();
    HapticFeedback.heavyImpact();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ship = widget.ship;
    final double discoveryBountyCredits =
        1000.0 * pow(1.5, (ship.tier - 1).clamp(0, 50));
    final double discoveryBountyDm = ship.tier >= 3 ? (ship.tier * 2.0) : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF090D1C),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ship.glowColor, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: ship.glowColor.withAlpha((0.45 * 255).round()),
              blurRadius: 36,
              spreadRadius: 3,
            ),
            BoxShadow(
              color: Colors.black.withAlpha(220),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Discovery Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: ship.glowColor.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ship.glowColor, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: ship.glowColor, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'NEW DISCOVERY UNLOCKED!',
                    style: TextStyle(
                      color: ship.glowColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.auto_awesome, color: ship.glowColor, size: 14),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Center Rotating Sunburst & Ship Sprite
            SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating Light Rays
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * pi,
                        child: CustomPaint(
                          size: const Size(170, 170),
                          painter: _SunburstPainter(color: ship.glowColor),
                        ),
                      );
                    },
                  ),

                  // Glowing Center Orb
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          ship.glowColor.withAlpha((0.4 * 255).round()),
                          ship.glowColor.withAlpha((0.05 * 255).round()),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ship.glowColor.withAlpha((0.5 * 255).round()),
                          blurRadius: 28,
                          spreadRadius: 4,
                        )
                      ],
                    ),
                  ),

                  // Ship Sprite
                  Image.asset(
                    ship.spriteAsset,
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.rocket_launch_rounded,
                      color: ship.glowColor,
                      size: 72,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Tier & Name
            Text(
              'TIER ${ship.tier}',
              style: TextStyle(
                color: ship.glowColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              ship.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Discovery Bounty Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: GameTheme.backgroundVoid,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFD700).withAlpha((0.35 * 255).round()),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.card_giftcard_rounded,
                        color: Color(0xFFFFD700), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'DISCOVERY BOUNTY: +${NumberFormatter.formatCredits(discoveryBountyCredits)} Coins',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (discoveryBountyDm > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '+${discoveryBountyDm.toInt()} DM 💎',
                        style: const TextStyle(
                          color: Color(0xFFBD00FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Spec Matrix
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.05 * 255).round()),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSpecItem(
                    icon: Icons.monetization_on_rounded,
                    label: 'BASE PAYOUT',
                    value:
                        '+${NumberFormatter.formatCredits(ship.calculateIncomePayout())}/lap',
                    color: GameTheme.neonGreen,
                  ),
                  Container(width: 1, height: 28, color: Colors.white12),
                  _buildSpecItem(
                    icon: Icons.speed_rounded,
                    label: 'WARP SPEED',
                    value: '${ship.baseSpeed.toInt()} px/s',
                    color: GameTheme.neonCyan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Deploy Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ship.glowColor,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shadowColor: ship.glowColor.withAlpha((0.6 * 255).round()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  SoundService().playPurchaseSound();
                  Navigator.of(context).pop();
                  widget.onDismiss();
                },
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flight_takeoff_rounded,
                          color: Colors.black, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'COLLECT BOUNTY & DEPLOY',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
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
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SunburstPainter extends CustomPainter {
  final Color color;
  const _SunburstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    const int rayCount = 12;
    const double angleStep = (2 * pi) / rayCount;

    final paint = Paint()
      ..color = color.withAlpha((0.15 * 255).round())
      ..style = PaintingStyle.fill;

    for (int i = 0; i < rayCount; i++) {
      final double startAngle = i * angleStep;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          angleStep * 0.45,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter oldDelegate) =>
      oldDelegate.color != color;
}
