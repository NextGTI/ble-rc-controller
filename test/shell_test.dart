import 'dart:async';

import 'package:ble_rc_controller/app.dart';
import 'package:ble_rc_controller/core/car_transport.dart';
import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/core/protocol.dart';
import 'package:ble_rc_controller/ui/cockpit/cockpit.dart';
import 'package:ble_rc_controller/ui/cockpit/cockpit_header.dart';
import 'package:ble_rc_controller/ui/cockpit/state_cells.dart';
import 'package:ble_rc_controller/ui/common/ambient.dart';
import 'package:ble_rc_controller/ui/garage/car_list.dart';
import 'package:ble_rc_controller/ui/garage/garage_column.dart';
import 'package:ble_rc_controller/ui/settings/bindings_page.dart';
import 'package:ble_rc_controller/ui/settings/settings_page.dart';
import 'package:ble_rc_controller/ui/shell.dart';
import 'package:ble_rc_controller/ui/strings.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_transport.dart';
import 'support/harness.dart';

const _sf25 = FoundCar(id: 'car1', name: 'SL-SF-25', rssi: -55);
const _gt3 = FoundCar(id: 'car2', name: 'SL-296 GT3', rssi: -70);

const _phone = Size(390, 844);
const _tablet = Size(600, 960);
const _landscape = Size(800, 360);
const _desktop = Size(1180, 760);

/// The side panel of the settings on a desktop window (spec 5.1).
const _drawerWidth = 380.0;

/// Prefs of a desktop window with the arrows off. flutter_test reports
/// Android, where the on-screen controls default to on.
const _noArrows = <String, Object>{'onScreen': false};

/// A driver wired to a fake transport.
class _Rig {
  _Rig(this.driver, this.transport);

  final Driver driver;
  final FakeTransport transport;
}

