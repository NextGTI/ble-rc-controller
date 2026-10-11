import 'package:ble_rc_controller/core/protocol.dart';
import 'package:ble_rc_controller/l10n/gen/app_localizations.dart';
import 'package:ble_rc_controller/ui/cockpit/steering_gauge.dart';
import 'package:ble_rc_controller/ui/cockpit/throttle_scale.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The same key on every pump, so a second pump updates the widget in place.
final _boundary = GlobalKey();

/// Mounts [child] at the top left of a window with a pixel ratio of 1, with the
/// l10n delegates and the language [locale], inside a repaint boundary that
/// [_colorAt] reads back.
Future<void> _pump(
  WidgetTester t,
  Widget child, {
  String locale = 'pt',
  bool reduceMotion = false,
}) async {
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: app!,
      ),
      home: Material(
        color: AppColors.bg,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(key: _boundary, child: child),
        ),
      ),
    ),
  );
}

/// The colour of the pixel ([x], [y]) of what [_pump]'s boundary draws, as
/// ARGB. Logical pixels, because the test window has a pixel ratio of 1.
Future<List<int>> _colorAt(WidgetTester t, int x, int y) async {
  final px = await t.runAsync(() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!; // raw RGBA
    final i = (y * image.width + x) * 4;
    final out = [
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    ];
    image.dispose();
    return out;
  });
  return px!;
}

/// Whether the pixel (ARGB) is amber (#FFB547) and opaque enough to be the
/// stroke rather than the tail of its glow: red high, blue low.
bool _isAmber(List<int> argb) =>
    argb[0] > 80 && argb[1] > 200 && argb[3] < 150 && argb[1] - argb[3] > 80;

/// Whether any pixel of the 3 by 3 block around ([x], [y]) is amber.
Future<bool> _amberNear(WidgetTester t, int x, int y) async {
  for (var dy = -1; dy <= 1; dy++) {
    for (var dx = -1; dx <= 1; dx++) {
      if (_isAmber(await _colorAt(t, x + dx, y + dy))) return true;
    }
  }
  return false;
}

SteeringGaugePainter _gaugePainter(WidgetTester t) =>
    t
            .widget<CustomPaint>(
              find.byWidgetPredicate(
                (w) => w is CustomPaint && w.painter is SteeringGaugePainter,
              ),
            )
            .painter!
        as SteeringGaugePainter;

ThrottleScalePainter _scalePainter(WidgetTester t) =>
    t
            .widget<CustomPaint>(
              find.byWidgetPredicate(
                (w) => w is CustomPaint && w.painter is ThrottleScalePainter,
              ),
            )
            .painter!
        as ThrottleScalePainter;

