import 'dart:convert';

import 'package:http/http.dart' as http;

import 'session.dart';

abstract interface class ApiClientPort {
  Future<Map<String, dynamic>> get(String path);
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body});
  Future<Map<String, dynamic>> upload(String path, String field, List<int> bytes, String filename);
  Future<void> delete(String path);
  Future<void> setAccessToken(String? token);
}

class ApiClient implements ApiClientPort {
  ApiClient({required String baseUrl, http.Client? client})
      : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 15);

  final String _baseUrl;
  final http.Client _client;
  String? _accessToken;

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

  @override
  Future<Map<String, dynamic>> get(String path) async {
    final response =
        await _client.get(_uri(path), headers: _headers).timeout(_timeout);
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body,}) async {
    final response = await _client
        .post(_uri(path),
            headers: _headers, body: jsonEncode(body ?? <String, dynamic>{}),)
        .timeout(_timeout);
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> patch(String path,
      {Map<String, dynamic>? body,}) async {
    final response = await _client
        .patch(_uri(path),
            headers: _headers, body: jsonEncode(body ?? <String, dynamic>{}),)
        .timeout(_timeout);
    return _decode(response);
  }

  @override
  Future<void> delete(String path) async {
    final response =
        await _client.delete(_uri(path), headers: _headers).timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _messageOf(response));
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
  Future<void> delete(String path) async {}
}
