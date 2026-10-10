import 'package:flutter/widgets.dart';

import '../core/driver.dart';
import '../core/protocol.dart';
import '../input/input_ref.dart';
import '../input/pad_input.dart';
import '../l10n/gen/app_localizations.dart';

/// Gives widgets access to the [Driver] and rebuilds them when it changes.
class DriverScope extends InheritedNotifier<Driver> {
  const DriverScope({super.key, required Driver driver, required super.child})
      : super(notifier: driver);

  static Driver of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DriverScope>()!.notifier!;
}

extension L10nText on AppLocalizations {
  String action(CarAction a) {
    switch (a) {
      case CarAction.forward:
        return actionForward;
      case CarAction.reverse:
        return actionReverse;
      case CarAction.left:
        return actionLeft;
      case CarAction.right:
        return actionRight;
      case CarAction.light:
        return actionLight;
      case CarAction.turbo:
        return actionTurbo;
      case CarAction.donut:
        return actionDonut;
      case CarAction.mode:
        return actionMode;
    }
  }

  String actionHint(CarAction a) => a.isToggle ? hintToggle : hintHold;

  String pad(PadInput p) {
    switch (p) {
      case PadInput.a:
        return padA;
      case PadInput.b:
        return padB;
      case PadInput.x:
        return padX;
      case PadInput.y:
        return padY;
      case PadInput.leftBumper:
        return padLeftBumper;
      case PadInput.rightBumper:
        return padRightBumper;
      case PadInput.leftTrigger:
        return padLeftTrigger;
      case PadInput.rightTrigger:
        return padRightTrigger;
      case PadInput.back:
        return padBack;
      case PadInput.start:
        return padStart;
      case PadInput.home:
        return padHome;
      case PadInput.leftStick:
        return padLeftStick;
      case PadInput.rightStick:
        return padRightStick;
      case PadInput.touchpad:
        return padTouchpad;
      case PadInput.dpadUp:
        return padDpadUp;
      case PadInput.dpadDown:
        return padDpadDown;
      case PadInput.dpadLeft:
        return padDpadLeft;
      case PadInput.dpadRight:
        return padDpadRight;
      case PadInput.leftStickUp:
        return padLeftStickUp;
      case PadInput.leftStickDown:
        return padLeftStickDown;
      case PadInput.leftStickLeft:
        return padLeftStickLeft;
      case PadInput.leftStickRight:
        return padLeftStickRight;
      case PadInput.rightStickUp:
        return padRightStickUp;
      case PadInput.rightStickDown:
        return padRightStickDown;
      case PadInput.rightStickLeft:
        return padRightStickLeft;
      case PadInput.rightStickRight:
        return padRightStickRight;
    }
  }

  String input(InputRef r) {
    switch (r.kind) {
      case InputKind.pad:
        final p = r.padInput;
        return p == null ? r.id : pad(p);
      case InputKind.key:
        return r.keyText;
      case InputKind.raw:
        return rawInput('${r.rawKey} ${r.rawSign < 0 ? '−' : '+'}');
    }
  }

  String teach(String id) {
    switch (id) {
      case 'a':
        return teach_a;
      case 'b':
        return teach_b;
      case 'x':
        return teach_x;
      case 'y':
        return teach_y;
      case 'leftBumper':
        return teach_leftBumper;
      case 'rightBumper':
        return teach_rightBumper;
      case 'leftTrigger':
        return teach_leftTrigger;
      case 'rightTrigger':
        return teach_rightTrigger;
      case 'back':
        return teach_back;
      case 'start':
        return teach_start;
      case 'axis:leftStickX':
        return teach_leftStickX;
      case 'axis:leftStickY':
        return teach_leftStickY;
      case 'axis:rightStickX':
        return teach_rightStickX;
      case 'axis:rightStickY':
        return teach_rightStickY;
      case 'dpadUp':
        return teach_dpadUp;
      case 'dpadDown':
        return teach_dpadDown;
      case 'dpadLeft':
        return teach_dpadLeft;
      case 'dpadRight':
        return teach_dpadRight;
    }
    return id;
  }

  String message(MessageKind k) {
    switch (k) {
      case MessageKind.connectFailed:
        return msgConnectFailed;
      case MessageKind.dropped:
        return msgDropped;
      case MessageKind.permissionDenied:
        return msgPermission;
    }
  }
}
