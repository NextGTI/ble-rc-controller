import 'package:flutter/material.dart';

import '../../core/car_transport.dart';
import '../../core/driver.dart';
import '../../l10n/gen/app_localizations.dart';
import '../cockpit/car_decal.dart';
import '../common/amber_switch.dart';
import '../common/glass.dart';
import '../common/notice.dart';
import '../strings.dart';
import '../theme/tokens.dart';

/// The cars in range, one glass row each, in the order of `Driver.cars`
/// (spec 4.8). The sheet on a phone and the column on a desktop both show it.
///
/// A row has the car icon, its name, the four signal bars and one button:
/// - the connected car is the active row (amber), says "Connected" with the
///   battery when it is known, and offers "Disconnect";
/// - a car being connected says so and offers "Cancel";
/// - any other car offers "Connect" while the link is idle and "Switch"
///   while another car is connected or being connected. Both connect to it.
///
/// A connection that failed puts a [Notice] above the rows (spec 5.2) with
/// "Try again" and "Close".
///
/// The list reads the driver, so it needs a `DriverScope` above it.
class CarList extends StatelessWidget {
  const CarList({super.key});

  /// Space between rows, and between the notice and the first row.
  static const double gap = 4;

  /// The cars to show: those the scan found plus the one the link is on. A
  /// car that stopped advertising is pruned from the scan, and when a retry
  /// brings it back the driver keeps it only as `connectedCar`.
  static List<FoundCar> _shown(Driver driver) {
    final cars = driver.cars;
    final linked = driver.connectedCar;
    if (linked == null || cars.any((c) => c.id == linked.id)) return cars;
    return [...cars, linked]..sort((a, b) => a.name.compareTo(b.name));
  }

  static String _signalText(AppLocalizations l, SignalStrength s) {
    switch (s) {
      case SignalStrength.strong:
        return l.signalStrong;
      case SignalStrength.medium:
        return l.signalMedium;
      case SignalStrength.weak:
        return l.signalWeak;
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final failed = ConnectFailedNotice.carOf(driver);
    final cars = _shown(driver);

    Widget row(FoundCar car) {
      final here = driver.carId == car.id;
      final connected = here && driver.link == LinkState.connected;
      final connecting = here && driver.link == LinkState.connecting;
      final battery = driver.battery;
      return _CarRow(
        model: car.model,
        level: car.signalLevel,
        connected: connected,
        subtitle: connected
            ? (battery == null
                  ? l.connectedLabel
                  : '${l.connectedLabel} · $battery%')
            : connecting
            ? l.statusConnecting
            : _signalText(l, car.signalStrength),
        buttonLabel: connected
            ? l.disconnect
            : connecting
            ? l.cancel
            : driver.link == LinkState.idle
            ? l.actionConnect
            : l.actionSwitch,
        quietButton: here,
        onButton: here ? driver.disconnect : () => driver.connect(car.id),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (failed != null)
          Padding(
            padding: const EdgeInsets.only(bottom: gap * 2),
            child: ConnectFailedNotice(car: failed),
          ),
        for (var i = 0; i < cars.length; i++)
          // Keyed by car, so a row keeps its fade when the order changes.
          Padding(
            key: ValueKey(cars[i].id),
            padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
            child: row(cars[i]),
          ),
      ],
    );
  }
}

/// The notice of a connection that failed (spec 5.2): which car it was, the
/// likeliest cause, and "Try again" (connects to [car] again) and "Close".
///
/// The list of cars shows it above the rows; a screen with no list to put it
/// on shows it by itself. It reads the driver.
class ConnectFailedNotice extends StatelessWidget {
  const ConnectFailedNotice({super.key, required this.car});

  final FoundCar car;

  /// The car whose connection failed while that is what the driver has to
  /// say, or null.
  static FoundCar? carOf(Driver driver) =>
      driver.message == MessageKind.connectFailed ? driver.failedCar : null;

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    return Notice(
      title: l.connectFailedTitle(car.model),
      body: l.connectFailedBody,
      primaryLabel: l.retry,
      onPrimary: () => driver.connect(car.id),
      secondaryLabel: l.close,
      onSecondary: driver.dismissMessage,
    );
  }
}

