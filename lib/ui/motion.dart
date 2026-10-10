import 'package:flutter/material.dart';

/// Animation length that honours the system "reduce motion" setting.
Duration motion(BuildContext context, [int ms = 240]) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : Duration(milliseconds: ms);

/// Fade with a small upward slide; used when swapping pages and cards.
Widget fadeSlide(Widget child, Animation<double> animation) {
  final slide = Tween<Offset>(begin: const Offset(0, .025), end: Offset.zero)
      .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
  return FadeTransition(opacity: animation, child: SlideTransition(position: slide, child: child));
}

/// Keeps the outgoing and incoming child the same size as the parent.
Widget fillStack(Widget? current, List<Widget> previous) =>
    Stack(fit: StackFit.expand, children: [...previous, ?current]);

/// Fades and slides [child] in the first time it is built.
class EntranceAnimation extends StatelessWidget {
  const EntranceAnimation({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final d = motion(context, 360);
    if (d == Duration.zero) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: d + delay,
      curve: Interval(
        delay.inMilliseconds / (d + delay).inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, v, child) =>
          Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: child)),
      child: child,
    );
  }
}

/// Gently pulses its child while visible (used for "waiting for input" hints).
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child});

  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Opacity(opacity: .6 + .4 * Curves.easeInOut.transform(_c.value), child: child),
        child: widget.child,
      );
}

/// [AnimatedSize] that is skipped entirely when the user asked to reduce
/// motion (Flutter's AnimatedSize asserts if given a zero duration).
class SmoothSize extends StatelessWidget {
  const SmoothSize({super.key, required this.child, this.alignment = Alignment.topCenter, this.ms = 220});

  final Widget child;
  final AlignmentGeometry alignment;
  final int ms;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSize(
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
      alignment: alignment,
      child: child,
    );
  }
}
