import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/core/protocol.dart';
import 'package:ble_rc_controller/input/bindings.dart';
import 'package:ble_rc_controller/input/input_ref.dart';
import 'package:ble_rc_controller/input/pad_input.dart';
import 'package:ble_rc_controller/ui/cockpit/particles.dart';
import 'package:ble_rc_controller/ui/common/amber_switch.dart';
import 'package:ble_rc_controller/ui/common/glass.dart';
import 'package:ble_rc_controller/ui/common/input_tag.dart';
import 'package:ble_rc_controller/ui/settings/bindings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

/// The block of [a] on the page: its name, its hint, its tags and its add
/// button.
Finder _block(CarAction a) => find.byKey(ValueKey<CarAction>(a));

/// [text] inside the block of [a].
Finder _in(CarAction a, String text) =>
    find.descendant(of: _block(a), matching: find.text(text));

/// The "+ Adicionar" button of [a].
Finder _add(CarAction a) => _in(a, '+ Adicionar');

/// The tag called [label] in the block of [a].
Finder _tag(CarAction a, String label) => find.descendant(
  of: _block(a),
  matching: find.widgetWithText(InputTag, label),
);

/// The "×" of the tag called [label] in the block of [a].
Finder _remove(CarAction a, String label) =>
    find.descendant(of: _tag(a, label), matching: find.byType(IconButton));

/// A window tall enough for the seven actions without scrolling, so a test can
/// reach every "+ Adicionar".
const _tall = Size(390, 1700);

/// Mounts the page in a tall window.
Future<void> _pump(WidgetTester t, Driver d, {String locale = 'pt'}) =>
    pumpWithDriver(t, d, const BindingsPage(), size: _tall, locale: locale);

