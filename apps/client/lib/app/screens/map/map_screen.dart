import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_client.dart';
import '../../services/location_service.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart' show ScreenHeader;

/// OpenStreetMap tabanli harita (Snap tarzi).
///
/// Yerel SDK yok: tile'lar dogrudan `tile.openstreetmap.org` adresinden alinir,
/// bu sayede tum platformlarda (web dahil) calisir. Uyelerin konumu sunucu
/// tarafinda ~2 km'ye yuvarlanarak gonderilir.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.apiClient});

  final ApiClientPort apiClient;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class MapMember {
  const MapMember({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.city,
    this.district,
    this.country,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? city;
  final String? district;
  final String? country;
  final double latitude;
  final double longitude;
  final double distanceKm;

  String get place => [district, city, country].where((part) => part != null && part.isNotEmpty).join(' / ');

  factory MapMember.fromJson(Map<String, dynamic> json) => MapMember(
        id: (json['id'] ?? '').toString(),
        displayName: (json['displayName'] ?? 'Bilinmeyen').toString(),
        avatarUrl: json['avatarUrl']?.toString(),
        city: json['city']?.toString(),
        district: json['district']?.toString(),
        country: json['country']?.toString(),
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      );
}

class MapEvent {
  const MapEvent({
    required this.id,
    required this.title,
    this.city,
    required this.startsAt,
    required this.attendeeCount,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  final String id;
  final String title;
  final String? city;
  final DateTime startsAt;
  final int attendeeCount;
  final double latitude;
  final double longitude;
  final double distanceKm;

  factory MapEvent.fromJson(Map<String, dynamic> json) => MapEvent(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? 'Etkinlik').toString(),
        city: json['city']?.toString(),
        startsAt: DateTime.tryParse((json['startsAt'] ?? '').toString())?.toLocal() ?? DateTime.now(),
        attendeeCount: (json['attendeeCount'] as num?)?.toInt() ?? 0,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      );
}

enum _PinKind { member, event }

class _Pin {
  const _Pin({
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.kind,
    this.id,
    this.avatarUrl,
    this.distanceKm = 0,
  });

  final double latitude;
  final double longitude;
  final String label;
  final _PinKind kind;
  final String? id;
  final String? avatarUrl;
  final double distanceKm;
}

const double _tileSize = 256.0;
const Color _tileBackground = Color(0xFFE8E4DE);

/// OSM kullanim sartlari gecerli bir istemci tanimi ister; aksi halde
/// kutular engellenebilir (ozellikle masaustunde yogun kullanimda).
const Map<String, String> _tileHeaders = {
  'User-Agent': 'CanMeydani/0.6.0 (contact: hi@canmeydani.com.tr)',
};

/// Web Mercator: coor -> dunya pikseli.
Offset _project(double lat, double lng, double zoom) {
  final worldSize = _tileSize * math.pow(2.0, zoom);
  final x = (lng + 180.0) / 360.0 * worldSize;
  final clamped = lat.clamp(-85.0, 85.0);
  final sinLat = math.sin(clamped * math.pi / 180.0);
  final y = (1.0 - math.log(sinLat + 1.0 / math.cos(clamped * math.pi / 180.0)) / math.pi) / 2.0 * worldSize;
  return Offset(x, y);
}

class _MapScreenState extends State<MapScreen> {
  double _centerLat = 39.9334;
  double _centerLng = 32.8597;
  double _zoom = 11;
  double _radiusKm = 50;
  List<_Pin> _pins = const [];
  bool _loading = true;
  String? _error;
  _Pin? _selected;
  Offset? _doubleTapPos;

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
    final position = await currentPosition();
    if (position != null && mounted) {
      setState(() {
        _centerLat = position.latitude;
        _centerLng = position.longitude;
      });
    }
    try {
      final result = await widget.apiClient.get(
        '/v1/map/nearby?lat=$_centerLat&lng=$_centerLng&radiusKm=${_radiusKm.round()}&limit=150',
      );
      final data = result['data'];
      final members = (data is Map ? data['members'] as List<dynamic>? : null) ?? const [];
      final events = (data is Map ? data['events'] as List<dynamic>? : null) ?? const [];
      final parsed = <_Pin>[
        for (final item in members)
          if (item is Map<String, dynamic>)
            () {
              final member = MapMember.fromJson(item);
              return _Pin(
                latitude: member.latitude,
                longitude: member.longitude,
                label: member.displayName,
                kind: _PinKind.member,
                id: member.id,
                avatarUrl: member.avatarUrl,
                distanceKm: member.distanceKm,
              );
            }(),
        for (final item in events)
          if (item is Map<String, dynamic>)
            () {
              final event = MapEvent.fromJson(item);
              return _Pin(
                latitude: event.latitude,
                longitude: event.longitude,
                label: event.title,
                kind: _PinKind.event,
                id: event.id,
                distanceKm: event.distanceKm,
              );
            }(),
      ];
      if (!mounted) return;
      setState(() {
        _pins = parsed;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message ?? 'Harita verisi alınamadı';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Harita verisi alınamadı';
        _loading = false;
      });
    }
  }

  void _setZoom(double value) {
    final next = value.clamp(3.0, 18.0);
    if (next == _zoom) return;
    setState(() => _zoom = next);
    _scheduleRadiusRefresh();
  }

  Timer? _radiusTimer;

  /// Kaydirma/tekerlek sirasinda art arda yukleme yapilmaz; durunca tek istek.
  void _scheduleRadiusRefresh() {
    _radiusTimer?.cancel();
    _radiusTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      // Görüş alanı genişledikçe arama yarıçapını otomatik büyüt.
      final spanKm = 320 / math.pow(2.0, _zoom - 8.0);
      final nextRadius = spanKm.clamp(5.0, 500.0);
      if ((nextRadius - _radiusKm).abs() >= 10) {
        setState(() => _radiusKm = nextRadius);
        _load();
      }
    });
  }

  /// Imlec/focus noktasini sabit tutup yaklasir (masaustu tekerlek + cift tik).
  void _zoomAt(Offset focalScreen, double delta, Size size) {
    final next = (_zoom + delta).clamp(3.0, 18.0);
    if (next == _zoom) return;
    final worldSize = _tileSize * math.pow(2.0, _zoom);
    final center = _project(_centerLat, _centerLng, _zoom);
    final focalWorld = Offset(
      center.dx + (focalScreen.dx - size.width / 2),
      center.dy + (focalScreen.dy - size.height / 2),
    );
    final lat = _unprojectY(focalWorld.dy, worldSize).clamp(-85.0, 85.0);
    var lng = focalWorld.dx / worldSize * 360.0 - 180.0;
    while (lng > 180) {
      lng -= 360;
    }
    while (lng < -180) {
      lng += 360;
    }
    final nextCenter = _project(lat, lng, next);
    final nextWorld = _tileSize * math.pow(2.0, next);
    var outLng = (nextCenter.dx - (focalScreen.dx - size.width / 2)) / nextWorld * 360.0 - 180.0;
    while (outLng > 180) {
      outLng -= 360;
    }
    while (outLng < -180) {
      outLng += 360;
    }
    setState(() {
      _zoom = next;
      _centerLat = _unprojectY(nextCenter.dy - (focalScreen.dy - size.height / 2), nextWorld).clamp(-85.0, 85.0);
      _centerLng = outLng;
    });
    _scheduleRadiusRefresh();
  }

  void _panBy(Offset delta, Size size) {
    final center = _project(_centerLat, _centerLng, _zoom);
    final next = center + delta;
    final worldSize = _tileSize * math.pow(2.0, _zoom);
    var lng = next.dx / worldSize * 360.0 - 180.0;
    var lat = _unprojectY(next.dy, worldSize);
    if (lng > 180) {
      lng -= 360;
    }
    if (lng < -180) {
      lng += 360;
    }
    setState(() {
      _centerLat = lat.clamp(-85.0, 85.0);
      _centerLng = lng;
    });
  }

  double _unprojectY(double y, double worldSize) {
    final n = math.pi - 2.0 * math.pi * y / worldSize;
    return 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  Future<void> _centerOnMe() async {
    final messenger = ScaffoldMessenger.of(context);
    final position = await currentPosition();
    if (position == null || !mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Konum alınamadı.')));
      return;
    }
    setState(() {
      _centerLat = position.latitude;
      _centerLng = position.longitude;
      _zoom = 13;
    });
    await _load();
  }

  @override
  void dispose() {
    _radiusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          title: 'Harita',
          subtitle: 'Yakınındaki üyeler ve etkinlikler · OpenStreetMap',
          action: IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Listener(
                        onPointerSignal: (signal) {
                          if (signal is PointerScrollEvent) {
                            final delta = signal.scrollDelta.dy > 0 ? -1.0 : 1.0;
                            _zoomAt(signal.localPosition, delta, size);
                          }
                        },
                        child: GestureDetector(
                          onPanUpdate: (details) => _panBy(details.delta, size),
                          onTapUp: (_) => setState(() => _selected = null),
                          onDoubleTapDown: (details) => _doubleTapPos = details.localPosition,
                          onDoubleTap: () {
                            final pos = _doubleTapPos;
                            if (pos != null) _zoomAt(pos, 1, size);
                          },
                          child: ClipRect(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _TileLayer(centerLat: _centerLat, centerLng: _centerLng, zoom: _zoom),
                                ),
                                ..._pinWidgets(size),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 88,
                      child: Column(
                        children: [
                          _MapButton(icon: Icons.add, label: 'Yakınlaştır', onTap: () => _setZoom(_zoom + 1)),
                          const SizedBox(height: 6),
                          _MapButton(icon: Icons.remove, label: 'Uzaklaştır', onTap: () => _setZoom(_zoom - 1)),
                          const SizedBox(height: 6),
                          _MapButton(icon: Icons.my_location, label: 'Konumum', onTap: _centerOnMe),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: _RadiusBar(
                        radiusKm: _radiusKm,
                        centerLat: _centerLat,
                        centerLng: _centerLng,
                        zoom: _zoom,
                        onChanged: (value) => setState(() => _radiusKm = value),
                        onChangeEnd: (value) {
                          setState(() => _radiusKm = value);
                          _load();
                        },
                      ),
                    ),
                    if (_loading)
                      const Positioned(
                        top: 10,
                        right: 10,
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    if (_error != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 60,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12))),
                              TextButton(onPressed: _load, child: const Text('Tekrar dene')),
                            ],
                          ),
                        ),
                      ),
                    if (_selected != null)
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 66,
                        child: _PinCard(pin: _selected!, onClose: () => setState(() => _selected = null)),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _pinWidgets(Size size) {
    final center = _project(_centerLat, _centerLng, _zoom);
    final offsetX = size.width / 2 - center.dx;
    final offsetY = size.height / 2 - center.dy;
    return [
      for (final pin in _pins)
        Builder(
          builder: (context) {
            final point = _project(pin.latitude, pin.longitude, _zoom);
            return Positioned(
              left: point.dx + offsetX - 17,
              top: point.dy + offsetY - 38,
              child: _PinMarker(pin: pin, onTap: () => setState(() => _selected = pin)),
            );
          },
        ),
    ];
  }
}

