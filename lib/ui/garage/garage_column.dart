import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/car_transport.dart';
import '../../core/driver.dart';
import '../../input/controller_profile.dart';
import '../../l10n/gen/app_localizations.dart';
import '../common/glass.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'car_list.dart';

/// The garage on a desktop window (spec 6, width of 900 or more): a fixed
/// column of 280 with the cars, the controllers and, at the foot, the switch
/// for reconnecting to the last car.
///
/// "Cars nearby" has the searching indicator beside it while the app is
/// scanning, which is when Bluetooth is ready and no car is linked. The cars
/// are the [CarList]. Each controller shows its name and whether the app
/// knows it ("Recognised") or was taught it ("Taught"); with none, the
/// section says so.
///
/// The cars and controllers scroll when the window is short; the switch stays
/// in place. The column fills the height it is given, so put it in a row of
/// fixed height. It needs a `DriverScope` above it.
class GarageColumn extends StatelessWidget {
  const GarageColumn({super.key});

  static const double width = 280;

  /// The column's own fill: lighter than the glass of the rows on it (the
  /// approved desktop design).
  static const Color _fill = Color.fromRGBO(255, 255, 255, 0.025);

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final searching =
        driver.bluetooth == BluetoothState.ready &&
        driver.link == LinkState.idle;
    final controllers = driver.controllers;

    return SizedBox(
      width: width,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: Glass.blur, sigmaY: Glass.blur),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: _fill,
              border: Border(right: BorderSide(color: AppColors.glassEdge)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Heading(
                            title: l.carsNearby,
                            trailing: searching
                                ? _Searching(label: l.statusSearching)
                                : null,
                          ),
                          const CarList(),
                          _Heading(title: l.controllersTitle, top: 22),
                          if (controllers.isEmpty)
                            _ControllerRow(name: l.noControllerShort)
                          else
                            for (var i = 0; i < controllers.length; i++)
                              Padding(
                                key: ValueKey(controllers[i].id),
                                padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
                                child: _ControllerRow(
                                  name: controllers[i].name,
                                  status: _taught(driver, controllers[i])
                                      ? l.taught
                                      : l.recognized,
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const AutoConnectToggle(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A controller is taught when the user gave its model a mapping of their
  /// own; otherwise the app knew it already.
  static bool _taught(Driver driver, ControllerInfo info) =>
      driver.profiles[info.profileKey]?.isCustom ?? false;
}

/// A small title over a section, with something at the far end if there is.
class _Heading extends StatelessWidget {
  const _Heading({required this.title, this.trailing, this.top = 6});

  final String title;
  final Widget? trailing;

  /// Space above, in the column's rhythm.
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(6, top, 6, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AppType.body(size: 12).copyWith(color: AppColors.text3),
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// The searching indicator: a ring of 10 with a quarter of it amber, turning
/// once a second. With the system's "reduce motion" on it stands still.
class _Searching extends StatefulWidget {
  const _Searching({required this.label});

  /// What a screen reader says for it.
  final String label;

  @override
  State<_Searching> createState() => _SearchingState();
}

class _SearchingState extends State<_Searching>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.value = 0;
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      child: ExcludeSemantics(
        child: RotationTransition(
          turns: _turn,
          child: const SizedBox(
            width: 10,
            height: 10,
            child: CustomPaint(painter: _RingPainter()),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter();

  static const double _stroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = AppColors.traceWeak;
    canvas.drawOval(rect, paint);
    // A quarter centred on the top.
    canvas.drawArc(
      rect,
      -math.pi * 3 / 4,
      math.pi / 2,
      false,
      paint..color = AppColors.amber,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

/// One controller: its name and, when [status] is given, whether the app
/// recognises it or was taught it, with a small lit dot.
class _ControllerRow extends StatelessWidget {
  const _ControllerRow({required this.name, this.status});

  final String name;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final known = status != null;
    return Glass(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: MergeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.body(size: 14)
                    .copyWith(color: known ? AppColors.text : AppColors.text2),
              ),
            ),
            if (known) ...[
              const SizedBox(width: 8),
              const _Dot(),
              const SizedBox(width: 5),
              Text(
                status!,
                maxLines: 1,
                style: AppType.body(size: 11).copyWith(color: AppColors.text2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The small lit dot before a controller's status.
class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.text,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.text.withValues(alpha: 0.6),
              blurRadius: 6,
            ),
          ],
        ),
        child: const SizedBox(width: 5, height: 5),
      ),
    );
  }
}
