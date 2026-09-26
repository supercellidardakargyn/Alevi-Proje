import '../../services/api_client.dart';

/// Sunucudaki FIFO kuyruktan gelen yapay zeka yardimcilarinin istemci tarafi.
/// Her cagrida null donebilir (AI kapaliysa veya model hatasi verirse);
/// cagiran taraf bu durumda sessizce gizlenir.
class AiService {
  const AiService(this.apiClient);

  final ApiClientPort apiClient;

  /// Son mesaja gore 3 hazir cevap onerisi.
  Future<List<String>> smartReplies(String conversationId) async {
    try {
      final result = await apiClient.post('/v1/ai/smart-replies', body: {'conversationId': conversationId});
      return _strings(result['data'], 'suggestions');
    } catch (_) {
      return const [];
    }
  }

  /// Hedef profile gore 3 ilk mesaj onerisi.
  Future<List<String>> icebreakers(String userId) async {
    try {
      final result = await apiClient.post('/v1/ai/icebreakers', body: {'userId': userId});
      return _strings(result['data'], 'openers');
    } catch (_) {
      return const [];
    }
  }

  /// Bio duzeltme onerisi (yeni bio + 2 ipucu).
  Future<String?> coachBio(String bio) async {
    try {
      final result = await apiClient.post('/v1/ai/bio-coach', body: {'bio': bio});
      final data = result['data'];
      if (data is Map) {
        final text = (data['suggestion'] ?? '').toString().trim();
        return text.isEmpty ? null : text;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sohbet ozeti (en fazla 3 cumle).
  Future<String?> summarize(String conversationId) async {
    try {
      final result = await apiClient.post('/v1/ai/summarize', body: {'conversationId': conversationId});
      final data = result['data'];
      if (data is Map) {
        final text = (data['summary'] ?? '').toString().trim();
        return text.isEmpty ? null : text;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// "Neden eslestiniz" tek cumle notu.
  Future<String?> matchNote(String userId) async {
    try {
      final result = await apiClient.post('/v1/ai/match-note', body: {'userId': userId});
      final data = result['data'];
      if (data is Map) {
        final text = (data['note'] ?? '').toString().trim();
        return text.isEmpty ? null : text;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<String> _strings(Object? data, String key) {
    if (data is! Map) return const [];
    final raw = data[key];
    if (raw is! List) return const [];
    final rows = raw.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
    return rows;
  }
}
