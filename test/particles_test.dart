import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ble_rc_controller/core/protocol.dart';
import 'package:ble_rc_controller/ui/cockpit/particles.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The cool white of the dust at rest and the warm tint of turbo, as the
/// approved design draws them (the lit colour is `AppColors.headlight`).
const _cool = Color(0xFFDCE4F0); // 220, 228, 240
const _warm = Color(0xFFFFCD96); // 255, 205, 150

/// What a canvas was asked to draw, with the paint read at the time of the
/// call: the painter reuses one `Paint`, so a recorder that keeps the object
/// would only ever see the last colour.
class _Dot {
  _Dot(this.centre, this.radius, this.color);
  final Offset centre;
  final double radius;
  final Color color;
}

class _Streak {
  _Streak(this.from, this.to, this.width, this.color);
  final Offset from;
  final Offset to;
  final double width;
  final Color color;
}

class _Probe implements ui.Canvas {
  final dots = <_Dot>[];
  final streaks = <_Streak>[];

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      dots.add(_Dot(c, radius, paint.color));

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) =>
      streaks.add(_Streak(p1, p2, paint.strokeWidth, paint.color));

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

const _field = Size(200, 300);
const _hero = Rect.fromLTWH(0, 60, 200, 180);

/// A sim of [count] particles fitted to [_field].
ParticleSim _sim(int count) => ParticleSim(count)..fit(_field);

/// Steps [sim] for [seconds] at 60 frames a second.
void _run(
  ParticleSim sim,
  CarCommand command, {
  double seconds = 2,
  Offset centre = const Offset(100, 150),
}) {
  for (var i = 0; i < seconds * 60; i++) {
    sim.step(1 / 60, command: command, center: centre);
  }
}

/// Paints [sim] once on a probe canvas.
_Probe _draw(
  ParticleSim sim, {
  CarCommand command = const CarCommand(),
  Rect hero = _hero,
  Rect? beam,
}) {
  final probe = _Probe();
  ParticlePainter(
    sim: sim,
    command: () => command,
    hero: () => hero,
    beam: beam == null ? null : () => beam,
  ).paint(probe, _field);
  return probe;
}

/// [c] without its opacity, rounded to 8 bits a channel like the constants it
/// is compared with.
Color _opaque(Color c) => Color(c.toARGB32() | 0xFF000000);

