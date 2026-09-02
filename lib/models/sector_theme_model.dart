import 'package:flutter/material.dart';

/// Dynamic Visual Theme for the Flame Racetrack & Space Atmosphere based on Sector
class SectorThemeModel {
  final int sectorLevel;
  final String sectorName;
  final Color trackPrimaryGlow;
  final Color trackSecondaryColor;
  final Color finishLineColor;
  final Color spaceDustColor;
  final Color particleSparkColor;
  final String backgroundMusicVibe;

  const SectorThemeModel({
    required this.sectorLevel,
    required this.sectorName,
    required this.trackPrimaryGlow,
    required this.trackSecondaryColor,
    required this.finishLineColor,
    required this.spaceDustColor,
    required this.particleSparkColor,
    required this.backgroundMusicVibe,
  });

  static SectorThemeModel getThemeForSector(int sectorLevel) {
    switch (sectorLevel) {
      case 1:
      case 2:
        return const SectorThemeModel(
          sectorLevel: 1,
          sectorName: 'Orion Plasma Nebula',
          trackPrimaryGlow: Color(0xFF00F0FF), // Neon Cyan
          trackSecondaryColor: Color(0xFF0077B6),
          finishLineColor: Color(0xFF00FF88), // Bright Emerald
          spaceDustColor: Color(0xFF7209B7),
          particleSparkColor: Color(0xFF00F0FF),
          backgroundMusicVibe: 'Synthwave Chill',
        );

      case 3:
      case 4:
        return const SectorThemeModel(
          sectorLevel: 3,
          sectorName: 'Solar Flare Core',
          trackPrimaryGlow: Color(0xFFFFD700), // Blazing Gold
          trackSecondaryColor: Color(0xFFFF8800),
          finishLineColor: Color(0xFFFF0055), // Crimson
          spaceDustColor: Color(0xFFFF5400),
          particleSparkColor: Color(0xFFFFD700),
          backgroundMusicVibe: 'Solar High-Energy',
        );

      case 5:
      case 6:
        return const SectorThemeModel(
          sectorLevel: 5,
          sectorName: 'Cygnus Void Rift',
          trackPrimaryGlow: Color(0xFFBD00FF), // Neon Magenta / Purple
          trackSecondaryColor: Color(0xFF7209B7),
          finishLineColor: Color(0xFF00F0FF),
          spaceDustColor: Color(0xFF3A0CA3),
          particleSparkColor: Color(0xFFBD00FF),
          backgroundMusicVibe: 'Dark Space Ambient',
        );

      case 7:
      case 8:
        return const SectorThemeModel(
          sectorLevel: 7,
          sectorName: 'Hyperion Emerald Singularity',
          trackPrimaryGlow: Color(0xFF00FF88), // Cyber Neon Green
          trackSecondaryColor: Color(0xFF06D6A0),
          finishLineColor: Color(0xFFFFD700),
          spaceDustColor: Color(0xFF0077B6),
          particleSparkColor: Color(0xFF00FF88),
          backgroundMusicVibe: 'Hyperspace Electro',
        );

      default:
        return const SectorThemeModel(
          sectorLevel: 9,
          sectorName: 'Cosmic Singularity Prime',
          trackPrimaryGlow: Color(0xFFFF0055), // Laser Red / Crimson
          trackSecondaryColor: Color(0xFFBD00FF),
          finishLineColor: Color(0xFFFFD700),
          spaceDustColor: Color(0xFF480CA8),
          particleSparkColor: Color(0xFFFF0055),
          backgroundMusicVibe: 'Quantum Peak',
        );
    }
  }
}
