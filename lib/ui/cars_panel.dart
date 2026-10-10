import 'package:flutter/material.dart';

import '../core/car_transport.dart';
import '../core/driver.dart';
import '../l10n/gen/app_localizations.dart';
import 'motion.dart';
import 'strings.dart';
import 'widgets.dart';

/// The list of cars found over Bluetooth.
class CarsPanel extends StatelessWidget {
  const CarsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final d = DriverScope.of(context);
    final l = AppLocalizations.of(context);

    Widget body;
    switch (d.bluetooth) {
      case BluetoothState.off:
        body = Notice(title: l.btOffTitle, body: l.btOffBody, icon: Icons.bluetooth_disabled);
      case BluetoothState.unauthorized:
        body = Notice(title: l.btDeniedTitle, body: l.btDeniedBody, icon: Icons.block);
      case BluetoothState.unsupported:
        body = Notice(title: l.btUnsupportedTitle, body: l.btUnsupportedBody, icon: Icons.error_outline);
      case BluetoothState.unknown:
      case BluetoothState.ready:
        body = d.cars.isEmpty
            ? Notice(title: l.carsSearching, body: l.carsHint, icon: Icons.bluetooth_searching)
            : ListView(
                children: [for (final c in d.cars) EntranceAnimation(key: ValueKey(c.id), child: _CarTile(car: c))],
              );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Text(l.carsTitle, style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              if (d.bluetooth == BluetoothState.ready && d.link == LinkState.idle)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
        Expanded(child: body),
        SwitchListTile(
          dense: true,
          title: Text(l.rememberLast),
          value: d.autoConnect,
          onChanged: (v) => d.autoConnect = v,
        ),
      ],
    );
  }
}

class _CarTile extends StatelessWidget {
  const _CarTile({required this.car});

  final FoundCar car;

  @override
  Widget build(BuildContext context) {
    final d = DriverScope.of(context);
    final active = d.carId == car.id;
    final connected = active && d.link == LinkState.connected;
    final connecting = active && d.link == LinkState.connecting;
    final color = connected ? Colors.green : Theme.of(context).colorScheme.primary;
    return ListTile(
      selected: active,
      leading: Icon(Icons.directions_car_filled, color: color, size: 30),
      title: Text(car.model, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(car.name),
      trailing: connecting
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : SignalBars(level: car.signalLevel),
      onTap: () => connected ? null : d.connect(car.id),
    );
  }
}
