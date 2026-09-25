import 'package:flutter/material.dart';

import '../app/services/api_client.dart';
import '../app/services/secure_storage.dart';
import '../app/services/session.dart';
import '../app/theme/app_theme.dart';
import '../app/widgets/app_widgets.dart';
import 'ticket_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.apiClient, required this.storage, required this.onLoggedOut});

  final ApiClientPort apiClient;
  final SecureStoragePort storage;
  final VoidCallback onLoggedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  Future<void> _logout() async {
    try {
      final refresh = await widget.storage.read(key: 'refresh_token');
      if (refresh != null && refresh.isNotEmpty) {
        await widget.apiClient.post('/v1/auth/logout', body: {'refreshToken': refresh});
      }
    } catch (_) {}
    await widget.storage.clear();
    await widget.apiClient.setAccessToken(null);
    Session.clear();
    widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardTab(apiClient: widget.apiClient),
      _TicketsTab(apiClient: widget.apiClient),
      _ReportsTab(apiClient: widget.apiClient),
      _UsersTab(apiClient: widget.apiClient),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetim'),
        actions: [
          IconButton(icon: const Icon(Icons.logout_outlined), tooltip: 'Çıkış', onPressed: _logout),
        ],
      ),
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Genel'),
          NavigationDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent), label: 'Talepler'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Bildirimler'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Kullanıcılar'),
        ],
      ),
    );
  }
}

