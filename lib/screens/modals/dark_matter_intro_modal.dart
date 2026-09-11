import 'package:flutter/material.dart';

/// Celebratory Introduction Modal for Dark Matter Discovery and Quantum Tech Tree Unlock (Tier 3).
class DarkMatterIntroModal extends StatefulWidget {
  final VoidCallback onOpenTechTree;
  final VoidCallback? onDismiss;

  const DarkMatterIntroModal({
    super.key,
    required this.onOpenTechTree,
    this.onDismiss,
  });

  @override
  State<DarkMatterIntroModal> createState() => _DarkMatterIntroModalState();
}

class _DarkMatterIntroModalState extends State<DarkMatterIntroModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF0C081A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFBD00FF),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBD00FF).withAlpha((0.35 * 255).round()),
              blurRadius: 30,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Glowing Animated Dark Matter Gem Centerpiece
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFFF00FF),
                      Color(0xFF7B2CBF),
                      Color(0xFF240046),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBD00FF).withAlpha((0.6 * 255).round()),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.diamond_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Title & Discovery Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFBD00FF).withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFBD00FF),
                  width: 1.0,
                ),
              ),
              child: const Text(
                'TIER 3 DISCOVERY UNLOCKED',
                style: TextStyle(
                  color: Color(0xFFBD00FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'DARK MATTER DETECTED! 💎',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            const Text(
              'You have synthesized pure Dark Matter! This rare cosmic element unlocks the Quantum Tech Tree for permanent fleet super-upgrades.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // 3. Feature Breakdown Perks
            _buildPerkRow(
              icon: Icons.account_tree_rounded,
              color: const Color(0xFFBD00FF),
              title: 'Quantum Super-Upgrades',
              description:
                  'Permanently buff base income, flight speed, buying discounts, and unlock extra merge bays.',
            ),
            const SizedBox(height: 8),
            _buildPerkRow(
              icon: Icons.stars_rounded,
              color: const Color(0xFFFFD700),
              title: 'Starter Supply Granted',
              description:
                  '+15 Dark Matter Crystals added to your wallet right now!',
            ),
            const SizedBox(height: 20),

            // 4. Primary CTA: Open Tech Tree
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBD00FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                ),
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: const Text(
                  'UPGRADE QUANTUM TECH MATRIX ⚡',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onOpenTechTree();
                },
              ),
            ),
            const SizedBox(height: 8),

            // 5. Dismiss Text Button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDismiss?.call();
              },
              child: const Text(
                'Continue to Fleet Hangar',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkRow({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha((0.35 * 255).round()),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha((0.2 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
