import 'dart:async';

import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/input/controller_profile.dart';
import 'package:ble_rc_controller/l10n/gen/app_localizations.dart';
import 'package:ble_rc_controller/ui/common/signal_meter.dart';
import 'package:ble_rc_controller/ui/settings/controllers_page.dart';
import 'package:ble_rc_controller/ui/settings/gamepad_drawing.dart';
import 'package:ble_rc_controller/ui/settings/settings_page.dart';
import 'package:ble_rc_controller/ui/settings/teach_page.dart';
import 'package:ble_rc_controller/ui/shell.dart';
import 'package:ble_rc_controller/ui/strings.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_transport.dart';
import 'support/harness.dart';

// ---------------------------------------------------------------------------
// A driver whose controllers and signals the test plays with
// ---------------------------------------------------------------------------

GamepadEvent _signal(
  String key,
  double value, {
  KeyType type = KeyType.button,
  String pad = 'g1',
}) => GamepadEvent(
  gamepadId: pad,
  timestamp: 0,
  type: type,
  key: key,
  value: value,
);

/// The key under which the controller [_Rig.plug] connects keeps its taught
/// mapping (no vendor or product id, so it is the lower-case name).
const _padKey = 'name:dualshock 4';

/// Lets an event of a stream reach the driver and the screen show what it
/// changed. A pump draws a frame only if one was already asked for when it
/// began, and the event asks for one when it arrives, so the first pump takes
/// the event in and the second draws it.
Future<void> _settleEvent(WidgetTester t) async {
  await t.pump();
  await t.pump();
}

class _Rig {
  _Rig(this.driver, this.raw, this.conn);

  final Driver driver;
  final StreamController<GamepadEvent> raw;
  final StreamController<GamepadConnectionEvent> conn;

  Future<void> plug(WidgetTester t, {String id = 'g1'}) async {
    conn.add(
      GamepadConnectionEvent(
        gamepadId: id,
        name: 'DualShock 4',
        type: GamepadConnectionEventType.connected,
      ),
    );
    await _settleEvent(t);
  }

  Future<void> unplug(WidgetTester t, {String id = 'g1'}) async {
    conn.add(
      GamepadConnectionEvent(
        gamepadId: id,
        name: 'DualShock 4',
        type: GamepadConnectionEventType.disconnected,
      ),
    );
    await _settleEvent(t);
  }

  /// A signal from the controller: a button by default, a stick when [analog].
  Future<void> send(
    WidgetTester t,
    String key,
    double value, {
    bool analog = false,
  }) async {
    raw.add(
      _signal(key, value, type: analog ? KeyType.analog : KeyType.button),
    );
    await _settleEvent(t);
  }
}

Future<_Rig> _newRig({
  bool keyboard = false,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final raw = StreamController<GamepadEvent>.broadcast();
  final conn = StreamController<GamepadConnectionEvent>.broadcast();
  final driver = Driver(
    transport: FakeTransport(),
    prefs: await SharedPreferences.getInstance(),
    rawEvents: raw.stream,
    connectionEvents: conn.stream,
    listGamepads: () async => [],
    enableKeyboard: keyboard,
  );
  await driver.start();
  return _Rig(driver, raw, conn);
}

/// A widget test with a [_Rig] that is taken down, widgets first, at the end.
void _rigTest(
  String name,
  Future<void> Function(WidgetTester t, _Rig rig) body, {
  bool keyboard = false,
  Map<String, Object> prefs = const {},
}) {
  testWidgets(name, (t) async {
    final rig = await _newRig(keyboard: keyboard, prefs: prefs);
    try {
      await body(t, rig);
    } finally {
      await t.pumpWidget(const SizedBox());
      rig.driver.dispose();
      await rig.raw.close();
      await rig.conn.close();
    }
  });
}

/// The controllers page, pushing what it opens as a route, as a phone does.
Widget _host() => Builder(
  builder: (context) => ControllersPage(
    open: (page) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Material(color: AppColors.bg, child: page),
      ),
    ),
  ),
);

/// The controllers page on a window with the pad plugged in, still (no
/// pulsing, so `pumpAndSettle` can finish).
Future<void> _mountControllers(
  WidgetTester t,
  _Rig rig, {
  Size size = const Size(390, 844),
  String locale = 'pt',
  bool plugged = true,
}) async {
  if (plugged) await rig.plug(t);
  await pumpWithDriver(
    t,
    rig.driver,
    _host(),
    size: size,
    locale: locale,
    reduceMotion: true,
  );
  await t.pumpAndSettle();
}

/// The row of the settings called [title]: the cockpit has a cell of the same
/// name behind the panel.
Finder _settingsRow(String title) =>
    find.descendant(of: find.byType(SettingsPage), matching: find.text(title));

/// Taps "Ensinar um controle novo" and waits for the wizard.
Future<void> _openWizard(WidgetTester t) async {
  await t.tap(find.text('Ensinar um controle novo'));
  await t.pumpAndSettle();
  expect(find.byType(TeachPage), findsOneWidget);
}

Future<void> _skip(WidgetTester t, [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await t.tap(find.text('Pular'));
    await t.pumpAndSettle();
  }
}

/// The labels of the meters on screen, top to bottom.
List<String> _meterLabels(WidgetTester t) => [
  for (final m in t.widgetList<SignalMeter>(find.byType(SignalMeter))) m.label,
];

