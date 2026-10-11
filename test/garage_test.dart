import 'dart:async';

import 'package:ble_rc_controller/core/car_transport.dart';
import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/input/controller_profile.dart';
import 'package:ble_rc_controller/l10n/gen/app_localizations.dart';
import 'package:ble_rc_controller/ui/cockpit/car_decal.dart';
import 'package:ble_rc_controller/ui/common/amber_switch.dart';
import 'package:ble_rc_controller/ui/common/glass.dart';
import 'package:ble_rc_controller/ui/common/notice.dart';
import 'package:ble_rc_controller/ui/garage/car_list.dart';
import 'package:ble_rc_controller/ui/garage/car_sheet.dart';
import 'package:ble_rc_controller/ui/garage/garage_column.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_transport.dart';
import 'support/harness.dart';

/// Strong signal (level 4) and medium signal (level 3).
const _sf25 = FoundCar(id: 'car1', name: 'SL-SF-25', rssi: -55);
const _gt3 = FoundCar(id: 'car2', name: 'SL-296 GT3', rssi: -70);

/// A car that never reports its battery.
class _NoBatteryTransport extends FakeTransport {
  @override
  Stream<int> batteryOf(String id) => const Stream.empty();
}

/// A driver wired to a fake transport, plus what a test needs to poke at it.
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

