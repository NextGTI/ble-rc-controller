import 'dart:typed_data';

enum BluetoothState { unknown, ready, off, unauthorized, unsupported }

/// A car seen during a scan.
class FoundCar {
  const FoundCar({required this.id, required this.name, required this.rssi});

  final String id;
  final String name;
  final int rssi;

  /// "SL-SF-25" becomes "SF-25".
  String get model =>
      name.startsWith('SL-') ? name.substring(3) : (name.isEmpty ? 'Car' : name);

  /// 1 (weak) to 4 (strong).
  int get signalLevel {
    if (rssi >= -60) return 4;
    if (rssi >= -72) return 3;
    if (rssi >= -85) return 2;
    return 1;
  }
}

/// Everything the app needs from Bluetooth, so it can be faked in tests.
abstract class CarTransport {
  Stream<BluetoothState> get availability;
  Future<BluetoothState> currentAvailability();

  /// Throws if the user denies the permission.
  Future<void> requestPermissions();

  Stream<FoundCar> get scanResults;
  Future<void> startScan();
  Future<void> stopScan();

  /// Connects and verifies that the control characteristic exists.
  /// Throws on failure.
  Future<void> connect(String id);
  Future<void> disconnect(String id);

  /// Emits `false` when the car drops the connection.
  Stream<bool> connectionOf(String id);

  /// Write-without-response to the control characteristic.
  Future<void> writeControl(String id, Uint8List bytes);

  /// Battery percentage updates (first value is read on connect, if the car
  /// exposes it).
  Stream<int> batteryOf(String id);
}
