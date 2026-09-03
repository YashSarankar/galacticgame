import 'package:flutter/material.dart';

/// Dynamic Daily Galactic Space Weather Forecast with active sector modifiers
class CosmicWeatherModel {
  final int weekday; // 1 (Mon) - 7 (Sun)
  final String title;
  final String subtitle;
  final String iconEmoji;
  final Color themeColor;
  final double speedMultiplier;
  final double incomeMultiplier;
  final double comboBonusMultiplier;
  final double bossDarkMatterMultiplier;

  const CosmicWeatherModel({
    required this.weekday,
    required this.title,
    required this.subtitle,
    required this.iconEmoji,
    required this.themeColor,
    this.speedMultiplier = 1.0,
    this.incomeMultiplier = 1.0,
    this.comboBonusMultiplier = 1.0,
    this.bossDarkMatterMultiplier = 1.0,
  });

  /// Derives today's galactic weather based on local weekday
  static CosmicWeatherModel getTodaysWeather([DateTime? date]) {
    final int day = (date ?? DateTime.now()).weekday;
    switch (day) {
      case DateTime.monday:
        return const CosmicWeatherModel(
          weekday: DateTime.monday,
          title: 'Solar Flare Storm',
          subtitle: '+50% Fleet Track Speed',
          iconEmoji: '☀️',
          themeColor: Color(0xFFFF8800),
          speedMultiplier: 1.5,
        );

      case DateTime.tuesday:
        return const CosmicWeatherModel(
          weekday: DateTime.tuesday,
          title: 'Quantum Resonance',
          subtitle: '+50% Merge Combo Surge Bonus',
          iconEmoji: '⚡',
          themeColor: Color(0xFF00F0FF),
          comboBonusMultiplier: 1.5,
        );

      case DateTime.wednesday:
        return const CosmicWeatherModel(
          weekday: DateTime.wednesday,
          title: 'Dark Matter Aurora',
          subtitle: '2X Dark Matter from Alien Bosses',
          iconEmoji: '💎',
          themeColor: Color(0xFFBD00FF),
          bossDarkMatterMultiplier: 2.0,
        );

      case DateTime.thursday:
        return const CosmicWeatherModel(
          weekday: DateTime.thursday,
          title: 'Cosmic Cargo Tide',
          subtitle: '+35% Global Fleet Income',
          iconEmoji: '📦',
          themeColor: Color(0xFFFFD700),
          incomeMultiplier: 1.35,
        );

      case DateTime.friday:
        return const CosmicWeatherModel(
          weekday: DateTime.friday,
          title: 'Wormhole Singularity',
          subtitle: '+25% Speed & +25% Income',
          iconEmoji: '🌀',
          themeColor: Color(0xFF00FF88),
          speedMultiplier: 1.25,
          incomeMultiplier: 1.25,
        );

      case DateTime.saturday:
        return const CosmicWeatherModel(
          weekday: DateTime.saturday,
          title: 'Supernova Weekend',
          subtitle: '+50% Fleet Income Surge',
          iconEmoji: '💥',
          themeColor: Color(0xFFFF0055),
          incomeMultiplier: 1.5,
        );

      case DateTime.sunday:
      default:
        return const CosmicWeatherModel(
          weekday: DateTime.sunday,
          title: 'Galactic Alignment',
          subtitle: 'Universal +25% Speed & Income',
          iconEmoji: '✨',
          themeColor: Color(0xFFFFD700),
          speedMultiplier: 1.25,
          incomeMultiplier: 1.25,
          comboBonusMultiplier: 1.25,
        );
    }
  }
}
