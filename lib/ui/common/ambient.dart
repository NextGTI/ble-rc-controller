import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../cockpit/particles.dart';
import '../theme/tokens.dart';

/// The ambient light behind a screen (spec 3.3): the base colour with a cold
/// gradient from the top, a faint warm spot in the middle, darkened corners and
/// fine grain. It is opaque: it paints the base colour itself.
///
/// With [sweep] a diagonal band of light (at most 5.5%) crosses the screen once
/// every `AppMotion.sweepEvery`. The band stays away, and no frame is scheduled
/// for it, when the system asks to reduce motion or when
/// `EffectsScope.particlesOf` is false; between two crossings it rests, so it
/// does not keep the screen redrawing.
///
/// It fills its parent and ignores touches.
class AmbientBackdrop extends StatefulWidget {
  const AmbientBackdrop({super.key, this.sweep = false});

  final bool sweep;

  @override
  State<AmbientBackdrop> createState() => _AmbientBackdropState();
}

class _AmbientBackdropState extends State<AmbientBackdrop>
    with SingleTickerProviderStateMixin {
  /// How long the band takes to cross the screen.
  static const Duration _crossing = Duration(milliseconds: 2600);

  /// Wait before the first crossing, so it does not compete with the screen
  /// appearing.
  static const Duration _firstDelay = Duration(seconds: 2);

  late final AnimationController _band = AnimationController(
    vsync: this,
    duration: _crossing,
  );
  Timer? _timer;
  bool _sweeping = false;

  @override
  void initState() {
    super.initState();
    _band.addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSweep();
  }

  @override
  void didUpdateWidget(AmbientBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSweep();
  }

  /// Starts or stops the cycle to match the widget and the context.
  void _syncSweep() {
    final allowed =
        widget.sweep &&
        !MediaQuery.disableAnimationsOf(context) &&
        EffectsScope.particlesOf(context);
    if (allowed == _sweeping) return;
    _sweeping = allowed;
    if (allowed) {
      _timer = Timer(_firstDelay, _cross);
    } else {
      _timer?.cancel();
      _timer = null;
      _band.value = 0; // stops the ticker and hides the band
    }
  }

  void _cross() {
    _timer = null;
    _band.forward(from: 0);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _sweeping) {
      _timer = Timer(AppMotion.sweepEvery - _crossing, _cross);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _band.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _LightPainter(MediaQuery.devicePixelRatioOf(context)),
            ),
          ),
          if (widget.sweep)
            RepaintBoundary(child: CustomPaint(painter: _SweepPainter(_band))),
        ],
      ),
    );
  }
}

/// Gradients and grain. Repaints only when the size or the pixel ratio changes.
class _LightPainter extends CustomPainter {
  _LightPainter(this.pixelRatio);

  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // The base the light is laid on: the backdrop is opaque, whatever is
    // behind it.
    canvas.drawRect(rect, Paint()..color = AppColors.bg);

    // Cold light from the top.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          Offset(rect.center.dx, rect.top + size.height * 0.6),
          [
            AppColors.text2.withValues(alpha: 0.10),
            AppColors.text2.withValues(alpha: 0),
          ],
        ),
    );

    // Faint warm spot where the car stands.
    final spot = Offset(size.width / 2, size.height * 0.42);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(spot, size.shortestSide * 0.75, [
          AppColors.headlight.withValues(alpha: 0.07),
          AppColors.headlight.withValues(alpha: 0),
        ]),
    );

    // Dark corners. The gradient is drawn on a unit circle stretched to the
    // screen, so the darkness follows the shape of the screen.
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 2, size.height / 2);
    canvas.drawRect(
      const Rect.fromLTRB(-1, -1, 1, 1),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          math.sqrt2,
          [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.55),
          ],
          [0, 0.6, 1],
        ),
    );
    canvas.restore();

    // Grain: one 256 px tile of noise, repeated, one noise pixel per device
    // pixel.
    final grain = _Grain.image;
    if (grain != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.ImageShader(
            grain,
            TileMode.repeated,
            TileMode.repeated,
            Float64List.fromList([
              1 / pixelRatio, 0, 0, 0, //
              0, 1 / pixelRatio, 0, 0,
              0, 0, 1, 0,
              0, 0, 0, 1,
            ]),
            filterQuality: FilterQuality.none,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_LightPainter old) => old.pixelRatio != pixelRatio;
}

/// The noise, drawn once for the whole run of the app.
abstract final class _Grain {
  static const int _tile = 256;

  /// Seed of the noise: the grain is the same on every start.
  static const int _seed = 0x6A41;

  /// Brightest a grain pixel gets: white at 8%.
  static const double _opacity = 0.08;

  static bool _built = false;
  static ui.Image? _image;

  /// The tile, or null if the engine cannot make it (the grain is only a
  /// decoration, so the screen is drawn without it).
  static ui.Image? get image {
    if (_built) return _image;
    _built = true;
    try {
      _image = _build();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'ambient backdrop',
          context: ErrorDescription('while drawing the grain'),
        ),
      );
    }
    return _image;
  }

  static ui.Image _build() {
    final random = math.Random(_seed);
    const levels = 4; // four strengths of grain pixel
    const perLevel = 4000;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (var level = 1; level <= levels; level++) {
      final points = Float32List(perLevel * 2);
      for (var i = 0; i < perLevel; i++) {
        points[2 * i] = random.nextInt(_tile) + 0.5;
        points[2 * i + 1] = random.nextInt(_tile) + 0.5;
      }
      canvas.drawRawPoints(
        ui.PointMode.points,
        points,
        Paint()
          ..color = Colors.white.withValues(alpha: _opacity * level / levels)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.square,
      );
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_tile, _tile);
    picture.dispose();
    return image;
  }
}

/// The band of light that crosses the screen. Draws nothing while the
/// animation is at either end.
class _SweepPainter extends CustomPainter {
  _SweepPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  /// Tilt of the band from the vertical, in radians (about 20 degrees).
  static const double _tilt = 0.35;

  /// White at 5.5%: the strongest the band gets.
  static const Color _light = Color.fromRGBO(255, 255, 255, 0.055);
  static const Color _none = Color.fromRGBO(255, 255, 255, 0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final width = size.width * 0.28 + 40;
    // Far enough on each side for the tilted band to be fully off screen.
    final reach = width + size.height * math.sin(_tilt);
    final x = ui.lerpDouble(-reach, size.width + reach, t)!;
    final band = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: size.height * 2 + size.width,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(x, size.height / 2);
    canvas.rotate(_tilt);
    canvas.drawRect(
      band,
      Paint()
        ..shader = ui.Gradient.linear(
          band.centerLeft,
          band.centerRight,
          [_none, _light, _none],
          [0, 0.5, 1],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SweepPainter old) => old.progress != progress;
}
