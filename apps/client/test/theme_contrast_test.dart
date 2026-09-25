import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alevi_client/app/theme/app_theme.dart';

double _luminance(Color color) {
  double channel(double value) {
    final c = value / 255.0;
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r * 255) +
      0.7152 * channel(color.g * 255) +
      0.0722 * channel(color.b * 255);
}

double _contrast(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  final bright = l1 > l2 ? l1 : l2;
  final dark = l1 > l2 ? l2 : l1;
  return (bright + 0.05) / (dark + 0.05);
}

void main() {
  test('gece temasinda kart uzerindeki yazilar okunur (kontrast >= 4.5)', () {
    AppInk.apply(AppThemeId.gece);
    const card = Color(0xFF2B2530);
    expect(_contrast(AppInk.text, card), greaterThanOrEqualTo(4.5));
    expect(_contrast(AppInk.subtle, card), greaterThanOrEqualTo(4.5));
    AppInk.apply(AppThemeId.bordo);
  });

  test('acik temalarda kart uzerindeki yazilar okunur (kontrast >= 4.5)', () {
    for (final id in [AppThemeId.bordo, AppThemeId.okyanus, AppThemeId.orman]) {
      AppInk.apply(id);
      expect(_contrast(AppInk.text, Colors.white), greaterThanOrEqualTo(4.5), reason: '$id text');
      expect(_contrast(AppInk.subtle, Colors.white), greaterThanOrEqualTo(4.5), reason: '$id subtle');
    }
    AppInk.apply(AppThemeId.bordo);
  });

  test('birincil dugme yazisi okunur', () {
    AppInk.apply(AppThemeId.gece);
    expect(_contrast(Colors.white, AppColors.burgundy), greaterThanOrEqualTo(4.5));
    AppInk.apply(AppThemeId.bordo);
  });
}
