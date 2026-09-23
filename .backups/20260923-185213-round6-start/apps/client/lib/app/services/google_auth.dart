import 'package:google_sign_in/google_sign_in.dart';

/// Google ile giriş akışı.
///
/// 1. Cihazda Google hesabı seçilir, Google ID token alınır.
/// 2. Bu token backend'e (`POST /v1/auth/google`) gönderilir; sunucu imzayı
///    Google sertifikalarıyla doğrular ve kendi access token'ını döner.
/// 3. Dönen token [onAuthenticated] ile secure storage'a yazılır.
///
/// Kurulum gerektirir (kodsuz olmaz):
/// - Google Cloud'da OAuth istemcisi (Android SHA-1 + Web istemcisi),
/// - `GOOGLE_SERVER_CLIENT_ID` (--dart-define) ve sunucuda `GOOGLE_CLIENT_ID`
///   env değeri. Yapılandırılmamışsa [GoogleNotConfiguredException] fırlatır.
class GoogleAuthService {
  GoogleAuthService({required String serverClientId, GoogleSignIn? signIn})
      : _serverClientId = serverClientId,
        _signIn = signIn ?? GoogleSignIn(serverClientId: serverClientId);

  final String _serverClientId;
  final GoogleSignIn _signIn;

  Future<String> signInAndGetIdToken() async {
    if (_serverClientId.isEmpty) throw const GoogleNotConfiguredException();
    final account = await _signIn.signIn();
    if (account == null) throw const GoogleCancelledException();
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) throw const GoogleTokenException();
    return idToken;
  }

  Future<void> signOut() => _signIn.signOut();
}

class GoogleNotConfiguredException implements Exception {
  const GoogleNotConfiguredException();
  @override
  String toString() => 'Google girişi yapılandırılmadı (GOOGLE_SERVER_CLIENT_ID eksik).';
}

class GoogleCancelledException implements Exception {
  const GoogleCancelledException();
  @override
  String toString() => 'Google girişi iptal edildi.';
}

class GoogleTokenException implements Exception {
  const GoogleTokenException();
  @override
  String toString() => 'Google kimliği alınamadı, tekrar dene.';
}
