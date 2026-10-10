import 'package:flutter/services.dart';

import 'pad_input.dart';

enum InputKind { pad, key, raw }

/// A reference to one physical input, stored as a plain string so it can be
/// saved and compared easily:
///
/// * `pad:rightTrigger`      standard controller input
/// * `key:458834:↑`          keyboard key (USB HID usage + label)
/// * `raw:KEYCODE_FOO|+`     a controller signal the app does not recognise
class InputRef {
  const InputRef(this.id);

  factory InputRef.pad(PadInput input) => InputRef('pad:${input.name}');

  factory InputRef.key(PhysicalKeyboardKey key) =>
      InputRef('key:${key.usbHidUsage}:${keyLabel(key)}');

  /// [sign] is +1 or -1: which direction of the raw signal counts as pressed.
  factory InputRef.raw(String key, int sign) =>
      InputRef('raw:$key|${sign < 0 ? '-' : '+'}');

  final String id;

  InputKind get kind {
    if (id.startsWith('key:')) return InputKind.key;
    if (id.startsWith('raw:')) return InputKind.raw;
    return InputKind.pad;
  }

  PadInput? get padInput =>
      kind == InputKind.pad ? PadInput.byName(id.substring(4)) : null;

  int? get keyUsage => kind == InputKind.key ? int.tryParse(id.split(':')[1]) : null;

  /// Label shown for a key. Derived from the key code with our own table:
  /// Flutter's `debugName` is empty in release builds, and labels saved by
  /// older versions may be raw numbers, so the stored text is only a fallback.
  String get keyText {
    final usage = keyUsage;
    final known = usage == null ? null : keyLabelForUsage(usage);
    if (known != null) return known;
    final parts = id.split(':');
    return parts.length > 2 ? parts.sublist(2).join(':') : '?';
  }

  String? get rawKey {
    if (kind != InputKind.raw) return null;
    final body = id.substring(4);
    final cut = body.lastIndexOf('|');
    return cut < 0 ? body : body.substring(0, cut);
  }

  int get rawSign => id.endsWith('|-') ? -1 : 1;

  @override
  bool operator ==(Object other) => other is InputRef && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;

  /// Short human label for a keyboard key ("W", "↑", "Space").
  static String keyLabel(PhysicalKeyboardKey key) =>
      keyLabelForUsage(key.usbHidUsage) ?? 'Key ${key.usbHidUsage & 0xFFFF}';

  /// Label for a USB HID usage code, or null when the key is not in the table.
  static String? keyLabelForUsage(int usage) => _labels[usage];