class _PinMarker extends StatelessWidget {
  const _PinMarker({required this.pin, required this.onTap});

  final _Pin pin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEvent = pin.kind == _PinKind.event;
    final resolved = Session.resolveAvatar(pin.avatarUrl);
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Semantics(
          button: true,
          label: '${isEvent ? 'Etkinlik' : 'Üye'}: ${pin.label}',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEvent && resolved != null)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: CircleAvatar(radius: 15, backgroundImage: NetworkImage(resolved)),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isEvent ? AppColors.burgundy : Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Icon(isEvent ? Icons.celebration : Icons.person, size: 16, color: Colors.white),
                ),
              Container(width: 2, height: 6, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

/// OSM tile katmani: gorunen kareleri X/Y tile adreslerine baglar.
class _TileLayer extends StatefulWidget {
  const _TileLayer({required this.centerLat, required this.centerLng, required this.zoom});

  final double centerLat;
  final double centerLng;
  final double zoom;

  @override
  State<_TileLayer> createState() => _TileLayerState();
}

class _TileLayerState extends State<_TileLayer> {
  final Map<String, Widget> _cache = {};
  int _cachedZoom = -1;

  void _tile(int x, int y, int z) {
    final key = '$z/$x/$y';
    if (_cache.containsKey(key)) return;
    _cache[key] = Image.network(
      'https://tile.openstreetmap.org/$z/$x/$y.png',
      headers: _tileHeaders,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const ColoredBox(color: _tileBackground),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const ColoredBox(color: _tileBackground),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final z = widget.zoom.floor().clamp(0, 18);
        if (z != _cachedZoom) {
          _cachedZoom = z;
          // Farkli yaklasimlilik seviyesindeki eski kutulari birak.
          _cache.removeWhere((key, _) => !key.startsWith('$z/'));
        }
        final scale = math.pow(2.0, widget.zoom - z);
        final count = math.pow(2.0, z).toInt();
        final center = _project(widget.centerLat, widget.centerLng, widget.zoom);
        final scaledCenter = Offset(center.dx * scale, center.dy * scale);
        final minX = ((scaledCenter.dx - width / 2) / (_tileSize * scale)).floor();
        final maxX = ((scaledCenter.dx + width / 2) / (_tileSize * scale)).ceil();
        final minY = ((scaledCenter.dy - height / 2) / (_tileSize * scale)).floor();
        final maxY = ((scaledCenter.dy + height / 2) / (_tileSize * scale)).ceil();

        final children = <Widget>[];
        for (var x = minX; x <= maxX; x++) {
          for (var y = minY; y <= maxY; y++) {
            if (y < 0 || y >= count) continue;
            final wrapped = ((x % count) + count) % count;
            _tile(wrapped, y, z);
            children.add(
              Positioned(
                left: (x * _tileSize - scaledCenter.dx) * scale + width / 2,
                top: (y * _tileSize - scaledCenter.dy) * scale + height / 2,
                width: _tileSize * scale,
                height: _tileSize * scale,
                child: _cache['$z/$wrapped/$y'] ?? const ColoredBox(color: _tileBackground),
              ),
            );
          }
        }
        return ColoredBox(color: _tileBackground, child: Stack(children: children));
      },
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20)),
        ),
      ),
    );
  }
}

