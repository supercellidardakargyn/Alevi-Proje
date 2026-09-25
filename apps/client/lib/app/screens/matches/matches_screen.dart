import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/api_client.dart';
import '../../theme/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../main_shell.dart';
import '../messages/messages_screen.dart' show ChatScreen;

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key, required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  bool _loading = true;
  String? _error;
  List<Profile> _matches = const [];
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.apiClient.get('/v1/matches');
      final data = result['data'];
      final raw = (data is List ? data : const []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _matches = raw.map((item) {
          final user = (item['user'] as Map?) ?? const {};
          return Profile(
            id: user['id']?.toString(),
            name: (user['displayName'] ?? AppStrings.unknownUser).toString(),
            city: (user['city'] ?? '').toString(),
            bio: (user['bio'] ?? '').toString(),
          );
        }).toList();
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message ?? 'Eşleşmeler yüklenemedi');
    } catch (_) {
      if (mounted) setState(() => _error = 'Eşleşmeler yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openChat(Profile profile) async {
    if (profile.id == null || _opening) return;
    setState(() => _opening = true);
    try {
      final created = await widget.apiClient.post('/v1/messages/conversations', body: {
        'participantIds': [profile.id],
      },);
      final data = created['data'];
      final conversationId = (data is Map ? data['id']?.toString() : null);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            name: profile.name,
            conversationId: conversationId,
            otherUserId: profile.id,
            apiClient: widget.apiClient,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Sohbet açılamadı')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sohbet açılamadı')));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const ScreenHeader(title: 'Eşleşmeler', subtitle: 'Karşılıklı ilgiler burada.'),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: LinearProgressIndicator())
          else if (_error != null && _matches.isEmpty)
            Row(
              children: [
                Expanded(child: Text(_error!, style: TextStyle(color: AppInk.subtle))),
                TextButton(onPressed: _loadMatches, child: const Text('Tekrar dene')),
              ],
            )
          else if (_matches.isEmpty)
            const EmptyState(
              icon: Icons.favorite_border,
              title: 'Henüz eşleşme yok',
              body: 'Keşfette beğenmeye devam et. Karşılıklı ilgi burada listelenir.',
            )
          else ...[
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _matches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final profile = _matches[index];
                  return Column(
                    children: [
                      AvatarCircle(name: profile.name, size: 58, online: index != 1),
                      const SizedBox(height: 6),
                      Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Divider(color: AppInk.divider),
            const SizedBox(height: 18),
            const SectionTitle('Yeni eşleşmeler'),
            const SizedBox(height: 12),
            ..._matches.map((profile) => _MatchTile(profile: profile, onOpen: () => _openChat(profile))),
          ],
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.profile, required this.onOpen});

  final Profile profile;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: AvatarCircle(name: profile.name, size: 52, online: true),
        title: Text(profile.age > 0 ? '${profile.name}, ${profile.age}' : profile.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(profile.city.isEmpty ? 'Can Meydanı üyesi' : profile.city, style: TextStyle(color: AppInk.subtle)),
        trailing: IconButton(
          onPressed: onOpen,
          icon: const Icon(Icons.chat_bubble_outline, color: AppColors.burgundy),
          tooltip: 'Sohbeti aç',
        ),
      ),
    );
  }
}
