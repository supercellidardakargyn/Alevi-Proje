class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.appName,
    required this.mockData,
    this.googleServerClientId = '',
  });

  final String apiBaseUrl;
  final String appName;
  final bool mockData;
  /// Google Cloud "Web uygulaması" OAuth istemci kimliği (google-services.json
  /// yoksa Android'de serverClientId olarak kullanılır). Boşsa Google girişi
  /// kapalıdır. Release: --dart-define=GOOGLE_SERVER_CLIENT_ID=... ile verilir.
  final String googleServerClientId;

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

    return const AppConfig(
      apiBaseUrl: apiBaseUrl,
      appName: appName,
      mockData: mockData,
      googleServerClientId: googleServerClientId,
    );
  }
}
