import 'dart:async';
import 'dart:typed_data';

import 'package:ble_rc_controller/core/car_transport.dart';

/// The one fake Bluetooth transport for the driver and widget tests.
class FakeTransport implements CarTransport {
  final scan = StreamController<FoundCar>.broadcast();
  final conn = StreamController<bool>.broadcast();

  /// Backs [availability]: push a state here to simulate Bluetooth changing.
  final avail = StreamController<BluetoothState>.broadcast();
  final writes = <Uint8List>[];
  final connected = <String>[];
  bool failConnect = false;

  /// How long [connect] takes before it succeeds (or throws).
  Duration connectDelay = Duration.zero;

  @override
  Stream<BluetoothState> get availability => avail.stream;
  @override
  Future<BluetoothState> currentAvailability() async => BluetoothState.ready;
  @override
  Future<void> requestPermissions() async {}
  @override
  Stream<FoundCar> get scanResults => scan.stream;
  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}
  @override
  Future<void> connect(String id) async {
    if (connectDelay > Duration.zero) await Future<void>.delayed(connectDelay);
    if (failConnect) throw StateError('nope');
    connected.add(id);
  }

  @override
  Future<void> disconnect(String id) async => connected.remove(id);
  @override
  Stream<bool> connectionOf(String id) => conn.stream;
  @override
  Future<void> writeControl(String id, Uint8List bytes) async => writes.add(bytes);
  @override
  Stream<int> batteryOf(String id) => Stream.value(77);
}
