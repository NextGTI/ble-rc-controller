import 'package:flutter/material.dart';

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

/// A pill that lights up while an input is active.
class StatePill extends StatelessWidget {
  const StatePill({super.key, required this.label, required this.on, this.color});

  final String label;
  final bool on;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = on ? (color ?? Colors.green.shade500) : scheme.onSurface.withValues(alpha: 0.07);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(99)),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: on ? Colors.black : scheme.onSurface.withValues(alpha: 0.6),
        ),
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
