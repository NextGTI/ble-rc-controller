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

  /// The id of every [disconnect] call, in order.
  final disconnected = <String>[];
  bool failConnect = false;

  /// How many times [connect] was called, whether it succeeded or not.
  int connectCalls = 0;

  /// What [currentAvailability] reports.
  BluetoothState state = BluetoothState.ready;

  /// When true, [requestPermissions] throws, like a user who said no.
  bool denyPermission = false;

  /// How many times [requestPermissions] was called.
  int permissionCalls = 0;

  /// How many times [enableBluetooth] was called.
  int enableCalls = 0;

  @override
  bool canEnableBluetooth = true;

  /// How long [connect] takes before it succeeds (or throws).
  Duration connectDelay = Duration.zero;

  /// How long [disconnect] takes.
  Duration disconnectDelay = Duration.zero;

  @override
  Stream<BluetoothState> get availability => avail.stream;
  @override
  Future<BluetoothState> currentAvailability() async => state;
  @override
  Future<void> requestPermissions() async {
    permissionCalls++;
    if (denyPermission) throw StateError('permission denied');
  }

  @override
  Future<bool> enableBluetooth() async {
    enableCalls++;
    return true;
  }

  @override
  Stream<FoundCar> get scanResults => scan.stream;
  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}
  @override
  Future<void> connect(String id) async {
    connectCalls++;
    if (connectDelay > Duration.zero) await Future<void>.delayed(connectDelay);
    if (failConnect) throw StateError('nope');
    connected.add(id);
  }

  @override
  Future<void> disconnect(String id) async {
    disconnected.add(id);
    if (disconnectDelay > Duration.zero) await Future<void>.delayed(disconnectDelay);
    connected.remove(id);
  }

  @override
  Stream<bool> connectionOf(String id) => conn.stream;
  @override
  Future<void> writeControl(String id, Uint8List bytes) async => writes.add(bytes);
  @override
  Stream<int> batteryOf(String id) => Stream.value(77);
}
