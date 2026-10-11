import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// How the car decal looks (spec 4.1).
enum DecalVariant {
  /// Outline in the decal colour with a faint fill: the connected car.
  solid,

  /// Every stroke dashed in the ghost colour: no car, or connection lost.
  ghost,

  /// The stroke completes progressively over a ghost outline: connecting.
  drawing,

  /// Only the body, for the car list on desktop.
  icon,
}

/// How far the car turns its front wheels, in degrees. It steers all or
/// nothing (spec 4.1), so this is the one angle the decal and the steering
/// gauge show.
const int steerDegrees = 18;

/// Angle of the front wheels for [steer] (-1, 0 or 1), in radians.
double wheelAngle(int steer) => steer * steerDegrees * math.pi / 180;

/// The outline of the car body (spec 4.1), drawn in a space of 100 by 200 and
/// scaled to [size].
Path carBodyPath(Size size) => _Shapes.body.transform(
  Matrix4.diagonal3Values(size.width / 100, size.height / 200, 1).storage,
);

/// The generic GT car seen from above, drawn with lines (spec 4.1).
///
/// The drawing is a fitted 100 by 200 box, centred in the space it gets, so it
/// needs bounded constraints. It paints outside that box on purpose: the
/// headlight beams reach 76 units above the car and the turbo halo hangs below
/// it, so callers leave room and must not clip it.
///
/// [steer] (-1, 0 or 1) turns the front wheels by 18 degrees and tilts the
/// whole car by a quarter of that. [lights] adds the headlight beams, [turbo]
/// the amber halo behind the car, and [spinning] makes one 360 degree turn in
/// `AppMotion.spin` each time it becomes true. These four only act on
/// [DecalVariant.solid]: the other variants are not a connected car.
///
/// `DecalVariant.drawing` repeats its stroke in `AppMotion.draw`. With the
/// system's "reduce motion" on, it shows the full stroke, the spin does not
/// animate and a change of [steer], [lights] or [turbo] is immediate.
///
/// [iconColor] is the colour of `DecalVariant.icon` (amber when the car is
/// connected, grey otherwise); it defaults to the grey of the traces.
class CarDecal extends StatefulWidget {
  const CarDecal({
    super.key,
    this.variant = DecalVariant.solid,
    this.steer = 0,
    this.lights = false,
    this.turbo = false,
    this.spinning = false,
    this.iconColor,
  }) : assert(steer >= -1 && steer <= 1, 'steer is -1, 0 or 1');

  final DecalVariant variant;
  final int steer;
  final bool lights;
  final bool turbo;
  final bool spinning;
  final Color? iconColor;

  /// Whether the spin is on: only a connected (solid) car turns.
  bool get _spins => spinning && variant == DecalVariant.solid;

  @override
  State<CarDecal> createState() => _CarDecalState();
}

class _CarDecalState extends State<CarDecal> with TickerProviderStateMixin {
  /// The 360 degree turn: 0 at rest, 1 after the turn (the same pose).
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: AppMotion.spin,
  );

  /// How much of the stroke is drawn, for `DecalVariant.drawing`.
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: AppMotion.draw,
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncSpin(widget);
    _syncDraw();
  }

  @override
  void didUpdateWidget(CarDecal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpin(oldWidget);
    _syncDraw();
  }

  /// Starts a turn when [CarDecal.spinning] became true since [old]; any other
  /// time the car rests (a turn that is over looks the same as no turn).
  void _syncSpin(CarDecal old) {
    if (!widget._spins) {
      _spin.value = 0;
    } else if (!old._spins && !_reduceMotion) {
      _spin.forward(from: 0);
    } else if (_reduceMotion || !_spin.isAnimating) {
      _spin.value = 1;
    }
  }

  void _syncDraw() {
    if (widget.variant == DecalVariant.drawing && !_reduceMotion) {
      if (!_draw.isAnimating) _draw.repeat();
    } else {
      _draw.value = 1;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final solid = widget.variant == DecalVariant.solid;
    return _Reaction(
      steer: solid ? widget.steer.toDouble() : 0,
      lights: solid && widget.lights ? 1 : 0,
      turbo: solid && widget.turbo ? 1 : 0,
      duration: _reduceMotion ? Duration.zero : AppMotion.needle,
      builder: (context, steer, lights, turbo) => CustomPaint(
        size: Size.infinite,
        painter: _DecalPainter(
          variant: widget.variant,
          steer: steer,
          lights: lights,
          turbo: turbo,
          iconColor: widget.iconColor ?? AppColors.trace,
          spin: _spin,
          draw: _draw,
        ),
      ),
    );
  }
}

