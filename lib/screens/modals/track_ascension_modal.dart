import 'package:flutter/material.dart';



/// Holographic Track Ascension & Circuit Evolution Celebration Modal
class TrackAscensionModal extends StatefulWidget {
  final int newTier;
  final String tierName;
  final double incomeMultiplier;
  final VoidCallback onContinue;

  const TrackAscensionModal({
    super.key,
    required this.newTier,
    required this.tierName,
    required this.incomeMultiplier,
    required this.onContinue,
  });

  static Future<void> show(
    BuildContext context, {
    required int newTier,
    required String tierName,
    required double incomeMultiplier,
    required VoidCallback onContinue,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TrackAscensionModal(
        newTier: newTier,
        tierName: tierName,
        incomeMultiplier: incomeMultiplier,
        onContinue: onContinue,
      ),
    );
  }

  @override
  State<TrackAscensionModal> createState() => _TrackAscensionModalState();
}

class _TrackAscensionModalState extends State<TrackAscensionModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color get _tierThemeColor {
    switch (widget.newTier) {
      case 2:
        return const Color(0xFF00F0FF); // Hyper-Elliptical Cyan
      case 3:
        return const Color(0xFFFFB703); // Infinity Gold
      case 4:
        return const Color(0xFF9D4EDD); // Pulsar Purple
      case 5:
      default:
        return const Color(0xFFFF007F); // Omega Magenta
    }
  }

  IconData get _tierIcon {
    switch (widget.newTier) {
      case 2:
        return Icons.all_inclusive_rounded;
      case 3:
        return Icons.sync_rounded;
      case 4:
        return Icons.flare_rounded;
      case 5:
      default:
        return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _tierThemeColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: themeColor, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: themeColor.withAlpha((0.35 * 255).round()),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: themeColor.withAlpha((0.18 * 255).round()),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: themeColor.withAlpha((0.5 * 255).round())),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: themeColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'CIRCUIT ASCENSION COMPLETE',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Animated Holographic Track Crest
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            themeColor.withAlpha((0.4 * 255).round()),
                            themeColor.withAlpha((0.05 * 255).round()),
                          ],
                        ),
                        border: Border.all(color: themeColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withAlpha((0.5 * 255).round()),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(_tierIcon, color: Colors.white, size: 48),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // 3. Track Circuit Tier & Title
            Text(
              'CIRCUIT TIER ${widget.newTier}',
              style: TextStyle(
                color: themeColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.tierName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 16),

            // 4. Multiplier Showcase Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF131B30),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: themeColor, size: 22),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PERMANENT CIRCUIT BOOST',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${widget.incomeMultiplier}X BASE EARNINGS',
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 5. Feature Description
            Text(
              'Your racetrack geometry has evolved into an advanced high-velocity circuit! Re-tune Laser Gates on this new raceway to multiply your income stream.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha((0.75 * 255).round()),
                fontSize: 11.5,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 22),

            // 6. Action Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                  shadowColor: themeColor.withAlpha((0.6 * 255).round()),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onContinue();
                },
                child: const Text(
                  'COMMENCE RACING',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
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
