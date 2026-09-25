import 'package:flutter/material.dart';

import '../app/services/api_client.dart';
import '../app/services/secure_storage.dart';
import '../app/services/session.dart';
import '../app/theme/app_theme.dart';
import '../app/widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.apiClient, required this.storage, required this.onLoggedIn});

  final ApiClientPort apiClient;
  final SecureStoragePort storage;
  final VoidCallback onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.apiClient.post('/v1/auth/admin-login', body: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });
      final data = result['data'];
      final access = (data is Map ? data['accessToken']?.toString() : null) ?? '';
      final refresh = (data is Map ? data['refreshToken']?.toString() : null) ?? '';
      if (access.isEmpty) throw const ApiException(401, 'Giriş başarısız');
      await widget.apiClient.setAccessToken(access);
      await widget.storage.write(key: 'access_token', value: access);
      if (refresh.isNotEmpty) await widget.storage.write(key: 'refresh_token', value: refresh);
      Session.currentUserId = 'admin';
      if (mounted) widget.onLoggedIn();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.statusCode == 403
            ? 'Bu hesapta yönetici yetkisi yok.'
            : e.message ?? 'E-posta veya şifre hatalı');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Bağlanılamadı. Sunucuyu kontrol edin.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined, color: AppColors.burgundy, size: 64),
                    const SizedBox(height: 16),
                    const Text('Can Meydanı Yönetim', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Yalnızca ADMIN yetkili hesaplar girebilir.', textAlign: TextAlign.center, style: TextStyle(color: AppInk.subtle)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.mail_outline)),
                      validator: (value) => value == null || !value.contains('@') ? 'Geçerli e-posta girin.' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Şifre girin.' : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                    ],
                    const SizedBox(height: 20),
                    PrimaryButton(label: _busy ? 'Giriliyor…' : 'Giriş yap', onPressed: _busy ? null : _login),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
