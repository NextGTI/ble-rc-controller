import 'dart:async';
import 'dart:typed_data';

import 'package:ble_rc_controller/core/car_transport.dart';
import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/l10n/gen/app_localizations.dart';
import 'package:ble_rc_controller/ui/strings.dart';
import 'package:ble_rc_controller/ui/touch_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoBle implements CarTransport {
  @override
  Stream<BluetoothState> get availability => const Stream.empty();
  @override
  Future<BluetoothState> currentAvailability() async => BluetoothState.ready;
  @override
  Future<void> requestPermissions() async {}
  @override
  Stream<FoundCar> get scanResults => const Stream.empty();
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
  Stream<int> batteryOf(String id) => const Stream.empty();
}

void main() {
  // Regression: on a 360 dp phone the on-screen buttons overflowed the row and
  // the Forward button was cut off.
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets('on-screen controls fit a ${width.toInt()} dp wide phone', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final driver = Driver(
        transport: _NoBle(),
        prefs: await SharedPreferences.getInstance(),
        rawEvents: const Stream<GamepadEvent>.empty(),
        connectionEvents: const Stream<GamepadConnectionEvent>.empty(),
        listGamepads: () async => [],
        enableKeyboard: false,
      );
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: DriverScope(
          driver: driver,
          child: const Scaffold(
            body: Padding(padding: EdgeInsets.all(16), child: TouchControls()),
          ),
        ),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow at $width dp');

      // The Forward button (top-right of the pedals) must be fully on screen.
      final forward = find.byIcon(Icons.arrow_upward_rounded);
      expect(forward, findsOneWidget);
      final right = tester.getRect(forward).right;
      expect(right, lessThanOrEqualTo(width - 16 + 0.5));

      await tester.pumpWidget(const SizedBox());
      driver.dispose();
    });
  }

  testWidgets('the on-screen turbo and 360° buttons are toggles, the others are held', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final driver = Driver(
      transport: _NoBle(),
      prefs: await SharedPreferences.getInstance(),
      rawEvents: const Stream<GamepadEvent>.empty(),
      connectionEvents: const Stream<GamepadConnectionEvent>.empty(),
      listGamepads: () async => [],
      enableKeyboard: false,
    );
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: DriverScope(
        driver: driver,
        child: const Scaffold(body: Padding(padding: EdgeInsets.all(16), child: TouchControls())),
      ),
    ));

    final turbo = find.text('Turbo');
    await tester.tap(turbo);
    await tester.pump();
    expect(driver.command.turbo, isTrue, reason: 'one tap switches it on...');
    await tester.pump(const Duration(milliseconds: 200));
    expect(driver.command.turbo, isTrue, reason: '...and it stays on after the finger is lifted');

    await tester.tap(turbo);
    await tester.pump();
    expect(driver.command.turbo, isFalse, reason: 'a second tap switches it off');

    // The 360° spin works the same way.
    final spin = find.byIcon(Icons.sync_rounded);
    await tester.tap(spin);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(driver.command.donut, isTrue, reason: 'stays on after the finger is lifted');
    await tester.tap(spin);
    await tester.pump();
    expect(driver.command.donut, isFalse);

    // Forward is still "while held".
    final forward = find.byIcon(Icons.arrow_upward_rounded);
    final g = await tester.startGesture(tester.getCenter(forward));
    await tester.pump();
    expect(driver.command.forward, isTrue);
    await g.up();
    await tester.pump();
    expect(driver.command.forward, isFalse);

    await tester.pumpWidget(const SizedBox());
    driver.dispose();
  });
}
