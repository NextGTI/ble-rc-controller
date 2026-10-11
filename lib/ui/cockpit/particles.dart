import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../core/protocol.dart';
import '../theme/tokens.dart';

/// Tells the decorative layers whether they may animate (spec 3.4).
///
/// Absent from the tree, the effects are on. Tests and low-power screens put a
/// scope above the layers with `particles: false` to keep them still.
class EffectsScope extends InheritedWidget {
  const EffectsScope({
    super.key,
    required this.particles,
    required super.child,
  });

  /// Whether particles and the glass sweep may run.
  final bool particles;

  /// The nearest scope's [particles]; `true` when there is none.
  static bool particlesOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EffectsScope>()?.particles ??
      true;

  @override
  bool updateShouldNotify(EffectsScope oldWidget) =>
      particles != oldWidget.particles;
}

// ---------------------------------------------------------------------------
// The rules of the field (spec 4.7), as pure functions
// ---------------------------------------------------------------------------

/// Pixels a second the dust runs at with turbo, with the car moving, and 0.
const double _turboSpeed = 520;
const double _driveSpeed = 240;

/// How much of the speed goes sideways in a turn.
const double _leanFactor = 0.55;

/// Where the dust is heading, in pixels a second, for the car doing [c].
///
/// Down (`+y`) when the car goes forward, up when it reverses; turbo makes it
/// faster. In a turn the current leans to the side opposite to the turn.
/// [tiltDegrees] then turns the whole vector, for a car drawn rotated.
Offset flowTarget(CarCommand c, {double tiltDegrees = 0}) {
  final speed = c.turbo
      ? _turboSpeed
      : (c.forward || c.reverse)
      ? _driveSpeed
      : 0.0;
  final steer = (c.right ? 1 : 0) - (c.left ? 1 : 0);
  final x = -steer * speed * _leanFactor;
  final y = c.reverse ? -speed : speed;
  if (tiltDegrees == 0) return Offset(x, y);
  final a = tiltDegrees * math.pi / 180;
  final cos = math.cos(a), sin = math.sin(a);
  return Offset(x * cos - y * sin, x * sin + y * cos);
}

/// How fast the dust winds around the car: 2.6 with the 360 degree spin, else 0.
double spinTarget(CarCommand c) => c.donut ? 2.6 : 0;

/// How strong the dust is at height [y]: 0.55 behind the header (above the
/// instrument, from [heroTop] to [heroBottom]), 1 in it, and falling to 0.18
/// behind the cells and buttons below.
double zoneFactor(
  double y, {
  required double heroTop,
  required double heroBottom,
}) {
  if (y < heroTop) return 0.55;
  if (y <= heroBottom) return 1;
  return math.max(0.18, 1 - (y - heroBottom) / 60);
}

/// How lit the dust at ([x], [y]) is by the headlight [beam]: 0 outside the
/// cone, up to 1 at the lights.
///
/// The cone stands on the bottom edge of [beam] and widens up to its top edge,
/// where it is as wide as the box. At its base it is 22.5% of that width, the
/// proportion of the approved design (10 against 44 of half-width). The glow
/// fades linearly along the cone.
double beamGlow(Rect beam, double x, double y) {
  final up = beam.bottom - y;
  if (up <= 0 || up >= beam.height) return 0;
  final along = up / beam.height;
  final half = beam.width / 2 * (_beamBase + (1 - _beamBase) * along);
  if ((x - beam.center.dx).abs() >= half) return 0;
  return 1 - along;
}

const double _beamBase = 0.225;

/// Cool white of the dust at rest (220, 228, 240 of the approved design). It
/// is the cold light of the ambient backdrop, so it has no token of its own.
const Color _coolDust = Color(0xFFDCE4F0);

/// Warm tint of the dust at turbo (255, 205, 150): paler than the amber, which
/// is for active states, so it is not a token either.
const Color _warmDust = Color(0xFFFFCD96);

/// The opacity ceiling of one particle.
const double _maxAlpha = 0.75;

/// The colour and opacity of a particle of [depth] (0.25 to 1), [lit] by the
/// beam (0 to 1), in a zone of strength [zone]. Lit dust takes the headlight
/// colour and glows up to 3.4 times; otherwise turbo tints it warm.
@visibleForTesting
Color particleColor({
  required double depth,
  required double lit,
  required double zone,
  required bool turbo,
}) {
  final base = lit > 0
      ? AppColors.headlight
      : turbo
      ? _warmDust
      : _coolDust;
  final alpha = (0.07 + 0.16 * depth) * (1 + lit * 2.4) * zone;
  return base.withValues(alpha: math.min(alpha, _maxAlpha));
}

// ---------------------------------------------------------------------------
// The simulation
// ---------------------------------------------------------------------------

/// Closing of the gap to the target, per frame at 60 a second: the flow
/// velocity 6%, the spin 5%.
const double _flowEase = 0.06;
const double _spinEase = 0.05;

/// The longest step taken at once, so coming back from a pause is not a jump.
const double _maxStep = 0.05;

