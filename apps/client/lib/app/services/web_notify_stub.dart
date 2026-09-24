/// Tarayici bildirimi destegi olmayan platformlar icin bos govde.
/// Imzalar `web_notify.dart` ile birebir aynidir.
library;

Future<bool> requestWebNotificationPermission() async => false;

void showWebNotification(
  String title,
  String body,
  String payload,
  void Function(String conversationId, String name)? onTap,
) {}
