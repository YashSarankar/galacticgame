import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob Management Service for Banner, Rewarded, and Smart Interstitial Ads
/// with rate limiting, VIP bypass, and FTUE protection.
class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  /// Timestamp tracking for strict non-aggressive 4-minute interstitial rate limiting
  DateTime? _lastInterstitialTimestamp;
  static const int _interstitialCooldownSeconds = 240; // 4 minutes

  /// Google Mobile Ads Production Unit IDs (Android & iOS)
  static String get bannerAdUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-9441953606119572/6216765385';
    }
    return 'ca-app-pub-9441953606119572/1902115855';
  }

  static String get rewardedAdUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-9441953606119572/2277520376';
    }
    return 'ca-app-pub-9441953606119572/9589034185';
  }

  static String get interstitialAdUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-9441953606119572/6025193698';
    }
    return 'ca-app-pub-9441953606119572/2962926401';
  }

  bool get isPlatformSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Initializes AdMob SDK with official Google UMP Consent Management (GDPR & ATT)
  Future<void> initialize() async {
    if (!isPlatformSupported) {
      debugPrint(
          '[AdManager] Running on non-mobile platform. AdMob simulation enabled.');
      _isInitialized = true;
      return;
    }

    try {
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          ConsentForm.loadAndShowConsentFormIfRequired(
            (FormError? formError) async {
              if (formError != null) {
                debugPrint(
                    '[AdManager] Consent form load error: ${formError.message}');
              }
              await _initMobileAds();
            },
          );
        },
        (FormError formError) async {
          debugPrint(
              '[AdManager] Consent info request error: ${formError.message}');
          await _initMobileAds();
        },
      );
    } catch (e) {
      debugPrint('[AdManager] Consent flow initialization fallback: $e');
      await _initMobileAds();
    }
  }

  Future<void> _initMobileAds() async {
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      loadRewardedAd();
      loadInterstitialAd();
      debugPrint('[AdManager] Google Mobile Ads initialized successfully.');
    } catch (e) {
      debugPrint('[AdManager] Error initializing MobileAds: $e');
    }
  }

  // ==========================================
  // REWARDED ADS (Opt-in High Value)
  // ==========================================

  /// Preloads a Rewarded Ad
  void loadRewardedAd() {
    if (!isPlatformSupported || _isRewardedAdLoading || _rewardedAd != null) {
      return;
    }

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
  /// If running on simulated environment or ad not ready, grants reward smoothly.
  void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
    VoidCallback? onAdFailed,
  }) {
    if (!isPlatformSupported) {
      debugPrint('[AdManager] Simulated Rewarded Ad completed.');
      onUserEarnedReward();
      onAdClosed?.call();
      return;
    }

    if (_rewardedAd == null) {
      debugPrint(
          '[AdManager] Rewarded ad not cached yet. Granting immediate reward.');
      loadRewardedAd();
      onUserEarnedReward();
      onAdClosed?.call();
      return;
    }

    bool earnedReward = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (earnedReward) {
          onUserEarnedReward();
        }
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdManager] Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdFailed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint(
            '[AdManager] User earned reward: ${reward.amount} ${reward.type}');
        earnedReward = true;
      },
    );
  }

  // ==========================================
  // SMART INTERSTITIAL ADS (Rate-Limited Natural Breaks)
  // ==========================================

  /// Preloads an Interstitial Ad
  void loadInterstitialAd() {
    if (!isPlatformSupported ||
        _isInterstitialLoading ||
        _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('[AdManager] Interstitial ad loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdManager] Interstitial ad failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Shows a smart interstitial ad with strict player-friendly guards:
  /// 1. Has Removed Ads / VIP -> Blocked (0 ads)
  /// 2. Tutorial Step < 5 -> Blocked (protects new player FTUE onboarding)
  /// 3. Less than 4 minutes since last interstitial -> Blocked (strict cooldown)
  void showSmartInterstitial({
    required bool hasRemovedAds,
    required int tutorialStep,
    VoidCallback? onAdClosed,
  }) {
    if (hasRemovedAds) {
      onAdClosed?.call();
      return;
    }

    if (tutorialStep < 5) {
      debugPrint('[AdManager] Smart interstitial suppressed during tutorial.');
      onAdClosed?.call();
      return;
    }

    final now = DateTime.now();
    if (_lastInterstitialTimestamp != null) {
      final elapsedSeconds =
          now.difference(_lastInterstitialTimestamp!).inSeconds;
      if (elapsedSeconds < _interstitialCooldownSeconds) {
        debugPrint(
            '[AdManager] Smart interstitial cooldown active ($elapsedSeconds/$_interstitialCooldownSeconds s). Suppressed.');
        onAdClosed?.call();
        return;
      }
    }

    if (!isPlatformSupported || _interstitialAd == null) {
      loadInterstitialAd();
      onAdClosed?.call();
      return;
    }

    _lastInterstitialTimestamp = now;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdManager] Interstitial failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onAdClosed?.call();
      },
    );

    _interstitialAd!.show();
  }

  // ==========================================
  // BANNER ADS
  // ==========================================

  /// Creates a standard Banner Ad instance
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
