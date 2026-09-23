import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/secure_storage.dart';
import '../../services/session.dart';
import '../../theme/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'profile_edit_screen.dart';

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
              IconButton(onPressed: () => _openSettings(context), icon: const Icon(Icons.settings_outlined, color: AppColors.burgundy), tooltip: 'Güvenlik merkezi'),
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
                        const Text('Can Meydanı üyesi', style: TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 8),
                        const Row(children: [Icon(Icons.verified, size: 17, color: AppColors.gold), SizedBox(width: 4), Text('Doğrulanmış profil', style: TextStyle(fontSize: 12, color: AppColors.muted))]),
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
              subtitle: const Text('Kapalıyken aktif listesinde çıkmazsın.', style: TextStyle(color: AppColors.muted)),
              secondary: const Icon(Icons.visibility_outlined, color: AppColors.burgundy),
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('Hesap ve güvenlik'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _SettingsTile(icon: Icons.shield_outlined, title: 'Güvenlik merkezi', subtitle: 'Engelleme, bildirim ve doğrulama', onTap: () => _openSafety(context)),
                _SettingsTile(icon: Icons.lock_outline, title: 'Gizlilik ayarları', subtitle: 'Verilerin ve görünürlük tercihlerin', onTap: () => _openPrivacy(context)),
                _SettingsTile(icon: Icons.help_outline, title: 'Yardım ve destek', subtitle: 'Soruların için buradayız', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Destek: ${AppStrings.supportMail}')))),
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
          const Center(child: Text(AppStrings.appVersion, style: TextStyle(color: AppColors.muted, fontSize: 12))),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) => _openSafety(context);

  void _openSafety(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _SafetySheet(apiClient: widget.apiClient),
    );
  }

  void _openPrivacy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PrivacySheet(
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.burgundy),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _SafetySheet extends StatelessWidget {
  const _SafetySheet({required this.apiClient});

  final ApiClientPort apiClient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Güvenlik merkezi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Can Meydanı’nda kendini güvende hissetmen için kontrol sende.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          const ListTile(
            leading: Icon(Icons.verified_user_outlined),
            title: Text('Profil doğrulama'),
            subtitle: Text('E-posta doğrulamalı hesap', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            trailing: Icon(Icons.check_circle, color: AppColors.sage),
          ),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: const Text('Engellenen kişiler'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _BlocksScreen(apiClient: apiClient)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Bildirim geçmişi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _ReportsScreen(apiClient: apiClient)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlocksScreen extends StatefulWidget {
  const _BlocksScreen({required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<_BlocksScreen> createState() => _BlocksScreenState();
}

class _BlocksScreenState extends State<_BlocksScreen> {
  List<Map<String, dynamic>> _blocks = const [];
  bool _loading = true;
  String? _error;

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
      final result = await widget.apiClient.get('/v1/safety/blocks');
      final data = result['data'];
      final raw = (data is List ? data : const []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() => _blocks = raw);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Liste yüklenemedi');
    } catch (_) {
      if (mounted) setState(() => _error = 'Liste yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(String userId, String name) async {
    try {
      await widget.apiClient.delete('/v1/safety/blocks/$userId');
      if (!mounted) return;
      setState(() => _blocks = _blocks.where((block) {
            final user = block['user'];
            return (user is Map ? user['id']?.toString() : null) != userId;
          }).toList(),);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name engeli kaldırıldı.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kaldırılamadı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Engellenen kişiler')),
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
              : _blocks.isEmpty
                  ? const EmptyState(
                      icon: Icons.block_outlined,
                      title: 'Engellenen kimse yok',
                      body: 'Sohbet içindeki güvenlik menüsünden engelleyebilirsin.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _blocks.length,
                      itemBuilder: (context, index) {
                        final user = (_blocks[index]['user'] as Map?) ?? const {};
                        final name = (user['displayName'] ?? 'Bilinmeyen').toString();
                        final id = (user['id'] ?? '').toString();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: AvatarCircle(name: name, size: 48),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            trailing: TextButton(
                              onPressed: id.isEmpty ? null : () => _unblock(id, name),
                              child: const Text('Kaldır'),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _ReportsScreen extends StatefulWidget {
  const _ReportsScreen({required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<_ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<_ReportsScreen> {
  List<Map<String, dynamic>> _reports = const [];
  bool _loading = true;
  String? _error;

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
      final result = await widget.apiClient.get('/v1/safety/reports/mine');
      final data = result['data'];
      final raw = (data is List ? data : const []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() => _reports = raw);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Liste yüklenemedi');
    } catch (_) {
      if (mounted) setState(() => _error = 'Liste yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim geçmişi')),
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
              : _reports.isEmpty
                  ? const EmptyState(
                      icon: Icons.flag_outlined,
                      title: 'Bildirim yok',
                      body: 'Yaptığın bildirimler burada listelenir.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final report = _reports[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.flag_outlined, color: AppColors.burgundy),
                            title: Text((report['reason'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text((report['status'] ?? '').toString(), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _PrivacySheet extends StatelessWidget {
  const _PrivacySheet({
    required this.showOnline,
    required this.onOnlineChanged,
    required this.onExport,
  });

  final bool showOnline;
  final ValueChanged<bool> onOnlineChanged;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gizlilik ayarları', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(value: showOnline, onChanged: onOnlineChanged, title: const Text('Çevrimiçi durumunu göster')),
          ListTile(leading: const Icon(Icons.download_outlined), title: const Text('Verilerimi indir'), trailing: const Icon(Icons.chevron_right), onTap: onExport),
        ],
      ),
    );
  }
}
