import 'dart:async';
import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

import 'car_transport.dart';
import 'protocol.dart';

/// [CarTransport] backed by the `universal_ble` package
/// (Android, macOS, Windows, ...).
class UniversalBleTransport implements CarTransport {
  static String _full(String uuid) => BleUuidParser.string(uuid).toLowerCase();

  static final _control = _full(CarUuids.controlService);
  static final _controlChar = _full(CarUuids.controlCharacteristic);
  static final _battery = _full(CarUuids.batteryService);
  static final _batteryChar = _full(CarUuids.batteryCharacteristic);
  static final _advertised = _full(CarUuids.advertisedService);

  static BluetoothState _map(AvailabilityState s) {
    switch (s) {
      case AvailabilityState.poweredOn:
        return BluetoothState.ready;
      case AvailabilityState.poweredOff:
        return BluetoothState.off;
      case AvailabilityState.unauthorized:
        return BluetoothState.unauthorized;
      case AvailabilityState.unsupported:
        return BluetoothState.unsupported;
      case AvailabilityState.unknown:
      case AvailabilityState.resetting:
        return BluetoothState.unknown;
    }
  }

  @override
  Stream<BluetoothState> get availability =>
      UniversalBle.availabilityStream.map(_map);

  @override
  Future<BluetoothState> currentAvailability() async =>
      _map(await UniversalBle.getBluetoothAvailabilityState());

  @override
  Future<void> requestPermissions() => UniversalBle.requestPermissions();

  static bool _isCar(BleDevice d) {
    final name = d.name ?? d.rawName ?? '';
    if (name.startsWith(CarUuids.namePrefix)) return true;
    return d.services.any((s) => _full(s) == _advertised);
  }

  @override
  Stream<FoundCar> get scanResults => UniversalBle.scanStream.where(_isCar).map(
        (d) => FoundCar(
          id: d.deviceId,
          name: d.name ?? d.rawName ?? '',
          rssi: d.rssi ?? -100,
        ),
      );

  @override
  Future<void> startScan() => UniversalBle.startScan();

  @override
  Future<void> stopScan() async {
    try {
      await UniversalBle.stopScan();
    } catch (_) {}
  }

  @override
  Future<void> connect(String id) async {
    await UniversalBle.connect(id, timeout: const Duration(seconds: 10));
    final services = await UniversalBle.discoverServices(id);
    final ok = services.any((s) =>
        _full(s.uuid) == _control &&
        s.characteristics.any((c) => _full(c.uuid) == _controlChar));
    if (!ok) {
      await disconnect(id);
      throw StateError('Control characteristic not found');
    }
  }

  @override
  Future<void> disconnect(String id) async {
    try {
      await UniversalBle.disconnect(id);
    } catch (_) {}
  }

  @override
  Stream<bool> connectionOf(String id) => UniversalBle.connectionStream(id);

  @override
  Future<void> writeControl(String id, Uint8List bytes) => UniversalBle.write(
        id,
        _control,
        _controlChar,
        bytes,
        withoutResponse: true,
      );

  @override
  Stream<int> batteryOf(String id) {
    final controller = StreamController<int>();
    StreamSubscription<Uint8List>? sub;

    controller.onListen = () async {
      sub = UniversalBle.characteristicValueStream(id, _batteryChar).listen(
        (v) {
          if (v.isNotEmpty) controller.add(v.first);
        },
        onError: (_) {},
      );
      try {
        final v = await UniversalBle.read(id, _battery, _batteryChar);
        if (v.isNotEmpty && !controller.isClosed) controller.add(v.first);
        await UniversalBle.subscribeNotifications(id, _battery, _batteryChar);
      } catch (_) {
        // The car may not expose a battery service; that is fine.
      }
    };
    controller.onCancel = () async {
      await sub?.cancel();
      await controller.close();
    };
    return controller.stream;
  }
}
