import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/tokens.dart';

/// A live signal (a trigger, a stick axis): its name, a thin amber bar that
/// fills with [value], and the value with two decimals in the language of the
/// app (spec 4.8).
///
/// [value] is limited to 0..1 before it is drawn or written.
///
/// The name takes the room it needs, up to 96. A list of meters gives every
/// one the same [labelWidth] instead, so the bars start in the same place
/// whatever the names are; a longer name is cut with an ellipsis.
class SignalMeter extends StatelessWidget {
  const SignalMeter({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth,
  });

  final String label;
  final double value;

  /// The fixed width of the name; null lets it be as wide as it is.
  final double? labelWidth;

  /// One format for each language, made once: a meter is rebuilt at every
  /// signal of a controller, which is many times a second.
  static final Map<String, NumberFormat> _formats = {};

  /// [value] limited to 0..1. A NaN counts as 0, and so does a negative zero
  /// (which would be written "-0,00").
  static double clamp01(double value) {
    if (value.isNaN || value <= 0) return 0;
    return value >= 1 ? 1 : value;
  }

  @override
  Widget build(BuildContext context) {
    final v = clamp01(value);
    final locale = Localizations.localeOf(context).toString();
    final text = _formats
        .putIfAbsent(locale, () => NumberFormat('0.00', locale))
        .format(v);
    final name = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppType.body(size: 12).copyWith(color: AppColors.text2),
    );
    return Semantics(
      label: label,
      value: text,
      excludeSemantics: true,
      child: Row(
        children: [
          if (labelWidth != null)
            SizedBox(width: labelWidth, child: name)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 24, maxWidth: 96),
              child: name,
            ),
          const SizedBox(width: 10),
          Expanded(child: _Bar(fraction: v)),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppType.numeric(size: 14).copyWith(color: AppColors.text),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 3,
        child: ColoredBox(
          color: AppColors.traceWeak,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              heightFactor: 1,
              child: const ColoredBox(color: AppColors.amber),
            ),
          ),
        ),
      ),
    );
  }
}
