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

  String get keyText {
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
  static String keyLabel(PhysicalKeyboardKey key) {
    final name = key.debugName ?? 'Key ${key.usbHidUsage}';
    const glyphs = {
      'Arrow Up': '↑',
      'Arrow Down': '↓',
      'Arrow Left': '←',
      'Arrow Right': '→',
      'Space': 'Space',
    };
    if (glyphs.containsKey(name)) return glyphs[name]!;
    if (name.startsWith('Key ')) return name.substring(4);
    if (name.startsWith('Digit ')) return name.substring(6);
    return name;
  }
}
