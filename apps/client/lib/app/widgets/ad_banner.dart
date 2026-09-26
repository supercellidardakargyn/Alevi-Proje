import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';

/// Ekranlarin altinda gosterilen AdMob banner. Web/masaustu veya reklam
/// kapaliyse hicbir sey cizmez (yer kaplamaz).
class AdBanner extends StatefulWidget {
  const AdBanner({super.key, required this.ads, this.margin = const EdgeInsets.fromLTRB(0, 8, 0, 0)});

  final AdsService ads;
  final EdgeInsets margin;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  @override
  void initState() {
    super.initState();
    widget.ads.addListener(_onChanged);
    _load();
  }

  @override
  void dispose() {
    widget.ads.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if (!widget.ads.enabled) return;
    await widget.ads.loadBanner(size: AdSize.banner);
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ads.banner;
    if (!widget.ads.enabled || ad == null) return const SizedBox.shrink();
    return Padding(
      padding: widget.margin,
      child: Center(
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
