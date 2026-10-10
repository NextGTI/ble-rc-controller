import 'package:flutter/material.dart';

import '../core/driver.dart';
import '../l10n/gen/app_localizations.dart';
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(child: _connection(context, d, l)),
        if (d.message != null) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded),
              title: Text(l.message(d.message!)),
              trailing: IconButton(icon: const Icon(Icons.close), onPressed: d.dismissMessage),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SectionCard(
          child: Row(
            children: [
              Icon(Icons.sports_esports,
                  size: 32, color: d.controllers.isEmpty ? Theme.of(context).hintColor : Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                StatePill(label: '▲ ${l.actionForward}', on: cmd.forward),
                StatePill(label: '▼ ${l.actionReverse}', on: cmd.reverse),
                StatePill(label: '◀ ${l.actionLeft}', on: cmd.left),
                StatePill(label: '${l.actionRight} ▶', on: cmd.right),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                StatePill(label: l.actionLight, on: cmd.light, color: Colors.yellow.shade600),
                StatePill(label: l.actionTurbo, on: cmd.turbo, color: Colors.red.shade400),
                StatePill(label: l.actionDonut, on: cmd.donut, color: Colors.purple.shade300),
                StatePill(label: l.modeValue(cmd.mode), on: cmd.mode == 2, color: Colors.teal.shade300),
              ]),
              const SizedBox(height: 12),
              Text(l.safetyNote, style: t.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
            ],
          ),
        ),
        if (d.onScreenControls) ...[
          const SizedBox(height: 16),
          const TouchControls(),
        ],
      ],
    );
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
              Text(l.noCar, style: t.titleMedium),
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
          Text(l.connecting, style: t.titleMedium),
        ]);
      case LinkState.connected:
        return Row(children: [
          const Icon(Icons.directions_car_filled, color: Colors.green, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.connectedCar?.model ?? '—', style: t.titleLarge),
              Text(l.connectedLabel, style: t.bodyMedium?.copyWith(color: Colors.green)),
            ]),
          ),
          if (d.battery != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(children: [
                const Icon(Icons.battery_5_bar_rounded),
                const SizedBox(width: 4),
                Text('${d.battery}%'),
              ]),
            ),
          OutlinedButton(onPressed: d.disconnect, child: Text(l.disconnect)),
        ]);
    }
  }
}
