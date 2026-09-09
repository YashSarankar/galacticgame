import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing audio playback cues, atmospheric BGM, and haptic feedback.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal() {
    _loadPreferences();
  }

  // Music & SFX are OFF by default at first
  bool isMuted = true;
  bool isHapticsEnabled = true;
  double bgmVolume = 0.40;

  AudioPlayer? _bgmPlayer;
  bool _isBgmPlaying = false;

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Default to muted/off on initial launch
      isMuted = prefs.getBool('pref_sound_muted') ?? true;
      isHapticsEnabled = prefs.getBool('pref_haptics_enabled') ?? true;
      bgmVolume = prefs.getDouble('pref_bgm_volume') ?? 0.40;
    } catch (_) {}
  }

  /// Initialize background cosmic synthwave music loop (only plays if unmuted)
  Future<void> startBgm() async {
    if (_isBgmPlaying) return;
    try {
      _bgmPlayer ??= AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(isMuted ? 0.0 : bgmVolume);
      await _bgmPlayer!.play(AssetSource('audio/cosmic_synthwave.wav'));
      _isBgmPlaying = true;
      if (isMuted) {
        await _bgmPlayer!.pause();
      }
    } catch (_) {
      // Audio fallback for headless test environments
    }
  }

  /// Pause background music
  Future<void> pauseBgm() async {
    try {
      if (_bgmPlayer != null) {
        await _bgmPlayer!.pause();
        _isBgmPlaying = false;
      }
    } catch (_) {}
  }

  /// Resume background music
  Future<void> resumeBgm() async {
    if (isMuted) return;
    try {
      if (_bgmPlayer != null) {
        await _bgmPlayer!.setVolume(bgmVolume);
        await _bgmPlayer!.resume();
        _isBgmPlaying = true;
      } else {
        await startBgm();
      }
    } catch (_) {}
  }

  /// Update BGM volume
  Future<void> setBgmVolume(double volume) async {
    bgmVolume = volume.clamp(0.0, 1.0);
    try {
      if (_bgmPlayer != null && !isMuted) {
        await _bgmPlayer!.setVolume(bgmVolume);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('pref_bgm_volume', bgmVolume);
    } catch (_) {}
  }

  Future<void> setMuted(bool muted) async {
    isMuted = muted;
    try {
      if (_bgmPlayer != null) {
        if (muted) {
          await _bgmPlayer!.pause();
        } else {
          await _bgmPlayer!.setVolume(bgmVolume);
          await _bgmPlayer!.resume();
          _isBgmPlaying = true;
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_sound_muted', muted);
    } catch (_) {}
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    isHapticsEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_haptics_enabled', enabled);
    } catch (_) {}
  }

  /// Trigger haptic feedback for merge shockwave
  void playMergeHaptic() {
    if (!isHapticsEnabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Trigger haptic for income line crossing on racetrack
  void playCrossingHaptic() {
    if (!isHapticsEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Trigger haptic for racetrack tap boost
  void playTrackTapHaptic() {
    if (!isHapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Trigger haptic for button presses
  void playButtonHaptic() {
    if (!isHapticsEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Play merge sound effect
  void playMergeSound() {
    if (isMuted) return;
    playMergeHaptic();
    SystemSound.play(SystemSoundType.click);
  }

  /// Play income laser crossing sound and haptic pulse on runway
  void playIncomeSound() {
    playCrossingHaptic();
    if (isMuted) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Play racetrack boost tap sound & haptic
  void playTrackTapSound() {
    playTrackTapHaptic();
    if (isMuted) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Play purchase confirmation sound
  void playPurchaseSound() {
    playButtonHaptic();
    if (isMuted) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Play reward claim celebration sound & haptic
  void playClaimSound() {
    if (isHapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (isMuted) return;
    SystemSound.play(SystemSoundType.alert);
  }

  /// Play prestige level up celebration
  void playPrestigeSound() {
    if (isHapticsEnabled) {
      HapticFeedback.vibrate();
    }
    if (isMuted) return;
    SystemSound.play(SystemSoundType.alert);
  }


  /// Play mystery crate unboxing sound & haptic burst
  void playCrateOpenSound() {
    if (isHapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (isMuted) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Play ship deployment onto circuit racetrack
  void playDeployShipSound() {
    if (isHapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (isMuted) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Play flight ops upgrade sound & haptic
  void playUpgradeSound() {
    if (isHapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (isMuted) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Play merge combo chime with intensifying haptic feedback
  void playComboSound(int comboCount) {
    if (isHapticsEnabled) {
      if (comboCount >= 3) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
    if (isMuted) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Play hyperspace fever activation rush
  void playFeverSound() {
    if (isHapticsEnabled) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.vibrate();
      });
    }
    if (isMuted) return;
    SystemSound.play(SystemSoundType.alert);
  }
}
