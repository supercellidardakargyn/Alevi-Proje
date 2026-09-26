import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../models/active_user.dart';
import '../../services/api_client.dart';
import '../../services/location_data.dart';
import '../../services/location_service.dart';
import '../../services/secure_storage.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../ai/ai_sheet.dart';
import '../main_shell.dart';
import '../messages/messages_screen.dart' show ChatScreen;
import '../profile/location_fields.dart';

class _GeoPoint {
  const _GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, required this.apiClient, required this.storage});

  final ApiClientPort apiClient;
  final SecureStoragePort storage;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _profileIndex = 0;
  bool _filtersOpen = false;
  bool _activeLoading = true;
  String? _activeError;
  String? _swipeError;
  String? _discoverError;
  bool _swipeBusy = false;
  bool _discoverLoading = true;
  List<ActiveUser> _activeUsers = const [];
  List<Profile> _discoverProfiles = const [];
  Profile? _lastRemoved;
  bool _undoBusy = false;
  double _distanceKm = 25;
  LocationChoice _location = const LocationChoice();
  _GeoPoint? _geo;
  bool _filterBusy = false;
  final Set<String> _ageRanges = {'26–35'};

  List<Profile> get _cards => _discoverProfiles;

  @override
  void initState() {
    super.initState();
    _loadActiveUsers();
    _restoreFilters();
  }

  Future<void> _restoreFilters() async {
    final country = await widget.storage.read(key: 'discover_country');
    final city = await widget.storage.read(key: 'discover_city');
    final district = await widget.storage.read(key: 'discover_district');
    final distance = await widget.storage.read(key: 'discover_distance');
    if (!mounted) return;
    setState(() {
      _location = LocationChoice(
        country: country?.isEmpty ?? true ? null : country,
        city: city?.isEmpty ?? true ? null : city,
        district: district?.isEmpty ?? true ? null : district,
      );
      final parsed = double.tryParse(distance ?? '');
      if (parsed != null && parsed >= 1 && parsed <= 100) _distanceKm = parsed;
    });
    await _loadDiscover();
  }

  Future<void> _loadActiveUsers() async {
    List<ActiveUser> users = const [];
    String? error;
    setState(() {
      _activeLoading = true;
      _activeError = null;
    });
    try {
      final result = await widget.apiClient.get('/v1/presence/active');
      final data = result['data'];
      final raw = (data is Map ? data['items'] as List<dynamic>? : null) ?? const [];
      users = raw.map((item) => ActiveUser.fromJson(item as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      error = e.message ?? 'Aktif kullanıcılar yüklenemedi';
    } catch (_) {
      error = 'Aktif kullanıcılar yüklenemedi';
    }
    if (!mounted) return;
    setState(() {
      _activeUsers = users;
      _activeError = error;
      _activeLoading = false;
    });
  }

  Future<void> _applyFilters() async {
    setState(() => _filterBusy = true);
    try {
      await widget.storage.write(key: 'discover_country', value: _location.country ?? '');
      await widget.storage.write(key: 'discover_city', value: _location.city ?? '');
      await widget.storage.write(key: 'discover_district', value: _location.district ?? '');
      await widget.storage.write(key: 'discover_distance', value: _distanceKm.round().toString());
      final position = await currentPosition();
      if (position == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum izni verilmedi. Mesafe filtresi uygulanamadı.')),
        );
        return;
      }
      if (mounted) setState(() => _geo = _GeoPoint(position.latitude, position.longitude));
      try {
        await widget.apiClient.patch('/v1/profile/me', body: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },);
      } catch (_) {
        // Profil guncelleme basarisizsa bile listeyi filtreli getir.
      }
      await _loadDiscover();
      if (mounted) setState(() => _filtersOpen = false);
    } finally {
      if (mounted) setState(() => _filterBusy = false);
    }
  }

  Future<void> _loadDiscover() async {
    List<Profile> profiles = const [];
    String? error;
    setState(() {
      _discoverLoading = true;
      _discoverError = null;
    });
    try {
      final params = <String, String>{'limit': '20'};
      final country = _location.country;
      final city = _location.city;
      final district = _location.district;
      if (country != null && country.isNotEmpty) params['country'] = country;
      if (city != null && city.isNotEmpty) params['city'] = city;
      if (district != null && district.isNotEmpty) params['district'] = district;
      if (_geo != null) {
        params['latitude'] = _geo!.latitude.toString();
        params['longitude'] = _geo!.longitude.toString();
        params['maxDistanceKm'] = _distanceKm.round().toString();
      }
      final query = params.entries.map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}').join('&');
      final result = await widget.apiClient.get('/v1/discover?$query');
      final data = result['data'];
      final raw = (data is Map ? data['items'] as List<dynamic>? : null) ?? const [];
      profiles = raw.map((item) => Profile.fromDiscover(item as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      error = e.message ?? 'Keşfet yüklenemedi';
    } catch (_) {
      error = 'Keşfet yüklenemedi';
    }
    if (!mounted) return;
    setState(() {
      _discoverProfiles = profiles;
      _discoverError = error;
      _discoverLoading = false;
      _profileIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards;
    final profile = cards.isEmpty ? null : cards[_profileIndex % cards.length];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          ScreenHeader(
            title: 'Keşfet',
            subtitle: 'Bugün kiminle tanışacaksın?',
            action: IconButton(
              onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
              icon: Icon(_filtersOpen ? Icons.tune : Icons.tune_outlined, color: AppColors.burgundy),
              tooltip: 'Filtreler',
            ),
          ),
          if (_filtersOpen) ...[
            const SizedBox(height: 18),
            _FilterPanel(
              distanceKm: _distanceKm,
              location: _location,
              ageRanges: _ageRanges,
              busy: _filterBusy,
              onDistanceChanged: (value) => setState(() => _distanceKm = value),
              onLocationChanged: (value) => setState(() => _location = value),
              onAgeToggled: (range) => setState(() {
                if (_ageRanges.contains(range)) {
                  _ageRanges.remove(range);
                } else {
                  _ageRanges.add(range);
                }
              }),
              onApply: _applyFilters,
              onClose: () => setState(() => _filtersOpen = false),
            ),
          ],
          const SizedBox(height: 22),
          SectionTitle('Şu anda aktif', actionLabel: 'Yenile', onAction: _loadActiveUsers),
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: _activeLoading
                ? const Center(child: LinearProgressIndicator())
                : _activeError != null
                    ? Row(
                        children: [
                          Expanded(child: Text(_activeError!, style: TextStyle(color: AppInk.subtle))),
                          TextButton(onPressed: _loadActiveUsers, child: const Text('Tekrar dene')),
                        ],
                      )
                    : _activeUsers.isEmpty
                    ? const Align(alignment: Alignment.centerLeft, child: Text('Şu anda aktif kullanıcı bulunamadı.'))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _activeUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (_, index) => Column(
                          children: [
                            AvatarCircle(name: _activeUsers[index].displayName, online: true, size: 46),
                            const SizedBox(height: 4),
                            Text(_activeUsers[index].displayName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
          ),
          const SizedBox(height: 22),
          if (_discoverLoading)
            const Center(child: LinearProgressIndicator())
          else if (_discoverError != null)
            Row(
              children: [
                Expanded(child: Text(_discoverError!, style: TextStyle(color: AppInk.subtle))),
                TextButton(onPressed: _loadDiscover, child: const Text('Tekrar dene')),
              ],
            )
          else if (profile == null)
            const EmptyState(
              icon: Icons.explore_outlined,
              title: 'Keşfedilecek kimse yok',
              body: 'Yeni üyeler katıldıkça burada görünür. Kendin de aktifsin; arkadaşlarını davet et, topluluk büyüsün.',
            )
          else ...[
            ProfileCard(profile: profile),
            if (profile.id != null) ...[
              const SizedBox(height: 10),
              MatchNoteText(apiClient: widget.apiClient, userId: profile.id!),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _swipeBusy ? null : _openIcebreakers,
                icon: const Icon(Icons.waving_hand, size: 18),
                label: const Text('Buz kırıcı önerileri'),
              ),
            ],
            if (_swipeError != null) ...[
              const SizedBox(height: 8),
              Text(_swipeError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  button: true,
                  label: 'Son kaydırmayı geri al',
                  child: _RoundAction(icon: Icons.undo, color: _lastRemoved == null ? AppInk.subtle : AppColors.burgundy, onPressed: (_swipeBusy || _undoBusy || _lastRemoved == null) ? null : _undo),
                ),
                const SizedBox(width: 22),
                Semantics(
                  button: true,
                  label: 'Profili geç',
                  child: _RoundAction(icon: Icons.close, color: AppInk.text, onPressed: _swipeBusy ? null : () => _swipe('PASS')),
                ),
                const SizedBox(width: 22),
                Semantics(
                  button: true,
                  label: 'Profili öne çıkar',
                  child: _RoundAction(icon: Icons.star_outline, color: AppColors.gold, onPressed: _swipeBusy ? null : () => _swipe('LIKE')),
                ),
                const SizedBox(width: 22),
                Semantics(
                  button: true,
                  label: 'Profili beğen',
                  child: _RoundAction(icon: Icons.favorite, color: AppColors.burgundy, onPressed: _swipeBusy ? null : () => _swipe('LIKE')),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          const SectionTitle('Sana özel topluluklar', actionLabel: 'Tümünü gör'),
          const SizedBox(height: 12),
          SizedBox(
            height: 94,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _TopicCard(icon: Icons.palette_outlined, label: 'Kültür & Sanat'),
                _TopicCard(icon: Icons.hiking, label: 'Doğa & Rota'),
                _TopicCard(icon: Icons.music_note_outlined, label: 'Müzik'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _nextProfile() => setState(() => _profileIndex++);

  /// Buz kirici onerisi: secilen cumle begeni bosluk birakmaz, mesaj
  /// taslagi olarak sohbete tasinir; kullanici gondermeden once duzenler.
  Future<void> _openIcebreakers() async {
    final cards = _cards;
    if (cards.isEmpty || _swipeBusy) return;
    final target = cards[_profileIndex % cards.length];
    final userId = target.id;
    if (userId == null) return;
    String? draft;
    await showIcebreakerSheet(
      context,
      apiClient: widget.apiClient,
      userId: userId,
      displayName: target.name,
      onPick: (text) => draft = text,
    );
    if (draft == null || !mounted) return;
    await _swipe('LIKE', openChatWith: draft!);
  }

  Future<void> _swipe(String decision, {String? openChatWith}) async {
    final cards = _cards;
    if (cards.isEmpty) return;
    final target = cards[_profileIndex % cards.length];
    if (target.id == null) {
      _nextProfile();
      return;
    }
    setState(() {
      _swipeBusy = true;
      _swipeError = null;
    });
    try {
      final result = await widget.apiClient.post('/v1/matches', body: {
        'userId': target.id,
        'decision': decision,
      },);
      final matched = (result['data'] as Map?)?['matched'] == true;
      final conversationId = (result['data'] as Map?)?['conversationId']?.toString();
      if (!mounted) return;
      if (matched) {
        final targetId = target.id;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              name: target.name,
              conversationId: conversationId,
              otherUserId: targetId,
              apiClient: widget.apiClient,
              initialDraft: openChatWith,
            ),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _lastRemoved = target;
          _discoverProfiles = List.of(_discoverProfiles)..removeAt(_profileIndex % _discoverProfiles.length);
          if (_profileIndex >= _discoverProfiles.length && _profileIndex > 0) _profileIndex = 0;
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      final message = error.message ?? 'Beğeni kaydedilemedi';
      setState(() => _swipeError = message);
      if (message.contains('Complete your profile')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce profilini tamamla: en az 20 karakter hakkımda yazısı gerekli.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _swipeError = 'Beğeni kaydedilemedi');
    } finally {
      if (mounted) setState(() => _swipeBusy = false);
    }
  }
  Future<void> _undo() async {
    final removed = _lastRemoved;
    if (removed == null || _undoBusy) return;
    setState(() => _undoBusy = true);
    try {
      await widget.apiClient.delete('/v1/matches/swipes/last');
      if (!mounted) return;
      setState(() {
        _discoverProfiles = [removed, ..._discoverProfiles];
        _profileIndex = 0;
        _lastRemoved = null;
        _swipeError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Son kaydırma geri alındı.')));
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Geri alınamadı')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geri alınamadı')));
      }
    } finally {
      if (mounted) setState(() => _undoBusy = false);
    }
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.color, required this.onPressed});

  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: AppColors.burgundy.withValues(alpha: 0.25),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppInk.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.burgundy),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({
    required this.onClose,
    required this.distanceKm,
    required this.location,
    required this.ageRanges,
    required this.onDistanceChanged,
    required this.onLocationChanged,
    required this.onAgeToggled,
    required this.onApply,
    required this.busy,
  });

  final VoidCallback onClose;
  final double distanceKm;
  final LocationChoice location;
  final Set<String> ageRanges;
  final ValueChanged<double> onDistanceChanged;
  final ValueChanged<LocationChoice> onLocationChanged;
  final ValueChanged<String> onAgeToggled;
  final VoidCallback onApply;
  final bool busy;

  static const _options = <String>['18–25', '26–35', '36+'];

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late double _localDistance;

  @override
  void initState() {
    super.initState();
    _localDistance = widget.distanceKm;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppInk.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.burgundy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, size: 20, color: AppColors.burgundy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Keşfet tercihleri', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 2),
                      Text('Sana uygun kişileri bulalım', style: TextStyle(fontSize: 12, color: AppInk.subtle)),
                    ],
                  ),
                ),
                IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close), tooltip: 'Filtreleri kapat'),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionLabel(icon: Icons.social_distance, label: 'Mesafe'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _localDistance,
                    min: 1,
                    max: 100,
                    divisions: 20,
                    label: '${_localDistance.round()} km',
                    onChanged: (value) => setState(() => _localDistance = value),
                    onChangeEnd: widget.onDistanceChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_localDistance.round()} km',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: scheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _SectionLabel(icon: Icons.public, label: 'Konum'),
            const SizedBox(height: 8),
            LocationField(
              choice: widget.location,
              onChanged: widget.onLocationChanged,
            ),
            const SizedBox(height: 6),
            Text(
              'Konum seçmezsen tüm dünya listelenir.',
              style: TextStyle(fontSize: 12, color: AppInk.subtle),
            ),
            const SizedBox(height: 14),
            const _SectionLabel(icon: Icons.cake_outlined, label: 'Yaş aralığı'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final option in _FilterPanel._options)
                  FilterChip(
                    label: Text(option),
                    selected: widget.ageRanges.contains(option),
                    onSelected: (_) => widget.onAgeToggled(option),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: widget.busy ? 'Konum alınıyor…' : 'Tercihleri kaydet',
              onPressed: widget.busy ? null : widget.onApply,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppInk.subtle),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppInk.subtle),
        ),
      ],
    );
  }
}
