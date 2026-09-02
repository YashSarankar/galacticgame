import 'package:flutter/material.dart';
import '../../models/ship_model.dart';
import '../../utils/game_theme.dart';
import '../../utils/number_formatter.dart';

/// Full-screen discovery modal celebrating the unlock of a brand-new highest tier ship!
class DiscoveryModal extends StatelessWidget {
  final ShipModel ship;
  final VoidCallback onDismiss;

  const DiscoveryModal({
    super.key,
    required this.ship,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E1B).withAlpha((0.95 * 255).round()),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ship.glowColor, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: ship.glowColor.withAlpha((0.4 * 255).round()),
              blurRadius: 24,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Discovery Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: ship.glowColor.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ship.glowColor, width: 1.2),
              ),
              child: Text(
                '✨ NEW SPACECRAFT DISCOVERED! ✨',
                style: TextStyle(
                  color: ship.glowColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Glowing Center Ship Display
            Stack(
              alignment: Alignment.center,
              children: [
                // Glowing radial backdrop
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ship.glowColor.withAlpha((0.15 * 255).round()),
                    boxShadow: [
                      BoxShadow(
                        color: ship.glowColor.withAlpha((0.5 * 255).round()),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                ),

                // Large Kenney Ship Sprite
                Image.asset(
                  ship.spriteAsset,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.rocket_launch_rounded,
                    color: ship.glowColor,
                    size: 72,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tier & Name
            Text(
              'TIER ${ship.tier}',
              style: TextStyle(
                color: ship.glowColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ship.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // Spec Matrix
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  Container(width: 1, height: 30, color: Colors.white12),
                  _buildSpecItem(
                    icon: Icons.speed_rounded,
                    label: 'WARP SPEED',
                    value: '${ship.baseSpeed.toInt()} px/s',
                    color: GameTheme.neonCyan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Deploy Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ship.glowColor,
                  foregroundColor: Colors.black,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss();
                },
                child: const Text(
                  'DEPLOY TO FLEET',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
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
        const SizedBox(height: 3),
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
