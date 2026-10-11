import 'dart:async';
import 'dart:io';

import 'package:ble_rc_controller/core/car_transport.dart';
import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/l10n/gen/app_localizations.dart';
import 'package:ble_rc_controller/ui/cockpit/car_decal.dart';
import 'package:ble_rc_controller/ui/cockpit/cockpit.dart';
import 'package:ble_rc_controller/ui/cockpit/cockpit_header.dart';
import 'package:ble_rc_controller/ui/cockpit/cockpit_states.dart';
import 'package:ble_rc_controller/ui/cockpit/instrument.dart';
import 'package:ble_rc_controller/ui/cockpit/state_cells.dart';
import 'package:ble_rc_controller/ui/cockpit/touch_pads.dart';
import 'package:ble_rc_controller/ui/common/metal_text.dart';
import 'package:ble_rc_controller/ui/common/notice.dart';
import 'package:ble_rc_controller/ui/garage/car_list.dart';
import 'package:ble_rc_controller/ui/garage/garage_column.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_transport.dart';
import 'support/harness.dart';

const _sf25 = FoundCar(id: 'car1', name: 'SL-SF-25', rssi: -55);
const _gt3 = FoundCar(id: 'car2', name: 'SL-296 GT3', rssi: -70);

/// Teaches the test font the real Saira, so the heights the layout works with
/// are the ones the app has (without it every glyph is a square of Ahem).
Future<void> _loadSaira() async {
  final bytes = File('assets/fonts/Saira-Variable.ttf').readAsBytesSync();
  final loader = FontLoader('Saira')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// A driver wired to a fake transport.
class _Rig {
  _Rig(this.driver, this.transport);

  final Driver driver;
  final FakeTransport transport;
}

/// Builds a driver and scans [cars]. The timers are the test's fake ones.
/// With [carStaleAfter] at zero the next prune forgets every car.
Future<_Rig> _rig(
  WidgetTester t, {
  FakeTransport? transport,
  Map<String, Object> prefs = const {},
  List<FoundCar> cars = const [_sf25],
  Duration carStaleAfter = const Duration(seconds: 6),
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final fake = transport ?? FakeTransport();
  final driver = Driver(
    transport: fake,
    prefs: await SharedPreferences.getInstance(),
    rawEvents: const Stream<GamepadEvent>.empty(),
    connectionEvents: const Stream<GamepadConnectionEvent>.empty(),
    listGamepads: () async => [],
    enableKeyboard: false,
    carStaleAfter: carStaleAfter,
  );
  await driver.start();
  for (final car in cars) {
    fake.scan.add(car);
  }
  await t.pump(const Duration(milliseconds: 70));
  return _Rig(driver, fake);
}

/// Takes the widgets down first, then the driver, as the app does.
Future<void> _finish(WidgetTester t, _Rig rig) async {
  await t.pumpWidget(const SizedBox());
  rig.driver.dispose();
}

/// A widget test with a [_Rig] that is taken down at the end.
void _stateTest(
  String name,
  Future<void> Function(WidgetTester t, _Rig rig) body, {
  FakeTransport Function()? transport,
  Map<String, Object> prefs = const {},
  List<FoundCar> cars = const [_sf25],
  Duration carStaleAfter = const Duration(seconds: 6),
}) {
  testWidgets(name, (t) async {
    final rig = await _rig(
      t,
      transport: transport?.call(),
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

Widget _cockpit({double textScale = 1}) {
  const cockpit = Cockpit(onSettings: _noop);
  if (textScale == 1) return cockpit;
  return Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: cockpit,
    ),
  );
}

void _noop() {}

Future<void> _mount(
  WidgetTester t,
  _Rig rig, {
  Size size = const Size(390, 844),
  String locale = 'pt',
  bool reduceMotion = false,
  double textScale = 1,
}) async {
  await pumpWithDriver(
    t,
    rig.driver,
    _cockpit(textScale: textScale),
    size: size,
    locale: locale,
    reduceMotion: reduceMotion,
  );
  await _settle(t);
}

/// Lets the state arrive and the short fades end. Not `pumpAndSettle`: the
/// searching ring and the waves repeat for ever.
Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 300));
}

Future<AppLocalizations> _l10n(String code) =>
    AppLocalizations.delegate.load(Locale(code));

/// The colour of every piece of text under [root].
Iterable<Color?> _textColors(WidgetTester t, Finder root) => t
    .widgetList<RichText>(
      find.descendant(of: root, matching: find.byType(RichText)),
    )
    .map((r) => (r.text as TextSpan).style?.color);

/// A transport whose connection takes five seconds.
FakeTransport _slow() =>
    FakeTransport()..connectDelay = const Duration(seconds: 5);

/// Lets a slow connection end, so no timer outlives the test.
Future<void> _drain(WidgetTester t) => t.pump(const Duration(seconds: 6));

/// Connects to the car and drops the link, like a car that went out of range.
Future<void> _drop(WidgetTester t, _Rig rig) async {
  await rig.driver.connect('car1');
  await t.pump();
  expect(rig.driver.link, LinkState.connected);
  rig.transport.conn.add(false);
  await t.pump();
  await _settle(t);
}

/// A state of the app to put the cockpit in, and what it must then show.
class _Scenario {
  const _Scenario(
    this.name,
    this.state,
    this.header,
    this.prepare, {
    this.cars = const [_sf25],
    this.prefs = const {},
    this.transport,
  });

  final String name;

  /// The state of the cockpit, and the line under the name that goes with it.
  final PanelState state;
  final String Function(AppLocalizations l) header;

  /// Brings the driver to the state, before the cockpit is mounted.
  final Future<void> Function(WidgetTester t, _Rig rig) prepare;
  final List<FoundCar> cars;
  final Map<String, Object> prefs;
  final FakeTransport Function()? transport;
}

Future<void> _nothing(WidgetTester t, _Rig rig) async {}

Future<void> _bluetooth(WidgetTester t, _Rig rig, BluetoothState s) async {
  rig.transport.avail.add(s);
  await t.pump();
}

final _scenarios = <_Scenario>[
  _Scenario(
    'searching, no cars',
    PanelState.searching,
    (l) => l.statusSearching,
    _nothing,
    cars: const [],
  ),
  _Scenario(
    'searching, with cars',
    PanelState.searching,
    (l) => l.statusSearching,
    _nothing,
    cars: const [_sf25, _gt3],
  ),
  _Scenario(
    'Bluetooth not known yet',
    PanelState.searching,
    (l) => l.statusSearching,
    _nothing,
    transport: () => FakeTransport()..state = BluetoothState.unknown,
  ),
  _Scenario(
    'Bluetooth off',
    PanelState.bluetooth,
    (l) => l.btOffTitle,
    (t, rig) => _bluetooth(t, rig, BluetoothState.off),
  ),
  _Scenario(
    'Bluetooth blocked',
    PanelState.bluetooth,
    (l) => l.btDeniedTitle,
    (t, rig) => _bluetooth(t, rig, BluetoothState.unauthorized),
  ),
  _Scenario(
    'permission refused',
    PanelState.bluetooth,
    (l) => l.btDeniedTitle,
    _nothing,
    transport: () => FakeTransport()..denyPermission = true,
  ),
  _Scenario(
    'Bluetooth unavailable',
    PanelState.bluetooth,
    (l) => l.btUnsupportedTitle,
    (t, rig) => _bluetooth(t, rig, BluetoothState.unsupported),
  ),
  _Scenario('connecting', PanelState.connecting, (l) => l.statusConnecting, (
    t,
    rig,
  ) async {
    unawaited(rig.driver.connect('car1'));
    await t.pump();
  }, transport: _slow),
  _Scenario(
    'connection lost',
    PanelState.lost,
    (l) => l.statusReconnecting,
    _drop,
  ),
  _Scenario(
    'dropped, auto-reconnect off',
    PanelState.searching,
    (l) => l.statusSearching,
    _drop,
    prefs: const {'autoConnect': false},
  ),
  _Scenario(
    'connection failed',
    PanelState.searching,
    (l) => l.statusSearching,
    (t, rig) async {
      await rig.driver.connect('car1');
      await t.pump();
    },
    transport: () => FakeTransport()..failConnect = true,
  ),
  _Scenario('connected', PanelState.connected, (l) => l.connectedLabel, (
    t,
    rig,
  ) async {
    await rig.driver.connect('car1');
    await t.pump();
  }),
];

/// The screen of each state.
const _screens = <PanelState, Type>{
  PanelState.bluetooth: BluetoothView,
  PanelState.connecting: ConnectingView,
  PanelState.connected: Instrument,
  PanelState.lost: LostView,
  PanelState.searching: SearchingView,
};

void main() {
  setUpAll(_loadSaira);

  group('Searching', () {
    _stateTest('with no car: the title, the body and the two hints', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      expect(find.text('Ligue o carro'), findsOneWidget);
      expect(
        find.text('Ele aparece aqui sozinho, em poucos segundos.'),
        findsOneWidget,
      );
      expect(find.text('Não aparece?'), findsOneWidget);
      expect(
        find.text(
          'Feche outros apps ligados a ele. O carro aceita uma conexão por '
          'vez.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ainda nada?'), findsOneWidget);
      expect(find.text('Desligue e ligue o carro de novo.'), findsOneWidget);
      expect(find.byType(CarList), findsNothing);
      expect(find.byType(StateCells), findsNothing);
    }, cars: const []);

    _stateTest('with a car: Cars nearby, the list and Connect', (t, rig) async {
      await _mount(t, rig);
      expect(find.text('Carros por perto'), findsOneWidget);
      expect(find.text('SF-25'), findsAtLeastNWidgets(1));
      expect(find.text('Conectar'), findsOneWidget);
      expect(find.byType(CarList), findsOneWidget);
      // The hints are for when nothing shows up.
      expect(find.text('Ligue o carro'), findsNothing);
      expect(find.text('Não aparece?'), findsNothing);
    });

    _stateTest('tapping Connect connects', (t, rig) async {
      await _mount(t, rig);
      await t.tap(find.text('Conectar'));
      await _settle(t);
      expect(rig.driver.link, LinkState.connected);
    });

    _stateTest('the ghost car is drawn dashed', (t, rig) async {
      await _mount(t, rig);
      expect(
        t.widget<CarDecal>(find.byType(CarDecal)).variant,
        DecalVariant.ghost,
      );
    }, cars: const []);
  });

  group('Bluetooth', () {
    _stateTest('off, where it can be turned on: the title and the button', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      rig.transport.avail.add(BluetoothState.off);
      await _settle(t);
      // The line under the name says it too.
      expect(find.text('Bluetooth desligado'), findsNWidgets(2));
      expect(
        find.text('Ligue o Bluetooth para encontrar o carro.'),
        findsOneWidget,
      );
      expect(find.text('Ligar o Bluetooth'), findsOneWidget);
      expect(find.byType(CarList), findsNothing);
      expect(
        t.widget<CarDecal>(find.byType(CarDecal)).variant,
        DecalVariant.ghost,
      );

      expect(rig.transport.enableCalls, 0);
      await t.tap(find.text('Ligar o Bluetooth'));
      await t.pump();
      expect(rig.transport.enableCalls, 1);
    });

    _stateTest('off, where it cannot: the text only', (t, rig) async {
      await _mount(t, rig);
      rig.transport.avail.add(BluetoothState.off);
      await _settle(t);
      expect(find.text('Bluetooth desligado'), findsNWidgets(2));
      expect(
        find.text('Ligue o Bluetooth para encontrar o carro.'),
        findsOneWidget,
      );
      expect(find.text('Ligar o Bluetooth'), findsNothing);
    }, transport: () => FakeTransport()..canEnableBluetooth = false);

    _stateTest('blocked: the title and Try again asks for the permission', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      rig.transport.avail.add(BluetoothState.unauthorized);
      await _settle(t);
      expect(find.text('Bluetooth bloqueado'), findsNWidgets(2));
      expect(
        find.text('Libere o Bluetooth para este app nos ajustes do sistema.'),
        findsOneWidget,
      );
      expect(find.text('Ligar o Bluetooth'), findsNothing);

      final before = rig.transport.permissionCalls;
      await t.tap(find.text('Tentar de novo'));
      await t.pump();
      expect(rig.transport.permissionCalls, before + 1);
    });

    _stateTest('a refused permission is the same screen', (t, rig) async {
      await _mount(t, rig);
      expect(rig.driver.message, MessageKind.permissionDenied);
      expect(rig.driver.bluetooth, BluetoothState.ready);
      expect(find.text('Bluetooth bloqueado'), findsNWidgets(2));
      expect(find.text('Tentar de novo'), findsOneWidget);
    }, transport: () => FakeTransport()..denyPermission = true);

    _stateTest('unavailable: the text and no button', (t, rig) async {
      await _mount(t, rig);
      rig.transport.avail.add(BluetoothState.unsupported);
      await _settle(t);
      expect(find.text('Bluetooth LE indisponível'), findsNWidgets(2));
      expect(
        find.text('Este aparelho não consegue falar com o carro.'),
        findsOneWidget,
      );
      expect(find.text('Ligar o Bluetooth'), findsNothing);
      expect(find.text('Tentar de novo'), findsNothing);
      expect(find.text('Cancelar'), findsNothing);
    });

    _stateTest('with a car connected, Bluetooth off wins over everything', (
      t,
      rig,
    ) async {
      await rig.driver.connect('car1');
      await t.pump();
      await _mount(t, rig);
      expect(find.byType(Instrument), findsOneWidget);

      rig.transport.avail.add(BluetoothState.off);
      await _settle(t);
      expect(rig.driver.link, LinkState.connected);
      expect(find.text('Bluetooth desligado'), findsNWidgets(2));
      expect(find.text('Conexão perdida'), findsNothing);
      expect(find.byType(Instrument), findsNothing);
      expect(find.byType(StateCells), findsNothing);
    });
  });

  group('Connecting', () {
    _stateTest('the title, the body and Cancel; Cancel ends the attempt', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      unawaited(rig.driver.connect('car1'));
      await _settle(t);
      expect(rig.driver.link, LinkState.connecting);
      expect(find.text('Conectando ao SF-25'), findsOneWidget);
      expect(find.text('Leva alguns segundos.'), findsOneWidget);
      expect(
        t.widget<CarDecal>(find.byType(CarDecal)).variant,
        DecalVariant.drawing,
      );
      expect(find.byType(CarList), findsNothing);

      await t.tap(find.text('Cancelar'));
      await _settle(t);
      expect(rig.driver.link, LinkState.idle);
      expect(find.text('Conectando ao SF-25'), findsNothing);
      await _drain(t);
      expect(
        rig.driver.link,
        LinkState.idle,
        reason: 'the late answer is moot',
      );
    }, transport: _slow);
  });

  group('Connecting to a car the scan never showed', () {
    _stateTest(
      'there is no name to give, so the title is the status',
      (t, rig) async {
        await _mount(t, rig);
        unawaited(rig.driver.connect('somewhere'));
        await _settle(t);
        expect(rig.driver.link, LinkState.connecting);
        expect(rig.driver.connectedCar, isNull);
        expect(find.textContaining('Conectando ao'), findsNothing);
        // The line under the name and the title of the screen.
        expect(find.text('Conectando'), findsNWidgets(2));
        expect(find.text('Cancelar'), findsOneWidget);
        await t.tap(find.text('Cancelar'));
        await _settle(t);
        expect(rig.driver.link, LinkState.idle);
        await _drain(t);
      },
      transport: _slow,
      cars: const [],
    );
  });

  group('Connection lost', () {
    _stateTest('the tag and the text; the cells are not there', (t, rig) async {
      await _mount(t, rig);
      await _drop(t, rig);
      expect(rig.driver.reconnecting, isTrue);
      expect(find.text('Conexão perdida'), findsOneWidget);
      expect(
        find.text(
          'O carro parou. O app volta a conectar assim que ele aparecer.',
        ),
        findsOneWidget,
      );
      expect(find.byType(StateCells), findsNothing);
      expect(find.byType(TouchPads), findsNothing);
      expect(find.byType(Instrument), findsNothing);
      expect(find.text('Luz'), findsNothing);
      expect(
        t.widget<CarDecal>(find.byType(CarDecal)).variant,
        DecalVariant.ghost,
      );
    });

    _stateTest('with auto-reconnect off: the list and the notice', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await _drop(t, rig);
      expect(rig.driver.reconnecting, isFalse);
      expect(rig.driver.message, MessageKind.dropped);
      expect(find.text('O carro desconectou.'), findsOneWidget);
      expect(find.text('Conexão perdida'), findsNothing);
      expect(find.text('Carros por perto'), findsOneWidget);
      expect(find.text('Conectar'), findsOneWidget);
      expect(find.byType(Notice), findsOneWidget);

      await t.tap(find.text('Fechar'));
      await _settle(t);
      expect(rig.driver.message, isNull);
      expect(find.byType(Notice), findsNothing);
    }, prefs: const {'autoConnect': false});
  });

  group('Connection lost, and the reconnect fails', () {
    _stateTest('the screen says so, with Try again and Close', (t, rig) async {
      await _mount(t, rig);
      await _drop(t, rig);
      expect(find.byType(Notice), findsNothing);

      // What the automatic reconnect does when the car is back and fails.
      rig.transport.failConnect = true;
      await rig.driver.connect('car1');
      await _settle(t);
      expect(rig.driver.reconnecting, isTrue, reason: 'still waiting');
      expect(rig.driver.message, MessageKind.connectFailed);
      expect(find.byType(LostView), findsOneWidget);
      expect(find.byType(Notice), findsOneWidget);
      expect(find.text('Não foi possível conectar ao SF-25'), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
      // The cells stay switched off under it.
      expect(find.byKey(LostView.cellKey), findsNWidgets(4));

      rig.transport.failConnect = false;
      await t.tap(find.text('Tentar de novo'));
      await _settle(t);
      expect(rig.driver.link, LinkState.connected);
      expect(find.byType(LostView), findsNothing);
      expect(find.byType(Notice), findsNothing);
    });

    _stateTest('Close dismisses it and the wait goes on', (t, rig) async {
      await _mount(t, rig);
      await _drop(t, rig);
      rig.transport.failConnect = true;
      await rig.driver.connect('car1');
      await _settle(t);
      await t.tap(find.text('Fechar'));
      await _settle(t);
      expect(find.byType(Notice), findsNothing);
      expect(find.byType(LostView), findsOneWidget);
      expect(rig.driver.reconnecting, isTrue);
    });

    for (final size in [const Size(320, 568), const Size(800, 360)]) {
      _stateTest('fits at ${size.width.toInt()}x${size.height.toInt()}', (
        t,
        rig,
      ) async {
        await _mount(t, rig, size: size, textScale: 1.3);
        await _drop(t, rig);
        rig.transport.failConnect = true;
        await rig.driver.connect('car1');
        await _settle(t);
        expect(find.byType(Notice), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  });

  group('Connection failed', () {
    _stateTest('the notice over the list; Try again connects again', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await rig.driver.connect('car1');
      await _settle(t);
      expect(rig.driver.message, MessageKind.connectFailed);
      expect(find.text('Não foi possível conectar ao SF-25'), findsOneWidget);
      expect(
        find.text(
          'Desligue e ligue o carro e confira se nenhum outro app está '
          'conectado a ele.',
        ),
        findsOneWidget,
      );
      expect(find.byType(Notice), findsOneWidget);
      expect(find.text('Carros por perto'), findsOneWidget);

      rig.transport.failConnect = false;
      await t.tap(find.text('Tentar de novo'));
      await _settle(t);
      expect(rig.driver.link, LinkState.connected);
      expect(rig.transport.connected, ['car1']);
      expect(find.byType(Notice), findsNothing);
    }, transport: () => FakeTransport()..failConnect = true);

    _stateTest('Close dismisses it', (t, rig) async {
      await _mount(t, rig);
      await rig.driver.connect('car1');
      await _settle(t);
      await t.tap(find.text('Fechar'));
      await _settle(t);
      expect(rig.driver.message, isNull);
      expect(find.byType(Notice), findsNothing);
    }, transport: () => FakeTransport()..failConnect = true);

    _stateTest(
      'with no car left in range, the notice is there once',
      (t, rig) async {
        await _mount(t, rig);
        await rig.driver.connect('car1');
        await _settle(t);
        // The next prune forgets the car, which is not advertising any more.
        await t.pump(const Duration(seconds: 2));
        expect(rig.driver.cars, isEmpty);
        expect(rig.driver.failedCar, isNotNull);
        expect(find.byType(Notice), findsOneWidget);
        expect(find.text('Não foi possível conectar ao SF-25'), findsOneWidget);
        // Nothing to list: the hints show.
        expect(find.text('Ligue o carro'), findsOneWidget);

        rig.transport.failConnect = false;
        await t.tap(find.text('Tentar de novo'));
        await _settle(t);
        expect(rig.driver.link, LinkState.connected);
      },
      transport: () => FakeTransport()..failConnect = true,
      carStaleAfter: Duration.zero,
    );

    _stateTest('on a desktop the garage column has the notice, once', (
      t,
      rig,
    ) async {
      const size = Size(1180, 760);
      await pumpWithDriver(
        t,
        rig.driver,
        SizedBox(
          width: size.width,
          height: size.height,
          child: const Row(
            children: [
              GarageColumn(),
              Expanded(child: Cockpit(onSettings: _noop)),
            ],
          ),
        ),
        size: size,
      );
      await _settle(t);
      await rig.driver.connect('car1');
      await _settle(t);
      expect(t.takeException(), isNull);
      expect(rig.driver.message, MessageKind.connectFailed);
      expect(find.byType(Notice), findsOneWidget);
      expect(find.text('Não foi possível conectar ao SF-25'), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
      expect(find.byType(CarList), findsOneWidget);
      // The Notice is inside the column.
      expect(
        find.descendant(
          of: find.byType(GarageColumn),
          matching: find.byType(Notice),
        ),
        findsOneWidget,
      );
    }, transport: () => FakeTransport()..failConnect = true);
  });

  group('The header', () {
    _stateTest(
      'says Searching, not Bluetooth off, while Bluetooth is unknown',
      (t, rig) async {
        await _mount(t, rig);
        expect(rig.driver.bluetooth, BluetoothState.unknown);
        expect(find.text('Procurando'), findsOneWidget);
        expect(find.text('Bluetooth desligado'), findsNothing);
        expect(find.text('Bluetooth bloqueado'), findsNothing);
        expect(find.text('Ligar o Bluetooth'), findsNothing);
        expect(find.text('Carros por perto'), findsOneWidget);
      },
      transport: () => FakeTransport()..state = BluetoothState.unknown,
    );
  });

  group('One function decides', () {
    for (final sc in _scenarios) {
      _stateTest(
        '${sc.name}: the header and the screen both say ${sc.state.name}',
        (t, rig) async {
          await sc.prepare(t, rig);
          await _mount(t, rig);
          expect(panelStateOf(rig.driver), sc.state);
          // The line under the name.
          expect(
            find.descendant(
              of: find.byType(CockpitHeader),
              matching: find.text(sc.header(await _l10n('pt'))),
            ),
            findsOneWidget,
          );
          // The screen: this one and no other.
          for (final MapEntry(key: state, value: type) in _screens.entries) {
            expect(
              find.byType(type),
              state == sc.state ? findsOneWidget : findsNothing,
              reason: '${state.name} for ${sc.name}',
            );
          }
          await _drain(t);
        },
        transport: sc.transport,
        prefs: sc.prefs,
        cars: sc.cars,
      );
    }

    // The order of spec 5.2 on a few that pull two ways.
    _stateTest('Bluetooth off outranks a connection being made', (
      t,
      rig,
    ) async {
      unawaited(rig.driver.connect('car1'));
      await t.pump();
      rig.transport.avail.add(BluetoothState.off);
      await t.pump();
      expect(rig.driver.link, LinkState.connecting);
      expect(panelStateOf(rig.driver), PanelState.bluetooth);
      expect(bluetoothBlockOf(rig.driver), BluetoothState.off);
      await _drain(t);
    }, transport: _slow);

    _stateTest(
      'unsupported outranks a refused permission, which outranks off',
      (t, rig) async {
        expect(rig.driver.message, MessageKind.permissionDenied);
        rig.transport.avail.add(BluetoothState.off);
        await t.pump();
        expect(bluetoothBlockOf(rig.driver), BluetoothState.unauthorized);
        rig.transport.avail.add(BluetoothState.unsupported);
        await t.pump();
        expect(bluetoothBlockOf(rig.driver), BluetoothState.unsupported);
      },
      transport: () => FakeTransport()..denyPermission = true,
    );

    _stateTest('an unknown Bluetooth is no problem', (t, rig) async {
      expect(rig.driver.bluetooth, BluetoothState.unknown);
      expect(bluetoothBlockOf(rig.driver), isNull);
      expect(panelStateOf(rig.driver), PanelState.searching);
    }, transport: () => FakeTransport()..state = BluetoothState.unknown);
  });

  group('The search waves', () {
    Finder ring(int i) => find.byKey(SearchWaves.ringKey(i));
    double scale(WidgetTester t, int i) => t
        .widget<Transform>(
          find.descendant(of: ring(i), matching: find.byType(Transform)),
        )
        .transform
        .entry(0, 0); // across: the depth does not scale
    double opacity(WidgetTester t, int i) => t
        .widget<Opacity>(
          find.descendant(of: ring(i), matching: find.byType(Opacity)),
        )
        .opacity;

    /// Mounts the searching cockpit and stands on the first frame of the
    /// waves, with the clock at zero.
    Future<void> mountAtZero(
      WidgetTester t,
      _Rig rig, {
      bool reduceMotion = false,
    }) async {
      await pumpWithDriver(
        t,
        rig.driver,
        _cockpit(),
        reduceMotion: reduceMotion,
      );
      await t.pump();
    }

    _stateTest('three amber rings that start at 0.6 times, 0.8 s apart', (
      t,
      rig,
    ) async {
      await mountAtZero(t, rig);
      expect(ring(0), findsOneWidget);
      expect(ring(1), findsOneWidget);
      expect(ring(2), findsOneWidget);
      expect(ring(3), findsNothing);

      // The first starts now, the second 0.8 s later, the third 1.6 s later.
      expect(scale(t, 0), closeTo(0.6, 0.01));
      expect(opacity(t, 0), closeTo(0.7, 0.01));
      await t.pump(const Duration(milliseconds: 800));
      expect(scale(t, 1), closeTo(0.6, 0.01));
      expect(opacity(t, 1), closeTo(0.7, 0.01));
      expect(scale(t, 0), greaterThan(1));
      await t.pump(const Duration(milliseconds: 800));
      expect(scale(t, 2), closeTo(0.6, 0.01));
      expect(opacity(t, 2), closeTo(0.7, 0.01));
    }, cars: const []);

    _stateTest('a ring grows to 2.2 times and fades out in 2.4 s', (
      t,
      rig,
    ) async {
      await mountAtZero(t, rig);
      var before = scale(t, 0);
      var fading = opacity(t, 0);
      for (var ms = 400; ms <= 2000; ms += 400) {
        await t.pump(const Duration(milliseconds: 400));
        expect(scale(t, 0), greaterThan(before), reason: 'grows at $ms ms');
        expect(opacity(t, 0), lessThan(fading), reason: 'fades at $ms ms');
        before = scale(t, 0);
        fading = opacity(t, 0);
      }
      // Just before the 2.4 s are over: all the way out and gone.
      await t.pump(const Duration(milliseconds: 300));
      expect(scale(t, 0), closeTo(2.2, 0.05));
      expect(opacity(t, 0), closeTo(0, 0.02));
    }, cars: const []);

    _stateTest('they are amber, hairline circles without a clip', (
      t,
      rig,
    ) async {
      await mountAtZero(t, rig);
      final box = t.widget<DecoratedBox>(
        find.descendant(of: ring(0), matching: find.byType(DecoratedBox)).first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      final side = (decoration.border! as Border).top;
      expect(side.width, 1);
      expect(side.color.a, closeTo(0.5, 0.01));
      expect(side.color.r, AppColors.amber.r);
      expect(side.color.g, AppColors.amber.g);
      expect(side.color.b, AppColors.amber.b);
      expect(
        find.descendant(
          of: find.byType(SearchWaves),
          matching: find.byType(ClipRect),
        ),
        findsNothing,
      );
    }, cars: const []);

    _stateTest('with reduce motion there is one ring and it stays put', (
      t,
      rig,
    ) async {
      await mountAtZero(t, rig, reduceMotion: true);
      expect(ring(0), findsOneWidget);
      expect(ring(1), findsNothing);
      final still = scale(t, 0);
      // Nothing is scheduled: the screen settles at once.
      await t.pumpAndSettle();
      await t.pump(const Duration(seconds: 1));
      expect(scale(t, 0), still);
      expect(
        still,
        inInclusiveRange(SearchWaves.fromScale, SearchWaves.toScale),
      );
      expect(opacity(t, 0), greaterThan(0));
    }, cars: const []);

    _stateTest('they are for a search that finds nothing only', (t, rig) async {
      await _mount(t, rig);
      expect(find.byType(SearchWaves), findsNothing);
    });

    _stateTest('and they are not in the way of a screen reader', (
      t,
      rig,
    ) async {
      final handle = t.ensureSemantics();
      await _mount(t, rig);
      expect(
        find.descendant(
          of: find.byType(SearchWaves),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      handle.dispose();
    }, cars: const []);
  });

  group('The lost car, switched off', () {
    Finder cells() => find.byKey(LostView.cellKey);
    Finder pads() => find.byKey(LostView.padKey);

    /// How many different left edges the boxes have: the columns.
    int columns(WidgetTester t, Finder boxes) => {
      for (final e in boxes.evaluate())
        t.getTopLeft(find.byWidget(e.widget)).dx,
    }.length;

    _stateTest('four cells and four arrows, empty glass', (t, rig) async {
      await _mount(t, rig);
      await _drop(t, rig);
      expect(cells(), findsNWidgets(4));
      expect(pads(), findsNWidgets(4));
      // No word of the real cells.
      for (final word in ['Luz', 'Turbo', 'Giro 360°', 'Controle']) {
        expect(find.text(word), findsNothing);
      }
      expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    });

    _stateTest('they are the cells\' grid and the arrows\' height', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await _drop(t, rig);
      expect(t.getSize(cells().first).height, StateCells.minHeight);
      expect(t.getSize(pads().first).height, TouchPads.height);
      expect(columns(t, cells()), 2);
      expect(columns(t, pads()), 4);
    });

    for (final (size, expected) in [
      (const Size(390, 844), 2),
      (const Size(600, 960), 4),
      (const Size(800, 360), 2),
      (const Size(1180, 760), 4),
      (const Size(915, 412), 2),
      (const Size(568, 320), 2),
    ]) {
      _stateTest('${size.width.toInt()}x${size.height.toInt()}: $expected '
          'columns, as with a connected car', (t, rig) async {
        await _mount(t, rig, size: size);
        await _drop(t, rig);
        expect(columns(t, cells()), expected);
      });
    }

    _stateTest('the arrows are only there with the on-screen controls on', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await _drop(t, rig);
      expect(pads(), findsNothing);
      expect(cells(), findsNWidgets(4));
    }, prefs: const {'onScreen': false});

    _stateTest('dimmed, untouchable and mute for a screen reader', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await _drop(t, rig);
      final box = cells().first;
      final opacity = t.widget<Opacity>(
        find.ancestor(of: box, matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, lessThanOrEqualTo(0.5));
      expect(
        find.ancestor(of: box, matching: find.byType(IgnorePointer)),
        findsWidgets,
      );
      expect(
        find.ancestor(of: box, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: find.byType(LostView),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    _stateTest('touching them drives nothing', (t, rig) async {
      await _mount(t, rig);
      await _drop(t, rig);
      final writes = rig.transport.writes.length;
      await t.tapAt(t.getCenter(pads().last));
      await t.tapAt(t.getCenter(cells().first));
      await t.pump(const Duration(milliseconds: 60));
      final c = rig.driver.command;
      expect(
        [c.forward, c.reverse, c.left, c.right, c.light, c.turbo],
        [false, false, false, false, false, false],
      );
      expect(rig.transport.writes.length, writes);
    });

    _stateTest('the name of the lost car is faded in the header', (
      t,
      rig,
    ) async {
      Opacity? around(WidgetTester t) => t
          .widgetList<Opacity>(
            find.ancestor(
              of: find.widgetWithText(MetalText, 'SF-25'),
              matching: find.byType(Opacity),
            ),
          )
          .firstOrNull;
      await _mount(t, rig);
      await rig.driver.connect('car1');
      await _settle(t);
      expect(around(t)?.opacity, 1);
      rig.transport.conn.add(false);
      await _settle(t);
      expect(rig.driver.reconnecting, isTrue);
      expect(around(t)?.opacity, 0.6);
    });

    _stateTest('the car comes back: the instrument replaces it', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await _drop(t, rig);
      expect(find.byType(LostView), findsOneWidget);
      // The car is out of range for a while, so it drops off the list...
      await t.pump(const Duration(seconds: 2));
      expect(rig.driver.cars, isEmpty);
      expect(find.byType(LostView), findsOneWidget);
      // ... and when it shows up again the app connects to it by itself.
      rig.transport.scan.add(_sf25);
      await t.pump(const Duration(milliseconds: 70));
      await _settle(t);
      expect(rig.driver.link, LinkState.connected);
      expect(find.byType(LostView), findsNothing);
      expect(find.byType(Instrument), findsOneWidget);
      expect(find.text('Conexão perdida'), findsNothing);
    }, carStaleAfter: Duration.zero);
  });

  group('On a desktop the garage column is the list', () {
    const size = Size(1180, 760);

    _stateTest('no car: the car, the waves and the hints; no list', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: size);
      expect(find.byType(CarList), findsNothing);
      expect(find.byType(SearchWaves), findsOneWidget);
      expect(find.text('Ligue o carro'), findsOneWidget);
      expect(find.text('Não aparece?'), findsOneWidget);
      expect(find.text('Ainda nada?'), findsOneWidget);
    }, cars: const []);

    _stateTest('with cars: the car and the words Cars nearby, once', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: size);
      expect(find.byType(CarList), findsNothing);
      expect(find.byType(SearchWaves), findsNothing);
      expect(find.text('Carros por perto'), findsOneWidget);
      expect(find.text('Não aparece?'), findsNothing);
      expect(
        t.widget<CarDecal>(find.byType(CarDecal)).variant,
        DecalVariant.ghost,
      );
      // And it has a good size to be seen at.
      expect(
        t.getSize(find.byType(CarDecal)).height,
        greaterThanOrEqualTo(200),
      );
    }, cars: const [_sf25, _gt3]);

    _stateTest('beside the column, "Cars nearby" shows twice: two places', (
      t,
      rig,
    ) async {
      await pumpWithDriver(
        t,
        rig.driver,
        SizedBox(
          width: size.width,
          height: size.height,
          child: const Row(
            children: [
              GarageColumn(),
              Expanded(child: Cockpit(onSettings: _noop)),
            ],
          ),
        ),
        size: size,
      );
      await _settle(t);
      expect(find.byType(CarList), findsOneWidget);
      expect(find.text('Carros por perto'), findsNWidgets(2));
    }, cars: const [_sf25, _gt3]);

    _stateTest('the dropped notice is the screen\'s, once', (t, rig) async {
      await rig.driver.connect('car1');
      await t.pump();
      rig.transport.conn.add(false);
      await t.pump();
      await pumpWithDriver(
        t,
        rig.driver,
        SizedBox(
          width: size.width,
          height: size.height,
          child: const Row(
            children: [
              GarageColumn(),
              Expanded(child: Cockpit(onSettings: _noop)),
            ],
          ),
        ),
        size: size,
      );
      await _settle(t);
      expect(rig.driver.message, MessageKind.dropped);
      expect(find.byType(Notice), findsOneWidget);
      expect(find.text('O carro desconectou.'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GarageColumn),
          matching: find.byType(Notice),
        ),
        findsNothing,
      );
    }, prefs: const {'autoConnect': false});

    _stateTest(
      'it tells a failure only through the column, car or not',
      (t, rig) async {
        await _mount(t, rig, size: size);
        await rig.driver.connect('car1');
        await _settle(t);
        // Cockpit alone: the notice is not its business on a desktop.
        expect(find.byType(Notice), findsNothing);
        await t.pump(const Duration(seconds: 2));
        expect(rig.driver.cars, isEmpty);
        expect(find.byType(Notice), findsNothing);
      },
      transport: () => FakeTransport()..failConnect = true,
      carStaleAfter: Duration.zero,
    );
  });

  group('A failure shows its notice once on every layout', () {
    for (final size in const [
      Size(320, 568),
      Size(390, 844),
      Size(600, 960),
      Size(800, 360),
      // A phone turned sideways.
      Size(915, 412),
      Size(568, 320),
    ]) {
      for (final withCars in [true, false]) {
        _stateTest(
          '${size.width.toInt()}x${size.height.toInt()}, '
          '${withCars ? 'with' : 'without'} cars in range',
          (t, rig) async {
            await _mount(t, rig, size: size);
            await rig.driver.connect('car1');
            await _settle(t);
            if (!withCars) await t.pump(const Duration(seconds: 2));
            expect(rig.driver.cars.isEmpty, !withCars);
            expect(rig.driver.message, MessageKind.connectFailed);
            expect(find.byType(Notice), findsOneWidget);
            expect(
              find.text('Não foi possível conectar ao SF-25'),
              findsOneWidget,
            );
            expect(find.text('Tentar de novo'), findsOneWidget);
            expect(find.text('Fechar'), findsOneWidget);
            expect(t.takeException(), isNull);
          },
          transport: () => FakeTransport()..failConnect = true,
          carStaleAfter: withCars ? const Duration(seconds: 6) : Duration.zero,
        );
      }
    }
  });

  group('Every state, on the smallest phone and in landscape', () {
    const sizes = [
      Size(320, 568),
      Size(800, 360),
      // A phone turned sideways, big and small.
      Size(915, 412),
      Size(568, 320),
    ];
    const codes = ['pt', 'en', 'es'];

    for (final sc in _scenarios.where((s) => s.state != PanelState.connected)) {
      for (final size in sizes) {
        for (final code in codes) {
          for (final reduce in [false, true]) {
            // Reduce motion is one language's worth: it is not about words.
            if (reduce && code != 'pt') continue;
            _stateTest(
              '${sc.name} at ${size.width.toInt()}x${size.height.toInt()} in '
              '$code with reduce motion ${reduce ? 'on' : 'off'}',
              (t, rig) async {
                await sc.prepare(t, rig);
                await _mount(
                  t,
                  rig,
                  size: size,
                  locale: code,
                  reduceMotion: reduce,
                );
                // With reduce motion nothing repeats: the screen settles.
                if (reduce) await t.pumpAndSettle();

                expect(t.takeException(), isNull);
                final screen = find.byType(_screens[sc.state]!);
                expect(screen, findsOneWidget);
                // The words are on the screen, whatever the motion.
                final l = await _l10n(code);
                expect(
                  find.descendant(
                    of: find.byType(CockpitHeader),
                    matching: find.text(sc.header(l)),
                  ),
                  findsOneWidget,
                );
                // Never the colour of the traces for text.
                expect(
                  _textColors(t, find.byType(Cockpit)),
                  isNot(contains(AppColors.trace)),
                );
                // Everything you can press is a target of 48 by 48 or more.
                for (final e in find.byType(InkWell).evaluate()) {
                  final s = t.getSize(find.byWidget(e.widget));
                  expect(s.width, greaterThanOrEqualTo(48));
                  expect(s.height, greaterThanOrEqualTo(48));
                }
                await _drain(t);
              },
              transport: sc.transport,
              prefs: sc.prefs,
              cars: sc.cars,
            );
          }
        }
      }
    }

    // Text that grows scrolls; it does not break the screen.
    for (final sc in _scenarios.where((s) => s.state != PanelState.connected)) {
      _stateTest(
        '${sc.name} with the text at 200% on the smallest phone',
        (t, rig) async {
          await sc.prepare(t, rig);
          await _mount(t, rig, size: const Size(320, 568), textScale: 2);
          expect(t.takeException(), isNull);
          expect(find.byType(_screens[sc.state]!), findsOneWidget);
          await _drain(t);
        },
        transport: sc.transport,
        prefs: sc.prefs,
        cars: sc.cars,
      );
    }

    _stateTest('a short screen scrolls to the last of the hints', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: const Size(320, 568), textScale: 2);
      expect(find.byType(Scrollable), findsWidgets);
      await t.scrollUntilVisible(
        find.text('Desligue e ligue o carro de novo.'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Desligue e ligue o carro de novo.'), findsOneWidget);
    }, cars: const []);
  });
}
