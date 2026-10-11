import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Colours of the single dark theme (spec 3.1).
///
/// Amber means "active state, main action or attention" and nothing else.
abstract final class AppColors {
  /// Base of every screen.
  static const Color bg = Color(0xFF0A0C0F);

  /// Main text.
  static const Color text = Color(0xFFECEEF1);

  /// Secondary text (7.5:1 on [bg]).
  static const Color text2 = Color(0xFF99A0AB);

  /// Small labels and hints (5.2:1 on [bg]).
  static const Color text3 = Color(0xFF7D8591);

  /// Marks, scales and outlines. Below text contrast: never use it for text.
  static const Color trace = Color(0xFF5E6570);

  /// Minor scale marks.
  static const Color traceWeak = Color(0xFF363C45);

  /// Active state, main action, attention.
  static const Color amber = Color(0xFFFFB547);

  /// Only in the gradient of the turbo halo.
  static const Color amberHot = Color(0xFFFF8A2A);

  /// Headlight beam and lit dust.
  static const Color headlight = Color(0xFFFFEBC8);

  /// Fill of cells, lists and buttons: white at 4%.
  static const Color glass = Color.fromRGBO(255, 255, 255, 0.04);

  /// Outline of the glass surfaces: white at 8%.
  static const Color glassEdge = Color.fromRGBO(255, 255, 255, 0.08);

  /// Line of the car decal.
  static const Color decal = Color(0xFFC9CFD8);

  /// Dim outline drawn behind the car decal while it is being drawn.
  static const Color ghost = Color(0xFF4A515B);
}

/// Text styles. Both use the variable Saira font (spec 3.2), never upper case.
abstract final class AppType {
  static const String family = 'Saira';

  /// Numbers and names (car name, battery, degrees, screen titles): condensed
  /// (`wdth` 75), light (`wght` 300) and with fixed-width digits.
  static TextStyle numeric({required double size}) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.w300,
    fontVariations: const [
      FontVariation('wdth', 75),
      FontVariation('wght', 300),
    ],
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Running text and labels: regular width (`wdth` 100), `wght` 400 by default.
  static TextStyle body({
    required double size,
    FontWeight weight = FontWeight.w400,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [
      const FontVariation('wdth', 100),
      FontVariation('wght', weight.value.toDouble()),
    ],
  );
}

/// Durations of the motion language (spec 3.4).
abstract final class AppMotion {
  /// State changes: amber lighting up, text swapping.
  static const Duration state = Duration(milliseconds: 220);

  /// Steering gauge needle.
  static const Duration needle = Duration(milliseconds: 350);

  /// 360 degree spin of the car.
  static const Duration spin = Duration(milliseconds: 550);

  /// The car decal completing its stroke while connecting.
  static const Duration draw = Duration(milliseconds: 1600);

  /// Interval of the glass reflection sweep.
  static const Duration sweepEvery = Duration(seconds: 9);
}

/// Width and height limits between layouts (spec 6).
abstract final class Breakpoints {
  /// From this width on the screen is a tablet.
  static const double tablet = 600;

  /// From this width on the screen is a desktop window.
  static const double desktop = 900;

  /// Below this height a screen that is wider than it is tall is landscape.
  static const double landscapeMaxHeight = 500;
}

enum LayoutKind { phone, tablet, landscape, desktop }

/// Which layout a screen of size [s] gets.
///
/// A screen wider than it is tall and under [Breakpoints.landscapeMaxHeight]
/// high is landscape, whatever its width: a big phone turned sideways is 915
/// wide and a small one 568, and both need the two columns, not the desktop's
/// column of cars or the portrait stack. Anything else goes by width: desktop
/// from 900, tablet from 600, phone below.
LayoutKind layoutFor(Size s) {
  if (s.height < Breakpoints.landscapeMaxHeight && s.width > s.height) {
    return LayoutKind.landscape;
  }
  if (s.width >= Breakpoints.desktop) return LayoutKind.desktop;
  if (s.width >= Breakpoints.tablet) return LayoutKind.tablet;
  return LayoutKind.phone;
}

/// Whether the app runs on a computer (macOS, Windows or Linux), with a mouse
/// and a keyboard, as opposed to a phone or a tablet.
///
/// It is the platform that says so, not the size of the window: an Android
/// tablet turned sideways is 1280 wide and has the desktop layout, but is
/// still touched, so it gets no legend of keys and "Tap", not "Click".
bool get isDesktopPlatform => switch (defaultTargetPlatform) {
  TargetPlatform.macOS ||
  TargetPlatform.windows ||
  TargetPlatform.linux => true,
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.fuchsia => false,
};
