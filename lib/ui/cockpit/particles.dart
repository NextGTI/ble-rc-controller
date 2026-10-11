import 'package:flutter/widgets.dart';

/// Tells the decorative layers whether they may animate (spec 3.4).
///
/// Absent from the tree, the effects are on. Tests and low-power screens put a
/// scope above the layers with `particles: false` to keep them still.
///
/// Task 8 completes this file with the particle field; this class and its
/// `particlesOf` stay as they are.
class EffectsScope extends InheritedWidget {
  const EffectsScope({
    super.key,
    required this.particles,
    required super.child,
  });

  /// Whether particles and the glass sweep may run.
  final bool particles;

  /// The nearest scope's [particles]; `true` when there is none.
  static bool particlesOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EffectsScope>()?.particles ??
      true;

  @override
  bool updateShouldNotify(EffectsScope oldWidget) =>
      particles != oldWidget.particles;
}