/// Eases the steering, the lights and the turbo halo to their new value (the
/// tilt follows the gauge needle, which also takes `AppMotion.needle`).
class _Reaction extends ImplicitlyAnimatedWidget {
  const _Reaction({
    required this.steer,
    required this.lights,
    required this.turbo,
    required this.builder,
    required super.duration,
  }) : super(curve: Curves.easeOutCubic);

  final double steer;
  final double lights;
  final double turbo;
  final Widget Function(
    BuildContext context,
    double steer,
    double lights,
    double turbo,
  )
  builder;

  @override
  ImplicitlyAnimatedWidgetState<_Reaction> createState() => _ReactionState();
}

class _ReactionState extends AnimatedWidgetBaseState<_Reaction> {
  Tween<double>? _steer;
  Tween<double>? _lights;
  Tween<double>? _turbo;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    Tween<double>? visit(Tween<double>? t, double target) =>
        visitor(t, target, (v) => Tween<double>(begin: v as double))
            as Tween<double>?;
    _steer = visit(_steer, widget.steer);
    _lights = visit(_lights, widget.lights);
    _turbo = visit(_turbo, widget.turbo);
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _steer!.evaluate(animation),
    _lights!.evaluate(animation),
    _turbo!.evaluate(animation),
  );
}

// ---------------------------------------------------------------------------
// Drawing

/// Which stroke a [_Part] is, and so its colour.
enum _Role { wheel, body, glass, roof, centre, light, tail }

/// Glass of the car (windshield and rear window): a grey between the secondary
/// and the tertiary text, so the panes read lighter than the traces. It is the
/// stroke of the approved sketch and has no token.
const Color _glassLine = Color(0xFF8A919C);

/// Alpha of the headlight beam where it leaves the car, falling to 0 (30%, as
/// in the approved design).
const double _beamAlpha = 0.30;

/// A stroke of the decal, in the 100 by 200 space.
class _Part {
  _Part(
    this.role,
    this.path,
    this.width, {
    this.pivot,
    this.dash,
    this.round = false,
  });

  final _Role role;
  final Path path;
  final double width;

  /// Centre the front wheels turn around.
  final Offset? pivot;

  /// Length of the dashes (and of the gaps) of a line that is dashed even in
  /// the solid variant.
  final double? dash;

  /// Round line ends.
  final bool round;

  /// [path] as the solid variant strokes it.
  late final Path solid = dash == null ? path : _dashed(path, dash!);

  /// [path] as the ghost strokes it: dashes of 4 with gaps of 4.
  late final Path ghost = _dashed(path, 4);
}

/// [src] cut in dashes of length [on] with gaps of the same length.
Path _dashed(Path src, double on) {
  final out = Path();
  for (final m in src.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += on * 2) {
      out.addPath(m.extractPath(d, math.min(d + on, m.length)), Offset.zero);
    }
  }
  return out;
}

/// The first [fraction] of every contour of [src].
Path _trimmed(Path src, double fraction) {
  final out = Path();
  for (final m in src.computeMetrics()) {
    out.addPath(m.extractPath(0, m.length * fraction), Offset.zero);
  }
  return out;
}

abstract final class _Shapes {
  /// Outline of the body (the approved sketch's `BODY`).
  static final Path body = Path()
    ..moveTo(50, 3)
    ..cubicTo(38, 3, 29, 6, 24, 12)
    ..cubicTo(19, 18, 17, 24, 15, 30)
    ..cubicTo(12, 38, 11, 46, 13, 54)
    ..cubicTo(15, 60, 18, 64, 19, 70)
    ..cubicTo(20, 84, 20, 100, 19, 116)
    ..cubicTo(18, 124, 14, 132, 12, 142)
    ..cubicTo(10, 152, 11, 162, 14, 172)
    ..cubicTo(16, 182, 22, 190, 32, 194)
    ..cubicTo(40, 197, 60, 197, 68, 194)
    ..cubicTo(78, 190, 84, 182, 86, 172)
    ..cubicTo(89, 162, 90, 152, 88, 142)
    ..cubicTo(86, 132, 82, 124, 81, 116)
    ..cubicTo(80, 100, 80, 84, 81, 70)
    ..cubicTo(82, 64, 85, 60, 87, 54)
    ..cubicTo(89, 46, 88, 38, 85, 30)
    ..cubicTo(83, 24, 81, 18, 76, 12)
    ..cubicTo(71, 6, 62, 3, 50, 3)
    ..close();