Widget _statCard(String label, String value, IconData icon) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.burgundy),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: AppInk.subtle, fontSize: 12)),
        ],
      ),
    ),
  );
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab({required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _overview;

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
      final result = await widget.apiClient.get('/v1/admin/overview');
      if (!mounted) return;
      final data = result;
      setState(() => _overview = data.cast<String, dynamic>());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Yüklenemedi');
    } catch (_) {
      if (mounted) setState(() => _error = 'Yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: AppInk.subtle)),
            TextButton(onPressed: _load, child: const Text('Tekrar dene')),
          ],
        ),
      );
    }
    final users = (_overview?['users'] as Map?) ?? const {};
    final reports = (_overview?['reports'] as Map?) ?? const {};
    final mesh = (_overview?['mesh'] as Map?) ?? const {};
    final activity = ((_overview?['activity'] as List?) ?? const []).cast<Map<String, dynamic>>();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const SectionTitle('Üyeler'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _statCard('Toplam üye', '${users['total'] ?? 0}', Icons.people_outline),
              _statCard('24s aktif', '${users['active24h'] ?? 0}', Icons.bolt_outlined),
              _statCard('Bu hafta', '${users['newThisWeek'] ?? 0}', Icons.person_add_outlined),
              _statCard('Onaysız e-posta', '${users['pendingVerification'] ?? 0}', Icons.mail_outline),
            ],
          ),
          const SizedBox(height: 20),
          const SectionTitle('Moderasyon'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _statCard('Açık bildirim', '${reports['open'] ?? 0}', Icons.flag_outlined),
              _statCard('Acil', '${reports['urgent'] ?? 0}', Icons.warning_amber_outlined),
              _statCard('Bugün çözülen', '${reports['resolvedToday'] ?? 0}', Icons.check_circle_outline),
              _statCard('Ağ durumu', '${mesh['state'] ?? '—'}', Icons.hub_outlined),
            ],
          ),
          const SizedBox(height: 20),
          const SectionTitle('Son hareketler'),
          const SizedBox(height: 10),
          if (activity.isEmpty)
            Text('Hareket yok.', style: TextStyle(color: AppInk.subtle))
          else
            ...activity.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text((item['title'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text((item['detail'] ?? '').toString(), style: TextStyle(color: AppInk.subtle, fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TicketsTab extends StatefulWidget {
  const _TicketsTab({required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<_TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<_TicketsTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tickets = const [];

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
      final result = await widget.apiClient.get('/v1/admin/tickets?limit=50');
      final data = result['data'];
      if (!mounted) return;
      setState(() => _tickets = (data is List ? data : const []).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Yüklenemedi');
    } catch (_) {
      if (mounted) setState(() => _error = 'Yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: AppInk.subtle)),
            TextButton(onPressed: _load, child: const Text('Tekrar dene')),
          ],
        ),
      );
    }
    if (_tickets.isEmpty) {
      return const EmptyState(icon: Icons.support_agent_outlined, title: 'Bekleyen talep yok', body: 'Tüm talepler yanıtlanmış.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        itemCount: _tickets.length,
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          final user = (ticket['user'] as Map?) ?? const {};
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text((ticket['subject'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                '${(user['displayName'] ?? 'Üye')} · ${ticket['status'] ?? ''}',
                style: TextStyle(color: AppInk.subtle, fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TicketDetailScreen(apiClient: widget.apiClient, ticket: ticket)),
                );
                if (mounted) _load();
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReportsTab extends StatefulWidget {
  const _ReportsTab({required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reports = const [];

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
      final result = await widget.apiClient.get('/v1/admin/reports?limit=50');
      final data = result['data'];
      if (!mounted) return;
      setState(() => _reports = (data is List ? data : const []).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Yüklenemedi');
    } catch (_) {
      if (mounted) setState(() => _error = 'Yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolve(Map<String, dynamic> report) async {
    String action = 'dismiss';
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text('Bildirimi çöz: ${report['reason'] ?? ''}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: action,
                items: const [
                  DropdownMenuItem(value: 'dismiss', child: Text('Reddet (işlem yok)')),
                  DropdownMenuItem(value: 'remove', child: Text('İçeriği kaldır')),
                  DropdownMenuItem(value: 'suspend', child: Text('Kullanıcıyı askıya al')),
                ],
                onChanged: (value) => setDialog(() => action = value ?? 'dismiss'),
              ),
              const SizedBox(height: 12),
              TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Not (opsiyonel)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Uygula')),
          ],
        ),
      ),
    );
    noteController.dispose();
    if (confirmed != true || !mounted) return;
    try {
      await widget.apiClient.post("/v1/admin/reports/${report['id']}/resolve", body: {
        'action': action,
        if (noteController.text.trim().isNotEmpty) 'note': noteController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bildirim çözüldü.')));
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Çözülemedi')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Çözülemedi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: AppInk.subtle)),
            TextButton(onPressed: _load, child: const Text('Tekrar dene')),
          ],
        ),
      );
    }
    if (_reports.isEmpty) {
      return const EmptyState(icon: Icons.flag_outlined, title: 'Bekleyen bildirim yok', body: 'Moderasyon kuyruğu temiz.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.burgundy),
              title: Text('${report['reason'] ?? ''} · ${report['status'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text((report['details'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppInk.subtle, fontSize: 12)),
              trailing: TextButton(onPressed: () => _resolve(report), child: const Text('Çöz')),
            ),
          );
        },
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab({required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = const [];

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
      final result = await widget.apiClient.get('/v1/admin/users?limit=50');
      final data = result['data'];
      if (!mounted) return;
      setState(() => _users = (data is List ? data : const []).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Yüklenemedi');
    } catch (_) {
      if (mounted) setState(() => _error = 'Yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _suspend(Map<String, dynamic> user) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user['displayName'] ?? 'Üye'} askıya alınsın mı?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hesap kapatılır, bu işlem geri alınamaz.', style: TextStyle(color: AppInk.subtle)),
            const SizedBox(height: 12),
            TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Gerekçe (en az 3 karakter)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Askıya al')),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;
    if (reason.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gerekçe en az 3 karakter olmalı.')));
      return;
    }
    try {
      await widget.apiClient.post("/v1/admin/users/${user['id']}/suspend", body: {'reason': reason});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı askıya alındı.')));
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Askıya alınamadı')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Askıya alınamadı')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: AppInk.subtle)),
            TextButton(onPressed: _load, child: const Text('Tekrar dene')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: AvatarCircle(name: (user['displayName'] ?? '?').toString(), size: 48),
              title: Text((user['displayName'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text((user['email'] ?? '').toString(), style: TextStyle(color: AppInk.subtle, fontSize: 12)),
              trailing: TextButton(onPressed: () => _suspend(user), child: const Text('Askıya al')),
            ),
          );
        },
      ),
    );
  }
}
