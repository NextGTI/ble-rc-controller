import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A frosted-glass surface (spec 3.3): a 4% white fill over a 14 px blur of
/// what is behind it, an 8% white outline and a 1 px line of light at the top.
///
/// With [active] the outline turns amber (35%), the fill becomes an amber
/// gradient (10% down to 3%) and the text and icons inside turn amber with a
/// soft halo.
///
/// Changing [active] is a fade of [duration] (`AppMotion.state` unless told
/// otherwise, with a deceleration): the fill, the outline, the colour of the
/// text and icons and their halo all move together. With the system's "reduce
/// motion" on it is a direct change. The widget tree has the same shape in
/// both states, so what is inside keeps its state.
///
/// With [onTap] the surface is a button; its target is never smaller than
/// 48 by 48.
///
/// Surfaces under a [GlassGroup] share one blur of the backdrop.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.active = false,
    this.radius = 16,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
    this.duration,
  });

  final Widget child;
  final bool active;
  final double radius;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  /// How long the fade between idle and active takes. Null is
  /// `AppMotion.state`; a surface that answers a touch (the arrow pads) asks
  /// for less. Zero with "reduce motion", whatever this is.
  final Duration? duration;

  /// The deceleration of the fade. Things that fade along with the glass
  /// (a halo, a value's colour) use the same one to stay in step.
  static const Curve curve = Curves.easeOut;

  /// The time a fade takes under [context]: [duration] (`AppMotion.state`
  /// when null), or zero with the system's "reduce motion". Things that fade
  /// along with a glass use it to stay in step.
  static Duration timeOf(BuildContext context, [Duration? duration]) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
      ? Duration.zero
      : (duration ?? AppMotion.state);

  /// Blur of what is behind the glass, in logical pixels.
  static const double blur = 14;

  /// Smallest side of a tappable surface.
  static const double minTarget = 48;

  /// White at 6.5%: the line of light on the top edge (spec: 6 to 7%).
  static const Color _lightLine = Color.fromRGBO(255, 255, 255, 0.065);

  /// White at 4% (idle) and the two ends of the amber fill (active).
  static final Color _amberTop = AppColors.amber.withValues(alpha: 0.10);
  static final Color _amberBottom = AppColors.amber.withValues(alpha: 0.03);
  static final Color _amberEdge = AppColors.amber.withValues(alpha: 0.35);

  /// The fill and outline at [t], 0 (idle) to 1 (active).
  ///
  /// At the ends the two plain looks: the glass colour, or the amber gradient
  /// with no colour under it (a colour and a gradient share one paint, so a
  /// colour under the gradient would multiply it by 4%). In between, both
  /// ends are gradients, so they blend without ever being painted together.
  BoxDecoration _decoration(double t, BorderRadius shape) {
    if (t <= 0) {
      return BoxDecoration(
        color: AppColors.glass,
        border: Border.all(color: AppColors.glassEdge),
        borderRadius: shape,
      );
    }
    final LinearGradient gradient;
    final Color edge;
    if (t >= 1) {
      gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_amberTop, _amberBottom],
      );
      edge = _amberEdge;
    } else {
      gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(AppColors.glass, _amberTop, t)!,
          Color.lerp(AppColors.glass, _amberBottom, t)!,
        ],
      );
      edge = Color.lerp(AppColors.glassEdge, _amberEdge, t)!;
    }
    return BoxDecoration(
      gradient: gradient,
      border: Border.all(color: edge),
      borderRadius: shape,
    );
  }

  /// [child] with the text and icons coloured amber, with a halo, [t] of the
  /// way (0 changes nothing; 1 is the active look).
  Widget _tint(BuildContext context, double t, Widget child) {
    TextStyle text = const TextStyle();
    IconThemeData icons = const IconThemeData();
    if (t > 0) {
      final textColor = t >= 1
          ? AppColors.amber
          : Color.lerp(
              DefaultTextStyle.of(context).style.color,
              AppColors.amber,
              t,
            );
      final iconColor = t >= 1
          ? AppColors.amber
          : Color.lerp(IconTheme.of(context).color, AppColors.amber, t);
      text = TextStyle(
        color: textColor,
        shadows: [
          Shadow(
            color: AppColors.amber.withValues(alpha: 0.35 * t),
            blurRadius: 8,
          ),
        ],
      );
      icons = IconThemeData(color: iconColor);
    }
    return DefaultTextStyle.merge(
      style: text,
      child: IconTheme.merge(data: icons, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final time = timeOf(context, duration);

    return ClipRRect(
      borderRadius: shape,
      // `grouped` joins the nearest [GlassGroup] (one blur for all of them);
      // with none above it is the plain filter, so a lone surface is alone.
      child: BackdropFilter.grouped(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: active ? 1 : 0),
          duration: time,
          curve: curve,
          child: Padding(padding: padding, child: child),
          builder: (context, t, padded) {
            Widget content = _tint(context, t, padded!);
            if (onTap != null) {
              content = Semantics(
                button: true,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: shape,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: minTarget,
                        minHeight: minTarget,
                      ),
                      child: content,
                    ),
                  ),
                ),
              );
            }
            return DecoratedBox(
              decoration: _decoration(t, shape),
              child: Stack(
                children: [
                  content,
                  // Just under the outline, fading out before the rounded
                  // corners.
                  Positioned(
                    top: 1,
                    left: radius * 0.5,
                    right: radius * 0.5,
                    height: 1,
                    child: const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromRGBO(255, 255, 255, 0),
                              _lightLine,
                              _lightLine,
                              Color.fromRGBO(255, 255, 255, 0),
                            ],
                            stops: [0, 0.2, 0.8, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Makes every [Glass] below it share one blur of what is behind (a
/// [BackdropGroup]). The engine then blurs the backdrop once and cuts each
/// surface out of the result, instead of once per surface: the cockpit has four
/// cells and four arrows, and it repaints on every frame while the dust moves.
///
/// Put one around a screen, a sheet or a panel whose glass surfaces do not
/// overlap each other. Surfaces that overlap (a sheet over the cockpit, two
/// pages cross-fading) must be in groups of their own: a shared blur is one
/// snapshot, and a surface that sits over another one would not blur it.
///
/// The key is made once and kept, so a rebuild of the parent does not mint a
/// new one and throw the shared layer away.
class GlassGroup extends StatefulWidget {
  const GlassGroup({super.key, required this.child});

  final Widget child;

  @override
  State<GlassGroup> createState() => _GlassGroupState();
}

class _GlassGroupState extends State<GlassGroup> {
  final BackdropKey _key = BackdropKey();

  @override
  Widget build(BuildContext context) =>
      BackdropGroup(backdropKey: _key, child: widget.child);
}
