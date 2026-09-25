import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

/// Profil ve Ayarlar ekranlarinin ortak kullandigi guvenlik bilesenleri.
class SettingsTile extends StatelessWidget {
  const SettingsTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

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
      subtitle: Text(subtitle, style: TextStyle(color: AppInk.subtle, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class SafetySheet extends StatelessWidget {
  const SafetySheet({super.key, required this.apiClient});

  final ApiClientPort apiClient;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Güvenlik merkezi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Can Meydanı’nda kendini güvende hissetmen için kontrol sende.', style: TextStyle(color: AppInk.subtle)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Profil doğrulama'),
              subtitle: Text('E-posta doğrulamalı hesap', style: TextStyle(color: AppInk.subtle, fontSize: 12)),
              trailing: const Icon(Icons.check_circle, color: AppColors.sage),
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('Engellenen kişiler'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BlocksScreen(apiClient: apiClient)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Bildirim geçmişi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReportsScreen(apiClient: apiClient)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlocksScreen extends StatefulWidget {
  const BlocksScreen({super.key, required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<BlocksScreen> createState() => _BlocksScreenState();
}

class _BlocksScreenState extends State<BlocksScreen> {
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
                      Text(_error!, style: TextStyle(color: AppInk.subtle)),
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

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
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
                      Text(_error!, style: TextStyle(color: AppInk.subtle)),
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
                            subtitle: Text((report['status'] ?? '').toString(), style: TextStyle(color: AppInk.subtle, fontSize: 12)),
                          ),
                        );
                      },
                    ),
    );
  }
}

class PrivacySheet extends StatelessWidget {
  const PrivacySheet({
    super.key,
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