/// Past this speed (pixels a second) a particle is drawn as a streak.
const double _streakSpeed = 40;

/// The particles and their motion: positions, depths and the velocity each
/// has this frame, in struct-of-arrays form so a frame allocates nothing.
///
/// The first picture comes from a fixed seed, so it is the same every time.
/// Notifies its listeners after each [step] and [rest], so a painter repaints.
@visibleForTesting
class ParticleSim extends ChangeNotifier {
  ParticleSim(this.count, {int seed = 0x6A5E})
    : assert(count >= 0),
      x = Float64List(count),
      y = Float64List(count),
      depth = Float64List(count),
      _phase = Float64List(count),
      fx = Float64List(count),
      fy = Float64List(count) {
    final random = math.Random(seed);
    for (var i = 0; i < count; i++) {
      // x and y start in the unit square; the first [fit] scales them.
      x[i] = random.nextDouble();
      y[i] = random.nextDouble();
      depth[i] = 0.25 + random.nextDouble() * 0.75;
      _phase[i] = random.nextDouble() * 6.28;
    }
  }

  final int count;

  /// Position of each particle, in the field's pixels.
  final Float64List x, y;

  /// Depth of each particle, 0.25 to 1: size, speed and opacity follow it.
  final Float64List depth;

  /// Velocity of each particle at the last step (flow and swirl, without the
  /// idle drift), in pixels a second. A streak is drawn along it.
  final Float64List fx, fy;

  final Float64List _phase;

  Size _size = const Size(1, 1);
  bool _fitted = false;

  double _vx = 0, _vy = 0, _spin = 0;
  double _clock = 0;
  bool _moving = false;

  /// The flow velocity the dust is easing to, before depth scales it.
  Offset get flow => Offset(_vx, _vy);

  /// How fast the swirl around the car is.
  double get spin => _spin;

  /// Fits the field to [size]: the first call spreads the particles over it,
  /// later ones scale the picture. An empty size changes nothing.
  void fit(Size size) {
    if (size.isEmpty || (_fitted && size == _size)) return;
    final sx = size.width / _size.width, sy = size.height / _size.height;
    for (var i = 0; i < count; i++) {
      x[i] *= sx;
      y[i] *= sy;
    }
    _size = size;
    _fitted = true;
  }

  /// Moves the dust by [dt] seconds towards what [command] asks, winding
  /// around [center] when the car spins. The easing is the design's 6% and 5%
  /// per frame at 60 frames a second, whatever the frame rate.
  void step(double dt, {required CarCommand command, required Offset center}) {
    if (!_fitted || dt <= 0) return;
    dt = math.min(dt, _maxStep);
    final frames = dt * 60;
    final target = flowTarget(command);
    final flowK = 1 - math.pow(1 - _flowEase, frames);
    final spinK = 1 - math.pow(1 - _spinEase, frames);
    _vx += (target.dx - _vx) * flowK;
    _vy += (target.dy - _vy) * flowK;
    _spin += (spinTarget(command) - _spin) * spinK;
    _clock += dt;
    _moving = true;

    final ms = _clock * 1000;
    final swirl = _spin > 0.01;
    final w = _size.width, h = _size.height;
    for (var i = 0; i < count; i++) {
      final z = depth[i];
      // Idle drift: a slow float about, always on.
      final driftX = math.sin(ms / 1700 + _phase[i]) * 6;
      final driftY = math.cos(ms / 2100 + _phase[i]) * 4;
      var vx = _vx * z, vy = _vy * z;
      if (swirl) {
        final ox = x[i] - center.dx, oy = y[i] - center.dy;
        final r = math.sqrt(ox * ox + oy * oy) + 30;
        vx += -oy / r * _spin * 180 * z;
        vy += ox / r * _spin * 180 * z;
      }
      var px = x[i] + (vx + driftX * 0.4) * dt;
      var py = y[i] + (vy + driftY * 0.4) * dt;
      // Out at one edge, back in at the other.
      if (px < -20) px += w + 40;
      if (px > w + 20) px -= w + 40;
      if (py < -20) py += h + 40;
      if (py > h + 20) py -= h + 40;
      x[i] = px;
      y[i] = py;
      fx[i] = vx;
      fy[i] = vy;
    }
    notifyListeners();
  }

