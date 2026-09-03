import 'package:flutter/material.dart';
import '../../services/user_growth_service.dart';
import '../../utils/game_theme.dart';

/// Celebratory Modal introducing newly unlocked systems to the Commander
class FeatureUnlockedModal extends StatelessWidget {
  final List<UnlockedFeatureInfo> features;
  final int tierUnlocked;

  const FeatureUnlockedModal({
    super.key,
    required this.features,
    required this.tierUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: GameTheme.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF00FF88),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FF88).withAlpha((0.35 * 255).round()),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Holographic Online Icon
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF00FF88),
                    Color(0xFF008855),
                    Color(0xFF0F172A),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withAlpha((0.5 * 255).round()),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              'NEW SYSTEMS ONLINE! (TIER $tierUnlocked)',
              style: const TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),

            const Text(
              'Your fleet expansion has authorized new command capabilities:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),

            // Features List
            ...features.map((feature) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GameTheme.backgroundVoid,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: feature.color.withAlpha((0.4 * 255).round()),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: feature.color.withAlpha((0.2 * 255).round()),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(feature.icon, color: feature.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.title.toUpperCase(),
                              style: TextStyle(
                                color: feature.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              feature.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 14),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'ACKNOWLEDGE & DEPLOY',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12.5,
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
}