  static final Map<int, String> _labels = () {
    final m = <int, String>{};
    void add(PhysicalKeyboardKey k, String label) => m[k.usbHidUsage] = label;

    const letters = {
      'A': PhysicalKeyboardKey.keyA, 'B': PhysicalKeyboardKey.keyB, 'C': PhysicalKeyboardKey.keyC,
      'D': PhysicalKeyboardKey.keyD, 'E': PhysicalKeyboardKey.keyE, 'F': PhysicalKeyboardKey.keyF,
      'G': PhysicalKeyboardKey.keyG, 'H': PhysicalKeyboardKey.keyH, 'I': PhysicalKeyboardKey.keyI,
      'J': PhysicalKeyboardKey.keyJ, 'K': PhysicalKeyboardKey.keyK, 'L': PhysicalKeyboardKey.keyL,
      'M': PhysicalKeyboardKey.keyM, 'N': PhysicalKeyboardKey.keyN, 'O': PhysicalKeyboardKey.keyO,
      'P': PhysicalKeyboardKey.keyP, 'Q': PhysicalKeyboardKey.keyQ, 'R': PhysicalKeyboardKey.keyR,
      'S': PhysicalKeyboardKey.keyS, 'T': PhysicalKeyboardKey.keyT, 'U': PhysicalKeyboardKey.keyU,
      'V': PhysicalKeyboardKey.keyV, 'W': PhysicalKeyboardKey.keyW, 'X': PhysicalKeyboardKey.keyX,
      'Y': PhysicalKeyboardKey.keyY, 'Z': PhysicalKeyboardKey.keyZ,
    };
    letters.forEach((label, k) => add(k, label));

    const digits = [
      PhysicalKeyboardKey.digit0, PhysicalKeyboardKey.digit1, PhysicalKeyboardKey.digit2,
      PhysicalKeyboardKey.digit3, PhysicalKeyboardKey.digit4, PhysicalKeyboardKey.digit5,
      PhysicalKeyboardKey.digit6, PhysicalKeyboardKey.digit7, PhysicalKeyboardKey.digit8,
      PhysicalKeyboardKey.digit9,
    ];
    for (var i = 0; i < digits.length; i++) {
      add(digits[i], '$i');
    }
    const numpad = [
      PhysicalKeyboardKey.numpad0, PhysicalKeyboardKey.numpad1, PhysicalKeyboardKey.numpad2,
      PhysicalKeyboardKey.numpad3, PhysicalKeyboardKey.numpad4, PhysicalKeyboardKey.numpad5,
      PhysicalKeyboardKey.numpad6, PhysicalKeyboardKey.numpad7, PhysicalKeyboardKey.numpad8,
      PhysicalKeyboardKey.numpad9,
    ];
    for (var i = 0; i < numpad.length; i++) {
      add(numpad[i], 'Num $i');
    }
    const fkeys = [
      PhysicalKeyboardKey.f1, PhysicalKeyboardKey.f2, PhysicalKeyboardKey.f3, PhysicalKeyboardKey.f4,
      PhysicalKeyboardKey.f5, PhysicalKeyboardKey.f6, PhysicalKeyboardKey.f7, PhysicalKeyboardKey.f8,
      PhysicalKeyboardKey.f9, PhysicalKeyboardKey.f10, PhysicalKeyboardKey.f11, PhysicalKeyboardKey.f12,
    ];
    for (var i = 0; i < fkeys.length; i++) {
      add(fkeys[i], 'F${i + 1}');
    }

    add(PhysicalKeyboardKey.arrowUp, '↑');
    add(PhysicalKeyboardKey.arrowDown, '↓');
    add(PhysicalKeyboardKey.arrowLeft, '←');
    add(PhysicalKeyboardKey.arrowRight, '→');
    add(PhysicalKeyboardKey.space, 'Space');
    add(PhysicalKeyboardKey.enter, 'Enter');
    add(PhysicalKeyboardKey.numpadEnter, 'Num Enter');
    add(PhysicalKeyboardKey.escape, 'Esc');
    add(PhysicalKeyboardKey.tab, 'Tab');
    add(PhysicalKeyboardKey.backspace, '⌫');
    add(PhysicalKeyboardKey.capsLock, 'Caps');
    add(PhysicalKeyboardKey.shiftLeft, 'Shift');
    add(PhysicalKeyboardKey.shiftRight, 'Shift (R)');
    add(PhysicalKeyboardKey.controlLeft, 'Ctrl');
    add(PhysicalKeyboardKey.controlRight, 'Ctrl (R)');
    add(PhysicalKeyboardKey.altLeft, 'Alt');
    add(PhysicalKeyboardKey.altRight, 'Alt (R)');
    add(PhysicalKeyboardKey.metaLeft, 'Meta');
    add(PhysicalKeyboardKey.metaRight, 'Meta (R)');
    add(PhysicalKeyboardKey.minus, '-');
    add(PhysicalKeyboardKey.equal, '=');
    add(PhysicalKeyboardKey.bracketLeft, '[');
    add(PhysicalKeyboardKey.bracketRight, ']');
    add(PhysicalKeyboardKey.backslash, '\\');
    add(PhysicalKeyboardKey.semicolon, ';');
    add(PhysicalKeyboardKey.quote, "'");
    add(PhysicalKeyboardKey.backquote, '`');
    add(PhysicalKeyboardKey.comma, ',');
    add(PhysicalKeyboardKey.period, '.');
    add(PhysicalKeyboardKey.slash, '/');
    add(PhysicalKeyboardKey.numpadAdd, 'Num +');
    add(PhysicalKeyboardKey.numpadSubtract, 'Num -');
    add(PhysicalKeyboardKey.numpadMultiply, 'Num *');
    add(PhysicalKeyboardKey.numpadDivide, 'Num /');
    add(PhysicalKeyboardKey.numpadDecimal, 'Num .');
    add(PhysicalKeyboardKey.home, 'Home');
    add(PhysicalKeyboardKey.end, 'End');
    add(PhysicalKeyboardKey.pageUp, 'PgUp');
    add(PhysicalKeyboardKey.pageDown, 'PgDn');
    add(PhysicalKeyboardKey.insert, 'Ins');
    add(PhysicalKeyboardKey.delete, 'Del');
    return m;
  }();
}