/// "Reconnect to the last car" and its switch, in one glass bar (the foot of
/// the sheet and of the column). It reads and sets `Driver.autoConnect`.
///
/// Only the switch toggles. For screen readers the label and the switch are
/// one control, so the switch is named.
class AutoConnectToggle extends StatelessWidget {
  const AutoConnectToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    return Glass(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
      child: MergeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l.rememberLast,
                  style: AppType.body(size: 13).copyWith(color: AppColors.text),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AmberSwitch(
              value: driver.autoConnect,
              onChanged: (v) => driver.autoConnect = v,
            ),
          ],
        ),
      ),
    );
  }
}

/// The four bars of a car's signal (spec 4.8): the first [level] are lit and
/// the rest dim. They rise from 4 to 11 high.
///
/// Screen readers get the signal from the text beside the bars, so these are
/// left out of the semantics.
class SignalBars extends StatelessWidget {
  const SignalBars({super.key, required this.level});

  /// 0 to 4.
  final int level;

  static const List<double> _heights = [4, 7, 9, 11];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: _heights.last,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _heights.length; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                child: SizedBox(
                  width: 2.5,
                  height: _heights[i],
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: i < level ? AppColors.text2 : AppColors.traceWeak,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CarRow extends StatelessWidget {
  const _CarRow({
    required this.model,
    required this.level,
    required this.connected,
    required this.subtitle,
    required this.buttonLabel,
    required this.quietButton,
    required this.onButton,
  });

  final String model;
  final int level;
  final bool connected;
  final String subtitle;
  final String buttonLabel;

  /// The button is a neutral outline, not the amber main action (Disconnect,
  /// Cancel).
  final bool quietButton;
  final VoidCallback onButton;

  static const double _iconWidth = 26;
  static const double _iconHeight = 34;

  @override
  Widget build(BuildContext context) {
    return Glass(
      active: connected,
      radius: 14,
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      // The glass fades its fill and outline between idle and active. The
      // icon and the texts fade in step with it, from their own idle colour
      // (not from the default text colour); the halo comes from the glass.
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: connected ? 1 : 0),
        duration: Glass.timeOf(context),
        curve: Glass.curve,
        builder: (context, t, _) {
          Color toward(Color idle) => Color.lerp(idle, AppColors.amber, t)!;
          return Row(
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: _iconWidth,
                  height: _iconHeight,
                  child: CarDecal(
                    variant: DecalVariant.icon,
                    iconColor: toward(AppColors.trace),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      model,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.numeric(size: 16)
                          .copyWith(color: toward(AppColors.text)),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // The halo of an active glass is for the name.
                      style: AppType.body(size: 10.5).copyWith(
                        color: toward(AppColors.text3),
                        shadows: const [],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // The signal was read from the advert, before the link. Once
              // connected the car does not advertise, so the bars would show
              // a number that never changes; the row says "Connected".
              if (!connected) ...[
                SignalBars(level: level),
                const SizedBox(width: 4),
              ],
              _RowButton(
                label: buttonLabel,
                car: model,
                quiet: quietButton,
                onTap: onButton,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The button at the end of a row: a small pill inside a target of at least
/// 48 by 48. Amber for the main action (Connect, Switch), a neutral outline
/// for leaving (Disconnect, Cancel).
class _RowButton extends StatelessWidget {
  const _RowButton({
    required this.label,
    required this.car,
    required this.quiet,
    required this.onTap,
  });

  final String label;

  /// The car it acts on, so a screen reader can tell the buttons apart.
  final String car;
  final bool quiet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, $car',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: Glass.minTarget,
              minHeight: Glass.minTarget,
            ),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: quiet ? null : AppColors.amber.withValues(alpha: 0.08),
                  border: Border.all(
                    color: quiet
                        ? AppColors.traceWeak
                        : AppColors.amber.withValues(alpha: 0.45),
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppType.body(size: 11).copyWith(
                      color: quiet ? AppColors.text : AppColors.amber,
                      shadows: const [],
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
