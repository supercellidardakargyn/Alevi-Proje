import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key, required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.apiClient.post('/v1/auth/forgot-password', body: {'email': _emailController.text.trim()});
      if (!mounted) return;
      setState(() => _codeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kod gönderildi. E-postanı kontrol et.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Gönderilemedi')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gönderilemedi')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    if (_codeController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('6 haneli kodu gir.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.apiClient.post('/v1/auth/reset-password', body: {
        'email': _emailController.text.trim(),
        'code': _codeController.text.trim(),
        'newPassword': _passwordController.text,
      },);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifren yenilendi. Giriş yapabilirsin.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Sıfırlanamadı')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sıfırlanamadı')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi unuttum')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _codeSent ? 'Yeni şifreni belirle' : 'E-postana kod gönderelim',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kod 10 dakika geçerli. Sıfırlayınca tüm cihazlardan çıkış yapılır.',
                      style: TextStyle(color: AppColors.muted, fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: _codeSent,
                      decoration: const InputDecoration(labelText: 'E-posta adresi', prefixIcon: Icon(Icons.mail_outline)),
                      validator: (value) => value == null || !value.contains('@') ? 'Geçerli bir e-posta yaz.' : null,
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        buildCounter: (_, {required currentLength, maxLength, required isFocused}) => null,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Doğrulama kodu', prefixIcon: Icon(Icons.mark_email_read_outlined)),
                        validator: (value) => value == null || value.trim().length != 6 ? '6 haneli kodu gir.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _reset(),
                        decoration: InputDecoration(
                          labelText: 'Yeni şifre (en az 12 karakter)',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                          ),
                        ),
                        validator: (value) => value == null || value.length < 12 ? 'Şifre en az 12 karakter olmalı.' : null,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _codeSent = false),
                          child: const Text('Farklı e-posta kullan'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _busy ? 'Lütfen bekle…' : _codeSent ? 'Şifreyi yenile' : 'Kod gönder',
                      onPressed: _busy ? null : (_codeSent ? _reset : _sendCode),
                    ),
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
