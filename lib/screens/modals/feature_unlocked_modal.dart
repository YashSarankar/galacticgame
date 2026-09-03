import 'package:flutter/material.dart';
import '../../services/user_growth_service.dart';

/// Celebratory Interactive Modal introducing newly unlocked systems and demonstrating "How It Works"
class FeatureUnlockedModal extends StatefulWidget {
  final List<UnlockedFeatureInfo> features;
  final int tierUnlocked;
  final void Function(UnlockedFeatureInfo feature)? onLaunchFeature;

  const FeatureUnlockedModal({
    super.key,
    required this.features,
    required this.tierUnlocked,
    this.onLaunchFeature,
  });

  @override
  State<FeatureUnlockedModal> createState() => _FeatureUnlockedModalState();
}

class _FeatureUnlockedModalState extends State<FeatureUnlockedModal> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.features.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentFeature = widget.features[_selectedIndex.clamp(0, widget.features.length - 1)];
    final bool hasMultiple = widget.features.length > 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 660),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F1E),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: currentFeature.color.withAlpha(220),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: currentFeature.color.withAlpha(80),
              blurRadius: 36,
              spreadRadius: 4,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header Banner with holographic tier clearance badge
            _buildHeader(currentFeature),

            // 2. Multi-feature Tab Selector (if > 1 feature unlocked)
            if (hasMultiple) _buildFeatureTabs(),

            // 3. Scrollable Feature Details & "How It Works" Card
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feature Main Card
                    _buildFeatureOverview(currentFeature),
                    const SizedBox(height: 14),

                    // "HOW IT WORKS" Walkthrough Section
                    _buildHowItWorksSection(currentFeature),
                    const SizedBox(height: 12),

                    // Commander Pro-Tip Banner
                    if (currentFeature.proTip.isNotEmpty)
                      _buildProTipCard(currentFeature),
                    const SizedBox(height: 12),

                    // Location / Where to access info
                    _buildLocationBadge(currentFeature),
                  ],
                ),
              ),
            ),

            // 4. Action Buttons Footer
            _buildActionFooter(currentFeature),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UnlockedFeatureInfo currentFeature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: currentFeature.color.withAlpha(20),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(
            color: currentFeature.color.withAlpha(60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: currentFeature.color.withAlpha(40),
              shape: BoxShape.circle,
              border: Border.all(color: currentFeature.color, width: 1.2),
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SYSTEM CLEARANCE UNLOCKED',
                      style: TextStyle(
                        color: currentFeature.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: currentFeature.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: currentFeature.color.withAlpha(120), width: 0.8),
                      ),
                      child: Text(
                        'TIER ${widget.tierUnlocked}',
                        style: TextStyle(
                          color: currentFeature.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.features.length > 1
                      ? '${widget.features.length} new command protocols authorized for active duty'
                      : 'New command protocol authorized for active duty',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: Colors.black26,
      child: Row(
        children: List.generate(widget.features.length, (index) {
          final item = widget.features[index];
          final bool isSelected = index == _selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: index < widget.features.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? item.color.withAlpha(45) : Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? item.color : Colors.white24,
                    width: isSelected ? 1.4 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 14,
                      color: isSelected ? item.color : Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFeatureOverview(UnlockedFeatureInfo feature) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: feature.color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: feature.color.withAlpha(70),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  feature.color.withAlpha(180),
                  feature.color.withAlpha(40),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: feature.color.withAlpha(90),
                  blurRadius: 16,
                )
              ],
            ),
            child: Icon(feature.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: feature.color.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    feature.category.toUpperCase(),
                    style: TextStyle(
                      color: feature.color,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(UnlockedFeatureInfo feature) {
    final steps = feature.steps;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF070B16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: feature.color, size: 16),
              const SizedBox(width: 6),
              Text(
                'HOW IT WORKS',
                style: TextStyle(
                  color: feature.color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          if (feature.howItWorks.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              feature.howItWorks,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10.5,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Steps list
          if (steps.isNotEmpty)
            ...List.generate(steps.length, (idx) {
              return Container(
                margin: EdgeInsets.only(bottom: idx < steps.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: feature.color.withAlpha(35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: feature.color.withAlpha(45),
                        shape: BoxShape.circle,
                        border: Border.all(color: feature.color, width: 1),
                      ),
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          color: feature.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[idx],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildProTipCard(UnlockedFeatureInfo feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFB703).withAlpha(25),
            const Color(0xFFFFB703).withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB703).withAlpha(120),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: Color(0xFFFFB703),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'COMMANDER TIP: ',
                    style: TextStyle(
                      color: Color(0xFFFFB703),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: feature.proTip,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBadge(UnlockedFeatureInfo feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(Icons.near_me_rounded, color: feature.color, size: 15),
          const SizedBox(width: 8),
          const Text(
            'ACCESS LOCATION:',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              feature.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: feature.color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter(UnlockedFeatureInfo currentFeature) {
    final bool hasMultiple = widget.features.length > 1;
    final bool isLast = _selectedIndex == widget.features.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF080C18),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(color: Colors.white12, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          if (hasMultiple && !isLast)
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('NEXT SYSTEM'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: currentFeature.color,
                    side: BorderSide(color: currentFeature.color, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = (_selectedIndex + 1) % widget.features.length;
                    });
                  },
                ),
              ),
            ),
          if (hasMultiple && !isLast) const SizedBox(width: 10),
          Expanded(
            flex: hasMultiple && !isLast ? 1 : 2,
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentFeature.color,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shadowColor: currentFeature.color.withAlpha(120),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onLaunchFeature?.call(currentFeature);
                },
                child: Text(
                  hasMultiple && !isLast ? 'ACKNOWLEDGE' : 'GOT IT • DEPLOY FLEET',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
