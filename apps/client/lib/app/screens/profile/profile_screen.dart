import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';
import '../../services/secure_storage.dart';
import '../../services/session.dart';
import '../../theme/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../support/support_screen.dart';
import 'profile_edit_screen.dart';
import 'safety_sheets.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.storage, required this.apiClient, required this.onLoggedOut});

  final SecureStoragePort storage;
  final ApiClientPort apiClient;
  final VoidCallback onLoggedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showOnline = true;
  String _displayName = '';
  String? _avatarUrl;
  String? _inviteCode;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final online = await widget.storage.read(key: 'show_online');
    if (mounted && online != null) setState(() => _showOnline = online != 'false');
    try {
      final result = await widget.apiClient.get('/v1/profile/me');
      final data = result['data'];
      if (data is Map && mounted) {
        setState(() {
          final name = data['displayName']?.toString() ?? '';
          if (name.isNotEmpty) _displayName = name;
          _avatarUrl = data['avatarUrl']?.toString();
          final code = data['inviteCode']?.toString();
          if (code != null && code.isNotEmpty) _inviteCode = code;
        });
      }
    } catch (_) {
      // Cevrimdisi/demo modda yer tutucu ad korunur.
    } finally {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  Future<void> _openEdit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProfileEditScreen(apiClient: widget.apiClient)),
    );
    if (saved == true) _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            children: [
              const Expanded(child: Text('Profilim', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(apiClient: widget.apiClient, storage: widget.storage, onLoggedOut: widget.onLoggedOut),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined, color: AppColors.burgundy),
                tooltip: 'Ayarlar',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  AvatarCircle(name: _displayName.isEmpty ? '?' : _displayName, size: 76, online: true, avatarUrl: _avatarUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profileLoading
                              ? 'Yükleniyor…'
                              : _displayName.isEmpty
                                  ? AppStrings.guestUser
                                  : _displayName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text('Can Meydanı üyesi', style: TextStyle(color: AppInk.subtle)),
                        const SizedBox(height: 8),
                        Row(children: [const Icon(Icons.verified, size: 17, color: AppColors.gold), const SizedBox(width: 4), Text('Doğrulanmış profil', style: TextStyle(fontSize: 12, color: AppInk.subtle))]),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _openEdit,
                    icon: const Icon(Icons.edit_outlined, color: AppColors.burgundy),
                    tooltip: 'Profili düzenle',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Profil görünürlüğü'),
          const SizedBox(height: 10),
          Card(
            child: SwitchListTile.adaptive(
              value: _showOnline,
              onChanged: (value) async {
                setState(() => _showOnline = value);
                await widget.storage.write(key: 'show_online', value: value ? 'true' : 'false');
                if (!value && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Çevrimiçi görünürlüğün kapatıldı.')),
                  );
                }
              },
              title: const Text('Çevrimiçi görün', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Kapalıyken aktif listesinde çıkmazsın.', style: TextStyle(color: AppInk.subtle)),
              secondary: const Icon(Icons.visibility_outlined, color: AppColors.burgundy),
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Hesap ve güvenlik'),
          const SizedBox(height: 10),
          if (_inviteCode != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.mail_outline, color: AppColors.burgundy),
                title: const Text('Davet kodun', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_inviteCode!, style: const TextStyle(letterSpacing: 2)),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.burgundy),
                  tooltip: 'Kodu kopyala',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _inviteCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Davet kodun kopyalandı. Paylaş, onaylı rozet kazandır.')),
                    );
                  },
                ),
              ),
            ),
          if (_inviteCode != null) const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SettingsTile(icon: Icons.shield_outlined, title: 'Güvenlik merkezi', subtitle: 'Engelleme, bildirim ve doğrulama', onTap: () => _openSafety(context)),
                SettingsTile(icon: Icons.lock_outline, title: 'Gizlilik ayarları', subtitle: 'Verilerin ve görünürlük tercihlerin', onTap: () => _openPrivacy(context)),
                SettingsTile(icon: Icons.help_outline, title: 'Yardım ve destek', subtitle: 'Taleplerin ve yanıtları', onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SupportScreen(apiClient: widget.apiClient)),
                    ),),
              ],
            ),
          ),
          const SizedBox(height: 22),
          OutlinedButton(
            onPressed: () => _confirmDelete(context),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('Hesabı sil'),
          ),
          const SizedBox(height: 14),
          Center(child: Text(AppStrings.appVersion, style: TextStyle(color: AppInk.subtle, fontSize: 12))),
        ],
      ),
    );
  }

  void _openSafety(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafetySheet(apiClient: widget.apiClient),
    );
  }

  void _openPrivacy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => PrivacySheet(
        showOnline: _showOnline,
        onOnlineChanged: (value) async {
          setState(() => _showOnline = value);
          await widget.storage.write(key: 'show_online', value: value ? 'true' : 'false');
        },
        onExport: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veri dışa aktarma isteğin alındı (KVKK).')),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabın silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz. Profilin kapatılır ve oturumun sonlanır.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.apiClient.delete('/v1/profile/me');
              } catch (_) {
                // Sunucu hatasi olsa da yerelde cikilir.
              }
              await widget.storage.clear();
              await widget.apiClient.setAccessToken(null);
              Session.clear();
              widget.onLoggedOut();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
