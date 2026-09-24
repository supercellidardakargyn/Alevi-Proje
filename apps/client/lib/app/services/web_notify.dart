/// Tarayici bildirimi (yalnizca web derlemesinde kullanilir).
///
/// Native derlemelerde `package:web` derlenemez; bu dosya yalnizca
/// `dart.library.js_interop` kosuluyla ice aktarilir.
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> requestWebNotificationPermission() async {
  try {
    if (web.Notification.permission == 'granted') return true;
    if (web.Notification.permission == 'denied') return false;
    final result = await web.Notification.requestPermission().toDart;
    return result.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

void showWebNotification(
  String title,
  String body,
  String payload,
  void Function(String conversationId, String name)? onTap,
) {
  try {
    if (web.Notification.permission != 'granted') return;
    final notification = web.Notification(title, web.NotificationOptions(body: body, tag: payload));
    notification.onclick = (() {
      try {
        web.window.focus();
      } catch (_) {}
      final parts = payload.split(':');
      if (parts.length >= 3 && parts[0] == 'msg' && onTap != null) {
        onTap(parts[1], parts.sublist(2).join(':'));
      }
    }).toJS;
  } catch (_) {}
}
