import 'dart:convert';

import 'package:http/http.dart' as http;

import 'secure_storage.dart';
import 'session.dart';

abstract interface class ApiClientPort {
  Future<Map<String, dynamic>> get(String path);
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> upload(String path, String field, List<int> bytes, String filename);
  Future<Map<String, dynamic>> getAbsolute(String url);
  Future<void> delete(String path);
  Future<void> setAccessToken(String? token);
  Future<bool> refreshSession();
}

class ApiClient implements ApiClientPort {
  ApiClient({required String baseUrl, http.Client? client, SecureStoragePort? storage})
      : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _client = client ?? http.Client(),
        _storage = storage;

  static const _timeout = Duration(seconds: 15);

  final String _baseUrl;
  final http.Client _client;
  final SecureStoragePort? _storage;
  String? _accessToken;
  Future<bool>? _refreshFlight;

  static bool _isAuthPath(String path) =>
      path.contains('/v1/auth/') || path.contains('/v1/edge/');

  Uri _uri(String path) =>
      Uri.parse('$_baseUrl/${path.replaceFirst(RegExp(r'^/'), '')}');

  @override
  Future<void> setAccessToken(String? token) async {
    _accessToken = token;
    Session.accessToken = token;
  }

  Map<String, String> get _headers => <String, String>{
        'content-type': 'application/json',
        'accept': 'application/json',
        if (_accessToken != null) 'authorization': 'Bearer $_accessToken',
      };

  Future<http.Response> _withRefresh(String path, Future<http.Response> Function() send) async {
    final first = await send();
    // Web'de sayfa yenilemede bellek tokeni bos olabilir; kayitli refresh
    // tokeni varsa her 401'de yenileme denenir (basarisizsa sessizce ilk yant doner).
    if (first.statusCode != 401 || _isAuthPath(path)) return first;
    final refreshed = await _refreshOnce();
    if (!refreshed) return first;
    return send();
  }

  /// Kayitli refresh token ile oturumu canlandirir (acilis + 401 kurtarma).
  @override
  Future<bool> refreshSession() => _refreshOnce();

  /// Tek seferlik refresh (paralel 401'ler tek istekte birlesir).
  /// Basarisizsa oturum tamamen dusurulur, cagiran giris ekranina doner.
  Future<bool> _refreshOnce() async {
    final flight = _refreshFlight ??= _doRefresh().whenComplete(() => _refreshFlight = null);
    return flight;
  }

  Future<bool> _doRefresh() async {
    final storage = _storage;
    if (storage == null) return false;
    String? refreshToken;
    try {
      refreshToken = await storage.read(key: 'refresh_token');
    } catch (_) {
      refreshToken = null;
    }
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _client
          .post(_uri('/v1/auth/refresh'), headers: _headers, body: jsonEncode({'refreshToken': refreshToken}),)
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) throw const ApiException(401, null);
      final data = (jsonDecode(response.body) as Map)['data'];
      final access = (data is Map ? data['accessToken']?.toString() : null);
      final refresh = (data is Map ? data['refreshToken']?.toString() : null);
      if (access == null || access.isEmpty) return false;
      await setAccessToken(access);
      await storage.write(key: 'access_token', value: access);
      if (refresh != null && refresh.isNotEmpty) {
        await storage.write(key: 'refresh_token', value: refresh);
      }
      return true;
    } catch (_) {
      await setAccessToken(null);
      Session.clear();
      try {
        await storage.delete(key: 'access_token');
        await storage.delete(key: 'refresh_token');
      } catch (_) {}
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> get(String path) async {
    final response = await _withRefresh(path, () => _client.get(_uri(path), headers: _headers).timeout(_timeout));
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body,}) async {
    final response = await _withRefresh(
      path,
      () => _client.post(_uri(path), headers: _headers, body: jsonEncode(body ?? <String, dynamic>{}),).timeout(_timeout),
    );
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> patch(String path,
      {Map<String, dynamic>? body,}) async {
    final response = await _withRefresh(
      path,
      () => _client.patch(_uri(path), headers: _headers, body: jsonEncode(body ?? <String, dynamic>{}),).timeout(_timeout),
    );
    return _decode(response);
  }

  @override
  Future<void> delete(String path) async {
    final response = await _withRefresh(path, () => _client.delete(_uri(path), headers: _headers).timeout(_timeout));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _messageOf(response));
    }
  }

  @override
  Future<Map<String, dynamic>> getAbsolute(String url) async {
    final response = await _client.get(Uri.parse(url), headers: {'accept': 'application/json'}).timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _messageOf(response));
    }
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(response.statusCode, 'Sunucu geçersiz yanıt döndürdü');
    }
  }

  @override
  Future<Map<String, dynamic>> upload(
      String path, String field, List<int> bytes, String filename,) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers);
    request.files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> payload;
    try {
      payload = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(response.statusCode, 'Sunucu geçersiz yanıt döndürdü');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload['error'] is Map
          ? (payload['error'] as Map)['message']?.toString()
          : payload['message']?.toString();
      throw ApiException(response.statusCode, message);
    }
    return payload;
  }

  String? _messageOf(http.Response response) {
    try {
      final payload = response.body.isEmpty ? null : jsonDecode(response.body);
      if (payload is Map && payload['error'] is Map) {
        return (payload['error'] as Map)['message']?.toString();
      }
    } catch (_) {}
    return null;
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String? message;
  @override
  String toString() =>
      'ApiException($statusCode): ${message ?? 'İstek başarısız'}';
}

