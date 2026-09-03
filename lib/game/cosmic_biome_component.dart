import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/sector_theme_model.dart';

class _StarParticle {
  double x;
  double y;
  double size;
  double brightness;
  double pulseSpeed;
  double driftSpeed;

  _StarParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.pulseSpeed,
    required this.driftSpeed,
  });
}

/// Dynamic, living cosmic background with parallax starfields, nebula dust, and orbiting celestial planets.
class CosmicBiomeComponent extends PositionComponent {
  SectorThemeModel theme;
  final List<_StarParticle> _stars = [];
  double _animTime = 0.0;
  double _planetOrbitAngle = 0.0;

  CosmicBiomeComponent({
    required Vector2 size,
    required this.theme,
  }) : super(size: size, priority: -100);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _generateStarfield();
  }

  void _generateStarfield() {
    _stars.clear();
    final random = Random(42);
    final int starCount = (size.x * size.y / 2800).clamp(40, 110).toInt();

    for (int i = 0; i < starCount; i++) {
      _stars.add(_StarParticle(
        x: random.nextDouble() * size.x,
        y: random.nextDouble() * size.y,
        size: 0.8 + random.nextDouble() * 1.8,
        brightness: 0.3 + random.nextDouble() * 0.7,
        pulseSpeed: 1.5 + random.nextDouble() * 3.5,
        driftSpeed: 1.5 + random.nextDouble() * 4.0,
      ));
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _generateStarfield();
  }

  void updateTheme(SectorThemeModel newTheme) {
    theme = newTheme;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;
    _planetOrbitAngle += dt * 0.04;

    for (final star in _stars) {
      star.y += star.driftSpeed * dt;
      if (star.y > size.y) {
        star.y = 0.0;
        star.x = (star.x + 37) % size.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    // 1. Deep Space Base Radial Gradient
    final bgGradient = RadialGradient(
      center: Alignment(0.3 * cos(_planetOrbitAngle), -0.2),
      radius: 1.2,
      colors: [
        theme.trackPrimaryGlow.withAlpha((0.18 * 255).round()),
        theme.trackSecondaryColor.withAlpha((0.08 * 255).round()),
        const Color(0xFF04060E),
      ],

      stops: const [0.0, 0.55, 1.0],
    );

    final bgPaint = Paint()
      ..shader = bgGradient.createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    // 2. Swirling Nebula Clouds
    final nebulaCenter = Offset(
      size.x * 0.5 + sin(_animTime * 0.2) * 25.0,
      size.y * 0.4 + cos(_animTime * 0.25) * 20.0,
    );
    final nebulaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          theme.particleSparkColor.withAlpha((0.14 * 255).round()),
          theme.trackPrimaryGlow.withAlpha((0.06 * 255).round()),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: nebulaCenter, radius: size.x * 0.48));

    canvas.drawCircle(nebulaCenter, size.x * 0.48, nebulaPaint);

    // 3. Render Shaded Orbiting Celestial Planet Body
    _renderCelestialPlanet(canvas);

    // 4. Parallax Twinkling Stars
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final star in _stars) {
      final double twinkle =
          (sin(_animTime * star.pulseSpeed + star.x) + 1.0) / 2.0;
      final double alpha = (star.brightness * (0.4 + twinkle * 0.6)).clamp(0.1, 1.0);

      starPaint.color = Colors.white.withAlpha((alpha * 255).round());
      canvas.drawCircle(Offset(star.x, star.y), star.size, starPaint);

      // Subtle star glow flare on larger stars
      if (star.size > 1.8) {
        starPaint.color =
            theme.trackPrimaryGlow.withAlpha(((alpha * 0.35) * 255).round());
        canvas.drawCircle(Offset(star.x, star.y), star.size * 2.5, starPaint);
      }
    }
  }

  void _renderCelestialPlanet(Canvas canvas) {
    final double planetX = size.x * 0.72 + cos(_planetOrbitAngle) * 20.0;
    final double planetY = size.y * 0.22 + sin(_planetOrbitAngle) * 12.0;
    final double planetRadius = 26.0;

    final planetCenter = Offset(planetX, planetY);

    // 1. Atmosphere Glow Rim
    final atmoPaint = Paint()
      ..color = theme.trackPrimaryGlow.withAlpha((0.35 * 255).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(planetCenter, planetRadius + 3.0, atmoPaint);

    // 2. 3D Spherical Shading Gradient
    final planetShader = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.95,
      colors: [
        theme.particleSparkColor,
        theme.trackPrimaryGlow,
        const Color(0xFF030814),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(Rect.fromCircle(center: planetCenter, radius: planetRadius));

    final spherePaint = Paint()..shader = planetShader;
    canvas.drawCircle(planetCenter, planetRadius, spherePaint);

    // 3. Planetary Rings (For Sector 2 & 5)
    if (theme.sectorLevel == 2 || theme.sectorLevel == 5) {
      final ringPaint = Paint()
        ..color = theme.trackPrimaryGlow.withAlpha((0.45 * 255).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.save();
      canvas.translate(planetX, planetY);
      canvas.rotate(-pi / 6.0);
      canvas.scale(1.0, 0.35);
      canvas.drawCircle(Offset.zero, planetRadius * 1.7, ringPaint);
      canvas.restore();
    }
  }
}
