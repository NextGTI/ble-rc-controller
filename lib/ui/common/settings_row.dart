import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'glass.dart';

/// A titled block of settings: a small label on top and the rows inside one
/// glass surface, with a hairline between them (spec 4.8).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: AppType.body(size: 12).copyWith(color: AppColors.text3),
            ),
          ),
        ),
        Glass(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: SizedBox(
                      height: 1,
                      width: double.infinity,
                      child: ColoredBox(color: AppColors.glassEdge),
                    ),
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One setting: a title, a short line saying what it does and, on the right,
/// whatever [trailing] is (a value, an `AmberSwitch`, a "›").
///
/// With [onTap] the whole row is a button. A row is never shorter than 56.
/// For screen readers the row is a single control: title, subtitle and
/// [trailing] are merged, so an `AmberSwitch` is named by the title.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  static const double minHeight = 56;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppType.body(size: 15)
                        .copyWith(color: AppColors.text),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: AppType.body(size: 12)
                            .copyWith(color: AppColors.text2),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: DefaultTextStyle.merge(
                  style: AppType.body(size: 13.5)
                      .copyWith(color: AppColors.text2),
                  child: trailing!,
                ),
              ),
          ],
        ),
      ),
    );
    // One node for the whole row, as a `SwitchListTile` does: the title names
    // the control on the right (a switch has no name of its own) and a value is
    // read with its title.
    return MergeSemantics(
      child: onTap == null
          ? content
          : Semantics(
              button: true,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap, child: content),
              ),
            ),
    );
  }
}