/// Builds a driver, scans the two cars and, with [connect], connects to the
/// first. With [keyboard] the driver listens to the keyboard like the app.
Future<_Rig> _rig(
  WidgetTester t, {
  Map<String, Object> prefs = const {},
  bool connect = true,
  bool keyboard = false,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final fake = FakeTransport();
  final driver = Driver(
    transport: fake,
    prefs: await SharedPreferences.getInstance(),
    rawEvents: const Stream<GamepadEvent>.empty(),
    connectionEvents: const Stream<GamepadConnectionEvent>.empty(),
    listGamepads: () async => [],
    enableKeyboard: keyboard,
  );
  await driver.start();
  fake.scan.add(_sf25);
  fake.scan.add(_gt3);
  await t.pump(const Duration(milliseconds: 70));
  if (connect) {
    await driver.connect(_sf25.id);
    await t.pump();
    expect(driver.link, LinkState.connected);
  }
  return _Rig(driver, fake);
}

/// A widget test with a [_Rig] that is taken down, widgets first, at the end.
///
/// flutter_test reports Android; a test of the computer passes [platform].
void _shellTest(
  String name,
  Future<void> Function(WidgetTester t, _Rig rig) body, {
  Map<String, Object> prefs = const {},
  bool connect = true,
  bool keyboard = false,
  TargetPlatform? platform,
}) {
  testWidgets(name, (t) async {
    debugDefaultTargetPlatformOverride = platform;
    _Rig? rig;
    try {
      rig = await _rig(t, prefs: prefs, connect: connect, keyboard: keyboard);
      await body(t, rig);
    } finally {
      await t.pumpWidget(const SizedBox());
      rig?.driver.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

/// The shell in a window of [size].
Future<void> _mount(
  WidgetTester t,
  _Rig rig, {
  Size size = _phone,
  bool reduceMotion = false,
}) => pumpWithDriver(
  t,
  rig.driver,
  const Shell(),
  size: size,
  reduceMotion: reduceMotion,
);

final _gear = find.byIcon(Icons.settings_outlined);
final _back = find.byIcon(Icons.chevron_left);
final _close = find.byIcon(Icons.close);

/// The name of the car in the header of the cockpit.
Finder _headerName() => find.descendant(
  of: find.byType(CockpitHeader),
  matching: find.text('SF-25'),
);

/// The panel of the settings: where the first page of them is drawn.
Rect _drawer(WidgetTester t) => t.getRect(find.byType(SettingsPage));

/// The colour of the scrim behind the settings drawer.
Color? _scrim(WidgetTester t) => t
    .widget<AnimatedModalBarrier>(find.byType(AnimatedModalBarrier))
    .color
    .value;

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

  group('Shell on a desktop window', () {
    _shellTest(
      'puts the garage column beside the cockpit',
      (t, rig) async {
        await _mount(t, rig, size: _desktop);
        await t.pumpAndSettle();

        expect(t.takeException(), isNull);
        expect(find.text('Carros por perto'), findsOneWidget);
        expect(find.text('Espaço'), findsOneWidget);
        final column = t.getRect(find.byType(GarageColumn));
        final cockpit = t.getRect(find.byType(Cockpit));
        expect(column.left, 0);
        expect(column.width, 280);
        expect(column.height, _desktop.height);
        expect(cockpit.left, column.right);
        expect(cockpit.right, _desktop.width);
        // The garage is the column, so the name is not a button.
        expect(t.widget<Cockpit>(find.byType(Cockpit)).onCarTap, isNull);
      },
      prefs: _noArrows,
      platform: TargetPlatform.macOS,
    );

    _shellTest(
      'a tablet turned sideways: the column and the cockpit keep clear of '
      'the bars and the cutout',
      (t, rig) async {
        // 24 of status bar, 48 of navigation bar (Android 15 edge to edge)
        // and a camera cutout of 30 on the left.
        const size = Size(1280, 800);
        const bars = FakeViewPadding(top: 24, bottom: 48, left: 30);
        await _mount(t, rig, size: size);
        t.view.viewPadding = bars;
        t.view.padding = bars;
        addTearDown(t.view.resetViewPadding);
        addTearDown(t.view.resetPadding);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);

        // The column: its fill to the edges, its content inside the bars.
        final column = t.getRect(find.byType(GarageColumn));
        expect(column, const Rect.fromLTWH(0, 0, 280, 800));
        final heading = t.getRect(find.text('Carros por perto'));
        expect(heading.top, greaterThanOrEqualTo(24));
        expect(heading.left, greaterThanOrEqualTo(30));
        final toggle = t.getRect(find.byType(AutoConnectToggle));
        expect(toggle.bottom, lessThanOrEqualTo(800 - 48));
        expect(toggle.left, greaterThanOrEqualTo(30));

        // The cockpit: inside the bars too, and no second room for the cutout
        // at its left edge, which is 280 from the window's.
        final name = t.getRect(_headerName());
        expect(name.top, greaterThanOrEqualTo(24));
        expect(name.left, 280 + 36, reason: 'the cutout is not over it');
        expect(
          t.getRect(find.byType(StateCells)).bottom,
          lessThanOrEqualTo(800 - 48),
        );
        expect(t.getRect(_gear).right, lessThanOrEqualTo(1280));
      },
    );

    _shellTest('a failed reconnect shows its notice once, in the column', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: _desktop);
      await t.pumpAndSettle();
      rig.transport.conn.add(false);
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(rig.driver.reconnecting, isTrue);

      rig.transport.failConnect = true;
      await rig.driver.connect('car1');
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));

      expect(rig.driver.reconnecting, isTrue);
      expect(find.text('Não foi possível conectar ao SF-25'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(GarageColumn),
          matching: find.text('Não foi possível conectar ao SF-25'),
        ),
        findsOneWidget,
      );
    }, prefs: _noArrows);

    _shellTest('the garage column has the light of the window behind it', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: _desktop);
      await t.pumpAndSettle();

      // The cockpit paints its own light over its own area; the one behind
      // the column is the shell's, so the glass has something to blur.
      final backdrops = find.byType(AmbientBackdrop);
      expect(backdrops, findsNWidgets(2));
      expect([
        for (var i = 0; i < 2; i++) t.getRect(backdrops.at(i)),
      ], contains(Offset.zero & _desktop));
    }, prefs: _noArrows);

    _shellTest('the gear opens the settings and keeps the car in view', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: _desktop);
      await t.pumpAndSettle();
      expect(find.text('Ajustes'), findsNothing);

      await t.tap(_gear);
      await t.pumpAndSettle();

      expect(t.takeException(), isNull);
      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.byType(SettingsPage), findsOneWidget);
      // The cockpit stays where it was, with the name in plain sight.
      expect(find.byType(Cockpit), findsOneWidget);
      expect(_headerName(), findsOneWidget);
      expect(
        t.getRect(_headerName()).right,
        lessThan(_desktop.width - _drawerWidth),
      );
    }, prefs: _noArrows);

    _shellTest('the settings are a frosted panel of 380 on the right', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: _desktop);
      await t.tap(_gear);
      await t.pumpAndSettle();

      final panel = _drawer(t);
      expect(panel.left, _desktop.width - _drawerWidth);
      expect(panel.right, _desktop.width);
      expect(panel.top, 0);
      expect(panel.bottom, _desktop.height);

      // Glass: a blur of 14 behind, rounded on the inner edge only.
      final blur = find.ancestor(
        of: find.byType(SettingsPage),
        matching: find.byType(BackdropFilter),
      );
      expect(blur, findsOneWidget);
      final clip = t.widget<ClipRRect>(
        find
            .ancestor(
              of: find.byType(SettingsPage),
              matching: find.byType(ClipRRect),
            )
            .first,
      );
      final radius = clip.borderRadius as BorderRadius;
      expect(radius.topLeft, const Radius.circular(24));
      expect(radius.bottomLeft, const Radius.circular(24));
      expect(radius.topRight, Radius.zero);
      expect(radius.bottomRight, Radius.zero);
    }, prefs: _noArrows);

    _shellTest('the cockpit is dimmed by 35% behind the panel', (t, rig) async {
      await _mount(t, rig, size: _desktop);
      await t.tap(_gear);
      await t.pumpAndSettle();

      final scrim = _scrim(t)!;
      expect(scrim.a, closeTo(0.35, 0.005));
      expect(scrim.r + scrim.g + scrim.b, 0, reason: 'black');
    }, prefs: _noArrows);

    _shellTest('a click on the dimmed cockpit closes the settings', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: _desktop);
      await t.tap(_gear);
      await t.pumpAndSettle();
      expect(find.text('Ajustes'), findsOneWidget);

      await t.tapAt(const Offset(500, 400));
      await t.pumpAndSettle();

      expect(find.text('Ajustes'), findsNothing);
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(Cockpit), findsOneWidget);
      expect(t.takeException(), isNull);
    }, prefs: _noArrows);

    _shellTest('a click on the panel itself does not close it', (t, rig) async {
      await _mount(t, rig, size: _desktop);
      await t.tap(_gear);
      await t.pumpAndSettle();

      await t.tap(find.text('Ajustes'));
      await t.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
    }, prefs: _noArrows);

    _shellTest('Esc closes the settings', (t, rig) async {
      await _mount(t, rig, size: _desktop);
      await t.tap(_gear);
      await t.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();

      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(Cockpit), findsOneWidget);
      expect(t.takeException(), isNull);
    }, prefs: _noArrows);

    _shellTest('Esc closes the settings from inside a page too', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: _desktop);
      await t.tap(_gear);
      await t.pumpAndSettle();
      await t.tap(find.text('Botões e teclas'));
      await t.pumpAndSettle();
      expect(find.byType(BindingsPage), findsOneWidget);

      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();

      expect(find.byType(BindingsPage), findsNothing);
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(Cockpit), findsOneWidget);
    }, prefs: _noArrows);

    _shellTest('the pages switch inside the panel, with their own way back', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: _desktop);
      await t.tap(_gear);
      await t.pumpAndSettle();
      // The first page has no way back or close: the panel closes by the
      // scrim and by Esc.
      expect(_back, findsNothing);
      expect(_close, findsNothing);

      await t.tap(find.text('Botões e teclas'));
      await t.pumpAndSettle();

      // Still the panel: a page of 380 on the right, over the cockpit.
      expect(find.byType(BindingsPage), findsOneWidget);
      final page = t.getRect(find.byType(BindingsPage));
      expect(page.left, _desktop.width - _drawerWidth);
      expect(page.width, _drawerWidth);
      expect(find.byType(Cockpit), findsOneWidget);
      // One way back, drawn by the page, not a second one by the shell.
      expect(_back, findsOneWidget);

      await t.tap(_back);
      await t.pumpAndSettle();
      expect(find.byType(BindingsPage), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(_drawer(t).width, _drawerWidth);
    }, prefs: _noArrows);

    _shellTest('the system back goes page by page, then closes the panel', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: _desktop);
      await t.tap(_gear);
      await t.pumpAndSettle();
      await t.tap(find.text('Botões e teclas'));
      await t.pumpAndSettle();

      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.byType(BindingsPage), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);

      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(Cockpit), findsOneWidget);
    }, prefs: _noArrows);

    _shellTest('the panel slides in over 220 ms', (t, rig) async {
      await _mount(t, rig, size: _desktop);
      await t.tap(_gear);
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      final early = _drawer(t).left;
      await t.pump(const Duration(milliseconds: 60));
      final later = _drawer(t).left;
      await t.pumpAndSettle();
      final end = _drawer(t).left;

      expect(end, _desktop.width - _drawerWidth);
      expect(early, greaterThan(later), reason: 'it is coming in');
      expect(later, greaterThan(end), reason: 'and not there yet');
      expect(early, lessThan(_desktop.width), reason: 'but has started');
    }, prefs: _noArrows);

    _shellTest('with reduce motion the panel is in place at once', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: _desktop, reduceMotion: true);
      await t.tap(_gear);
      await t.pump();

      expect(_drawer(t).left, _desktop.width - _drawerWidth);
      expect(_scrim(t)!.a, closeTo(0.35, 0.005));
      // And it goes at once too.
      await t.tapAt(const Offset(500, 400));
      await t.pump();
      expect(find.byType(SettingsPage), findsNothing);
    }, prefs: _noArrows);

    _shellTest('two clicks on the gear before a frame open the panel once', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: _desktop);
      await t.pumpAndSettle();

      final openSettings = t.widget<Cockpit>(find.byType(Cockpit)).onSettings;
      openSettings();
      openSettings();
      await t.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(Cockpit), findsOneWidget);
    }, prefs: _noArrows);

    group('with the keyboard on', () {
      _shellTest(
        'Esc, with the panel closed, does nothing',
        (t, rig) async {
          await _mount(t, rig, size: _desktop);
          await t.pumpAndSettle();

          await t.sendKeyEvent(LogicalKeyboardKey.escape);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          expect(find.byType(Cockpit), findsOneWidget);
          expect(find.byType(SettingsPage), findsNothing);
        },
        prefs: _noArrows,
        keyboard: true,
      );

      _shellTest(
        'the keys still drive with the panel closed',
        (t, rig) async {
          await _mount(t, rig, size: _desktop);
          await t.pumpAndSettle();
          expect(rig.driver.command.forward, isFalse);

          await t.sendKeyDownEvent(LogicalKeyboardKey.keyW);
          await t.pump(const Duration(milliseconds: 40));
          expect(rig.driver.command.forward, isTrue);
          await t.sendKeyUpEvent(LogicalKeyboardKey.keyW);
          await t.pump(const Duration(milliseconds: 40));
          expect(rig.driver.command.forward, isFalse);
        },
        prefs: _noArrows,
        keyboard: true,
      );

      _shellTest(
        'and with the panel open',
        (t, rig) async {
          await _mount(t, rig, size: _desktop);
          await t.tap(_gear);
          await t.pumpAndSettle();

          await t.sendKeyDownEvent(LogicalKeyboardKey.keyW);
          await t.pump(const Duration(milliseconds: 40));
          expect(rig.driver.command.forward, isTrue);
          await t.sendKeyUpEvent(LogicalKeyboardKey.keyW);
          await t.pump(const Duration(milliseconds: 40));
          expect(find.byType(SettingsPage), findsOneWidget);
        },
        prefs: _noArrows,
        keyboard: true,
      );

      _shellTest(
        'Esc that cancels a capture does not close the panel',
        (t, rig) async {
          await _mount(t, rig, size: _desktop);
          await t.tap(_gear);
          await t.pumpAndSettle();
          await t.tap(find.text('Botões e teclas'));
          await t.pumpAndSettle();
          rig.driver.beginCapture(CarAction.light);
          await t.pump();
          expect(rig.driver.capturing, CarAction.light);

          await t.sendKeyEvent(LogicalKeyboardKey.escape);
          await t.pumpAndSettle();

          expect(rig.driver.capturing, isNull, reason: 'the capture is over');
          expect(find.byType(BindingsPage), findsOneWidget);
          expect(find.byType(Cockpit), findsOneWidget);

          // The next Esc is for the panel.
          await t.sendKeyEvent(LogicalKeyboardKey.escape);
          await t.pumpAndSettle();
          expect(find.byType(BindingsPage), findsNothing);
          expect(find.byType(SettingsPage), findsNothing);
        },
        prefs: _noArrows,
        keyboard: true,
      );
    });
  });

  for (final (name, size) in const [
    ('phone', _phone),
    ('tablet', _tablet),
    ('landscape', _landscape),
    // A phone turned sideways is not a desktop window, however wide.
    ('big phone sideways', Size(915, 412)),
    ('small phone sideways', Size(568, 320)),
  ]) {
    group('Shell on a $name', () {
      _shellTest('is the cockpit alone, with the name as a button', (
        t,
        rig,
      ) async {
        await _mount(t, rig, size: size);
        await t.pumpAndSettle();

        expect(t.takeException(), isNull);
        expect(find.byType(Cockpit), findsOneWidget);
        expect(find.byType(GarageColumn), findsNothing);
        expect(t.getRect(find.byType(Cockpit)), Offset.zero & size);
        expect(t.widget<Cockpit>(find.byType(Cockpit)).onCarTap, isNotNull);
      });

      _shellTest('the gear stacks the settings over the cockpit', (
        t,
        rig,
      ) async {
        await _mount(t, rig, size: size);
        await t.pumpAndSettle();

        await t.tap(_gear);
        await t.pumpAndSettle();

        expect(t.takeException(), isNull);
        expect(find.text('Ajustes'), findsOneWidget);
        expect(find.byType(SettingsPage), findsOneWidget);
        // A screen of its own, not a panel.
        expect(t.getSize(find.byType(SettingsPage)).width, size.width);
        expect(find.byType(Cockpit), findsNothing, reason: 'covered');
        // With the ambient light behind it, covering the whole screen.
        expect(find.byType(AmbientBackdrop), findsOneWidget);
        expect(t.getRect(find.byType(AmbientBackdrop)), Offset.zero & size);
      });

      _shellTest('going back returns to the cockpit', (t, rig) async {
        await _mount(t, rig, size: size);
        await t.tap(_gear);
        await t.pumpAndSettle();

        await t.binding.handlePopRoute();
        await t.pumpAndSettle();
        expect(find.byType(SettingsPage), findsNothing);
        expect(find.byType(Cockpit), findsOneWidget);

        // The close cross of the first page does the same.
        await t.tap(_gear);
        await t.pumpAndSettle();
        await t.tap(_close);
        await t.pumpAndSettle();
        expect(find.byType(SettingsPage), findsNothing);
        expect(find.byType(Cockpit), findsOneWidget);
      });

      _shellTest('each page is a new route, and the back goes page by page', (
        t,
        rig,
      ) async {
        await _mount(t, rig, size: size);
        await t.tap(_gear);
        await t.pumpAndSettle();

        await t.tap(find.text('Botões e teclas'));
        await t.pumpAndSettle();
        expect(find.byType(BindingsPage), findsOneWidget);
        expect(find.byType(SettingsPage), findsNothing, reason: 'covered');
        expect(find.byType(AmbientBackdrop), findsOneWidget);
        expect(_back, findsOneWidget);

        await t.tap(_back);
        await t.pumpAndSettle();
        expect(find.byType(BindingsPage), findsNothing);
        expect(find.byType(SettingsPage), findsOneWidget);

        // On a short screen the row is under the fold.
        await t.scrollUntilVisible(find.text('Idioma'), 100);
        await t.ensureVisible(find.text('Idioma'));
        await t.pumpAndSettle();
        await t.tap(find.text('Idioma'));
        await t.pumpAndSettle();
        await t.binding.handlePopRoute();
        await t.pumpAndSettle();
        expect(find.byType(SettingsPage), findsOneWidget);
        await t.binding.handlePopRoute();
        await t.pumpAndSettle();
        expect(find.byType(Cockpit), findsOneWidget);
      });

      _shellTest(
        'two taps on the gear before a frame stack the settings once',
        (t, rig) async {
          await _mount(t, rig, size: size);
          await t.pumpAndSettle();

          final openSettings = t
              .widget<Cockpit>(find.byType(Cockpit))
              .onSettings;
          openSettings();
          openSettings();
          await t.pumpAndSettle();
          expect(find.byType(SettingsPage), findsOneWidget);

          await t.binding.handlePopRoute();
          await t.pumpAndSettle();
          expect(find.byType(SettingsPage), findsNothing);
          expect(find.byType(Cockpit), findsOneWidget);
        },
      );
    });
  }

  group('Shell, a capture left open', () {
    // "+ Adicionar" of the action [a] on the page of buttons and keys.
    Finder add(CarAction a) => find.descendant(
      of: find.byKey(ValueKey<CarAction>(a)),
      matching: find.text('+ Adicionar'),
    );

    _shellTest(
      'the system back on a phone ends it, and the cockpit drives again',
      (t, rig) async {
        await _mount(t, rig);
        await t.pumpAndSettle();
        await t.tap(_gear);
        await t.pumpAndSettle();
        await t.tap(find.text('Botões e teclas'));
        await t.pumpAndSettle();
        await t.tap(add(CarAction.forward));
        await t.pumpAndSettle();
        expect(rig.driver.capturing, CarAction.forward);

        await t.binding.handlePopRoute();
        await t.pumpAndSettle();
        expect(find.byType(BindingsPage), findsNothing);
        expect(rig.driver.capturing, isNull);

        // Up arrow: the cockpit drives, and the key is not bound to anything.
        final before = rig.driver.bindings[CarAction.forward]!.length;
        await t.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
        await t.pump(const Duration(milliseconds: 40));
        expect(rig.driver.command.forward, isTrue);
        await t.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
        await t.pump(const Duration(milliseconds: 40));
        expect(rig.driver.bindings[CarAction.forward]!.length, before);
      },
      keyboard: true,
    );

    _shellTest('the back chevron on a phone ends it', (t, rig) async {
      await _mount(t, rig);
      await t.tap(_gear);
      await t.pumpAndSettle();
      await t.tap(find.text('Botões e teclas'));
      await t.pumpAndSettle();
      await t.tap(add(CarAction.reverse));
      await t.pumpAndSettle();
      expect(rig.driver.capturing, CarAction.reverse);

      await t.tap(_back);
      await t.pumpAndSettle();
      expect(rig.driver.capturing, isNull);
    });

    _shellTest('the scrim of the desktop drawer ends it', (t, rig) async {
      await _mount(t, rig, size: _desktop);
      await t.tap(_gear);
      await t.pumpAndSettle();
      await t.tap(find.text('Botões e teclas'));
      await t.pumpAndSettle();
      await t.tap(add(CarAction.forward));
      await t.pumpAndSettle();
      expect(rig.driver.capturing, CarAction.forward);

      await t.tapAt(const Offset(500, 400));
      await t.pumpAndSettle();
      expect(find.byType(BindingsPage), findsNothing);
      expect(rig.driver.capturing, isNull);
    }, prefs: _noArrows);

    _shellTest(
      'Esc on the desktop drawer ends it, and the next Esc closes',
      (t, rig) async {
        await _mount(t, rig, size: _desktop);
        await t.tap(_gear);
        await t.pumpAndSettle();
        await t.tap(find.text('Botões e teclas'));
        await t.pumpAndSettle();
        await t.tap(add(CarAction.forward));
        await t.pumpAndSettle();
        expect(rig.driver.capturing, CarAction.forward);

        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pumpAndSettle();
        expect(rig.driver.capturing, isNull);
        expect(find.byType(BindingsPage), findsOneWidget);

        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pumpAndSettle();
        expect(find.byType(BindingsPage), findsNothing);
        expect(rig.driver.capturing, isNull);
      },
      prefs: _noArrows,
      keyboard: true,
    );

    _shellTest('the system back in the desktop drawer ends it', (t, rig) async {
      await _mount(t, rig, size: _desktop);
      await t.tap(_gear);
      await t.pumpAndSettle();
      await t.tap(find.text('Botões e teclas'));
      await t.pumpAndSettle();
      await t.tap(add(CarAction.reverse));
      await t.pumpAndSettle();
      expect(rig.driver.capturing, CarAction.reverse);

      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.byType(BindingsPage), findsNothing);
      expect(rig.driver.capturing, isNull);
    }, prefs: _noArrows);
  });

  group('Shell, the sheet of cars', () {
    _shellTest('the name of the car opens it', (t, rig) async {
      await _mount(t, rig);
      await t.pumpAndSettle();
      expect(find.byType(CarList), findsNothing);

      await t.tap(_headerName());
      await t.pumpAndSettle();

      expect(find.byType(CarList), findsOneWidget);
      expect(find.text('Reconectar ao último carro'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    _shellTest('two taps before a frame open one sheet, not two', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await t.pumpAndSettle();

      // The second tap gets through when no frame has drawn the first sheet
      // (and its barrier) yet.
      final openCars = t.widget<Cockpit>(find.byType(Cockpit)).onCarTap!;
      openCars();
      openCars();
      await t.pumpAndSettle();
      expect(find.byType(CarList), findsOneWidget);

      // One drag down and it is gone: there was no sheet under it.
      await t.fling(
        find.descendant(of: find.byType(CarList), matching: find.text('SF-25')),
        const Offset(0, 600),
        2000,
      );
      await t.pumpAndSettle();
      expect(find.byType(CarList), findsNothing);
    });

    _shellTest('a tap on the name after it closed opens it again', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await t.pumpAndSettle();

      await t.tap(_headerName());
      await t.pumpAndSettle();
      await t.tapAt(const Offset(195, 30));
      await t.pumpAndSettle();
      expect(find.byType(CarList), findsNothing);

      await t.tap(_headerName());
      await t.pumpAndSettle();
      expect(find.byType(CarList), findsOneWidget);
    });

    _shellTest('with the settings on top the name is not a way to a sheet', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await t.pumpAndSettle();
      final onCarTap = t.widget<Cockpit>(find.byType(Cockpit)).onCarTap!;

      await t.tap(_gear);
      await t.pumpAndSettle();
      onCarTap();
      await t.pumpAndSettle();
      expect(find.byType(CarList), findsNothing);
    });
  });

  group('BleRcApp', () {
    Future<_Rig> start(WidgetTester t, {Map<String, Object> prefs = const {}}) {
      t.view.physicalSize = _phone;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      return _rig(t, prefs: prefs, connect: false);
    }

    Future<void> finish(WidgetTester t, _Rig rig) async {
      await t.pumpWidget(const SizedBox());
      rig.driver.dispose();
    }

    testWidgets('mounts the shell with the dark theme only', (t) async {
      final rig = await start(t);
      await t.pumpWidget(BleRcApp(driver: rig.driver));
      // Searching never settles (waves, ring): timed pumps.
      for (var i = 0; i < 3; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      expect(t.takeException(), isNull);
      expect(find.byType(Shell), findsOneWidget);
      final context = t.element(find.byType(Shell));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(Theme.of(context).colorScheme.primary, AppColors.amber);
      expect(DriverScope.of(context), same(rig.driver));
      final app = t.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme!.brightness, Brightness.dark);
      expect(app.darkTheme, isNull);
      await finish(t, rig);
    });

    testWidgets('is dark whatever the system asks', (t) async {
      final rig = await start(t);
      t.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
      await t.pumpWidget(BleRcApp(driver: rig.driver));
      await t.pump(const Duration(milliseconds: 100));

      expect(
        Theme.of(t.element(find.byType(Shell))).brightness,
        Brightness.dark,
      );
      await finish(t, rig);
    });

    testWidgets('follows the language of the driver, and the system for '
        '"system"', (t) async {
      final rig = await start(t, prefs: {'locale': 'es'});
      await t.pumpWidget(BleRcApp(driver: rig.driver));
      await t.pump(const Duration(milliseconds: 100));
      expect(
        t.widget<MaterialApp>(find.byType(MaterialApp)).locale,
        const Locale('es'),
      );
      expect(
        Localizations.localeOf(t.element(find.byType(Shell))).languageCode,
        'es',
      );

      rig.driver.localeCode = 'system';
      await t.pump(const Duration(milliseconds: 100));
      expect(t.widget<MaterialApp>(find.byType(MaterialApp)).locale, isNull);
      await finish(t, rig);
    });

    testWidgets('the gear opens the settings in the real app', (t) async {
      final rig = await start(t, prefs: {'locale': 'en'});
      await t.pumpWidget(BleRcApp(driver: rig.driver));
      await t.pump(const Duration(milliseconds: 100));

      await t.tap(_gear);
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Settings'), findsOneWidget);
      expect(t.takeException(), isNull);
      await finish(t, rig);
    });
  });
}
