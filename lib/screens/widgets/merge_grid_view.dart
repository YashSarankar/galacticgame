import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/game_state.dart';
import '../../models/ship_model.dart';
import '../../utils/game_theme.dart';

typedef OnGridMergeCallback = void Function(
    int fromIndex, int toIndex, ShipModel targetShip, Offset dropPos);

/// Interactive 4x4 Merge Deck with drag-and-drop mechanics, deadlock recovery, and matching glow feedback.
class MergeGridView extends StatefulWidget {
  final GameState state;
  final int maxUnlockedGridSlots;
  final GlobalKey? slot0Key;
  final GlobalKey? slot1Key;
  final Function(int from, int to) onMergeOrMove;
  final Function(int index) onOpenCrate;
  final VoidCallback onQuickClearDeadlock;
  final OnGridMergeCallback onMergeVfx;

  const MergeGridView({
    super.key,
    required this.state,
    required this.maxUnlockedGridSlots,
    this.slot0Key,
    this.slot1Key,
    required this.onMergeOrMove,
    required this.onOpenCrate,
    required this.onQuickClearDeadlock,
    required this.onMergeVfx,
  });

  @override
  State<MergeGridView> createState() => _MergeGridViewState();
}

class _MergeGridViewState extends State<MergeGridView> {
  int? _draggingShipTier;
  int? _draggingFromSlotIndex;
  final Map<int, GlobalKey> _slotKeys = {};

