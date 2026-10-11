import 'dart:async';

import 'package:ble_rc_controller/core/car_transport.dart';
import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/core/protocol.dart';
import 'package:ble_rc_controller/input/bindings.dart';
import 'package:ble_rc_controller/input/input_ref.dart';
import 'package:ble_rc_controller/input/pad_input.dart';
import 'package:ble_rc_controller/l10n/gen/app_localizations.dart';
import 'package:ble_rc_controller/ui/cockpit/key_legend.dart';
import 'package:ble_rc_controller/ui/cockpit/state_cells.dart';
import 'package:ble_rc_controller/ui/cockpit/touch_pads.dart';
import 'package:ble_rc_controller/ui/common/glass.dart';
import 'package:ble_rc_controller/ui/strings.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_transport.dart';
import 'support/harness.dart';

/// A driver with a connected car, plus what a test needs to poke at it.
class _Rig {
  _Rig(this.driver, this.transport, this.controllers);

  final Driver driver;
  final FakeTransport transport;

  /// Plug a controller in with a `connected` event.
  final StreamController<GamepadConnectionEvent> controllers;

  bool _disposed = false;

  void plugIn(String name, {String id = 'g1'}) => controllers.add(
    GamepadConnectionEvent(
      gamepadId: id,
      name: name,
      type: GamepadConnectionEventType.connected,
    ),
  );

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    driver.dispose();
    controllers.close();
  }
}

/// Builds a driver, scans one car and connects to it. The timers are the
/// test's fake ones, so `pump(Duration)` runs the driver's 20 ms tick.
Future<_Rig> _connected(WidgetTester t) async {
  SharedPreferences.setMockInitialValues({});
  final transport = FakeTransport();
  final controllers = StreamController<GamepadConnectionEvent>.broadcast();
  final driver = Driver(
    transport: transport,
    prefs: await SharedPreferences.getInstance(),
    rawEvents: const Stream<GamepadEvent>.empty(),
    connectionEvents: controllers.stream,
    listGamepads: () async => [],
    enableKeyboard: false,
  );
  final rig = _Rig(driver, transport, controllers);
  addTearDown(rig.dispose);
  await driver.start();
  transport.scan.add(const FoundCar(id: 'car1', name: 'SL-SF-25', rssi: -55));
  await t.pump(const Duration(milliseconds: 70));
  await driver.connect('car1');
  await t.pump();
  expect(driver.link, LinkState.connected);
  return rig;
}

/// Takes the widgets down first, then the driver, as the app does.
Future<void> _finish(WidgetTester t, _Rig rig) async {
  await t.pumpWidget(const SizedBox());
  rig.dispose();
}

/// Lets the driver tick and the 220 ms light-up of the legend finish.
Future<void> _settle(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 40));
  await t.pump(const Duration(milliseconds: 300));
}

List<Glass> _glasses(WidgetTester t) =>
    t.widgetList<Glass>(find.byType(Glass)).toList();

Future<AppLocalizations> _l10n(String code) =>
    AppLocalizations.delegate.load(Locale(code));

/// The RGBA of the pixel ([x], [y]) that the repaint boundary [key] draws. The
/// harness has a pixel ratio of 1, so a logical pixel is one pixel.
Future<List<int>> _pixel(WidgetTester t, GlobalKey key, int x, int y) async {
  final px = await t.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!; // raw RGBA
    final at = (y * image.width + x) * 4;
    image.dispose();
    return [for (var i = 0; i < 4; i++) bytes.getUint8(at + i)];
  });
  return px!;
}

/// The opacity of the top of the fill of the [index]th glass: 4% when idle, 10%
/// when active, and in between while it changes.
double _fillTop(WidgetTester t, int index) {
  final d = t
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(Glass).at(index),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((b) => b.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.border != null);
  return d.gradient == null
      ? d.color!.a
      : (d.gradient! as LinearGradient).colors.first.a;
}

/// The colour the text [s] is painted with, after every style is merged.
Color? _textColor(WidgetTester t, String s) =>
    (t.renderObject<RenderParagraph>(find.text(s)).text as TextSpan)
        .style
        ?.color;

