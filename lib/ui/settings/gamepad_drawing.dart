import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The pieces of a controller that the teach wizard asks for (spec 4.8).
enum GamepadPart {
  faceBottom,
  faceRight,
  faceLeft,
  faceTop,
  leftBumper,
  rightBumper,
  leftTrigger,
  rightTrigger,
  back,
  start,
  leftStick,
  rightStick,
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
}

/// The piece of the controller that the teach step [stepId] (one of the ids
/// of `teachSteps`) asks the user to press or push.
///
/// The two axes of a stick point at the same stick: the wizard asks for
/// "right" and then "up" on it, and the drawing lights the stick both times.
///
/// Throws an [ArgumentError] for an id that is not a step.
GamepadPart gamepadPartFor(String stepId) => switch (stepId) {
  'a' => GamepadPart.faceBottom,
  'b' => GamepadPart.faceRight,
  'x' => GamepadPart.faceLeft,
  'y' => GamepadPart.faceTop,
  'leftBumper' => GamepadPart.leftBumper,
  'rightBumper' => GamepadPart.rightBumper,
  'leftTrigger' => GamepadPart.leftTrigger,
  'rightTrigger' => GamepadPart.rightTrigger,
  'back' => GamepadPart.back,
  'start' => GamepadPart.start,
  'axis:leftStickX' || 'axis:leftStickY' => GamepadPart.leftStick,
  'axis:rightStickX' || 'axis:rightStickY' => GamepadPart.rightStick,
  'dpadUp' => GamepadPart.dpadUp,
  'dpadDown' => GamepadPart.dpadDown,
  'dpadLeft' => GamepadPart.dpadLeft,
  'dpadRight' => GamepadPart.dpadRight,
  _ => throw ArgumentError.value(stepId, 'stepId', 'is not a teach step'),
};

/// A generic controller seen from the front, in the thin line of the car
/// decal, with [highlight] lit in amber and pulsing (spec 4.8).
///
/// The drawing takes the width it is given and keeps its proportions. The
/// line is 1.5 px wide whatever the size.
///
/// The glow of the lit part goes down to a third and up again every 1.3 s,
/// and never stops by itself. With the system's "reduce motion" on it is lit
/// and still. Changing [highlight] moves the light without restarting the
/// beat, so the pulse does not stutter from one step to the next.
class GamepadDrawing extends StatefulWidget {
  const GamepadDrawing({super.key, required this.highlight});

  final GamepadPart highlight;

  @override
  State<GamepadDrawing> createState() => _GamepadDrawingState();
}

class _GamepadDrawingState extends State<GamepadDrawing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _pulse = CurvedAnimation(
    parent: _beat,
    curve: Curves.easeInOut,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      // Lit, at its brightest, and still.
      _beat.stop();
      _beat.value = 0;
    } else if (!_beat.isAnimating) {
      _beat.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The words of the step say it all; the drawing is for the eyes.
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: GamepadPainter.world.width / GamepadPainter.world.height,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: GamepadPainter(highlight: widget.highlight, pulse: _pulse),
          ),
        ),
      ),
    );
  }
}

/// Paints the controller of [GamepadDrawing].
///
/// [pulse] is 0 when the glow of the lit part is at its brightest and 1 when
/// it is at its dimmest; the painter repaints with it.
class GamepadPainter extends CustomPainter {
  GamepadPainter({required this.highlight, required this.pulse})
    : super(repaint: pulse);

  final GamepadPart highlight;
  final Animation<double> pulse;

  /// The size the drawing is made in, in drawing units. It is scaled to fit
  /// the room it gets.
  static const Size world = Size(240, 156);

  /// Width of the line, in logical pixels.
  static const double _line = 1.5;

  /// The glow of the lit part at its dimmest, as a share of the brightest.
  static const double _dimmest = 0.35;

  /// Where the sketch starts: its bumpers and triggers go a little above 0.
  static const double _top = 8;

  // The shapes, in the units of the approved sketch (spec 4.8) below [_top].
  static final Path _body = Path()
    ..moveTo(60, 20)
    ..cubicTo(40, 20, 30, 28, 24, 44)
    ..lineTo(8, 104)
    ..cubicTo(2, 128, 14, 146, 34, 146)
    ..cubicTo(48, 146, 56, 136, 64, 122)
    ..lineTo(76, 102)
    ..cubicTo(80, 96, 86, 94, 92, 94)
    ..lineTo(148, 94)
    ..cubicTo(154, 94, 160, 96, 164, 102)
    ..lineTo(176, 122)
    ..cubicTo(184, 136, 192, 146, 206, 146)
    ..cubicTo(226, 146, 238, 128, 232, 104)
    ..lineTo(216, 44)
    ..cubicTo(210, 28, 200, 20, 180, 20)
    ..close();

