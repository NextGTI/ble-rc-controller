import 'package:flutter/widgets.dart';

import '../../core/protocol.dart';
import '../../l10n/gen/app_localizations.dart';
import '../theme/tokens.dart';

/// How far the amber bar of the throttle scale goes for [c] (spec 4.3): 1 (the
/// top) with turbo, 0.72 going forward, -0.6 (below the middle) in reverse and
/// 0 otherwise. The throttle is all or nothing, so these are the only heights.
///
/// Turbo wins over forward, and forward over reverse.
double throttleFill(CarCommand c) {
  if (c.turbo) return 1.0;
  if (c.forward) return 0.72;
  if (c.reverse) return -0.6;
  return 0.0;
}

/// The vertical throttle scale to the right of the car (spec 4.3): 17 marks
/// with "frente" at the top and "ré" at the bottom, and an amber bar that
/// starts at the middle and goes up (forward, turbo) or down (reverse). With
/// turbo it also lights a marker and the word "turbo" at the top, in amber.
///
/// The bar eases to its new height in `AppMotion.state`; with the system's
/// "reduce motion" on it jumps.
///
/// The scale has the fixed proportions of [designSize] and scales down,
/// keeping them, to fit a smaller box. The glow of the bar is painted outside
/// the box on purpose, so the box must not clip it.
class ThrottleScale extends StatelessWidget {
  const ThrottleScale({super.key, required this.command});

  final CarCommand command;

  /// Natural size, in logical pixels.
  static const Size designSize = Size(92, 200);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final labelStyle = AppType.body(size: 10).copyWith(color: AppColors.text3);
    final String? state = command.turbo
        ? l.scaleTurbo
        : command.forward
        ? l.scaleForward
        : command.reverse
        ? l.scaleReverse
        : null;
    return Semantics(
      label: state ?? '',
      excludeSemantics: true,
      child: FittedBox(
        child: SizedBox.fromSize(
          size: designSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: throttleFill(command)),
                  duration: reduceMotion ? Duration.zero : AppMotion.state,
                  curve: Curves.easeOutCubic,
                  builder: (context, fill, _) => CustomPaint(
                    painter: ThrottleScalePainter(
                      fill: fill,
                      turbo: command.turbo,
                    ),
                  ),
                ),
              ),
              // "frente" over the top mark and "ré" under the bottom one,
              // centred on the column of marks.
              _Slot(
                left: 16,
                top: 2,
                width: 66,
                alignment: Alignment.center,
                text: l.scaleForward,
                style: labelStyle,
              ),
              _Slot(
                left: 16,
                top: 186,
                width: 66,
                alignment: Alignment.center,
                text: l.scaleReverse,
                style: labelStyle,
              ),
              // "turbo" beside the top mark, next to the marker.
              if (command.turbo)
                _Slot(
                  left: 0,
                  top: 20,
                  width: 30,
                  alignment: Alignment.centerRight,
                  text: l.scaleTurbo,
                  style: labelStyle.copyWith(color: AppColors.amber),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A line of text in a fixed slot of the scale. It keeps its size when the
/// system enlarges text (the scale is a drawing), and shrinks instead of
/// spilling over when a language needs more room ("marcha atrás").
class _Slot extends StatelessWidget {
  const _Slot({
    required this.left,
    required this.top,
    required this.width,
    required this.alignment,
    required this.text,
    required this.style,
  });

  final double left;
  final double top;
  final double width;
  final Alignment alignment;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    width: width,
    height: 14,
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

/// Draws the marks, the bar and the turbo marker in the space of
/// [ThrottleScale.designSize].
///
/// [fill] is the height of the bar now, from -0.6 to 1 (it eases, so it is
/// often in between): positive goes up from the middle, negative goes down.
@visibleForTesting
class ThrottleScalePainter extends CustomPainter {
  const ThrottleScalePainter({required this.fill, required this.turbo});

  final double fill;
  final bool turbo;

  /// Left edge of the marks.
  static const double markX = 44;

  /// Height of the top mark, of the bottom mark and of the middle, and the
  /// distance from the middle to either end.
  static const double top = 26;
  static const double bottom = 176;
  static const double middle = (top + bottom) / 2;
  static const double reach = (bottom - top) / 2;

  /// Number of marks: the ends and the middle are the longer ones.
  static const int markCount = 17;

  static Paint _glow(double width) => Paint()
    ..color = AppColors.amber
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4);

  @override
  void paint(Canvas canvas, Size size) {
    final major = Paint()
      ..color = AppColors.trace
      ..strokeWidth = 1;
    final minor = Paint()
      ..color = AppColors.traceWeak
      ..strokeWidth = 1;
    for (var i = 0; i < markCount; i++) {
      final y = top + i * (bottom - top) / (markCount - 1);
      final isMajor = i % 8 == 0;
      canvas.drawLine(
        Offset(markX, y),
        Offset(markX + (isMajor ? 10 : 6), y),
        isMajor ? major : minor,
      );
    }

    // The bar, from the middle: up for a positive fill, down for a negative.
    if (fill != 0) {
      final end = middle - reach * fill;
      final bar = RRect.fromLTRBR(
        markX - 4,
        fill > 0 ? end : middle,
        markX - 1.5,
        fill > 0 ? middle : end,
        const Radius.circular(1),
      );
      canvas.drawRRect(
        bar,
        Paint()
          ..color = AppColors.amber
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
      );
      canvas.drawRRect(bar, Paint()..color = AppColors.amber);
    }

    if (turbo) {
      final from = Offset(markX - 8, top);
      final to = Offset(markX + 14, top);
      canvas.drawLine(from, to, _glow(1.5));
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = AppColors.amber
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(ThrottleScalePainter old) =>
      old.fill != fill || old.turbo != turbo;
}
