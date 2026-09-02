import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob Management Service for Banner and Rewarded Ads with lifecycle managers.
class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  RewardedAd? _rewardedAd;

  bool _isRewardedAdLoading = false;

  /// Official Google Mobile Ads Test Unit IDs
  static String get bannerAdUnitId {
    if (kIsWeb) return 'ca-app-pub-3940256099942544/6300978111';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) return 'ca-app-pub-3940256099942544/5224354917';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  bool get isPlatformSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Initializes AdMob SDK
  Future<void> initialize() async {
    if (!isPlatformSupported) {
      debugPrint('[AdManager] Running on non-mobile platform. AdMob simulation enabled.');
      _isInitialized = true;
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      loadRewardedAd();
    } catch (e) {
      debugPrint('[AdManager] Error initializing MobileAds: $e');
    }
  }

  /// Preloads a Rewarded Ad
  void loadRewardedAd() {
    if (!isPlatformSupported || _isRewardedAdLoading || _rewardedAd != null) return;

    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          debugPrint('[AdManager] Rewarded ad loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdManager] Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  /// Shows Rewarded Ad with callback on completion.
  /// If running on simulated environment / desktop, grants reward immediately.
  void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
    VoidCallback? onAdFailed,
  }) {
    if (!isPlatformSupported) {
      // Non-mobile simulation: Grant reward directly
      debugPrint('[AdManager] Simulated Rewarded Ad completed.');
      onUserEarnedReward();
      onAdClosed?.call();
      return;
    }

    if (_rewardedAd == null) {
      debugPrint('[AdManager] Rewarded ad not ready, granting simulated reward.');
      loadRewardedAd();
      onUserEarnedReward();
      onAdClosed?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdFailed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('[AdManager] User earned reward: ${reward.amount} ${reward.type}');
        onUserEarnedReward();
      },
    );
  }

  /// Creates a Banner Ad instance
  BannerAd? createBannerAd({required VoidCallback onAdLoaded}) {
    if (!isPlatformSupported) return null;

    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded(),
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdManager] Banner failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }
}
