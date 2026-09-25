import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_client.dart';
import 'secure_storage.dart';

/// Mağaza dışı dağıtım güncelleyici: site/version.json ile kurulu
/// sürümü karşılaştırır, yenisi varsa indirme önerir.
class UpdateService {
  UpdateService({required this.apiClient, required this.storage});

  final ApiClientPort apiClient;
  final SecureStoragePort storage;

  Future<void> checkDaily(BuildContext context) => _check(context, force: false);

  /// Ayarlardaki "denetle" dugmesi icin gunluk kilidi atlar.
  Future<void> checkNow(BuildContext context) => _check(context, force: true);

  Future<void> _check(BuildContext context, {required bool force}) async {
    try {
      if (!force) {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final last = await storage.read(key: 'update_check_date');
        if (last == today) return;
        await storage.write(key: 'update_check_date', value: today);
      }
      final info = await PackageInfo.fromPlatform();
      final current = int.tryParse(info.buildNumber) ?? 0;
      final result = await apiClient.getAbsolute('https://sonalis.com.tr/version.json');
      final data = result;
      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isWindows
              ? 'windows'
              : null;
      if (platform == null) return;
      final entry = data[platform];
      if (entry is! Map) return;
      final latest = int.tryParse((entry['versionCode'] ?? '').toString()) ?? 0;
      final url = (entry['url'] ?? '').toString();
      if (latest > current && url.isNotEmpty && context.mounted) {
        final go = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Yeni sürüm var'),
            content: Text('Can Meydanı v${entry['version'] ?? ''} hazır. Şimdi indirilsin mi?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Sonra')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('İndir')),
            ],
          ),
        );
        if (go == true) {
          final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://sonalis.com.tr$url');
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {
      // Sessiz: güncelleme kontrolü uygulamayı engellemez.
    }
  }
}
