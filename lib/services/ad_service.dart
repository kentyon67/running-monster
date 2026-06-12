import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _initialized = false;
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  static Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // test ID
    }
    return 'ca-app-pub-3940256099942544/1712485313'; // test ID iOS
  }

  Future<void> loadRewardedAd() async {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
        },
      ),
    );
  }

  bool get isAdReady => _rewardedAd != null;

  /// Shows rewarded ad. Calls [onRewarded] if user earns reward.
  Future<void> showRewardedAd({required void Function() onRewarded}) async {
    if (_rewardedAd == null) return;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) => onRewarded(),
    );
  }
}
