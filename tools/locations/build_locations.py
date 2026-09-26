#!/usr/bin/env python3
"""Konum veri setini uretir: ulkeler (TR adlariyla), dunya sehirleri, TR il/ilce.

Kaynaklar (gecici indirilir, repoya girmez):
  - countries.json : mledoze/countries (Turkish country names)
  - cities5000.txt  : GeoNames
  - admin1CodesASCII.txt / admin2Codes.txt : GeoNames (TR iller/ilceler)

Cikti: apps/client/assets/data/locations.json

Kullanim:
  python tools/locations/build_locations.py <geos klasoru> <cikti.json>
"""
import json
import os
import sys
from collections import defaultdict

# Bos tutuldu: ilce adlari DISTRICT_OVERRIDES ile duzeltilir.
TR_DISTRICT_FIX = {}

# Bolge -> uygun Turkce etiket (filtre degil, sadece bilgi amacli; kullanilmiyor).
REGION_TR = {
    "Europe": "Avrupa",
    "Asia": "Asya",
    "Africa": "Afrika",
    "Americas": "Amerika",
    "Oceania": "Okyanusya",
    "Antarctic": "Antarktika",
}

# Geonames ilce adlarini Turkce yazar; uctan uca Turkcelestirme gerekiyor.
DISTRICT_OVERRIDES = {
    "Usak": "Uşak",
    "Mus": "Muş",
    "Mugla": "Muğla",
    "Kutahya": "Kütahya",
    "Canakkale": "Çanakkale",
    "Corum": "Çorum",
    "Nigde": "Niğde",
    "Nevsehir": "Nevşehir",
    "Kirsehir": "Kırşehir",
    "Sirnak": "Şırnak",
    "Karabuk": "Karabük",
    "Bartin": "Bartın",
    "Sinop": "Sinop",
    "Kilis": "Kilis",
    "Osmaniye": "Osmaniye",
    "Duzce": "Düzce",
    "Balikesir": "Balıkesir",
    "Manisa": "Manisa",
    "Aydin": "Aydın",
    "Antalya": "Antalya",
    "Isparta": "Isparta",
    "Bursa": "Bursa",
    "Yalova": "Yalova",
    "Adapazari": "Adapazarı",
    "Merkez": "Merkez",
}

# GeoNames il adlarinda " Province" ekini kullanir ve bazi illeri ASCII yazar.
PROVINCE_OVERRIDES = {
    "Istanbul": "İstanbul",
}


def turkish_province(local_name: str) -> str:
    name = local_name.replace(" Province", "").replace(" province", "").strip()
    return PROVINCE_OVERRIDES.get(name, name)


def turkish_district(local_name: str) -> str:
    """`Karkamiş Ilçesi` gibi geonames adini sade ilce adina cevirir."""
    name = local_name.replace("İlçesi", " ").replace("Ilçesi", " ").replace("ilçesi", " ")
    name = " ".join(part for part in name.split() if part)
    name = name.replace("Ilce ", "").replace("ilce ", "")
    return DISTRICT_OVERRIDES.get(name, name)


def load_countries(path):
    raw = json.load(open(path, encoding="utf-8"))
    out = []
    for item in raw:
        code = item.get("cca2")
        if not code:
            continue
        name = item.get("name", {})
        tr = name.get("tur") or item.get("translations", {}).get("tur", {}).get("common")
        latlng = item.get("latlng") or [None, None]
        region = item.get("region") or ""
        out.append(
            {
                "code": code,
                "name": name.get("common") or code,
                "tr": tr or name.get("common") or code,
                "lat": latlng[0],
                "lng": latlng[1],
                "capital": (item.get("capital") or [None])[0],
                "region": REGION_TR.get(region, region),
            }
        )
    out.sort(key=lambda c: c["tr"])
    return out


def load_cities(path, allowed_codes):
    """Ulke basina sehirleri toplar (nufus >= 50k ya da ulkenin en iyi 30'u)."""
    by_country = defaultdict(list)
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 15:
                continue
            code = parts[8]
            if code not in allowed_codes:
                continue
            name = parts[1]
            if parts[0] in ("001", "PPR"):  # Prefers kodlari harici kalsin
                continue
            try:
                lat = round(float(parts[4]), 4)
                lng = round(float(parts[5]), 4)
                pop = int(parts[14] or 0)
            except ValueError:
                continue
            by_country[code].append((pop, name, lat, lng))
    result = {}
    for code, rows in by_country.items():
        rows.sort(key=lambda r: (-r[0], r[1]))
        keep = []
        seen = set()
        for pop, name, lat, lng in rows:
            if name in seen:
                continue
            seen.add(name)
            keep.append([name, lat, lng])
            if len(keep) >= 30:
                break
        extra = [row for row in rows if row[0] >= 50000 and row[1] not in seen]
        for pop, name, lat, lng in extra:
            if len(keep) >= 120:
                break
            if name in seen:
                continue
            seen.add(name)
            keep.append([name, lat, lng])
        keep.sort(key=lambda r: r[0])
        result[code] = keep
    return result


def load_turkey(admin1_path, admin2_path):
    province_names = {}
    with open(admin1_path, encoding="utf-8") as handle:
        for line in handle:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 2 or not parts[0].startswith("TR."):
                continue
            code = parts[0].split(".")[1]
            province_names[code] = turkish_province(parts[1])
    districts = defaultdict(set)
    with open(admin2_path, encoding="utf-8") as handle:
        for line in handle:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 2 or not parts[0].startswith("TR."):
                continue
            code = parts[0].split(".")[1]
            if code not in province_names:
                continue
            districts[code].add(turkish_district(parts[1]))
    out = []
    for code, name in province_names.items():
        rows = sorted(districts.get(code, set()), key=lambda n: n.lower())
        if not rows:
            rows = ["Merkez"]
        out.append({"code": code, "name": name, "districts": rows})
    out.sort(key=lambda p: p["name"])
    return out


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    geo_dir, out_path = sys.argv[1], sys.argv[2]
    countries = load_countries(os.path.join(geo_dir, "mledoze.json"))
    codes = {c["code"] for c in countries}
    cities = load_cities(os.path.join(geo_dir, "cities5000.txt"), codes)
    turkey = load_turkey(
        os.path.join(geo_dir, "admin1CodesASCII.txt"),
        os.path.join(geo_dir, "admin2Codes.txt"),
    )
    payload = {
        "version": 1,
        "source": "GeoNames + mledoze/countries (derleme zamaninda indirilir)",
        "countries": [
            [c["code"], c["tr"], c["name"], c["lat"], c["lng"], c["capital"], c["region"]]
            for c in countries
        ],
        "cities": cities,
        "trProvinces": [[p["code"], p["name"], p["districts"]] for p in turkey],
    }
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, separators=(",", ":"))
    print(
        "ulkeler: {} sehir: {} il: {} ilce: {} -> {} ({} KB)".format(
            len(countries),
            sum(len(v) for v in cities.values()),
            len(turkey),
            sum(len(p["districts"]) for p in turkey),
            out_path,
            os.path.getsize(out_path) // 1024,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
