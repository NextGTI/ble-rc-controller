import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// The small "working on it" indicator: a ring of 10 with a quarter of it
/// amber, turning once a second. It stands still with the system's "reduce
/// motion" on.
///
/// [label] is what a screen reader says for it (the ring itself is a drawing);
/// without one the ring is left out of the semantics, for a ring that has the
/// words that say the same beside it. It sits in its own repaint boundary, so
/// its turning does not repaint what is around it.
class RingSpinner extends StatefulWidget {
  const RingSpinner({super.key, this.label});

  final String? label;

  @override
  State<RingSpinner> createState() => _RingSpinnerState();
}

class _RingSpinnerState extends State<RingSpinner>
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
        child: RepaintBoundary(
          child: RotationTransition(
            turns: _turn,
            child: const SizedBox(
              width: 10,
              height: 10,
              child: CustomPaint(painter: _RingPainter()),
            ),
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
