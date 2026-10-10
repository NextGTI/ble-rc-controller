import 'package:flutter/material.dart';

import '../core/driver.dart';
import '../l10n/gen/app_localizations.dart';
import 'motion.dart';
import 'strings.dart';
import 'touch_controls.dart';
import 'widgets.dart';

class DrivePage extends StatelessWidget {
  const DrivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final d = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final cmd = d.command;
    final t = Theme.of(context).textTheme;

    final info = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          child: SmoothSize(
            child: AnimatedSwitcher(
              duration: motion(context, 220),
              transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: KeyedSubtree(key: ValueKey(d.link), child: _connection(context, d, l)),
            ),
          ),
        ),
        SmoothSize(
          child: d.message == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: Text(l.message(d.message!)),
                      trailing: IconButton(icon: const Icon(Icons.close), onPressed: d.dismissMessage),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: motion(context, 220),
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: Icon(
                  Icons.sports_esports,
                  key: ValueKey(d.controllers.isEmpty),
                  size: 32,
                  color: d.controllers.isEmpty ? Theme.of(context).hintColor : Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: motion(context, 220),
                  transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: Column(
                    key: ValueKey(d.controllers.map((c) => c.name).join('|')),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.controllers.isEmpty ? l.noController : d.controllers.map((c) => c.name).join(', '),
                        style: t.titleMedium,
                      ),
                      if (d.controllers.isEmpty)
                        Text(l.noControllerHint, style: t.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.driveLive, style: t.titleSmall),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                StatePill(icon: Icons.arrow_upward_rounded, label: l.actionForward, on: cmd.forward),
                StatePill(icon: Icons.arrow_downward_rounded, label: l.actionReverse, on: cmd.reverse),
                StatePill(icon: Icons.arrow_back_rounded, label: l.actionLeft, on: cmd.left),
                StatePill(icon: Icons.arrow_forward_rounded, label: l.actionRight, on: cmd.right),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                StatePill(icon: Icons.light_mode_outlined, label: l.actionLight, on: cmd.light, color: Colors.yellow.shade600),
                StatePill(icon: Icons.bolt_rounded, label: l.actionTurbo, on: cmd.turbo, color: Colors.red.shade400),
                StatePill(icon: Icons.sync_rounded, label: l.actionDonut, on: cmd.donut, color: Colors.purple.shade300),
                StatePill(icon: Icons.tune_rounded, label: l.modeValue(cmd.mode), on: cmd.mode == 2, color: Colors.teal.shade300),
              ]),
              const SizedBox(height: 12),
              Text(l.safetyNote, style: t.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
            ],
          ),
        ),
      ],
    );

    // On-screen controls sit at the bottom, where thumbs rest; the info above
    // scrolls if the screen is short.
    return Column(
      children: [
        Expanded(child: info),
        if (d.onScreenControls)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: TouchControls(),
          ),
      ],
    );
  }

  IconData _batteryIcon(int p) {
    if (p >= 88) return Icons.battery_full_rounded;
    if (p >= 63) return Icons.battery_5_bar_rounded;
    if (p >= 38) return Icons.battery_3_bar_rounded;
    if (p >= 13) return Icons.battery_1_bar_rounded;
    return Icons.battery_alert_rounded;
  }

  Widget _connection(BuildContext context, Driver d, AppLocalizations l) {
    final t = Theme.of(context).textTheme;
    switch (d.link) {
      case LinkState.idle:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.bluetooth_disabled),
              const SizedBox(width: 10),
              Expanded(child: Text(l.noCar, style: t.titleMedium)),
            ]),
            const SizedBox(height: 6),
            Text(l.noCarHint, style: t.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
            if (d.cars.length == 1) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => d.connect(d.cars.first.id),
                child: Text(l.connectTo(d.cars.first.model)),
              ),
            ],
          ],
        );
      case LinkState.connecting:
        return Row(children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded(child: Text(l.connecting, style: t.titleMedium)),
        ]);
      case LinkState.connected:
        final c = d.command;
        final header = Row(children: [
          DrivingCar(
            moving: c.isMoving,
            steer: c.left == c.right ? 0 : (c.right ? 1 : -1),
            size: 34,
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.connectedCar?.model ?? '—', style: t.titleLarge),
              Text(l.connectedLabel, style: t.bodyMedium?.copyWith(color: Colors.green)),
            ]),
          ),
          if (d.battery != null)
            Row(mainAxisSize: MainAxisSize.min, children: [
              AnimatedSwitcher(
                duration: motion(context, 240),
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: Icon(_batteryIcon(d.battery!), key: ValueKey(_batteryIcon(d.battery!))),
              ),
              const SizedBox(width: 4),
              Text('${d.battery}%'),
            ]),
        ]);
        final disconnect = OutlinedButton(onPressed: d.disconnect, child: Text(l.disconnect));
        // Side by side when there is room; stacked on narrow phones.
        return LayoutBuilder(
          builder: (context, box) => box.maxWidth < 400
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  header,
                  const SizedBox(height: 12),
                  disconnect,
                ])
              : Row(children: [
                  Expanded(child: header),
                  const SizedBox(width: 12),
                  disconnect,
                ]),
        );
    }
  }
}
