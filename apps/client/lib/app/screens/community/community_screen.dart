import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/community_post.dart';
import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../main_shell.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _filter = 'Sana özel';
  final List<CommunityPost> _localPosts = [];
  List<CommunityPost> _remotePosts = const [];
  List<_Community> _communities = const [];
  bool _loading = true;
  String? _error;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<CommunityPost> posts = const [];
    List<_Community> communities = const [];
    String? error;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final communitiesRes = await widget.apiClient.get('/v1/communities');
      final communitiesData = communitiesRes['data'];
      final communitiesRaw = (communitiesData is List ? communitiesData : const []).cast<Map<String, dynamic>>();
      communities = communitiesRaw
          .map((item) => _Community(id: (item['id'] ?? '').toString(), name: (item['name'] ?? 'Topluluk').toString()))
          .where((community) => community.id.isNotEmpty)
          .toList();
      // Topluluk gonderileri paralel cekilir (seri bekleme yok).
      final fetched = await Future.wait(
        communities.take(5).map((community) async {
          try {
            final postsRes = await widget.apiClient.get('/v1/communities/${community.id}/posts?limit=20');
            final postsData = postsRes['data'];
            final postsRaw = (postsData is List ? postsData : const []).cast<Map<String, dynamic>>();
            return postsRaw.map((item) => CommunityPost(
                  author: ((item['author'] as Map?)?['displayName'] ?? AppStrings.unknownUser).toString(),
                  time: relativePostTime((item['createdAt'] ?? '').toString(), 'yeni'),
                  title: community.name,
                  body: (item['body'] ?? '').toString(),
                  imageUrl: (item['imageUrl'] as String?)?.isNotEmpty == true ? (item['imageUrl'] as String) : null,
                  likes: 0,
                  comments: 0,
                  category: 'Topluluk',
                  communityId: community.id,
                  createdAtIso: (item['createdAt'] ?? '').toString(),
                ),);
          } catch (_) {
            return <CommunityPost>[];
          }
        }),
      );
      posts = fetched.expand((list) => list).toList();
    } on ApiException catch (e) {
      error = e.message ?? 'Topluluk yüklenemedi';
    } catch (_) {
      error = 'Topluluk yüklenemedi';
    }
    if (!mounted) return;
    setState(() {
      _communities = communities;
      _remotePosts = posts;
      if (_filter != 'Sana özel' && !_communities.any((community) => community.name == _filter)) {
        _filter = 'Sana özel';
      }
      _error = error;
      _loading = false;
    });
  }

  List<CommunityPost> get _allPosts => [..._remotePosts, ..._localPosts];

  List<CommunityPost> get _visiblePosts {
    if (_filter == 'Sana özel') return _allPosts;
    final selected = _communities.where((community) => community.name == _filter).toList();
    if (selected.isEmpty) return const [];
    final ids = selected.map((community) => community.id).toSet();
    return _remotePosts.where((post) => post.communityId != null && ids.contains(post.communityId)).toList();
  }

  List<String> get _filterLabels => ['Sana özel', ..._communities.map((community) => community.name)];

  Future<String?> _ensureCommunity() async {
    if (_communities.isNotEmpty) return _communities.first.id;
    final created = await widget.apiClient.post('/v1/communities', body: {
      'name': 'Genel Sohbet',
      'description': 'Herkese açık tanışma ve muhabbet topluluğu.',
      'visibility': 'PUBLIC',
    },);
    final data = created['data'];
    final id = (data is Map ? data['id']?.toString() : null) ?? '';
    if (id.isEmpty) return null;
    if (mounted) {
      setState(() {
        _communities = [..._communities, _Community(id: id, name: 'Genel Sohbet')];
      });
    }
    try {
      await widget.apiClient.post('/v1/communities/$id/join');
    } catch (_) {
      // Zaten uye olabilir.
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visiblePosts;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          ScreenHeader(
            title: 'Topluluk',
            subtitle: 'Hikâyeni paylaş, sohbete katıl.',
            action: IconButton(
              onPressed: _posting ? null : () => _showComposer(context),
              icon: const Icon(Icons.add_circle_outline, color: AppColors.burgundy),
              tooltip: 'Yeni paylaşım',
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final label in _filterLabels)
                  _CommunityFilter(
                    label: label,
                    selected: _filter == label,
                    onSelected: () => setState(() => _filter = label),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: LinearProgressIndicator())
          else if (_error != null)
            Row(
              children: [
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.muted))),
                TextButton(onPressed: _load, child: const Text('Tekrar dene')),
              ],
            )
          else if (visible.isEmpty)
            const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Bu filtrede paylaşım yok',
              body: 'İlk paylaşımı sen yap, sohbeti başlat.',
            )
          else
            ...visible.map((post) => _PostCard(post: post)),
          const SizedBox(height: 28),
          _EventsSection(apiClient: widget.apiClient),
        ],
      ),
    );
  }

  Future<void> _sharePost(String body, String? imageUrl) async {
    if (body.isEmpty || _posting) return;
    setState(() => _posting = true);
    var shared = false;
    try {
      final communityId = await _ensureCommunity();
      if (communityId == null) throw const ApiException(502, 'Topluluk hazırlanamadı');
      await widget.apiClient.post(
        '/v1/communities/$communityId/posts',
        body: {
          'body': body,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        },
      );
      shared = true;
    } catch (_) {
      // API kapaliysa yerel listeye dus, akisi kilitleme.
    } finally {
      if (mounted) {
        setState(() {
          (shared ? _remotePosts : _localPosts).insert(
            0,
            CommunityPost(
              author: 'Sen',
              time: 'şimdi',
              title: 'Yeni paylaşım',
              body: body,
              imageUrl: shared ? imageUrl : null,
              likes: 0,
              comments: 0,
              category: 'Şehir & Kültür',
            ),
          );
          _posting = false;
        });
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşımın toplulukla paylaşıldı.')),
      );
    }
  }

  void _showComposer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
        child: _ComposerSheet(
          apiClient: widget.apiClient,
          busy: _posting,
          onShare: (body, imageUrl) async {
            Navigator.of(sheetContext).pop();
            await _sharePost(body, imageUrl);
          },
        ),
      ),
    );
  }
}

