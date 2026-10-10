import 'package:ble_rc_controller/core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('packet layout is [1, fwd, rev, left, right, light, turbo, donut]', () {
    const c = CarCommand(
      forward: true,
      left: true,
      light: true,
      donut: true,
    );
    expect(c.toBytes(), [1, 1, 0, 1, 0, 1, 0, 1]);
    expect(c.toBytes().length, CarCommand.length);
  });

  test('neutral keeps the light, drops all movement', () {
    const c = CarCommand(
      forward: true,
      reverse: false,
      left: true,
      right: true,
      light: true,
      turbo: true,
      donut: true,
    );
    expect(c.neutral.toBytes(), [1, 0, 0, 0, 0, 1, 0, 0]);
    expect(c.neutral.isMoving, isFalse);
    expect(c.isMoving, isTrue);
  });

  test('value equality', () {
    expect(const CarCommand(forward: true), const CarCommand(forward: true));
    expect(const CarCommand(forward: true) == const CarCommand(), isFalse);
  });

  test('only the light is a toggle', () {
    expect(CarAction.values.where((a) => a.isToggle).toSet(), {CarAction.light});
  });

  test('the first byte is always 1: the car showed no effect for 2', () {
    expect(const CarCommand().toBytes().first, 1);
    expect(const CarCommand(forward: true, turbo: true).toBytes().first, 1);
  });
}