TextStyle _styleOf(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style!;

void main() {
  group('throttleFill', () {
    test('turbo fills the scale', () {
      expect(throttleFill(const CarCommand(turbo: true)), 1.0);
    });

    test('forward fills 72%', () {
      expect(throttleFill(const CarCommand(forward: true)), 0.72);
    });

    test('reverse goes down to 60%', () {
      expect(throttleFill(const CarCommand(reverse: true)), -0.6);
    });

    test('nothing pressed is empty', () {
      expect(throttleFill(const CarCommand()), 0);
    });

    test('steering, light and donut do not move the bar', () {
      expect(
        throttleFill(
          const CarCommand(left: true, right: true, light: true, donut: true),
        ),
        0,
      );
    });

    test('turbo wins over forward, and forward over reverse', () {
      expect(throttleFill(const CarCommand(turbo: true, forward: true)), 1.0);
      expect(throttleFill(const CarCommand(turbo: true, reverse: true)), 1.0);
      expect(
        throttleFill(const CarCommand(forward: true, reverse: true)),
        0.72,
      );
    });
  });

  group('the gauge scale', () {
    test('has 17 marks from -40 to 40, every 5 degrees', () {
      expect(steerTicks, hasLength(17));
      expect(steerTicks.first, -40);
      expect(steerTicks.last, 40);
      for (var i = 1; i < steerTicks.length; i++) {
        expect(steerTicks[i] - steerTicks[i - 1], 5);
      }
    });

    test('marks every 20 degrees are the major ones', () {
      expect(steerTicks.where(isMajorTick), [-40, -20, 0, 20, 40]);
    });

    test('the needle sits at 0 or at 18 degrees to the side of the turn', () {
      expect(needleDegrees(0), 0);
      expect(needleDegrees(1), 18);
      expect(needleDegrees(-1), -18);
    });

    test('marks within 6 degrees of the needle light up when steering', () {
      List<int> lit(int steer) => [
        for (final t in steerTicks)
          if (tickLit(t, needleDegrees(steer), steer)) t,
      ];
      expect(lit(1), [15, 20]);
      expect(lit(-1), [-20, -15]);
      expect(lit(0), isEmpty, reason: 'centred: nothing lights up');
    });

    test('no mark lights up while the car is not steering, wherever the '
        'needle still is', () {
      expect(tickLit(0, 0, 0), isFalse);
      expect(tickLit(5, 4, 0), isFalse);
    });
  });

  group('SteeringGauge', () {
    testWidgets('reads 18° direita to the right, in Portuguese', (t) async {
      await _pump(t, const SteeringGauge(steer: 1));
      expect(find.text('18° direita'), findsOneWidget);
    });

    testWidgets('reads 18° esquerda to the left, in Portuguese', (t) async {
      await _pump(t, const SteeringGauge(steer: -1));
      expect(find.text('18° esquerda'), findsOneWidget);
    });

    testWidgets('reads 0° when centred', (t) async {
      await _pump(t, const SteeringGauge(steer: 0));
      expect(find.text('0°'), findsOneWidget);
      expect(find.textContaining('18'), findsNothing);
    });

    testWidgets('follows the language', (t) async {
      await _pump(t, const SteeringGauge(steer: 1), locale: 'en');
      expect(find.text('18° right'), findsOneWidget);
      expect(find.text('left'), findsOneWidget);
      expect(find.text('right'), findsOneWidget);
      await _pump(t, const SteeringGauge(steer: -1), locale: 'es');
      expect(find.text('18° izquierda'), findsOneWidget);
      expect(find.text('izquierda'), findsOneWidget);
      expect(find.text('derecha'), findsOneWidget);
    });

    testWidgets('names the two ends of the arc', (t) async {
      await _pump(t, const SteeringGauge(steer: 0));
      expect(find.text('esquerda'), findsOneWidget);
      expect(find.text('direita'), findsOneWidget);
    });

    testWidgets('the readout is the main text colour and the end labels the '
        'tertiary one, never the trace grey', (t) async {
      await _pump(t, const SteeringGauge(steer: 1));
      expect(_styleOf(t, '18° direita').color, AppColors.text);
      expect(_styleOf(t, 'esquerda').color, AppColors.text3);
      expect(_styleOf(t, 'direita').color, AppColors.text3);
      expect(_styleOf(t, 'direita').fontSize, 10);
    });

    testWidgets('the text uses the Saira styles', (t) async {
      await _pump(t, const SteeringGauge(steer: 1));
      expect(_styleOf(t, '18° direita').fontFamily, AppType.family);
      expect(_styleOf(t, 'esquerda').fontFamily, AppType.family);
    });

    testWidgets('has the size it declares', (t) async {
      await _pump(t, const SteeringGauge(steer: 0));
      expect(t.getSize(find.byType(SteeringGauge)), SteeringGauge.designSize);
    });

    testWidgets('shrinks to fit a smaller box, keeping its proportions', (
      t,
    ) async {
      await _pump(
        t,
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120, maxHeight: 100),
          child: SteeringGauge(steer: 1),
        ),
      );
      expect(t.takeException(), isNull);
      final size = t.getSize(find.byType(SteeringGauge));
      expect(size.width, 120);
      expect(
        size.width / size.height,
        closeTo(
          SteeringGauge.designSize.width / SteeringGauge.designSize.height,
          0.01,
        ),
      );
    });

    testWidgets('is one node for a screen reader: the readout', (t) async {
      final handle = t.ensureSemantics();
      await _pump(t, const SteeringGauge(steer: -1));
      expect(
        t.getSemantics(find.byType(SteeringGauge)),
        matchesSemantics(label: '18° esquerda'),
      );
      handle.dispose();
    });

    testWidgets('the needle goes past the point and settles at 18 degrees in '
        'the needle time', (t) async {
      await _pump(t, const SteeringGauge(steer: 0));
      expect(_gaugePainter(t).needle, 0);

      await _pump(t, const SteeringGauge(steer: 1));
      expect(_gaugePainter(t).needle, 0, reason: 'starts moving from 0');

      var peak = 0.0;
      const step = Duration(milliseconds: 10);
      for (var ms = 0; ms < AppMotion.needle.inMilliseconds; ms += 10) {
        await t.pump(step);
        peak = peak < _gaugePainter(t).needle ? _gaugePainter(t).needle : peak;
      }
      await t.pump(step);
      expect(peak, greaterThan(18), reason: 'a small overshoot');
      expect(peak, lessThan(18 * 1.15), reason: 'but only a small one');
      expect(_gaugePainter(t).needle, 18);
      expect(t.hasRunningAnimations, isFalse);
    });

    testWidgets('with reduce motion the needle jumps and no frame is left '
        'pending', (t) async {
      await _pump(t, const SteeringGauge(steer: 0), reduceMotion: true);
      await _pump(t, const SteeringGauge(steer: -1), reduceMotion: true);
      await t.pump();
      expect(_gaugePainter(t).needle, -18);
      expect(t.hasRunningAnimations, isFalse);
    });

    testWidgets('the painter lights the marks near the needle', (t) async {
      await _pump(t, const SteeringGauge(steer: 1));
      await t.pumpAndSettle();
      final p = _gaugePainter(t);
      expect(p.steer, 1);
      expect(
        [
          for (final tick in steerTicks)
            if (p.isLit(tick)) tick,
        ],
        [15, 20],
      );
    });

    testWidgets('draws an amber needle at the top at 0°', (t) async {
      await _pump(t, const SteeringGauge(steer: 0));
      // The needle runs from 123 to 105 from the pivot (120, 146): (120, 23)
      // to (120, 41).
      expect(await _amberNear(t, 120, 32), isTrue);
      // Nothing amber where the 18 degree needle would be.
      expect(await _amberNear(t, 155, 38), isFalse);
    });

    testWidgets('draws the needle 18 degrees to the right', (t) async {
      await _pump(t, const SteeringGauge(steer: 1));
      await t.pumpAndSettle();
      // At 114 from the pivot: (120 + 114 sin 18, 146 - 114 cos 18).
      expect(await _amberNear(t, 155, 38), isTrue);
      expect(await _amberNear(t, 120, 32), isFalse);
    });

    testWidgets('draws the needle 18 degrees to the left', (t) async {
      await _pump(t, const SteeringGauge(steer: -1));
      await t.pumpAndSettle();
      expect(await _amberNear(t, 85, 38), isTrue);
      expect(await _amberNear(t, 155, 38), isFalse);
    });
  });

  group('ThrottleScale', () {
    testWidgets('names the two ends: frente and ré', (t) async {
      await _pump(t, const ThrottleScale(command: CarCommand()));
      expect(find.text('frente'), findsOneWidget);
      expect(find.text('ré'), findsOneWidget);
    });

    testWidgets('shows turbo only with turbo', (t) async {
      await _pump(t, const ThrottleScale(command: CarCommand()));
      expect(find.text('turbo'), findsNothing);
      await _pump(t, const ThrottleScale(command: CarCommand(forward: true)));
      expect(find.text('turbo'), findsNothing);
      await _pump(t, const ThrottleScale(command: CarCommand(turbo: true)));
      expect(find.text('turbo'), findsOneWidget);
    });

    testWidgets('turbo is amber, the ends are tertiary text and 10 px', (
      t,
    ) async {
      await _pump(t, const ThrottleScale(command: CarCommand(turbo: true)));
      expect(_styleOf(t, 'turbo').color, AppColors.amber);
      expect(_styleOf(t, 'frente').color, AppColors.text3);
      expect(_styleOf(t, 'ré').color, AppColors.text3);
      expect(_styleOf(t, 'frente').fontSize, 10);
      expect(_styleOf(t, 'frente').fontFamily, AppType.family);
    });

    testWidgets('follows the language', (t) async {
      await _pump(
        t,
        const ThrottleScale(command: CarCommand(turbo: true)),
        locale: 'es',
      );
      expect(find.text('adelante'), findsOneWidget);
      expect(find.text('marcha atrás'), findsOneWidget);
      expect(find.text('turbo'), findsOneWidget);
    });

    testWidgets('draws 17 marks and no bar while nothing is pressed', (
      t,
    ) async {
      await _pump(t, const ThrottleScale(command: CarCommand()));
      expect(
        t.renderObject(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is ThrottleScalePainter,
          ),
        ),
        paintsExactlyCountTimes(#drawLine, 17),
      );
      expect(_scalePainter(t).fill, 0);
    });

    testWidgets('the bar eases to the new height in the state time', (t) async {
      await _pump(t, const ThrottleScale(command: CarCommand()));
      await _pump(t, const ThrottleScale(command: CarCommand(forward: true)));
      expect(_scalePainter(t).fill, 0);
      await t.pump(); // the animation starts on the next frame
      await t.pump(AppMotion.state ~/ 2);
      expect(_scalePainter(t).fill, inExclusiveRange(0, 0.72));
      await t.pump(AppMotion.state);
      expect(_scalePainter(t).fill, 0.72);
      expect(t.hasRunningAnimations, isFalse);

      await _pump(t, const ThrottleScale(command: CarCommand(reverse: true)));
      await t.pumpAndSettle();
      expect(_scalePainter(t).fill, -0.6);
    });

    testWidgets('with reduce motion the bar jumps and no frame is left '
        'pending', (t) async {
      await _pump(
        t,
        const ThrottleScale(command: CarCommand()),
        reduceMotion: true,
      );
      await _pump(
        t,
        const ThrottleScale(command: CarCommand(turbo: true)),
        reduceMotion: true,
      );
      await t.pump();
      expect(_scalePainter(t).fill, 1);
      expect(t.hasRunningAnimations, isFalse);
    });

    testWidgets('the turbo marker only exists with turbo', (t) async {
      await _pump(t, const ThrottleScale(command: CarCommand(forward: true)));
      expect(_scalePainter(t).turbo, isFalse);
      await _pump(t, const ThrottleScale(command: CarCommand(turbo: true)));
      expect(_scalePainter(t).turbo, isTrue);
    });

    testWidgets('has the size it declares', (t) async {
      await _pump(t, const ThrottleScale(command: CarCommand()));
      expect(t.getSize(find.byType(ThrottleScale)), ThrottleScale.designSize);
    });

    testWidgets('shrinks to fit a smaller box, keeping its proportions', (
      t,
    ) async {
      await _pump(
        t,
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200, maxHeight: 100),
          child: ThrottleScale(command: CarCommand(turbo: true)),
        ),
      );
      expect(t.takeException(), isNull);
      final size = t.getSize(find.byType(ThrottleScale));
      expect(size.height, 100);
      expect(
        size.width / size.height,
        closeTo(
          ThrottleScale.designSize.width / ThrottleScale.designSize.height,
          0.01,
        ),
      );
    });

    testWidgets('is one node for a screen reader: forward, reverse or turbo', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      await _pump(t, const ThrottleScale(command: CarCommand(reverse: true)));
      expect(
        t.getSemantics(find.byType(ThrottleScale)),
        matchesSemantics(label: 'ré'),
      );
      handle.dispose();
    });

    testWidgets('draws an amber bar going up from the middle for forward', (
      t,
    ) async {
      await _pump(t, const ThrottleScale(command: CarCommand(forward: true)));
      await t.pumpAndSettle();
      // The bar is at x 40 to 42.5; the middle of the scale is at y 101.
      expect(await _amberNear(t, 41, 80), isTrue, reason: 'above the middle');
      expect(await _amberNear(t, 41, 125), isFalse, reason: 'below it');
    });

    testWidgets('draws the bar going down from the middle for reverse', (
      t,
    ) async {
      await _pump(t, const ThrottleScale(command: CarCommand(reverse: true)));
      await t.pumpAndSettle();
      expect(await _amberNear(t, 41, 125), isTrue);
      expect(await _amberNear(t, 41, 80), isFalse);
    });
  });
}
