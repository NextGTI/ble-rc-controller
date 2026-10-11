import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// An on/off switch: amber when on, grey when off (spec 4.8).
///
/// The track is 44 by 26 but the target is 48 by 48. With the system "reduce
/// motion" on, the change is instant.
///
/// It has no name of its own for screen readers. Put it in a `SettingsRow`
/// (which merges its title in), or wrap it together with its label in a
/// `MergeSemantics`.
class AmberSwitch extends StatelessWidget {
  const AmberSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const double _target = 48;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.state;
    const curve = Curves.easeOutCubic;
    void toggle() => onChanged(!value);

    return Semantics(
      toggled: value,
      enabled: true,
      onTap: toggle,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: toggle,
          excludeFromSemantics: true,
          customBorder: const CircleBorder(),
          radius: _target / 2,
          overlayColor: WidgetStatePropertyAll(
            AppColors.amber.withValues(alpha: 0.12),
          ),
          child: SizedBox(
            width: _target,
            height: _target,
            child: Center(
              child: AnimatedContainer(
                duration: duration,
                curve: curve,
                width: 44,
                height: 26,
                decoration: BoxDecoration(
                  color: value ? AppColors.amber : AppColors.traceWeak,
                  border: Border.all(
                    color: value ? AppColors.amber : AppColors.trace,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: AnimatedAlign(
                  duration: duration,
                  curve: curve,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: AnimatedContainer(
                      duration: duration,
                      curve: curve,
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: value ? AppColors.bg : AppColors.text2,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