  static final Rect bodyBox = body.getBounds();

  static Path _wheel(double x, double y, double w, double h) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(3.5),
      ),
    );

  static const Offset leftPivot = Offset(10.5, 42);
  static const Offset rightPivot = Offset(89.5, 42);

  /// Beams, from the headlights to 76 units above the car.
  static final Path beams = Path()
    ..moveTo(26, 10)
    ..lineTo(-4, -76)
    ..lineTo(38, -76)
    ..close()
    ..moveTo(74, 10)
    ..lineTo(62, -76)
    ..lineTo(104, -76)
    ..close();

  /// In the order they are drawn.
  static final List<_Part> parts = [
    _Part(_Role.wheel, _wheel(4, 29, 13, 27), 1, pivot: leftPivot),
    _Part(_Role.wheel, _wheel(83, 29, 13, 27), 1, pivot: rightPivot),
    _Part(_Role.wheel, _wheel(3, 138, 14, 30), 1),
    _Part(_Role.wheel, _wheel(83, 138, 14, 30), 1),
    _Part(_Role.body, body, 1.1),
    // Windshield.
    _Part(
      _Role.glass,
      Path()
        ..moveTo(30, 66)
        ..cubicTo(34, 60, 66, 60, 70, 66)
        ..lineTo(68, 82)
        ..cubicTo(60, 78, 40, 78, 32, 82)
        ..close(),
      0.9,
    ),
    // Roof.
    _Part(
      _Role.roof,
      Path()
        ..moveTo(32, 84)
        ..cubicTo(40, 80, 60, 80, 68, 84)
        ..lineTo(67, 118)
        ..cubicTo(60, 121, 40, 121, 33, 118)
        ..close(),
      0.9,
    ),
    // Rear window.
    _Part(
      _Role.glass,
      Path()
        ..moveTo(33, 120)
        ..cubicTo(40, 123, 60, 123, 67, 120)
        ..lineTo(66, 134)
        ..cubicTo(60, 137, 40, 137, 34, 134)
        ..close(),
      0.9,
    ),
    // Centre line.
    _Part(
      _Role.centre,
      Path()
        ..moveTo(50, 4)
        ..lineTo(50, 196),
      0.8,
      dash: 3,
    ),
    // Headlights.
    _Part(
      _Role.light,
      Path()
        ..moveTo(22, 16)
        ..cubicTo(26, 11, 31, 9, 37, 9)
        ..moveTo(78, 16)
        ..cubicTo(74, 11, 69, 9, 63, 9),
      1.6,
      round: true,
    ),
    // Tail lights.
    _Part(
      _Role.tail,
      Path()
        ..moveTo(30, 190)
        ..cubicTo(42, 193, 58, 193, 70, 190),
      1.2,
      round: true,
    ),
  ];
}

class _DecalPainter extends CustomPainter {
  _DecalPainter({
    required this.variant,
    required this.steer,
    required this.lights,
    required this.turbo,
    required this.iconColor,
    required this.spin,
    required this.draw,
  }) : super(repaint: Listenable.merge([spin, draw]));

  final DecalVariant variant;

  /// -1 to 1 (in between while it eases).
  final double steer;

  /// 0 to 1: how lit the headlights and beams are.
  final double lights;

  /// 0 to 1: how visible the halo is.
  final double turbo;
  final Color iconColor;

  /// 0 to 1: the turn of the car.
  final Animation<double> spin;

  /// 0 to 1: how much of the stroke is drawn.
  final Animation<double> draw;