  GlobalKey _getSlotKey(int index) {
    if (index == 0 && widget.slot0Key != null) return widget.slot0Key!;
    if (index == 1 && widget.slot1Key != null) return widget.slot1Key!;
    return _slotKeys.putIfAbsent(index, () => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDeadlocked =
        widget.state.isGridDeadlocked(widget.maxUnlockedGridSlots);
    final int? lowestSlotIdx = widget.state.lowestTierSlotIndex;
    final int? lowestTier = widget.state.lowestTierOnGrid;

    return Stack(
      children: [
        Container(
          decoration: GameTheme.glassCard(
            borderColor: isDeadlocked
                ? const Color(0xFFFF9900).withAlpha((0.6 * 255).round())
                : GameTheme.cardBorder,
            radius: 16,
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              if (isDeadlocked && lowestSlotIdx != null && lowestTier != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1502),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFF9900),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFF9900), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Deck Full! Quick Sell Tier $lowestTier to make space',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 24,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9900),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: widget.onQuickClearDeadlock,
                          child: const Text(
                            'QUICK CLEAR',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableW = constraints.maxWidth;
                    final double availableH = constraints.maxHeight;
                    final double cellW = (availableW - (3 * 6)) / 4;
                    final double cellH = (availableH - (3 * 6)) / 4;
                    final double aspectRatio =
                        (cellW > 0 && cellH > 0) ? (cellW / cellH) : 1.0;

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 16,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: aspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final bool isLocked =
                            index >= widget.maxUnlockedGridSlots;
                        final ShipModel? ship =
                            isLocked ? null : widget.state.gridSlots[index];

                        if (isLocked) {
                          return Container(
                            decoration: BoxDecoration(
                              color:
                                  Colors.black.withAlpha((0.35 * 255).round()),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white10,
                                width: 1.0,
                              ),
                            ),
                            child: const Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      color: Colors.white24,
                                      size: 13,
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      'TECH',
                                      style: TextStyle(
                                        color: Colors.white24,
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        final bool isDeadlockCandidate =
                            isDeadlocked && index == lowestSlotIdx;
                        final GlobalKey slotKey = _getSlotKey(index);

                        return DragTarget<int>(
                          onWillAcceptWithDetails: (details) =>
                              !isLocked && details.data != index,
                          onAcceptWithDetails: (details) {
                            final int fromIndex = details.data;
                            final fromShip = widget.state.gridSlots[fromIndex];
                            final targetShip = widget.state.gridSlots[index];
                            final bool isMerge = fromShip != null &&
                                targetShip != null &&
                                !fromShip.isBox &&
                                !targetShip.isBox &&
                                fromShip.tier == targetShip.tier;

                            widget.onMergeOrMove(fromIndex, index);

                            if (isMerge) {
                              final slotBox = slotKey.currentContext
                                  ?.findRenderObject() as RenderBox?;
                              final dropPos = (slotBox != null && slotBox.hasSize)
                                  ? slotBox.localToGlobal(
                                      slotBox.size.center(Offset.zero))
                                  : details.offset;
                              widget.onMergeVfx(
                                  fromIndex, index, targetShip, dropPos);
                            }
                          },
                          builder: (context, candidateData, rejectedData) {
                            final bool isHovered = candidateData.isNotEmpty;
                            final bool isMatchingTarget =
                                _draggingShipTier != null &&
                                    ship != null &&
                                    !ship.isBox &&
                                    ship.tier == _draggingShipTier &&
                                    index != _draggingFromSlotIndex;

                            return Container(
                              key: slotKey,
                              decoration: BoxDecoration(
                                color: isHovered
                                    ? const Color(0xFF00FF88)
                                        .withAlpha((0.35 * 255).round())
                                    : (isMatchingTarget
                                        ? const Color(0xFF00FF88)
                                            .withAlpha((0.22 * 255).round())
                                        : (isDeadlockCandidate
                                            ? const Color(0xFFFF9900)
                                                .withAlpha((0.18 * 255).round())
                                            : GameTheme.cardSurface)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isHovered
                                      ? const Color(0xFF00FF88)
                                      : (isMatchingTarget
                                          ? const Color(0xFF00FF88)
                                          : (isDeadlockCandidate
                                              ? const Color(0xFFFF9900)
                                              : (ship != null && !ship.isBox
                                                  ? ship.glowColor.withAlpha(
                                                      (0.35 * 255).round())
                                                  : Colors.white10))),
                                  width: isHovered ||
                                          isMatchingTarget ||
                                          isDeadlockCandidate
                                      ? 1.8
                                      : 1.0,
                                ),
                                boxShadow: isHovered || isMatchingTarget
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF00FF88)
                                              .withAlpha((0.45 * 255).round()),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: ship == null
                                  ? null
                                  : (ship.isBox
                                      ? InkWell(
                                          onTap: () => widget.onOpenCrate(index),
                                          child: _buildCrateTileContent(
                                            isAdBox: ship.isAdBox,
                                            isVip: widget.state.hasRemovedAds,
                                          ),
                                        )
                                      : Draggable<int>(
                                          data: index,
                                          feedback: Material(
                                            type: MaterialType.transparency,
                                            child: SizedBox(
                                              width: cellW,
                                              height: cellH,
                                              child: _buildShipTileContent(
                                                ship,
                                                isDragging: true,
                                              ),
                                            ),
                                          ),
                                          childWhenDragging: Opacity(
                                            opacity: 0.25,
                                            child: _buildShipTileContent(ship),
                                          ),
                                          onDragStarted: () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _draggingShipTier = ship.tier;
                                              _draggingFromSlotIndex = index;
                                            });
                                          },
                                          onDragEnd: (_) {
                                            setState(() {
                                              _draggingShipTier = null;
                                              _draggingFromSlotIndex = null;
                                            });
                                          },
                                          child: _buildShipTileContent(ship),
                                        )),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShipTileContent(ShipModel ship, {bool isDragging = false}) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: Image.asset(
                ship.spriteAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.rocket_rounded,
                  color: Colors.white70,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
          Flexible(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
              decoration: BoxDecoration(
                color: ship.glowColor.withAlpha((0.20 * 255).round()),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: ship.glowColor.withAlpha((0.5 * 255).round()),
                  width: 0.6,
                ),
              ),
              child: Text(
                'T${ship.tier}',
                style: TextStyle(
                  color: ship.glowColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 8.5,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrateTileContent({bool isAdBox = false, bool isVip = false}) {
    final Color primaryColor =
        isAdBox ? const Color(0xFFFFD700) : const Color(0xFFFF9900);
    final String labelText = isAdBox
        ? (isVip ? 'VIP FREE' : 'AD 🎬')
        : 'TAP OPEN';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 6,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha((0.20 * 255).round()),
                shape: BoxShape.circle,
                border: isAdBox
                    ? Border.all(
                        color: const Color(0xFFFFD700),
                        width: 1.2,
                      )
                    : null,
                boxShadow: isAdBox
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withAlpha((0.4 * 255).round()),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                isAdBox
                    ? Icons.card_giftcard_rounded
                    : Icons.inventory_2_rounded,
                color: primaryColor,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(height: 1),
        Flexible(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha((0.25 * 255).round()),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: primaryColor,
                width: 0.6,
              ),
            ),
            child: Text(
              labelText,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 7.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
