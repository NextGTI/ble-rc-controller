import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/driver.dart';
import '../common/glass.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'car_list.dart';

/// Opens the car sheet over the cockpit (spec 5.3): frosted glass that rises
/// over a dimmed screen, with the [CarList] and, at the foot, the switch for
/// reconnecting to the last car.
///
/// It closes when the screen is dragged down or tapped outside, and by
/// itself when the driver connects to a car other than the one that was
/// connected when it opened. A connection that fails keeps it open, with the
/// notice. With the system's "reduce motion" on it appears and goes at once.
///
/// Needs a `DriverScope` above [context]. Completes when the sheet is gone.
Future<void> showCarSheet(BuildContext context) {
  final driver = DriverScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // The sheet paints its own frosted surface.
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: AppColors.bg.withValues(alpha: 0.6),
    constraints: const BoxConstraints(maxWidth: 560),
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (_) => _CarSheet(
      driver: driver,
      openedOn: driver.link == LinkState.connected ? driver.carId : null,
    ),
  );
}

class _CarSheet extends StatefulWidget {
  const _CarSheet({required this.driver, required this.openedOn});

  final Driver driver;

  /// The car that was connected when the sheet opened, or null. The sheet
  /// stays for that car and leaves when another one connects.
  final String? openedOn;

  @override
  State<_CarSheet> createState() => _CarSheetState();
}

class _CarSheetState extends State<_CarSheet> {
  ModalRoute<void>? _route;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.driver.addListener(_onDriver);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of<void>(context);
  }

  @override
  void dispose() {
    widget.driver.removeListener(_onDriver);
    super.dispose();
  }

  void _onDriver() {
    final d = widget.driver;
    if (_closing || d.link != LinkState.connected) return;
    if (d.carId == widget.openedOn) return;
    // Under something else (a dialog), popping would close that instead.
    if (!(_route?.isCurrent ?? false)) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return _Surface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Handle(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: const CarList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 14 + bottomInset),
            child: const AutoConnectToggle(),
          ),
        ],
      ),
    );
  }
}

/// The frosted surface of the sheet (spec 3.3): a 14 px blur of what is
/// behind, a dark veil so the texts stay legible over the cockpit, the 4%
/// glass fill, an 8% outline and a line of light on the top edge. The top
/// corners have a radius of 24.
class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  static const double radius = 24;
  static const BorderRadius _shape = BorderRadius.vertical(
    top: Radius.circular(radius),
  );

  /// White at 6.5%: the same line of light as `Glass`.
  static const Color _lightLine = Color.fromRGBO(255, 255, 255, 0.065);

  /// The background at 70% under the glass fill.
  static final Color _fill = Color.alphaBlend(
    AppColors.glass,
    AppColors.bg.withValues(alpha: 0.7),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _shape,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: Glass.blur, sigmaY: Glass.blur),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: _fill,
            shape: const RoundedRectangleBorder(
              borderRadius: _shape,
              side: BorderSide(color: AppColors.glassEdge),
            ),
          ),
          child: Stack(
            children: [
              child,
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

/// The grab bar at the top of the sheet. The whole sheet drags; this only
/// says so.
class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: SizedBox(
            width: 36,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.trace,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
