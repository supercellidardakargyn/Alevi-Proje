import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';
import '../../services/secure_storage.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({
    super.key,
    required this.email,
    required this.apiClient,
    required this.storage,
    required this.onVerified,
    required this.onBack,
  });

  final String email;
  final ApiClientPort apiClient;
  final SecureStoragePort storage;
  final VoidCallback onVerified;
  final VoidCallback onBack;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _codeController = TextEditingController();
  bool _busy = false;
  bool _resending = false;
  final ValueNotifier<int> _cooldown = ValueNotifier<int>(0);

  @override
  void dispose() {
    _codeController.dispose();
    _cooldown.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _fail('6 haneli kodu gir.');
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await widget.apiClient.post('/v1/auth/verify-email',
          body: {'email': widget.email, 'code': code},);
      final data = res['data'];
      final user = (data is Map ? data['user'] : null);
      final accessToken = (data is Map ? data['accessToken']?.toString() : null);
      final refreshToken = (data is Map ? data['refreshToken']?.toString() : null);
      final userId = (user is Map ? user['id']?.toString() : null);
      if (accessToken == null || accessToken.isEmpty) {
        throw const ApiException(502, 'Sunucu token üretmedi');
      }
      await widget.apiClient.setAccessToken(accessToken);
      await widget.storage.write(key: 'access_token', value: accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await widget.storage.write(key: 'refresh_token', value: refreshToken);
      }
      Session.currentUserId = userId;
      Session.accessToken = accessToken;
      if (!mounted) return;
      widget.onVerified();
    } on ApiException catch (e) {
      _fail(e.message ?? 'Kod doğrulanamadı.');
    } catch (_) {
      _fail('Sunucuya ulaşılamadı. İnterneti kontrol et.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown.value > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await widget.apiClient
          .post('/v1/auth/resend-code', body: {'email': widget.email});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Yeni kod gönderildi. E-postanı kontrol et.'),),);
      _cooldown.value = 60;
      _tick();
    } catch (_) {
      _fail('Kod gönderilemedi, tekrar dene.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _tick() async {
    while (mounted && _cooldown.value > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      _cooldown.value--;
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              onPressed: widget.onBack, icon: const Icon(Icons.arrow_back),),),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AleviLogo(),
                  const SizedBox(height: 34),
                  Text('E-postanı doğrula',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.email} adresine 6 haneli kod gönderdik. 10 dakika geçerli.',
                    style:
                        TextStyle(color: AppInk.subtle, fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    buildCounter: (_, {required currentLength, maxLength, required isFocused}) => null,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: 'Doğrulama kodu',
                        prefixIcon: Icon(Icons.mark_email_read_outlined),),
                    onSubmitted: (_) => _verify(),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                      label: _busy ? 'Doğrulanıyor…' : 'Doğrula ve giriş yap',
                      onPressed: _busy ? null : _verify,),
                  const SizedBox(height: 12),
                  Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _cooldown,
                      builder: (context, cooldown, _) => TextButton(
                        onPressed: (_resending || cooldown > 0) ? null : _resend,
                        child: Text(cooldown > 0 ? 'Tekrar gönder ($cooldown sn)' : 'Kodu tekrar gönder',),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