void main() {
  group('padGlyph', () {
    test('uses the PlayStation symbols the approved design shows', () {
      expect(padGlyph(PadInput.a), '✕');
      expect(padGlyph(PadInput.b), '○');
      expect(padGlyph(PadInput.x), '□');
      expect(padGlyph(PadInput.y), '△');
      expect(padGlyph(PadInput.leftBumper), 'L1');
      expect(padGlyph(PadInput.rightBumper), 'R1');
      expect(padGlyph(PadInput.leftTrigger), 'L2');
      expect(padGlyph(PadInput.rightTrigger), 'R2');
      expect(padGlyph(PadInput.back), 'Share');
      expect(padGlyph(PadInput.start), 'Options');
      expect(padGlyph(PadInput.home), 'PS');
      expect(padGlyph(PadInput.leftStick), 'L3');
      expect(padGlyph(PadInput.rightStick), 'R3');
      expect(padGlyph(PadInput.touchpad), 'Touchpad');
    });

    test(
      'draws the D-pad as arrows and the sticks as a letter and an arrow',
      () {
        expect(padGlyph(PadInput.dpadUp), '↑');
        expect(padGlyph(PadInput.dpadDown), '↓');
        expect(padGlyph(PadInput.dpadLeft), '←');
        expect(padGlyph(PadInput.dpadRight), '→');
        expect(padGlyph(PadInput.leftStickUp), 'L ↑');
        expect(padGlyph(PadInput.leftStickDown), 'L ↓');
        expect(padGlyph(PadInput.leftStickLeft), 'L ←');
        expect(padGlyph(PadInput.leftStickRight), 'L →');
        expect(padGlyph(PadInput.rightStickUp), 'R ↑');
        expect(padGlyph(PadInput.rightStickDown), 'R ↓');
        expect(padGlyph(PadInput.rightStickLeft), 'R ←');
        expect(padGlyph(PadInput.rightStickRight), 'R →');
      },
    );

    test(
      'gives every input its own non-empty symbol, never in capitals only',
      () {
        final all = [for (final p in PadInput.values) padGlyph(p)];
        expect(all, everyElement(isNotEmpty));
        expect(all.toSet(), hasLength(PadInput.values.length));
        // Words are in normal case; only the short codes (L1, PS...) are capitals.
        for (final g in all.where((g) => g.length > 3)) {
          expect(g, isNot(g.toUpperCase()), reason: g);
        }
      },
    );
  });

  group('shortcutSymbol', () {
    test('is the first controller input, with PlayStation symbols', () async {
      final l = await _l10n('pt');
      final b = defaultBindings();
      expect(shortcutSymbol(l, b, CarAction.light), '✕');
      expect(shortcutSymbol(l, b, CarAction.turbo), '○');
      expect(shortcutSymbol(l, b, CarAction.donut), '△');
    });

    test('takes the first controller input when there are several', () async {
      final l = await _l10n('pt');
      final b = {
        CarAction.turbo: [
          InputRef.key(PhysicalKeyboardKey.space),
          InputRef.pad(PadInput.rightBumper),
          InputRef.pad(PadInput.b),
        ],
      };
      expect(shortcutSymbol(l, b, CarAction.turbo), 'R1');
    });

    test(
      'writes a signal the app does not know the way the settings do',
      () async {
        final l = await _l10n('pt');
        final raw = InputRef.raw('KEYCODE_FOO', 1);
        final b = {
          CarAction.turbo: [InputRef.key(PhysicalKeyboardKey.space), raw],
        };
        expect(shortcutSymbol(l, b, CarAction.turbo), l.input(raw));
      },
    );

    test('falls back to the first key, in the app language', () async {
      final b = {
        CarAction.turbo: [
          InputRef.key(PhysicalKeyboardKey.space),
          InputRef.key(PhysicalKeyboardKey.keyT),
        ],
        CarAction.light: [InputRef.key(PhysicalKeyboardKey.keyL)],
      };
      expect(shortcutSymbol(await _l10n('pt'), b, CarAction.turbo), 'Espaço');
      expect(shortcutSymbol(await _l10n('es'), b, CarAction.turbo), 'Espacio');
      expect(shortcutSymbol(await _l10n('en'), b, CarAction.turbo), 'Space');
      expect(shortcutSymbol(await _l10n('pt'), b, CarAction.light), 'L');
    });

    test('names the Space key in every place a key is written', () async {
      final space = InputRef.key(PhysicalKeyboardKey.space);
      expect((await _l10n('pt')).keyName(space), 'Espaço');
      expect((await _l10n('pt')).input(space), 'Espaço');
      expect((await _l10n('es')).input(space), 'Espacio');
      expect((await _l10n('en')).input(space), 'Space');
      // Other keys keep their label.
      final w = InputRef.key(PhysicalKeyboardKey.keyW);
      expect((await _l10n('pt')).keyName(w), 'W');
    });

    test('is null when the action has no input at all', () async {
      final l = await _l10n('pt');
      expect(shortcutSymbol(l, {CarAction.turbo: []}, CarAction.turbo), isNull);
      expect(shortcutSymbol(l, {}, CarAction.donut), isNull);
    });
  });

  group('StateCells', () {
    testWidgets('show the four cells with label, shortcut and value', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));

      for (final s in [
        'Luz', 'Turbo', 'Giro 360°', 'Controle', // labels
        '✕', '○', '△', // shortcuts of the default controller bindings
        'Apagada', 'Desligado', 'Parado', 'Nenhum controle', // values
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      expect(find.byType(Glass), findsNWidgets(4));
      expect(_glasses(t).every((g) => !g.active), isTrue);
      await _finish(t, rig);
    });

    testWidgets('speak the three languages', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(
        t,
        rig.driver,
        const StateCells(tappable: true),
        locale: 'en',
      );
      for (final s in [
        'Light',
        'Turbo',
        '360° spin',
        'Controller',
        'No controller',
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      expect(find.text('Off'), findsNWidgets(2)); // light and turbo
      expect(find.text('Stopped'), findsOneWidget);

      await pumpWithDriver(
        t,
        rig.driver,
        const StateCells(tappable: true),
        locale: 'es',
      );
      await t.pump();
      for (final s in [
        'Luz',
        'Giro 360°',
        'Mando',
        'Ningún mando',
        'Apagada',
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      await _finish(t, rig);
    });

    testWidgets('Turbo: one tap latches it on, a second tap switches it off', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));

      await t.tap(find.text('Turbo'));
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.turbo, isTrue);
      expect(rig.driver.isLatched(CarAction.turbo), isTrue);

      await t.pump(const Duration(milliseconds: 300)); // finger long gone
      expect(rig.driver.command.turbo, isTrue, reason: 'it stays on');
      expect(find.text('Ativo'), findsOneWidget);
      expect(find.text('Desligado'), findsNothing);
      expect(_glasses(t)[1].active, isTrue, reason: 'the Turbo cell is amber');
      expect(_glasses(t)[0].active, isFalse);

      await t.tap(find.text('Turbo'));
      await _settle(t);
      expect(rig.driver.command.turbo, isFalse);
      expect(find.text('Desligado'), findsOneWidget);
      expect(find.text('Ativo'), findsNothing);
      expect(_glasses(t)[1].active, isFalse);
      await _finish(t, rig);
    });

    testWidgets('Light: a tap switches it on, another switches it off', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));

      await t.tap(find.text('Luz'));
      await _settle(t);
      expect(rig.driver.command.light, isTrue);
      expect(find.text('Acesa'), findsOneWidget);
      expect(_glasses(t)[0].active, isTrue);
      expect(
        rig.driver.isLatched(CarAction.light),
        isFalse,
        reason: 'the light is a toggle in the driver, not a latch',
      );

      await t.tap(find.text('Luz'));
      await _settle(t);
      expect(rig.driver.command.light, isFalse);
      expect(find.text('Apagada'), findsOneWidget);
      expect(_glasses(t)[0].active, isFalse);
      await _finish(t, rig);
    });

    testWidgets(
      'Light is pressed while the finger is down and released after',
      (t) async {
        final rig = await _connected(t);
        await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));

        final g = await t.startGesture(t.getCenter(find.text('Luz')));
        await t.pump(const Duration(milliseconds: 40));
        expect(rig.driver.command.light, isTrue, reason: 'the press flips it');
        await g.up();
        await t.pump(const Duration(milliseconds: 40));
        expect(rig.driver.command.light, isTrue, reason: 'letting go keeps it');

        // A new press flips it again: the release really reached the driver.
        final g2 = await t.startGesture(t.getCenter(find.text('Luz')));
        await t.pump(const Duration(milliseconds: 40));
        expect(rig.driver.command.light, isFalse);
        await g2.up();
        await _finish(t, rig);
      },
    );

    testWidgets('360° spin latches on with one tap, like Turbo', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));

      await t.tap(find.text('Giro 360°'));
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.donut, isTrue);
      await t.pump(const Duration(milliseconds: 300));
      expect(rig.driver.command.donut, isTrue);
      expect(find.text('Girando'), findsOneWidget);
      expect(_glasses(t)[2].active, isTrue);

      await t.tap(find.text('Giro 360°'));
      await _settle(t);
      expect(rig.driver.command.donut, isFalse);
      expect(find.text('Parado'), findsOneWidget);
      await _finish(t, rig);
    });

    testWidgets(
      'a latched Turbo is released when the app goes to the background',
      (t) async {
        final rig = await _connected(t);
        await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));

        await t.tap(find.text('Turbo'));
        await t.pump(const Duration(milliseconds: 40));
        expect(rig.driver.command.turbo, isTrue);
        expect(find.text('Ativo'), findsOneWidget);

        rig.driver.didChangeAppLifecycleState(AppLifecycleState.paused);
        await _settle(t);
        expect(rig.driver.isLatched(CarAction.turbo), isFalse);
        expect(rig.driver.command.turbo, isFalse);
        expect(find.text('Desligado'), findsOneWidget);
        expect(find.text('Ativo'), findsNothing);
        expect(_glasses(t)[1].active, isFalse);
        await _finish(t, rig);
      },
    );

    testWidgets('a latched 360° spin is released when the car disconnects', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));

      await t.tap(find.text('Giro 360°'));
      await t.pump(const Duration(milliseconds: 40));
      expect(find.text('Girando'), findsOneWidget);

      await t.runAsync(rig.driver.disconnect);
      await _settle(t);
      expect(rig.driver.isLatched(CarAction.donut), isFalse);
      expect(find.text('Parado'), findsOneWidget);
      await _finish(t, rig);
    });

    testWidgets('without tappable the cells only show the state', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const StateCells(tappable: false));

      await t.tap(find.text('Turbo'));
      await t.tap(find.text('Luz'));
      await t.tap(find.text('Giro 360°'));
      await _settle(t);
      expect(rig.driver.command.turbo, isFalse);
      expect(rig.driver.command.light, isFalse);
      expect(rig.driver.command.donut, isFalse);

      // The state still follows whatever drives the car (controller, keys).
      rig.driver.setVirtual(CarAction.turbo, true);
      await _settle(t);
      expect(find.text('Ativo'), findsOneWidget);
      expect(_glasses(t)[1].active, isTrue);
      rig.driver.setVirtual(CarAction.turbo, false);
      await _finish(t, rig);
    });

    testWidgets(
      'the Controller cell shows the first controller and never reacts',
      (t) async {
        final rig = await _connected(t);
        await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));
        expect(find.text('Nenhum controle'), findsOneWidget);

        rig.plugIn('DualShock 4');
        await _settle(t);
        expect(find.text('DualShock 4'), findsOneWidget);
        expect(find.text('Nenhum controle'), findsNothing);

        // With two, the one that came first.
        rig.plugIn('Xbox Wireless', id: 'g2');
        await _settle(t);
        expect(find.text('DualShock 4'), findsOneWidget);
        expect(find.text('Xbox Wireless'), findsNothing);
        expect(_glasses(t)[3].active, isFalse, reason: 'never amber');

        await t.tap(find.text('DualShock 4'));
        await _settle(t);
        final c = rig.driver.command;
        expect([
          c.forward,
          c.reverse,
          c.left,
          c.right,
          c.light,
          c.turbo,
          c.donut,
        ], everyElement(isFalse));
        expect(rig.driver.isLatched(CarAction.turbo), isFalse);
        expect(_glasses(t)[3].active, isFalse);
        await _finish(t, rig);
      },
    );

    testWidgets(
      'the shortcut follows the bindings: first controller input, then first key',
      (t) async {
        final rig = await _connected(t);
        await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));
        expect(find.text('○'), findsOneWidget);

        rig.driver.removeBinding(CarAction.turbo, InputRef.pad(PadInput.b));
        await t.pump();
        expect(find.text('○'), findsNothing);
        expect(find.text('Espaço'), findsOneWidget, reason: 'the first key');

        rig.driver.addBinding(
          CarAction.turbo,
          InputRef.pad(PadInput.rightBumper),
        );
        await t.pump();
        expect(find.text('R1'), findsOneWidget);
        expect(find.text('Espaço'), findsNothing);
        await _finish(t, rig);
      },
    );

    testWidgets(
      'are a 2 by 2 grid by default and one row of four with columns: 4',
      (t) async {
        final rig = await _connected(t);
        await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));
        var tops = [
          for (final g in _glasses(t)) t.getTopLeft(find.byWidget(g)),
        ];
        expect(tops[0].dy, tops[1].dy);
        expect(tops[2].dy, tops[3].dy);
        expect(tops[2].dy, greaterThan(tops[0].dy));
        expect(tops[0].dx, tops[2].dx);
        expect(tops[1].dx, greaterThan(tops[0].dx));

        await pumpWithDriver(
          t,
          rig.driver,
          const StateCells(tappable: true, columns: 4),
        );
        await t.pump();
        tops = [for (final g in _glasses(t)) t.getTopLeft(find.byWidget(g))];
        expect({for (final p in tops) p.dy}, hasLength(1));
        expect({for (final p in tops) p.dx}, hasLength(4));
        await _finish(t, rig);
      },
    );

    testWidgets('are at least 56 high and 48 wide, in every language', (
      t,
    ) async {
      final rig = await _connected(t);
      for (final (size, code) in [
        (const Size(320, 568), 'es'),
        (const Size(390, 844), 'pt'),
        (const Size(1180, 760), 'en'),
      ]) {
        await pumpWithDriver(
          t,
          rig.driver,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: StateCells(
              tappable: true,
              columns: size.width > 900 ? 4 : 2,
            ),
          ),
          size: size,
          locale: code,
        );
        await t.pump();
        for (final g in _glasses(t)) {
          final s = t.getSize(find.byWidget(g));
          expect(s.height, greaterThanOrEqualTo(56), reason: '$size $code');
          expect(s.width, greaterThanOrEqualTo(48), reason: '$size $code');
        }
        expect(t.takeException(), isNull, reason: '$size $code');
      }
      await _finish(t, rig);
    });

    testWidgets('a very long controller name is cut, not overflowing', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(
        t,
        rig.driver,
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: StateCells(tappable: true),
        ),
        size: const Size(320, 568),
      );
      rig.plugIn('Wireless Controller Pro Elite Series 2 Limited Edition');
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.textContaining('Wireless Controller'), findsOneWidget);
      await _finish(t, rig);
    });

    testWidgets('a cell fades to amber: halfway at 100 ms, done by 250 ms', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));
      expect(_fillTop(t, 1), closeTo(0.04, 0.001), reason: 'idle glass');

      await t.tap(find.text('Turbo'));
      await t.pump(); // the frame that starts the fade
      expect(rig.driver.command.turbo, isTrue);
      expect(
        _textColor(t, 'Ativo'),
        AppColors.text2,
        reason: 'the value starts from its idle colour, not from white',
      );
      await t.pump(const Duration(milliseconds: 100));
      final mid = _fillTop(t, 1);
      expect(mid, inExclusiveRange(0.05, 0.095), reason: 'in the middle');
      expect(
        _textColor(t, 'Ativo')!.b,
        inExclusiveRange(AppColors.amber.b, AppColors.text2.b),
        reason: 'between the idle grey and amber',
      );
      expect(_fillTop(t, 0), closeTo(0.04, 0.001), reason: 'Light is unmoved');

      await t.pump(const Duration(milliseconds: 150));
      expect(_fillTop(t, 1), closeTo(0.10, 0.001));
      expect(_textColor(t, 'Ativo'), AppColors.amber);
      expect(t.binding.transientCallbackCount, 0);

      // And back to plain glass when it is switched off.
      await t.tap(find.text('Turbo'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(_fillTop(t, 1), inExclusiveRange(0.045, 0.095));
      await t.pump(const Duration(milliseconds: 150));
      expect(_fillTop(t, 1), closeTo(0.04, 0.001));
      await _finish(t, rig);
    });

    testWidgets('with reduce motion a cell lights up at once', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(
        t,
        rig.driver,
        const StateCells(tappable: true),
        reduceMotion: true,
      );
      await t.tap(find.text('Turbo'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 1));
      expect(_fillTop(t, 1), closeTo(0.10, 0.001));
      expect(_textColor(t, 'Ativo'), AppColors.amber);
      await _finish(t, rig);
    });

    testWidgets('the tappable cells are named buttons, with their state', (
      t,
    ) async {
      final rig = await _connected(t);
      final handle = t.ensureSemantics();
      await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));

      for (final label in [
        'Luz, Apagada',
        'Turbo, Desligado',
        'Giro 360°, Parado',
      ]) {
        expect(
          t.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(isButton: true, hasTapAction: true, label: label),
          reason: label,
        );
      }
      // The Controller cell has a name too, but it is not a button.
      final ctl = t.getSemantics(
        find.bySemanticsLabel('Controle, Nenhum controle'),
      );
      expect(ctl, isSemantics(isButton: false, hasTapAction: false));

      // A screen reader activating a cell does what a finger does.
      t.semantics.tap(find.semantics.byLabel('Turbo, Desligado'));
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.turbo, isTrue);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.bySemanticsLabel('Turbo, Ativo'), findsOneWidget);

      t.semantics.tap(find.semantics.byLabel('Luz, Apagada'));
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.light, isTrue);
      handle.dispose();
      await _finish(t, rig);
    });

    testWidgets('without tappable the cells are named but not buttons', (
      t,
    ) async {
      final rig = await _connected(t);
      final handle = t.ensureSemantics();
      await pumpWithDriver(t, rig.driver, const StateCells(tappable: false));

      final node = t.getSemantics(find.bySemanticsLabel('Turbo, Desligado'));
      expect(node, isSemantics(isButton: false, hasTapAction: false));
      handle.dispose();
      await _finish(t, rig);
    });

    testWidgets('a Light cell removed while the finger is down lets go', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));
      final g = await t.startGesture(t.getCenter(find.text('Luz')));
      await t.pump(const Duration(milliseconds: 40));

      await pumpWithDriver(t, rig.driver, const SizedBox());
      await t.pump(const Duration(milliseconds: 40));
      expect(t.takeException(), isNull);

      // If the press had stayed in the driver this tap would not flip the light.
      await g.up();
      await pumpWithDriver(t, rig.driver, const StateCells(tappable: true));
      final before = rig.driver.command.light;
      await t.tap(find.text('Luz'));
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.light, !before);
      await _finish(t, rig);
    });
  });

  group('TouchPads', () {
    final up = find.byIcon(Icons.arrow_upward_rounded);
    final down = find.byIcon(Icons.arrow_downward_rounded);
    final left = find.byIcon(Icons.arrow_back_rounded);
    final right = find.byIcon(Icons.arrow_forward_rounded);

    testWidgets('are four arrows in the order left, right, down, up', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const TouchPads());
      expect(find.byType(Glass), findsNWidgets(4));
      final xs = [
        for (final f in [left, right, down, up]) t.getCenter(f).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
      expect(xs.toSet(), hasLength(4));
      await _finish(t, rig);
    });

    testWidgets('holding up drives forward and letting go stops', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const TouchPads());

      final g = await t.startGesture(t.getCenter(up));
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.forward, isTrue);
      await t.pump(const Duration(milliseconds: 300));
      expect(rig.driver.command.forward, isTrue, reason: 'still held');

      await g.up();
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.forward, isFalse);
      await _finish(t, rig);
    });

    testWidgets('each arrow drives its own action', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const TouchPads());

      for (final (icon, read) in <(Finder, bool Function(CarCommand))>[
        (left, (cmd) => cmd.left),
        (right, (cmd) => cmd.right),
        (down, (cmd) => cmd.reverse),
        (up, (cmd) => cmd.forward),
      ]) {
        final g = await t.startGesture(t.getCenter(icon));
        await t.pump(const Duration(milliseconds: 40));
        expect(read(rig.driver.command), isTrue);
        await g.up();
        await t.pump(const Duration(milliseconds: 40));
        expect(read(rig.driver.command), isFalse);
      }
      await _finish(t, rig);
    });

    testWidgets('can be held together, with two fingers', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const TouchPads());

      final steer = await t.startGesture(t.getCenter(left));
      final gas = await t.startGesture(t.getCenter(up));
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.left, isTrue);
      expect(rig.driver.command.forward, isTrue);

      await gas.up();
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.forward, isFalse);
      expect(
        rig.driver.command.left,
        isTrue,
        reason: 'the other finger is down',
      );

      await steer.up();
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.left, isFalse);
      await _finish(t, rig);
    });

    testWidgets('two fingers on one arrow keep it held until both lift', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const TouchPads());
      final first = await t.startGesture(t.getCenter(up));
      final second = await t.startGesture(t.getCenter(up) + const Offset(5, 5));
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.forward, isTrue);

      await first.up();
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.forward, isTrue, reason: 'one finger is left');

      await second.up();
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.forward, isFalse);
      await _finish(t, rig);
    });

    testWidgets('sliding off an arrow keeps it held until the finger lifts', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const TouchPads());
      final g = await t.startGesture(t.getCenter(up));
      await g.moveBy(const Offset(0, 300));
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.forward, isTrue);
      await g.up();
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.forward, isFalse);
      await _finish(t, rig);
    });

    testWidgets('a cancelled touch (a system gesture) lets go too', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const TouchPads());
      final g = await t.startGesture(t.getCenter(up));
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.forward, isTrue);
      await g.cancel();
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.forward, isFalse);
      await _finish(t, rig);
    });

    testWidgets('an arrow removed while held does not leave the car running', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const TouchPads());
      final g = await t.startGesture(t.getCenter(up));
      await t.pump(const Duration(milliseconds: 40));
      expect(rig.driver.command.forward, isTrue);

      // The layout changes (the phone turns) and the pads go away.
      await pumpWithDriver(t, rig.driver, const SizedBox());
      await t.pump(const Duration(milliseconds: 40));
      expect(t.takeException(), isNull);
      expect(rig.driver.command.forward, isFalse);
      await g.up();
      await _finish(t, rig);
    });

    testWidgets('fade to amber in 150 ms, quicker than the cells', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const TouchPads());
      expect(_fillTop(t, 3), closeTo(0.04, 0.001));

      final g = await t.startGesture(t.getCenter(up));
      await t.pump(); // the frame that starts the fade
      await t.pump(const Duration(milliseconds: 60));
      expect(_fillTop(t, 3), inExclusiveRange(0.05, 0.095), reason: 'at 60 ms');
      await t.pump(const Duration(milliseconds: 100));
      expect(_fillTop(t, 3), closeTo(0.10, 0.001), reason: 'done by 160 ms');
      expect(_fillTop(t, 0), closeTo(0.04, 0.001), reason: 'others unmoved');

      await g.up();
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      expect(_fillTop(t, 3), inExclusiveRange(0.045, 0.095));
      await t.pump(const Duration(milliseconds: 100));
      expect(_fillTop(t, 3), closeTo(0.04, 0.001));
      await _finish(t, rig);
    });

    testWidgets('the icon and the halo fade in with the glass, in 150 ms', (
      t,
    ) async {
      final rig = await _connected(t);
      final key = GlobalKey();
      await pumpWithDriver(
        t,
        rig.driver,
        RepaintBoundary(
          key: key,
          child: const ColoredBox(
            color: Colors.black,
            child: Padding(padding: EdgeInsets.all(30), child: TouchPads()),
          ),
        ),
      );
      final pad = find.byType(Glass).last;
      final origin = t.getTopLeft(find.byKey(key));
      final rect = t.getRect(pad);
      // Just under the pad, where only the halo can be.
      final x = (rect.center.dx - origin.dx).round();
      final y = (rect.bottom - origin.dy).round() + 4;
      final icon = find.byIcon(Icons.arrow_upward_rounded);
      double iconBlue() => t.widget<Icon>(icon).color!.b;
      expect(t.widget<Icon>(icon).color, AppColors.text2);
      expect((await _pixel(t, key, x, y))[0], 0, reason: 'no halo at rest');

      final g = await t.startGesture(t.getCenter(icon));
      await t.pump(); // the frame that starts the fade
      await t.pump(const Duration(milliseconds: 60));
      expect(
        iconBlue(),
        inExclusiveRange(AppColors.amber.b, AppColors.text2.b),
      );
      final mid = (await _pixel(t, key, x, y))[0];
      expect(mid, greaterThan(0), reason: 'the halo is coming in');

      await t.pump(const Duration(milliseconds: 100));
      expect(t.widget<Icon>(icon).color, AppColors.amber);
      final full = (await _pixel(t, key, x, y))[0];
      expect(full, greaterThan(mid), reason: 'and done by 160 ms');
      expect(t.widget<Icon>(icon).shadows, isNotEmpty);

      await g.up();
      await t.pump();
      await t.pump(const Duration(milliseconds: 160));
      expect(t.widget<Icon>(icon).color, AppColors.text2);
      expect((await _pixel(t, key, x, y))[0], 0, reason: 'halo gone again');
      expect(t.widget<Icon>(icon).shadows, isNull);
      await _finish(t, rig);
    });

    testWidgets('light up at once with reduce motion', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(
        t,
        rig.driver,
        const TouchPads(),
        reduceMotion: true,
      );
      final g = await t.startGesture(t.getCenter(up));
      await t.pump();
      await t.pump(const Duration(milliseconds: 1));
      expect(_fillTop(t, 3), closeTo(0.10, 0.001));
      await g.up();
      await _finish(t, rig);
    });

    testWidgets('light up amber while pressed, and drop 1 px', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const TouchPads());
      expect(_glasses(t).every((g) => !g.active), isTrue);
      final rest = t.getTopLeft(find.byType(Glass).last);

      final g = await t.startGesture(t.getCenter(up));
      await t.pump(const Duration(milliseconds: 40));
      expect(_glasses(t).map((g) => g.active), [false, false, false, true]);
      expect(t.getTopLeft(find.byType(Glass).last).dy, rest.dy + 1);

      await g.up();
      await t.pump(const Duration(milliseconds: 40));
      expect(_glasses(t).every((g) => !g.active), isTrue);
      expect(t.getTopLeft(find.byType(Glass).last).dy, rest.dy);
      await _finish(t, rig);
    });

    testWidgets('fill the row in four equal columns, 54 high, 10 apart', (
      t,
    ) async {
      final rig = await _connected(t);
      for (final (width, side) in [
        (222.0, 48.0), // the smallest row that keeps a 48 wide target
        (320.0, 72.5), // (320 - 3 * 10) / 4
        (354.0, 81.0), // a 390 phone minus its margins
        (480.0, 112.5), // the widest row the cockpit gives them
      ]) {
        await pumpWithDriver(
          t,
          rig.driver,
          SizedBox(width: width, child: const TouchPads()),
          size: Size(width + 40, 400),
        );
        await t.pump();
        final rects = [
          for (var i = 0; i < 4; i++) t.getRect(find.byType(Glass).at(i)),
        ];
        for (final r in rects) {
          expect(r.width, closeTo(side, 0.01), reason: 'width $width');
          expect(r.height, 54, reason: 'width $width');
        }
        for (var i = 1; i < 4; i++) {
          expect(
            rects[i].left - rects[i - 1].right,
            closeTo(10, 0.01),
            reason: 'gap $i at width $width',
          );
        }
        expect(rects.first.left, 20, reason: 'the row starts at its edge');
        expect(rects.last.right, closeTo(20 + width, 0.01));
        expect(t.takeException(), isNull, reason: 'width $width');
      }
      await _finish(t, rig);
    });

    testWidgets('fit a 320 wide phone', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(
        t,
        rig.driver,
        const Padding(padding: EdgeInsets.all(18), child: TouchPads()),
        size: const Size(320, 568),
      );
      expect(t.takeException(), isNull);
      expect(t.getRect(up).right, lessThanOrEqualTo(320 - 18));
      expect(t.getRect(left).left, greaterThanOrEqualTo(18));
      await _finish(t, rig);
    });

    testWidgets('are named buttons for a screen reader', (t) async {
      final rig = await _connected(t);
      final handle = t.ensureSemantics();
      await pumpWithDriver(t, rig.driver, const TouchPads());
      for (final label in ['Esquerda', 'Direita', 'Ré', 'Frente']) {
        expect(
          t.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(isButton: true, hasTapAction: true, label: label),
          reason: label,
        );
      }
      handle.dispose();
      await _finish(t, rig);
    });

    testWidgets('a tap from a screen reader presses the arrow and lets go', (
      t,
    ) async {
      final rig = await _connected(t);
      final handle = t.ensureSemantics();
      await pumpWithDriver(t, rig.driver, const TouchPads());
      expect(rig.driver.command.forward, isFalse);
      final writes = rig.transport.writes.length;

      // The double tap of TalkBack and VoiceOver: no pointer, only the action.
      t.semantics.tap(find.semantics.byLabel('Frente'));
      await t.pump(const Duration(milliseconds: 60));
      expect(rig.driver.command.forward, isTrue, reason: 'pressed');
      expect(rig.driver.command.reverse, isFalse);
      expect(rig.transport.writes.length, greaterThan(writes), reason: 'sent');

      // It does not hold: a screen reader cannot, and the car must not run on.
      await t.pump(const Duration(milliseconds: 400));
      expect(rig.driver.command.forward, isFalse, reason: 'let go');
      handle.dispose();
      await _finish(t, rig);
    });

    testWidgets('each arrow does its own action from a screen reader', (
      t,
    ) async {
      final rig = await _connected(t);
      final handle = t.ensureSemantics();
      await pumpWithDriver(t, rig.driver, const TouchPads());
      for (final (label, read) in <(String, bool Function(CarCommand))>[
        ('Esquerda', (c) => c.left),
        ('Direita', (c) => c.right),
        ('Ré', (c) => c.reverse),
        ('Frente', (c) => c.forward),
      ]) {
        t.semantics.tap(find.semantics.byLabel(label));
        await t.pump(const Duration(milliseconds: 60));
        expect(read(rig.driver.command), isTrue, reason: label);
        await t.pump(const Duration(milliseconds: 400));
        expect(read(rig.driver.command), isFalse, reason: '$label let go');
      }
      handle.dispose();
      await _finish(t, rig);
    });

    testWidgets('a finger that holds the arrow is not let go by the pulse', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const TouchPads());
      final hold = await t.startGesture(t.getCenter(up));
      await t.pump(const Duration(milliseconds: 60));
      expect(rig.driver.command.forward, isTrue);
      rig.driver.pulse(CarAction.forward);
      await t.pump(const Duration(milliseconds: 400));
      expect(rig.driver.command.forward, isTrue, reason: 'still held');
      await hold.up();
      await t.pump(const Duration(milliseconds: 60));
      expect(rig.driver.command.forward, isFalse);
      await _finish(t, rig);
    });
  });

  group('text size', () {
    testWidgets(
      'cells, arrows and legend survive 200% text on a 320 wide phone',
      (t) async {
        final rig = await _connected(t);
        await pumpWithDriver(
          t,
          rig.driver,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  children: [
                    StateCells(tappable: true),
                    TouchPads(),
                    KeyLegend(),
                  ],
                ),
              ),
            ),
          ),
          size: const Size(320, 900),
          locale: 'es',
        );
        rig.plugIn('Wireless Controller');
        await t.pump();
        expect(t.takeException(), isNull);
        await _finish(t, rig);
      },
    );
  });

  group('legendKeys', () {
    test('lists the keys of an action, arrows last, at most two', () {
      final b = defaultBindings();
      expect(legendKeys(b, CarAction.forward).map((r) => r.keyText), [
        'W',
        '↑',
      ]);
      expect(legendKeys(b, CarAction.reverse).map((r) => r.keyText), [
        'S',
        '↓',
      ]);
      expect(legendKeys(b, CarAction.turbo).map((r) => r.keyText), ['Space']);
      expect(legendKeys(b, CarAction.light).map((r) => r.keyText), ['L']);
      expect(legendKeys(b, CarAction.donut).map((r) => r.keyText), ['Q']);

      final many = {
        CarAction.forward: [
          InputRef.key(PhysicalKeyboardKey.arrowUp),
          InputRef.key(PhysicalKeyboardKey.keyI),
          InputRef.key(PhysicalKeyboardKey.keyW),
          InputRef.key(PhysicalKeyboardKey.keyT),
        ],
      };
      expect(legendKeys(many, CarAction.forward).map((r) => r.keyText), [
        'I',
        'W',
      ]);
    });

    test(
      'shows steering as the first key of left and the first key of right',
      () {
        expect(steerLegendKeys(defaultBindings()).map((r) => r.keyText), [
          'A',
          'D',
        ]);
        final arrowsOnly = {
          CarAction.left: [InputRef.key(PhysicalKeyboardKey.arrowLeft)],
          CarAction.right: [InputRef.key(PhysicalKeyboardKey.arrowRight)],
        };
        expect(steerLegendKeys(arrowsOnly).map((r) => r.keyText), ['←', '→']);
        final leftOnly = {
          CarAction.left: [InputRef.key(PhysicalKeyboardKey.keyA)],
          CarAction.right: [InputRef.pad(PadInput.dpadRight)],
        };
        expect(steerLegendKeys(leftOnly).map((r) => r.keyText), ['A']);
      },
    );

    test('leaves out controller inputs and an action with no key', () {
      final b = {
        CarAction.light: [InputRef.pad(PadInput.a)],
      };
      expect(legendKeys(b, CarAction.light), isEmpty);
      expect(legendKeys(b, CarAction.donut), isEmpty);
      expect(steerLegendKeys(b), isEmpty);
    });
  });

  group('KeyLegend', () {
    testWidgets('shows the keys of every action with their name', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(
        t,
        rig.driver,
        const KeyLegend(),
        size: const Size(1180, 760),
      );

      for (final s in [
        'W', '↑', 'S', '↓', 'A', 'D', 'Espaço', 'L', 'Q', // keys
        'Frente', 'Ré', 'Direção', 'Turbo', 'Luz', 'Giro 360°', // actions
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      // W comes before the arrow, as in the approved design.
      expect(
        t.getTopLeft(find.text('W')).dx,
        lessThan(t.getTopLeft(find.text('↑')).dx),
      );
      // And each key sits before the name of its action.
      expect(
        t.getTopLeft(find.text('Espaço')).dx,
        lessThan(t.getTopLeft(find.text('Turbo')).dx),
      );
      await _finish(t, rig);
    });

    testWidgets('speaks the three languages', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const KeyLegend(), locale: 'en');
      for (final s in [
        'Space',
        'Forward',
        'Reverse',
        'Steer',
        'Light',
        '360° spin',
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      await pumpWithDriver(t, rig.driver, const KeyLegend(), locale: 'es');
      await t.pump();
      for (final s in ['Espacio', 'Adelante', 'Marcha atrás', 'Dirección']) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      await _finish(t, rig);
    });

    testWidgets('disappears when the keyboard is off, and comes back', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const KeyLegend());
      expect(find.text('W'), findsOneWidget);

      rig.driver.keyboardEnabled = false;
      await t.pump();
      expect(find.text('W'), findsNothing);
      expect(find.text('Espaço'), findsNothing);
      expect(t.getSize(find.byType(KeyLegend)), Size.zero);

      rig.driver.keyboardEnabled = true;
      await t.pump();
      expect(find.text('W'), findsOneWidget);
      await _finish(t, rig);
    });

    testWidgets('lights the group of an action that is in the command', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const KeyLegend());
      expect(_textColor(t, 'W'), AppColors.text2);
      expect(_textColor(t, 'Frente'), AppColors.text3);

      rig.driver.setVirtual(CarAction.forward, true);
      await _settle(t);
      expect(_textColor(t, 'W'), AppColors.amber);
      expect(_textColor(t, '↑'), AppColors.amber);
      expect(_textColor(t, 'Frente'), AppColors.text);
      expect(
        _textColor(t, 'S'),
        AppColors.text2,
        reason: 'the others stay out',
      );
      expect(_textColor(t, 'Espaço'), AppColors.text2);

      rig.driver.setVirtual(CarAction.forward, false);
      await _settle(t);
      expect(_textColor(t, 'W'), AppColors.text2);
      expect(_textColor(t, 'Frente'), AppColors.text3);
      await _finish(t, rig);
    });

    testWidgets('lights Direction for either side, and each other action', (
      t,
    ) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const KeyLegend());

      for (final (action, keys, name) in [
        (CarAction.left, ['A', 'D'], 'Direção'),
        (CarAction.right, ['A', 'D'], 'Direção'),
        (CarAction.reverse, ['S', '↓'], 'Ré'),
        (CarAction.turbo, ['Espaço'], 'Turbo'),
        (CarAction.donut, ['Q'], 'Giro 360°'),
      ]) {
        rig.driver.setVirtual(action, true);
        await _settle(t);
        for (final k in keys) {
          expect(_textColor(t, k), AppColors.amber, reason: '$k for $action');
        }
        expect(_textColor(t, name), AppColors.text, reason: name);
        expect(_textColor(t, 'W'), AppColors.text2, reason: 'W for $action');
        rig.driver.setVirtual(action, false);
        await _settle(t);
        expect(
          _textColor(t, keys.first),
          AppColors.text2,
          reason: '$action off',
        );
      }

      // The light stays lit while it is on, not only while the key is down.
      rig.driver.setVirtual(CarAction.light, true);
      rig.driver.setVirtual(CarAction.light, false);
      await _settle(t);
      expect(rig.driver.command.light, isTrue);
      expect(_textColor(t, 'L'), AppColors.amber);
      await _finish(t, rig);
    });

    testWidgets('lights at once with reduce motion', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(
        t,
        rig.driver,
        const KeyLegend(),
        reduceMotion: true,
      );
      rig.driver.setVirtual(CarAction.forward, true);
      await t.pump(const Duration(milliseconds: 40));
      expect(_textColor(t, 'W'), AppColors.amber);
      await _finish(t, rig);
    });

    testWidgets('follows the current shortcuts', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(t, rig.driver, const KeyLegend());
      rig.driver.removeBinding(
        CarAction.turbo,
        InputRef.key(PhysicalKeyboardKey.space),
      );
      rig.driver.addBinding(
        CarAction.turbo,
        InputRef.key(PhysicalKeyboardKey.keyT),
      );
      await t.pump();
      expect(find.text('Espaço'), findsNothing);
      expect(find.text('T'), findsOneWidget);

      // An action that has no key left has no group.
      rig.driver.removeBinding(
        CarAction.donut,
        InputRef.key(PhysicalKeyboardKey.keyQ),
      );
      await t.pump();
      expect(find.text('Giro 360°'), findsNothing);
      expect(find.text('Q'), findsNothing);
      await _finish(t, rig);
    });

    testWidgets('wraps on a narrow window without overflowing', (t) async {
      final rig = await _connected(t);
      await pumpWithDriver(
        t,
        rig.driver,
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: KeyLegend(),
        ),
        size: const Size(320, 568),
        locale: 'es',
      );
      expect(t.takeException(), isNull);
      expect(find.text('Marcha atrás'), findsOneWidget);
      await _finish(t, rig);
    });
  });
}
