import 'package:ble_rc_controller/input/pad_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

void main() {
  test('stick directions use the dead zone, buttons a fixed threshold', () {
    final s = PadState();
    s.setAxis(GamepadAxis.leftStickX, 0.3);
    expect(s.pressed(PadInput.leftStickRight, 0.35), isFalse);
    expect(s.pressed(PadInput.leftStickRight, 0.2), isTrue);
    s.setAxis(GamepadAxis.leftStickX, -0.8);
    expect(s.pressed(PadInput.leftStickLeft, 0.35), isTrue);
    expect(s.pressed(PadInput.leftStickRight, 0.35), isFalse);
  });

  test('stick Y: up is positive', () {
    final s = PadState();
    s.setAxis(GamepadAxis.leftStickY, 0.9);
    expect(s.pressed(PadInput.leftStickUp, 0.35), isTrue);
    expect(s.pressed(PadInput.leftStickDown, 0.35), isFalse);
  });

  test('a trigger counts whether it reports as a button or an axis', () {
    final s = PadState();
    s.setButton(GamepadButton.rightTrigger, 1);
    expect(s.pressed(PadInput.rightTrigger, 0.35), isTrue);
    s.clear();
    s.setAxis(GamepadAxis.rightTrigger, 0.5);
    expect(s.pressed(PadInput.rightTrigger, 0.35), isTrue);
    s.setAxis(GamepadAxis.rightTrigger, 0.1);
    expect(s.pressed(PadInput.rightTrigger, 0.35), isFalse);
  });

  test('clear releases everything', () {
    final s = PadState();
    s.setButton(GamepadButton.a, 1);
    s.setAxis(GamepadAxis.leftStickX, 1);
    expect(s.pressedSet(0.35), isNotEmpty);
    s.clear();
    expect(s.pressedSet(0.35), isEmpty);
  });
}
