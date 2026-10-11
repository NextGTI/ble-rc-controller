import 'package:flutter/material.dart';

import '../../core/driver.dart';
import '../../l10n/gen/app_localizations.dart';
import '../common/glass.dart';
import '../common/metal_text.dart';
import '../common/ring_spinner.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'cockpit_states.dart';

/// The top of the cockpit (spec 5.2): on the left the name of the car in metal
/// text and, under it, what the app is doing; on the right the battery, while
/// a car is connected (and Bluetooth is up), and the gear that opens the
/// settings.
///
/// The name is the model of the car that is connected or being connected, the
/// lost one while the app waits to reconnect to it, and "No car" otherwise.
/// The line under it is the state `panelStateOf` gives, the one the cockpit
/// chooses its screen by, so the two always agree:
/// 1. Bluetooth not ready: its title ("Bluetooth is off", "Bluetooth is
///    blocked" or "Bluetooth LE is unavailable"), with an unlit dot;
/// 2. connecting: "Connecting", with a turning ring;
/// 3. connected: "Connected", with a lit amber dot;
/// 4. waiting to reconnect: "Reconnecting", with a turning ring;
/// 5. otherwise "Searching", with a turning ring. This includes the instant
///    at start-up before Bluetooth has said anything.
///
/// With [onCarTap] the name and the line under it are a button (the phone and
/// the tablet open the sheet of cars from it); without, they are plain text.
/// The gear calls [onSettings].
///
/// Sizes follow spec 3.2: the name 42 and the battery 36 in the phone layouts,
/// 56 and 44 on the desktop. It needs a `DriverScope` above it.
class CockpitHeader extends StatelessWidget {
  const CockpitHeader({super.key, required this.onSettings, this.onCarTap});

  final VoidCallback onSettings;
  final VoidCallback? onCarTap;

  /// The words under the name for [state] (the ring or the dot is the block's).
  static String _statusOf(Driver d, PanelState state, AppLocalizations l) =>
      switch (state) {
        PanelState.bluetooth => bluetoothTitle(l, bluetoothBlockOf(d)!),
        PanelState.connecting => l.statusConnecting,
        PanelState.connected => l.connectedLabel,
        PanelState.lost => l.statusReconnecting,
        PanelState.searching => l.statusSearching,
      };

  static String _nameOf(Driver d, AppLocalizations l) {
    final car = d.link == LinkState.idle ? d.lostCar : d.connectedCar;
    return car?.model ?? l.noCarShort;
  }

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final desktop = layoutFor(MediaQuery.sizeOf(context)) == LayoutKind.desktop;
    final state = panelStateOf(driver);
    final battery = state == PanelState.connected ? driver.battery : null;
    final gap = desktop ? 22.0 : 10.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _CarBlock(
              name: _nameOf(driver, l),
              status: _statusOf(driver, state, l),
              // A ring while the app is at work, a lit dot when connected, an
              // unlit one when Bluetooth is the problem.
              working:
                  state == PanelState.connecting ||
                  state == PanelState.lost ||
                  state == PanelState.searching,
              lit: state == PanelState.connected,
              // The car that was lost is the name of a car that is not there.
              dimName: state == PanelState.lost,
              nameSize: desktop ? 56 : 42,
              statusSize: desktop ? 12.5 : 12,
              onTap: onCarTap,
            ),
          ),
        ),
        if (battery != null) ...[
          SizedBox(width: gap),
          _Battery(level: battery, size: desktop ? 44 : 36),
        ],
        SizedBox(width: gap),
        _GearButton(onTap: onSettings),
      ],
    );
  }
}

/// The name and the line under it, one control for a screen reader.
class _CarBlock extends StatelessWidget {
  const _CarBlock({
    required this.name,
    required this.status,
    required this.working,
    required this.lit,
    required this.dimName,
    required this.nameSize,
    required this.statusSize,
    required this.onTap,
  });

  final String name;
  final String status;

  /// Whether the app is at work (a ring) and whether the dot is lit.
  final bool working;
  final bool lit;

  /// Whether the name is shown faded (the car is gone, for now).
  final bool dimName;
  final double nameSize;
  final double statusSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget block = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: dimName ? 0.6 : 1,
          child: MetalText(
            name,
            // Saira is tall for its size (1.57 em a line): a line of 1.1 keeps
            // the accents of the capitals inside the box the metal gradient is
            // laid on, and the name close to the line under it.
            style: AppType.numeric(size: nameSize)
                .copyWith(height: 1.1, letterSpacing: 0.2),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              child: Center(
                // The words beside the ring say what it says.
                child: working ? const RingSpinner() : _Dot(lit: lit),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.body(size: statusSize)
                    .copyWith(color: AppColors.text2),
              ),
            ),
          ],
        ),
      ],
    );

    if (onTap != null) {
      block = Semantics(
        button: true,
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
              child: block,
            ),
          ),
        ),
      );
    }
    return MergeSemantics(child: block);
  }
}

/// The 5 px dot before the status: amber with a glow when it is lit, the grey
/// of the traces when it is not.
class _Dot extends StatelessWidget {
  const _Dot({required this.lit});

  final bool lit;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: lit ? AppColors.amber : AppColors.trace,
          boxShadow: lit
              ? [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.8),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: const SizedBox.square(dimension: 5),
      ),
    );
  }
}

/// The charge, "80%" in metal text over a small "battery".
class _Battery extends StatelessWidget {
  const _Battery({required this.level, required this.size});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: '$level% ${l.batteryLabel}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              MetalText(
                '$level',
                style: AppType.numeric(size: size).copyWith(height: 1),
              ),
              const SizedBox(width: 2),
              // The percent sign is 4/9 of the figure (16 against 36).
              MetalText(
                '%',
                style: AppType.numeric(size: size * 4 / 9).copyWith(height: 1),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.batteryLabel,
            maxLines: 1,
            style: AppType.body(size: 11).copyWith(color: AppColors.text3),
          ),
        ],
      ),
    );
  }
}

/// The gear: a glass square of 36 inside a target of 48.
class _GearButton extends StatelessWidget {
  const _GearButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).settingsTitle;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox.square(
              dimension: Glass.minTarget,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.glass,
                    border: Border.all(color: AppColors.glassEdge),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const SizedBox.square(
                    dimension: 36,
                    child: Icon(
                      Icons.settings_outlined,
                      size: 18,
                      color: AppColors.text2,
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
