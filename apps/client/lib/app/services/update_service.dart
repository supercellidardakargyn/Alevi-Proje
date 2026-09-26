import 'dart:io' show Directory, File, Platform, Process, exit;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_client.dart';
import 'secure_storage.dart';

/// Magaza disi dagitim guncelleyici: site/version.json ile kurulu
/// surumu karsilastirir. Windows kurulum paketinde sessiz kuruluma
/// gecer (indir + dogrula + /VERYSILENT kurulum); diger platformlarda
/// indirme onerir.
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
      final result = await apiClient.getAbsolute('https://canmeydani.com.tr/version.json');
      final platform = _platformKey();
      if (platform == null) return;
      final entry = result[platform];
      if (entry is! Map) return;
      final latest = int.tryParse((entry['versionCode'] ?? '').toString()) ?? 0;
      final url = (entry['url'] ?? '').toString();
      if (latest <= current || url.isEmpty || !context.mounted) {
        if (force && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uygulaman güncel.')),
          );
        }
        return;
      }
      final version = (entry['version'] ?? '').toString();
      final sha = (entry['sha256'] ?? '').toString();
      // Windows kurulum paketi: sessiz indir + kur.
      if (!kIsWeb && platform == 'windows' && url.toLowerCase().endsWith('.exe')) {
        await _silentWindowsUpdate(context, url, sha, version);
        return;
      }
      if (!context.mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Yeni sürüm var'),
          content: Text('Can Meydanı v$version hazır. Şimdi indirilsin mi?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Sonra')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('İndir')),
          ],
        ),
      );
      if (go == true) {
        final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://canmeydani.com.tr$url');
        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Sessiz: güncelleme kontrolü uygulamayı engellemez.
    }
  }

  String? _platformKey() {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return null;
  }

  /// Kurulum exe'sini indirir, SHA-256 dogrular, sessiz kurar ve cikar.
  /// Dogrulama basarisizsa hicbir sey calistirilmaz.
  Future<void> _silentWindowsUpdate(BuildContext context, String url, String sha, String version) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('v$version indiriliyor, arka planda kurulacak…'), duration: const Duration(seconds: 4)),
    );
    try {
      final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://canmeydani.com.tr$url');
      if (uri == null) return;
      final response = await http.get(uri).timeout(const Duration(minutes: 5));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return;
      if (sha.isNotEmpty) {
        final digest = sha256.convert(response.bodyBytes).toString();
        if (digest.toLowerCase() != sha.toLowerCase()) return;
      }
      final file = File('${Directory.systemTemp.path}\\can-meydani-kurulum-$version.exe');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kuruluyor, uygulama kapatılıyor…')),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      await Process.start(file.path, const ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/CLOSEAPPLICATIONS'], runInShell: true);
      exit(0);
    } catch (_) {
      // Sessiz: indirme/kurulum basarisizsa kullanici manuel indirebilir.
    }
  }
}