  /// Stops the flow: the dust stays where it is and is drawn as dots, not as
  /// streaks. Repaints once, and only if anything was moving.
  void rest() {
    if (!_moving) return;
    _moving = false;
    _vx = _vy = _spin = 0;
    fx.fillRange(0, count, 0);
    fy.fillRange(0, count, 0);
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------

/// Draws the particles of [sim]: a dot, or a streak along its velocity when it
/// is fast. It reads [command], [hero] and [beam] each time it paints.
@visibleForTesting
class ParticlePainter extends CustomPainter {
  ParticlePainter({
    required this.sim,
    required this.command,
    required this.hero,
    this.beam,
  }) : super(repaint: sim);

  final ParticleSim sim;
  final CarCommand Function() command;
  final Rect Function() hero;
  final Rect Function()? beam;

  // One paint for the whole field, changed for each particle.
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    sim.fit(size);
    final car = command();
    final heroRect = hero();
    final beamRect = car.light ? beam?.call() : null;
    final streakLength = car.turbo ? 0.055 : 0.03;
    for (var i = 0; i < sim.count; i++) {
      final x = sim.x[i], y = sim.y[i], z = sim.depth[i];
      final fx = sim.fx[i], fy = sim.fy[i];
      _paint.color = particleColor(
        depth: z,
        lit: beamRect == null ? 0 : beamGlow(beamRect, x, y),
        zone: zoneFactor(y, heroTop: heroRect.top, heroBottom: heroRect.bottom),
        turbo: car.turbo,
      );
      if (fx * fx + fy * fy > _streakSpeed * _streakSpeed) {
        final k = streakLength * z;
        _paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6 + z * 0.9;
        canvas.drawLine(Offset(x, y), Offset(x - fx * k, y - fy * k), _paint);
      } else {
        _paint.style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 0.5 + z * 0.9, _paint);
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter old) =>
      old.sim != sim ||
      old.command != command ||
      old.hero != hero ||
      old.beam != beam;
}

/// How many particles the dust has over an [area] (spec 4.7, "about 95 on a
/// phone and 150 on a desktop, adjusted by the area").
///
/// A straight line through the two sizes the spec names: 95 for a phone of
/// 390 by 844 and 150 for a desktop window of 1180 by 760, held between 60
/// and 170 so a tiny window still has dust (the line starts at about 63) and a
/// huge one does not drown the frame. The area is the cockpit's own, so the cockpit beside the garage
/// column (900 wide in a window of 1180) has fewer than a window of its own.
///
/// It goes in steps of five: a window being dragged would otherwise restart
/// the dust at nearly every pixel.
int particleCountFor(Size area) {
  const phone = 390.0 * 844.0;
  const desktop = 1180.0 * 760.0;
  final t = (area.width * area.height - phone) / (desktop - phone);
  final count = 95 + (150 - 95) * t;
  return ((count / 5).round() * 5).clamp(60, 170);
}

/// The air and dust behind the cockpit (spec 4.7): fine particles that float
/// at rest, run down with the car going forward, up in reverse, lean away from
/// a turn, stretch into warm streaks at turbo, wind around the car in the
/// 360 degree spin, and glow in the headlight colour inside the beam.
///
/// It fills its parent (bounded constraints) and ignores touches. Everything
/// is given in the field's own coordinates, as callbacks read at each frame:
/// [command] is what the car is doing, [carCenter] the centre the dust winds
/// around, [hero] the box of the instrument (the dust is 55% above it and fades
/// to 18% below it, see [zoneFactor]) and [beam], when there is one, the box of
/// the headlight cone: its base edge on the lights, its top edge where the beam
/// ends. [count] is the number of particles (about 95 on a phone and 150 on a
/// desktop; the caller adjusts it to the area with [particleCountFor]).
///
/// It makes no ticker, and draws the particles once and still, when
/// `EffectsScope.particlesOf` is false or the system asks to reduce motion
/// (needs a `MediaQuery` above). The ticker also stops while the app is not in
/// the foreground and while the subtree's `TickerMode` is off, and starts again
/// when both are back.
class ParticleField extends StatefulWidget {
  const ParticleField({
    super.key,
    required this.command,
    required this.carCenter,
    required this.hero,
    this.beam,
    this.count = 95,
  }) : assert(count >= 0);

  final CarCommand Function() command;
  final Offset Function() carCenter;
  final Rect Function() hero;
  final Rect Function()? beam;
  final int count;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ParticleSim _sim = ParticleSim(widget.count);
  Ticker? _ticker;
  Duration? _lastTick;

  // The three reasons it may not run; see [_sync].
  bool _effects = true;
  bool _visible = true;
  late bool _foreground;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _effects =
        EffectsScope.particlesOf(context) &&
        !MediaQuery.disableAnimationsOf(context);
    _visible = TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didUpdateWidget(ParticleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _sim.dispose();
      _sim = ParticleSim(widget.count);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  /// Runs the ticker only when the effects are on, the subtree is visible and
  /// the app is in the foreground. When the effects are off the dust is left
  /// still, as dots; when it is only away it stays as it was.
  void _sync() {
    if (!_effects) _sim.rest();
    final run = _effects && _visible && _foreground;
    if (run && _ticker == null) {
      _lastTick = null;
      _ticker = createTicker(_onTick)..start();
    } else if (!run && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
    }
  }

  void _onTick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return; // the first frame has no time behind it
    _sim.step(
      (elapsed - last).inMicroseconds / Duration.microsecondsPerSecond,
      command: widget.command(),
      center: widget.carCenter(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    _sim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox.expand(
          child: CustomPaint(
            painter: ParticlePainter(
              sim: _sim,
              command: widget.command,
              hero: widget.hero,
              beam: widget.beam,
            ),
          ),
        ),
      ),
    );
  }
}