class _RadiusBar extends StatelessWidget {
  const _RadiusBar({
    required this.radiusKm,
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double radiusKm;
  final double centerLat;
  final double centerLng;
  final double zoom;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.social_distance, size: 18),
            const SizedBox(width: 6),
            Text('${radiusKm.round()} km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            Expanded(
              child: Slider(
                min: 5,
                max: 500,
                divisions: 33,
                value: radiusKm.clamp(5, 500),
                label: '${radiusKm.round()} km',
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
            IconButton(
              tooltip: 'OpenStreetMap uygulamasında aç',
              onPressed: () {
                final lat = centerLat.toStringAsFixed(4);
                final lng = centerLng.toStringAsFixed(4);
                final zoom = this.zoom.round().clamp(3, 18);
                launchUrl(Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=$zoom/$lat/$lng'));
              },
              icon: const Icon(Icons.open_in_new, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  const _PinCard({required this.pin, required this.onClose});

  final _Pin pin;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isEvent = pin.kind == _PinKind.event;
    final resolved = Session.resolveAvatar(pin.avatarUrl);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (!isEvent && resolved != null)
              CircleAvatar(radius: 20, backgroundImage: NetworkImage(resolved))
            else
              CircleAvatar(radius: 20, child: Icon(isEvent ? Icons.celebration : Icons.person, size: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pin.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    isEvent ? 'Etkinlik · ${pin.distanceKm.round()} km' : 'Üye · ${pin.distanceKm.round()} km uzaklıkta',
                    style: TextStyle(fontSize: 12, color: AppInk.subtle),
                  ),
                ],
              ),
            ),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close), tooltip: 'Kapat'),
          ],
        ),
      ),
    );
  }
}
