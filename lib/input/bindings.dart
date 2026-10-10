import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/protocol.dart';
import 'input_ref.dart';
import 'pad_input.dart';

typedef Bindings = Map<CarAction, List<InputRef>>;

/// Factory defaults. The left stick only steers: forward/reverse are on the
/// triggers (and ↑/↓ or W/S on a keyboard).
Bindings defaultBindings() => {
      CarAction.forward: [
        InputRef.pad(PadInput.rightTrigger),
        InputRef.key(PhysicalKeyboardKey.arrowUp),
        InputRef.key(PhysicalKeyboardKey.keyW),
      ],
      CarAction.reverse: [
        InputRef.pad(PadInput.leftTrigger),
        InputRef.key(PhysicalKeyboardKey.arrowDown),
        InputRef.key(PhysicalKeyboardKey.keyS),
      ],
      CarAction.left: [
        InputRef.pad(PadInput.leftStickLeft),
        InputRef.pad(PadInput.dpadLeft),
        InputRef.key(PhysicalKeyboardKey.arrowLeft),
        InputRef.key(PhysicalKeyboardKey.keyA),
      ],
      CarAction.right: [
        InputRef.pad(PadInput.leftStickRight),
        InputRef.pad(PadInput.dpadRight),
        InputRef.key(PhysicalKeyboardKey.arrowRight),
        InputRef.key(PhysicalKeyboardKey.keyD),
      ],
      CarAction.light: [
        InputRef.pad(PadInput.a),
        InputRef.key(PhysicalKeyboardKey.keyL),
      ],
      CarAction.turbo: [
        InputRef.pad(PadInput.b),
        InputRef.key(PhysicalKeyboardKey.space),
      ],
      CarAction.donut: [
        InputRef.pad(PadInput.y),
        InputRef.key(PhysicalKeyboardKey.keyQ),
      ],
      CarAction.mode: [
        InputRef.pad(PadInput.start),
        InputRef.key(PhysicalKeyboardKey.keyM),
      ],
    };

String encodeBindings(Bindings b) => jsonEncode({
      for (final e in b.entries) e.key.name: [for (final r in e.value) r.id],
    });

/// Missing or corrupt data falls back to the defaults for that action.
Bindings decodeBindings(String? source) {
  final result = defaultBindings();
  if (source == null) return result;
  try {
    final map = jsonDecode(source) as Map<String, dynamic>;
    for (final action in CarAction.values) {
      final list = map[action.name];
      if (list is List) {
        result[action] = [for (final s in list) InputRef(s as String)];
      }
    }
  } catch (_) {}
  return result;
}
