import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../../core/protocol.dart';
import '../../input/bindings.dart';
import '../../input/input_ref.dart';
import '../../l10n/gen/app_localizations.dart';
import '../strings.dart';
import '../theme/tokens.dart';

/// Most keys the legend shows for one action.
const int _maxKeys = 2;

final Set<int> _arrowUsages = {
  PhysicalKeyboardKey.arrowUp.usbHidUsage,
  PhysicalKeyboardKey.arrowDown.usbHidUsage,
  PhysicalKeyboardKey.arrowLeft.usbHidUsage,
  PhysicalKeyboardKey.arrowRight.usbHidUsage,
};

/// The keys the legend shows for [a]: the keyboard keys bound to it, with the
/// arrows after the others (so the default reads "W ↑" like the approved
/// design, although the arrow is the first binding), and no more than two.
List<InputRef> legendKeys(Bindings b, CarAction a) {
  final keys = keyInputs(b, a);
  return [
    ...keys.where((r) => !_arrowUsages.contains(r.keyUsage)),
    ...keys.where((r) => _arrowUsages.contains(r.keyUsage)),
  ].take(_maxKeys).toList();
}

/// The keys shown for steering: the first key of left and the first key of
/// right ("A D"). Either one is left out if the side has no key.
List<InputRef> steerLegendKeys(Bindings b) => [
  ...legendKeys(b, CarAction.left).take(1),
  ...legendKeys(b, CarAction.right).take(1),
];

/// A row under the instrument with the keys of every action (spec 4.6), taken
/// from the current shortcuts: by default W ↑ forward, S ↓ reverse, A D
/// steering, Space turbo, L light and Q spin. The group of an action that is
/// in the command the car is getting lights up in amber, so it teaches the
/// keys and follows the driving.
///
/// It is not there at all with "Use the keyboard" off, and an action with no
/// key has no group. The groups wrap onto a second line on a narrow window.
class KeyLegend extends StatelessWidget {
  const KeyLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    if (!driver.keyboardEnabled) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final c = driver.command;
    final b = driver.bindings;

    final groups = <(String, List<InputRef>, bool)>[
      (l.actionForward, legendKeys(b, CarAction.forward), c.forward),
      (l.actionReverse, legendKeys(b, CarAction.reverse), c.reverse),
      (l.legendSteer, steerLegendKeys(b), c.left || c.right),
      (l.actionTurbo, legendKeys(b, CarAction.turbo), c.turbo),
      (l.actionLight, legendKeys(b, CarAction.light), c.light),
      (l.actionDonut, legendKeys(b, CarAction.donut), c.donut),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (name, keys, lit) in groups)
          if (keys.isNotEmpty)
            _Group(
              name: name,
              keys: [for (final k in keys) l.keyName(k)],
              lit: lit,
            ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.name, required this.keys, required this.lit});

  final String name;
  final List<String> keys;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.state;
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final k in keys) ...[
            _KeyCap(label: k, lit: lit, duration: duration),
            const SizedBox(width: 6),
          ],
          // Flexible, so a group wider than the row (large text) cuts its name
          // instead of overflowing.
          Flexible(
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: AppType.body(size: 11.5)
                  .copyWith(color: lit ? AppColors.text : AppColors.text3),
              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

/// One key, drawn as a small keycap: light, with a dark line under it. Lit, it
/// is amber with a glow.
class _KeyCap extends StatelessWidget {
  const _KeyCap({
    required this.label,
    required this.lit,
    required this.duration,
  });

  final String label;
  final bool lit;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: lit
              ? AppColors.amber.withValues(alpha: 0.5)
              : AppColors.glassEdge,
        ),
        color: lit ? AppColors.amber.withValues(alpha: 0.12) : null,
        gradient: lit
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(255, 255, 255, 0.06),
                  Color.fromRGBO(255, 255, 255, 0.01),
                ],
              ),
        boxShadow: lit
            ? [
                BoxShadow(
                  color: AppColors.amber.withValues(alpha: 0.25),
                  blurRadius: 12,
                ),
              ]
            : const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.6),
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: AnimatedDefaultTextStyle(
        duration: duration,
        style: AppType.body(size: 11)
            .copyWith(color: lit ? AppColors.amber : AppColors.text2),
        child: Text(label),
      ),
    );
  }
}