  /// Easing of the turn (the approved sketch's curve).
  static const Curve _turn = Cubic(0.3, 0.75, 0.25, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 100, size.height / 200);
    if (scale <= 0 || !scale.isFinite) return;
    canvas.save();
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 200 * scale) / 2,
    );
    canvas.scale(scale);
    switch (variant) {
      case DecalVariant.icon:
        _paintIcon(canvas);
      case DecalVariant.ghost:
        _paintGhost(canvas);
      case DecalVariant.drawing:
        _paintGhost(canvas);
        _paintStrokes(canvas, progress: Curves.easeInOut.transform(draw.value));
      case DecalVariant.solid:
        // Tilt of a quarter of the wheel angle, and the turn, around the
        // centre of the car.
        canvas.translate(50, 100);
        canvas.rotate(
          steer * wheelAngle(1) / 4 + 2 * math.pi * _turn.transform(spin.value),
        );
        canvas.translate(-50, -100);
        _paintStrokes(canvas, wheelTurn: steer * wheelAngle(1));
        _paintBeams(canvas);
        _paintHalo(canvas);
    }
    canvas.restore();
  }

  Color _colorOf(_Role role) => switch (role) {
    _Role.wheel || _Role.roof => AppColors.trace,
    _Role.body || _Role.tail => AppColors.decal,
    _Role.glass => _glassLine,
    _Role.centre => AppColors.traceWeak,
    _Role.light => Color.lerp(AppColors.decal, AppColors.headlight, lights)!,
  };

  /// The body, in the colour of the icon, with a 10% fill.
  void _paintIcon(Canvas canvas) {
    canvas.drawPath(
      _Shapes.body,
      Paint()..color = iconColor.withValues(alpha: 0.10),
    );
    canvas.drawPath(
      _Shapes.body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..color = iconColor,
    );
  }

  /// Every element dashed in the ghost colour.
  void _paintGhost(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.ghost;
    for (final part in _Shapes.parts) {
      paint.strokeWidth = part.width;
      _withWheelTurn(canvas, part, 0, () => canvas.drawPath(part.ghost, paint));
    }
  }

  /// The elements in their colours. With a [progress] below 1, only that
  /// fraction of each stroke (and of the fill) is there.
  void _paintStrokes(
    Canvas canvas, {
    double progress = 1,
    double wheelTurn = 0,
  }) {
    for (final part in _Shapes.parts) {
      if (part.role == _Role.body) {
        canvas.drawPath(
          part.path,
          Paint()
            ..shader = ui.Gradient.linear(
              _Shapes.bodyBox.centerLeft,
              _Shapes.bodyBox.centerRight,
              [
                AppColors.text.withValues(alpha: 0.02 * progress),
                AppColors.text.withValues(alpha: 0.07 * progress),
                AppColors.text.withValues(alpha: 0.02 * progress),
              ],
              const [0, 0.5, 1],
            ),
        );
      }
      final Path path;
      if (progress >= 1) {
        path = part.solid;
      } else if (progress <= 0) {
        continue;
      } else {
        final cut = _trimmed(part.path, progress);
        path = part.dash == null ? cut : _dashed(cut, part.dash!);
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = part.width
        ..strokeCap = part.round ? StrokeCap.round : StrokeCap.butt
        ..color = _colorOf(part.role);
      _withWheelTurn(
        canvas,
        part,
        wheelTurn,
        () => canvas.drawPath(path, paint),
      );
    }
  }

  /// Runs [paintIt] with the canvas turned around the wheel's pivot, if it has one.
  void _withWheelTurn(
    Canvas canvas,
    _Part part,
    double angle,
    VoidCallback paintIt,
  ) {
    final pivot = part.pivot;
    if (pivot == null || angle == 0) return paintIt();
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    paintIt();
    canvas.restore();
  }

  /// Two beams that fade from the headlights to 76 units above the car.
  void _paintBeams(Canvas canvas) {
    if (lights <= 0) return;
    canvas.drawPath(
      _Shapes.beams,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 10),
          const Offset(0, -76),
          [
            AppColors.headlight.withValues(alpha: _beamAlpha * lights),
            AppColors.headlight.withValues(alpha: 0),
          ],
        ),
    );
  }

  /// The turbo halo: an ellipse centred under the tail, amber fading out
  /// through the hot amber.
  void _paintHalo(Canvas canvas) {
    if (turbo <= 0) return;
    canvas.save();
    canvas.translate(50, 206);
    canvas.scale(1, 16 / 30);
    canvas.drawCircle(
      Offset.zero,
      30,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          30,
          [
            AppColors.amber.withValues(alpha: 0.75 * turbo),
            AppColors.amberHot.withValues(alpha: 0.25 * turbo),
            AppColors.amberHot.withValues(alpha: 0),
          ],
          const [0, 0.45, 1],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DecalPainter old) =>
      variant != old.variant ||
      steer != old.steer ||
      lights != old.lights ||
      turbo != old.turbo ||
      iconColor != old.iconColor ||
      spin != old.spin ||
      draw != old.draw;
}
