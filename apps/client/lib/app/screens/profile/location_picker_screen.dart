import 'package:flutter/material.dart';

import '../../services/location_data.dart';
import '../../theme/app_theme.dart';

/// Ulke -> sehir -> Turkiye il/ilce secimi. Kademeli liste, aramali.
/// Donus: secilen [LocationChoice] (degistirilmediyse onceki deger).
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial});

  final LocationChoice? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

enum _Step { country, city, district }

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LocationData? _data;
  String _query = '';
  _Step _step = _Step.country;
  String? _countryCode;
  String? _countryName;
  String? _city;
  String? _provinceCode;
  String? _provinceName;
  String? _district;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _countryName = initial.country;
      _city = initial.city;
      _district = initial.district;
    }
    LocationData.load().then((data) {
      if (!mounted) return;
      setState(() {
        _data = data;
        _countryCode = data.countryByCode(initial?.countryCode)?.code;
        if (_countryCode == null && initial?.country != null) {
          _countryCode = _matchCountry(data, initial!.country!);
        }
      });
    }).catchError((Object error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum listesi yüklenemedi.')));
      }
    });
  }

  String? _matchCountry(LocationData data, String name) {
    for (final country in data.countries) {
      if (country.name.toLowerCase() == name.toLowerCase() || country.englishName.toLowerCase() == name.toLowerCase()) {
        return country.code;
      }
    }
    return null;
  }

  void _resetFrom(String step) {
    setState(() {
      _query = '';
      if (step == 'country') {
        _countryCode = null;
        _countryName = null;
        _city = null;
      }
      if (step == 'city') {
        _city = null;
      }
      if (step == 'district') {
        _provinceCode = null;
        _provinceName = null;
        _district = null;
      }
    });
  }

  Future<void> _pickCountry(Country country) async {
    setState(() {
      _countryCode = country.code;
      _countryName = country.name;
      _city = null;
      _provinceCode = null;
      _provinceName = null;
      _district = null;
      _query = '';
    });
    if (country.code == LocationData.turkeyCode) {
      setState(() => _step = _Step.district);
    } else {
      setState(() => _step = _Step.city);
    }
  }

  Future<void> _pickCity(String name) async {
    setState(() {
      _city = name;
      _district = null;
      _query = '';
    });
  }

  Future<void> _pickProvince(Province province) async {
    setState(() {
      _provinceCode = province.code;
      _provinceName = province.name;
      _city = province.name;
      _district = null;
      _query = '';
      _step = _Step.district;
    });
  }

  void _confirm() {
    Navigator.of(context).pop(
      LocationChoice(
        country: _countryName,
        countryCode: _countryCode,
        city: _city,
        district: _district,
      ),
    );
  }

  List<String> _crumbs() => [
        if (_countryName != null) _countryName!,
        if (_provinceName != null) _provinceName!,
        if (_city != null && _provinceName == null) _city!,
        if (_district != null) _district!,
      ];

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum seç'),
        actions: [
          if (_countryName != null || _city != null || _district != null)
            TextButton(onPressed: _confirm, child: const Text('Bitir')),
        ],
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _Crumbs(
                    crumbs: _crumbs(),
                    onTap: (index) {
                      if (index <= 0) _resetFrom('country');
                      if (index == 1 && _provinceName == null) _resetFrom('city');
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      autofocus: false,
                      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                        hintText: switch (_step) {
                          _Step.country => 'Ülke ara',
                          _Step.city => 'Şehir ara',
                          _Step.district => 'İlçe ara',
                        },
                      ),
                    ),
                  ),
                  Expanded(child: _buildList(data)),
                ],
              ),
            ),
    );
  }

  Widget _buildList(LocationData data) {
    final query = _query;
    switch (_step) {
      case _Step.country:
        return _countryList(data, query);
      case _Step.city:
        return _cityList(data, query);
      case _Step.district:
        return _provinceCode == null ? _provinceList(data, query) : _districtList(data, query);
    }
  }

  Widget _countryList(LocationData data, String query) {
    final rows = data.countries
        .where((c) => query.isEmpty || c.name.toLowerCase().contains(query) || c.englishName.toLowerCase().contains(query) || c.code.toLowerCase() == query)
        .toList()
      ..sort((a, b) => LocationData.compareTr(a.name, b.name));
    if (rows.isEmpty) return const _Empty();
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final country = rows[index];
        return ListTile(
          leading: CircleAvatar(child: Text(country.code.substring(0, 2), style: const TextStyle(fontSize: 11))),
          title: Text(country.name),
          subtitle: country.capital == null
              ? null
              : Text('Başkent: ${country.capital}', style: TextStyle(color: AppInk.subtle)),
          trailing: country.code == _countryCode ? const Icon(Icons.check) : null,
          onTap: () => _pickCountry(country),
        );
      },
    );
  }

  Widget _cityList(LocationData data, String query) {
    final cities = data.citiesOf(_countryCode).where((c) => query.isEmpty || c.name.toLowerCase().contains(query)).toList()
      ..sort((a, b) => LocationData.compareTr(a.name, b.name));
    if (cities.isEmpty) return const _Empty();
    return ListView.builder(
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];
        return ListTile(
          leading: const Icon(Icons.location_city),
          title: Text(city.name),
          subtitle: Text(_countryName ?? '', style: TextStyle(color: AppInk.subtle)),
          trailing: city.name == _city ? const Icon(Icons.check) : null,
          onTap: () {
            _pickCity(city.name);
            _confirm();
          },
        );
      },
    );
  }

  Widget _provinceList(LocationData data, String query) {
    final rows = data.provinces.where((p) => query.isEmpty || p.name.toLowerCase().contains(query)).toList()
      ..sort((a, b) => LocationData.compareTr(a.name, b.name));
    if (rows.isEmpty) return const _Empty();
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final province = rows[index];
        return ListTile(
          leading: const Icon(Icons.map_outlined),
          title: Text(province.name),
          subtitle: Text('${province.districts.length} ilçe', style: TextStyle(color: AppInk.subtle)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pickProvince(province),
        );
      },
    );
  }

  Widget _districtList(LocationData data, String query) {
    final province = data.provinces.where((p) => p.code == _provinceCode).toList();
    final districts = province.isEmpty ? <String>[] : province.first.districts;
    final rows = districts.where((d) => query.isEmpty || d.toLowerCase().contains(query)).toList();
    if (rows.isEmpty) return const _Empty();
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final district = rows[index];
        return ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(district),
          subtitle: Text('$_provinceName / $_countryName', style: TextStyle(color: AppInk.subtle)),
          trailing: district == _district ? const Icon(Icons.check) : null,
          onTap: () {
            setState(() => _district = district);
            _confirm();
          },
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Sonuç bulunamadı.', style: TextStyle(color: AppInk.subtle)),
        ),
      );
}

class _Crumbs extends StatelessWidget {
  const _Crumbs({required this.crumbs, required this.onTap});

  final List<String> crumbs;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    if (crumbs.isEmpty) return const SizedBox(height: 4);
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: crumbs.length,
        itemBuilder: (context, index) {
          final last = index == crumbs.length - 1;
          return Row(
            children: [
              if (index > 0) Icon(Icons.chevron_right, size: 16, color: AppInk.subtle),
              InkWell(
                onTap: () => onTap(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    crumbs[index],
                    style: TextStyle(
                      color: last ? AppInk.text : AppInk.subtle,
                      fontWeight: last ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
