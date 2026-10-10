import 'package:ble_rc_controller/core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('packet layout is [mode, fwd, rev, left, right, light, turbo, donut]', () {
    const c = CarCommand(
      mode: 2,
      forward: true,
      left: true,
      light: true,
      donut: true,
    );
    expect(c.toBytes(), [2, 1, 0, 1, 0, 1, 0, 1]);
    expect(c.toBytes().length, CarCommand.length);
  });

  test('neutral keeps mode and light, drops all movement', () {
    const c = CarCommand(
      mode: 2,
      forward: true,
      reverse: false,
      left: true,
      right: true,
      light: true,
      turbo: true,
      donut: true,
    );
    expect(c.neutral.toBytes(), [2, 0, 0, 0, 0, 1, 0, 0]);
    expect(c.neutral.isMoving, isFalse);
    expect(c.isMoving, isTrue);
  });

  test('value equality', () {
    expect(const CarCommand(forward: true), const CarCommand(forward: true));
    expect(const CarCommand(forward: true) == const CarCommand(), isFalse);
  });

  test('only light and mode are toggles', () {
    expect(CarAction.values.where((a) => a.isToggle).toSet(), {CarAction.light, CarAction.mode});
  });
}
