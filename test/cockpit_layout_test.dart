import 'dart:async';
import 'dart:io';

import 'package:ble_rc_controller/core/car_transport.dart';
import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/core/protocol.dart';
import 'package:ble_rc_controller/l10n/gen/app_localizations.dart';
import 'package:ble_rc_controller/ui/cockpit/car_decal.dart';
import 'package:ble_rc_controller/ui/cockpit/cockpit.dart';
import 'package:ble_rc_controller/ui/cockpit/cockpit_header.dart';
import 'package:ble_rc_controller/ui/cockpit/instrument.dart';
import 'package:ble_rc_controller/ui/cockpit/key_legend.dart';
import 'package:ble_rc_controller/ui/cockpit/particles.dart';
import 'package:ble_rc_controller/ui/cockpit/state_cells.dart';
import 'package:ble_rc_controller/ui/cockpit/steering_gauge.dart';
import 'package:ble_rc_controller/ui/cockpit/throttle_scale.dart';
import 'package:ble_rc_controller/ui/cockpit/touch_pads.dart';
import 'package:ble_rc_controller/ui/common/ambient.dart';
import 'package:ble_rc_controller/ui/common/metal_text.dart';
import 'package:ble_rc_controller/ui/common/ring_spinner.dart';
import 'package:ble_rc_controller/ui/garage/car_list.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_transport.dart';
import 'support/harness.dart';

const _sf25 = FoundCar(id: 'car1', name: 'SL-SF-25', rssi: -55);
const _longName = FoundCar(
  id: 'car1',
  name: 'SL-SUPER-LONG-NAME-296-GT3-EVO',
  rssi: -55,
);

/// The sizes of spec 6, from the smallest phone to the desktop window.
const _sizes = [
  Size(320, 568),
  Size(360, 780),
  Size(390, 844),
  Size(430, 932),
  Size(600, 960),
  Size(800, 360),
  Size(1180, 760),
];

const _locales = ['pt', 'en', 'es'];

/// Prefs of a desktop window with the arrows off. flutter_test reports
/// Android, where the on-screen controls default to on.
const _noArrows = <String, Object>{'onScreen': false};

/// Teaches the test font the real Saira, so the heights the layout works with
/// are the ones the app has (without it every glyph is a square of Ahem, and a
/// line is far shorter than Saira's).
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

/// Builds a driver, scans [cars] and, with [connect], connects to the first.
/// The timers are the test's fake ones.
Future<_Rig> _rig(
  WidgetTester t, {
  FakeTransport? transport,
  Map<String, Object> prefs = const {},
  List<FoundCar> cars = const [_sf25],
  bool connect = true,
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
  );
  await driver.start();
  for (final car in cars) {
    fake.scan.add(car);
  }
  await t.pump(const Duration(milliseconds: 70));
  if (connect) {
    await driver.connect(cars.first.id);
    await t.pump();
    expect(driver.link, LinkState.connected);
  }
  return _Rig(driver, fake);
}

/// A widget test with a [_Rig] that is taken down, widgets first, at the end.
void _cockpitTest(
  String name,
  Future<void> Function(WidgetTester t, _Rig rig) body, {
  FakeTransport Function()? transport,
  Map<String, Object> prefs = const {},
  List<FoundCar> cars = const [_sf25],
  bool connect = true,
}) {
  testWidgets(name, (t) async {
    final rig = await _rig(
      t,
      transport: transport?.call(),
      prefs: prefs,
      cars: cars,
      connect: connect,
    );
    try {
      await body(t, rig);
    } finally {
      await t.pumpWidget(const SizedBox());
      rig.driver.dispose();
    }
  });
}

Future<void> _mount(
  WidgetTester t,
  _Rig rig, {
  Size size = const Size(390, 844),
  String locale = 'pt',
  bool reduceMotion = false,
  VoidCallback? onSettings,
  VoidCallback? onCarTap,
}) => pumpWithDriver(
  t,
  rig.driver,
  Cockpit(onSettings: onSettings ?? () {}, onCarTap: onCarTap),
  size: size,
  locale: locale,
  reduceMotion: reduceMotion,
);

Future<AppLocalizations> _l10n(String code) =>
    AppLocalizations.delegate.load(Locale(code));

final _up = find.byIcon(Icons.arrow_upward_rounded);

