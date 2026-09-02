import 'package:flutter/material.dart';
import '../../models/mystery_card_model.dart';
import '../../utils/game_theme.dart';
import '../../utils/number_formatter.dart';
import '../../services/ad_manager.dart';


/// Holographic 3-Card Surprise Pick triggered by Golden UFO fly-bys
class MysteryCardModal extends StatefulWidget {
  final double fleetIncomePerLap;
  final int highestTierUnlocked;
  final void Function(MysteryCardReward reward, {bool doubleWithAd}) onRewardChosen;

  const MysteryCardModal({
    super.key,
    required this.fleetIncomePerLap,
    required this.highestTierUnlocked,
    required this.onRewardChosen,
  });

  @override
  State<MysteryCardModal> createState() => _MysteryCardModalState();
}

class _MysteryCardModalState extends State<MysteryCardModal>
    with SingleTickerProviderStateMixin {
  late final List<MysteryCardReward> _cards;
  int? _selectedIndex;
  bool _revealed = false;


  @override
  void initState() {
    super.initState();
    _cards = MysteryCardReward.generateThreeCards(
      fleetIncomePerLap: widget.fleetIncomePerLap,
      highestTierUnlocked: widget.highestTierUnlocked,
    );
  }

  void _onCardTap(int index) {
    if (_revealed) return;
    setState(() {
      _selectedIndex = index;
      _revealed = true;
    });
  }

  void _claimReward({bool doubleWithAd = false}) {
    if (_selectedIndex == null) return;
    final reward = _cards[_selectedIndex!];
    widget.onRewardChosen(reward, doubleWithAd: doubleWithAd);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GameTheme.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD700).withAlpha((0.6 * 255).round()),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withAlpha((0.25 * 255).round()),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'GOLDEN UFO MYSTERY DROP!',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Text(
              _revealed
                  ? 'SURPRISE REWARD UNLOCKED!'
                  : 'Pick 1 of 3 Holographic Cards',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _revealed
                  ? 'Claim your prize or double it with a fast reward!'
                  : 'Tap any card to reveal your cosmic prize.',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 20),

            // 3 Mystery Cards Row
            Row(
              children: List.generate(3, (index) {
                final card = _cards[index];
                final isSelected = _selectedIndex == index;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _onCardTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        height: 160,
                        decoration: BoxDecoration(
                          color: _revealed
                              ? (isSelected
                                  ? Color(card.colorValue)
                                      .withAlpha((0.25 * 255).round())
                                  : Colors.white.withAlpha((0.05 * 255).round()))
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _revealed
                                ? (isSelected
                                    ? Color(card.colorValue)
                                    : Colors.white24)
                                : const Color(0xFFFFD700),
                            width: isSelected ? 2.2 : 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Color(card.colorValue)
                                        .withAlpha((0.4 * 255).round()),
                                    blurRadius: 16,
                                  ),
                                ]
                              : [],
                        ),
                        child: _revealed
                            ? _buildRevealedCard(card, isSelected)
                            : _buildHiddenCard(),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Action Buttons when revealed
            if (_revealed && _selectedIndex != null) ...[
              // 2X Double Claim Button (Ad)
              ElevatedButton(
                onPressed: () {
                  AdManager().showRewardedAd(
                    onUserEarnedReward: () {
                      _claimReward(doubleWithAd: true);
                    },
                    onAdFailed: () {
                      _claimReward(doubleWithAd: false);
                    },
                  );
                },
                style: ElevatedButton.styleFrom(

                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_fill_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '2X DOUBLE CLAIM (FREE AD)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Normal Claim
              TextButton(
                onPressed: () => _claimReward(doubleWithAd: false),
                child: const Text(
                  'Claim Normal Reward',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenCard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.help_outline_rounded,
          color: const Color(0xFFFFD700).withAlpha((0.8 * 255).round()),
          size: 38,
        ),
        const SizedBox(height: 8),
        const Text(
          'MYSTERY',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildRevealedCard(MysteryCardReward card, bool isSelected) {
    final cardColor = Color(card.colorValue);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            card.iconAsset,
            width: 38,
            height: 38,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              card.title,
              style: TextStyle(
                color: cardColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          if (card.creditsValue > 0)
            Text(
              '+${NumberFormatter.formatCredits(card.creditsValue)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          if (card.darkMatterValue > 0)
            Text(
              '+${card.darkMatterValue.toInt()} Gems',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          if (card.crateCount > 0)
            Text(
              '${card.crateCount}x Crates',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          if (card.droneSeconds > 0)
            Text(
              '${card.droneSeconds}s Drone',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}
