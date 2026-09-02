import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdBoostState {
  final bool isSpeedBoostActive;
  final int speedBoostRemainingSeconds;
  final bool isPrestigeDoublerActive;

  const AdBoostState({
    this.isSpeedBoostActive = false,
    this.speedBoostRemainingSeconds = 0,
    this.isPrestigeDoublerActive = false,
  });

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

  /// Activates 2x Track Speed boost for 300 seconds (5 minutes)
  void activateSpeedBoost({int durationSeconds = 300}) {
    _countdownTimer?.cancel();
    state = state.copyWith(
      isSpeedBoostActive: true,
      speedBoostRemainingSeconds: durationSeconds,
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
