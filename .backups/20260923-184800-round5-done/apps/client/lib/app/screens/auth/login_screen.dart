import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/api_client.dart';
import '../../services/google_auth.dart';
import '../../services/secure_storage.dart';
import '../../services/session.dart';
import 'forgot_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onVerify,
    required this.onBack,
    required this.config,
    required this.apiClient,
    required this.storage,
  });

  final VoidCallback onLogin;
  final ValueChanged<String> onVerify;
  final VoidCallback onBack;
  final AppConfig config;
  final ApiClientPort apiClient;
  final SecureStoragePort storage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _ageConfirmed = false;
  bool _googleBusy = false;
  bool _submitBusy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_ageConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devam etmek için 18 yaşından büyük olduğunu onayla.')),
      );
      return;
    }
    if (_submitBusy) return;
    setState(() => _submitBusy = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isLogin) {
        final res = await widget.apiClient.post('/v1/auth/login', body: {'email': email, 'password': password});
        await _saveSession(res);
        if (!mounted) return;
        widget.onLogin();
      } else {
        await widget.apiClient.post('/v1/auth/register', body: {
          'email': email,
          'password': password,
          'displayName': _nameController.text.trim().isEmpty ? email.split('@').first : _nameController.text.trim(),
          'consentVersion': 'v1',
          'ageConfirmed': true,
        },);
        if (!mounted) return;
        widget.onVerify(email);
      }
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        if (!mounted) return;
        widget.onVerify(_emailController.text.trim());
        return;
      }
      _fail(_friendlyError(e));
    } catch (e) {
      _fail(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _submitBusy = false);
    }
  }

  Future<void> _saveSession(Map<String, dynamic> res) async {
    final data = res['data'];
    final user = (data is Map ? data['user'] : null);
    final accessToken = (data is Map ? data['accessToken']?.toString() : null);
    final refreshToken = (data is Map ? data['refreshToken']?.toString() : null);
    final userId = (user is Map ? user['id']?.toString() : null);
    if (accessToken == null || accessToken.isEmpty) throw const ApiException(502, 'Sunucu token üretmedi');
    await widget.apiClient.setAccessToken(accessToken);
    await widget.storage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await widget.storage.write(key: 'refresh_token', value: refreshToken);
    }
    Session.currentUserId = userId;
    Session.accessToken = accessToken;
  }

  String _friendlyError(Object e) {
    final text = e.toString();
    if (e is ApiException) return e.message ?? 'Giriş başarısız (${e.statusCode}).';
    final host = Uri.tryParse(widget.config.apiBaseUrl)?.host ?? 'sunucu';
    if (text.contains('SocketException') || text.contains('Failed host lookup') || text.contains('Connection refused') || text.contains('timed out')) {
      return 'Sunucuya ulaşılamadı ($host). İnterneti kontrol edip tekrar dene.';
    }
    return 'Giriş başarısız, tekrar dene.';
  }

  Future<void> _signInWithGoogle() async {
    if (_googleBusy) return;
    if (!_ageConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google ile devam etmek için önce 18 yaş onayını işaretle.')),
      );
      return;
    }
    setState(() => _googleBusy = true);
    try {
      final idToken = await GoogleAuthService(
        serverClientId: widget.config.googleServerClientId,
      ).signInAndGetIdToken();
      final res = await widget.apiClient.post('/v1/auth/google', body: {
        'idToken': idToken,
        'displayName': _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        'consentVersion': 'v1',
        'ageConfirmed': true,
      },);
      await _saveSession(res);
      if (!mounted) return;
      widget.onLogin();
    } on GoogleNotConfiguredException {
      _fail('Google girişi henüz yapılandırılmadı. E-posta ile devam et.');
    } on GoogleCancelledException {
      _fail('Google girişi iptal edildi.');
    } on ApiException catch (e) {
      _fail(_friendlyError(e));
    } catch (e) {
      _fail(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AleviLogo(),
                const SizedBox(height: 34),
                Text(
                  _isLogin ? 'Tekrar hoş geldin' : 'Can Meydanı’na katıl',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Bağlantılarına kaldığın yerden devam et.' : 'Güvenli ve samimi bir topluluk seni bekliyor.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'E-posta adresi', prefixIcon: Icon(Icons.mail_outline)),
                  validator: (value) => value == null || !value.contains('@') ? 'Geçerli bir e-posta yaz.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                  autofillHints: _isLogin ? const [AutofillHints.password] : const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) {
                    if (_isLogin) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                    ),
                  ),
                  validator: (value) => value == null || value.length < 12 ? 'Şifre en az 12 karakter olmalı.' : null,
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(labelText: 'Görünen ad', prefixIcon: Icon(Icons.person_outline)),
                    validator: (value) {
                      if (_isLogin) return null;
                      return value == null || value.trim().length < 2 ? 'Görünen ad en az 2 karakter olmalı.' : null;
                    },
                  ),
                ],
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _ageConfirmed,
                  onChanged: (value) => setState(() => _ageConfirmed = value ?? false),
                  title: const Text('18 yaşından büyük olduğumu onaylıyorum.'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ForgotScreen(apiClient: widget.apiClient)),
                      ),
                      child: const Text('Şifremi unuttum'),
                    ),
                  ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: _submitBusy
                      ? 'Lütfen bekle…'
                      : _isLogin
                          ? 'Giriş yap'
                          : 'Hesap oluştur',
                  onPressed: _submitBusy ? null : _submit,
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('veya', style: TextStyle(color: AppColors.muted))),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _googleBusy ? null : _signInWithGoogle,
                  icon: _googleBusy
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(_googleBusy ? 'Google açılıyor…' : 'Google ile devam et'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? 'Hesabın yok mu? Kayıt ol' : 'Zaten hesabın var mı? Giriş yap'),
                  ),
                ),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _showPrivacy(context),
                    icon: const Icon(Icons.shield_outlined, size: 18),
                    label: const Text('Gizlilik ve güvenlik'),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
        ),
        ),
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Güvenlik ilkeleri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 12),
              Text('Verilerin kontrolü sende. İstediğin zaman görünürlüğünü düzenleyebilir, kişileri engelleyebilir ve bildirebilirsin.', style: TextStyle(color: AppColors.muted, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}