void main() {
  group('flowTarget and spinTarget', () {
    test('flow follows the car', () {
      expect(flowTarget(const CarCommand(forward: true)), const Offset(0, 240));
      expect(
        flowTarget(const CarCommand(reverse: true)),
        const Offset(0, -240),
      );
      expect(flowTarget(const CarCommand(turbo: true)).dy, 520);
      expect(
        flowTarget(const CarCommand(forward: true, right: true)).dx,
        lessThan(0),
      );
      expect(flowTarget(const CarCommand()), Offset.zero);
      expect(spinTarget(const CarCommand(donut: true)), 2.6);
    });

    test('the current leans away from the turn, by 55% of the speed', () {
      expect(
        flowTarget(const CarCommand(forward: true, right: true)),
        const Offset(-240 * 0.55, 240),
      );
      expect(
        flowTarget(const CarCommand(forward: true, left: true)),
        const Offset(240 * 0.55, 240),
      );
      expect(
        flowTarget(const CarCommand(forward: true, left: true, right: true)),
        const Offset(0, 240),
        reason: 'left and right cancel',
      );
      expect(
        flowTarget(const CarCommand(turbo: true, right: true)),
        const Offset(-520 * 0.55, 520),
      );
    });

    test('there is no current while the car only steers', () {
      expect(flowTarget(const CarCommand(left: true)), Offset.zero);
      expect(
        flowTarget(const CarCommand(right: true, light: true)),
        Offset.zero,
      );
      expect(flowTarget(const CarCommand(donut: true)), Offset.zero);
    });

    test('turbo sets the speed and reverse still flips the direction', () {
      expect(flowTarget(const CarCommand(turbo: true, forward: true)).dy, 520);
      expect(flowTarget(const CarCommand(turbo: true, reverse: true)).dy, -520);
    });

    test('the vector is rotated by the tilt', () {
      final turned = flowTarget(
        const CarCommand(forward: true),
        tiltDegrees: -12,
      );
      // Rotating (0, 240) by -12 degrees: (240 sin 12, 240 cos 12).
      expect(turned.dx, closeTo(240 * math.sin(12 * math.pi / 180), 1e-9));
      expect(turned.dy, closeTo(240 * math.cos(12 * math.pi / 180), 1e-9));
      expect(turned.distance, closeTo(240, 1e-9));
      final quarter = flowTarget(
        const CarCommand(forward: true),
        tiltDegrees: 90,
      );
      expect(quarter.dx, closeTo(-240, 1e-9));
      expect(quarter.dy, closeTo(0, 1e-9));
    });

    test('only the donut spins', () {
      expect(spinTarget(const CarCommand()), 0);
      expect(spinTarget(const CarCommand(forward: true, turbo: true)), 0);
      expect(spinTarget(const CarCommand(donut: true, forward: true)), 2.6);
    });
  });

  group('zoneFactor', () {
    test('quiet behind the header and the controls', () {
      expect(zoneFactor(10, heroTop: 100, heroBottom: 400), 0.55);
      expect(zoneFactor(250, heroTop: 100, heroBottom: 400), 1);
      expect(
        zoneFactor(430, heroTop: 100, heroBottom: 400),
        closeTo(0.5, 1e-9),
      );
      expect(zoneFactor(900, heroTop: 100, heroBottom: 400), 0.18);
    });

    test('the instrument includes both of its edges', () {
      expect(zoneFactor(100, heroTop: 100, heroBottom: 400), 1);
      expect(zoneFactor(400, heroTop: 100, heroBottom: 400), 1);
      expect(zoneFactor(99.9, heroTop: 100, heroBottom: 400), 0.55);
    });

    test('falls to the floor 49.2 below the instrument and stays there', () {
      expect(zoneFactor(450, heroTop: 100, heroBottom: 400), 0.18);
      expect(zoneFactor(449, heroTop: 100, heroBottom: 400), greaterThan(0.18));
      expect(zoneFactor(5000, heroTop: 100, heroBottom: 400), 0.18);
    });
  });

  group('beamGlow', () {
    // 80 wide and 100 high, its base on y=200.
    const beam = Rect.fromLTWH(60, 100, 80, 100);

    test('is brightest at the base and fades to nothing at the far end', () {
      final near = beamGlow(beam, 100, 190);
      final mid = beamGlow(beam, 100, 150);
      final far = beamGlow(beam, 100, 110);
      expect(near, closeTo(0.9, 1e-9));
      expect(mid, closeTo(0.5, 1e-9));
      expect(far, closeTo(0.1, 1e-9));
      expect(beamGlow(beam, 100, 100), 0, reason: 'the far end is dark');
    });

    test('is nothing below the base or past the far end', () {
      expect(beamGlow(beam, 100, 200), 0);
      expect(beamGlow(beam, 100, 260), 0);
      expect(beamGlow(beam, 100, 40), 0);
    });

    test(
      'is a cone: narrow at the base, as wide as the box at the far end',
      () {
        // Just above the base the half-width is about 10...
        expect(beamGlow(beam, 100 + 15, 195), 0);
        expect(beamGlow(beam, 100 + 5, 195), greaterThan(0));
        // ...and it widens to the half-width of the box (40) at the far end.
        expect(beamGlow(beam, 100 + 15, 101), greaterThan(0));
        expect(beamGlow(beam, 100 + 39, 101), greaterThan(0));
        expect(beamGlow(beam, 100 + 41, 101), 0);
        expect(beamGlow(beam, 100 - 39, 101), greaterThan(0));
        expect(beamGlow(beam, 100 - 41, 101), 0);
      },
    );

    test('follows the box, not the origin', () {
      final moved = beam.shift(const Offset(30, -20));
      expect(beamGlow(moved, 130, 170), closeTo(0.9, 1e-9));
      expect(beamGlow(moved, 100, 190), 0);
    });
  });

  group('particleColor', () {
    test('cool white at rest, warm with turbo, headlight when lit', () {
      expect(
        _opaque(particleColor(depth: 1, lit: 0, zone: 1, turbo: false)),
        _cool,
      );
      expect(
        _opaque(particleColor(depth: 1, lit: 0, zone: 1, turbo: true)),
        _warm,
      );
      expect(
        _opaque(particleColor(depth: 1, lit: 0.5, zone: 1, turbo: false)),
        AppColors.headlight,
      );
      expect(
        _opaque(particleColor(depth: 1, lit: 0.5, zone: 1, turbo: true)),
        AppColors.headlight,
        reason: 'the lit colour wins over the turbo tint',
      );
    });

    test('opacity grows with depth, lit and zone, as in the design', () {
      double a(double depth, {double lit = 0, double zone = 1}) =>
          particleColor(depth: depth, lit: lit, zone: zone, turbo: false).a;
      expect(a(0.25), closeTo(0.07 + 0.16 * 0.25, 1e-3));
      expect(a(1), closeTo(0.23, 1e-3));
      expect(a(0.5, lit: 0.5), closeTo((0.07 + 0.08) * (1 + 0.5 * 2.4), 1e-3));
      expect(a(1, zone: 0.55), closeTo(0.23 * 0.55, 1e-3));
      expect(a(1, zone: 0.18), closeTo(0.23 * 0.18, 1e-3));
    });

    test('the brightness is up to 3.4 times, and never above 75%', () {
      // The multiplier at the base of the beam (lit = 1).
      final dim = particleColor(depth: 0.25, lit: 1, zone: 1, turbo: false).a;
      expect(dim, closeTo(0.11 * 3.4, 1e-3));
      expect(
        particleColor(depth: 1, lit: 1, zone: 1, turbo: false).a,
        0.75,
        reason: '0.23 * 3.4 = 0.78 is capped',
      );
    });
  });

  group('ParticleSim', () {
    test('the first picture is the same every time, inside the field', () {
      final a = _sim(95);
      final b = _sim(95);
      expect(a.x, b.x);
      expect(a.y, b.y);
      expect(a.depth, b.depth);
      expect(a.count, 95);
      for (var i = 0; i < a.count; i++) {
        expect(a.x[i], inInclusiveRange(0, _field.width));
        expect(a.y[i], inInclusiveRange(0, _field.height));
        expect(a.depth[i], inInclusiveRange(0.25, 1));
      }
      // Not all in one place: the spread covers the field.
      expect(a.x.reduce(math.max) - a.x.reduce(math.min), greaterThan(150));
      expect(a.y.reduce(math.max) - a.y.reduce(math.min), greaterThan(250));
    });

    test('fitting to a new size keeps the picture and scales it', () {
      final sim = _sim(40);
      final x0 = Float64List.fromList(sim.x);
      final y0 = Float64List.fromList(sim.y);
      sim.fit(const Size(400, 150));
      for (var i = 0; i < sim.count; i++) {
        expect(sim.x[i], closeTo(x0[i] * 2, 1e-9));
        expect(sim.y[i], closeTo(y0[i] * 0.5, 1e-9));
      }
      sim.fit(Size.zero); // an empty size changes nothing
      expect(sim.x[0], closeTo(x0[0] * 2, 1e-9));
    });

    test('a sim that was never fitted does not move', () {
      final sim = ParticleSim(10);
      final before = Float64List.fromList(sim.x);
      sim.step(
        1 / 60,
        command: const CarCommand(forward: true),
        center: Offset.zero,
      );
      expect(sim.x, before);
    });

    test('the velocity closes 6% of the gap each frame', () {
      final sim = _sim(5);
      sim.step(
        1 / 60,
        command: const CarCommand(forward: true),
        center: const Offset(100, 150),
      );
      expect(sim.flow.dy, closeTo(240 * 0.06, 1e-9));
      sim.step(
        1 / 60,
        command: const CarCommand(forward: true),
        center: const Offset(100, 150),
      );
      expect(sim.flow.dy, closeTo(240 * (1 - 0.94 * 0.94), 1e-9));
    });

    test('the easing takes the same time on any frame rate', () {
      final slow = _sim(5);
      final fast = _sim(5);
      const forward = CarCommand(forward: true, right: true, donut: true);
      slow.step(2 / 60, command: forward, center: const Offset(100, 150));
      fast.step(1 / 60, command: forward, center: const Offset(100, 150));
      fast.step(1 / 60, command: forward, center: const Offset(100, 150));
      expect(slow.flow.dx, closeTo(fast.flow.dx, 1e-9));
      expect(slow.flow.dy, closeTo(fast.flow.dy, 1e-9));
      expect(slow.spin, closeTo(fast.spin, 1e-9));
    });

    test('the spin closes 5% of the gap each frame', () {
      final sim = _sim(5);
      sim.step(
        1 / 60,
        command: const CarCommand(donut: true),
        center: const Offset(100, 150),
      );
      expect(sim.spin, closeTo(2.6 * 0.05, 1e-9));
    });

    test('forward sends the dust down, reverse up, turbo faster', () {
      double meanFlow(CarCommand c) {
        final sim = _sim(95);
        _run(sim, c, seconds: 2);
        var sum = 0.0;
        for (var i = 0; i < sim.count; i++) {
          sum += sim.fy[i];
        }
        return sum / sim.count;
      }

      final forward = meanFlow(const CarCommand(forward: true));
      final reverse = meanFlow(const CarCommand(reverse: true));
      final turbo = meanFlow(const CarCommand(turbo: true));
      expect(forward, greaterThan(100));
      expect(reverse, lessThan(-100));
      expect(turbo, greaterThan(forward * 2));
    });

    test('depth scales the speed: near dust is quicker than far dust', () {
      final sim = _sim(95);
      _run(sim, const CarCommand(forward: true));
      var near = 0, far = 0;
      for (var i = 0; i < sim.count; i++) {
        if (sim.depth[i] > 0.9) near = i;
        if (sim.depth[i] < 0.3) far = i;
      }
      expect(sim.depth[near], greaterThan(0.9));
      expect(sim.depth[far], lessThan(0.3));
      expect(sim.fy[near], greaterThan(sim.fy[far] * 2.5));
    });

    test('dust actually moves with the flow', () {
      final sim = _sim(1)
        ..x[0] = 100
        ..y[0] = 100
        ..depth[0] = 1;
      _run(sim, const CarCommand(forward: true), seconds: 0.5);
      expect(sim.y[0], greaterThan(100 + 20));
      expect((sim.x[0] - 100).abs(), lessThan(5), reason: 'only the drift');
    });

    test('at rest the dust only floats about', () {
      final sim = _sim(95);
      final y0 = Float64List.fromList(sim.y);
      _run(sim, const CarCommand(), seconds: 3);
      var farthest = 0.0;
      for (var i = 0; i < sim.count; i++) {
        farthest = math.max(farthest, (sim.y[i] - y0[i]).abs());
        expect(sim.fx[i], 0);
        expect(sim.fy[i], 0);
      }
      expect(farthest, greaterThan(0), reason: 'it floats');
      expect(farthest, lessThan(8), reason: 'slowly');
    });

    test('dust leaving one edge comes back by the opposite one', () {
      final sim = _sim(95);
      _run(sim, const CarCommand(turbo: true, right: true), seconds: 6);
      for (var i = 0; i < sim.count; i++) {
        expect(sim.x[i], inInclusiveRange(-20, _field.width + 20));
        expect(sim.y[i], inInclusiveRange(-20, _field.height + 20));
      }
      _run(sim, const CarCommand(reverse: true), seconds: 6);
      for (var i = 0; i < sim.count; i++) {
        expect(sim.y[i], inInclusiveRange(-20, _field.height + 20));
      }
    });

    test('a long gap between frames is capped, not a jump', () {
      final sim = _sim(1)
        ..x[0] = 100
        ..y[0] = 100
        ..depth[0] = 1;
      // 10 minutes in the background would be 144000 px at full speed.
      sim.step(
        600,
        command: const CarCommand(turbo: true),
        center: const Offset(100, 150),
      );
      expect(sim.y[0], inInclusiveRange(-20, _field.height + 20));
      expect(sim.flow.dy, lessThan(520 * 0.5));
    });

    test('the donut winds the dust around the car', () {
      const centre = Offset(100, 150);
      final sim = _sim(2)
        ..depth[0] = 1
        ..depth[1] = 1
        ..x[0] = 160
        ..y[0] = 150
        ..x[1] = 40
        ..y[1] = 150;
      _run(sim, const CarCommand(donut: true), centre: centre, seconds: 0.5);
      // Right of the car it goes down, left of the car it goes up: the same
      // sense of rotation, with no flow at all.
      expect(sim.fy[0], greaterThan(50));
      expect(sim.fy[1], lessThan(-50));
      expect(sim.flow, Offset.zero);
    });

    test('rest() stops the flow and leaves the dust where it is', () {
      final sim = _sim(30);
      _run(sim, const CarCommand(turbo: true, donut: true));
      final x = Float64List.fromList(sim.x);
      var notified = 0;
      sim.addListener(() => notified++);
      sim.rest();
      expect(notified, 1, reason: 'one repaint, to draw it still');
      expect(sim.flow, Offset.zero);
      expect(sim.spin, 0);
      expect(sim.x, x);
      expect(sim.fx.every((v) => v == 0), isTrue);
      expect(sim.fy.every((v) => v == 0), isTrue);
      sim.rest();
      expect(notified, 1, reason: 'nothing to redraw the second time');
    });

    test('every step asks for one repaint', () {
      final sim = _sim(5);
      var notified = 0;
      sim.addListener(() => notified++);
      sim.step(1 / 60, command: const CarCommand(), center: Offset.zero);
      expect(notified, 1);
    });
  });

  group('ParticlePainter', () {
    test('at rest every particle is a dot in the cool white', () {
      final sim = _sim(95);
      final probe = _draw(sim);
      expect(probe.dots, hasLength(95));
      expect(probe.streaks, isEmpty);
      for (var i = 0; i < 95; i++) {
        final dot = probe.dots[i];
        expect(dot.centre, Offset(sim.x[i], sim.y[i]));
        expect(dot.radius, closeTo(0.5 + sim.depth[i] * 0.9, 1e-9));
        expect(_opaque(dot.color), _cool);
      }
    });

    test('moving fast, every particle is a streak trailing behind it', () {
      final sim = _sim(95);
      _run(sim, const CarCommand(forward: true));
      final probe = _draw(sim, command: const CarCommand(forward: true));
      expect(probe.dots, isEmpty);
      expect(probe.streaks, hasLength(95));
      for (var i = 0; i < 95; i++) {
        final s = probe.streaks[i];
        final z = sim.depth[i];
        expect(s.from, Offset(sim.x[i], sim.y[i]));
        expect(s.to.dx, closeTo(sim.x[i] - sim.fx[i] * 0.03 * z, 1e-4));
        expect(s.to.dy, closeTo(sim.y[i] - sim.fy[i] * 0.03 * z, 1e-4));
        expect(s.to.dy, lessThan(s.from.dy), reason: 'it falls: tail above');
        expect(s.width, closeTo(0.6 + z * 0.9, 1e-5)); // Paint keeps a float32
        expect(_opaque(s.color), _cool);
      }
    });

    test('reverse trails the other way', () {
      final sim = _sim(20);
      _run(sim, const CarCommand(reverse: true));
      final probe = _draw(sim, command: const CarCommand(reverse: true));
      for (final s in probe.streaks) {
        expect(s.to.dy, greaterThan(s.from.dy));
      }
    });

    test('a slow particle stays a dot while a fast one is a streak', () {
      // Speed is vy * depth: 40 is the line between them.
      final sim = _sim(2)
        ..depth[0] = 1
        ..depth[1] = 1;
      sim
        ..fx[0] = 0
        ..fy[0] = 39
        ..fx[1] = 0
        ..fy[1] = 41;
      final probe = _draw(sim);
      expect(probe.dots, hasLength(1));
      expect(probe.streaks, hasLength(1));
      expect(probe.dots.single.centre, Offset(sim.x[0], sim.y[0]));
      expect(probe.streaks.single.from, Offset(sim.x[1], sim.y[1]));
    });

    test('turbo is warm and the streaks are almost twice as long', () {
      final sim = _sim(95);
      _run(sim, const CarCommand(turbo: true));
      final probe = _draw(sim, command: const CarCommand(turbo: true));
      expect(probe.streaks, hasLength(95));
      for (var i = 0; i < 95; i++) {
        final s = probe.streaks[i];
        expect(_opaque(s.color), _warm);
        expect(
          s.to.dy,
          closeTo(sim.y[i] - sim.fy[i] * 0.055 * sim.depth[i], 1e-4),
        );
      }
    });

    group('with the headlights on', () {
      // Base on y=200, 80 wide: x from 60 to 140 at the far end.
      const beam = Rect.fromLTWH(60, 100, 80, 100);
      const lights = CarCommand(light: true);

      ParticleSim twoDust() => _sim(2)
        ..depth[0] = 0.5
        ..depth[1] = 0.5
        ..x[0] = 100
        ..y[0] =
            190 // inside the beam, near the base
        ..x[1] = 10
        ..y[1] = 190; // outside it

      test('dust inside the beam takes the headlight colour and glows', () {
        final probe = _draw(twoDust(), command: lights, beam: beam);
        expect(_opaque(probe.dots[0].color), AppColors.headlight);
        // lit = 1 - 10/100; base alpha for depth 0.5; the hero zone is 1.
        expect(
          probe.dots[0].color.a,
          closeTo((0.07 + 0.16 * 0.5) * (1 + 0.9 * 2.4), 1e-3),
        );
        expect(_opaque(probe.dots[1].color), _cool);
        expect(probe.dots[1].color.a, closeTo(0.07 + 0.16 * 0.5, 1e-3));
      });

      test('the lit streak is still a streak, in the headlight colour', () {
        final sim = twoDust();
        sim
          ..fy[0] = 200
          ..fy[1] = 200;
        final probe = _draw(sim, command: lights, beam: beam);
        expect(probe.streaks, hasLength(2));
        expect(_opaque(probe.streaks[0].color), AppColors.headlight);
        expect(_opaque(probe.streaks[1].color), _cool);
      });

      test('turbo does not tint the lit dust, only the dust outside', () {
        final probe = _draw(
          twoDust(),
          command: const CarCommand(light: true, turbo: true),
          beam: beam,
        );
        expect(_opaque(probe.dots[0].color), AppColors.headlight);
        expect(_opaque(probe.dots[1].color), _warm);
      });

      test('nothing glows with the light off, or without a beam', () {
        for (final probe in [
          _draw(twoDust(), command: const CarCommand(), beam: beam),
          _draw(twoDust(), command: lights),
        ]) {
          expect(probe.dots, hasLength(2));
          for (final dot in probe.dots) {
            expect(_opaque(dot.color), _cool);
            expect(dot.color.a, closeTo(0.07 + 0.16 * 0.5, 1e-3));
          }
        }
      });

      test('asks for the beam only when the light is on', () {
        var asked = 0;
        final sim = twoDust();
        ParticlePainter(
          sim: sim,
          command: () => const CarCommand(),
          hero: () => _hero,
          beam: () {
            asked++;
            return beam;
          },
        ).paint(_Probe(), _field);
        expect(asked, 0);
      });
    });

    test('the dust is quieter behind the header and the controls', () {
      // Hero: y 60 to 240. Above it 55%; 30 below its bottom 50%.
      final sim = _sim(3)
        ..depth[0] = 1
        ..depth[1] = 1
        ..depth[2] = 1
        ..y[0] = 20
        ..y[1] = 150
        ..y[2] = 270;
      final probe = _draw(sim);
      expect(probe.dots[0].color.a, closeTo(0.23 * 0.55, 1e-3));
      expect(probe.dots[1].color.a, closeTo(0.23, 1e-3));
      expect(probe.dots[2].color.a, closeTo(0.23 * 0.5, 1e-3));
    });

    test('repaints when what it reads changes, not for the same inputs', () {
      final sim = _sim(3);
      CarCommand command() => const CarCommand();
      Rect hero() => _hero;
      ParticlePainter make({
        ParticleSim? s,
        CarCommand Function()? c,
        Rect Function()? h,
      }) => ParticlePainter(
        sim: s ?? sim,
        command: c ?? command,
        hero: h ?? hero,
      );
      final base = make();
      expect(make().shouldRepaint(base), isFalse);
      expect(make(s: _sim(3)).shouldRepaint(base), isTrue);
      expect(
        make(c: () => const CarCommand(turbo: true)).shouldRepaint(base),
        isTrue,
      );
      expect(make(h: () => _hero).shouldRepaint(base), isTrue);
    });
  });

  group('ParticleField', () {
    var command = const CarCommand();

    /// Mounts a field in a 200 by 300 box, in the same place of the tree each
    /// time, so a second call updates the state instead of replacing it.
    Future<void> mount(
      WidgetTester t, {
      bool effects = true,
      bool reduceMotion = false,
      bool ticking = true,
      int count = 95,
      Rect? beam,
    }) async {
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: EffectsScope(
              particles: effects,
              child: TickerMode(
                enabled: ticking,
                child: Center(
                  child: SizedBox.fromSize(
                    size: _field,
                    child: ParticleField(
                      command: () => command,
                      carCenter: () => const Offset(100, 150),
                      hero: () => _hero,
                      beam: beam == null ? null : () => beam,
                      count: count,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    ParticlePainter painter(WidgetTester t) =>
        t
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(ParticleField),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as ParticlePainter;

    RenderObject paintBox(WidgetTester t) => t.renderObject(
      find.descendant(
        of: find.byType(ParticleField),
        matching: find.byType(CustomPaint),
      ),
    );

    /// Whether a ticker is running: it registers a frame callback.
    bool running(WidgetTester t) => t.binding.transientCallbackCount > 0;

    /// Pumps [frames] frames of 16 ms.
    Future<void> frames(WidgetTester t, int frames) async {
      for (var i = 0; i < frames; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
    }

    setUp(() => command = const CarCommand());
    // The lifecycle tests leave the binding paused or inactive otherwise.
    tearDown(
      () => TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    testWidgets('effects off: no ticker, no frame, the dust drawn still once', (
      t,
    ) async {
      await mount(t, effects: false);
      await t.pump();
      expect(t.binding.hasScheduledFrame, isFalse);
      expect(running(t), isFalse);
      expect(paintBox(t), paintsExactlyCountTimes(#drawCircle, 95));
      expect(paintBox(t), paintsExactlyCountTimes(#drawLine, 0));
      final before = Float64List.fromList(painter(t).sim.y);
      await t.pump(const Duration(seconds: 2));
      expect(painter(t).sim.y, before, reason: 'nothing moves');
    });

    testWidgets('reduce motion: no ticker, no frame, the dust drawn still', (
      t,
    ) async {
      await mount(t, reduceMotion: true);
      await t.pump();
      expect(t.binding.hasScheduledFrame, isFalse);
      expect(running(t), isFalse);
      expect(paintBox(t), paintsExactlyCountTimes(#drawCircle, 95));
    });

    testWidgets('effects on: a ticker runs and the dust moves', (t) async {
      command = const CarCommand(forward: true);
      await mount(t);
      expect(running(t), isTrue);
      expect(t.binding.hasScheduledFrame, isTrue);
      final before = Float64List.fromList(painter(t).sim.y);
      await frames(t, 30);
      expect(painter(t).sim.y, isNot(before));
      expect(t.binding.hasScheduledFrame, isTrue);
      // Streaks after half a second of driving.
      expect(paintBox(t), paintsExactlyCountTimes(#drawLine, 95));
    });

    testWidgets('the dust follows the command as it changes', (t) async {
      await mount(t);
      await frames(t, 120);
      expect(paintBox(t), paintsExactlyCountTimes(#drawCircle, 95));
      command = const CarCommand(forward: true);
      await frames(t, 120);
      expect(paintBox(t), paintsExactlyCountTimes(#drawLine, 95));
      command = const CarCommand();
      await frames(t, 240);
      expect(paintBox(t), paintsExactlyCountTimes(#drawCircle, 95));
    });

    testWidgets('the count is the number of particles', (t) async {
      await mount(t, effects: false, count: 150);
      expect(paintBox(t), paintsExactlyCountTimes(#drawCircle, 150));
      await mount(t, effects: false, count: 40);
      expect(paintBox(t), paintsExactlyCountTimes(#drawCircle, 40));
    });

    testWidgets('lights on and a beam: some of the dust is lit', (t) async {
      command = const CarCommand(light: true);
      await mount(
        t,
        effects: false,
        beam: const Rect.fromLTWH(20, 20, 160, 220),
      );
      final probe = _Probe();
      painter(t).paint(probe, _field);
      final lit = probe.dots.where(
        (d) => _opaque(d.color) == AppColors.headlight,
      );
      expect(lit, isNotEmpty);
      expect(lit.length, lessThan(probe.dots.length));
    });

    testWidgets('app not in the foreground: the ticker stops', (t) async {
      command = const CarCommand(forward: true);
      await mount(t);
      await frames(t, 5);
      expect(running(t), isTrue);

      // Inactive keeps the engine drawing frames but is not "resumed".
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      expect(running(t), isFalse);
      expect(t.binding.hasScheduledFrame, isFalse);
      final stopped = Float64List.fromList(painter(t).sim.y);
      await t.pump(const Duration(seconds: 1));
      expect(painter(t).sim.y, stopped, reason: 'frozen while away');

      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(running(t), isTrue);
      expect(t.binding.hasScheduledFrame, isTrue);
      await frames(t, 5);
      expect(painter(t).sim.y, isNot(stopped));
    });

    testWidgets('app paused: no ticker and no frame scheduled', (t) async {
      await mount(t);
      expect(running(t), isTrue);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      expect(t.binding.hasScheduledFrame, isFalse);
      expect(running(t), isFalse);
      final stopped = Float64List.fromList(painter(t).sim.y);
      await t.pump(const Duration(seconds: 1));
      expect(painter(t).sim.y, stopped);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(running(t), isTrue);
    });

    testWidgets('mounted while the app is away, it waits for it', (t) async {
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await mount(t);
      await t.pump();
      expect(running(t), isFalse);
      expect(t.binding.hasScheduledFrame, isFalse);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(running(t), isTrue);
    });

    testWidgets('screen not visible (ticker mode off): the ticker stops', (
      t,
    ) async {
      await mount(t, ticking: false);
      await t.pump();
      expect(running(t), isFalse);
      expect(t.binding.hasScheduledFrame, isFalse);
      await mount(t);
      expect(running(t), isTrue);
      await mount(t, ticking: false);
      await t.pump();
      expect(running(t), isFalse);
      expect(t.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('effects switched off while running: stops and settles still', (
      t,
    ) async {
      command = const CarCommand(turbo: true);
      await mount(t);
      await frames(t, 60);
      expect(paintBox(t), paintsExactlyCountTimes(#drawLine, 95));

      await mount(t, effects: false);
      await t.pump();
      expect(running(t), isFalse);
      expect(t.binding.hasScheduledFrame, isFalse);
      // Still: dots, not frozen streaks.
      expect(paintBox(t), paintsExactlyCountTimes(#drawCircle, 95));
      expect(paintBox(t), paintsExactlyCountTimes(#drawLine, 0));

      await mount(t);
      expect(running(t), isTrue);
    });

    testWidgets('reduce motion switched on while running: stops', (t) async {
      await mount(t);
      await frames(t, 5);
      await mount(t, reduceMotion: true);
      await t.pump();
      expect(running(t), isFalse);
      expect(t.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('removed while running: nothing is left behind', (t) async {
      await mount(t);
      await frames(t, 5);
      await t.pumpWidget(const SizedBox());
      expect(running(t), isFalse);
      // The frame the ticker had asked for is still pending; it is empty.
      await t.pump();
      expect(t.binding.hasScheduledFrame, isFalse);
      expect(t.takeException(), isNull);
    });

    testWidgets('does not take touches from what is behind it', (t) async {
      var taps = 0;
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: EffectsScope(
              particles: false,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => taps++,
                    ),
                  ),
                  Positioned.fill(
                    child: ParticleField(
                      command: () => command,
                      carCenter: () => const Offset(100, 150),
                      hero: () => _hero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.tapAt(const Offset(100, 100));
      expect(taps, 1);
    });

    testWidgets('fills the space it is given', (t) async {
      await mount(t, effects: false);
      expect(t.getSize(find.byType(ParticleField)), _field);
      expect(painter(t).sim.x.reduce(math.max), greaterThan(150));
    });
  });
}
