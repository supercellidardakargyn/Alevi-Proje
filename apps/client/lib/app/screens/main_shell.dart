import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/location_service.dart';
import '../services/notifier.dart';
import '../services/secure_storage.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import 'community/community_screen.dart';
import 'discover/discover_screen.dart';
import 'matches/matches_screen.dart';
import 'messages/messages_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.apiClient,
    required this.storage,
    required this.onLoggedOut,
  });

  final ApiClientPort apiClient;
  final SecureStoragePort storage;
  final VoidCallback onLoggedOut;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  AppNotifier? _notifier;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CommunityScreen(apiClient: widget.apiClient),
      DiscoverScreen(apiClient: widget.apiClient),
      MatchesScreen(apiClient: widget.apiClient),
      MessagesScreen(apiClient: widget.apiClient),
      ProfileScreen(storage: widget.storage, apiClient: widget.apiClient, onLoggedOut: widget.onLoggedOut),
    ];
    _notifier = AppNotifier(apiClient: widget.apiClient)..start();
    _shareLocation();
    _heartbeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService(apiClient: widget.apiClient, storage: widget.storage).checkDaily(context);
    });
  }

  @override
  void dispose() {
    _notifier?.stop();
    super.dispose();
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
      bottomNavigationBar: NavigationBar(
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
                      fontWeight: FontWeight.w800, color: AppColors.charcoal,),),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(subtitle!, style: const TextStyle(color: AppColors.muted)),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
