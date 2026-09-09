import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdBoostState {
  final bool isSpeedBoostActive;
  final int speedBoostRemainingSeconds;
  final bool isPrestigeDoublerActive;

  static const int boostPerAdSeconds = 900; // 15 minutes per rewarded video
  static const int maxBoostSeconds = 3600; // 60 minutes maximum stack

  const AdBoostState({
    this.isSpeedBoostActive = false,
    this.speedBoostRemainingSeconds = 0,
    this.isPrestigeDoublerActive = false,
  });

  bool get canStackBoost => speedBoostRemainingSeconds < maxBoostSeconds;

  double get boostProgress =>
      (speedBoostRemainingSeconds / maxBoostSeconds).clamp(0.0, 1.0);

  String get formattedBoostTime {
    if (speedBoostRemainingSeconds <= 0) return '2X SPEED';
    final int minutes = (speedBoostRemainingSeconds / 60).floor();
    final int seconds = speedBoostRemainingSeconds % 60;
    if (minutes >= 1) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  AdBoostState copyWith({
    bool? isSpeedBoostActive,
    int? speedBoostRemainingSeconds,
    bool? isPrestigeDoublerActive,
  }) {
    return AdBoostState(
      isSpeedBoostActive: isSpeedBoostActive ?? this.isSpeedBoostActive,
      speedBoostRemainingSeconds:
          speedBoostRemainingSeconds ?? this.speedBoostRemainingSeconds,
      isPrestigeDoublerActive:
          isPrestigeDoublerActive ?? this.isPrestigeDoublerActive,
    );
  }
}

class AdStateNotifier extends StateNotifier<AdBoostState> {
  Timer? _countdownTimer;

  AdStateNotifier() : super(const AdBoostState());

  /// Stacks 2X Track Speed boost (+15 minutes per ad, up to 60 minutes maximum)
  void activateSpeedBoost({int durationSeconds = AdBoostState.boostPerAdSeconds}) {
    final int currentRemaining = state.speedBoostRemainingSeconds;
    final int newDuration =
        min(AdBoostState.maxBoostSeconds, currentRemaining + durationSeconds);

    _countdownTimer?.cancel();
    state = state.copyWith(
      isSpeedBoostActive: true,
      speedBoostRemainingSeconds: newDuration,
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.speedBoostRemainingSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(
          isSpeedBoostActive: false,
          speedBoostRemainingSeconds: 0,
        );
      } else {
        state = state.copyWith(
          speedBoostRemainingSeconds: state.speedBoostRemainingSeconds - 1,
        );
      }
    });
  }

  /// Sets 2x Dark Matter doubler flag for Prestige
  void setPrestigeDoubler(bool active) {
    state = state.copyWith(isPrestigeDoublerActive: active);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

final adStateProvider =
    StateNotifierProvider<AdStateNotifier, AdBoostState>((ref) {
  return AdStateNotifier();
});
