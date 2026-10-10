import 'dart:async';
import 'dart:typed_data';

import 'package:ble_rc_controller/core/car_transport.dart';
import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/l10n/gen/app_localizations.dart';
import 'package:ble_rc_controller/ui/controls_page.dart';
import 'package:ble_rc_controller/ui/strings.dart';
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
  // Regression: long chip labels ("Gatilho direito (RT / R2)") overflowed the
  // Buttons page on phones because the action title took a fixed 120 dp column.
  for (final locale in ['pt', 'en', 'es']) {
    for (final width in [320.0, 360.0, 390.0]) {
      testWidgets('Buttons page fits ${width.toInt()} dp in $locale', (tester) async {
        SharedPreferences.setMockInitialValues({'locale': locale});
        final driver = Driver(
          transport: _NoBle(),
          prefs: await SharedPreferences.getInstance(),
          rawEvents: const Stream<GamepadEvent>.empty(),
          connectionEvents: const Stream<GamepadConnectionEvent>.empty(),
          listGamepads: () async => [],
          enableKeyboard: false,
        );
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: DriverScope(driver: driver, child: const Scaffold(body: ControlsPage())),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'no overflow at $width dp ($locale)');

        await tester.pumpWidget(const SizedBox());
        driver.dispose();
      });
    }
  }
}
