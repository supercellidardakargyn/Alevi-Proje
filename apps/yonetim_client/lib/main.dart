import 'package:flutter/material.dart';

import 'app/services/api_client.dart';
import 'app/services/secure_storage.dart';
import 'app/services/session.dart';
import 'app/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

const _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.sonalis.com.tr');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SecureStorage();
  final apiClient = ApiClient(baseUrl: _apiBaseUrl, storage: storage);
  runApp(YonetimApp(apiClient: apiClient, storage: storage));
}

class YonetimApp extends StatelessWidget {
  const YonetimApp({super.key, required this.apiClient, required this.storage});

  final ApiClientPort apiClient;
  final SecureStoragePort storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Can Meydanı Yönetim',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _Gate(apiClient: apiClient, storage: storage),
    );
  }
}

class _Gate extends StatefulWidget {
  const _Gate({required this.apiClient, required this.storage});

  final ApiClientPort apiClient;
  final SecureStoragePort storage;

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  bool _ready = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    String? token;
    try {
      token = await widget.storage.read(key: 'access_token');
    } catch (_) {
      token = null;
    }
    if (token != null && token.isNotEmpty) {
      try {
        await widget.apiClient.setAccessToken(token);
        await widget.apiClient.get('/v1/admin/overview');
        if (!mounted) return;
        setState(() {
          _loggedIn = true;
          _ready = true;
        });
        return;
      } catch (_) {
        await widget.apiClient.setAccessToken(null);
        Session.clear();
      }
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_loggedIn) {
      return LoginScreen(
        apiClient: widget.apiClient,
        storage: widget.storage,
        onLoggedIn: () => setState(() => _loggedIn = true),
      );
    }
    return HomeScreen(
      apiClient: widget.apiClient,
      storage: widget.storage,
      onLoggedOut: () => setState(() => _loggedIn = false),
    );
  }
}
