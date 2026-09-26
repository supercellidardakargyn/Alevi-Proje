/// Windows/Linux/macOS sistem cekmecesi: X tusunda kapatmak yerine
/// cekmeceye indir (Discord tarzi), simge menusu Ac/Cikis sunar.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class _TrayHost with TrayListener, WindowListener {
  Future<void> init() async {
    try {
      await windowManager.ensureInitialized();
      await windowManager.setPreventClose(true);
      final dir = await Directory('${Directory.systemTemp.path}/can-meydani').create(recursive: true);
      final iconFile = File('${dir.path}/can-tray.ico');
      if (!await iconFile.exists()) {
        final data = await rootBundle.load('assets/icon/can-tray.ico');
        await iconFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      await TrayManager.instance.setIcon(iconFile.path);
      await TrayManager.instance.setToolTip('Can Meydanı');
      await TrayManager.instance.setContextMenu(
        Menu(
          items: [
            MenuItem(key: 'show', label: 'Aç'),
            MenuItem.separator(),
            MenuItem(key: 'quit', label: 'Çıkış'),
          ],
        ),
      );
      TrayManager.instance.addListener(this);
      windowManager.addListener(this);
    } catch (_) {}
  }

  Future<void> toggle() async {
    try {
      final visible = await windowManager.isVisible();
      if (visible) {
        await windowManager.hide();
      } else {
        await _show();
      }
    } catch (_) {}
  }

  Future<void> _show() async {
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (_) {}
  }

  @override
  void onTrayIconMouseDown() {
    toggle();
  }

  @override
  void onTrayIconRightMouseDown() {
    try {
      TrayManager.instance.popUpContextMenu();
    } catch (_) {}
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'quit') {
      quitApp();
    } else {
      _show();
    }
  }

  @override
  void onWindowClose() async {
    try {
      if (await windowManager.isPreventClose()) await windowManager.hide();
    } catch (_) {}
  }
}

bool get _supported => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

Future<void> initTray() async {
  if (!_supported) return;
  await _TrayHost().init();
}

Future<void> quitApp() async {
  if (!_supported) return;
  try {
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  } catch (_) {
    exit(0);
  }
}
