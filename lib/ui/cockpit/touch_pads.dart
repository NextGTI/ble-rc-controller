import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/driver.dart';
import '../../core/protocol.dart';
import '../../l10n/gen/app_localizations.dart';
import '../common/glass.dart';
import '../strings.dart';
import '../theme/tokens.dart';

/// A region of the screen that holds a [CarAction] on while a finger (or the
/// mouse button) is down on it, through `Driver.setVirtual`.
///
/// It reports "down" on pointer-down and "up" on pointer-up or cancel, so
/// several regions can be held at once (multi-touch), and a finger that slides
/// off the region keeps it held until it lifts. [builder] draws the region and
/// is told whether it is held.
///
/// If the region leaves the tree while held (the layout changes, the on-screen
/// controls are switched off) it lets go, so the car never keeps running.
class HoldRegion extends StatefulWidget {
  const HoldRegion({super.key, required this.action, required this.builder});

  final CarAction action;
  final Widget Function(BuildContext context, bool held) builder;

  @override
  State<HoldRegion> createState() => _HoldRegionState();
}

class _HoldRegionState extends State<HoldRegion> {
  /// The fingers down on this region; it is held while there is one.
  final Set<int> _pointers = {};
  late Driver _driver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _driver = DriverScope.of(context);
  }

  void _down(PointerDownEvent e) {
    if (!_pointers.add(e.pointer) || _pointers.length != 1) return;
    setState(() {});
    _driver.setVirtual(widget.action, true);
  }

  void _up(PointerEvent e) {
    // A finger can outlive the region: it was let go of in [dispose].
    if (!mounted) return;
    if (!_pointers.remove(e.pointer) || _pointers.isNotEmpty) return;
    setState(() {});
    _driver.setVirtual(widget.action, false);
  }

  @override
  void dispose() {
    if (_pointers.isNotEmpty) {
      // The driver tells its listeners when the command changes, and the tree
      // is locked while it is being torn down: let go once the frame is done.
      final driver = _driver;
      final action = widget.action;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        try {
          driver.setVirtual(action, false);
        } catch (_) {
          // The driver itself is gone (the app is closing): nothing to stop.
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: _down,
    onPointerUp: _up,
    onPointerCancel: _up,
    child: widget.builder(context, _pointers.isNotEmpty),
  );
}

/// The four arrows under the instrument (spec 4.5), in the order left, right,
/// down, up. Each one is on while it is pressed, through `Driver.setVirtual`.
///
/// They are glass with a line of light. Pressed, one turns amber with a halo
/// and sits 1 px lower. They are square, 52 at least, and grow with the width
/// they are given (four sides and three gaps of 12) up to 84.
class TouchPads extends StatelessWidget {
  const TouchPads({super.key});

  static const double gap = 12;
  static const double minSide = 52;
  static const double maxSide = 84;

  /// The side of one arrow in a row [width] wide.
  static double sideFor(double width) =>
      ((width - 3 * gap) / 4).clamp(minSide, maxSide);

  static const _arrows = [
    (CarAction.left, Icons.arrow_back_rounded),
    (CarAction.right, Icons.arrow_forward_rounded),
    (CarAction.reverse, Icons.arrow_downward_rounded),
    (CarAction.forward, Icons.arrow_upward_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = sideFor(constraints.maxWidth);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _arrows.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              _Pad(action: _arrows[i].$1, icon: _arrows[i].$2, side: side),
            ],
          ],
        );
      },
    );
  }
}

class _Pad extends StatelessWidget {
  const _Pad({required this.action, required this.icon, required this.side});

  final CarAction action;
  final IconData icon;
  final double side;

  static const double _radius = 16;

  /// The fade to amber and back: the 150 ms of the approved design, quicker
  /// than a cell's, so a press answers at once.
  static const Duration _fade = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l.action(action),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: side,
        child: HoldRegion(
          action: action,
          // The 1 px drop is at once; the colour, the halo and the glass fade
          // together (same time, same curve).
          builder: (context, held) => Transform.translate(
            offset: Offset(0, held ? 1 : 0),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: held ? 1 : 0),
              duration: Glass.timeOf(context, _fade),
              curve: Glass.curve,
              builder: (context, t, _) => CustomPaint(
                painter: t > 0 ? _Halo(_radius, t) : null,
                child: Glass(
                  active: held,
                  duration: _fade,
                  radius: _radius,
                  padding: EdgeInsets.zero,
                  child: Center(
                    child: Icon(
                      icon,
                      size: 24,
                      color: t >= 1
                          ? AppColors.amber
                          : Color.lerp(AppColors.text2, AppColors.amber, t),
                      shadows: t > 0
                          ? [
                              Shadow(
                                color: AppColors.amber.withValues(
                                  alpha: 0.35 * t,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The amber glow around a pressed arrow, [strength] of the way in: drawn outside its outline only (a
/// blur that is clipped from the inside, like a CSS outer shadow), so it does
/// not tint the glass.
class _Halo extends CustomPainter {
  const _Halo(this.radius, this.strength);

  final double radius;

  /// 0 (none) to 1 (the full glow).
  final double strength;

  /// Gaussian sigma of the glow: half the 24 px blur of the approved design.
  static const double _sigma = 12;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      Paint()
        ..color = AppColors.amber.withValues(alpha: 0.25 * strength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, _sigma),
    );
  }

  @override
  bool shouldRepaint(_Halo old) =>
      old.radius != radius || old.strength != strength;
}
