import 'package:ble_rc_controller/core/protocol.dart';
import 'package:ble_rc_controller/input/bindings.dart';
import 'package:ble_rc_controller/input/input_ref.dart';
import 'package:ble_rc_controller/input/pad_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every action has a default binding', () {
    final b = defaultBindings();
    for (final a in CarAction.values) {
      expect(b[a], isNotEmpty, reason: a.name);
    }
  });

  test('left stick up/down is NOT bound to forward/reverse by default', () {
    final b = defaultBindings();
    final all = [for (final l in b.values) ...l];
    expect(all.contains(InputRef.pad(PadInput.leftStickUp)), isFalse);
    expect(all.contains(InputRef.pad(PadInput.leftStickDown)), isFalse);
    expect(b[CarAction.forward], contains(InputRef.pad(PadInput.rightTrigger)));
    expect(b[CarAction.left], contains(InputRef.pad(PadInput.leftStickLeft)));
  });

  test('save and load round-trips', () {
    final b = defaultBindings();
    b[CarAction.forward] = [InputRef.raw('KEYCODE_BUTTON_C', 1), InputRef.key(PhysicalKeyboardKey.keyI)];
    final back = decodeBindings(encodeBindings(b));
    expect(back[CarAction.forward], b[CarAction.forward]);
    expect(back[CarAction.light], b[CarAction.light]);
  });

  test('corrupt or missing data falls back to defaults', () {
    expect(decodeBindings(null)[CarAction.forward], defaultBindings()[CarAction.forward]);
    expect(decodeBindings('not json')[CarAction.turbo], defaultBindings()[CarAction.turbo]);
  });

  test('InputRef parsing', () {
    final raw = InputRef.raw('AXIS_HAT_X', -1);
    expect(raw.kind, InputKind.raw);
    expect(raw.rawKey, 'AXIS_HAT_X');
    expect(raw.rawSign, -1);

    final key = InputRef.key(PhysicalKeyboardKey.arrowUp);
    expect(key.kind, InputKind.key);
    expect(key.keyUsage, PhysicalKeyboardKey.arrowUp.usbHidUsage);
    expect(key.keyText, '↑');

    final pad = InputRef.pad(PadInput.leftBumper);
    expect(pad.padInput, PadInput.leftBumper);
  });

  test('keyboard labels are short', () {
    expect(InputRef.keyLabel(PhysicalKeyboardKey.keyW), 'W');
    expect(InputRef.keyLabel(PhysicalKeyboardKey.space), 'Space');
    expect(InputRef.keyLabel(PhysicalKeyboardKey.digit5), '5');
  });
}
