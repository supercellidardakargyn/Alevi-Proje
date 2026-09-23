// Oturumun hafif bellek kopyasi. Token'lar secure storage'dadir;
// burada yalnizca kimlik ve API header'i icin gereken parca tutulur.
class Session {
  static String? currentUserId;
  static String? accessToken;
  static String apiBaseUrl = '';

  static Map<String, String> get authHeaders => <String, String>{
        if (accessToken != null) 'authorization': 'Bearer $accessToken',
      };

  static String? resolveAvatar(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    if (apiBaseUrl.isEmpty) return null;
    return '$apiBaseUrl$url';
  }

  static void clear() {
    currentUserId = null;
    accessToken = null;
  }
}
