import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/verify_screen.dart';
import 'screens/main_shell.dart';
import 'services/api_client.dart';
import 'services/secure_storage.dart';
import 'theme/app_theme.dart';

class AleviApp extends StatelessWidget {
  const AleviApp({
    super.key,
    required this.config,
    required this.apiClient,
    required this.storage,
  });

  final AppConfig config;
  final ApiClientPort apiClient;
  final SecureStoragePort storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(monochrome: true),
      themeMode: ThemeMode.system,
      home: AppEntry(
        config: config,
        apiClient: apiClient,
        storage: storage,
      ),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({
    super.key,
    required this.config,
    required this.apiClient,
    required this.storage,
  });

  final AppConfig config;
  final ApiClientPort apiClient;
  final SecureStoragePort storage;

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _showOnboarding = true;
  bool _showLogin = false;
  String? _verifyEmail;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final done = await widget.storage.read(key: 'onboarding_done');
    if (!mounted) return;
    setState(() {
      _showOnboarding = done != 'true';
      _ready = true;
    });
  }

  void _completeOnboarding() {
    widget.storage.write(key: 'onboarding_done', value: 'true');
    setState(() {
      _showOnboarding = false;
      _showLogin = true;
    });
  }

  void _completeLogin() {
    setState(() {
      _showLogin = false;
      _verifyEmail = null;
    });
  }

  void _logout() {
    setState(() {
      _showOnboarding = false;
      _showLogin = true;
      _verifyEmail = null;
    });
  }

  void _startVerify(String email) {
    setState(() {
      _verifyEmail = email;
      _showLogin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }
    final pendingEmail = _verifyEmail;
    if (pendingEmail != null) {
      return VerifyScreen(
        email: pendingEmail,
        apiClient: widget.apiClient,
        storage: widget.storage,
        onVerified: _completeLogin,
        onBack: () => setState(() {
          _verifyEmail = null;
          _showLogin = true;
        }),
      );
    }
    if (_showLogin) {
      return LoginScreen(
        onLogin: _completeLogin,
        onVerify: _startVerify,
        onBack: () => setState(() => _showOnboarding = true),
        config: widget.config,
        apiClient: widget.apiClient,
        storage: widget.storage,
      );
    }
    return MainShell(
      apiClient: widget.apiClient,
      storage: widget.storage,
      onLoggedOut: _logout,
    );
  }
}
