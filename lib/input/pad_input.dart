import 'dart:math' as math;

import 'package:gamepads/gamepads.dart';

/// Everything that can be bound on a controller, in standard (positional)
/// terms: `a` is the bottom face button (Xbox A, PlayStation ✕), and so on.
enum PadInput {
  a,
  b,
  x,
  y,
  leftBumper,
  rightBumper,
  leftTrigger,
  rightTrigger,
  back,
  start,
  home,
  leftStick,
  rightStick,
  touchpad,
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
  leftStickUp,
  leftStickDown,
  leftStickLeft,
  leftStickRight,
  rightStickUp,
  rightStickDown,
  rightStickLeft,
  rightStickRight;

  /// True for the "stick pushed in a direction" inputs.
  bool get isStickDirection => index >= PadInput.leftStickUp.index;

  static PadInput? byName(String name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

/// Current value of every standard button/axis of all connected controllers.
class PadState {
  final Map<GamepadButton, double> _buttons = {};
  final Map<GamepadAxis, double> _axes = {};

  void setButton(GamepadButton b, double v) => _buttons[b] = v;
  void setAxis(GamepadAxis a, double v) => _axes[a] = v;

  void clear() {
    _buttons.clear();
    _axes.clear();
  }

  double _b(GamepadButton b) => _buttons[b] ?? 0;
  double _a(GamepadAxis a) => _axes[a] ?? 0;

  /// 0..1 strength of [input].
  double value(PadInput input) {
    switch (input) {
      case PadInput.a:
        return _b(GamepadButton.a);
      case PadInput.b:
        return _b(GamepadButton.b);
      case PadInput.x:
        return _b(GamepadButton.x);
      case PadInput.y:
        return _b(GamepadButton.y);
      case PadInput.leftBumper:
        return _b(GamepadButton.leftBumper);
      case PadInput.rightBumper:
        return _b(GamepadButton.rightBumper);
      case PadInput.leftTrigger:
        return math.max(_b(GamepadButton.leftTrigger), _a(GamepadAxis.leftTrigger));
      case PadInput.rightTrigger:
        return math.max(_b(GamepadButton.rightTrigger), _a(GamepadAxis.rightTrigger));
      case PadInput.back:
        return _b(GamepadButton.back);
      case PadInput.start:
        return _b(GamepadButton.start);
      case PadInput.home:
        return _b(GamepadButton.home);
      case PadInput.leftStick:
        return _b(GamepadButton.leftStick);
      case PadInput.rightStick:
        return _b(GamepadButton.rightStick);
      case PadInput.touchpad:
        return _b(GamepadButton.touchpad);
      case PadInput.dpadUp:
        return _b(GamepadButton.dpadUp);
      case PadInput.dpadDown:
        return _b(GamepadButton.dpadDown);
      case PadInput.dpadLeft:
        return _b(GamepadButton.dpadLeft);
      case PadInput.dpadRight:
        return _b(GamepadButton.dpadRight);
      case PadInput.leftStickUp:
        return math.max(0, _a(GamepadAxis.leftStickY));
      case PadInput.leftStickDown:
        return math.max(0, -_a(GamepadAxis.leftStickY));
      case PadInput.leftStickLeft:
        return math.max(0, -_a(GamepadAxis.leftStickX));
      case PadInput.leftStickRight:
        return math.max(0, _a(GamepadAxis.leftStickX));
      case PadInput.rightStickUp:
        return math.max(0, _a(GamepadAxis.rightStickY));
      case PadInput.rightStickDown:
        return math.max(0, -_a(GamepadAxis.rightStickY));
      case PadInput.rightStickLeft:
        return math.max(0, -_a(GamepadAxis.rightStickX));
      case PadInput.rightStickRight:
        return math.max(0, _a(GamepadAxis.rightStickX));
    }
  }

  /// Whether [input] counts as pressed. Sticks use [deadzone]; everything else
  /// uses a fixed 30% threshold.
  bool pressed(PadInput input, double deadzone) =>
      value(input) > (input.isStickDirection ? deadzone : 0.3);

  Set<PadInput> pressedSet(double deadzone) =>
      {for (final i in PadInput.values) if (pressed(i, deadzone)) i};
}
