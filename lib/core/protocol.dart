import 'dart:typed_data';

/// BLE identifiers used by the supported toy cars.
///
/// See docs/PROTOCOL.md for how these were determined.
class CarUuids {
  CarUuids._();

  /// Service that holds the control characteristic.
  static const controlService = 'FFF0';

  /// Write-without-response characteristic that receives [CarCommand] packets.
  static const controlCharacteristic = 'FFF1';

  static const batteryService = '180F';
  static const batteryCharacteristic = '2A19';

  /// Extra service the cars advertise; used (with [namePrefix]) to find them.
  static const advertisedService = '6936';

  /// Every known car advertises a name that starts with this prefix.
  static const namePrefix = 'SL-';
}

/// Things the user can do with the car.
enum CarAction {
  forward,
  reverse,
  left,
  right,
  light,
  turbo,
  donut,
  mode;

  /// Light and mode flip on each press; the others apply while held.
  bool get isToggle => this == light || this == mode;
}

/// The 8-byte packet sent to the car.
///
/// `[mode, forward, reverse, left, right, light, turbo, donut]`
///
/// [mode] is 1 or 2; every other field is 0 or 1. There is no proportional
/// speed or steering: everything is on/off.
class CarCommand {
  const CarCommand({
    this.mode = 1,
    this.forward = false,
    this.reverse = false,
    this.left = false,
    this.right = false,
    this.light = false,
    this.turbo = false,
    this.donut = false,
  });

  final int mode;
  final bool forward;
  final bool reverse;
  final bool left;
  final bool right;
  final bool light;
  final bool turbo;
  final bool donut;

  static const int length = 8;

  Uint8List toBytes() => Uint8List.fromList([
        mode,
        forward ? 1 : 0,
        reverse ? 1 : 0,
        left ? 1 : 0,
        right ? 1 : 0,
        light ? 1 : 0,
        turbo ? 1 : 0,
        donut ? 1 : 0,
      ]);

  /// Same mode and light, but no movement.
  CarCommand get neutral => CarCommand(mode: mode, light: light);

  bool get isMoving =>
      forward || reverse || left || right || turbo || donut;

  @override
  bool operator ==(Object other) =>
      other is CarCommand &&
      other.mode == mode &&
      other.forward == forward &&
      other.reverse == reverse &&
      other.left == left &&
      other.right == right &&
      other.light == light &&
      other.turbo == turbo &&
      other.donut == donut;

  @override
  int get hashCode =>
      Object.hash(mode, forward, reverse, left, right, light, turbo, donut);

  @override
  String toString() => 'CarCommand(${toBytes()})';
}
