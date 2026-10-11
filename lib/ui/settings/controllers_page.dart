import 'package:flutter/material.dart';

import '../../core/driver.dart';
import '../../input/controller_profile.dart';
import '../../l10n/gen/app_localizations.dart';
import '../common/glass.dart';
import '../common/settings_row.dart';
import '../common/signal_meter.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'page_frame.dart';
import 'teach_page.dart';

/// How many live signals the page shows: the strongest.
const int liveSignalCount = 6;

/// The width of the name of a signal, the same for all so the bars line up.
const double _signalLabelWidth = 112;

/// The controllers (spec 5.6): the ones that are connected, each recognised
/// or taught; the signals they send as live meters; and the way to teach the
/// app a controller it does not know.
///
/// The meters are the strongest signals the driver has seen
/// (`driver.rawSignals`), at most [liveSignalCount], the strongest first. A
/// signal that goes the other way (a stick pushed left, a negative value) is
/// as strong as the same push the other way, so it counts and shows as its
/// absolute value. The meters are rebuilt at every new signal
/// (`driver.rawRevision`); nothing else on the page is, since a signal does
/// not change anything else. With no controller connected there are none: the
/// signals still in the driver are the ones of a controller that is gone.
///
/// "Ensinar um controle novo" starts the wizard for the connected controller
/// and asks [open] to show it, so the shell decides where it goes.
class ControllersPage extends StatelessWidget {
  const ControllersPage({super.key, required this.open});

  final void Function(Widget page) open;

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final controllers = driver.controllers;

    return SettingsFrame(
      title: l.controllersTitle,
      children: [
        SettingsGroup(
          title: l.connectedSection,
          rows: controllers.isEmpty
              ? [
                  SettingsRow(
                    title: l.noControllerShort,
                    subtitle: l.noControllerHint,
                  ),
                ]
              : [for (final c in controllers) _ControllerRow(info: c)],
        ),
        const SizedBox(height: 20),
        _SectionTitle(l.liveSignals),
        // Rebuilt at every signal, and only this.
        ValueListenableBuilder<int>(
          valueListenable: driver.rawRevision,
          builder: (context, _, _) {
            final signals = controllers.isEmpty
                ? const <RawSignal>[]
                : strongestSignals(driver.rawSignals.values);
            if (signals.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SettingsCard(
                items: [
                  for (final s in signals)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      child: SignalMeter(
                        label: s.key,
                        value: signalStrength(s),
                        labelWidth: _signalLabelWidth,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
          child: Text(
            l.liveSignalsHint,
            style: AppType.body(size: 13.5)
                .copyWith(color: AppColors.text2, height: 1.5),
          ),
        ),
        _TeachButton(open: open),
      ],
    );
  }
}

/// How strong [s] is, from 0 to 1: its value without the sign. A value that
/// is not a number counts as 0.
double signalStrength(RawSignal s) => SignalMeter.clamp01(s.value.abs());

/// The [liveSignalCount] strongest of [signals], the strongest first; the
/// ones that are as strong in the order of their names.
List<RawSignal> strongestSignals(Iterable<RawSignal> signals) {
  final all = signals.toList()
    ..sort((a, b) {
      final byStrength = signalStrength(b).compareTo(signalStrength(a));
      return byStrength != 0 ? byStrength : a.key.compareTo(b.key);
    });
  return all.length > liveSignalCount ? all.sublist(0, liveSignalCount) : all;
}

/// A small label over a block, as `SettingsGroup` has over its card.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: AppType.body(size: 12).copyWith(color: AppColors.text3),
        ),
      ),
    );
  }
}

/// One connected controller: its name and whether the app recognises it or
/// was taught it. A taught one can be made to forget.
class _ControllerRow extends StatelessWidget {
  const _ControllerRow({required this.info});

  final ControllerInfo info;

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final taught = driver.profiles[info.profileKey]?.isCustom ?? false;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SettingsRow.minHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, taught ? 2 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MergeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      info.name,
                      style: AppType.body(size: 15)
                          .copyWith(color: AppColors.text),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Status(label: taught ? l.taught : l.recognized),
                ],
              ),
            ),
            if (taught)
              TextButton(
                onPressed: () => driver.forgetProfile(info.profileKey),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.text2,
                  textStyle: AppType.body(size: 13.5),
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.only(right: 12),
                  alignment: Alignment.centerLeft,
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: Text(l.forgetTaught),
              ),
          ],
        ),
      ),
    );
  }
}

/// A white dot with a soft halo and the word beside it.
class _Status extends StatelessWidget {
  const _Status({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.text,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.text.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
          child: const SizedBox.square(dimension: 5),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppType.body(size: 12).copyWith(color: AppColors.text2),
        ),
      ],
    );
  }
}

/// "Ensinar um controle novo": starts the wizard for the controller that is
/// connected. With none it is there but still, and the page above says why.
class _TeachButton extends StatelessWidget {
  const _TeachButton({required this.open});

  final void Function(Widget page) open;

  void _teach(BuildContext context) {
    // A touch that comes while the wizard is already on its way in (two
    // before a frame) must not open a second one.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final driver = DriverScope.of(context);
    final controllers = driver.controllers;
    if (controllers.isEmpty) return;
    driver.beginTeaching(controllers.first);
    open(const TeachPage());
  }

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final enabled = driver.controllers.isNotEmpty;

    // One button for a screen reader, named by its words, switched off when
    // there is nothing to teach.
    return Semantics(
      button: true,
      enabled: enabled,
      label: l.teachNew,
      onTap: enabled ? () => _teach(context) : null,
      excludeSemantics: true,
      child: Glass(
        active: enabled,
        radius: 14,
        onTap: enabled ? () => _teach(context) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: Center(
            child: Text(
              l.teachNew,
              textAlign: TextAlign.center,
              // The active glass colours its text amber.
              style: AppType.body(size: 15)
                  .copyWith(color: enabled ? null : AppColors.text3),
            ),
          ),
        ),
      ),
    );
  }
}
