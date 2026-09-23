import 'package:flutter/material.dart';

import '../../models/conversation.dart';
import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../main_shell.dart';
import '../matches/matches_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _query = '';
  bool _loading = true;
  String? _error;
  List<Conversation> _conversations = const [];

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
      final result = await widget.apiClient.get('/v1/messages/conversations');
      final data = result['data'];
      final raw = (data is List ? data : const []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _conversations = raw.map(Conversation.fromApi).toList();
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message ?? 'Sohbetler yüklenemedi');
    } catch (_) {
      if (mounted) setState(() => _error = 'Sohbetler yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    List<Conversation> filter(List<Conversation> source) => query.isEmpty
        ? source
        : source
            .where((c) =>
                c.name.toLowerCase().contains(query) ||
                c.preview.toLowerCase().contains(query),)
            .toList();
    final conversations = [...filter(_conversations)];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          ScreenHeader(
            title: 'Mesajlar',
            subtitle: 'Sohbetlerin ve bağlantıların.',
            action: IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MatchesScreen(apiClient: widget.apiClient)),
              ),
              icon: const Icon(Icons.edit_outlined, color: AppColors.burgundy),
              tooltip: 'Eşleşmelerden sohbet başlat',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Mesajlarda ara'),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: LinearProgressIndicator())
          else if (_error != null && conversations.isEmpty)
            Row(
              children: [
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.muted))),
                TextButton(onPressed: _load, child: const Text('Tekrar dene')),
              ],
            )
          else if (conversations.isEmpty)
            const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'Henüz sohbet yok',
              body: 'Keşfette eşleşince sohbetlerin burada listelenir.',
            )
          else
            ...conversations.map(
              (conversation) => _ConversationTile(conversation: conversation, apiClient: widget.apiClient),
            ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.apiClient});

  final Conversation conversation;
  final ApiClientPort apiClient;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () {
          final otherId = conversation.memberIds.firstWhere(
            (id) => id != Session.currentUserId,
            orElse: () => '',
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                name: conversation.name,
                conversationId: conversation.id,
                otherUserId: otherId.isEmpty ? null : otherId,
                apiClient: apiClient,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: AvatarCircle(name: conversation.name, size: 54, online: conversation.online),
        title: Row(
          children: [
            Expanded(child: Text(conversation.name, style: const TextStyle(fontWeight: FontWeight.w800))),
            if (conversation.time.isNotEmpty)
              Text(conversation.time, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(child: Text(conversation.preview, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (conversation.unread > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.burgundy, shape: BoxShape.circle),
                child: Text('${conversation.unread}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.name, this.conversationId, this.otherUserId, required this.apiClient});

  final String name;
  final String? conversationId;
  final String? otherUserId;
  final ApiClientPort apiClient;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<String> _messages = [];
  bool _loading = false;
  String? _error;
  bool _sending = false;

  bool get _remote => widget.conversationId != null;

  @override
  void initState() {
    super.initState();
    if (_remote) {
      _load();
    } else {
      _messages.add('Hafta sonu sergiye gidelim mi?');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.apiClient.get('/v1/messages/conversations/${widget.conversationId}/messages');
      final data = result['data'];
      final raw = (data is List ? data : const []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(raw.map((item) => (item['body'] ?? '').toString()));
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message ?? 'Mesajlar yüklenemedi');
    } catch (_) {
      if (mounted) setState(() => _error = 'Mesajlar yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final value = _controller.text.trim();
    if (value.isEmpty || _sending) return;
    if (!_remote) {
      setState(() {
        _messages.add(value);
        _controller.clear();
      });
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.apiClient.post('/v1/messages/conversations/${widget.conversationId}/messages', body: {'body': value});
      if (!mounted) return;
      setState(() {
        _messages.add(value);
        _controller.clear();
      });
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Mesaj gönderilemedi')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mesaj gönderilemedi')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [AvatarCircle(name: widget.name, size: 34, online: true), const SizedBox(width: 10), Text(widget.name)]),
        actions: [
          IconButton(onPressed: () => _showSafety(context), icon: const Icon(Icons.shield_outlined), tooltip: 'Güvenlik'),
        ],
      ),
      body: Column(
        children: [
          if (_loading)
            const LinearProgressIndicator()
          else if (_error != null && _messages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.muted))),
                  TextButton(onPressed: _load, child: const Text('Tekrar dene')),
                ],
              ),
            )
          else
            Expanded(
              child: _messages.isEmpty
                  ? const EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'Henüz mesaj yok',
                      body: 'İlk selamı sen ver.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => Align(
                        alignment: index.isEven ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: index.isEven ? Colors.white : AppColors.burgundy,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(_messages[index], style: TextStyle(color: index.isEven ? AppColors.charcoal : Colors.white)),
                        ),
                      ),
                    ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Bir mesaj yaz…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    tooltip: 'Gönder',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSafety(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Kişiyi engelle'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(sheetContext);
                final target = widget.otherUserId;
                if (target == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo sohbette engelleme kullanılamaz.')),
                  );
                  return;
                }
                try {
                  await widget.apiClient.post('/v1/safety/blocks', body: {'userId': target});
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.name} engellendi.')),
                  );
                } on ApiException catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Engelleme başarısız')));
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engelleme başarısız')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Bildirim gönder'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(sheetContext);
                final target = widget.otherUserId;
                if (target == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo sohbette bildirim kullanılamaz.')),
                  );
                  return;
                }
                try {
                  await widget.apiClient.post('/v1/safety/reports', body: {'userId': target, 'reason': 'OTHER'});
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bildirimin alındı. Ekibimiz inceleyecek.')),
                  );
                } on ApiException catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Bildirim başarısız')));
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bildirim başarısız')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Sohbet gizliliği'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hassas bilgilerin varsayılan olarak gizli.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
