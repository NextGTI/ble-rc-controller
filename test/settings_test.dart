import 'dart:async';

import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/ui/common/amber_switch.dart';
import 'package:ble_rc_controller/ui/common/settings_row.dart';
import 'package:ble_rc_controller/ui/settings/about_page.dart';
import 'package:ble_rc_controller/ui/settings/bindings_page.dart';
import 'package:ble_rc_controller/ui/settings/controllers_page.dart';
import 'package:ble_rc_controller/ui/settings/language_page.dart';
import 'package:ble_rc_controller/ui/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_transport.dart';
import 'support/harness.dart';

/// The row of the setting called [title]: the `SettingsRow` that has it.
Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SettingsRow));

/// [text] inside the row called [title].
Finder _inRow(String title, String text) =>
    find.descendant(of: _row(title), matching: find.text(text));

/// A button on a page that pushes [page] as a route, the way the phone does.
Widget _pusher(Widget page) => Builder(
  builder: (context) => TextButton(
    onPressed: () => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => Material(child: page))),
    child: const Text('abrir'),
  ),
);

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

  group('SettingsPage', () {
    testWidgets('has the groups Comandos, Pilotagem and App', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
      await t.pumpAndSettle();
      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Comandos'), findsOneWidget);
      expect(find.text('Pilotagem'), findsOneWidget);
      expect(find.text('App'), findsOneWidget);
    });

    testWidgets('has every row of spec 5.4 with what it does', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
      await t.pumpAndSettle();
      expect(_inRow('Botões e teclas', 'O que cada entrada faz'), findsOne);
      expect(_inRow('Controles', 'Nenhum controle'), findsOne);
      expect(_inRow('Botões na tela', 'Para tablet e celular'), findsOne);
      expect(
        _inRow('Zona morta do analógico', 'Ignora toques leves no analógico'),
        findsOne,
      );
      expect(_row('Reconectar ao último carro'), findsOne);
      expect(_row('Idioma'), findsOne);
      expect(_row('Sobre'), findsOne);
    });

    testWidgets('tapping "Botões e teclas" opens a BindingsPage', (t) async {
      final d = await newDriver();
      Widget? opened;
      await pumpWithDriver(t, d, SettingsPage(open: (page) => opened = page));
      await t.pumpAndSettle();
      await t.tap(find.text('Botões e teclas'));
      expect(opened, isA<BindingsPage>());
    });

    testWidgets('tapping "Idioma" opens the LanguagePage', (t) async {
      final d = await newDriver();
      Widget? opened;
      await pumpWithDriver(t, d, SettingsPage(open: (page) => opened = page));
      await t.pumpAndSettle();
      await t.tap(find.text('Idioma'));
      expect(opened, isA<LanguagePage>());
    });

    testWidgets('tapping "Sobre" opens the AboutPage', (t) async {
      final d = await newDriver();
      Widget? opened;
      await pumpWithDriver(t, d, SettingsPage(open: (page) => opened = page));
      await t.pumpAndSettle();
      await t.tap(find.text('Sobre'));
      expect(opened, isA<AboutPage>());
    });

    testWidgets('tapping "Controles" opens the ControllersPage', (t) async {
      final d = await newDriver();
      Widget? opened;
      await pumpWithDriver(t, d, SettingsPage(open: (page) => opened = page));
      await t.pumpAndSettle();
      await t.tap(find.text('Controles'));
      expect(opened, isA<ControllersPage>());
      // It keeps the title of the row, and goes on opening through the same
      // callback.
      await pumpWithDriver(t, d, opened!);
      await t.pumpAndSettle();
      expect(find.text('Controles'), findsOneWidget);
    });

    testWidgets('Controles names the connected controller', (t) async {
      SharedPreferences.setMockInitialValues({});
      final connections = StreamController<GamepadConnectionEvent>.broadcast();
      final d = Driver(
        transport: FakeTransport(),
        prefs: await SharedPreferences.getInstance(),
        rawEvents: const Stream<GamepadEvent>.empty(),
        connectionEvents: connections.stream,
        listGamepads: () async => [],
        enableKeyboard: false,
      );
      await d.start();
      await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
      await t.pumpAndSettle();
      expect(_inRow('Controles', 'Nenhum controle'), findsOne);

      connections.add(
        GamepadConnectionEvent(
          gamepadId: 'g1',
          name: 'DualShock 4',
          type: GamepadConnectionEventType.connected,
        ),
      );
      await t.pumpAndSettle();
      expect(_inRow('Controles', 'DualShock 4'), findsOne);
      expect(find.text('Nenhum controle'), findsNothing);

      connections.add(
        GamepadConnectionEvent(
          gamepadId: 'g1',
          name: 'DualShock 4',
          type: GamepadConnectionEventType.disconnected,
        ),
      );
      await t.pumpAndSettle();
      expect(_inRow('Controles', 'Nenhum controle'), findsOne);

      await t.pumpWidget(const SizedBox());
      d.dispose();
      await connections.close();
    });

    group('switches', () {
      testWidgets('"Botões na tela" follows the driver and turns it', (
        t,
      ) async {
        final d = await newDriver(prefs: {'onScreen': false});
        await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
        await t.pumpAndSettle();
        final sw = find.descendant(
          of: _row('Botões na tela'),
          matching: find.byType(AmberSwitch),
        );
        expect(t.widget<AmberSwitch>(sw).value, isFalse);
        await t.tap(sw);
        await t.pumpAndSettle();
        expect(d.onScreenControls, isTrue);
        expect(t.widget<AmberSwitch>(sw).value, isTrue);
        await t.tap(sw);
        await t.pumpAndSettle();
        expect(d.onScreenControls, isFalse);
      });

      testWidgets('"Reconectar ao último carro" follows the driver and turns '
          'it', (t) async {
        final d = await newDriver(prefs: {'autoConnect': true});
        await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
        await t.pumpAndSettle();
        final sw = find.descendant(
          of: _row('Reconectar ao último carro'),
          matching: find.byType(AmberSwitch),
        );
        expect(t.widget<AmberSwitch>(sw).value, isTrue);
        await t.tap(sw);
        await t.pumpAndSettle();
        expect(d.autoConnect, isFalse);
        expect(t.widget<AmberSwitch>(sw).value, isFalse);
      });

      testWidgets('a row with a switch is not itself a button (no double '
          'toggle)', (t) async {
        final d = await newDriver(prefs: {'onScreen': false});
        await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
        await t.pumpAndSettle();
        // The text of the row is not a target: only the switch is.
        await t.tap(find.text('Botões na tela'));
        await t.pumpAndSettle();
        expect(d.onScreenControls, isFalse);
        for (final title in ['Botões na tela', 'Reconectar ao último carro']) {
          final row = t.widget<SettingsRow>(_row(title));
          expect(row.onTap, isNull, reason: title);
          expect(row.trailing, isA<AmberSwitch>(), reason: title);
        }
      });

      testWidgets('a switch row is one control named by its title', (t) async {
        final handle = t.ensureSemantics();
        final d = await newDriver(prefs: {'autoConnect': true});
        await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
        await t.pumpAndSettle();
        final node = t.getSemantics(
          find.descendant(
            of: _row('Reconectar ao último carro'),
            matching: find.byType(AmberSwitch),
          ),
        );
        expect(node.label, 'Reconectar ao último carro');
        expect(node, isSemantics(hasToggledState: true, isToggled: true));
        handle.dispose();
      });
    });

    group('dead zone', () {
      testWidgets('is a slider from 0.10 to 0.60 in steps of 0.05', (t) async {
        final d = await newDriver(prefs: {'deadzone': 0.35});
        await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
        await t.pumpAndSettle();
        final slider = t.widget<Slider>(find.byType(Slider));
        expect(slider.min, 0.10);
        expect(slider.max, 0.60);
        expect(slider.divisions, 10);
        expect(slider.value, closeTo(0.35, 1e-9));
      });

      testWidgets('shows the value of the driver as a percentage', (t) async {
        final d = await newDriver(prefs: {'deadzone': 0.35});
        await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
        await t.pumpAndSettle();
        expect(_inRow('Zona morta do analógico', '35%'), findsOne);
        d.deadzone = 0.5;
        await t.pumpAndSettle();
        expect(_inRow('Zona morta do analógico', '50%'), findsOne);
        expect(t.widget<Slider>(find.byType(Slider)).value, closeTo(0.5, 1e-9));
      });

      testWidgets('dragging the slider to the end leaves 0.60', (t) async {
        final d = await newDriver(prefs: {'deadzone': 0.35});
        await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
        await t.pumpAndSettle();
        await t.drag(find.byType(Slider), const Offset(600, 0));
        await t.pumpAndSettle();
        expect(d.deadzone, closeTo(0.60, 1e-9));
        expect(_inRow('Zona morta do analógico', '60%'), findsOne);
      });

      testWidgets('dragging the slider to the start leaves 0.10', (t) async {
        final d = await newDriver(prefs: {'deadzone': 0.35});
        await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
        await t.pumpAndSettle();
        await t.drag(find.byType(Slider), const Offset(-600, 0));
        await t.pumpAndSettle();
        expect(d.deadzone, closeTo(0.10, 1e-9));
      });

      testWidgets('a value saved by the old slider (up to 70%) still shows', (
        t,
      ) async {
        final d = await newDriver(prefs: {'deadzone': 0.7});
        await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        // The text tells the real value; the knob rests at the end of the bar.
        expect(_inRow('Zona morta do analógico', '70%'), findsOne);
        expect(t.widget<Slider>(find.byType(Slider)).value, closeTo(0.6, 1e-9));
        expect(d.deadzone, 0.7, reason: 'looking at it changes nothing');
      });

      testWidgets('the slider is named and valued for a screen reader', (
        t,
      ) async {
        final handle = t.ensureSemantics();
        final d = await newDriver(prefs: {'deadzone': 0.35});
        await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
        await t.pumpAndSettle();
        // What the platform is told: one node, named by the row.
        final data = t.getSemantics(find.byType(Slider)).getSemanticsData();
        expect(data.label, contains('Zona morta do analógico'));
        expect(data.label, contains('Ignora toques leves no analógico'));
        expect(data.value, '35%');
        expect(data.increasedValue, '40%');
        expect(data.decreasedValue, '30%');
        expect(
          t.getSemantics(find.byType(Slider)),
          isSemantics(isSlider: true, hasIncreaseAction: true),
        );
        handle.dispose();
      });
    });

    group('language row', () {
      for (final (code, name) in [
        ('system', 'Sistema'),
        ('pt', 'Português'),
        ('en', 'English'),
        ('es', 'Español'),
      ]) {
        testWidgets('says $name for "$code"', (t) async {
          final d = await newDriver(prefs: {'locale': code});
          await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
          await t.pumpAndSettle();
          expect(_inRow('Idioma', name), findsOne);
        });
      }
    });

    testWidgets('About says the version of the app', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
      await t.pumpAndSettle();
      expect(_inRow('Sobre', 'Versão 1.0.2, código aberto'), findsOne);
    });

    testWidgets('a version that cannot be read leaves the line out', (t) async {
      final d = await newDriver();
      // No mock and no platform: the lookup fails, and the page must not.
      PackageInfo.setMockInitialValues(
        appName: '',
        packageName: '',
        version: '',
        buildNumber: '',
        buildSignature: '',
      );
      await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(_row('Sobre'), findsOne);
      expect(find.textContaining('Versão'), findsNothing);
    });

    testWidgets('speaks the language of the app', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, SettingsPage(open: (_) {}), locale: 'en');
      await t.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Commands'), findsOneWidget);
      expect(find.text('Driving'), findsOneWidget);
      expect(find.text('Buttons and keys'), findsOneWidget);
      expect(find.text('No controller'), findsOneWidget);
      expect(_inRow('About', 'Version 1.0.2, open source'), findsOne);
    });

    group('header', () {
      testWidgets('has no back or close button when it is not pushed', (
        t,
      ) async {
        final d = await newDriver();
        await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
        await t.pumpAndSettle();
        expect(find.byType(BackButton), findsNothing);
        expect(find.byIcon(Icons.close), findsNothing);
        expect(find.byIcon(Icons.chevron_left), findsNothing);
      });

      testWidgets('has a close button when pushed, and it pops', (t) async {
        final d = await newDriver();
        await pumpWithDriver(t, d, _pusher(SettingsPage(open: (_) {})));
        await t.tap(find.text('abrir'));
        await t.pumpAndSettle();
        expect(find.text('Ajustes'), findsOneWidget);
        final close = find.byIcon(Icons.close);
        expect(close, findsOneWidget);
        expect(
          t
              .getSize(
                find.ancestor(of: close, matching: find.byType(IconButton)),
              )
              .width,
          greaterThanOrEqualTo(48),
        );
        await t.tap(close);
        await t.pumpAndSettle();
        expect(find.text('Ajustes'), findsNothing);
        expect(find.text('abrir'), findsOneWidget);
      });
    });

    group('fits', () {
      for (final locale in ['pt', 'en', 'es']) {
        for (final width in [320.0, 360.0, 390.0, 380.0]) {
          testWidgets('$width wide in $locale, large text, no overflow', (
            t,
          ) async {
            final d = await newDriver();
            await pumpWithDriver(
              t,
              d,
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: SettingsPage(open: (_) {}),
                ),
              ),
              size: Size(width, 640),
              locale: locale,
            );
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
          });
        }
      }

      testWidgets('rows are at least 56 high and touch targets 48', (t) async {
        final d = await newDriver();
        await pumpWithDriver(t, d, SettingsPage(open: (_) {}));
        await t.pumpAndSettle();
        for (final row in t.widgetList<SettingsRow>(find.byType(SettingsRow))) {
          expect(
            t.getSize(find.byWidget(row)).height,
            greaterThanOrEqualTo(SettingsRow.minHeight),
            reason: row.title,
          );
        }
        for (final sw in t.widgetList(find.byType(AmberSwitch))) {
          final size = t.getSize(find.byWidget(sw));
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        expect(t.getSize(find.byType(Slider)).height, greaterThanOrEqualTo(48));
      });

      testWidgets('scrolls on a short screen instead of overflowing', (
        t,
      ) async {
        final d = await newDriver();
        await pumpWithDriver(
          t,
          d,
          SettingsPage(open: (_) {}),
          size: const Size(320, 400),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await t.drag(find.byType(Scrollable).first, const Offset(0, -800));
        await t.pumpAndSettle();
        expect(find.text('Sobre'), findsOneWidget);
        expect(
          t.getRect(_row('Sobre')).bottom,
          lessThanOrEqualTo(400),
          reason: 'About can be scrolled into view',
        );
      });
    });
  });

  group('LanguagePage', () {
    testWidgets('lists Sistema, Português, English and Español in order', (
      t,
    ) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, const LanguagePage());
      await t.pumpAndSettle();
      expect(find.text('Idioma'), findsOneWidget);
      final ys = [
        for (final name in ['Sistema', 'Português', 'English', 'Español'])
          t.getTopLeft(find.text(name)).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      expect(ys.toSet().length, 4);
    });

    testWidgets('tapping "English" leaves the code at en', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, const LanguagePage());
      await t.pumpAndSettle();
      await t.tap(find.text('English'));
      await t.pumpAndSettle();
      expect(d.localeCode, 'en');
    });

    testWidgets('every row sets its code', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, const LanguagePage());
      await t.pumpAndSettle();
      for (final (name, code) in [
        ('Español', 'es'),
        ('Português', 'pt'),
        ('English', 'en'),
        ('Sistema', 'system'),
      ]) {
        await t.tap(find.text(name));
        await t.pumpAndSettle();
        expect(d.localeCode, code, reason: name);
      }
    });

    for (final (code, name) in [
      ('system', 'Sistema'),
      ('pt', 'Português'),
      ('en', 'English'),
      ('es', 'Español'),
    ]) {
      testWidgets('marks only $name when the code is "$code"', (t) async {
        final d = await newDriver(prefs: {'locale': code});
        await pumpWithDriver(t, d, const LanguagePage());
        await t.pumpAndSettle();
        final marks = find.byIcon(Icons.check);
        expect(marks, findsOneWidget);
        expect(
          find.descendant(of: _row(name), matching: find.byIcon(Icons.check)),
          findsOneWidget,
        );
        final icon = t.widget<Icon>(marks);
        expect(icon.color, const Color(0xFFFFB547), reason: 'amber');
      });
    }

    testWidgets('the mark moves when the choice changes', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, const LanguagePage());
      await t.pumpAndSettle();
      expect(
        find.descendant(
          of: _row('Sistema'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      await t.tap(find.text('Español'));
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        find.descendant(
          of: _row('Español'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a code the app does not know counts as Sistema', (t) async {
      final d = await newDriver(prefs: {'locale': 'fr'});
      await pumpWithDriver(t, d, const LanguagePage());
      await t.pumpAndSettle();
      expect(
        find.descendant(
          of: _row('Sistema'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the chosen row tells a screen reader it is selected', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      final d = await newDriver(prefs: {'locale': 'en'});
      await pumpWithDriver(t, d, const LanguagePage());
      await t.pumpAndSettle();
      expect(
        t.getSemantics(_row('English')),
        isSemantics(
          label: 'English',
          hasSelectedState: true,
          isSelected: true,
          isButton: true,
        ),
      );
      expect(
        t.getSemantics(_row('Español')),
        isSemantics(
          label: 'Español',
          hasSelectedState: true,
          isSelected: false,
          isButton: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('has a back button when pushed, and it pops', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, _pusher(const LanguagePage()));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.text('Idioma'), findsOneWidget);
      await t.tap(find.byIcon(Icons.chevron_left));
      await t.pumpAndSettle();
      expect(find.text('Idioma'), findsNothing);
    });

    testWidgets('changing the language does not close the page', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, _pusher(const LanguagePage()));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await t.tap(find.text('English'));
      await t.pumpAndSettle();
      expect(find.text('English'), findsOneWidget);
      expect(d.localeCode, 'en');
    });
  });
  group('AboutPage', () {
    testWidgets('shows the name, the version, the licence and the notice', (
      t,
    ) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, const AboutPage());
      await t.pumpAndSettle();
      expect(find.text('Sobre'), findsOneWidget);
      expect(find.text('BLE RC Controller'), findsOneWidget);
      expect(find.text('Versão 1.0.2 (7)'), findsOneWidget);
      expect(find.text('Licença MIT'), findsOneWidget);
      expect(
        find.textContaining(
          'Projeto de código aberto, independente e não oficial',
        ),
        findsOneWidget,
      );
      expect(find.text('Licenças de código aberto'), findsOneWidget);
    });

    testWidgets('the version is the one of the package', (t) async {
      PackageInfo.setMockInitialValues(
        appName: 'x',
        packageName: 'x',
        version: '2.4.0',
        buildNumber: '31',
        buildSignature: '',
      );
      final d = await newDriver();
      await pumpWithDriver(t, d, const AboutPage());
      await t.pumpAndSettle();
      expect(find.text('Versão 2.4.0 (31)'), findsOneWidget);
    });

    testWidgets('a package with no build number shows the version alone', (
      t,
    ) async {
      PackageInfo.setMockInitialValues(
        appName: 'x',
        packageName: 'x',
        version: '2.4.0',
        buildNumber: '',
        buildSignature: '',
      );
      final d = await newDriver();
      await pumpWithDriver(t, d, const AboutPage());
      await t.pumpAndSettle();
      expect(find.text('Versão 2.4.0'), findsOneWidget);
    });

    testWidgets('the repository address is text that can be selected', (
      t,
    ) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, const AboutPage());
      await t.pumpAndSettle();
      expect(find.text('Código-fonte'), findsOneWidget);
      final address = find.widgetWithText(
        SelectableText,
        'github.com/daniel-nextgti/ble-rc-controller',
      );
      expect(address, findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('the licences button opens the licence page', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, const AboutPage());
      await t.pumpAndSettle();
      expect(find.byType(LicensePage), findsNothing);
      await t.tap(find.text('Licenças de código aberto'));
      await t.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('is in the language of the app', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, const AboutPage(), locale: 'es');
      await t.pumpAndSettle();
      expect(find.text('Acerca de'), findsOneWidget);
      expect(find.text('Versión 1.0.2 (7)'), findsOneWidget);
      expect(find.text('Licencia MIT'), findsOneWidget);
      expect(find.text('Código fuente'), findsOneWidget);
      expect(find.text('Licencias de código abierto'), findsOneWidget);
    });

    testWidgets('has a back button when pushed, and it pops', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, _pusher(const AboutPage()));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.text('Sobre'), findsOneWidget);
      await t.tap(find.byIcon(Icons.chevron_left));
      await t.pumpAndSettle();
      expect(find.text('Sobre'), findsNothing);
    });

    for (final locale in ['pt', 'en', 'es']) {
      for (final width in [320.0, 360.0, 390.0]) {
        testWidgets('fits ${width.toInt()} wide in $locale at 1.5 times the '
            'text', (t) async {
          final d = await newDriver();
          await pumpWithDriver(
            t,
            d,
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.5)),
                child: const AboutPage(),
              ),
            ),
            size: Size(width, 700),
            locale: locale,
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        });
      }
    }

    testWidgets('the licences button is a 48 high target', (t) async {
      final d = await newDriver();
      await pumpWithDriver(t, d, const AboutPage());
      await t.pumpAndSettle();
      final button = find.ancestor(
        of: find.text('Licenças de código aberto'),
        matching: find.byType(InkWell),
      );
      expect(t.getSize(button.first).height, greaterThanOrEqualTo(48));
    });
  });
}
