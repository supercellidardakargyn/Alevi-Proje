import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Dunya ulkeleri (Turkce adlariyla), dunya sehirleri ve Turkiye il/ilce
/// veri seti. Tek pakette gelir: `assets/data/locations.json`
/// (uretici: `tools/locations/build_locations.py`, kaynak GeoNames).
class Country {
  const Country({
    required this.code,
    required this.name,
    required this.englishName,
    this.latitude,
    this.longitude,
    this.capital,
    this.region = '',
  });

  final String code;
  final String name;
  final String englishName;
  final double? latitude;
  final double? longitude;
  final String? capital;
  final String region;

  factory Country.fromRow(List<dynamic> row) {
    return Country(
      code: (row[0] ?? '').toString(),
      name: (row[1] ?? '').toString(),
      englishName: (row[2] ?? '').toString(),
      latitude: (row[3] as num?)?.toDouble(),
      longitude: (row[4] as num?)?.toDouble(),
      capital: row.length > 5 && (row[5] ?? '').toString().isNotEmpty ? row[5].toString() : null,
      region: row.length > 6 ? (row[6] ?? '').toString() : '',
    );
  }
}

class City {
  const City({required this.name, this.latitude, this.longitude});

  final String name;
  final double? latitude;
  final double? longitude;

  factory City.fromRow(List<dynamic> row) {
    return City(
      name: (row[0] ?? '').toString(),
      latitude: (row[1] as num?)?.toDouble(),
      longitude: (row[2] as num?)?.toDouble(),
    );
  }
}

class Province {
  const Province({required this.code, required this.name, required this.districts});

  final String code;
  final String name;
  final List<String> districts;

  factory Province.fromRow(List<dynamic> row) {
    return Province(
      code: (row[0] ?? '').toString(),
      name: (row[1] ?? '').toString(),
      districts: ((row[2] as List?) ?? const []).map((d) => d.toString()).toList(),
    );
  }
}

/// Kullanicinin sectigi konum: ulke / sehir / ilce.
class LocationChoice {
  const LocationChoice({this.country, this.countryCode, this.city, this.district});

  final String? country;
  final String? countryCode;
  final String? city;
  final String? district;

  bool get isEmpty => (country == null || country!.isEmpty) && (city == null || city!.isEmpty);

  String get summary {
    final parts = <String>[
      if (country != null && country!.isNotEmpty) country!,
      if (city != null && city!.isNotEmpty) city!,
      if (district != null && district!.isNotEmpty) district!,
    ];
    return parts.join(' / ');
  }

  Map<String, dynamic> toJson() => {
        if (country != null && country!.isNotEmpty) 'country': country,
        if (countryCode != null && countryCode!.isNotEmpty) 'countryCode': countryCode,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (district != null && district!.isNotEmpty) 'district': district,
      };

  @override
  String toString() => summary;
}

/// Paketlenmis konum veri setini bellekte tutar (tek seferlik yukleme).
class LocationData {
  LocationData._({
    required this.countries,
    required this.citiesByCountry,
    required this.provinces,
  });

  final List<Country> countries;
  final Map<String, List<City>> citiesByCountry;
  final List<Province> provinces;

  static const String turkeyCode = 'TR';
  static LocationData? _cache;
  static Future<LocationData>? _pending;

  static Future<LocationData> load() {
    if (_cache != null) return Future.value(_cache);
    return _pending ??= _read().then((data) {
      _cache = data;
      _pending = null;
      return data;
    }, onError: (Object error) {
      _pending = null;
      throw error;
    },);
  }

  static Future<LocationData> _read() async {
    final raw = await rootBundle.loadString('assets/data/locations.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final countries = ((json['countries'] as List?) ?? const [])
        .map((row) => Country.fromRow(row as List<dynamic>))
        .toList(growable: false);
    final cities = <String, List<City>>{};
    ((json['cities'] as Map<String, dynamic>?) ?? const {}).forEach((code, rows) {
      cities[code] = (rows as List)
          .map((row) => City.fromRow(row as List<dynamic>))
          .toList(growable: false);
    });
    final provinces = ((json['trProvinces'] as List?) ?? const [])
        .map((row) => Province.fromRow(row as List<dynamic>))
        .toList(growable: false);
    return LocationData._(countries: countries, citiesByCountry: cities, provinces: provinces);
  }

  Country? countryByCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final country in countries) {
      if (country.code == code) return country;
    }
    return null;
  }

  List<City> citiesOf(String? countryCode) {
    if (countryCode == null) return const [];
    return citiesByCountry[countryCode] ?? const [];
  }

  List<Country> get turkeyCountry => countryByCode(turkeyCode)?.let((c) => [c]) ?? const [];

  /// Turkce alfabeteye gore Turkce karsilastirma (buyuk/kucuk harf duyarsiz).
  static int compareTr(String a, String b) {
    final left = _foldTr(a);
    final right = _foldTr(b);
    return left.compareTo(right);
  }

  static String _foldTr(String value) {
    const map = <String, String>{
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'â': 'a',
      'î': 'i',
      'û': 'u',
    };
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(map[char] ?? char);
    }
    return buffer.toString();
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
