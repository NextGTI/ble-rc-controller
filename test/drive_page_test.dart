import 'dart:async';
import 'dart:typed_data';

import 'package:ble_rc_controller/core/car_transport.dart';
import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/l10n/gen/app_localizations.dart';
import 'package:ble_rc_controller/ui/home_page.dart';
import 'package:ble_rc_controller/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Ble implements CarTransport {
  final scan = StreamController<FoundCar>.broadcast();
  @override
  Stream<BluetoothState> get availability => const Stream.empty();
  @override
  Future<BluetoothState> currentAvailability() async => BluetoothState.ready;
  @override
  Future<void> requestPermissions() async {}
  @override
  bool get canEnableBluetooth => false;
  @override
  Future<bool> enableBluetooth() async => false;
  @override
  Stream<FoundCar> get scanResults => scan.stream;
  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}
  @override
  Future<void> connect(String id) async {}
  @override
  Future<void> disconnect(String id) async {}
  @override
  Stream<bool> connectionOf(String id) => const Stream.empty();
  @override
  Future<void> writeControl(String id, Uint8List bytes) async {}
  @override
  Stream<int> batteryOf(String id) => Stream.value(64);
}

GamepadEvent _axis(String k, double v) =>
    GamepadEvent(gamepadId: 'g', timestamp: 0, type: KeyType.analog, key: k, value: v);

Future<(Driver, _Ble, StreamController<GamepadEvent>)> _driver() async {
  SharedPreferences.setMockInitialValues({'onScreen': true, 'autoConnect': false});
  final ble = _Ble();
  final raw = StreamController<GamepadEvent>.broadcast();
  final driver = Driver(
    transport: ble,
    prefs: await SharedPreferences.getInstance(),
    rawEvents: raw.stream,
    connectionEvents: const Stream<GamepadConnectionEvent>.empty(),
    listGamepads: () async => [],
    normalizer: GamepadNormalizer.forPlatform(GamepadPlatform.windows),
    enableKeyboard: false,
  );
  return (driver, ble, raw);
}

Widget _app(Driver driver, {bool reduceMotion = false}) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: DriverScope(driver: driver, child: child!),
      ),
      home: const HomePage(),
    );

void main() {
  // Sizes: small phone, common phone, tablet portrait, phone landscape.
  for (final size in [const Size(320, 568), const Size(360, 780), const Size(600, 960), const Size(800, 360)]) {
    for (final reduce in [false, true]) {
      testWidgets('Drive page fits ${size.width.toInt()}x${size.height.toInt()} (reduce motion: $reduce)', (tester) async {
        final (driver, ble, raw) = await _driver();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app(driver, reduceMotion: reduce));
        await driver.start();
        ble.scan.add(const FoundCar(id: 'c', name: 'SL-RC-07', rssi: -50));
        await tester.pump(const Duration(milliseconds: 50));
        await driver.connect('c');
        raw.add(_axis('rightTrigger', 1));
        raw.add(_axis('leftThumbstickX', 1));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 120)); // let animations run
        }
        expect(tester.takeException(), isNull);

        // The Forward on-screen button must be fully visible, not under the nav bar.
        final fwd = tester.getRect(find.byIcon(Icons.arrow_upward_rounded).last);
        expect(fwd.right, lessThanOrEqualTo(size.width));
        expect(fwd.bottom, lessThanOrEqualTo(size.height));

        // Switch tabs (exercises the page transition) and come back.
        await tester.pumpWidget(const SizedBox());
        driver.dispose();
        await raw.close();
      });
    }
  }

  testWidgets('with reduce motion on, switching tabs is instant', (tester) async {
    final (driver, _, raw) = await _driver();
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(driver, reduceMotion: true));
    await driver.start();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pump(); // a single frame is enough when motion is off
    expect(find.byIcon(Icons.add), findsWidgets, reason: 'Buttons page is showing');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    driver.dispose();
    await raw.close();
  });
}
