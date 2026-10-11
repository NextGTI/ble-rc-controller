import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/tokens.dart';

/// How far the car turns its wheels, in degrees: the car steers all or nothing
/// (spec 4.2), so the needle has three positions, not a proportional angle.
const int _turnDegrees = 18;

/// The marks of the arc, in degrees from the centre: -40 to 40 every 5.
final List<int> steerTicks = List.unmodifiable([
  for (var a = -40; a <= 40; a += 5) a,
]);

/// Whether the mark at [degrees] is one of the longer ones (every 20).
bool isMajorTick(int degrees) => degrees % 20 == 0;

/// Where the needle points for [steer] (-1, 0 or 1), in degrees.
double needleDegrees(int steer) => steer * _turnDegrees.toDouble();

/// Whether the mark at [tick] degrees lights up: only while steering, and only
/// within 6 degrees of the [needle].
bool tickLit(int tick, double needle, int steer) =>
    steer != 0 && (tick - needle).abs() <= 6;

/// The needle's ease: it goes a little past the point and comes back (the
/// approved sketch's `cubic-bezier(.3, 1.4, .4, 1)`; the overshoot is about 5%,
/// under one degree).
const Curve _needleCurve = Cubic(0.3, 1.4, 0.4, 1);

/// The steering protractor that sits above the car (spec 4.2): an arc from -40
/// to +40 degrees with a mark every 5 and a longer one every 20, an amber
/// needle, the marks next to the needle lit, a readout over the arc ("0°",
/// "18° direita", "18° esquerda") and the words "esquerda" and "direita" at the
/// two ends.
///
/// [steer] is -1, 0 or 1. The needle eases to its new place in
/// `AppMotion.needle`, going slightly past it; with the system's "reduce
/// motion" on it jumps.
///
/// The gauge has the fixed proportions of [designSize] and scales down,
/// keeping them, to fit a smaller box; the arc is drawn in that space, with its
/// centre at (120, 146), 118 below the top of the arc. The glow of the needle
/// is painted outside the box on purpose, so the box must not clip it.
class SteeringGauge extends StatelessWidget {
  const SteeringGauge({super.key, required this.steer})
    : assert(steer >= -1 && steer <= 1, 'steer is -1, 0 or 1');

  final int steer;

  /// Natural size, in logical pixels.
  static const Size designSize = Size(240, 72);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final readout = steer > 0
        ? l.steerRight(_turnDegrees)
        : steer < 0
        ? l.steerLeft(_turnDegrees)
        : '0°';
    final labelStyle = AppType.body(size: 10).copyWith(color: AppColors.text3);
    return Semantics(
      label: readout,
      excludeSemantics: true,
      child: FittedBox(
        child: SizedBox.fromSize(
          size: designSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: needleDegrees(steer)),
                  duration: reduceMotion ? Duration.zero : AppMotion.needle,
                  curve: _needleCurve,
                  builder: (context, needle, _) => CustomPaint(
                    painter: SteeringGaugePainter(needle: needle, steer: steer),
                  ),
                ),
              ),
              // The readout, centred on the arc, above the needle.
              _Slot(
                left: SteeringGaugePainter.centre.dx - 60,
                top: 0,
                width: 120,
                height: 17,
                alignment: Alignment.center,
                text: readout,
                style: AppType.numeric(size: 13)
                    .copyWith(color: AppColors.text),
              ),
              // The ends of the arc: right-aligned to the left of the arc, and
              // left-aligned to the right of it.
              _Slot(
                left: 0,
                top: 33,
                width: 42,
                height: 16,
                alignment: Alignment.centerRight,
                text: l.gaugeLeft,
                style: labelStyle,
              ),
              _Slot(
                left: 198,
                top: 33,
                width: 42,
                height: 16,
                alignment: Alignment.centerLeft,
                text: l.gaugeRight,
                style: labelStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A line of text in a fixed slot of the gauge. It keeps its size when the
/// system enlarges text (the gauge is a drawing), and shrinks instead of
/// spilling over when a language needs more room.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.alignment,
    required this.text,
    required this.style,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final Alignment alignment;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    width: width,
    height: height,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        text,
        style: style,
        maxLines: 1,
        softWrap: false,
        textScaler: TextScaler.noScaling,
      ),
    ),
  );
}

/// Draws the arc, its marks and the needle in the space of
/// [SteeringGauge.designSize].
///
/// [needle] is where the needle is now, in degrees (it eases, so it is rarely
/// -18, 0 or 18), and [steer] what the car is doing: the marks light up for
/// [steer] != 0, the ones within 6 degrees of [needle].
@visibleForTesting
class SteeringGaugePainter extends CustomPainter {
  const SteeringGaugePainter({required this.needle, required this.steer});

  final double needle;
  final int steer;

  /// The point the needle turns around, the centre of the arc.
  static const Offset centre = Offset(120, 146);

  /// Radius of the arc.
  static const double radius = 118;

  /// Whether the mark at [tick] degrees is lit now.
  bool isLit(int tick) => tickLit(tick, needle, steer);

  /// A soft amber glow under a stroke of [width]: the stroke is drawn blurred
  /// first and sharp over it.
  static Paint _glow(double width) => Paint()
    ..color = AppColors.amber
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);

  @override
  void paint(Canvas canvas, Size size) {
    final major = Paint()
      ..color = AppColors.trace
      ..strokeWidth = 1;
    final minor = Paint()
      ..color = AppColors.traceWeak
      ..strokeWidth = 1;
    final lit = Paint()
      ..color = AppColors.amber
      ..strokeWidth = 1;
    final glow = _glow(1);

    for (final tick in steerTicks) {
      final a = tick * math.pi / 180;
      final dir = Offset(math.sin(a), -math.cos(a));
      final inner = radius - (isMajorTick(tick) ? 10 : 5);
      final from = centre + dir * radius;
      final to = centre + dir * inner;
      if (isLit(tick)) {
        canvas.drawLine(from, to, glow);
        canvas.drawLine(from, to, lit);
      } else {
        canvas.drawLine(from, to, isMajorTick(tick) ? major : minor);
      }
    }

    // The needle crosses the arc: 5 outside it and 13 inside.
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(needle * math.pi / 180);
    final top = Offset(0, -(radius + 5));
    final bottom = Offset(0, -(radius - 13));
    canvas.drawLine(top, bottom, _glow(2));
    canvas.drawLine(
      top,
      bottom,
      Paint()
        ..color = AppColors.amber
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SteeringGaugePainter old) =>
      old.needle != needle || old.steer != steer;
}
