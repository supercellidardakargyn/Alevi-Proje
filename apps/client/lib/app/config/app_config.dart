class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.appName,
    required this.mockData,
    this.googleServerClientId = '',
    this.adsEnabled = true,
    this.admobAndroidAppId = '',
    this.admobIosAppId = '',
    this.admobBannerUnit = '',
    this.admobInterstitialUnit = '',
    this.adsenseClientId = '',
  });

  final String apiBaseUrl;
  final String appName;
  final bool mockData;
  /// Google Cloud "Web uygulaması" OAuth istemci kimliği (google-services.json
  /// yoksa Android'de serverClientId olarak kullanılır). Boşsa Google girişi
  /// kapalıdır. Release: --dart-define=GOOGLE_SERVER_CLIENT_ID=... ile verilir.
  final String googleServerClientId;

  /// Uygulama ici reklam anahtari. Kapaliysa hicbir reklam yuklenmez.
  final bool adsEnabled;
  final String admobAndroidAppId;
  final String admobIosAppId;
  final String admobBannerUnit;
  final String admobInterstitialUnit;

  /// Web (site) icin AdSense yayinci kimligi; ads.txt ve etiketler icin.
  final String adsenseClientId;

  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:3000',
    );
    const appName = String.fromEnvironment(
      'APP_NAME',
      defaultValue: 'Can Meydanı',
    );
    const mockData = bool.fromEnvironment('MOCK_DATA', defaultValue: true);
    const googleServerClientId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '',
    );
    const adsEnabled = bool.fromEnvironment('ADS_ENABLED', defaultValue: true);
    const admobAndroidAppId = String.fromEnvironment('ADMOB_ANDROID_APP_ID', defaultValue: '');
    const admobIosAppId = String.fromEnvironment('ADMOB_IOS_APP_ID', defaultValue: '');
    const admobBannerUnit = String.fromEnvironment('ADMOB_BANNER_UNIT', defaultValue: '');
    const admobInterstitialUnit = String.fromEnvironment('ADMOB_INTERSTITIAL_UNIT', defaultValue: '');
    const adsenseClientId = String.fromEnvironment('ADSENSE_CLIENT_ID', defaultValue: '');

    return const AppConfig(
      apiBaseUrl: apiBaseUrl,
      appName: appName,
      mockData: mockData,
      googleServerClientId: googleServerClientId,
      adsEnabled: adsEnabled,
      admobAndroidAppId: admobAndroidAppId,
      admobIosAppId: admobIosAppId,
      admobBannerUnit: admobBannerUnit,
      admobInterstitialUnit: admobInterstitialUnit,
      adsenseClientId: adsenseClientId,
    );
  }
}
