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

  test('a binding saved for the removed "mode" action is ignored', () {
    // Releases up to 1.0.1 had a Mode action; their saved settings still hold it.
    final back = decodeBindings(
        '{"mode":["pad:start","key:458767"],"turbo":["raw:X|+"]}');
    expect(back.keys.toSet(), CarAction.values.toSet());
    expect(back[CarAction.turbo], [InputRef.raw('X', 1)]);
    expect(back[CarAction.forward], defaultBindings()[CarAction.forward]);
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

  // Regression: PhysicalKeyboardKey.debugName is null in release builds, so the
  // Buttons tab showed raw numbers (458834...) instead of "↑", "W", "Space".
  test('key labels come from our own table, not from debug-only names', () {
    final expected = {
      PhysicalKeyboardKey.arrowUp: '↑',
      PhysicalKeyboardKey.arrowDown: '↓',
      PhysicalKeyboardKey.arrowLeft: '←',
      PhysicalKeyboardKey.arrowRight: '→',
      PhysicalKeyboardKey.keyW: 'W',
      PhysicalKeyboardKey.keyA: 'A',
      PhysicalKeyboardKey.keyS: 'S',
      PhysicalKeyboardKey.keyD: 'D',
      PhysicalKeyboardKey.keyL: 'L',
      PhysicalKeyboardKey.keyQ: 'Q',
      PhysicalKeyboardKey.keyM: 'M',
      PhysicalKeyboardKey.space: 'Space',
      PhysicalKeyboardKey.shiftLeft: 'Shift',
      PhysicalKeyboardKey.digit7: '7',
      PhysicalKeyboardKey.f5: 'F5',
    };
    expected.forEach((key, label) {
      expect(InputRef.keyLabelForUsage(key.usbHidUsage), label, reason: key.usbHidUsage.toString());
    });
  });

  test('a label saved as a bare number by an old release build is shown correctly', () {
    // This is exactly what v1.0.0/v1.0.1 release builds stored for the ↑ key.
    final old = InputRef('key:${PhysicalKeyboardKey.arrowUp.usbHidUsage}:${PhysicalKeyboardKey.arrowUp.usbHidUsage}');
    expect(old.keyText, '↑');
  });

  test('no default keyboard binding is labelled with a number', () {
    final numeric = RegExp(r'^\d{4,}$');
    for (final refs in defaultBindings().values) {
      for (final r in refs.where((r) => r.kind == InputKind.key)) {
        expect(numeric.hasMatch(r.keyText), isFalse, reason: r.id);
      }
    }
  });
}
