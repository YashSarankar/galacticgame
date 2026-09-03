import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../services/storage_service.dart';
import '../services/razorpay_payment_service.dart';
import 'game_economy_provider.dart';

export 'game_economy_provider.dart';
export 'ad_state_provider.dart';


/// Main Game Economy and State Provider
final gameStateProvider =
    StateNotifierProvider<GameEconomyNotifier, GameState>((ref) {
  return GameEconomyNotifier(GameState.initial());
});

/// Async state loader for initial app startup and offline calculation
final initialGameLoaderProvider = FutureProvider<OfflineEarningsResult?>((ref) async {
  await StorageService.initialize();
  final loadedState = await StorageService.loadGameState();
  final offlineResult = StorageService.calculateOfflineEarnings(loadedState);

  // Hydrate the state into the notifier
  ref.read(gameStateProvider.notifier).loadFromState(loadedState);

  return offlineResult;
});

/// Razorpay Payment Gateway Provider
final razorpayServiceProvider = Provider<RazorpayPaymentService>((ref) {
  final service = RazorpayPaymentService()..init();
  ref.onDispose(() => service.dispose());
  return service;
});
