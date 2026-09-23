import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'app/services/api_client.dart';
import 'app/services/secure_storage.dart';

import 'app/services/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  Session.apiBaseUrl = config.apiBaseUrl;
  final storage = SecureStorage();
  final ApiClientPort apiClient = config.mockData
      ? MockApiClient()
      : ApiClient(baseUrl: config.apiBaseUrl);

  runApp(
    AleviApp(
      config: config,
      apiClient: apiClient,
      storage: storage,
    ),
  );
}
