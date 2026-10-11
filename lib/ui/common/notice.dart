import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'glass.dart';

/// An amber card with a title, an explanation and up to two text actions
/// (spec 4.8). It sits at the top of a screen to say what needs attention.
///
/// The explanation and an action show only when given: a notice whose title
/// says it all ("The car disconnected.") has no [body].
class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.title,
    this.body,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String? body;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final hasActions = primaryLabel != null || secondaryLabel != null;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Glass(
        active: true,
        padding: EdgeInsets.fromLTRB(16, 14, 16, hasActions ? 4 : 14),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppType.body(size: 15).copyWith(color: AppColors.amber),
              ),
              if (body != null) ...[
                const SizedBox(height: 4),
                Text(
                  body!,
                  style: AppType.body(size: 13.5)
                      .copyWith(color: AppColors.text2),
                ),
              ],
              if (hasActions)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      children: [
                        if (secondaryLabel != null)
                          _NoticeAction(
                            label: secondaryLabel!,
                            color: AppColors.text2,
                            onTap: onSecondary,
                          ),
                        if (primaryLabel != null)
                          _NoticeAction(
                            label: primaryLabel!,
                            color: AppColors.amber,
                            onTap: onPrimary,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeAction extends StatelessWidget {
  const _NoticeAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: AppType.body(size: 13.5),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(label),
    );
  }
}
