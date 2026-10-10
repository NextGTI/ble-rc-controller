import 'package:flutter/material.dart';

import 'motion.dart';

/// Signal strength as four rising bars.
class SignalBars extends StatelessWidget {
  const SignalBars({super.key, required this.level});

  final int level; // 1..4

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 4; i++)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Container(
              width: 4,
              height: 4.0 + i * 3,
              decoration: BoxDecoration(
                color: i <= level ? on : on.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
      ],
    );
  }
}

/// A pill that lights up (and pops slightly) while an input is active.
class StatePill extends StatelessWidget {
  const StatePill({super.key, required this.label, required this.on, this.color, this.icon});

  final String label;
  final bool on;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = on ? (color ?? Colors.green.shade500) : scheme.onSurface.withValues(alpha: 0.07);
    final fg = on ? Colors.black : scheme.onSurface.withValues(alpha: 0.6);
    return AnimatedScale(
      scale: on ? 1.06 : 1,
      duration: motion(context, 140),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: motion(context, 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: fg)),
        ]),
      ),
    );
  }
}

/// The car icon: bobs while driving and leans into turns.
class DrivingCar extends StatefulWidget {
  const DrivingCar({super.key, required this.moving, required this.steer, this.size = 34, this.color});

  final bool moving;

  /// -1 left, 0 straight, +1 right.
  final int steer;
  final double size;
  final Color? color;

  @override
  State<DrivingCar> createState() => _DrivingCarState();
}

class _DrivingCarState extends State<DrivingCar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));

  void _sync() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (widget.moving && !reduce) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.animateTo(0, duration: const Duration(milliseconds: 160));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(DrivingCar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: widget.steer * 0.018,
      duration: motion(context, 160),
      curve: Curves.easeOut,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) =>
            Transform.translate(offset: Offset(0, -2.5 * Curves.easeInOut.transform(_c.value)), child: child),
        child: Icon(Icons.directions_car_filled, size: widget.size, color: widget.color),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: padding, child: SizedBox(width: double.infinity, child: child)),
    );
  }
}

class Notice extends StatelessWidget {
  const Notice({super.key, required this.title, required this.body, this.icon});

  final String title;
  final String body;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, size: 28),
          if (icon != null) const SizedBox(height: 8),
          Text(title, style: t.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: t.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }
}