void main() {
  setUpAll(loadSaira);
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'BLE RC Controller',
      packageName: 'br.com.nextgti.ble_rc_controller',
      version: '1.0.2',
      buildNumber: '7',
      buildSignature: '',
    );
  });

  // -------------------------------------------------------------------------
  group('the 18 steps', () {
    test('every teach step has a part and a group', () {
      expect(teachSteps.length, 18);
      for (final s in teachSteps) {
        expect(() => gamepadPartFor(s.id), returnsNormally);
      }
      expect(gamepadPartFor('a'), GamepadPart.faceBottom);
      expect(gamepadPartFor('axis:leftStickY'), GamepadPart.leftStick);
    });

    test('each part of the pad belongs to a step, and to one only', () {
      final parts = [for (final s in teachSteps) gamepadPartFor(s.id)];
      // The two axes of one stick point at the same stick: 18 steps, 16 parts.
      expect(parts.toSet().length, 16);
      expect(parts.toSet(), GamepadPart.values.toSet());
      expect(
        gamepadPartFor('axis:leftStickX'),
        gamepadPartFor('axis:leftStickY'),
      );
      expect(
        gamepadPartFor('axis:rightStickX'),
        gamepadPartFor('axis:rightStickY'),
      );
      expect(gamepadPartFor('axis:rightStickX'), GamepadPart.rightStick);
    });

    test('the parts name the right piece of the pad', () {
      expect(gamepadPartFor('b'), GamepadPart.faceRight);
      expect(gamepadPartFor('x'), GamepadPart.faceLeft);
      expect(gamepadPartFor('y'), GamepadPart.faceTop);
      expect(gamepadPartFor('leftBumper'), GamepadPart.leftBumper);
      expect(gamepadPartFor('rightTrigger'), GamepadPart.rightTrigger);
      expect(gamepadPartFor('back'), GamepadPart.back);
      expect(gamepadPartFor('start'), GamepadPart.start);
      expect(gamepadPartFor('dpadUp'), GamepadPart.dpadUp);
      expect(gamepadPartFor('dpadRight'), GamepadPart.dpadRight);
    });

    test('an id that is not a step is refused', () {
      expect(() => gamepadPartFor('home'), throwsArgumentError);
    });

    test('teachTagOf names a stick by its push and a button by its name', () {
      final l = lookupAppLocalizations(const Locale('pt'));
      expect(teachTagOf(l, 'a'), 'Botão de baixo (A / ✕)');
      expect(teachTagOf(l, 'rightTrigger'), 'Gatilho direito (RT / R2)');
      expect(teachTagOf(l, 'back'), 'Voltar (View / Share / −)');
      expect(teachTagOf(l, 'dpadLeft'), 'D-pad ←');
      // The click of a stick (L3, R3) is another input.
      expect(teachTagOf(l, 'axis:leftStickX'), l.padLeftStickRight);
      expect(teachTagOf(l, 'axis:leftStickY'), l.padLeftStickUp);
      expect(teachTagOf(l, 'axis:rightStickX'), l.padRightStickRight);
      expect(teachTagOf(l, 'axis:rightStickY'), l.padRightStickUp);
      for (final s in teachSteps) {
        expect(teachTagOf(l, s.id), isNot(l.padLeftStick), reason: s.id);
        expect(teachTagOf(l, s.id), isNot(l.padRightStick), reason: s.id);
      }
    });

    test('teachGroupOf names the five groups, in the order of the steps', () {
      final l = lookupAppLocalizations(const Locale('pt'));
      final groups = [for (final s in teachSteps) teachGroupOf(l, s.id)];
      expect(groups, [
        for (var i = 0; i < 4; i++) 'Botões de ação',
        for (var i = 0; i < 4; i++) 'Ombros e gatilhos',
        for (var i = 0; i < 2; i++) 'Botões do meio',
        for (var i = 0; i < 4; i++) 'Analógicos',
        for (var i = 0; i < 4; i++) 'Direcional',
      ]);
    });
  });

  // -------------------------------------------------------------------------
  group('GamepadDrawing', () {
    /// The amber of the drawing: how many pixels are fully opaque amber and
    /// where their centre is. The drawing is 480 wide at a pixel ratio of 1.
    Future<({int count, Offset centre})> amberOf(
      WidgetTester t,
      GamepadPart part,
    ) async {
      final key = GlobalKey();
      await pumpWithDriver(
        t,
        await newDriver(),
        RepaintBoundary(
          key: key,
          child: SizedBox(width: 480, child: GamepadDrawing(highlight: part)),
        ),
        size: const Size(600, 600),
        reduceMotion: true,
      );
      await t.pumpAndSettle();
      final found = await t.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = (await image.toByteData())!;
        var count = 0;
        var sx = 0.0;
        var sy = 0.0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final at = (y * image.width + x) * 4;
            final r = bytes.getUint8(at);
            final g = bytes.getUint8(at + 1);
            final b = bytes.getUint8(at + 2);
            final a = bytes.getUint8(at + 3);
            // #FFB547 is (255, 181, 71).
            if (a >= 250 &&
                r >= 240 &&
                g >= 165 &&
                g <= 200 &&
                b >= 55 &&
                b <= 95) {
              count++;
              sx += x;
              sy += y;
            }
          }
        }
        image.dispose();
        return (count: count, centre: Offset(sx / count, sy / count));
      });
      return found!;
    }

    testWidgets('lights each of the 16 parts in amber, and only that part', (
      t,
    ) async {
      final lit = <GamepadPart, Offset>{};
      for (final part in GamepadPart.values) {
        final found = await amberOf(t, part);
        expect(found.count, greaterThan(40), reason: '$part is lit in amber');
        lit[part] = found.centre;
      }
      // Where each one is: the pad is seen from the front.
      Offset at(GamepadPart p) => lit[p]!;
      expect(
        at(GamepadPart.faceTop).dy,
        lessThan(at(GamepadPart.faceBottom).dy),
      );
      expect(
        at(GamepadPart.faceLeft).dx,
        lessThan(at(GamepadPart.faceRight).dx),
      );
      expect(at(GamepadPart.dpadUp).dy, lessThan(at(GamepadPart.dpadDown).dy));
      expect(
        at(GamepadPart.dpadLeft).dx,
        lessThan(at(GamepadPart.dpadRight).dx),
      );
      expect(
        at(GamepadPart.leftStick).dx,
        lessThan(at(GamepadPart.rightStick).dx),
      );
      expect(
        at(GamepadPart.leftBumper).dx,
        lessThan(at(GamepadPart.rightBumper).dx),
      );
      expect(
        at(GamepadPart.leftTrigger).dx,
        lessThan(at(GamepadPart.rightTrigger).dx),
      );
      expect(at(GamepadPart.back).dx, lessThan(at(GamepadPart.start).dx));
      // The triggers are above the bumpers, which are above the body.
      expect(
        at(GamepadPart.leftTrigger).dy,
        lessThan(at(GamepadPart.leftBumper).dy),
      );
      expect(
        at(GamepadPart.rightTrigger).dy,
        lessThan(at(GamepadPart.rightBumper).dy),
      );
      expect(
        at(GamepadPart.leftBumper).dy,
        lessThan(at(GamepadPart.leftStick).dy),
      );
      // The d-pad is on the left, the face buttons on the right.
      expect(at(GamepadPart.dpadUp).dx, lessThan(at(GamepadPart.faceTop).dx));
      // No two parts light the same place.
      final all = lit.values.toList();
      for (var i = 0; i < all.length; i++) {
        for (var j = i + 1; j < all.length; j++) {
          expect(
            (all[i] - all[j]).distance,
            greaterThan(10),
            reason: '${GamepadPart.values[i]} and ${GamepadPart.values[j]}',
          );
        }
      }
    });

    /// The painter of the drawing on screen.
    GamepadPainter painter(WidgetTester t) =>
        t
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter is GamepadPainter,
                  ),
                )
                .painter!
            as GamepadPainter;

    testWidgets('pulses: the glow of the part goes down and up', (t) async {
      await pumpWithDriver(
        t,
        await newDriver(),
        const GamepadDrawing(highlight: GamepadPart.faceBottom),
      );
      final seen = <double>{};
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 100));
        seen.add(painter(t).pulse.value);
      }
      expect(seen.length, greaterThan(3), reason: 'the pulse moves');
      expect(t.binding.hasScheduledFrame, isTrue, reason: 'and keeps going');
    });

    testWidgets('with "reduce motion" it is lit and still', (t) async {
      await pumpWithDriver(
        t,
        await newDriver(),
        const GamepadDrawing(highlight: GamepadPart.faceBottom),
        reduceMotion: true,
      );
      await t.pumpAndSettle();
      final lit = painter(t).pulse.value;
      await t.pump(const Duration(seconds: 2));
      expect(painter(t).pulse.value, lit);
      expect(t.binding.hasScheduledFrame, isFalse, reason: 'nothing runs');
      // The brightest the glow gets.
      expect(lit, 0);
    });

    testWidgets('stops pulsing when the system asks for less motion', (
      t,
    ) async {
      final driver = await newDriver();
      Future<void> mount({required bool reduce}) => pumpWithDriver(
        t,
        driver,
        const GamepadDrawing(highlight: GamepadPart.faceBottom),
        reduceMotion: reduce,
      );
      await mount(reduce: false);
      await t.pump(const Duration(milliseconds: 300));
      expect(t.binding.hasScheduledFrame, isTrue);
      await mount(reduce: true);
      await t.pumpAndSettle();
      expect(t.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('changing the part does not restart the pulse', (t) async {
      final driver = await newDriver();
      Future<void> mount(GamepadPart p) =>
          pumpWithDriver(t, driver, GamepadDrawing(highlight: p));
      await mount(GamepadPart.faceBottom);
      await t.pump(const Duration(milliseconds: 200));
      final before = painter(t).pulse.value;
      expect(before, greaterThan(0));
      await mount(GamepadPart.leftStick);
      expect(painter(t).highlight, GamepadPart.leftStick);
      expect(painter(t).pulse.value, closeTo(before, 0.01));
    });

    testWidgets('takes the room it is given and keeps its proportions', (
      t,
    ) async {
      await pumpWithDriver(
        t,
        await newDriver(),
        const SizedBox(
          width: 300,
          child: GamepadDrawing(highlight: GamepadPart.start),
        ),
        reduceMotion: true,
      );
      final size = t.getSize(find.byType(GamepadDrawing));
      expect(size.width, 300);
      expect(size.height, greaterThan(150));
      expect(size.height, lessThan(220));
    });
  });

  // -------------------------------------------------------------------------
  group('the strongest signals', () {
    RawSignal sig(String key, double v) => RawSignal('pad', key, v);

    test('sorts by strength, whatever the sign, and keeps six', () {
      final all = [
        for (var i = 0; i < 9; i++) sig('k$i', i.isEven ? i / 10 : -i / 10),
      ];
      final top = strongestSignals(all);
      expect(
        [for (final s in top) s.key],
        ['k8', 'k7', 'k6', 'k5', 'k4', 'k3'],
      );
      expect(top.length, liveSignalCount);
      expect(liveSignalCount, 6);
    });

    test('puts the signals as strong in the order of their names', () {
      final top = strongestSignals([
        sig('b', 0.5),
        sig('c', -0.5),
        sig('a', 0.5),
        sig('z', 0),
      ]);
      expect([for (final s in top) s.key], ['a', 'b', 'c', 'z']);
    });

    test('counts what is not a number as nothing, and a huge push as 1', () {
      expect(signalStrength(sig('x', double.nan)), 0);
      expect(signalStrength(sig('x', -0.0)), 0);
      expect(signalStrength(sig('x', -3)), 1);
      expect(signalStrength(sig('x', -0.25)), 0.25);
      final top = strongestSignals([sig('n', double.nan), sig('p', 0.1)]);
      expect([for (final s in top) s.key], ['p', 'n']);
    });

    test('gives nothing for nothing', () {
      expect(strongestSignals(const []), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  group('ControllersPage', () {
    _rigTest('with no controller says how to pair one, and waits', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig, plugged: false);
      expect(find.text('Controles'), findsOneWidget);
      expect(find.text('Conectados'), findsOneWidget);
      expect(find.text('Nenhum controle'), findsOneWidget);
      expect(
        find.text(
          'Pareie o controle por Bluetooth ou USB e aperte qualquer botão.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sinais ao vivo'), findsOneWidget);
      expect(
        find.text(
          'Aperte botões para ver os sinais. Útil para conferir um controle que o app não conhece.',
        ),
        findsOneWidget,
      );
      expect(find.byType(SignalMeter), findsNothing);

      // There is nothing to teach yet: the button is there but does nothing.
      await t.tap(find.text('Ensinar um controle novo'));
      await t.pumpAndSettle();
      expect(find.byType(TeachPage), findsNothing);
      expect(rig.driver.teaching, isNull);
    });

    _rigTest('names the connected controller and says it is recognised', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      expect(find.text('DualShock 4'), findsOneWidget);
      expect(find.text('Reconhecido'), findsOneWidget);
      expect(find.text('Ensinado'), findsNothing);
      expect(find.text('Esquecer o que foi ensinado'), findsNothing);
      expect(find.text('Nenhum controle'), findsNothing);
    });

    _rigTest(
      'a taught controller says so, and can be made to forget',
      (t, rig) async {
        await _mountControllers(t, rig);
        expect(rig.driver.profiles[_padKey]?.isCustom, isTrue);
        expect(find.text('Ensinado'), findsOneWidget);
        expect(find.text('Reconhecido'), findsNothing);

        await t.tap(find.text('Esquecer o que foi ensinado'));
        await t.pumpAndSettle();

        expect(rig.driver.profiles.containsKey(_padKey), isFalse);
        expect(find.text('Reconhecido'), findsOneWidget);
        expect(find.text('Esquecer o que foi ensinado'), findsNothing);
      },
      prefs: {
        'profiles': encodeProfiles({
          _padKey: ControllerProfile(
            key: _padKey,
            name: 'DualShock 4',
            rawMap: {
              'b0': [RawMapping('a', 1)],
            },
          ),
        }),
      },
    );

    _rigTest(
      'a profile with nothing taught in it still counts as recognised',
      (t, rig) async {
        await _mountControllers(t, rig);
        expect(find.text('Reconhecido'), findsOneWidget);
        expect(find.text('Esquecer o que foi ensinado'), findsNothing);
      },
      prefs: {
        'profiles': encodeProfiles({
          _padKey: ControllerProfile(key: _padKey, name: 'DualShock 4'),
        }),
      },
    );

    _rigTest('shows the signals as meters: six at most, the strongest first, '
        'a negative one as its absolute value', (t, rig) async {
      await _mountControllers(t, rig);
      expect(
        find.byType(SignalMeter),
        findsNothing,
        reason: 'nothing sent yet',
      );

      final values = {
        'k1': 0.10,
        'k2': 0.90,
        'k3': -0.80,
        'k4': 0.30,
        'k5': 0.0,
        'k6': 0.50,
        'k7': 0.70,
        'k8': 0.20,
      };
      for (final e in values.entries) {
        await rig.send(t, e.key, e.value);
      }
      expect(_meterLabels(t), ['k2', 'k3', 'k7', 'k6', 'k4', 'k8']);
      final meters = t
          .widgetList<SignalMeter>(find.byType(SignalMeter))
          .toList();
      expect(meters[1].value, closeTo(0.80, 1e-9), reason: 'k3 is -0.80');
      expect(find.text('0,80'), findsOneWidget);
      expect(find.text('0,90'), findsOneWidget);
    });

    _rigTest('rebuilds the meters at every new signal, with no other change', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await rig.send(t, 'k1', 0.2);
      await rig.send(t, 'k2', 0.6);
      expect(_meterLabels(t), ['k2', 'k1']);

      var driverChanges = 0;
      rig.driver.addListener(() => driverChanges++);
      await rig.send(t, 'k1', 1.0);
      expect(
        driverChanges,
        0,
        reason: 'only the revision of the signals moved',
      );
      expect(_meterLabels(t), ['k1', 'k2']);
      expect(find.text('1,00'), findsOneWidget);

      await rig.send(t, 'k1', -0.1);
      expect(_meterLabels(t), ['k2', 'k1']);
      expect(find.text('0,10'), findsOneWidget);
    });

    _rigTest('writes the values in the language of the app', (t, rig) async {
      await _mountControllers(t, rig, locale: 'en');
      await rig.send(t, 'k1', 0.72);
      expect(find.text('0.72'), findsOneWidget);
    });

    _rigTest('lines the bars up whatever the length of the names', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await rig.send(t, 'a', 0.9);
      await rig.send(t, 'trigger-left-long-name', 0.5);
      await rig.send(t, 'axis 3', 0.1);
      final bars = [
        for (var i = 0; i < 3; i++)
          t.getTopLeft(
            find
                .descendant(
                  of: find.byType(SignalMeter).at(i),
                  matching: find.byType(ClipRRect),
                )
                .first,
          ),
      ];
      expect(bars[0].dx, bars[1].dx);
      expect(bars[1].dx, bars[2].dx);
      expect(t.takeException(), isNull);
    });

    _rigTest('hides the meters of a controller that is gone', (t, rig) async {
      await _mountControllers(t, rig);
      await rig.send(t, 'k1', 0.5);
      expect(find.byType(SignalMeter), findsOneWidget);
      await rig.unplug(t);
      await t.pumpAndSettle();
      expect(find.byType(SignalMeter), findsNothing);
      expect(find.text('Nenhum controle'), findsOneWidget);
    });

    _rigTest(
      '"Ensinar um controle novo" starts the wizard for the controller',
      (t, rig) async {
        await _mountControllers(t, rig);
        await _openWizard(t);
        final session = rig.driver.teaching;
        expect(session, isNotNull);
        expect(session!.profile.key, _padKey);
        expect(session.index, 0);
      },
    );

    _rigTest('opens the wizard only once, whatever the taps', (t, rig) async {
      await _mountControllers(t, rig);
      // Two touches before a frame: the second one finds the page covered.
      final tap = t
          .widget<InkWell>(
            find
                .ancestor(
                  of: find.text('Ensinar um controle novo'),
                  matching: find.byType(InkWell),
                )
                .first,
          )
          .onTap!;
      tap();
      tap();
      await t.pumpAndSettle();
      expect(find.byType(TeachPage, skipOffstage: false), findsOneWidget);
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(find.byType(TeachPage, skipOffstage: false), findsNothing);
      expect(find.byType(ControllersPage), findsOneWidget);
    });

    _rigTest('every control is at least 48 by 48', (t, rig) async {
      await _mountControllers(t, rig);
      final button = find.ancestor(
        of: find.text('Ensinar um controle novo'),
        matching: find.byType(InkWell),
      );
      expect(t.getSize(button.first).height, greaterThanOrEqualTo(48));
      expect(t.getSize(button.first).width, greaterThanOrEqualTo(48));
    });

    _rigTest(
      'the forget action is at least 48 by 48',
      (t, rig) async {
        await _mountControllers(t, rig);
        final forget = find.ancestor(
          of: find.text('Esquecer o que foi ensinado'),
          matching: find.byType(InkWell),
        );
        expect(t.getSize(forget.first).height, greaterThanOrEqualTo(48));
      },
      prefs: {
        'profiles': encodeProfiles({
          _padKey: ControllerProfile(
            key: _padKey,
            name: 'DualShock 4',
            rawMap: {
              'b0': [RawMapping('a', 1)],
            },
          ),
        }),
      },
    );

    for (final (locale, size) in const [
      ('pt', Size(320, 568)),
      ('en', Size(320, 568)),
      ('es', Size(320, 568)),
      ('pt', Size(800, 360)),
      ('en', Size(1180, 760)),
    ]) {
      _rigTest('fits $size in $locale, and scrolls when it must', (
        t,
        rig,
      ) async {
        await _mountControllers(t, rig, size: size, locale: locale);
        for (final k in ['k1', 'k2', 'k3', 'k4', 'k5', 'k6', 'k7']) {
          await rig.send(t, k, 0.5);
        }
        expect(t.takeException(), isNull);
        expect(find.byType(SignalMeter), findsNWidgets(6));
        // Whatever is below the fold can be scrolled to.
        final l = lookupAppLocalizations(Locale(locale));
        await t.scrollUntilVisible(
          find.text(l.teachNew),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(t.takeException(), isNull);
      });
    }
  });

  // -------------------------------------------------------------------------
  group('TeachPage', () {
    _rigTest('opens at step 1 of 18, in the group of the face buttons', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      expect(find.text('Ensinar controle'), findsOneWidget);
      expect(find.text('Passo 1 de 18'), findsOneWidget);
      expect(find.text('Botões de ação'), findsOneWidget);
      expect(find.byType(GamepadDrawing), findsOneWidget);
      final drawing = t.widget<GamepadDrawing>(find.byType(GamepadDrawing));
      expect(drawing.highlight, GamepadPart.faceBottom);
    });

    _rigTest('asks in large type and says it in the words of each brand', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      final ask = find.text('Aperte o botão de baixo');
      expect(ask, findsOneWidget);
      final style = t.widget<Text>(ask).style!;
      expect(style.fontSize, inInclusiveRange(26, 28));
      expect(style.fontFamily, AppType.family);
      final hint = find.text('✕ no PlayStation, A no Xbox, B no Switch');
      expect(hint, findsOneWidget);
      // The brands under the question.
      expect(t.getTopLeft(hint).dy, greaterThan(t.getBottomLeft(ask).dy - 1));
    });

    _rigTest('"Pular" goes to the next step, with its part and its words', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      await _skip(t);
      expect(find.text('Passo 2 de 18'), findsOneWidget);
      expect(find.text('Passo 1 de 18'), findsNothing);
      expect(find.text('Aperte o botão da direita'), findsOneWidget);
      expect(
        find.text('○ no PlayStation, B no Xbox, A no Switch'),
        findsOneWidget,
      );
      expect(
        t.widget<GamepadDrawing>(find.byType(GamepadDrawing)).highlight,
        GamepadPart.faceRight,
      );
    });

    _rigTest('goes through every group, its name and its part', (t, rig) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      final groups = <String>[];
      final parts = <GamepadPart>[];
      for (var i = 0; i < teachSteps.length; i++) {
        expect(find.text('Passo ${i + 1} de 18'), findsOneWidget);
        parts.add(
          t.widget<GamepadDrawing>(find.byType(GamepadDrawing)).highlight,
        );
        final l = AppLocalizations.of(t.element(find.byType(TeachPage)));
        groups.add(teachGroupOf(l, teachSteps[i].id));
        expect(find.text(groups.last), findsOneWidget);
        expect(find.text(l.teach(teachSteps[i].id)), findsOneWidget);
        await _skip(t);
      }
      expect(parts, [for (final s in teachSteps) gamepadPartFor(s.id)]);
      expect(groups.toSet().length, 5);
    });

    _rigTest('shows only the hint a step has', (t, rig) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      await _skip(t, 10); // now at the left stick
      expect(find.text('Passo 11 de 18'), findsOneWidget);
      expect(
        find.text('Empurre o analógico esquerdo todo para a direita'),
        findsOneWidget,
      );
      expect(find.textContaining('no PlayStation'), findsNothing);
    });

    _rigTest('skipping every step ends in "Pronto", which saves', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      await _skip(t, teachSteps.length);

      expect(find.text('Pronto'), findsOneWidget);
      expect(find.text('Pular'), findsNothing);
      expect(find.textContaining('Passo '), findsNothing);
      expect(find.byType(GamepadDrawing), findsNothing);
      expect(rig.driver.teaching!.finished, isTrue);

      await t.tap(find.text('Pronto'));
      await t.pumpAndSettle();

      expect(rig.driver.teaching, isNull);
      expect(rig.driver.profiles.containsKey(_padKey), isTrue);
      expect(find.byType(TeachPage), findsNothing);
      expect(find.byType(ControllersPage), findsOneWidget);
    });

    _rigTest('teaching with the controller saves what it said', (t, rig) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      // The bottom button, the right one, the left one and the top one.
      for (final key in ['b0', 'b1', 'b2', 'b3']) {
        await rig.send(t, key, 1.0);
        await rig.send(t, key, 0.0);
      }
      await t.pumpAndSettle();
      expect(find.text('Passo 5 de 18'), findsOneWidget);
      await _skip(t, teachSteps.length - 4);
      await t.tap(find.text('Pronto'));
      await t.pumpAndSettle();

      final profile = rig.driver.profiles[_padKey]!;
      expect(profile.isCustom, isTrue);
      expect(profile.rawMap['b0']!.single.role, 'a');
      expect(profile.rawMap['b3']!.single.role, 'y');
      // And the controller is now a taught one.
      expect(find.text('Ensinado'), findsOneWidget);
    });

    _rigTest('tags what was learned, only in the group of the step', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      Finder tag(String text) => find.text(text);

      // Step 1: the bottom button.
      expect(tag('Botão de baixo (A / ✕)'), findsNothing);
      await rig.send(t, 'b0', 1.0);
      await rig.send(t, 'b0', 0.0);
      expect(find.text('Passo 2 de 18'), findsOneWidget);
      expect(tag('Botão de baixo (A / ✕)'), findsOneWidget);

      // A step that is skipped is no tag.
      await _skip(t);
      expect(find.text('Passo 3 de 18'), findsOneWidget);
      expect(tag('Botão da direita (B / ○)'), findsNothing);
      expect(tag('Botão de baixo (A / ✕)'), findsOneWidget);

      // Another group: the tags of the face buttons are gone.
      await _skip(t, 2);
      expect(find.text('Passo 5 de 18'), findsOneWidget);
      expect(find.text('Ombros e gatilhos'), findsOneWidget);
      expect(tag('Botão de baixo (A / ✕)'), findsNothing);
      await rig.send(t, 'b4', 1.0);
      await rig.send(t, 'b4', 0.0);
      expect(tag('Bumper esquerdo (LB / L1)'), findsOneWidget);

      // Back to the middle of the group: a trigger as a button.
      await rig.send(t, 'b6', 1.0);
      await rig.send(t, 'b6', 0.0);
      expect(tag('Bumper esquerdo (LB / L1)'), findsOneWidget);
      expect(tag('Bumper direito (RB / R1)'), findsOneWidget);
    });

    _rigTest('names a stick by the direction it was pushed, not by its click', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      await _skip(t, 10);
      expect(find.text('Analógicos'), findsOneWidget);

      // Rest, then all the way: to the right, then up (up reads negative).
      await rig.send(t, 'ax0', 0.0, analog: true);
      await rig.send(t, 'ax0', 1.0, analog: true);
      expect(find.text('Passo 12 de 18'), findsOneWidget);
      expect(find.text('Analógico esq. →'), findsOneWidget);

      await rig.send(t, 'ax1', 0.0, analog: true);
      await rig.send(t, 'ax1', -1.0, analog: true);
      expect(find.text('Passo 13 de 18'), findsOneWidget);
      expect(find.text('Analógico esq. ↑'), findsOneWidget);

      await rig.send(t, 'ax2', 0.0, analog: true);
      await rig.send(t, 'ax2', 1.0, analog: true);
      expect(find.text('Passo 14 de 18'), findsOneWidget);
      expect(find.text('Analógico dir. →'), findsOneWidget);
      // Three tags, all of the same group, and none is the click of a stick.
      expect(find.text('Analógico esq. →'), findsOneWidget);
      expect(find.text('Analógico esq. ↑'), findsOneWidget);
      expect(find.textContaining('Clique do analógico'), findsNothing);

      // The last step of the group takes the wizard on to the d-pad, whose
      // tags start from none.
      await rig.send(t, 'ax3', 0.0, analog: true);
      await rig.send(t, 'ax3', -1.0, analog: true);
      expect(find.text('Passo 15 de 18'), findsOneWidget);
      expect(find.text('Direcional'), findsOneWidget);
      expect(find.textContaining('Analógico'), findsNothing);
      expect(rig.driver.teaching!.draft.length, 4);
    });

    _rigTest('has "Pular" and "Cancelar" of at least 48 by 48', (t, rig) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      for (final label in ['Pular', 'Cancelar']) {
        final target = find
            .ancestor(of: find.text(label), matching: find.byType(InkWell))
            .first;
        expect(
          t.getSize(target).height,
          greaterThanOrEqualTo(48),
          reason: label,
        );
        expect(
          t.getSize(target).width,
          greaterThanOrEqualTo(48),
          reason: label,
        );
      }
    });

    _rigTest('"Pronto" is at least 48 by 48', (t, rig) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      await _skip(t, teachSteps.length);
      final target = find
          .ancestor(of: find.text('Pronto'), matching: find.byType(InkWell))
          .first;
      expect(t.getSize(target).height, greaterThanOrEqualTo(48));
      expect(t.getSize(target).width, greaterThanOrEqualTo(48));
    });

    _rigTest('"Cancelar" closes the wizard and ends the session', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      await _skip(t);
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(rig.driver.teaching, isNull);
      expect(find.byType(TeachPage), findsNothing);
      expect(find.byType(ControllersPage), findsOneWidget);
      // Nothing was saved.
      expect(rig.driver.profiles.containsKey(_padKey), isFalse);
    });

    _rigTest('losing the controller in the middle does not break it', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      await _skip(t);
      expect(find.text('Nenhum controle'), findsNothing);

      await rig.unplug(t);
      await t.pumpAndSettle();

      expect(t.takeException(), isNull);
      expect(find.byType(TeachPage), findsOneWidget);
      expect(find.text('Nenhum controle'), findsOneWidget);
      expect(find.text('Passo 2 de 18'), findsOneWidget);
      expect(rig.driver.teaching, isNotNull);

      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(rig.driver.teaching, isNull);
      expect(find.byType(TeachPage), findsNothing);
    });

    _rigTest('losing the controller at the end still lets it finish', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      await _skip(t, teachSteps.length);
      await rig.unplug(t);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('Nenhum controle'), findsOneWidget);
      await t.tap(find.text('Pronto'));
      await t.pumpAndSettle();
      expect(rig.driver.teaching, isNull);
      expect(find.byType(TeachPage), findsNothing);
    });

    _rigTest('Esc, which the driver takes, closes the wizard too', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(rig.driver.teaching, isNull);
      expect(find.byType(TeachPage), findsNothing);
      expect(find.byType(ControllersPage), findsOneWidget);
    }, keyboard: true);

    _rigTest('going back ends the session as well, at once', (t, rig) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      await t.tap(find.byTooltip('Fechar'));
      // One frame into the way out: the page is still sliding away.
      await t.pump();
      expect(find.byType(TeachPage), findsOneWidget);
      expect(rig.driver.teaching, isNull);
      await t.pumpAndSettle();
      expect(find.byType(TeachPage), findsNothing);
      expect(find.byType(ControllersPage), findsOneWidget);
    });

    _rigTest('the system back ends the session as well, at once', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      await t.binding.handlePopRoute();
      await t.pump();
      expect(find.byType(TeachPage), findsOneWidget);
      expect(rig.driver.teaching, isNull);
      await t.pumpAndSettle();
      expect(find.byType(TeachPage), findsNothing);
    });

    _rigTest('a wizard that is taken off the screen leaves no session', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      expect(rig.driver.teaching, isNotNull);
      // The whole tree goes away, as when the panel is closed from outside.
      await t.pumpWidget(const SizedBox());
      await t.pump();
      expect(rig.driver.teaching, isNull);
      expect(t.takeException(), isNull);
    });

    _rigTest('is still while "reduce motion" is on, and moves otherwise', (
      t,
      rig,
    ) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      expect(t.binding.hasScheduledFrame, isFalse);

      await pumpWithDriver(
        t,
        rig.driver,
        const TeachPage(),
        reduceMotion: false,
      );
      await t.pump(const Duration(milliseconds: 200));
      expect(t.binding.hasScheduledFrame, isTrue);
    });

    for (final locale in const ['pt', 'en', 'es']) {
      _rigTest('fits a 320 by 568 phone in $locale, even on the longest step', (
        t,
        rig,
      ) async {
        await _mountControllers(
          t,
          rig,
          size: const Size(320, 568),
          locale: locale,
        );
        final l = lookupAppLocalizations(Locale(locale));
        await t.tap(find.text(l.teachNew));
        await t.pumpAndSettle();
        for (var i = 0; i < teachSteps.length; i++) {
          expect(t.takeException(), isNull, reason: 'step ${i + 1}');
          // The question is on screen, whole.
          final ask = find.text(l.teach(teachSteps[i].id));
          expect(ask, findsOneWidget);
          final rect = t.getRect(ask);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
          // The two actions never leave the window.
          expect(
            t.getRect(find.text(l.skip)).bottom,
            lessThanOrEqualTo(568),
            reason: 'skip, step ${i + 1}',
          );
          expect(t.getRect(find.text(l.cancel)).bottom, lessThanOrEqualTo(568));
          await t.tap(find.text(l.skip));
          await t.pumpAndSettle();
        }
        expect(find.text(l.done), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }

    for (final size in const [
      Size(600, 960),
      Size(800, 360),
      Size(1180, 760),
    ]) {
      _rigTest('fits $size', (t, rig) async {
        await _mountControllers(t, rig, size: size);
        await _openWizard(t);
        expect(t.takeException(), isNull);
        await _skip(t, 10);
        expect(t.takeException(), isNull);
        // The footer is inside the window.
        expect(
          t.getRect(find.text('Pular')).bottom,
          lessThanOrEqualTo(size.height),
        );
      });
    }

    _rigTest('puts the drawing over the question on a phone', (t, rig) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      final drawing = t.getRect(find.byType(GamepadDrawing));
      final ask = t.getRect(find.text('Aperte o botão de baixo'));
      expect(drawing.bottom, lessThanOrEqualTo(ask.top));
    });

    _rigTest('puts the drawing beside the question on a phone turned sideways, '
        'with everything above the buttons', (t, rig) async {
      await _mountControllers(t, rig, size: const Size(800, 360));
      await _openWizard(t);
      final drawing = t.getRect(find.byType(GamepadDrawing));
      final ask = t.getRect(find.text('Aperte o botão de baixo'));
      expect(drawing.right, lessThanOrEqualTo(ask.left));
      final buttons = t.getRect(find.text('Pular')).top;
      expect(ask.bottom, lessThan(buttons));
      expect(t.getRect(find.text('Passo 1 de 18')).bottom, lessThan(buttons));
      expect(drawing.bottom, lessThan(buttons));

      // The longest question of the group of the sticks, with its tags.
      await _skip(t, 10);
      await rig.send(t, 'ax0', 0.0, analog: true);
      await rig.send(t, 'ax0', 1.0, analog: true);
      await t.pumpAndSettle();
      final tag = t.getRect(find.text('Analógico esq. →'));
      expect(tag.bottom, lessThan(buttons));
      expect(t.takeException(), isNull);
    });

    _rigTest('never writes text in the colour of the strokes', (t, rig) async {
      await _mountControllers(t, rig);
      await _openWizard(t);
      // Never the colour of the strokes for text.
      for (final w in t.widgetList<Text>(
        find.descendant(
          of: find.byType(TeachPage),
          matching: find.byType(Text),
        ),
      )) {
        expect(w.style?.color, isNot(AppColors.trace), reason: w.data);
        expect(w.style?.color, isNot(AppColors.traceWeak), reason: w.data);
      }
    });
  });

  // -------------------------------------------------------------------------
  group('on the desktop panel', () {
    _rigTest(
      'Esc ends the wizard, and the next Esc closes the panel',
      (t, rig) async {
        await rig.plug(t);
        await pumpWithDriver(
          t,
          rig.driver,
          const Shell(),
          size: const Size(1180, 760),
          reduceMotion: true,
        );
        await t.pumpAndSettle();
        await t.tap(find.byIcon(Icons.settings_outlined));
        await t.pumpAndSettle();
        await t.tap(_settingsRow('Controles'));
        await t.pumpAndSettle();
        expect(find.byType(ControllersPage), findsOneWidget);
        await t.tap(find.text('Ensinar um controle novo'));
        await t.pumpAndSettle();
        expect(find.byType(TeachPage), findsOneWidget);
        expect(rig.driver.teaching, isNotNull);

        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pumpAndSettle();
        expect(rig.driver.teaching, isNull, reason: 'the driver took it');
        expect(find.byType(TeachPage), findsNothing);
        expect(find.byType(ControllersPage), findsOneWidget);

        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pumpAndSettle();
        expect(find.byType(ControllersPage), findsNothing);
        expect(find.byType(TeachPage), findsNothing);
        expect(t.takeException(), isNull);
      },
      keyboard: true,
      prefs: {'onScreen': false},
    );

    _rigTest('a click outside goes back from the wizard and ends it', (
      t,
      rig,
    ) async {
      await rig.plug(t);
      await pumpWithDriver(
        t,
        rig.driver,
        const Shell(),
        size: const Size(1180, 760),
        reduceMotion: true,
      );
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.settings_outlined));
      await t.pumpAndSettle();
      await t.tap(_settingsRow('Controles'));
      await t.pumpAndSettle();
      await t.tap(find.text('Ensinar um controle novo'));
      await t.pumpAndSettle();
      expect(rig.driver.teaching, isNotNull);

      // A click on the dimmed part, left of the panel, is a back: the panel
      // closes a page before it closes itself.
      await t.tapAt(const Offset(100, 400));
      await t.pumpAndSettle();
      expect(find.byType(TeachPage), findsNothing);
      expect(find.byType(ControllersPage), findsOneWidget);
      expect(rig.driver.teaching, isNull);

      // The next one closes the panel.
      await t.tapAt(const Offset(100, 400));
      await t.pumpAndSettle();
      expect(find.byType(ControllersPage), findsNothing);
      expect(t.takeException(), isNull);
    }, prefs: {'onScreen': false});

    _rigTest(
      'a finished wizard does not hold the panel: Esc closes it',
      (t, rig) async {
        await rig.plug(t);
        await pumpWithDriver(
          t,
          rig.driver,
          const Shell(),
          size: const Size(1180, 760),
          reduceMotion: true,
        );
        await t.pumpAndSettle();
        await t.tap(find.byIcon(Icons.settings_outlined));
        await t.pumpAndSettle();
        await t.tap(_settingsRow('Controles'));
        await t.pumpAndSettle();
        await t.tap(find.text('Ensinar um controle novo'));
        await t.pumpAndSettle();
        await _skip(t, teachSteps.length);
        expect(find.text('Pronto'), findsOneWidget);

        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pumpAndSettle();
        expect(find.byType(TeachPage), findsNothing);
        expect(find.byType(ControllersPage), findsNothing);
        expect(rig.driver.teaching, isNull);
      },
      keyboard: true,
      prefs: {'onScreen': false},
    );
  });
}
