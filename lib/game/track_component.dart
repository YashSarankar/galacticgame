import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/sector_theme_model.dart';

/// Racetrack component rendering glowing neon cybernetic circuit and dynamic sector atmosphere.
class TrackComponent extends PositionComponent {
  ui.PathMetric? pathMetric;
  double trackLength = 0.0;
  final Path _trackPath = Path();
  SectorThemeModel theme = SectorThemeModel.getThemeForSector(1);

  TrackComponent({required Vector2 size}) : super(size: size);

  void updateTheme(SectorThemeModel newTheme) {
    theme = newTheme;
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

    // Smooth Rounded Racetrack (Stadium shape or curved oval)
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

    // 2. Track Base Dynamic Outer Glow
    final outerGlowPaint = Paint()
      ..color = theme.trackPrimaryGlow.withAlpha((0.28 * 255).round())
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

    // 4. Track Dual Neon Borders (Dynamic Sector Rail Colors)
    final railOuterPaint = Paint()
      ..color = theme.trackPrimaryGlow.withAlpha((0.65 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(_trackPath, railOuterPaint);

    // 5. Track Center Dashed Neon Guide Line
    final centerLinePaint = Paint()
      ..color = theme.spaceDustColor.withAlpha((0.45 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(_trackPath, centerLinePaint);
  }
}

