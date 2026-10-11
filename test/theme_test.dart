import 'dart:math' as math;

import 'package:ble_rc_controller/main.dart' show registerFontLicense;
import 'package:ble_rc_controller/ui/theme/theme.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  double lin(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double lum(Color c) =>
      0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  final la = lum(a);
  final lb = lum(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('text colours meet 4.5:1 on the background', () {
    for (final c in [
      AppColors.text,
      AppColors.text2,
      AppColors.text3,
      AppColors.amber,
    ]) {
      expect(contrast(c, AppColors.bg), greaterThanOrEqualTo(4.5));
    }
  });

  test('the trace colour is below text contrast, so it can never be text', () {
    expect(contrast(AppColors.trace, AppColors.bg), lessThan(4.5));
  });

  test('numbers are condensed, light and tabular', () {
    final s = AppType.numeric(size: 42);
    expect(s.fontFamily, 'Saira');
    expect(s.fontSize, 42);
    expect(
      s.fontVariations,
      containsAll([
        const FontVariation('wdth', 75),
        const FontVariation('wght', 300),
      ]),
    );
    expect(s.fontWeight, FontWeight.w300);
    expect(s.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  test('body text is regular width and weight', () {
    final s = AppType.body(size: 14);
    expect(s.fontFamily, 'Saira');
    expect(s.fontSize, 14);
    expect(
      s.fontVariations,
      containsAll([
        const FontVariation('wdth', 100),
        const FontVariation('wght', 400),
      ]),
    );
    expect(s.fontWeight, FontWeight.w400);
    expect(
      AppType.body(size: 14, weight: FontWeight.w500).fontVariations,
      contains(const FontVariation('wght', 500)),
    );
  });

  test('layout kinds follow the breakpoints', () {
    expect(layoutFor(const Size(390, 844)), LayoutKind.phone);
    expect(layoutFor(const Size(320, 568)), LayoutKind.phone);
    expect(layoutFor(const Size(600, 960)), LayoutKind.tablet);
    expect(layoutFor(const Size(800, 360)), LayoutKind.landscape);
    expect(layoutFor(const Size(1180, 760)), LayoutKind.desktop);
  });

  test('layout kind edges', () {
    expect(layoutFor(const Size(599, 960)), LayoutKind.phone);
    expect(layoutFor(const Size(899, 960)), LayoutKind.tablet);
    expect(layoutFor(const Size(900, 960)), LayoutKind.desktop);
    // Landscape: wider than tall and under 500 high.
    expect(layoutFor(const Size(600, 499)), LayoutKind.landscape);
    expect(layoutFor(const Size(600, 500)), LayoutKind.tablet);
    expect(layoutFor(const Size(500, 499)), LayoutKind.landscape);
    // Not wider than tall: a short portrait or a square stays a phone.
    expect(layoutFor(const Size(499, 499)), LayoutKind.phone);
    expect(layoutFor(const Size(320, 480)), LayoutKind.phone);
  });

  test('a phone turned sideways is landscape, whatever its width', () {
    // The ruling of spec 6: "landscape with a height under 500" comes first.
    // A big phone is 915 wide, a small one 568; neither is a desktop window
    // or a portrait phone.
    expect(layoutFor(const Size(915, 412)), LayoutKind.landscape);
    expect(layoutFor(const Size(844, 390)), LayoutKind.landscape);
    expect(layoutFor(const Size(568, 320)), LayoutKind.landscape);
    expect(layoutFor(const Size(599, 360)), LayoutKind.landscape);
    expect(layoutFor(const Size(800, 360)), LayoutKind.landscape);
    expect(layoutFor(const Size(1200, 400)), LayoutKind.landscape);
  });

  test('a tall or large window is not landscape', () {
    expect(layoutFor(const Size(1280, 800)), LayoutKind.desktop);
    expect(layoutFor(const Size(800, 1280)), LayoutKind.tablet);
    expect(layoutFor(const Size(412, 915)), LayoutKind.phone);
    expect(layoutFor(const Size(1180, 760)), LayoutKind.desktop);
    expect(layoutFor(const Size(900, 500)), LayoutKind.desktop);
  });

  test('desktop platforms are macOS, Windows and Linux', () {
    expect(isDesktopPlatform, isFalse, reason: 'flutter_test says Android');
    for (final (platform, desktop) in [
      (TargetPlatform.macOS, true),
      (TargetPlatform.windows, true),
      (TargetPlatform.linux, true),
      (TargetPlatform.android, false),
      (TargetPlatform.iOS, false),
      (TargetPlatform.fuchsia, false),
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      try {
        expect(isDesktopPlatform, desktop, reason: platform.name);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }
  });

  test('theme is dark with the amber accent', () {
    final t = buildAppTheme();
    expect(t.brightness, Brightness.dark);
    expect(t.scaffoldBackgroundColor, AppColors.bg);
    expect(t.colorScheme.primary, AppColors.amber);
    expect(t.colorScheme.surface, AppColors.bg);
    expect(t.useMaterial3, isTrue);
  });

  test('text theme uses the spec sizes in Saira', () {
    final t = buildAppTheme().textTheme;
    expect(t.headlineMedium!.fontSize, 28); // screen title
    expect(
      t.headlineMedium!.fontVariations,
      contains(const FontVariation('wdth', 75)),
    );
    expect(t.bodyMedium!.fontSize, 13.5); // row text
    expect(
      t.bodyMedium!.fontVariations,
      contains(const FontVariation('wdth', 100)),
    );
    expect(t.bodyMedium!.color, AppColors.text);
    for (final s in [t.displayLarge, t.titleMedium, t.labelSmall]) {
      expect(s!.fontFamily, 'Saira');
    }
  });

  test('the Saira licence is registered and its asset is bundled', () async {
    registerFontLicense();
    final entries = await LicenseRegistry.licenses
        .where((e) => e.packages.contains('saira'))
        .toList();
    expect(entries, hasLength(1));
    final text = entries.single.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('SIL OPEN FONT LICENSE Version 1.1'));
  });
}
