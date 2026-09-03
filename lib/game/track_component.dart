import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/sector_theme_model.dart';

/// Racetrack component rendering glowing neon cybernetic circuits and dynamic circuit tier geometries.
class TrackComponent extends PositionComponent {
  ui.PathMetric? pathMetric;
  double trackLength = 0.0;
  final Path _trackPath = Path();
  int circuitTier = 1;
  SectorThemeModel theme = SectorThemeModel.getThemeForSector(1);

  TrackComponent({required Vector2 size, this.circuitTier = 1})
      : super(size: size);

  void updateTheme(SectorThemeModel newTheme) {
    theme = newTheme;
  }

  void updateCircuitTier(int tier) {
    if (circuitTier == tier) return;
    circuitTier = tier;
    _buildTrackPath();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _buildTrackPath();
  }

  @override
  void onLoad() {
    super.onLoad();
    _buildTrackPath();
  }

  void _buildTrackPath() {
    _trackPath.reset();
    final double w = size.x;
    final double h = size.y;
    if (w <= 0 || h <= 0) return;

    final double cx = w / 2;
    final double cy = h / 2;

    switch (circuitTier) {
      case 1:
        // Tier 1: Orbital Loop (Smooth Stadium Oval)
        final double marginX = w * 0.12;
        final double marginY = h * 0.14;
        final double trackW = w - (marginX * 2);
        final double trackH = h - (marginY * 2);
        final double radius = min(trackW, trackH) * 0.38;

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(marginX, marginY, trackW, trackH),
          Radius.circular(radius),
        );
        _trackPath.addRRect(rect);
        break;

      case 2:
        // Tier 2: Hyper-Elliptical Superhighway (Wider, sweeping aerodynamic curve)
        final double rx = w * 0.40;
        final double ry = h * 0.38;

        _trackPath.moveTo(cx - rx, cy);
        _trackPath.cubicTo(
            cx - rx, cy - ry * 1.05, cx + rx, cy - ry * 1.05, cx + rx, cy);
        _trackPath.cubicTo(
            cx + rx, cy + ry * 1.05, cx - rx, cy + ry * 1.05, cx - rx, cy);
        _trackPath.close();
        break;

      case 3:
        // Tier 3: Infinity Singularity Ring (Figure-8 Lemniscate Loop)
        final double spanX = w * 0.38;
        final double spanY = h * 0.32;

        _trackPath.moveTo(cx, cy);
        // Loop 1: Top-Left to Bottom-Left
        _trackPath.cubicTo(
            cx - spanX * 0.4, cy - spanY, cx - spanX, cy - spanY, cx - spanX, cy);
        _trackPath.cubicTo(
            cx - spanX, cy + spanY, cx - spanX * 0.4, cy + spanY, cx, cy);
        // Loop 2: Top-Right to Bottom-Right
        _trackPath.cubicTo(
            cx + spanX * 0.4, cy - spanY, cx + spanX, cy - spanY, cx + spanX, cy);
        _trackPath.cubicTo(
            cx + spanX, cy + spanY, cx + spanX * 0.4, cy + spanY, cx, cy);
        _trackPath.close();
        break;

      case 4:
        // Tier 4: Quantum Pulsar Tri-Loop (Hypersonic Tri-Lobe)
        const int lobes = 3;
        final double baseR = min(w, h) * 0.28;
        final double amp = min(w, h) * 0.10;

        for (int i = 0; i <= 360; i += 2) {
          final double rad = i * pi / 180.0;
          final double r = baseR + amp * sin(lobes * rad);
          final double px = cx + r * cos(rad);
          final double py = cy + r * sin(rad);
          if (i == 0) {
            _trackPath.moveTo(px, py);
          } else {
            _trackPath.lineTo(px, py);
          }
        }
        _trackPath.close();
        break;

      case 5:
      default:
        // Tier 5: Omega Cosmic Hyper-Loop (Quad-Arc Hyper-Spiral Speedway)
        const int lobes = 4;
        final double baseR = min(w, h) * 0.30;
        final double amp = min(w, h) * 0.08;

        for (int i = 0; i <= 360; i += 2) {
          final double rad = i * pi / 180.0;
          final double r = baseR + amp * cos(lobes * rad);
          final double px = cx + r * cos(rad);
          final double py = cy + r * sin(rad);
          if (i == 0) {
            _trackPath.moveTo(px, py);
          } else {
            _trackPath.lineTo(px, py);
          }
        }
        _trackPath.close();
        break;
    }

    final metrics = _trackPath.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      pathMetric = metrics.first;
      trackLength = pathMetric!.length;
    }
  }

  @override
  void render(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;

    // 1. Draw subtle cosmic grid background lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withAlpha((0.35 * 255).round())
      ..strokeWidth = 1.0;

    const double gridSize = 30.0;
    for (double x = 0; x < w; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    if (_trackPath.getBounds().isEmpty) return;

    // Tier-based accent hue
    final Color tierGlow = circuitTier >= 5
        ? const Color(0xFFFF007F)
        : (circuitTier >= 4
            ? const Color(0xFF9D4EDD)
            : (circuitTier >= 3
                ? const Color(0xFFFFB703)
                : theme.trackPrimaryGlow));

    // 2. Track Base Dynamic Outer Glow
    final outerGlowPaint = Paint()
      ..color = tierGlow.withAlpha((0.32 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 16.0);
    canvas.drawPath(_trackPath, outerGlowPaint);

    // 3. Track Asphalt / Dark Core Lane
    final lanePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28.0;
    canvas.drawPath(_trackPath, lanePaint);

    // 4. Track Dual Neon Borders
    final railOuterPaint = Paint()
      ..color = tierGlow.withAlpha((0.75 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(_trackPath, railOuterPaint);

    // 5. Track Center Dashed Neon Guide Line
    final centerLinePaint = Paint()
      ..color = Colors.white.withAlpha((0.45 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(_trackPath, centerLinePaint);
  }
}
