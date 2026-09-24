import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_client.dart';
import 'session.dart';
import 'web_notify_stub.dart' if (dart.library.js_interop) 'web_notify.dart';

/// Uygulama acikken eslesme/sohbet degisikligini yoklayip bildirim gosterir.
/// Mobil/masaustunde yerel bildirim, web'de tarayici bildirimi kullanilir.
/// Sunucu tarafinda FCM kurulana kadar gecerli cozumdur.
class AppNotifier {
  AppNotifier({required ApiClientPort apiClient, this.onMessageTap}) : _apiClient = apiClient;

  final ApiClientPort _apiClient;
  final void Function(String conversationId, String name)? onMessageTap;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _started = false;
  bool _webGranted = false;
  int _lastMatchCount = -1;
  final Map<String, String> _lastPreview = {};

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      if (kIsWeb) {
        await _requestWebPermission();
      } else {
        const settings = InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
          macOS: DarwinInitializationSettings(),
          linux: LinuxInitializationSettings(defaultActionName: 'Aç'),
          windows: WindowsInitializationSettings(
            appName: 'Can Meydanı',
            appUserModelId: 'com.alevi.client',
            guid: '8f9e2c1a-3b4d-4e5f-a6b7-c8d9e0f1a2b3',
          ),
        );
        await _plugin.initialize(
          settings,
          onDidReceiveNotificationResponse: (response) {
            final payload = response.payload ?? '';
            final parts = payload.split(':');
            if (parts.length >= 3 && parts[0] == 'msg') {
              onMessageTap?.call(parts[1], parts.sublist(2).join(':'));
            }
          },
        );
        await _requestPermission();
      }
      await _poll();
    } catch (_) {
      _started = false;
    }
  }

  Future<void> _requestWebPermission() async {
    _webGranted = await requestWebNotificationPermission();
  }

  Future<void> _requestPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  Future<void> _poll() async {
    while (_started) {
      await Future<void>.delayed(const Duration(seconds: 30));
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
      await _show('Yeni eşleşmen var', 'Keşfette karşılıklı ilgi oluştu. Sohbete başla.', null, null);
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
      _lastPreview[id] = preview;
      if (previous == null || previous == preview) continue;
      // Acik sohbet icin bildirim gerekmez, icerik zaten ekranda.
      if (Session.openConversationId == id) continue;
      // Kendi mesajim icin bildirim gerekmez.
      if ((last?['senderId']?.toString() ?? '') == Session.currentUserId) continue;
      final name = _otherName(conversation);
      await _show(name, preview, 'msg:$id:$name', (String convId, String convName) {
        onMessageTap?.call(convId, convName);
      });
    }
  }

  String _otherName(Map<String, dynamic> conversation) {
    final members = (conversation['members'] as List? ?? const []).cast<Map<String, dynamic>>();
    for (final member in members) {
      final id = member['id']?.toString() ?? '';
      if (id.isNotEmpty && id != Session.currentUserId) {
        final name = (member['displayName'] ?? '').toString();
        if (name.isNotEmpty) return name;
      }
    }
    final title = (conversation['title'] ?? '').toString();
    return title.isNotEmpty ? title : 'Can Meydanı';
  }

  Future<void> _show(
    String title,
    String body,
    String? payload,
    void Function(String conversationId, String name)? tap,
  ) async {
    if (kIsWeb) {
      _showWeb(title, body, payload, tap);
      return;
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails('can_meydani_updates', 'Can Meydanı güncellemeleri', importance: Importance.high),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  void _showWeb(
    String title,
    String body,
    String? payload,
    void Function(String conversationId, String name)? tap,
  ) {
    if (!_webGranted) return;
    showWebNotification(title, body, payload ?? '', tap);
  }

  void stop() {
    _started = false;
  }
}
