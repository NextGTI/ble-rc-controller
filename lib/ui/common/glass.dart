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
/// With [onTap] the surface is a button; its target is never smaller than
/// 48 by 48.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.active = false,
    this.radius = 16,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
  });

  final Widget child;
  final bool active;
  final double radius;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  /// Blur of what is behind the glass, in logical pixels.
  static const double blur = 14;

  /// Smallest side of a tappable surface.
  static const double minTarget = 48;

  /// White at 6.5%: the line of light on the top edge (spec: 6 to 7%).
  static const Color _lightLine = Color.fromRGBO(255, 255, 255, 0.065);

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);

    Widget content = Padding(padding: padding, child: child);
    if (active) {
      content = DefaultTextStyle.merge(
        style: TextStyle(
          color: AppColors.amber,
          shadows: [
            Shadow(
              color: AppColors.amber.withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
        child: IconTheme.merge(
          data: const IconThemeData(color: AppColors.amber),
          child: content,
        ),
      );
    }
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

    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.glass,
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.amber.withValues(alpha: 0.10),
                      AppColors.amber.withValues(alpha: 0.03),
                    ],
                  )
                : null,
            border: Border.all(
              color: active
                  ? AppColors.amber.withValues(alpha: 0.35)
                  : AppColors.glassEdge,
            ),
            borderRadius: shape,
          ),
          child: Stack(
            children: [
              content,
              // Just under the outline, fading out before the rounded corners.
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
        ),
      ),
    );
  }
}
