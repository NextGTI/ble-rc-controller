import 'dart:math' as math;

import 'package:ble_rc_controller/ui/cockpit/car_decal.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The same key on every pump, so a second pump updates the decal in place
/// instead of mounting a new one.
final _boundary = GlobalKey();

/// Mounts [decal] in a box of [size] at the top left of a window with a pixel
/// ratio of 1. The repaint boundary around it has [top] logical pixels of room
/// above the box (for the beams) and 40 below it (for the turbo halo), because
/// an image of a boundary only holds what is inside the boundary.
Future<void> _pump(
  WidgetTester t,
  CarDecal decal, {
  Size size = const Size(80, 160),
  double top = 0,
  bool reduceMotion = false,
}) async {
  await t.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _boundary,
          child: Padding(
            padding: EdgeInsets.only(top: top, left: 20, bottom: 40),
            child: SizedBox.fromSize(size: size, child: decal),
          ),
        ),
      ),
    ),
  );
}

/// The alpha of the pixel ([x], [y]) that [_pump]'s repaint boundary draws.
Future<int> _alphaAt(WidgetTester t, int x, int y) async {
  final alpha = await t.runAsync(() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!; // raw RGBA
    final a = bytes.getUint8((y * image.width + x) * 4 + 3);
    image.dispose();
    return a;
  });
  return alpha!;
}

void main() {
  group('wheelAngle', () {
    test('steers 18 degrees to either side', () {
      expect(wheelAngle(1), 18 * math.pi / 180);
      expect(wheelAngle(-1), -wheelAngle(1));
      expect(wheelAngle(0), 0);
    });
  });

  group('carBodyPath', () {
    test('stays inside the outline of the spec', () {
      final b = carBodyPath(const Size(100, 200)).getBounds();
      final limit = const Rect.fromLTWH(10, 2, 81, 196).inflate(1);
      expect(limit.contains(b.topLeft), isTrue, reason: '$b');
      expect(limit.contains(b.bottomRight), isTrue, reason: '$b');
    });

    test('is drawn in the 100 by 200 space and scaled to the size', () {
      final full = carBodyPath(const Size(100, 200)).getBounds();
      final half = carBodyPath(const Size(50, 100)).getBounds();
      expect(half.left, closeTo(full.left / 2, 1e-6));
      expect(half.top, closeTo(full.top / 2, 1e-6));
      expect(half.right, closeTo(full.right / 2, 1e-6));
      expect(half.bottom, closeTo(full.bottom / 2, 1e-6));
    });
  });

  group('CarDecal', () {
    for (final reduce in [false, true]) {
      for (final variant in DecalVariant.values) {
        testWidgets('${variant.name} renders at 80 by 160 '
            '(reduce motion: $reduce)', (tester) async {
          await _pump(
            tester,
            CarDecal(
              variant: variant,
              steer: 1,
              lights: true,
              turbo: true,
              spinning: true,
            ),
            reduceMotion: reduce,
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(find.byType(CarDecal), findsOneWidget);
        });
      }
    }

    testWidgets('a spin with reduce motion leaves no frame pending', (
      tester,
    ) async {
      await _pump(tester, const CarDecal(spinning: true), reduceMotion: true);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('drawing with reduce motion shows the full stroke at rest', (
      tester,
    ) async {
      await _pump(
        tester,
        const CarDecal(variant: DecalVariant.drawing),
        reduceMotion: true,
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('drawing repeats while connecting', (tester) async {
      await _pump(tester, const CarDecal(variant: DecalVariant.drawing));
      await tester.pump(AppMotion.draw);
      await tester.pump(AppMotion.draw);
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('the other variants stay still', (tester) async {
      for (final v in [
        DecalVariant.solid,
        DecalVariant.ghost,
        DecalVariant.icon,
      ]) {
        await _pump(tester, CarDecal(variant: v));
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse, reason: v.name);
      }
    });

    testWidgets('spinning turns once in AppMotion.spin and stops', (
      tester,
    ) async {
      await _pump(tester, const CarDecal());
      expect(tester.hasRunningAnimations, isFalse);

      await _pump(tester, const CarDecal(spinning: true));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(AppMotion.spin ~/ 2);
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pump(AppMotion.spin);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a car that is already spinning when mounted does not turn', (
      tester,
    ) async {
      await _pump(tester, const CarDecal(spinning: true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('turns again each time spinning goes back to true', (
      tester,
    ) async {
      await _pump(tester, const CarDecal());
      await _pump(tester, const CarDecal(spinning: true));
      await tester.pump();
      await tester.pump(AppMotion.spin + const Duration(milliseconds: 1));
      expect(tester.hasRunningAnimations, isFalse);

      await _pump(tester, const CarDecal());
      await _pump(tester, const CarDecal(spinning: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('the beams are painted above the box, outside it', (
      tester,
    ) async {
      // Left beam 30 units above the car: x from about 12 to 32 units, so the
      // middle is 22 units = 17.6 px (20 px of padding on the left); 30 units
      // are 24 px, above the 80 px of room: y = 80 - 24.
      await _pump(tester, const CarDecal(), top: 80);
      expect(await _alphaAt(tester, 37, 56), 0);

      await _pump(tester, const CarDecal(lights: true), top: 80);
      await tester.pump(AppMotion.needle * 2);
      expect(await _alphaAt(tester, 37, 56), greaterThan(0));

      await _pump(tester, const CarDecal(), top: 80);
      await tester.pump(AppMotion.needle * 2);
      expect(await _alphaAt(tester, 37, 56), 0);
    });

    testWidgets('the turbo halo is painted under the car, outside the box', (
      tester,
    ) async {
      // The halo is centred 6 units under the car: 4.8 px below the 160 px box,
      // on the centre line (20 px of padding + 40 px).
      await _pump(tester, const CarDecal());
      expect(await _alphaAt(tester, 60, 164), 0);

      await _pump(tester, const CarDecal(turbo: true));
      await tester.pump(AppMotion.needle * 2);
      expect(await _alphaAt(tester, 60, 164), greaterThan(0));
    });
  });
}
