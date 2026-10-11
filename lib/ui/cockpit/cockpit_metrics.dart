import 'package:flutter/painting.dart';

import '../theme/tokens.dart';

/// What is different in each layout of the cockpit (spec 6): the space at the
/// sides, how far the content may grow. The connected cockpit and the screens
/// of the other states read the same numbers, so their edges line up.
class CockpitMetrics {
  const CockpitMetrics({
    required this.header,
    required this.body,
    required this.minimum,
    this.maxInstrument = double.infinity,
    this.maxPads = double.infinity,
  });

  /// Space at the sides of the header, and of the cells and arrows.
  final EdgeInsets header;
  final EdgeInsets body;

  /// Least space kept at the top and bottom of the window, where the system
  /// bars do not already leave it.
  final EdgeInsets minimum;

  /// Largest side of the instrument, and widest the row of arrows gets.
  final double maxInstrument;
  final double maxPads;

  static const _phone = CockpitMetrics(
    header: EdgeInsets.symmetric(horizontal: 24),
    body: EdgeInsets.symmetric(horizontal: 18),
    minimum: EdgeInsets.only(top: 24, bottom: 20),
  );

  static const _tablet = CockpitMetrics(
    header: EdgeInsets.symmetric(horizontal: 32),
    body: EdgeInsets.symmetric(horizontal: 32),
    minimum: EdgeInsets.only(top: 24, bottom: 20),
    // A portrait tablet has height to spare: the instrument takes most of
    // the width (on the Lenovo at 800 wide, 640 of the 736 available).
    maxInstrument: 640,
    maxPads: 480,
  );

  static const _landscape = CockpitMetrics(
    header: EdgeInsets.symmetric(horizontal: 24),
    body: EdgeInsets.symmetric(horizontal: 24),
    minimum: EdgeInsets.only(top: 24, bottom: 20),
  );

  // The approved desktop design: 36 on the left, 28 on the right.
  static const _desktop = CockpitMetrics(
    header: EdgeInsets.fromLTRB(36, 0, 28, 0),
    body: EdgeInsets.fromLTRB(36, 0, 28, 0),
    minimum: EdgeInsets.only(top: 28, bottom: 28),
    maxInstrument: 440,
    maxPads: 480,
  );

  static CockpitMetrics of(LayoutKind kind) => switch (kind) {
    LayoutKind.phone => _phone,
    LayoutKind.tablet => _tablet,
    LayoutKind.landscape => _landscape,
    LayoutKind.desktop => _desktop,
  };
}
