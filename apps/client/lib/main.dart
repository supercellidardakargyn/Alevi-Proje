import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'app/services/api_client.dart';
import 'app/services/secure_storage.dart';
import 'app/services/tray_stub.dart' if (dart.library.io) 'app/services/tray_service.dart';

import 'app/services/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  Session.apiBaseUrl = config.apiBaseUrl;
  final storage = SecureStorage();
  final ApiClientPort apiClient = config.mockData
      ? MockApiClient()
      : ApiClient(baseUrl: config.apiBaseUrl, storage: storage);

  runApp(
    AleviApp(
      config: config,
      apiClient: apiClient,
      storage: storage,
    ),
  );
  // Masaustunde sistem cekmecesi (carpida kapatma yerine gizleme).
  initTray();
}
