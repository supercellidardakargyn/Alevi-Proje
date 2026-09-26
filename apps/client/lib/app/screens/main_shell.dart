import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/ads_service.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../services/notifier.dart';
import '../services/secure_storage.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner.dart';
import 'community/community_screen.dart';
import 'call/call_screen.dart';
import 'discover/discover_screen.dart';
import 'map/map_screen.dart';
import 'matches/matches_screen.dart';
import 'messages/messages_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.apiClient,
    required this.storage,
    required this.onLoggedOut,
    required this.config,
  });

  final ApiClientPort apiClient;
  final SecureStoragePort storage;
  final VoidCallback onLoggedOut;
  final AppConfig config;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  AppNotifier? _notifier;
  Timer? _callPoller;
  String? _activeCallId;
  String? _ringingCallId;
  late final List<Widget> _screens;
  late final AdsService _ads;

  @override
  void initState() {
    super.initState();
    _ads = AdsService(widget.config);
    _screens = [
      CommunityScreen(apiClient: widget.apiClient),
      DiscoverScreen(apiClient: widget.apiClient, storage: widget.storage),
      MapScreen(apiClient: widget.apiClient),
      MatchesScreen(apiClient: widget.apiClient),
      MessagesScreen(apiClient: widget.apiClient),
      ProfileScreen(storage: widget.storage, apiClient: widget.apiClient, onLoggedOut: widget.onLoggedOut),
    ];
    widget.storage.read(key: 'notifications_enabled').then((value) {
      AppNotifier.enabled = value != 'false';
    });
    _notifier = AppNotifier(
      apiClient: widget.apiClient,
      onMessageTap: (conversationId, name) {
        if (!mounted) return;
        setState(() => _selectedIndex = 4);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              name: name,
              conversationId: conversationId,
              apiClient: widget.apiClient,
            ),
          ),
        );
      },
    )..start();
    _callPoller = Timer.periodic(const Duration(seconds: 10), (_) => _checkIncoming());
    _shareLocation();
    _heartbeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService(apiClient: widget.apiClient, storage: widget.storage).checkDaily(context);
      _maybePromptNotifications();
      _ads.init();
    });
    // Kullanici uygulamaya dondugunde ara sira tam ekran reklam gosterilir.
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _maybePromptNotifications() async {
    final done = await widget.storage.read(key: 'notif_prompt_done');
    if (done == 'true' || !mounted) return;
    final open = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Bildirimleri aç'),
        content: const Text('Yeni eşleşme ve mesajlardan anında haberin olsun. İstediğin zaman Ayarlar’dan kapatabilirsin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Şimdi değil')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aç')),
        ],
      ),
    );
    await widget.storage.write(key: 'notif_prompt_done', value: 'true');
    if (!mounted) return;
    if (open == true) {
      final granted = await _notifier?.ensurePermission() ?? false;
      AppNotifier.enabled = true;
      await widget.storage.write(key: 'notifications_enabled', value: 'true');
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sistem izni verilmedi, bildirimler sessizde kalabilir.')),
        );
      }
    } else {
      AppNotifier.enabled = false;
      await widget.storage.write(key: 'notifications_enabled', value: 'false');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _ads.maybeShowInterstitial();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callPoller?.cancel();
    _notifier?.stop();
    _ads.dispose();
    super.dispose();
  }

  Future<void> _checkIncoming() async {
    if (!mounted || _activeCallId != null || _ringingCallId != null) return;
    try {
      final result = await widget.apiClient.get('/v1/calls/incoming');
      final data = result['data'];
      final list = (data is List ? data : const []).cast<Map<String, dynamic>>();
      if (list.isEmpty || !mounted) return;
      final call = list.first;
      final callId = (call['id'] ?? '').toString();
      if (callId.isEmpty) return;
      _ringingCallId = callId;
      final caller = (call['caller'] as Map?) ?? const {};
      final name = ((caller['displayName'] ?? '') as String).isEmpty ? 'Bilinmeyen' : (caller['displayName'] as String);
      final video = (call['kind']?.toString() ?? 'VOICE') == 'VIDEO';
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Gelen ${video ? 'görüntülü' : 'sesli'} arama'),
          content: Text('$name seni arıyor.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Reddet'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yanıtla'),
            ),
          ],
        ),
      );
      if (!mounted) {
        _ringingCallId = null;
        return;
      }
      if (accepted == true) {
        _activeCallId = callId;
        _ringingCallId = null;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CallScreen(
              apiClient: widget.apiClient,
              callId: callId,
              peerName: name,
              isVideo: video,
              isCaller: false,
              initialCall: call,
              onEnded: () => _activeCallId = null,
            ),
          ),
        );
        _activeCallId = null;
      } else {
        try {
          await widget.apiClient.post('/v1/calls/$callId/decline');
        } catch (_) {}
        _ringingCallId = null;
      }
    } catch (_) {
      // Sessiz: sonraki turda tekrar denenir.
    }
  }

  Future<void> _heartbeat() async {
    final online = await widget.storage.read(key: 'show_online');
    if (online == 'false') return;
    try {
      await widget.apiClient.post('/v1/presence/heartbeat');
    } catch (_) {
      // Sessiz: cevrimicilik bilgisi en iyi cabayla gonderilir.
    }
  }

  Future<void> _shareLocation() async {
    final position = await currentPosition();
    if (position == null) return;
    try {
      await widget.apiClient.patch('/v1/profile/me', body: {
        'latitude': position.latitude,
        'longitude': position.longitude,
      },);
    } catch (_) {
      // Sessiz: konum paylasimi zorunlu degil.
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    const destinations = [
      (icon: Icons.groups_outlined, active: Icons.groups, label: 'Topluluk'),
      (icon: Icons.explore_outlined, active: Icons.explore, label: 'Keşfet'),
      (icon: Icons.map_outlined, active: Icons.map, label: 'Harita'),
      (
        icon: Icons.favorite_border,
        active: Icons.favorite,
        label: 'Eşleşmeler'
      ),
      (
        icon: Icons.chat_bubble_outline,
        active: Icons.chat_bubble,
        label: 'Mesajlar'
      ),
      (icon: Icons.person_outline, active: Icons.person, label: 'Profil'),
    ];
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
    );
    if (landscape && size.width >= 700) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.active),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdBanner(ads: _ads),
          NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Topluluk',),
          NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Keşfet',),
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Harita',),
          NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Eşleşmeler',),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Mesajlar',),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',),
        ],
          ),
        ],
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader(
      {super.key, required this.title, this.subtitle, this.action,});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, color: AppInk.text,),),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(subtitle!, style: TextStyle(color: AppInk.subtle)),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
