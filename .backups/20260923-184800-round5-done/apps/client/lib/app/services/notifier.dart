import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_client.dart';

/// Uygulama acikken 60 sn'de bir eslesme/sohbet degisikligini yoklayip
/// yerel bildirim gosterir. FCM altyapisi hazir olana kadar gecerli cozum.
class AppNotifier {
  AppNotifier({required ApiClientPort apiClient}) : _apiClient = apiClient;

  final ApiClientPort _apiClient;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _started = false;
  int _lastMatchCount = -1;
  final Map<String, String> _lastPreview = {};

  Future<void> start() async {
    if (_started) return;
    _started = true;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      linux: LinuxInitializationSettings(defaultActionName: 'Aç'),
      windows: WindowsInitializationSettings(
        appName: 'Can Meydanı',
        appUserModelId: 'com.alevi.client',
        guid: '8f9e2c1a-3b4d-4e5f-a6b7-c8d9e0f1a2b3',
      ),
    );
    await _plugin.initialize(settings);
    await _poll();
  }

  Future<void> _poll() async {
    while (_started) {
      await Future<void>.delayed(const Duration(seconds: 60));
      try {
        await _check();
      } catch (_) {
        // Sessiz: bir sonraki turda tekrar denenir.
      }
    }
  }

  Future<void> _check() async {
    final matchesRes = await _apiClient.get('/v1/matches');
    final matchesData = matchesRes['data'];
    final matchCount = matchesData is List ? matchesData.length : 0;
    if (_lastMatchCount >= 0 && matchCount > _lastMatchCount) {
      await _show('Yeni eşleşmen var', 'Keşfette karşılıklı ilgi oluştu. Sohbete başla.');
    }
    _lastMatchCount = matchCount;

    final convRes = await _apiClient.get('/v1/messages/conversations');
    final convData = convRes['data'];
    final conversations = (convData is List ? convData : const []).cast<Map<String, dynamic>>();
    for (final conversation in conversations) {
      final id = conversation['id']?.toString() ?? '';
      final last = conversation['lastMessage'] as Map?;
      final preview = last?['body']?.toString() ?? '';
      if (id.isEmpty || preview.isEmpty) continue;
      final previous = _lastPreview[id];
      if (previous != null && previous != preview) {
        await _show('Yeni mesaj', preview);
      }
      _lastPreview[id] = preview;
    }
  }

  Future<void> _show(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails('can_meydani_updates', 'Can Meydanı güncellemeleri', importance: Importance.high),
    );
    await _plugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }

  void stop() {
    _started = false;
  }
}
