import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

/// Uygulama ici reklam (AdMob).
///
/// Varsayilan degerler Google'in **resmi test kimlikleridir**; gercek hesap
/// kimlikleri verilene kadar test reklamlari gosterilir. Kimlikler iki yerden
/// gelir:
///   - Android: `android/gradle.properties` icindeki `admobAppId` (manifest)
///   - Dart: `--dart-define=ADMOB_BANNER_UNIT=...` / `ADMOB_INTERSTITIAL_UNIT=...`
///
/// Web/masaustu platformunda reklam gosterilmez. Cevrimdisi veya yuklenemeyen
/// reklam sessizce gizlenir, uygulama hicbir kosulda calismazliga girmez.
class AdsService extends ChangeNotifier {
  AdsService(this.config);

  final AppConfig config;

  static const _testBannerUnit = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialUnit = 'ca-app-pub-3940256099942544/1033173712';

  static bool get _supported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool _ready = false;
  bool _initializing = false;
  BannerAd? _banner;
  InterstitialAd? _interstitial;
  DateTime _lastInterstitial = DateTime.fromMillisecondsSinceEpoch(0);

  bool get enabled => _supported && config.adsEnabled;

  String get _bannerUnit => config.admobBannerUnit.isNotEmpty ? config.admobBannerUnit : _testBannerUnit;
  String get _interstitialUnit =>
      config.admobInterstitialUnit.isNotEmpty ? config.admobInterstitialUnit : _testInterstitialUnit;

  /// Uygulama acilirken bir kez cagrilir. Hata durumunda sessizce gecersiz
  /// kilinir; reklam yoksa da uygulama calisir.
  Future<void> init() async {
    if (!enabled || _ready || _initializing) return;
    _initializing = true;
    try {
      await MobileAds.instance.initialize();
      _ready = true;
    } catch (error) {
      debugPrint('[ads] baslatilamadi: $error');
    } finally {
      _initializing = false;
    }
  }

  /// Alt banner reklamini yukler (ana ekranin altinda gosterilir).
  Future<void> loadBanner({AdSize? size}) async {
    if (!enabled) return;
    await init();
    if (!_ready) return;
    await _banner?.dispose();
    _banner = null;
    notifyListeners();
    final ad = BannerAd(
      adUnitId: _bannerUnit,
      size: size ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => notifyListeners(),
        onAdFailedToLoad: (ad, error) {
          debugPrint('[ads] banner yuklenemedi: ${error.message}');
          notifyListeners();
        },
      ),
    );
    _banner = ad;
    await ad.load();
  }

  Future<void> disposeBanner() async {
    await _banner?.dispose();
    _banner = null;
    notifyListeners();
  }

  /// Ara sira gosterilen tam ekran reklam. Kural: en az 4 dakika aralikla ve
  /// sadece uygulama on plandayken.
  Future<void> maybeShowInterstitial() async {
    if (!enabled) return;
    await init();
    if (!_ready) return;
    final now = DateTime.now();
    if (now.difference(_lastInterstitial) < const Duration(minutes: 4)) return;
    if (_interstitial == null) {
      await InterstitialAd.load(
        adUnitId: _interstitialUnit,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitial = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitial = null;
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('[ads] interstitial gosterilemedi: ${error.message}');
                ad.dispose();
                _interstitial = null;
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('[ads] interstitial yuklenemedi: ${error.message}');
            _interstitial = null;
          },
        ),
      );
    }
    final ad = _interstitial;
    if (ad == null) return;
    _lastInterstitial = now;
    await ad.show();
  }

  BannerAd? get banner => _banner;
}
