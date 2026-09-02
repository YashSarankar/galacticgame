import 'package:flutter/services.dart';

/// Service managing audio playback cues and haptic feedback.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool isMuted = false;
  bool isHapticsEnabled = true;

  /// Trigger haptic feedback for merge shockwave
  void playMergeHaptic() {
    if (!isHapticsEnabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Trigger haptic for income line crossing
  void playCrossingHaptic() {
    if (!isHapticsEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Trigger haptic for button presses
  void playButtonHaptic() {
    if (!isHapticsEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Play merge sound effect
  void playMergeSound() {
    if (isMuted) return;
    playMergeHaptic();
    SystemSound.play(SystemSoundType.click);
  }

  /// Play income laser crossing sound
  void playIncomeSound() {
    if (isMuted) return;
    playCrossingHaptic();
  }

  /// Play purchase confirmation sound
  void playPurchaseSound() {
    if (isMuted) return;
    playButtonHaptic();
    SystemSound.play(SystemSoundType.click);
  }

  /// Play prestige level up celebration
  void playPrestigeSound() {
    if (isMuted) return;
    if (isHapticsEnabled) {
      HapticFeedback.vibrate();
    }
  }
}