/// The square the instrument is drawn in: the first `FittedBox` under it.
Finder _frame() => find
    .descendant(of: find.byType(Instrument), matching: find.byType(FittedBox))
    .first;

/// Holds [a] on and lets the driver's 20 ms tick pick it up.
Future<void> _hold(WidgetTester t, _Rig rig, CarAction a) async {
  rig.driver.setVirtual(a, true);
  await t.pump(const Duration(milliseconds: 40));
}

/// The colour of every piece of text under [root].
Iterable<Color?> _textColors(WidgetTester t, Finder root) => t
    .widgetList<RichText>(
      find.descendant(of: root, matching: find.byType(RichText)),
    )
    .map((r) => (r.text as TextSpan).style?.color);

void main() {
  setUpAll(_loadSaira);

  group('Cockpit, connected', () {
    // 7 sizes x 3 languages x reduce motion on and off.
    for (final size in _sizes) {
      for (final code in _locales) {
        for (final reduce in [false, true]) {
          final desktop = layoutFor(size) == LayoutKind.desktop;
          _cockpitTest(
            '${size.width.toInt()}x${size.height.toInt()} in $code with '
            'reduce motion ${reduce ? 'on' : 'off'}',
            (t, rig) async {
              final l = await _l10n(code);
              await _mount(
                t,
                rig,
                size: size,
                locale: code,
                reduceMotion: reduce,
              );
              await t.pumpAndSettle();

              expect(t.takeException(), isNull);
              // The state is on the screen, whatever the motion.
              expect(find.text('SF-25'), findsOneWidget);
              expect(find.text(l.connectedLabel), findsOneWidget);
              expect(find.byType(StateCells), findsOneWidget);
              expect(find.byType(Instrument), findsOneWidget);

              if (desktop) {
                // Arrows off: the keys take their place, and no arrow is
                // drawn.
                expect(_up, findsNothing);
                expect(find.byType(TouchPads), findsNothing);
                expect(find.text(l.keySpace), findsOneWidget);
              } else {
                final r = t.getRect(_up);
                expect(r.left, greaterThanOrEqualTo(0));
                expect(r.right, lessThanOrEqualTo(size.width));
                expect(r.bottom, lessThanOrEqualTo(size.height));
                expect(find.byType(KeyLegend), findsNothing);
              }
            },
            prefs: desktop ? _noArrows : const {},
          );
        }
      }
    }

    for (final code in _locales) {
      _cockpitTest(
        'a desktop window with the arrows on puts them above the key legend '
        '($code)',
        (t, rig) async {
          final l = await _l10n(code);
          await _mount(t, rig, size: const Size(1180, 760), locale: code);
          await t.pumpAndSettle();

          expect(t.takeException(), isNull);
          final window = const Size(1180, 760);
          final up = t.getRect(_up);
          expect(up.right, lessThanOrEqualTo(window.width));
          expect(up.bottom, lessThanOrEqualTo(window.height));
          expect(find.text(l.keySpace), findsOneWidget);
          expect(
            t.getRect(find.byType(TouchPads)).bottom,
            lessThanOrEqualTo(t.getRect(find.byType(KeyLegend)).top),
            reason: 'the arrows are above the legend',
          );
          expect(
            t.getRect(find.byType(KeyLegend)).bottom,
            lessThanOrEqualTo(window.height),
          );
        },
        prefs: const {'onScreen': true},
      );
    }

    _cockpitTest('a very long car name is cut, not overflowing', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: const Size(320, 568), locale: 'es');
      await t.pumpAndSettle();

      expect(t.takeException(), isNull);
      final name = find.text('SUPER-LONG-NAME-296-GT3-EVO');
      expect(name, findsOneWidget);
      expect(t.getRect(name).right, lessThanOrEqualTo(320));
      expect(t.getRect(_up).right, lessThanOrEqualTo(320));
    }, cars: const [_longName]);

    _cockpitTest('the instrument is at least 200 on the smallest phone', (
      t,
      rig,
    ) async {
      for (final code in _locales) {
        await _mount(t, rig, size: const Size(320, 568), locale: code);
        await t.pumpAndSettle();
        final side = t.getSize(_frame());
        expect(side.width, side.height, reason: 'square');
        expect(side.width, greaterThanOrEqualTo(200), reason: code);
      }
    });

    _cockpitTest('the instrument shrinks and the controls keep their size', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: const Size(360, 780));
      await t.pumpAndSettle();
      final tall = (
        t.getSize(_frame()).width,
        t.getSize(find.byType(StateCells)),
        t.getSize(find.byType(TouchPads)),
      );
      await _mount(t, rig, size: const Size(360, 600));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(t.getSize(_frame()).width, lessThan(tall.$1));
      expect(t.getSize(find.byType(StateCells)), tall.$2);
      expect(t.getSize(find.byType(TouchPads)), tall.$3);
    });
  });

  group('Cockpit, by layout', () {
    // The StateCells and the row of arrows of each layout: how many columns,
    // whether the cells are buttons, and how wide the arrows are.
    final cases = <(String, Size, Map<String, Object>, int, bool)>[
      ('phone', const Size(390, 844), const {}, 2, true),
      ('tablet', const Size(600, 960), const {}, 4, true),
      ('landscape', const Size(800, 360), const {}, 2, true),
      (
        'desktop with the arrows off',
        const Size(1180, 760),
        _noArrows,
        4,
        false,
      ),
      (
        'desktop with the arrows on',
        const Size(1180, 760),
        {'onScreen': true},
        4,
        true,
      ),
    ];
    for (final (name, size, prefs, columns, tappable) in cases) {
      _cockpitTest('$name: $columns columns, '
          '${tappable ? 'tappable' : 'not tappable'} cells', (t, rig) async {
        await _mount(t, rig, size: size);
        await t.pumpAndSettle();
        final cells = t.widget<StateCells>(find.byType(StateCells));
        expect(cells.columns, columns);
        expect(cells.tappable, tappable);
      }, prefs: prefs);
    }

    _cockpitTest('phone: the arrows fill the width of the cells', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: const Size(390, 844));
      await t.pumpAndSettle();
      expect(t.getSize(find.byType(TouchPads)).width, 390 - 36);
      expect(
        t.getSize(find.byType(TouchPads)).width,
        t.getSize(find.byType(StateCells)).width,
      );
      expect(t.getSize(find.byType(TouchPads)).height, 54);
    });

    _cockpitTest('tablet: the arrows are 480 wide at most, centred', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: const Size(600, 960));
      await t.pumpAndSettle();
      final pads = t.getRect(find.byType(TouchPads));
      expect(pads.width, 480);
      expect(pads.center.dx, 300);
      final cells = t.getRect(find.byType(StateCells));
      expect(cells.width, greaterThan(480), reason: 'the cells are wider');
    });

    _cockpitTest('desktop: the arrows are 480 wide at most, centred', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: const Size(1180, 760));
      await t.pumpAndSettle();
      final pads = t.getRect(find.byType(TouchPads));
      expect(pads.width, 480);
      // The axis of the cells above them: the window less 36 and 28.
      expect(pads.center.dx, closeTo((36 + 1180 - 28) / 2, 0.5));
      expect(
        t.getRect(_frame()).center.dx,
        closeTo(pads.center.dx, 0.5),
        reason: 'the instrument is on the same axis',
      );
    }, prefs: const {'onScreen': true});

    _cockpitTest('landscape: the instrument is on the left, the cells and '
        'arrows on the right', (t, rig) async {
      await _mount(t, rig, size: const Size(800, 360));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final instrument = t.getRect(_frame());
      final cells = t.getRect(find.byType(StateCells));
      final pads = t.getRect(find.byType(TouchPads));
      expect(instrument.right, lessThanOrEqualTo(cells.left));
      expect(pads.left, cells.left);
      expect(pads.width, cells.width);
      expect(pads.top, greaterThan(cells.bottom));
      // The header runs over both columns.
      expect(
        t.getRect(find.text('SF-25')).bottom,
        lessThanOrEqualTo(instrument.top + 1),
      );
    });

    _cockpitTest('landscape with very large text scrolls the right column', (
      t,
      rig,
    ) async {
      await pumpWithDriver(
        t,
        rig.driver,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: Cockpit(onSettings: () {}),
          ),
        ),
        size: const Size(800, 360),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      // Both the cells and the arrows are still in the tree to be scrolled to.
      expect(find.byType(StateCells), findsOneWidget);
      expect(find.byType(TouchPads), findsOneWidget);
    });

    _cockpitTest('a turn of the phone moves the instrument without a trace', (
      t,
      rig,
    ) async {
      for (final size in const [
        Size(390, 844),
        Size(844, 390),
        Size(1180, 760),
        Size(390, 844),
      ]) {
        await _mount(t, rig, size: size);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: '$size');
        final field = t.widget<ParticleField>(find.byType(ParticleField));
        expect(field.hero(), t.getRect(_frame()), reason: '$size');
        expect(find.byType(Instrument), findsOneWidget);
      }
    });

    _cockpitTest('the legend is gone with the keyboard off', (t, rig) async {
      rig.driver.keyboardEnabled = false;
      await _mount(t, rig, size: const Size(1180, 760));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byType(KeyLegend), findsNothing);
      expect(find.byType(TouchPads), findsNothing);
      expect(find.byType(StateCells), findsOneWidget);
      // With nothing under them the cells sit at the bottom margin.
      expect(t.getRect(find.byType(StateCells)).bottom, 760 - 28);
    }, prefs: _noArrows);
  });

  group('Cockpit, the dust', () {
    _cockpitTest('95 particles on a phone, 150 on a desktop', (t, rig) async {
      await _mount(t, rig, size: const Size(390, 844));
      await t.pumpAndSettle();
      expect(t.widget<ParticleField>(find.byType(ParticleField)).count, 95);
      await _mount(t, rig, size: const Size(600, 960));
      await t.pumpAndSettle();
      expect(t.widget<ParticleField>(find.byType(ParticleField)).count, 95);
      await _mount(t, rig, size: const Size(800, 360));
      await t.pumpAndSettle();
      expect(t.widget<ParticleField>(find.byType(ParticleField)).count, 95);
      await _mount(t, rig, size: const Size(1180, 760));
      await t.pumpAndSettle();
      expect(t.widget<ParticleField>(find.byType(ParticleField)).count, 150);
    });

    _cockpitTest('the field fills the cockpit, between the backdrop and the '
        'content', (t, rig) async {
      await _mount(t, rig);
      await t.pumpAndSettle();
      expect(
        t.getRect(find.byType(ParticleField)),
        t.getRect(find.byType(Cockpit)),
      );
      final stack = t.widget<Stack>(
        find
            .descendant(of: find.byType(Cockpit), matching: find.byType(Stack))
            .first,
      );
      expect(stack.children[0], isA<AmbientBackdrop>());
      expect(stack.children[1], isA<ParticleField>());
      expect(stack.children.length, greaterThan(2));
    });

    for (final size in [
      const Size(390, 844),
      const Size(800, 360),
      const Size(1180, 760),
    ]) {
      _cockpitTest('${size.width.toInt()}x${size.height.toInt()}: the car, the '
          'hero and the beam come from the laid-out instrument', (
        t,
        rig,
      ) async {
        await _mount(t, rig, size: size);
        await t.pumpAndSettle();
        final origin = t.getTopLeft(find.byType(ParticleField));
        final field = t.widget<ParticleField>(find.byType(ParticleField));
        final frame = t.getRect(_frame()).shift(-origin);
        final decal = t.getRect(find.byType(CarDecal)).shift(-origin);

        expect(field.hero(), frame);
        expect(field.carCenter().dx, closeTo(decal.center.dx, 0.01));
        expect(field.carCenter().dy, closeTo(decal.center.dy, 0.01));
        expect(field.beam, isNull, reason: 'lights off: no beam');

        // The lights on: a beam standing on the headlights (10 units from the
        // top of the car's 200), centred on the car, as wide as the drawn beams.
        await _hold(t, rig, CarAction.light);
        await t.pumpAndSettle();
        final lit = t.widget<ParticleField>(find.byType(ParticleField));
        expect(lit.beam, isNotNull);
        final beam = lit.beam!();
        final k = frame.width / 300;
        expect(beam.bottom, closeTo(decal.top + decal.height * 10 / 200, 0.01));
        expect(beam.center.dx, closeTo(decal.center.dx, 0.01));
        expect(beam.width, closeTo(88.8 * k, 0.01));
        expect(beam.height, closeTo(82 * k, 0.01));
        expect(beam.top, greaterThan(frame.top), reason: 'inside the frame');
      });
    }

    _cockpitTest('the geometry follows a new layout', (t, rig) async {
      await _mount(t, rig, size: const Size(390, 844));
      await t.pumpAndSettle();
      final before = t.widget<ParticleField>(find.byType(ParticleField)).hero();
      await _mount(t, rig, size: const Size(360, 640));
      await t.pumpAndSettle();
      final field = t.widget<ParticleField>(find.byType(ParticleField));
      expect(field.hero(), isNot(before));
      expect(field.hero(), t.getRect(_frame()));
    });

    _cockpitTest('the backdrop sweeps only while connected', (t, rig) async {
      await _mount(t, rig);
      await t.pumpAndSettle();
      expect(
        t.widget<AmbientBackdrop>(find.byType(AmbientBackdrop)).sweep,
        isTrue,
      );
    });
  });

  group('Instrument', () {
    _cockpitTest('draws the gauge above the car and the scale to its right', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: const Size(390, 844));
      await t.pumpAndSettle();
      final frame = t.getRect(_frame());
      final k = frame.width / 300;
      final decal = t.getRect(find.byType(CarDecal));
      // The approved placement, in a 300 box: gauge (30, 24) 240x72, scale
      // (226, 86) 92x200, car (110, 106) 80x160.
      expect(decal.left, closeTo(frame.left + 110 * k, 0.01));
      expect(decal.top, closeTo(frame.top + 106 * k, 0.01));
      expect(decal.width, closeTo(80 * k, 0.01));
      expect(decal.height, closeTo(160 * k, 0.01));
      final gauge = t.getRect(find.byType(SteeringGauge));
      expect(
        gauge.topLeft,
        offsetMoreOrLessEquals(
          frame.topLeft + Offset(30, 24) * k,
          epsilon: 0.01,
        ),
      );
      expect(gauge.width, closeTo(240 * k, 0.01));
      final scale = t.getRect(find.byType(ThrottleScale));
      expect(
        scale.topLeft,
        offsetMoreOrLessEquals(
          frame.topLeft + Offset(226, 86) * k,
          epsilon: 0.01,
        ),
      );
      expect(gauge.bottom, lessThan(decal.top + 40 * k));
      expect(scale.left, greaterThan(decal.right));
    });

    _cockpitTest('follows the command: steering, light, turbo and throttle', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await t.pumpAndSettle();
      var decal = t.widget<CarDecal>(find.byType(CarDecal));
      expect(
        (decal.steer, decal.lights, decal.turbo, decal.spinning),
        (0, false, false, false),
      );

      await _hold(t, rig, CarAction.left);
      await _hold(t, rig, CarAction.turbo);
      await _hold(t, rig, CarAction.donut);
      await _hold(t, rig, CarAction.light);
      await t.pumpAndSettle();
      decal = t.widget<CarDecal>(find.byType(CarDecal));
      expect(
        (decal.steer, decal.lights, decal.turbo, decal.spinning),
        (-1, true, true, true),
      );
      expect(t.widget<SteeringGauge>(find.byType(SteeringGauge)).steer, -1);
      expect(
        t.widget<ThrottleScale>(find.byType(ThrottleScale)).command.turbo,
        isTrue,
      );
      await _hold(t, rig, CarAction.right);
      expect(
        t.widget<SteeringGauge>(find.byType(SteeringGauge)).steer,
        0,
        reason: 'left and right cancel out',
      );
    });

    _cockpitTest('the drawings repaint on their own and are not clipped', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await t.pumpAndSettle();
      final boundaries = find.descendant(
        of: find.byType(Instrument),
        matching: find.byType(RepaintBoundary),
      );
      for (final drawing in [
        find.byType(CarDecal),
        find.byType(SteeringGauge),
        find.byType(ThrottleScale),
      ]) {
        expect(
          find.ancestor(of: drawing, matching: boundaries),
          findsAtLeastNWidgets(1),
          reason: '$drawing has its own layer',
        );
      }
      for (final clip in [ClipRect, ClipRRect, ClipPath, ClipOval]) {
        expect(
          find.descendant(
            of: find.byType(Instrument),
            matching: find.byElementPredicate(
              (e) => e.widget.runtimeType == clip,
            ),
          ),
          findsNothing,
          reason: '$clip would cut the beams and the glow',
        );
      }
      expect(t.widget<FittedBox>(_frame()).clipBehavior, Clip.none);
    });

    for (final side in [200.0, 300.0, 440.0]) {
      _cockpitTest('paints nothing outside its ${side.toInt()} square', (
        t,
        rig,
      ) async {
        // Everything on at once: the beams, the halo, the turbo marker, the
        // bar and a turn. The scale's box ends past the square (318 of 300),
        // but what it draws does not.
        for (final a in [
          CarAction.forward,
          CarAction.turbo,
          CarAction.light,
          CarAction.left,
        ]) {
          rig.driver.setVirtual(a, true);
        }
        await t.pump(const Duration(milliseconds: 40));
        const margin = 60.0;
        final key = GlobalKey();
        await pumpWithDriver(
          t,
          rig.driver,
          RepaintBoundary(
            key: key,
            child: Padding(
              padding: const EdgeInsets.all(margin),
              child: SizedBox.square(
                dimension: side,
                child: const Instrument(),
              ),
            ),
          ),
          size: Size(side + 2 * margin, side + 2 * margin),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);

        final image = await t.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final picture = await boundary.toImage();
          final bytes = (await picture.toByteData())!;
          final size = (picture.width, picture.height);
          picture.dispose();
          return (bytes, size);
        });
        final (bytes, (w, h)) = image!;
        var inside = 0, outside = 0;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            if (bytes.getUint8((y * w + x) * 4 + 3) == 0) continue;
            final in_ =
                x >= margin &&
                x < margin + side &&
                y >= margin &&
                y < margin + side;
            in_ ? inside++ : outside++;
          }
        }
        expect(inside, greaterThan(500), reason: 'something is drawn');
        expect(outside, 0, reason: 'nothing paints outside the square');
      });
    }
  });

  group('CockpitHeader', () {
    Future<void> mountHeader(
      WidgetTester t,
      _Rig rig, {
      Size size = const Size(390, 844),
      String locale = 'pt',
      bool reduceMotion = false,
      VoidCallback? onSettings,
      VoidCallback? onCarTap,
    }) => pumpWithDriver(
      t,
      rig.driver,
      CockpitHeader(onSettings: onSettings ?? () {}, onCarTap: onCarTap),
      size: size,
      locale: locale,
      reduceMotion: reduceMotion,
    );

    /// The 5 px dot before the status.
    Finder dot() => find.descendant(
      of: find.byType(CockpitHeader),
      matching: find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
    );
    Color? dotColor(WidgetTester t) =>
        (t.widget<DecoratedBox>(dot()).decoration as BoxDecoration).color;
    final spinner = find.byType(RingSpinner);

    _cockpitTest('connected: the model, a lit dot, the battery and the gear', (
      t,
      rig,
    ) async {
      await mountHeader(t, rig);
      await t.pumpAndSettle();
      expect(find.text('SF-25'), findsOneWidget);
      expect(find.text('Conectado'), findsOneWidget);
      expect(dotColor(t), AppColors.amber);
      expect(spinner, findsNothing);
      expect(find.text('77'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
      expect(find.text('bateria'), findsOneWidget);
      expect(find.byTooltip('Ajustes'), findsOneWidget);
    });

    _cockpitTest('the name and the battery are metal text of the spec sizes', (
      t,
      rig,
    ) async {
      await mountHeader(t, rig);
      await t.pumpAndSettle();
      MetalText metal(String s) =>
          t.widget<MetalText>(find.widgetWithText(MetalText, s));
      expect(metal('SF-25').style.fontSize, 42);
      expect(metal('77').style.fontSize, 36);
      expect(
        metal('SF-25').style.fontVariations,
        AppType.numeric(size: 42).fontVariations,
      );
      expect(metal('SF-25').style.fontFamily, AppType.family);

      await mountHeader(t, rig, size: const Size(1180, 760));
      await t.pumpAndSettle();
      expect(metal('SF-25').style.fontSize, 56);
      expect(metal('77').style.fontSize, 44);
    });

    _cockpitTest('no text is drawn in the trace colour', (t, rig) async {
      await _mount(t, rig);
      await t.pumpAndSettle();
      expect(
        _textColors(t, find.byType(Cockpit)),
        isNot(contains(AppColors.trace)),
      );
    });

    _cockpitTest('searching: no car, a turning ring, no battery', (
      t,
      rig,
    ) async {
      await mountHeader(t, rig);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Nenhum carro'), findsOneWidget);
      expect(find.text('Procurando'), findsOneWidget);
      expect(spinner, findsOneWidget);
      expect(dot(), findsNothing);
      expect(find.text('bateria'), findsNothing);
      final turns = t.widget<RotationTransition>(
        find.descendant(of: spinner, matching: find.byType(RotationTransition)),
      );
      expect((turns.turns as AnimationController).isAnimating, isTrue);
    }, connect: false);

    _cockpitTest('the ring stands still with reduce motion', (t, rig) async {
      await mountHeader(t, rig, reduceMotion: true);
      await t.pumpAndSettle();
      expect(spinner, findsOneWidget);
      final turns = t.widget<RotationTransition>(
        find.descendant(of: spinner, matching: find.byType(RotationTransition)),
      );
      expect((turns.turns as AnimationController).isAnimating, isFalse);
    }, connect: false);

    testWidgets('connecting: the car being reached, a turning ring', (t) async {
      final rig = await _rig(
        t,
        transport: FakeTransport()..connectDelay = const Duration(seconds: 5),
        connect: false,
      );
      try {
        await pumpWithDriver(t, rig.driver, CockpitHeader(onSettings: () {}));
        unawaited(rig.driver.connect('car1'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(rig.driver.link, LinkState.connecting);
        expect(find.text('SF-25'), findsOneWidget);
        expect(find.text('Conectando'), findsOneWidget);
        expect(spinner, findsOneWidget);
        expect(find.text('bateria'), findsNothing);
        await t.pump(const Duration(seconds: 6));
      } finally {
        await t.pumpWidget(const SizedBox());
        rig.driver.dispose();
      }
    });

    _cockpitTest('reconnecting: the lost car, a turning ring, no battery', (
      t,
      rig,
    ) async {
      await mountHeader(t, rig);
      rig.transport.conn.add(false);
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(rig.driver.reconnecting, isTrue);
      expect(find.text('SF-25'), findsOneWidget);
      expect(find.text('Reconectando'), findsOneWidget);
      expect(spinner, findsOneWidget);
      expect(find.text('bateria'), findsNothing);
    });

    testWidgets('Bluetooth off: no car, an unlit dot, nothing turning', (
      t,
    ) async {
      final rig = await _rig(
        t,
        transport: FakeTransport()..state = BluetoothState.off,
        cars: const [_sf25],
        connect: false,
      );
      try {
        await pumpWithDriver(t, rig.driver, CockpitHeader(onSettings: () {}));
        await t.pumpAndSettle();
        expect(rig.driver.bluetooth, BluetoothState.off);
        expect(find.text('Nenhum carro'), findsOneWidget);
        expect(find.text('Bluetooth desligado'), findsOneWidget);
        expect(spinner, findsNothing);
        expect(dotColor(t), isNot(AppColors.amber));
        expect(dotColor(t), AppColors.trace);
      } finally {
        await t.pumpWidget(const SizedBox());
        rig.driver.dispose();
      }
    });

    for (final (code, none, searching, connected) in [
      ('pt', 'Nenhum carro', 'Procurando', 'Conectado'),
      ('en', 'No car', 'Searching', 'Connected'),
      ('es', 'Ningún coche', 'Buscando', 'Conectado'),
    ]) {
      _cockpitTest('speaks $code', (t, rig) async {
        await mountHeader(t, rig, locale: code);
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text(none), findsOneWidget);
        expect(find.text(searching), findsOneWidget);
        await rig.driver.connect('car1');
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        expect(find.text(connected), findsOneWidget);
      }, connect: false);
    }

    _cockpitTest('the name is a button only with onCarTap', (t, rig) async {
      var taps = 0;
      await mountHeader(t, rig);
      await t.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(CockpitHeader),
          matching: find.byType(InkWell),
        ),
        findsOneWidget,
        reason: 'the gear only',
      );
      await t.tap(find.text('SF-25'));
      await t.pump();
      expect(taps, 0);

      await mountHeader(t, rig, onCarTap: () => taps++);
      await t.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(CockpitHeader),
          matching: find.byType(InkWell),
        ),
        findsNWidgets(2),
      );
      await t.tap(find.text('SF-25'));
      await t.pump();
      expect(taps, 1);
      await t.tap(find.text('Conectado'));
      await t.pump();
      expect(taps, 2, reason: 'the status is part of the target');
      final target = t.getSize(
        find
            .ancestor(of: find.text('SF-25'), matching: find.byType(InkWell))
            .first,
      );
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));
    });

    _cockpitTest('the name and the status are one button for a screen reader', (
      t,
      rig,
    ) async {
      final handle = t.ensureSemantics();
      await mountHeader(t, rig, onCarTap: () {});
      await t.pumpAndSettle();
      expect(
        t.getSemantics(find.text('SF-25')),
        isSemantics(
          label: 'SF-25\nConectado',
          isButton: true,
          hasTapAction: true,
        ),
      );
      await mountHeader(t, rig);
      await t.pumpAndSettle();
      expect(
        t.getSemantics(find.text('SF-25')),
        isSemantics(label: 'SF-25\nConectado', isButton: false),
      );
      handle.dispose();
    });

    _cockpitTest('the gear is a 48 target that opens the settings', (
      t,
      rig,
    ) async {
      final handle = t.ensureSemantics();
      var opened = 0;
      await mountHeader(t, rig, onSettings: () => opened++);
      await t.pumpAndSettle();
      final gear = find.byTooltip('Ajustes');
      expect(t.getSize(gear).width, greaterThanOrEqualTo(48));
      expect(t.getSize(gear).height, greaterThanOrEqualTo(48));
      expect(
        t.getSemantics(
          find.descendant(of: gear, matching: find.byType(InkWell)),
        ),
        isSemantics(label: 'Ajustes', isButton: true, hasTapAction: true),
      );
      await t.tap(gear);
      await t.pump();
      expect(opened, 1);
      handle.dispose();
    });

    _cockpitTest('the battery says what it is for a screen reader', (
      t,
      rig,
    ) async {
      final handle = t.ensureSemantics();
      await mountHeader(t, rig);
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('77% bateria'), findsOneWidget);
      handle.dispose();
    });
  });

  group('Cockpit, outside the connected state', () {
    _cockpitTest('a phone shows the header and the list of cars', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull);
      expect(find.byType(CockpitHeader), findsOneWidget);
      expect(find.byType(CarList), findsOneWidget);
      expect(find.text('Conectar'), findsOneWidget);
      expect(find.byType(Instrument), findsNothing);
      expect(find.byType(StateCells), findsNothing);
      expect(find.byType(TouchPads), findsNothing);
      expect(find.byType(ParticleField), findsNothing);
      expect(
        t.widget<AmbientBackdrop>(find.byType(AmbientBackdrop)).sweep,
        isFalse,
      );
    }, connect: false);

    _cockpitTest('a tablet centres the list under the car', (t, rig) async {
      await _mount(t, rig, size: const Size(600, 960));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull);
      expect(find.byType(CarList), findsOneWidget);
      expect(t.getCenter(find.byType(CarList)).dx, closeTo(300, 0.5));
    }, connect: false);

    _cockpitTest('landscape puts the list at the right of the car', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: const Size(800, 360));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull);
      final list = t.getRect(find.byType(CarList));
      expect(list.left, greaterThan(400));
      expect(list.right, lessThanOrEqualTo(800));
      final ghost = find.byWidgetPredicate(
        (w) => w is CarDecal && w.variant == DecalVariant.ghost,
      );
      expect(t.getRect(ghost).right, lessThan(list.left));
    }, connect: false);

    _cockpitTest('a desktop window leaves the list to the garage column', (
      t,
      rig,
    ) async {
      await _mount(t, rig, size: const Size(1180, 760));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull);
      expect(find.byType(CockpitHeader), findsOneWidget);
      expect(find.byType(CarList), findsNothing);
      expect(find.byType(Instrument), findsNothing);
    }, connect: false);

    _cockpitTest(
      'a long list of cars scrolls instead of overflowing',
      (t, rig) async {
        await _mount(t, rig, size: const Size(320, 568));
        await t.pump(const Duration(milliseconds: 300));
        expect(t.takeException(), isNull);
      },
      connect: false,
      cars: [
        for (var i = 0; i < 12; i++)
          FoundCar(id: 'c$i', name: 'SL-Car $i', rssi: -60),
      ],
    );

    _cockpitTest('the same cockpit goes back to the instrument on connecting', (
      t,
      rig,
    ) async {
      await _mount(t, rig);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(Instrument), findsNothing);
      await rig.driver.connect('car1');
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(Instrument), findsOneWidget);
      expect(find.byType(ParticleField), findsOneWidget);
      expect(find.byType(CarList), findsNothing);
      expect(
        t.widget<AmbientBackdrop>(find.byType(AmbientBackdrop)).sweep,
        isTrue,
      );
    }, connect: false);
  });
}
