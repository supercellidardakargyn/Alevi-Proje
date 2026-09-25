import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_client.dart';
import '../../services/notifier.dart';
import '../../services/secure_storage.dart';
import '../../services/session.dart';
import '../../services/update_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../auth/forgot_screen.dart';
import '../support/support_screen.dart';
import 'safety_sheets.dart';

/// Tum uygulama tercihleri tek ekranda: bildirim, kesfet, hesap, veri, uygulama.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.apiClient, required this.storage, required this.onLoggedOut});

  final ApiClientPort apiClient;
  final SecureStoragePort storage;
  final VoidCallback onLoggedOut;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _showOnline = true;
  String _city = '';
  double _distanceKm = 25;
  String _appVersion = '';
  bool _checkingUpdate = false;
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final notifications = await widget.storage.read(key: 'notifications_enabled');
    final online = await widget.storage.read(key: 'show_online');
    final city = await widget.storage.read(key: 'discover_city');
    final distance = await widget.storage.read(key: 'discover_distance');
    String version = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } catch (_) {
      version = '';
    }
    if (!mounted) return;
    setState(() {
      _notifications = notifications != 'false';
      if (online != null) _showOnline = online != 'false';
      if (city != null) {
        _city = city;
        _cityController.text = city;
      }
      final parsed = double.tryParse(distance ?? '');
      if (parsed != null && parsed >= 1 && parsed <= 100) _distanceKm = parsed;
      _appVersion = version;
    });
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notifications = value);
    AppNotifier.enabled = value;
    await widget.storage.write(key: 'notifications_enabled', value: value ? 'true' : 'false');
    if (!value && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bildirimler kapatıldı.')));
    }
  }

  Future<void> _setOnline(bool value) async {
    setState(() => _showOnline = value);
    await widget.storage.write(key: 'show_online', value: value ? 'true' : 'false');
  }

  Future<void> _saveDiscovery() async {
    await widget.storage.write(key: 'discover_city', value: _city.trim());
    await widget.storage.write(key: 'discover_distance', value: _distanceKm.round().toString());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keşfet tercihlerin kaydedildi.')));
    }
  }

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      await UpdateService(apiClient: widget.apiClient, storage: widget.storage).checkNow(context);
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text('Bu cihazda oturumun kapatılacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Çıkış yap')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final refresh = await widget.storage.read(key: 'refresh_token');
      if (refresh != null && refresh.isNotEmpty) {
        await widget.apiClient.post('/v1/auth/logout', body: {'refreshToken': refresh});
      }
    } catch (_) {
      // Sunucu hatasi olsa da yerelde cikilir.
    }
    await widget.storage.clear();
    await widget.apiClient.setAccessToken(null);
    Session.clear();
    widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const SectionTitle('Bildirimler'),
          const SizedBox(height: 10),
          Card(
            child: SwitchListTile.adaptive(
              value: _notifications,
              onChanged: _setNotifications,
              title: const Text('Bildirimleri aç', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Eşleşme ve yeni mesaj uyarıları', style: TextStyle(color: AppColors.muted)),
              secondary: const Icon(Icons.notifications_outlined, color: AppColors.burgundy),
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Keşfet tercihleri'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _cityController,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) => _city = value,
                    decoration: const InputDecoration(labelText: 'Şehir (boşsa tüm şehirler)', prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                  const SizedBox(height: 8),
                  Text('Mesafe: ${_distanceKm.round()} km', style: const TextStyle(color: AppColors.muted)),
                  Slider(
                    value: _distanceKm,
                    min: 1,
                    max: 100,
                    divisions: 20,
                    label: '${_distanceKm.round()} km',
                    onChanged: (value) => setState(() => _distanceKm = value),
                  ),
                  const SizedBox(height: 4),
                  PrimaryButton(label: 'Tercihleri kaydet', onPressed: _saveDiscovery),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Hesap ve güvenlik'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Güvenlik merkezi',
                  subtitle: 'Engelleme, bildirim ve doğrulama',
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (_) => SafetySheet(apiClient: widget.apiClient),
                  ),
                ),
                SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Gizlilik ayarları',
                  subtitle: 'Çevrimiçi durum ve verilerin',
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    builder: (_) => PrivacySheet(
                      showOnline: _showOnline,
                      onOnlineChanged: _setOnline,
                      onExport: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MyDataScreen(apiClient: widget.apiClient)),
                      ),
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Yardım ve destek',
                  subtitle: 'Taleplerin ve yanıtları',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SupportScreen(apiClient: widget.apiClient)),
                  ),
                ),
                SettingsTile(
                  icon: Icons.key_outlined,
                  title: 'Şifreyi değiştir',
                  subtitle: 'E-posta doğrulamasıyla yenile',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ForgotScreen(apiClient: widget.apiClient)),
                  ),
                ),
                SettingsTile(
                  icon: Icons.logout_outlined,
                  title: 'Çıkış yap',
                  subtitle: 'Bu cihazdaki oturumu kapat',
                  onTap: _logout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Verilerim (KVKK)'),
          const SizedBox(height: 10),
          Card(
            child: SettingsTile(
              icon: Icons.folder_shared_outlined,
              title: 'Verilerimi gör',
              subtitle: 'Sunucuda saklanan bilgilerin',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MyDataScreen(apiClient: widget.apiClient)),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Tema'),
          const SizedBox(height: 10),
          Card(
            child: ValueListenableBuilder<AppThemeId>(
              valueListenable: ThemeController.current,
              builder: (context, current, _) => RadioGroup<AppThemeId>(
                groupValue: current,
                onChanged: (value) {
                  if (value != null) ThemeController.select(value, widget.storage);
                },
                child: Column(
                  children: [
                    for (final id in AppThemeId.values)
                      RadioListTile<AppThemeId>(
                        value: id,
                        title: Text(id.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                        activeColor: AppColors.burgundy,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Uygulama'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.system_update_outlined,
                  title: _checkingUpdate ? 'Denetleniyor…' : 'Güncellemeleri denetle',
                  subtitle: _appVersion.isEmpty ? 'Yüklü sürüm bilgisi alınıyor' : 'Yüklü: $_appVersion',
                  onTap: _checkingUpdate ? () {} : _checkUpdate,
                ),
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Gizlilik Politikası',
                  subtitle: 'sonalis.com.tr/gizlilik.html',
                  onTap: () => _openLink('https://sonalis.com.tr/gizlilik.html'),
                ),
                SettingsTile(
                  icon: Icons.gavel_outlined,
                  title: 'KVKK başvurusu',
                  subtitle: 'sonalis.com.tr/kvkk.html',
                  onTap: () => _openLink('https://sonalis.com.tr/kvkk.html'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// KVKK: sunucuda saklanan verilerin ozefeti + destek/hesap silme yonlendirmesi.
class MyDataScreen extends StatefulWidget {
  const MyDataScreen({super.key, required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends State<MyDataScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  int _matchCount = 0;
  int _conversationCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profileRes = await widget.apiClient.get('/v1/profile/me');
      final matchesRes = await widget.apiClient.get('/v1/matches');
      final convRes = await widget.apiClient.get('/v1/messages/conversations');
      if (!mounted) return;
      final matches = matchesRes['data'];
      final convs = convRes['data'];
      setState(() {
        final data = profileRes['data'];
        _profile = data is Map ? data.cast<String, dynamic>() : null;
        _matchCount = matches is List ? matches.length : 0;
        _conversationCount = convs is List ? convs.length : 0;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Veriler yüklenemedi');
    } catch (_) {
      if (mounted) setState(() => _error = 'Veriler yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Verilerim')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.muted)),
                      TextButton(onPressed: _load, child: const Text('Tekrar dene')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    const Text(
                      'Hesabınla saklanan bilgiler. Düzeltme/silme talebi için destekten yaz, 30 günde yanıtlanır.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          _row('Görünen ad', (profile?['displayName'] ?? '—').toString()),
                          _row('Şehir', (profile?['city'] ?? '—').toString()),
                          _row('Hakkımda', (profile?['bio'] ?? '—').toString()),
                          _row('İlgi alanları', ((profile?['interests'] as List?) ?? const []).join(', ').ifEmpty('—')),
                          _row('Eşleşme sayısı', '$_matchCount'),
                          _row('Sohbet sayısı', '$_conversationCount'),
                          _row('Davet kodu', (profile?['inviteCode'] ?? '—').toString()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Destekten veri talebi aç',
                      icon: Icons.support_agent_outlined,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SupportScreen(apiClient: widget.apiClient)),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _row(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      subtitle: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
