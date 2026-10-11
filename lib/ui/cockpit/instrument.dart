import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../strings.dart';
import 'car_decal.dart';
import 'steering_gauge.dart';
import 'throttle_scale.dart';

/// The instrument of the connected cockpit (spec 4.1 to 4.3): the steering
/// gauge over the car, which is drawn solid, and the throttle scale to its
/// right, all reading the command the car is getting.
///
/// It is a square. It takes the largest one that fits the space it is given
/// (and no more than [maxSide]) and centres it. The drawing keeps the
/// proportions of the approved design, a space of [designSide] square, and
/// only scales: the texts inside it do not follow the system's text size and
/// there is no minimum, so on a short screen the instrument is what gives way.
///
/// The three drawings paint outside their own boxes (beams, halos, glow), so
/// nothing here clips. Each one is in a repaint boundary of its own, so the
/// easing of a needle or the turn of the car does not repaint the cockpit
/// around them.
///
/// The cockpit puts its particles behind this widget and needs to know where
/// the drawing stands: [frameKey] is the key of the square, and [carCenterIn]
/// and [beamIn] say where the car's centre and the headlight cone are in a
/// frame.
class Instrument extends StatelessWidget {
  const Instrument({super.key, this.frameKey, this.maxSide = double.infinity});

  /// Key of the square the instrument is drawn in.
  final Key? frameKey;

  /// The largest the square gets.
  final double maxSide;

  /// Side of the space the approved design is drawn in.
  static const double designSide = 300;

  /// Where the three drawings stand in that space.
  static const Rect _gauge = Rect.fromLTWH(30, 24, 240, 72);
  static const Rect _scale = Rect.fromLTWH(226, 86, 92, 200);
  static const Rect _car = Rect.fromLTWH(110, 106, 80, 160);

  // The 92 wide box of the scale ends at 318, past the 300 of the space. What
  // it draws does not: the marks end at 54 of its 92, the glow of the bar and
  // of the turbo line some 7 beyond, and the words (kept inside a slot by the
  // scale itself) at about 64, so everything ends near 291.

  /// The headlights, 10 units from the top of the 200 of the car.
  static final double _headlights = _car.top + _car.height * 10 / 200;

  /// The centre of the car, which the dust winds around in the 360 degree
  /// spin.
  static final Offset _carCentre = _car.center;

  /// The cone of dust the headlights light (spec 4.7), in the same space: its
  /// bottom on the headlights, 82 high and widening to 88.8, of which the base
  /// is 22.5%.
  static final Rect _beam = Rect.fromLTRB(
    _car.center.dx - 44.4,
    _headlights - 82,
    _car.center.dx + 44.4,
    _headlights,
  );

  /// The centre of the car in a [frame], the square of an instrument.
  static Offset carCenterIn(Rect frame) => _place(frame, _carCentre);

  /// The headlight cone in a [frame].
  static Rect beamIn(Rect frame) {
    final k = frame.width / designSide;
    return Rect.fromLTWH(
      frame.left + _beam.left * k,
      frame.top + _beam.top * k,
      _beam.width * k,
      _beam.height * k,
    );
  }

  static Offset _place(Rect frame, Offset p) =>
      frame.topLeft + p * (frame.width / designSide);

  @override
  Widget build(BuildContext context) {
    final command = DriverScope.of(context).command;
    final steer = (command.right ? 1 : 0) - (command.left ? 1 : 0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          math.min(constraints.maxWidth, constraints.maxHeight),
          maxSide,
        );
        if (!(side > 0) || side.isInfinite) return const SizedBox.shrink();
        return Center(
          child: SizedBox.square(
            key: frameKey,
            dimension: side,
            child: FittedBox(
              child: SizedBox.square(
                dimension: designSide,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fromRect(
                      rect: _gauge,
                      child: RepaintBoundary(
                        child: SteeringGauge(steer: steer),
                      ),
                    ),
                    Positioned.fromRect(
                      rect: _scale,
                      child: RepaintBoundary(
                        child: ThrottleScale(command: command),
                      ),
                    ),
                    Positioned.fromRect(
                      rect: _car,
                      child: RepaintBoundary(
                        child: CarDecal(
                          steer: steer,
                          lights: command.light,
                          turbo: command.turbo,
                          spinning: command.donut,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