class MockApiClient implements ApiClientPort {
  @override
  Future<void> setAccessToken(String? token) async {}

  @override
  Future<bool> refreshSession() async => false;

  @override
  Future<Map<String, dynamic>> get(String path) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (path.contains('/presence/active')) {
      return {
        'data': {
          'items': const [
            {'id': 'active-1', 'displayName': 'Derya'},
            {'id': 'active-2', 'displayName': 'Cem'},
            {'id': 'active-3', 'displayName': 'Melek'},
          ],
        },
      };
    }
    if (path.contains('/discover')) {
      return {
        'data': {
          'items': const [
            {'id': 'mock-u1', 'displayName': 'Zeynep', 'bio': 'Kahve ve kitap.', 'city': 'İstanbul', 'avatarUrl': null, 'createdAt': '2026-01-01T00:00:00.000Z'},
            {'id': 'mock-u2', 'displayName': 'Emre', 'bio': 'Doğa yürüyüşleri.', 'city': 'Ankara', 'avatarUrl': null, 'createdAt': '2026-01-02T00:00:00.000Z'},
          ],
          'nextCursor': null,
        },
      };
    }
    if (path.contains('/matches')) {
      return {'data': const []};
    }
    if (path.contains('/messages/conversations')) {
      return {'data': const []};
    }
    if (path.contains('/events')) {
      return {
        'data': const [
          {'id': 'mock-e1', 'title': 'Tanışma pikniği', 'city': 'İstanbul', 'startsAt': '2026-10-01T16:00:00.000Z', 'attendeeCount': 3, 'joined': false},
        ],
      };
    }
    if (path.contains('/profile/me')) {
      return {
        'data': const {'id': 'mock-user', 'displayName': 'Mock Kullanıcı', 'bio': null, 'city': null, 'avatarUrl': null},
      };
    }
    if (path.contains('/safety/blocks') || path.contains('/safety/reports/mine')) {
      return {'data': const []};
    }
    if (path.contains('/communities')) {
      return {'data': const []};
    }
    return <String, dynamic>{'path': path, 'data': <String, dynamic>{}};
  }

  @override
  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body,}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (path.contains('/matches')) {
      final liked = (body?['decision'] ?? 'LIKE') == 'LIKE';
      return {
        'data': liked
            ? {'matched': true, 'conversationId': 'mock-conv-1'}
            : {'matched': false},
      };
    }
    if (path.contains('/auth/verify-email')) {
      return {
        'data': {
          'accessToken': 'mock-access-token',
          'refreshToken': 'mock-refresh-token',
          'user': {'id': 'mock-user', 'displayName': 'Mock Kullanıcı'},
        },
      };
    }
    if (path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/google')) {
      return {
        'data': {
          'accessToken': 'mock-access-token',
          'refreshToken': 'mock-refresh-token',
          'user': {'id': 'mock-user', 'displayName': 'Mock Kullanıcı'},
        },
      };
    }
    if (path.contains('/communities') && !path.contains('/posts')) {
      return {
        'data': {'id': 'mock-community-1', 'name': 'Genel Sohbet'},
      };
    }
    return <String, dynamic>{'path': path, 'data': body ?? <String, dynamic>{}};
  }

  @override
  Future<Map<String, dynamic>> patch(String path,
          {Map<String, dynamic>? body,}) async =>
      <String, dynamic>{'path': path, 'data': body ?? <String, dynamic>{}};

  @override
  Future<Map<String, dynamic>> upload(
          String path, String field, List<int> bytes, String filename,) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return <String, dynamic>{
      'path': path,
      'data': {'avatarUrl': '/v1/media/mock.jpg'},
    };
  }

  @override
  Future<Map<String, dynamic>> getAbsolute(String url) async =>
      <String, dynamic>{'android': {'versionCode': 4}};

  @override
  Future<void> delete(String path) async {}
}
