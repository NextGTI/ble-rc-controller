import 'dart:convert';

import 'package:gamepads/gamepads.dart';

/// A controller the app has seen.
class ControllerInfo {
  const ControllerInfo({
    required this.id,
    required this.name,
    this.vendorId,
    this.productId,
  });

  /// Session identifier from the platform (not stable across reconnects).
  final String id;
  final String name;
  final int? vendorId;
  final int? productId;

  /// Stable key used to store this model's custom mapping.
  String get profileKey {
    if (vendorId != null && productId != null) {
      return 'usb:${vendorId!.toRadixString(16)}:${productId!.toRadixString(16)}';
    }
    return 'name:${name.toLowerCase().trim()}';
  }
}

/// One thing a raw signal means: "role" is a [GamepadButton] name (a, dpadUp,
/// leftTrigger...) or `axis:` + a [GamepadAxis] name (axis:leftStickX...).
///
/// [sign] flips the signal when needed (a stick axis that reports up as
/// negative, a hat axis where "right" is +1, ...).
class RawMapping {
  const RawMapping(this.role, this.sign);

  final String role;
  final int sign;

  Map<String, dynamic> toJson() => {'role': role, 'sign': sign};

  factory RawMapping.fromJson(Map<String, dynamic> j) =>
      RawMapping(j['role'] as String, (j['sign'] as num).toInt() < 0 ? -1 : 1);

  GamepadButton? get button {
    for (final b in GamepadButton.values) {
      if (b.name == role) return b;
    }
    return null;
  }

  GamepadAxis? get axis {
    if (!role.startsWith('axis:')) return null;
    final n = role.substring(5);
    for (final a in GamepadAxis.values) {
      if (a.name == n) return a;
    }
    return null;
  }
}

/// A user-taught mapping for one controller model. Signals listed here win
/// over the built-in database, so it can also be used to correct a known
/// controller.
class ControllerProfile {
  ControllerProfile({
    required this.key,
    required this.name,
    Map<String, List<RawMapping>>? rawMap,
  }) : rawMap = rawMap ?? {};

  final String key;
  String name;

  /// Raw signal key -> what it means.
  final Map<String, List<RawMapping>> rawMap;

  bool get isCustom => rawMap.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'map': {
          for (final e in rawMap.entries)
            e.key: [for (final m in e.value) m.toJson()],
        },
      };

  factory ControllerProfile.fromJson(Map<String, dynamic> j) =>
      ControllerProfile(
        key: j['key'] as String,
        name: j['name'] as String,
        rawMap: {
          for (final e in (j['map'] as Map<String, dynamic>).entries)
            e.key: [
              for (final m in e.value as List)
                RawMapping.fromJson(m as Map<String, dynamic>),
            ],
        },
      );
}

String encodeProfiles(Map<String, ControllerProfile> p) =>
    jsonEncode([for (final v in p.values) v.toJson()]);

Map<String, ControllerProfile> decodeProfiles(String? source) {
  if (source == null) return {};
  try {
    final list = jsonDecode(source) as List;
    return {
      for (final j in list)
        (j as Map<String, dynamic>)['key'] as String:
            ControllerProfile.fromJson(j),
    };
  } catch (_) {
    return {};
  }
}

// ---------------------------------------------------------------------------
// Teaching an unknown controller
// ---------------------------------------------------------------------------

enum TeachKind {
  /// A button (also accepts a trigger that reports as a button, or a hat axis).
  button,

  /// A trigger: button or analog axis.
  trigger,

  /// A stick axis: the user pushes it in the stated direction.
  stickAxis,
}

class TeachStep {
  const TeachStep(this.id, this.kind, {this.sign = 1});

  /// Localisation key suffix and storage role. For [TeachKind.stickAxis] this
  /// is `axis:<GamepadAxis name>`; otherwise a [GamepadButton] name.
  final String id;
  final TeachKind kind;

  /// For sticks: +1 means "the user pushes right/up".
  final int sign;
}

/// The questions asked, in order. Each can be skipped.
const teachSteps = <TeachStep>[
  TeachStep('a', TeachKind.button),
  TeachStep('b', TeachKind.button),
  TeachStep('x', TeachKind.button),
  TeachStep('y', TeachKind.button),
  TeachStep('leftBumper', TeachKind.button),
  TeachStep('rightBumper', TeachKind.button),
  TeachStep('leftTrigger', TeachKind.trigger),
  TeachStep('rightTrigger', TeachKind.trigger),
  TeachStep('back', TeachKind.button),
  TeachStep('start', TeachKind.button),
  TeachStep('axis:leftStickX', TeachKind.stickAxis),
  TeachStep('axis:leftStickY', TeachKind.stickAxis),
  TeachStep('axis:rightStickX', TeachKind.stickAxis),
  TeachStep('axis:rightStickY', TeachKind.stickAxis),
  TeachStep('dpadUp', TeachKind.button),
  TeachStep('dpadDown', TeachKind.button),
  TeachStep('dpadLeft', TeachKind.button),
  TeachStep('dpadRight', TeachKind.button),
];

class TeachSession {
  TeachSession(this.profile);

  final ControllerProfile profile;
  int index = 0;

  /// Raw signals discovered so far (committed to [profile] when finished).
  final Map<String, List<RawMapping>> draft = {};

  bool get finished => index >= teachSteps.length;
  TeachStep get current => teachSteps[index];

  void advance() => index++;

  void add(String rawKey, RawMapping m) {
    final list = draft.putIfAbsent(rawKey, () => []);
    list.removeWhere((e) => e.role == m.role);
    list.add(m);
  }
}