/// Builds a driver and, with [cars], scans the SF-25 and the 296 GT3. The
/// timers are the test's fake ones.
Future<_Rig> _rig(
  WidgetTester t, {
  FakeTransport? transport,
  Map<String, Object> prefs = const {},
  List<FoundCar> cars = const [_sf25, _gt3],
  Duration carStaleAfter = const Duration(seconds: 6),
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final fake = transport ?? FakeTransport();
  final controllers = StreamController<GamepadConnectionEvent>.broadcast();
  final driver = Driver(
    transport: fake,
    prefs: await SharedPreferences.getInstance(),
    rawEvents: const Stream<GamepadEvent>.empty(),
    connectionEvents: controllers.stream,
    listGamepads: () async => [],
    enableKeyboard: false,
    carStaleAfter: carStaleAfter,
  );
  await driver.start();
  for (final car in cars) {
    fake.scan.add(car);
  }
  await t.pump(const Duration(milliseconds: 70));
  return _Rig(driver, fake, controllers);
}

/// Takes the widgets down first, then the driver, as the app does.
Future<void> _finish(WidgetTester t, _Rig rig) async {
  await t.pumpWidget(const SizedBox());
  rig.dispose();
}

/// A widget test with a [_Rig] that is taken down at the end.
void _rigTest(
  String name,
  Future<void> Function(WidgetTester t, _Rig rig) body, {
  FakeTransport? transport,
  Map<String, Object> prefs = const {},
  List<FoundCar> cars = const [_sf25, _gt3],
  Duration carStaleAfter = const Duration(seconds: 6),
}) {
  testWidgets(name, (t) async {
    final rig = await _rig(
      t,
      transport: transport,
      prefs: prefs,
      cars: cars,
      carStaleAfter: carStaleAfter,
    );
    try {
      await body(t, rig);
    } finally {
      await _finish(t, rig);
    }
  });
}

/// Connects to [id] and lets the answer arrive.
Future<void> _connect(WidgetTester t, _Rig rig, String id) async {
  await rig.driver.connect(id);
  await t.pump();
  expect(rig.driver.link, LinkState.connected);
}

/// Lets the driver finish letting go of a car. That awaits the cancelling of
/// its subscriptions, which only the real event loop completes, not the fake
/// clock of a widget test.
Future<void> _letGo(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await t.pump(const Duration(milliseconds: 300));
}

/// The glass row of the car called [model].
Finder _row(String model) =>
    find.ancestor(of: find.text(model), matching: find.byType(Glass)).first;

/// [text] inside [row].
Finder _in(Finder row, String text) =>
    find.descendant(of: row, matching: find.text(text));

/// The colour of each bar in the row of [model], shortest bar first.
List<Color?> _barColors(WidgetTester t, String model) => [
  for (final box in t.widgetList<DecoratedBox>(
    find.descendant(
      of: find.descendant(of: _row(model), matching: find.byType(SignalBars)),
      matching: find.byType(DecoratedBox),
    ),
  ))
    (box.decoration as BoxDecoration).color,
];

/// The icon in the row of [model].
CarDecal _icon(WidgetTester t, String model) => t.widget<CarDecal>(
  find.descendant(of: _row(model), matching: find.byType(CarDecal)),
);

/// A button that opens the car sheet.
Widget _opener() => Builder(
  builder: (context) => TextButton(
    onPressed: () => showCarSheet(context),
    child: const Text('abrir'),
  ),
);

Future<void> _openSheet(WidgetTester t) async {
  await t.tap(find.text('abrir'));
  await t.pumpAndSettle();
}

void main() {
  group('CarList', () {
    _rigTest('lists the cars found, in the order of the driver', (
      t,
      rig,
    ) async {
      await pumpWithDriver(t, rig.driver, const CarList());
      expect(find.text('SF-25'), findsOneWidget);
      expect(find.text('296 GT3'), findsOneWidget);
      expect(rig.driver.cars.map((c) => c.model), [
        '296 GT3',
        'SF-25',
      ], reason: 'the driver sorts by name');
      expect(
        t.getTopLeft(find.text('296 GT3')).dy,
        lessThan(t.getTopLeft(find.text('SF-25')).dy),
      );
    });

    _rigTest('with no car connected each row says its signal and Connect', (
      t,
      rig,
    ) async {
      await pumpWithDriver(t, rig.driver, const CarList());
      expect(_in(_row('SF-25'), 'sinal forte'), findsOneWidget);
      expect(_in(_row('296 GT3'), 'sinal médio'), findsOneWidget);
      expect(find.text('Conectar'), findsNWidgets(2));
      expect(find.text('Trocar'), findsNothing);
      expect(find.text('Desconectar'), findsNothing);
    });

    _rigTest('a weak car says so', (t, rig) async {
      rig.transport.scan.add(
        const FoundCar(id: 'car3', name: 'SL-Weak', rssi: -90),
      );
      await t.pump(const Duration(milliseconds: 70));
      await pumpWithDriver(t, rig.driver, const CarList());
      expect(_in(_row('Weak'), 'sinal fraco'), findsOneWidget);
    });

    _rigTest('the bars show the signal level, lit ones first', (t, rig) async {
      await pumpWithDriver(t, rig.driver, const CarList());
      const lit = AppColors.text2;
      const dim = AppColors.traceWeak;
      expect(_barColors(t, 'SF-25'), [lit, lit, lit, lit]);
      expect(_barColors(t, '296 GT3'), [lit, lit, lit, dim]);
    });

    _rigTest('the car names use the numeric type', (t, rig) async {
      await pumpWithDriver(t, rig.driver, const CarList());
      final style = t.widget<Text>(find.text('SF-25')).style!;
      expect(style.fontFamily, AppType.family);
      expect(style.fontVariations, contains(const FontVariation('wdth', 75)));
      expect(style.fontVariations, contains(const FontVariation('wght', 300)));
    });

    _rigTest(
      'the connected car says Connected with its battery and Disconnect, '
      'the others say Switch',
      (t, rig) async {
        await pumpWithDriver(t, rig.driver, const CarList());
        await _connect(t, rig, 'car1');
        await t.pump(const Duration(milliseconds: 300));

        expect(_in(_row('SF-25'), 'Conectado · 77%'), findsOneWidget);
        expect(_in(_row('SF-25'), 'Desconectar'), findsOneWidget);
        expect(_in(_row('296 GT3'), 'Trocar'), findsOneWidget);
        expect(_in(_row('296 GT3'), 'sinal médio'), findsOneWidget);
        expect(find.text('Conectar'), findsNothing);
        expect(find.text('Desconectar'), findsOneWidget);
        expect(find.text('Trocar'), findsOneWidget);
      },
    );

    _rigTest(
      'without a battery reading the connected car only says Connected',
      (t, rig) async {
        await pumpWithDriver(t, rig.driver, const CarList());
        await _connect(t, rig, 'car1');
        await t.pump(const Duration(milliseconds: 300));
        expect(rig.driver.battery, isNull);
        expect(_in(_row('SF-25'), 'Conectado'), findsOneWidget);
      },
      transport: _NoBatteryTransport(),
    );

    _rigTest('only the connected row is active, with an amber icon', (
      t,
      rig,
    ) async {
      await pumpWithDriver(t, rig.driver, const CarList());
      await _connect(t, rig, 'car1');
      await t.pumpAndSettle();

      expect(t.widget<Glass>(_row('SF-25')).active, isTrue);
      expect(t.widget<Glass>(_row('296 GT3')).active, isFalse);

      final sf25 = _icon(t, 'SF-25');
      expect(sf25.variant, DecalVariant.icon);
      expect(sf25.iconColor, AppColors.amber);
      expect(_icon(t, '296 GT3').iconColor, AppColors.trace);
      expect(t.widget<Text>(find.text('SF-25')).style!.color, AppColors.amber);
      expect(t.widget<Text>(find.text('296 GT3')).style!.color, AppColors.text);
    });

    _rigTest('Disconnect leaves the link idle', (t, rig) async {
      await pumpWithDriver(t, rig.driver, const CarList());
      await _connect(t, rig, 'car1');
      await t.pump(const Duration(milliseconds: 300));

      await t.tap(find.text('Desconectar'));
      await _letGo(t);
      expect(rig.driver.link, LinkState.idle);
      expect(find.text('Conectar'), findsNWidgets(2));
    });

    _rigTest('Connect and Switch both connect to that car', (t, rig) async {
      await pumpWithDriver(t, rig.driver, const CarList());
      await t.tap(_in(_row('SF-25'), 'Conectar'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(rig.driver.carId, 'car1');
      expect(rig.driver.link, LinkState.connected);

      await t.tap(_in(_row('296 GT3'), 'Trocar'));
      await _letGo(t);
      expect(rig.driver.carId, 'car2');
      expect(rig.driver.link, LinkState.connected);
      expect(_in(_row('296 GT3'), 'Desconectar'), findsOneWidget);
      expect(_in(_row('SF-25'), 'Trocar'), findsOneWidget);
    });

    testWidgets('while connecting, that car says so and can be cancelled', (
      t,
    ) async {
      final transport = FakeTransport()
        ..connectDelay = const Duration(seconds: 5);
      final rig = await _rig(t, transport: transport);
      try {
        await pumpWithDriver(t, rig.driver, const CarList());
        unawaited(rig.driver.connect('car1'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(rig.driver.link, LinkState.connecting);

        expect(_in(_row('SF-25'), 'Conectando'), findsOneWidget);
        expect(_in(_row('SF-25'), 'Cancelar'), findsOneWidget);
        expect(t.widget<Glass>(_row('SF-25')).active, isFalse);
        expect(_in(_row('296 GT3'), 'Trocar'), findsOneWidget);

        await t.tap(find.text('Cancelar'));
        await t.pump();
        expect(rig.driver.link, LinkState.idle);
        // The attempt that was cancelled ends on its own.
        await t.pump(const Duration(seconds: 6));
      } finally {
        await _finish(t, rig);
      }
    });

    _rigTest('every button has a target of at least 48 by 48', (t, rig) async {
      await pumpWithDriver(t, rig.driver, const CarList());
      Size target(String label) => t.getSize(
        find
            .ancestor(of: find.text(label), matching: find.byType(InkWell))
            .first,
      );

      expect(target('Conectar').width, greaterThanOrEqualTo(48));
      expect(target('Conectar').height, greaterThanOrEqualTo(48));

      await _connect(t, rig, 'car1');
      await t.pump(const Duration(milliseconds: 300));
      for (final label in ['Desconectar', 'Trocar']) {
        expect(target(label).width, greaterThanOrEqualTo(48), reason: label);
        expect(target(label).height, greaterThanOrEqualTo(48), reason: label);
      }
    });

    _rigTest('an empty list is just empty', (t, rig) async {
      await pumpWithDriver(t, rig.driver, const CarList());
      expect(find.byType(Glass), findsNothing);
      expect(t.takeException(), isNull);
    }, cars: const []);

    group('when connecting fails', () {
      Future<void> fail(WidgetTester t, _Rig rig) async {
        rig.transport.failConnect = true;
        await rig.driver.connect('car1');
        await t.pump();
        expect(rig.driver.message, MessageKind.connectFailed);
      }

      _rigTest('the garage shows the notice with both actions', (t, rig) async {
        await pumpWithDriver(t, rig.driver, const CarList());
        expect(find.byType(Notice), findsNothing);
        await fail(t, rig);
        await t.pump(const Duration(milliseconds: 300));

        expect(find.byType(Notice), findsOneWidget);
        expect(find.text('Não foi possível conectar ao SF-25'), findsOneWidget);
        expect(
          find.text(
            'Desligue e ligue o carro e confira se nenhum outro app está '
            'conectado a ele.',
          ),
          findsOneWidget,
        );
        expect(find.text('Tentar de novo'), findsOneWidget);
        expect(find.text('Fechar'), findsOneWidget);
        // The notice sits above the cars.
        expect(
          t.getTopLeft(find.byType(Notice)).dy,
          lessThan(t.getTopLeft(find.text('296 GT3')).dy),
        );
      });

      _rigTest('Try again connects to the car that failed', (t, rig) async {
        await pumpWithDriver(t, rig.driver, const CarList());
        await fail(t, rig);
        rig.transport.failConnect = false;

        await t.tap(find.text('Tentar de novo'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(rig.driver.link, LinkState.connected);
        expect(rig.driver.carId, 'car1');
        expect(find.byType(Notice), findsNothing);
      });

      _rigTest('Close dismisses the notice', (t, rig) async {
        await pumpWithDriver(t, rig.driver, const CarList());
        await fail(t, rig);

        await t.tap(find.text('Fechar'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(rig.driver.message, isNull);
        expect(rig.driver.failedCar, isNull);
        expect(find.byType(Notice), findsNothing);
        expect(find.text('Conectar'), findsNWidgets(2));
      });

      _rigTest(
        'a car that is no longer advertising can still be retried and then '
        'appears connected',
        (t, rig) async {
          await pumpWithDriver(t, rig.driver, const CarList());
          await fail(t, rig);
          // Nothing advertises any more, so the next sweep prunes the scan.
          await t.pump(const Duration(seconds: 2));
          expect(rig.driver.cars, isEmpty);
          expect(find.text('Tentar de novo'), findsOneWidget);

          rig.transport.failConnect = false;
          await t.tap(find.text('Tentar de novo'));
          await t.pump();
          await t.pump(const Duration(milliseconds: 300));
          expect(rig.driver.link, LinkState.connected);
          expect(rig.driver.cars, isEmpty);
          expect(_in(_row('SF-25'), 'Desconectar'), findsOneWidget);
        },
        carStaleAfter: Duration.zero,
      );
    });

    _rigTest('a dropped link is not a failed connection', (t, rig) async {
      await pumpWithDriver(t, rig.driver, const CarList());
      await _connect(t, rig, 'car1');
      rig.transport.conn.add(false);
      await t.pump();
      expect(rig.driver.message, MessageKind.dropped);
      expect(find.byType(Notice), findsNothing);
    });
  });

  group('AutoConnectToggle', () {
    _rigTest('is named by its label and follows the driver', (t, rig) async {
      final handle = t.ensureSemantics();
      await pumpWithDriver(t, rig.driver, const AutoConnectToggle());
      expect(find.text('Reconectar ao último carro'), findsOneWidget);
      expect(
        t.getSemantics(find.byType(AmberSwitch)),
        isSemantics(
          label: 'Reconectar ao último carro',
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
        ),
      );

      await t.tap(find.byType(AmberSwitch));
      await t.pump(const Duration(milliseconds: 300));
      expect(rig.driver.autoConnect, isFalse);
      expect(
        t.getSemantics(find.byType(AmberSwitch)),
        isSemantics(
          label: 'Reconectar ao último carro',
          hasToggledState: true,
          isToggled: false,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    _rigTest('one tap toggles once', (t, rig) async {
      await pumpWithDriver(t, rig.driver, const AutoConnectToggle());
      await t.tap(find.byType(AmberSwitch));
      await t.pump(const Duration(milliseconds: 300));
      expect(rig.driver.autoConnect, isFalse);
      await t.tap(find.byType(AmberSwitch));
      await t.pump(const Duration(milliseconds: 300));
      expect(rig.driver.autoConnect, isTrue);
    });
  });

  group('showCarSheet', () {
    _rigTest('opens a frosted sheet with the cars and the reconnect switch', (
      t,
      rig,
    ) async {
      await pumpWithDriver(t, rig.driver, _opener());
      expect(find.byType(CarList), findsNothing);
      await _openSheet(t);

      expect(find.byType(CarList), findsOneWidget);
      expect(find.text('SF-25'), findsOneWidget);
      expect(find.text('Reconectar ao último carro'), findsOneWidget);
      expect(find.byType(AmberSwitch), findsOneWidget);
      // The sheet blurs what is behind it.
      expect(
        find.ancestor(
          of: find.byType(CarList),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
    });

    _rigTest('the rows and the switch share one blur', (t, rig) async {
      await pumpWithDriver(t, rig.driver, _opener());
      await _openSheet(t);

      final inside =
          backdropKeysUnder(t, find.byType(CarList)) +
          backdropKeysUnder(t, find.byType(AutoConnectToggle));
      expect(inside, hasLength(3), reason: 'two cars and the switch');
      expect(inside.first, isNotNull);
      expect(inside.toSet(), hasLength(1));
    });

    _rigTest('turning the switch off turns auto-connect off', (t, rig) async {
      await pumpWithDriver(t, rig.driver, _opener());
      await _openSheet(t);
      expect(rig.driver.autoConnect, isTrue);

      await t.tap(find.byType(AmberSwitch));
      await t.pumpAndSettle();
      expect(rig.driver.autoConnect, isFalse);
      expect(find.byType(CarList), findsOneWidget, reason: 'the sheet stays');
    });

    _rigTest('connecting a car from the sheet connects and closes it', (
      t,
      rig,
    ) async {
      await pumpWithDriver(t, rig.driver, _opener());
      await _openSheet(t);

      await t.tap(_in(_row('296 GT3'), 'Conectar'));
      await t.pumpAndSettle();
      expect(rig.driver.link, LinkState.connected);
      expect(rig.driver.carId, 'car2');
      expect(find.byType(CarList), findsNothing);
    });

    _rigTest('opened on a connected car it stays open until another connects', (
      t,
      rig,
    ) async {
      await pumpWithDriver(t, rig.driver, _opener());
      await _connect(t, rig, 'car1');
      await _openSheet(t);
      expect(find.byType(CarList), findsOneWidget);

      // Something else changes in the driver: the sheet is not for that.
      rig.driver.autoConnect = false;
      await t.pumpAndSettle();
      expect(find.byType(CarList), findsOneWidget);

      await t.tap(_in(_row('296 GT3'), 'Trocar'));
      await _letGo(t);
      await t.pumpAndSettle();
      expect(rig.driver.carId, 'car2');
      expect(find.byType(CarList), findsNothing);
    });

    _rigTest('the car it was opened on is the one at the call, not at the '
        'first frame', (t, rig) async {
      await pumpWithDriver(t, rig.driver, _opener());
      expect(rig.driver.link, LinkState.idle);

      // The call is made with no car connected...
      await t.tap(find.text('abrir'));
      // ...and a car connects before the sheet is on the screen.
      await _connect(t, rig, 'car1');
      await t.pumpAndSettle();
      expect(find.byType(CarList), findsOneWidget);

      // That car came after the sheet was asked for, so it is "another car":
      // the next thing the driver says takes the sheet away.
      rig.driver.autoConnect = false;
      await t.pumpAndSettle();
      expect(find.byType(CarList), findsNothing);
    });

    _rigTest('a failed attempt keeps the sheet open, with the notice', (
      t,
      rig,
    ) async {
      rig.transport.failConnect = true;
      await pumpWithDriver(t, rig.driver, _opener());
      await _openSheet(t);

      await t.tap(_in(_row('296 GT3'), 'Conectar'));
      await t.pumpAndSettle();
      expect(rig.driver.link, LinkState.idle);
      expect(rig.driver.message, MessageKind.connectFailed);
      expect(find.byType(CarList), findsOneWidget);
      expect(find.byType(Notice), findsOneWidget);
      expect(find.text('Não foi possível conectar ao 296 GT3'), findsOneWidget);

      // And a retry that works closes it.
      rig.transport.failConnect = false;
      await t.tap(find.text('Tentar de novo'));
      await t.pumpAndSettle();
      expect(rig.driver.carId, 'car2');
      expect(find.byType(CarList), findsNothing);
    });

    _rigTest('closes on a drag down', (t, rig) async {
      await pumpWithDriver(t, rig.driver, _opener());
      await _openSheet(t);

      await t.fling(find.text('SF-25'), const Offset(0, 600), 2000);
      await t.pumpAndSettle();
      expect(find.byType(CarList), findsNothing);
      expect(rig.driver.link, LinkState.idle, reason: 'nothing connected');
    });

    _rigTest('closes on a tap outside', (t, rig) async {
      await pumpWithDriver(t, rig.driver, _opener());
      await _openSheet(t);

      await t.tapAt(const Offset(195, 40));
      await t.pumpAndSettle();
      expect(find.byType(CarList), findsNothing);
    });

    _rigTest('with reduce motion it is in place at once', (t, rig) async {
      await pumpWithDriver(t, rig.driver, _opener(), reduceMotion: true);
      await t.tap(find.text('abrir'));
      await t.pump();
      final first = t.getTopLeft(find.byType(CarList));
      await t.pumpAndSettle();
      expect(t.getTopLeft(find.byType(CarList)), first);
    });

    _rigTest('without reduce motion it slides up', (t, rig) async {
      await pumpWithDriver(t, rig.driver, _opener());
      await t.tap(find.text('abrir'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      final first = t.getTopLeft(find.byType(CarList));
      await t.pumpAndSettle();
      expect(t.getTopLeft(find.byType(CarList)).dy, lessThan(first.dy));
    });

    _rigTest('fits a small phone without overflow, in every language', (
      t,
      rig,
    ) async {
      await _connect(t, rig, 'car1');
      for (final locale in ['pt', 'en', 'es']) {
        await pumpWithDriver(
          t,
          rig.driver,
          _opener(),
          size: const Size(320, 568),
          locale: locale,
        );
        await _openSheet(t);
        expect(find.byType(CarList), findsOneWidget, reason: locale);
        expect(t.takeException(), isNull, reason: locale);
        await t.tapAt(const Offset(160, 20));
        await t.pumpAndSettle();
        expect(find.byType(CarList), findsNothing, reason: locale);
      }
    });
  });

  group('GarageColumn', () {
    _rigTest('is 280 wide and has the cars, the controls and the switch', (
      t,
      rig,
    ) async {
      await pumpWithDriver(
        t,
        rig.driver,
        const GarageColumn(),
        size: const Size(1180, 760),
        reduceMotion: true,
      );
      expect(t.getSize(find.byType(GarageColumn)).width, 280);
      expect(find.text('Carros por perto'), findsOneWidget);
      expect(find.byType(CarList), findsOneWidget);
      expect(find.text('SF-25'), findsOneWidget);
      expect(find.text('Controles'), findsOneWidget);
      expect(find.text('Nenhum controle'), findsOneWidget);
      expect(find.text('Reconectar ao último carro'), findsOneWidget);

      await t.tap(find.byType(AmberSwitch));
      await t.pump(const Duration(milliseconds: 300));
      expect(rig.driver.autoConnect, isFalse);
    });

    _rigTest('the rows and the switch share one blur', (t, rig) async {
      await pumpWithDriver(
        t,
        rig.driver,
        const GarageColumn(),
        size: const Size(1180, 760),
        reduceMotion: true,
      );
      rig.plugIn('DualShock 4');
      await t.pump(const Duration(milliseconds: 100));
      final rows = backdropKeysUnder(
        t,
        find.descendant(
          of: find.byType(GarageColumn),
          matching: find.byType(Glass),
        ),
      );
      // Two cars, a controller and the switch.
      expect(rows, hasLength(4));
      expect(rows.first, isNotNull);
      expect(rows.toSet(), hasLength(1));
      // The column's own blur is the plain one: the rows are on top of it.
      final own = t.widget<BackdropFilter>(
        find
            .descendant(
              of: find.byType(GarageColumn),
              matching: find.byType(BackdropFilter),
            )
            .first,
      );
      expect(own.backdropGroupKey, isNull);
    });

    group('the system bars and cutouts', () {
      // A tablet turned sideways with a status bar of 24, a navigation bar of
      // 48 (Android 15 edge to edge) and a camera cutout of 30 on the left.
      const size = Size(1280, 800);
      const bars = FakeViewPadding(top: 24, bottom: 48, left: 30);

      void useBars(WidgetTester t) {
        t.view.viewPadding = bars;
        t.view.padding = bars;
        addTearDown(t.view.resetViewPadding);
        addTearDown(t.view.resetPadding);
      }

      /// The column at the left edge of the window, as the shell puts it.
      const atTheEdge = SizedBox(
        width: 1280,
        height: 800,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [GarageColumn(), Spacer()],
        ),
      );

      _rigTest('the header, the cars and the switch keep inside them', (
        t,
        rig,
      ) async {
        await pumpWithDriver(
          t,
          rig.driver,
          atTheEdge,
          size: size,
          reduceMotion: true,
        );
        useBars(t);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);

        // Not under the status bar.
        expect(
          t.getRect(find.text('Carros por perto')).top,
          greaterThanOrEqualTo(24),
        );
        // Not under the navigation bar.
        final toggle = find.byType(AutoConnectToggle);
        expect(t.getRect(toggle).bottom, lessThanOrEqualTo(size.height - 48));
        expect(find.text('Reconectar ao último carro'), findsOneWidget);
        // Not under the camera: neither the headings nor the rows.
        for (final finder in [
          find.text('Carros por perto'),
          find.text('Controles'),
          find.byType(CarList),
          toggle,
        ]) {
          expect(t.getRect(finder).left, greaterThanOrEqualTo(30));
        }
        // The column itself still runs to the edges.
        final column = t.getRect(find.byType(GarageColumn));
        expect(column.left, 0);
        expect(column.top, 0);
        expect(column.bottom, size.height);
        expect(column.width, 280);
        final glass = t.getRect(
          find
              .descendant(
                of: find.byType(GarageColumn),
                matching: find.byType(BackdropFilter),
              )
              .first,
        );
        expect(glass, column);
      });

      _rigTest('without bars the content sits where it always did', (
        t,
        rig,
      ) async {
        await pumpWithDriver(
          t,
          rig.driver,
          atTheEdge,
          size: size,
          reduceMotion: true,
        );
        expect(t.getRect(find.text('Carros por perto')).left, 14 + 6);
        expect(
          t.getRect(find.byType(AutoConnectToggle)).bottom,
          size.height - 14,
        );
      });
    });

    _rigTest('lists each controller the app recognises', (t, rig) async {
      await pumpWithDriver(
        t,
        rig.driver,
        const GarageColumn(),
        size: const Size(1180, 760),
        reduceMotion: true,
      );
      rig.plugIn('DualShock 4', id: 'g1');
      rig.plugIn('Other Pad', id: 'g2');
      await t.pump(const Duration(milliseconds: 100));

      expect(find.text('Nenhum controle'), findsNothing);
      expect(find.text('DualShock 4'), findsOneWidget);
      expect(find.text('Other Pad'), findsOneWidget);
      expect(find.text('Reconhecido'), findsNWidgets(2));
      expect(find.text('Ensinado'), findsNothing);
    });

    _rigTest(
      'a controller with a taught profile says so',
      (t, rig) async {
        await pumpWithDriver(
          t,
          rig.driver,
          const GarageColumn(),
          size: const Size(1180, 760),
          reduceMotion: true,
        );
        rig.plugIn('DualShock 4', id: 'g1');
        rig.plugIn('Other Pad', id: 'g2');
        await t.pump(const Duration(milliseconds: 100));

        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text('DualShock 4'),
              matching: find.byType(Glass),
            ),
            matching: find.text('Ensinado'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text('Other Pad'),
              matching: find.byType(Glass),
            ),
            matching: find.text('Reconhecido'),
          ),
          findsOneWidget,
        );
      },
      prefs: {
        'profiles': encodeProfiles({
          'name:dualshock 4': ControllerProfile(
            key: 'name:dualshock 4',
            name: 'DualShock 4',
            rawMap: {
              'btn:1': [const RawMapping('a', 1)],
            },
          ),
        }),
      },
    );

    group('the searching indicator', () {
      Finder spinner() => find.bySemanticsLabel('Procurando');

      double turns(WidgetTester t) => t
          .widget<RotationTransition>(
            find.descendant(
              of: find.byType(GarageColumn),
              matching: find.byType(RotationTransition),
            ),
          )
          .turns
          .value;

      _rigTest('turns while Bluetooth is ready and no car is linked', (
        t,
        rig,
      ) async {
        final handle = t.ensureSemantics();
        await pumpWithDriver(t, rig.driver, const GarageColumn());
        expect(spinner(), findsOneWidget);
        final before = turns(t);
        await t.pump(const Duration(milliseconds: 400));
        expect(turns(t), isNot(before));
        handle.dispose();
      });

      _rigTest('stands still with reduce motion, and the page settles', (
        t,
        rig,
      ) async {
        final handle = t.ensureSemantics();
        await pumpWithDriver(
          t,
          rig.driver,
          const GarageColumn(),
          reduceMotion: true,
        );
        expect(spinner(), findsOneWidget, reason: 'still says it is searching');
        await t.pump(const Duration(milliseconds: 400));
        expect(turns(t), 0);
        await t.pumpAndSettle();
        handle.dispose();
      });

      _rigTest('is gone while a car is connected', (t, rig) async {
        final handle = t.ensureSemantics();
        await pumpWithDriver(t, rig.driver, const GarageColumn());
        await _connect(t, rig, 'car1');
        await t.pumpAndSettle();
        expect(spinner(), findsNothing);
        handle.dispose();
      });

      testWidgets('is gone while connecting', (t) async {
        final rig = await _rig(
          t,
          transport: FakeTransport()..connectDelay = const Duration(seconds: 5),
        );
        try {
          final handle = t.ensureSemantics();
          await pumpWithDriver(t, rig.driver, const GarageColumn());
          unawaited(rig.driver.connect('car1'));
          await t.pump();
          expect(rig.driver.link, LinkState.connecting);
          await t.pumpAndSettle();
          expect(spinner(), findsNothing);
          await t.pump(const Duration(seconds: 6));
          handle.dispose();
        } finally {
          await _finish(t, rig);
        }
      });

      testWidgets('is gone while Bluetooth is off', (t) async {
        final rig = await _rig(
          t,
          transport: FakeTransport()..state = BluetoothState.off,
          cars: const [],
        );
        try {
          final handle = t.ensureSemantics();
          await pumpWithDriver(t, rig.driver, const GarageColumn());
          expect(rig.driver.bluetooth, BluetoothState.off);
          await t.pumpAndSettle();
          expect(spinner(), findsNothing);
          handle.dispose();
        } finally {
          await _finish(t, rig);
        }
      });
    });

    for (final locale in ['pt', 'en', 'es']) {
      _rigTest(
        'the connected row fits the 280 column with its Disconnect button '
        '($locale)',
        (t, rig) async {
          final l = await AppLocalizations.delegate.load(Locale(locale));
          await pumpWithDriver(
            t,
            rig.driver,
            const GarageColumn(),
            size: const Size(1180, 760),
            locale: locale,
          );
          await _connect(t, rig, 'car3');
          await t.pumpAndSettle();

          expect(t.takeException(), isNull);
          final button = find.text(l.disconnect);
          expect(button, findsOneWidget);
          final column = t.getRect(find.byType(GarageColumn));
          final rect = t.getRect(button);
          expect(rect.right, lessThanOrEqualTo(column.right));
          expect(rect.left, greaterThanOrEqualTo(column.left));
          expect(find.text(l.actionSwitch), findsNWidgets(2));

          await t.tap(button);
          await _letGo(t);
          expect(rig.driver.link, LinkState.idle);
        },
        cars: const [
          _sf25,
          _gt3,
          FoundCar(id: 'car3', name: 'SL-Ferrari 296 GTB Speciale', rssi: -90),
        ],
      );
    }

    _rigTest('a short window scrolls the middle and keeps the switch', (
      t,
      rig,
    ) async {
      for (var i = 0; i < 8; i++) {
        rig.transport.scan.add(
          FoundCar(id: 'x$i', name: 'SL-Car $i', rssi: -60 - i),
        );
      }
      await t.pump(const Duration(milliseconds: 70));
      await pumpWithDriver(
        t,
        rig.driver,
        const GarageColumn(),
        size: const Size(900, 360),
        reduceMotion: true,
      );
      expect(t.takeException(), isNull);
      expect(find.byType(AmberSwitch), findsOneWidget);
      final switchRect = t.getRect(find.byType(AmberSwitch));
      expect(switchRect.bottom, lessThanOrEqualTo(360));
      final before = t.getTopLeft(find.text('Controles')).dy;
      expect(before, greaterThan(switchRect.top), reason: 'out of view');

      await t.drag(find.text('296 GT3'), const Offset(0, -600));
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull);
      expect(t.getTopLeft(find.text('Controles')).dy, lessThan(before));
      expect(
        t.getRect(find.text('Controles')).bottom,
        lessThanOrEqualTo(switchRect.top),
        reason: 'scrolled into view above the switch',
      );
      expect(t.getRect(find.byType(AmberSwitch)), switchRect, reason: 'fixed');
    });
  });
}