class _ComposerSheet extends StatefulWidget {
  const _ComposerSheet({required this.apiClient, required this.busy, required this.onShare});

  final ApiClientPort apiClient;
  final bool busy;
  final Future<void> Function(String body, String? imageUrl) onShare;

  @override
  State<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends State<_ComposerSheet> {
  final _controller = TextEditingController();
  String? _imageUrl;
  bool _uploading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _attachPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final result = await widget.apiClient.upload('/v1/media/uploads', 'file', bytes, 'post.jpg');
      final data = result['data'];
      final url = (data is Map ? data['url']?.toString() : null);
      if (!mounted) return;
      if (url == null || url.isEmpty) throw const ApiException(502, 'Yükleme başarısız');
      setState(() => _imageUrl = url);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Yükleme başarısız')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yükleme başarısız')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _imageUrl == null ? null : Session.resolveAvatar(_imageUrl);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Yeni paylaşım', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        TextField(controller: _controller, maxLines: 4, decoration: const InputDecoration(hintText: 'Toplulukla ne paylaşmak istersin?')),
        const SizedBox(height: 12),
        if (resolved != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(resolved, headers: Session.authHeaders, height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => setState(() => _imageUrl = null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: _uploading ? null : _attachPhoto,
            icon: _uploading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add_a_photo_outlined),
            label: Text(_uploading ? 'Yükleniyor…' : 'Fotoğraf ekle'),
          ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: widget.busy ? 'Paylaşılıyor…' : 'Paylaş',
          onPressed: widget.busy || _uploading
              ? null
              : () {
                  final body = _controller.text.trim();
                  if (body.isEmpty) return;
                  widget.onShare(body, _imageUrl);
                },
        ),
      ],
    );
  }
}

