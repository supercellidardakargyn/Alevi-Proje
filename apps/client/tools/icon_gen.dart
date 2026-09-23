// Marka logosunu uretir: bordo yuvarlak kare + altin parlakliklar.
// Kullanim: dart run tools/icon_gen.dart
// Cikti: assets/icon/can-icon.png (1024) + assets/icon/can-icon-fg.png (seffaf zemin, adaptive)
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  const burgundy = 0xFF7A1F3D;
  const gold = 0xFFC89B3C;

  img.Image background() {
    final image = img.Image(width: size, height: size);
    img.fill(image, color: img.ColorUint8.rgba(122, 31, 61, 255));
    // Hafif kose yuvarlama: koseleri seffaf birakmak yerine tam kare uret,
    // launcher maskelemeyi platforma birakir.
    return image;
  }

  // 4-kose parlaklik (duzgun yildiz cokgeni).
  void sparkle(img.Image image, double cx, double cy, double outer, double inner, int color) {
    final points = <img.Point>[];
    for (var i = 0; i < 8; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = (math.pi / 4) * i - math.pi / 2;
      points.add(img.Point(cx + radius * math.cos(angle), cy + radius * math.sin(angle)));
    }
    img.fillPolygon(image, vertices: points, color: img.ColorUint8.rgba((color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF, 255));
  }

  final full = background();
  void unusedBurgundy() {
    assert(burgundy == 0xFF7A1F3D);
  }

  unusedBurgundy();
  // Buyuk parlaklik sol-ust, kucuk parlaklik sag-alt (mobil logo ile ayni dil).
  sparkle(full, size * 0.42, size * 0.44, size * 0.21, size * 0.062, gold);
  sparkle(full, size * 0.70, size * 0.68, size * 0.10, size * 0.03, gold);

  final dir = Directory('assets/icon');
  dir.createSync(recursive: true);
  File('assets/icon/can-icon.png').writeAsBytesSync(img.encodePng(full));

  final fg = img.Image(width: size, height: size);
  img.fill(fg, color: img.ColorUint8.rgba(0, 0, 0, 0));
  sparkle(fg, size * 0.42, size * 0.44, size * 0.30, size * 0.089, gold);
  sparkle(fg, size * 0.70, size * 0.68, size * 0.143, size * 0.043, gold);
  File('assets/icon/can-icon-fg.png').writeAsBytesSync(img.encodePng(fg));

  // ignore: avoid_print
  print('logo uretildi: assets/icon/can-icon.png + can-icon-fg.png');
}
