import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/gen/app_localizations.dart';
import '../common/amber_switch.dart';
import '../common/settings_row.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'about_page.dart';
import 'bindings_page.dart';
import 'controllers_page.dart';
import 'language_page.dart';
import 'page_frame.dart';

/// The smallest and the largest dead zone the slider offers, and the step
/// between two values (spec 5.4: 10% to 60%).
const double deadzoneMin = 0.10;
const double deadzoneMax = 0.60;
const int deadzoneSteps = 10;

/// The screen behind the gear (spec 5.4): Commands, Driving and App, each a
/// group of rows that say what they do.
///
/// A row that leads to another screen asks [open] to show it, so the shell
/// decides where it goes: a new route on a phone or tablet, a swap inside the
/// side panel on a desktop. The rest are settings of the `Driver`, which the
/// rows read and change.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.open});

  final void Function(Widget page) open;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Looked up once; the package keeps the answer, so this is cheap.
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final controllers = driver.controllers;

    return SettingsFrame(
      title: l.settingsTitle,
      root: true,
      children: [
        SettingsGroup(
          title: l.groupCommands,
          rows: [
            SettingsRow(
              title: l.bindingsTitle,
              subtitle: l.bindingsHint,
              trailing: const SettingsChevron(),
              onTap: () => widget.open(const BindingsPage()),
            ),
            SettingsRow(
              title: l.controllersTitle,
              subtitle: controllers.isEmpty
                  ? l.noControllerShort
                  : controllers.first.name,
              trailing: const SettingsChevron(),
              onTap: () => widget.open(ControllersPage(open: widget.open)),
            ),
            // The switch is the only target of this row: with a tap on the row
            // as well, one touch would flip it twice.
            SettingsRow(
              title: l.onScreen,
              subtitle: l.onScreenHint,
              trailing: AmberSwitch(
                value: driver.onScreenControls,
                onChanged: (v) => driver.onScreenControls = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SettingsGroup(
          title: l.groupDriving,
          rows: [
            const _DeadzoneRow(),
            SettingsRow(
              title: l.rememberLast,
              trailing: AmberSwitch(
                value: driver.autoConnect,
                onChanged: (v) => driver.autoConnect = v,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SettingsGroup(
          title: l.groupApp,
          rows: [
            SettingsRow(
              title: l.language,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      languageName(l, driver.localeCode),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const SettingsChevron(),
                ],
              ),
              onTap: () => widget.open(const LanguagePage()),
            ),
            FutureBuilder<PackageInfo>(
              future: _info,
              builder: (context, snapshot) {
                final version = versionOf(snapshot.data);
                return SettingsRow(
                  title: l.aboutTitle,
                  subtitle: version == null ? null : l.aboutHint(version),
                  trailing: const SettingsChevron(),
                  onTap: () => widget.open(const AboutPage()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// The dead zone of the stick: a row like the others, with the value on the
/// right, and under it the slider that sets it.
///
/// A screen reader meets one control: the title, what it does, and the slider
/// with its value (the percentage written on the right is left out of the
/// reading, since the slider says it).
class _DeadzoneRow extends StatelessWidget {
  const _DeadzoneRow();

  static String _percent(double v) => '${(v * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final value = driver.deadzone;
    final theme = SliderTheme.of(context);

    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsRow(
            title: l.deadzoneTitle,
            subtitle: l.deadzoneHint,
            // The text tells the real value of the driver, even one that the
            // slider cannot show (the old slider went up to 70%).
            trailing: ExcludeSemantics(child: Text(_percent(value))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: SliderTheme(
              data: theme.copyWith(
                trackHeight: 4,
                activeTrackColor: AppColors.amber,
                inactiveTrackColor: AppColors.traceWeak,
                thumbColor: AppColors.amber,
                overlayColor: AppColors.amber.withValues(alpha: 0.12),
                activeTickMarkColor: AppColors.bg.withValues(alpha: 0.6),
                inactiveTickMarkColor: AppColors.trace,
              ),
              child: Slider(
                value: value.clamp(deadzoneMin, deadzoneMax),
                min: deadzoneMin,
                max: deadzoneMax,
                divisions: deadzoneSteps,
                semanticFormatterCallback: _percent,
                // Two decimals: the sum of steps of 0.05 is never exact.
                onChanged: (v) => driver.deadzone = (v * 100).round() / 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