class _Community {
  const _Community({required this.id, required this.name});

  final String id;
  final String name;
}

class _EventItem {
  const _EventItem({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.city,
    required this.attendeeCount,
    required this.joined,
  });

  final String id;
  final String title;
  final String startsAt;
  final String city;
  final int attendeeCount;
  final bool joined;

  factory _EventItem.fromJson(Map<String, dynamic> json) {
    return _EventItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Etkinlik').toString(),
      startsAt: (json['startsAt'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      attendeeCount: (json['attendeeCount'] as num?)?.toInt() ?? 0,
      joined: json['joined'] == true,
    );
  }
}

class _EventsSection extends StatefulWidget {
  const _EventsSection({required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<_EventsSection> createState() => _EventsSectionState();
}

class _EventsSectionState extends State<_EventsSection> {
  List<_EventItem> _events = const [];
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
      final result = await widget.apiClient.get('/v1/events');
      final data = result['data'];
      final raw = (data is List ? data : const []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _events = raw.map(_EventItem.fromJson).toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Etkinlikler yüklenemedi');
    } catch (_) {
      if (mounted) setState(() => _error = 'Etkinlikler yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleJoin(_EventItem event) async {
    try {
      if (event.joined) {
        await widget.apiClient.delete('/v1/events/${event.id}/join');
      } else {
        await widget.apiClient.post('/v1/events/${event.id}/join');
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(event.joined ? 'Katılım iptal edildi.' : 'Etkinliğe katıldın. İyi eğlenceler!')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'İşlem başarısız')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem başarısız')));
    }
  }

  Future<void> _create() async {
    final titleController = TextEditingController();
    final cityController = TextEditingController();
    DateTime? date;
    if (!mounted) return;
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni etkinlik'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Başlık')),
            TextField(controller: cityController, decoration: const InputDecoration(labelText: 'Şehir (opsiyonel)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, titleController.text.trim()), child: const Text('Devam')),
        ],
      ),
    );
    if (title == null || title.length < 2 || !mounted) return;
    date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    try {
      await widget.apiClient.post('/v1/events', body: {
        'title': title,
        if (cityController.text.trim().isNotEmpty) 'city': cityController.text.trim(),
        'startsAt': DateTime(date.year, date.month, date.day, 19).toUtc().toIso8601String(),
      },);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Etkinlik oluşturuldu.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Oluşturulamadı')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oluşturulamadı')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('Yaklaşan etkinlikler', actionLabel: 'Oluştur', onAction: _create),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: LinearProgressIndicator())
        else if (_error != null)
          Row(
            children: [
              Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.muted))),
              TextButton(onPressed: _load, child: const Text('Tekrar dene')),
            ],
          )
        else if (_events.isEmpty)
          const EmptyState(
            icon: Icons.event_outlined,
            title: 'Henüz etkinlik yok',
            body: 'İlk buluşmayı sen organize et.',
          )
        else
          ..._events.map(
            (event) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                leading: const Icon(Icons.event, color: AppColors.burgundy),
                title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  [if (event.city.isNotEmpty) event.city, '${event.attendeeCount} katılımcı'].join(' · '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                trailing: OutlinedButton(
                  onPressed: () => _toggleJoin(event),
                  child: Text(event.joined ? 'Bırak' : 'Katıl'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CommunityFilter extends StatelessWidget {
  const _CommunityFilter({required this.label, this.selected = false, this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected?.call(),
        selectedColor: AppColors.burgundy,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.charcoal, fontWeight: FontWeight.w600),
        checkmarkColor: Colors.white,
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarCircle(name: post.author, size: 40, online: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${post.category} · ${post.time}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: 16),
            Text(post.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 7),
            Text(post.body, style: const TextStyle(color: AppColors.muted, height: 1.4)),
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PostImage(url: post.imageUrl!),
            ],
          ],
        ),
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final resolved = Session.resolveAvatar(url);
    if (resolved == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        resolved,
        headers: Session.authHeaders,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