  static Path _rrect(double l, double t, double r, double b, double radius) =>
      Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)));

  static Path _circle(double x, double y, double radius) =>
      Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: radius));

  /// Each part: its outline and, for a stick, the cap inside it.
  static final Map<GamepadPart, _Piece> _pieces = {
    GamepadPart.leftTrigger: _Piece(_rrect(52, -4, 82, 6, 5)),
    GamepadPart.rightTrigger: _Piece(_rrect(158, -4, 188, 6, 5)),
    GamepadPart.leftBumper: _Piece(_rrect(46, 10, 88, 17, 3.5)),
    GamepadPart.rightBumper: _Piece(_rrect(152, 10, 194, 17, 3.5)),
    GamepadPart.back: _Piece(_circle(104, 38, 5.5)),
    GamepadPart.start: _Piece(_circle(136, 38, 5.5)),
    GamepadPart.dpadUp: _Piece(_rrect(46, 38, 58, 52, 2)),
    GamepadPart.dpadDown: _Piece(_rrect(46, 64, 58, 78, 2)),
    GamepadPart.dpadLeft: _Piece(_rrect(32, 52, 46, 64, 2)),
    GamepadPart.dpadRight: _Piece(_rrect(58, 52, 72, 64, 2)),
    GamepadPart.leftStick: _Piece(_circle(88, 82, 11), _circle(88, 82, 5.5)),
    GamepadPart.rightStick: _Piece(_circle(152, 82, 11), _circle(152, 82, 5.5)),
    GamepadPart.faceTop: _Piece(_circle(186, 42, 7)),
    GamepadPart.faceRight: _Piece(_circle(200, 56, 7)),
    GamepadPart.faceLeft: _Piece(_circle(172, 56, 7)),
    GamepadPart.faceBottom: _Piece(_circle(186, 70, 7)),
  };

  /// The square at the middle of the d-pad, which no step asks for.
  static final Path _dpadCentre = _rrect(46, 52, 58, 64, 2);

  /// The home button, which no step asks for either.
  static final Path _home = _circle(120, 60, 4);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / world.width,
      size.height / world.height,
    );
    if (scale <= 0) return;
    canvas.save();
    canvas.translate(
      (size.width - world.width * scale) / 2,
      (size.height - world.height * scale) / 2,
    );
    canvas.scale(scale);
    canvas.translate(0, _top);

    // A line is the same width on any size of the drawing.
    final width = _line / scale;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round;

    // The body, then what no step asks for, then the parts.
    canvas.drawPath(
      _body,
      Paint()..color = AppColors.text.withValues(alpha: 0.04),
    );
    canvas.drawPath(_body, stroke..color = AppColors.decal);
    stroke.color = AppColors.trace;
    canvas.drawPath(_dpadCentre, stroke);
    canvas.drawPath(_home, stroke);
    for (final entry in _pieces.entries) {
      if (entry.key == highlight) continue;
      canvas.drawPath(entry.value.outline, stroke);
      final cap = entry.value.cap;
      if (cap != null) canvas.drawPath(cap, stroke);
    }

    _drawLit(canvas, _pieces[highlight]!, stroke);
    canvas.restore();
  }

  /// The lit part: a glow that pulses behind it, then the part itself in amber.
  void _drawLit(Canvas canvas, _Piece piece, Paint stroke) {
    final bounds = piece.outline.getBounds();
    final strength = 1 - (1 - _dimmest) * pulse.value;

    // An ellipse of light a little wider than the part, from amber at the
    // centre to nothing at the edge.
    canvas.save();
    canvas.translate(bounds.center.dx, bounds.center.dy);
    canvas.scale(bounds.width / 2 + 11, bounds.height / 2 + 11);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.amber.withValues(alpha: 0.7 * strength),
            AppColors.amber.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1)),
    );
    canvas.restore();

    final cap = piece.cap;
    if (cap == null) {
      canvas.drawPath(piece.outline, Paint()..color = AppColors.amber);
      canvas.drawPath(piece.outline, stroke..color = AppColors.amber);
    } else {
      // A stick: the ring faintly filled, the cap solid.
      canvas.drawPath(
        piece.outline,
        Paint()..color = AppColors.amber.withValues(alpha: 0.16),
      );
      canvas.drawPath(piece.outline, stroke..color = AppColors.amber);
      canvas.drawPath(cap, Paint()..color = AppColors.amber);
    }
  }

  @override
  bool shouldRepaint(GamepadPainter old) =>
      old.highlight != highlight || old.pulse != pulse;
}

/// One part of the controller: its outline, and the cap inside it if it is a
/// stick.
class _Piece {
  const _Piece(this.outline, [this.cap]);

  final Path outline;
  final Path? cap;
}