void main() {
  setUpAll(loadSaira);

  group('BindingsPage', () {
    testWidgets('shows the seven actions in the order of CarAction', (t) async {
      final d = await newDriver();
      await _pump(t, d);
      await t.pumpAndSettle();
      expect(find.text('Botões e teclas'), findsOneWidget);
      final names = [
        'Frente',
        'Ré',
        'Esquerda',
        'Direita',
        'Luz',
        'Turbo',
        'Giro 360°',
      ];
      expect(names.length, CarAction.values.length);
      for (final a in CarAction.values) {
        expect(_block(a), findsOneWidget, reason: a.name);
        expect(_in(a, names[a.index]), findsOneWidget, reason: a.name);
      }
      final ys = [for (final a in CarAction.values) t.getTopLeft(_block(a)).dy];
      expect(ys, orderedEquals([...ys]..sort()));
    });

    testWidgets('each action says how it works', (t) async {
      final d = await newDriver();
      await _pump(t, d);
      await t.pumpAndSettle();
      for (final a in CarAction.values) {
        final hint = a.isToggle
            ? 'cada toque liga e desliga'
            : 'enquanto pressionado';
        expect(_in(a, hint), findsOneWidget, reason: a.name);
      }
      expect(find.text('cada toque liga e desliga'), findsOneWidget);
      expect(find.text('enquanto pressionado'), findsNWidgets(6));
    });

    group('lead', () {
      testWidgets('says "Toque" on a phone', (t) async {
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        expect(
          find.text(
            'Toque em Adicionar e aperte um botão do controle, mova o '
            'analógico ou aperte uma tecla.',
          ),
          findsOneWidget,
        );
      });

      for (final size in [const Size(600, 960), const Size(800, 360)]) {
        testWidgets('says "Toque" on ${size.width.toInt()} wide', (t) async {
          final d = await newDriver();
          await pumpWithDriver(t, d, const BindingsPage(), size: size);
          await t.pumpAndSettle();
          expect(find.textContaining('Toque em Adicionar'), findsOneWidget);
          expect(find.textContaining('Clique em Adicionar'), findsNothing);
        });
      }

      testWidgets('says "Clique" on a desktop window', (t) async {
        final d = await newDriver();
        await pumpWithDriver(
          t,
          d,
          const BindingsPage(),
          size: const Size(1180, 760),
        );
        await t.pumpAndSettle();
        expect(
          find.text(
            'Clique em Adicionar e aperte um botão do controle, mova o '
            'analógico ou aperte uma tecla.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Toque em Adicionar'), findsNothing);
      });

      testWidgets('is in the language of the app', (t) async {
        final d = await newDriver();
        await _pump(t, d, locale: 'en');
        await t.pumpAndSettle();
        expect(
          find.text(
            'Tap Add, then press a controller button, move a stick or press '
            'a key.',
          ),
          findsOneWidget,
        );
      });
    });

    group('tags', () {
      testWidgets('show the inputs of every action with the glyphs of the '
          'cells', (t) async {
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        // Forward: R2, ↑, W.
        expect(_tag(CarAction.forward, 'R2'), findsOneWidget);
        expect(_tag(CarAction.forward, '↑'), findsOneWidget);
        expect(_tag(CarAction.forward, 'W'), findsOneWidget);
        // Reverse: L2, ↓, S.
        expect(_tag(CarAction.reverse, 'L2'), findsOneWidget);
        expect(_tag(CarAction.reverse, '↓'), findsOneWidget);
        expect(_tag(CarAction.reverse, 'S'), findsOneWidget);
        // Light: the bottom button is ✕, then L. Turbo: ○. Spin: △.
        expect(_tag(CarAction.light, '✕'), findsOneWidget);
        expect(_tag(CarAction.light, 'L'), findsOneWidget);
        expect(_tag(CarAction.turbo, '○'), findsOneWidget);
        expect(_tag(CarAction.donut, '△'), findsOneWidget);
        // A stick direction is the letter of the stick and an arrow.
        expect(_tag(CarAction.left, 'L ←'), findsOneWidget);
        expect(_tag(CarAction.right, 'L →'), findsOneWidget);
      });

      testWidgets('the space bar is "Espaço" and not "Space"', (t) async {
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        expect(_tag(CarAction.turbo, 'Espaço'), findsOneWidget);
        expect(find.text('Space'), findsNothing);
      });

      testWidgets('the icon says controller or keyboard', (t) async {
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        expect(
          find.descendant(
            of: _tag(CarAction.forward, 'R2'),
            matching: find.byIcon(Icons.sports_esports_outlined),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: _tag(CarAction.forward, 'W'),
            matching: find.byIcon(Icons.keyboard_outlined),
          ),
          findsOneWidget,
        );
      });

      testWidgets('a signal the app does not know is written the way the '
          'cells write it', (t) async {
        final d = await newDriver();
        d.addBinding(CarAction.light, InputRef.raw('KEYCODE_FOO', -1));
        await _pump(t, d);
        await t.pumpAndSettle();
        expect(_tag(CarAction.light, 'Bruto: KEYCODE_FOO −'), findsOneWidget);
      });

      testWidgets('no input shows only "+ Adicionar"', (t) async {
        final d = await newDriver();
        for (final r in List.of(d.bindings[CarAction.donut]!)) {
          d.removeBinding(CarAction.donut, r);
        }
        await _pump(t, d);
        await t.pumpAndSettle();
        expect(
          find.descendant(
            of: _block(CarAction.donut),
            matching: find.byType(InputTag),
          ),
          findsNothing,
        );
        expect(_add(CarAction.donut), findsOneWidget);
      });

      testWidgets('an input on two actions has the amber dot on both', (
        t,
      ) async {
        final d = await newDriver();
        d.addBinding(CarAction.donut, InputRef.pad(PadInput.b));
        await _pump(t, d);
        await t.pumpAndSettle();
        expect(t.widget<InputTag>(_tag(CarAction.turbo, '○')).shared, isTrue);
        expect(t.widget<InputTag>(_tag(CarAction.donut, '○')).shared, isTrue);
        expect(
          t.widget<InputTag>(_tag(CarAction.turbo, 'Espaço')).shared,
          isFalse,
        );
        expect(t.widget<InputTag>(_tag(CarAction.donut, '△')).shared, isFalse);
      });

      testWidgets('follow the driver when an input is added from outside', (
        t,
      ) async {
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        expect(_tag(CarAction.light, 'F5'), findsNothing);
        d.addBinding(CarAction.light, InputRef.key(PhysicalKeyboardKey.f5));
        await t.pumpAndSettle();
        expect(_tag(CarAction.light, 'F5'), findsOneWidget);
      });
    });

    group('removing', () {
      testWidgets('the "×" of "W" takes it out of Frente', (t) async {
        final d = await newDriver();
        final w = InputRef.key(PhysicalKeyboardKey.keyW);
        expect(d.bindings[CarAction.forward], contains(w));
        await _pump(t, d);
        await t.pumpAndSettle();
        await t.tap(_remove(CarAction.forward, 'W'));
        await t.pumpAndSettle();
        expect(d.bindings[CarAction.forward], isNot(contains(w)));
        expect(_tag(CarAction.forward, 'W'), findsNothing);
        // The others stay.
        expect(_tag(CarAction.forward, 'R2'), findsOneWidget);
        expect(_tag(CarAction.forward, '↑'), findsOneWidget);
        expect(d.bindings[CarAction.reverse], isNotEmpty);
      });

      testWidgets('only that action loses the input', (t) async {
        final d = await newDriver();
        final b = InputRef.pad(PadInput.b);
        d.addBinding(CarAction.donut, b);
        await _pump(t, d);
        await t.pumpAndSettle();
        await t.tap(_remove(CarAction.donut, '○'));
        await t.pumpAndSettle();
        expect(d.bindings[CarAction.donut], isNot(contains(b)));
        expect(d.bindings[CarAction.turbo], contains(b));
        // It is no longer shared.
        expect(t.widget<InputTag>(_tag(CarAction.turbo, '○')).shared, isFalse);
      });
    });

    group('capturing', () {
      testWidgets('"+ Adicionar" of Turbo asks for an input and offers '
          '"Cancelar"', (t) async {
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        expect(find.text('Aperte o que vai acionar Turbo'), findsNothing);
        expect(find.text('Cancelar'), findsNothing);
        await t.tap(_add(CarAction.turbo));
        await t.pumpAndSettle();
        expect(d.capturing, CarAction.turbo);
        expect(find.text('Aperte o que vai acionar Turbo'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
        expect(_in(CarAction.turbo, 'Cancelar'), findsOneWidget);
      });

      testWidgets('"Cancelar" clears the capture', (t) async {
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        await t.tap(_add(CarAction.turbo));
        await t.pumpAndSettle();
        await t.tap(find.text('Cancelar'));
        await t.pumpAndSettle();
        expect(d.capturing, isNull);
        expect(find.text('Aperte o que vai acionar Turbo'), findsNothing);
        expect(find.text('Cancelar'), findsNothing);
        expect(_add(CarAction.turbo), findsOneWidget);
      });

      testWidgets('only the action being captured changes', (t) async {
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        await t.tap(_add(CarAction.light));
        await t.pumpAndSettle();
        expect(find.text('Aperte o que vai acionar Luz'), findsOneWidget);
        expect(find.text('+ Adicionar'), findsNWidgets(6));
        expect(_add(CarAction.light), findsNothing);
        for (final a in CarAction.values.where((a) => a != CarAction.light)) {
          expect(_add(a), findsOneWidget, reason: a.name);
        }
        // Its tags stay while it waits.
        expect(_tag(CarAction.light, '✕'), findsOneWidget);
      });

      testWidgets('asking for another action moves the capture', (t) async {
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        await t.tap(_add(CarAction.turbo));
        await t.pumpAndSettle();
        await t.tap(_add(CarAction.donut));
        await t.pumpAndSettle();
        expect(d.capturing, CarAction.donut);
        expect(find.text('Aperte o que vai acionar Turbo'), findsNothing);
        expect(find.text('Aperte o que vai acionar Giro 360°'), findsOneWidget);
        expect(find.text('Cancelar'), findsOneWidget);
      });

      testWidgets('ends by itself when the driver learns the input', (t) async {
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        await t.tap(_add(CarAction.turbo));
        await t.pumpAndSettle();
        // What the driver does when a key arrives while it waits.
        d.addBinding(CarAction.turbo, InputRef.key(PhysicalKeyboardKey.keyT));
        d.cancelCapture();
        await t.pumpAndSettle();
        expect(_tag(CarAction.turbo, 'T'), findsOneWidget);
        expect(find.text('Cancelar'), findsNothing);
        expect(_add(CarAction.turbo), findsOneWidget);
      });

      testWidgets('ends when the page is taken off the screen', (t) async {
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        await t.tap(_add(CarAction.forward));
        await t.pumpAndSettle();
        expect(d.capturing, CarAction.forward);

        // Not popped: the host (the panel of the desktop) just goes away.
        await t.pumpWidget(const SizedBox());
        await t.pump();
        expect(d.capturing, isNull);
      });

      testWidgets('is in the language of the app', (t) async {
        final d = await newDriver();
        await _pump(t, d, locale: 'en');
        await t.pumpAndSettle();
        await t.tap(_in(CarAction.turbo, '+ Add'));
        await t.pumpAndSettle();
        expect(find.text('Press whatever should trigger Turbo'), findsOne);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('is announced to a screen reader', (t) async {
        final handle = t.ensureSemantics();
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        await t.tap(_add(CarAction.turbo));
        await t.pumpAndSettle();
        expect(
          t.getSemantics(find.text('Aperte o que vai acionar Turbo')),
          isSemantics(
            label: 'Aperte o que vai acionar Turbo',
            isLiveRegion: true,
          ),
        );
        handle.dispose();
      });

      testWidgets('the dot pulses, and stands still with "reduce motion"', (
        t,
      ) async {
        // Motion on: a frame is always scheduled while the dot pulses.
        final d = await newDriver();
        await pumpWithDriver(
          t,
          d,
          const EffectsScope(particles: true, child: BindingsPage()),
        );
        await t.pumpAndSettle();
        expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
        d.beginCapture(CarAction.turbo);
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
        d.cancelCapture();
        await t.pumpAndSettle();

        // Reduce motion: the page settles with the dot lit.
        await pumpWithDriver(
          t,
          d,
          const EffectsScope(particles: true, child: BindingsPage()),
          reduceMotion: true,
        );
        d.beginCapture(CarAction.turbo);
        await t.pumpAndSettle();
        expect(find.text('Aperte o que vai acionar Turbo'), findsOneWidget);
      });
    });

    group('footer', () {
      testWidgets('"Usar o teclado" follows the driver and turns it', (
        t,
      ) async {
        final d = await newDriver(prefs: {'keyboard': true});
        await _pump(t, d);
        await t.pumpAndSettle();
        final sw = find.byType(AmberSwitch);
        expect(sw, findsOneWidget);
        expect(t.widget<AmberSwitch>(sw).value, isTrue);
        await t.tap(sw);
        await t.pumpAndSettle();
        expect(d.keyboardEnabled, isFalse);
        expect(t.widget<AmberSwitch>(sw).value, isFalse);
        await t.tap(sw);
        await t.pumpAndSettle();
        expect(d.keyboardEnabled, isTrue);
      });

      testWidgets('the switch is named by "Usar o teclado"', (t) async {
        final handle = t.ensureSemantics();
        final d = await newDriver(prefs: {'keyboard': true});
        await _pump(t, d);
        await t.pumpAndSettle();
        final node = t.getSemantics(find.byType(AmberSwitch));
        expect(node.label, 'Usar o teclado');
        expect(node, isSemantics(hasToggledState: true, isToggled: true));
        handle.dispose();
      });

      testWidgets('"Restaurar padrão" puts the factory inputs back', (t) async {
        final d = await newDriver();
        d.removeBinding(
          CarAction.forward,
          InputRef.key(PhysicalKeyboardKey.keyW),
        );
        d.addBinding(CarAction.light, InputRef.key(PhysicalKeyboardKey.f5));
        await _pump(t, d);
        await t.pumpAndSettle();
        expect(_tag(CarAction.forward, 'W'), findsNothing);
        await t.tap(find.text('Restaurar padrão'));
        await t.pumpAndSettle();
        final defaults = defaultBindings();
        for (final a in CarAction.values) {
          expect(d.bindings[a], defaults[a], reason: a.name);
        }
        expect(_tag(CarAction.forward, 'W'), findsOneWidget);
        expect(_tag(CarAction.light, 'F5'), findsNothing);
      });

      testWidgets('stays in place while the actions scroll', (t) async {
        final d = await newDriver();
        await pumpWithDriver(
          t,
          d,
          const BindingsPage(),
          size: const Size(360, 480),
        );
        await t.pumpAndSettle();
        final before = t.getTopLeft(find.text('Restaurar padrão'));
        final first = t.getTopLeft(find.text('Frente'));
        await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await t.pumpAndSettle();
        expect(
          t.getTopLeft(find.text('Frente')).dy,
          lessThan(first.dy),
          reason: 'the list moved',
        );
        expect(t.getTopLeft(find.text('Restaurar padrão')), before);
        expect(find.text('Usar o teclado'), findsOneWidget);
        // The footer is under the list, never over it: scrolled to the end,
        // the last action stops at the top of the footer.
        await t.drag(find.byType(Scrollable).first, const Offset(0, -3000));
        await t.pumpAndSettle();
        final footer = find.ancestor(
          of: find.text('Usar o teclado'),
          matching: find.byType(Glass),
        );
        expect(
          t.getRect(_block(CarAction.donut)).bottom,
          lessThanOrEqualTo(t.getRect(footer.first).top),
        );
        expect(t.getTopLeft(find.text('Restaurar padrão')), before);
      });

      testWidgets('is below the last action when everything fits', (t) async {
        final d = await newDriver();
        await pumpWithDriver(
          t,
          d,
          const BindingsPage(),
          size: const Size(390, 1400),
        );
        await t.pumpAndSettle();
        final footer = t.getTopLeft(find.text('Usar o teclado')).dy;
        expect(footer, greaterThan(t.getRect(_block(CarAction.donut)).bottom));
      });
    });

    group('touch targets', () {
      testWidgets('tags, their "×", "+ Adicionar" and "Cancelar" are 48 or '
          'more', (t) async {
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        await t.tap(_add(CarAction.turbo));
        await t.pumpAndSettle();
        for (final tag in t.widgetList(find.byType(InputTag))) {
          expect(
            t.getSize(find.byWidget(tag)).height,
            greaterThanOrEqualTo(48),
          );
        }
        for (final x in t.widgetList(find.byType(IconButton))) {
          final size = t.getSize(find.byWidget(x));
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
        for (final text in ['+ Adicionar', 'Cancelar', 'Restaurar padrão']) {
          for (final e in t.elementList(find.text(text))) {
            final target = find.ancestor(
              of: find.byWidget(e.widget),
              matching: find.byWidgetPredicate(
                (w) => w is InkResponse || w is ButtonStyleButton,
              ),
            );
            expect(target, findsWidgets, reason: text);
            final size = t.getSize(target.first);
            expect(size.width, greaterThanOrEqualTo(48), reason: text);
            expect(size.height, greaterThanOrEqualTo(48), reason: text);
          }
        }
        final sw = t.getSize(find.byType(AmberSwitch));
        expect(sw.width, greaterThanOrEqualTo(48));
        expect(sw.height, greaterThanOrEqualTo(48));
      });

      testWidgets('"+ Adicionar" tells a screen reader which action it is '
          'for', (t) async {
        final handle = t.ensureSemantics();
        final d = await newDriver();
        await _pump(t, d);
        await t.pumpAndSettle();
        final node = t.getSemantics(_add(CarAction.turbo));
        expect(node.label, contains('Adicionar'));
        expect(node.label, contains('Turbo'));
        expect(node, isSemantics(isButton: true));
        handle.dispose();
      });
    });

    group('fits', () {
      for (final locale in ['pt', 'en', 'es']) {
        for (final width in [320.0, 360.0, 390.0]) {
          // Regression of the old Buttons page: long labels overflowed on a
          // phone because the title took a fixed column.
          testWidgets('${width.toInt()} wide in $locale', (t) async {
            final d = await newDriver();
            await pumpWithDriver(
              t,
              d,
              const BindingsPage(),
              size: Size(width, 900),
              locale: locale,
            );
            await t.pumpAndSettle();
            expect(
              t.takeException(),
              isNull,
              reason: 'no overflow at $width ($locale)',
            );
          });

          testWidgets('${width.toInt()} wide in $locale, waiting for an '
              'input, at 1.5 times the text', (t) async {
            final d = await newDriver();
            // Every action with as many tags as it can have.
            d.addBinding(
              CarAction.forward,
              InputRef.raw('KEYCODE_BUTTON_L1', 1),
            );
            d.addBinding(CarAction.left, InputRef.pad(PadInput.rightStickLeft));
            d.addBinding(CarAction.donut, InputRef.pad(PadInput.touchpad));
            d.addBinding(
              CarAction.donut,
              InputRef.key(PhysicalKeyboardKey.numpadEnter),
            );
            await pumpWithDriver(
              t,
              d,
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: const BindingsPage(),
                ),
              ),
              size: Size(width, 900),
              locale: locale,
            );
            d.beginCapture(CarAction.donut);
            await t.pumpAndSettle();
            expect(
              t.takeException(),
              isNull,
              reason: 'no overflow at $width ($locale)',
            );
          });
        }
      }
    });

    testWidgets('has a back button when pushed, and none when not', (t) async {
      final d = await newDriver();
      await _pump(t, d);
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_left), findsNothing);

      await pumpWithDriver(
        t,
        d,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Material(child: BindingsPage()),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.text('Botões e teclas'), findsOneWidget);
      await t.tap(find.byIcon(Icons.chevron_left));
      await t.pumpAndSettle();
      expect(find.text('Botões e teclas'), findsNothing);
    });
  });
}
