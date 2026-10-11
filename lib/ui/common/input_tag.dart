import 'package:flutter/material.dart';

import '../../input/input_ref.dart';
import '../../l10n/gen/app_localizations.dart';
import '../theme/tokens.dart';

/// The name of one input (a gamepad button, a key or a raw axis) with the icon
/// of its device and, when [onRemove] is given, a "×" to take it off (spec 4.8).
///
/// With [shared] a small amber dot says the same input also drives another
/// action. The tag is 48 high so the "×" has a 48 by 48 target.
class InputTag extends StatelessWidget {
  const InputTag({
    super.key,
    required this.label,
    required this.kind,
    this.shared = false,
    this.onRemove,
  });

  final String label;
  final InputKind kind;
  final bool shared;
  final VoidCallback? onRemove;

  /// Height of the tag, and the side of the remove button.
  static const double target = 48;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final icon = switch (kind) {
      InputKind.key => Icons.keyboard_outlined,
      InputKind.pad || InputKind.raw => Icons.sports_esports_outlined,
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: target),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.glass,
          border: Border.all(color: AppColors.glassEdge),
          borderRadius: BorderRadius.circular(target / 2),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 14, right: onRemove == null ? 14 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.text2),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body(size: 13.5)
                      .copyWith(color: AppColors.text),
                ),
              ),
              if (shared)
                Tooltip(
                  message: l.sharedInput,
                  child: const SizedBox(
                    width: 20,
                    height: target,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(width: 6, height: 6),
                      ),
                    ),
                  ),
                ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  // "Remove W", not just "Remove": a list of tags has a
                  // button for each, and they must be told apart.
                  tooltip: '${l.remove} $label',
                  icon: const Icon(Icons.close, size: 18),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.text2,
                    fixedSize: const Size.square(target),
                    minimumSize: const Size.square(target),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.standard,
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
