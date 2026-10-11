import 'package:flutter/material.dart';

import '../../core/car_transport.dart';
import '../../core/driver.dart';
import '../../l10n/gen/app_localizations.dart';
import '../common/glass.dart';
import '../common/notice.dart';
import '../common/ring_spinner.dart';
import '../garage/car_list.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'car_decal.dart';
import 'cockpit_metrics.dart';
import 'state_cells.dart';
import 'touch_pads.dart';

// ---------------------------------------------------------------------------
// Which state the cockpit is in
// ---------------------------------------------------------------------------

/// What fills the middle of the cockpit (spec 5.2). The first one that holds
/// wins, in the order below.
enum PanelState {
  /// Bluetooth is off, blocked or missing: nothing else can happen.
  bluetooth,

  /// A car is being reached.
  connecting,

  /// A car is connected: the instrument.
  connected,

  /// The link dropped and the app waits to reconnect to the car.
  lost,

  /// Nothing else: looking for a car (and the list of those found).
  searching,
}

/// Why Bluetooth cannot be used, as the state the screen is for, or null when
/// it can (or is not known yet).
///
/// - `unsupported`: the device has no Bluetooth LE, whatever else is true;
/// - `unauthorized`: the system blocks the app, or the permission request was
///   refused (the driver says so with [MessageKind.permissionDenied]). With
///   the permission refused, turning Bluetooth on would not help;
/// - `off`: the adapter is off.
///
/// `unknown`, the moment before the first answer, is not a problem: the app
/// is just starting to look.
BluetoothState? bluetoothBlockOf(Driver d) {
  final refused = d.message == MessageKind.permissionDenied;
  switch (d.bluetooth) {
    case BluetoothState.unsupported:
      return BluetoothState.unsupported;
    case BluetoothState.unauthorized:
      return BluetoothState.unauthorized;
    case BluetoothState.off:
      return refused ? BluetoothState.unauthorized : BluetoothState.off;
    case BluetoothState.ready:
    case BluetoothState.unknown:
      return refused ? BluetoothState.unauthorized : null;
  }
}

/// The state of the cockpit: the one place that decides. The cockpit picks its
/// screen with it and the header picks its line with it, so the two cannot
/// disagree.
///
/// In the order of spec 5.2:
/// 1. Bluetooth not ready (see [bluetoothBlockOf]);
/// 2. a car being connected;
/// 3. a car connected;
/// 4. waiting to reconnect to a car that dropped;
/// 5. otherwise searching.
PanelState panelStateOf(Driver d) {
  if (bluetoothBlockOf(d) != null) return PanelState.bluetooth;
  switch (d.link) {
    case LinkState.connecting:
      return PanelState.connecting;
    case LinkState.connected:
      return PanelState.connected;
    case LinkState.idle:
      return d.reconnecting ? PanelState.lost : PanelState.searching;
  }
}

/// What the line under the name and the title of the screen say when
/// Bluetooth is in state [s].
String bluetoothTitle(AppLocalizations l, BluetoothState s) => switch (s) {
  BluetoothState.unauthorized => l.btDeniedTitle,
  BluetoothState.unsupported => l.btUnsupportedTitle,
  _ => l.btOffTitle,
};

// ---------------------------------------------------------------------------
// The screens
// ---------------------------------------------------------------------------

/// Looking for a car (spec 5.2, "Procurando").
///
/// - No car in range: the ghost car with amber waves going out of it
///   ([SearchWaves]), "Turn the car on" and the two hints that usually solve
///   it.
/// - Cars in range: the ghost car and "Cars nearby" with the list of cars.
///   On the desktop the garage column already is that list, so the screen
///   keeps the ghost car and the words "Cars nearby" and does not repeat it.
///
/// Two notices can sit above all that:
/// - "The car disconnected.", after a drop with auto-reconnect off, with
///   "Close". On every layout.
/// - "Could not connect to X" with "Try again" and "Close". The list of cars
///   carries it where there is one; with no cars on a phone, tablet or
///   landscape screen this screen shows it itself. The desktop's garage
///   column shows it, so this screen does not.
///
/// It reads the driver, so it needs a `DriverScope` above it.
class SearchingView extends StatelessWidget {
  const SearchingView({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final kind = layoutFor(MediaQuery.sizeOf(context));
    final desktop = kind == LayoutKind.desktop;
    final cars = driver.cars;
    final failed = ConnectFailedNotice.carOf(driver);

    final notices = <Widget>[
      if (driver.message == MessageKind.dropped)
        Notice(
          title: l.msgDropped,
          secondaryLabel: l.close,
          onSecondary: driver.dismissMessage,
        ),
      // The list carries it when there is one, and the garage column on the
      // desktop.
      if (failed != null && cars.isEmpty && !desktop)
        ConnectFailedNotice(car: failed),
    ];

    if (cars.isEmpty) {
      return _StateFrame(
        variant: DecalVariant.ghost,
        waves: true,
        notices: notices,
        details: [
          _Message(title: l.searchTitle, body: l.searchBody),
          const SizedBox(height: 18),
          _Tips(
            tips: [
              (l.tipNotShowingLabel, l.tipNotShowing),
              (l.tipStillLabel, l.tipStill),
            ],
          ),
        ],
      );
    }

    return _StateFrame(
      variant: DecalVariant.ghost,
      decalShare: desktop ? 0.34 : 0.2,
      minDecal: desktop ? 96 : 72,
      notices: notices,
      details: desktop
          ? [_Message(title: l.carsNearby)]
          : [_NearbyHeading(title: l.carsNearby), const CarList()],
    );
  }
}

/// Bluetooth is not ready (spec 5.2): the ghost car with the crossed
/// Bluetooth symbol, a title that says which of the three it is and what to
/// do.
///
/// - `off`: "Bluetooth is off". Where the system can be asked to turn it on
///   (Android), the button "Turn Bluetooth on"; elsewhere only the text.
/// - `unauthorized`: "Bluetooth is blocked" and "Try again", which asks for the
///   permission once more.
/// - `unsupported`: "Bluetooth LE is unavailable" and no action.
///
/// [state] is [bluetoothBlockOf] of the driver. It needs a `DriverScope`.
class BluetoothView extends StatelessWidget {
  const BluetoothView(this.state, {super.key})
    : assert(
        state != BluetoothState.ready && state != BluetoothState.unknown,
        'there is a screen only for a Bluetooth that cannot be used',
      );

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final body = switch (state) {
      BluetoothState.unauthorized => l.btDeniedBody,
      BluetoothState.unsupported => l.btUnsupportedBody,
      _ => l.btOffBody,
    };
    final Widget? action = switch (state) {
      BluetoothState.unauthorized => _Cta(
        label: l.retry,
        onTap: driver.retryPermissions,
      ),
      BluetoothState.unsupported => null,
      _ =>
        driver.canEnableBluetooth
            ? _Cta(label: l.btEnable, onTap: driver.enableBluetooth)
            : null,
    };

    return _StateFrame(
      variant: DecalVariant.ghost,
      overlay: const _BluetoothGlyph(),
      details: [
        _Message(title: bluetoothTitle(l, state), body: body),
        if (action != null) ...[const SizedBox(height: 18), action],
      ],
    );
  }
}

/// A car is being reached (spec 5.2, "Conectando"): the car draws itself, over
/// and over, "Connecting to X", "It takes a few seconds." and "Cancel", which
/// gives up the attempt.
///
/// It needs a `DriverScope`.
class ConnectingView extends StatelessWidget {
  const ConnectingView({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final car = driver.connectedCar;
    return _StateFrame(
      variant: DecalVariant.drawing,
      details: [
        _Message(
          // A car the scan never showed has no name to give.
          title: car == null
              ? l.statusConnecting
              : l.connectingTitle(car.model),
          body: l.connectingBody,
        ),
        const SizedBox(height: 18),
        _Cta(label: l.cancel, quiet: true, onTap: driver.disconnect),
      ],
    );
  }
}

/// The link dropped and the app is waiting for the car to show up again
/// (spec 5.2, "Conexão perdida"): the ghost car with the tag "Connection
/// lost", what happened, and the cells and arrows switched off.
///
/// The cells and arrows are not the real ones: they are empty glass at low
/// opacity that no finger or screen reader reaches, so nothing on this screen
/// can drive a car that is not there. With auto-reconnect off there is no
/// waiting, and the cockpit shows [SearchingView] with its notice instead.
///
/// It needs a `DriverScope`.
class LostView extends StatelessWidget {
  const LostView({super.key});

  /// Marks of the switched-off cells and arrows, for the tests.
  static const Key cellKey = ValueKey('lostCell');
  static const Key padKey = ValueKey('lostPad');

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final kind = layoutFor(MediaQuery.sizeOf(context));
    return _StateFrame(
      variant: DecalVariant.ghost,
      overlay: _LostTag(label: l.lostTag),
      decalShare: 0.26,
      details: [
        _Message(body: l.lostBody),
        const SizedBox(height: 16),
        _SwitchedOff(
          // The same grid as the real cells.
          columns: kind == LayoutKind.phone || kind == LayoutKind.landscape
              ? 2
              : 4,
          pads: driver.onScreenControls,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// The search waves
// ---------------------------------------------------------------------------

/// Three amber rings going out of the car while the app searches (spec 5.2):
/// each one grows from 0.6 to 2.2 times its size and fades out in 2.4 s, one
/// starting 0.8 s after the other. With the system's "reduce motion" on there
/// is one still ring.
///
/// [diameter] is the size of a ring at scale 1. The rings are centred on the
/// widget and paint outside it as they grow; they are not clipped.
class SearchWaves extends StatefulWidget {
  const SearchWaves({super.key, required this.diameter});

  final double diameter;

  /// How many rings, and how long and how far apart in time they go.
  static const int rings = 3;
  static const Duration period = Duration(milliseconds: 2400);
  static const Duration stagger = Duration(milliseconds: 800);

  /// Size of a ring when it starts and when it is gone.
  static const double fromScale = 0.6;
  static const double toScale = 2.2;

  /// How opaque a ring is when it starts (before its own 50% amber).
  static const double startOpacity = 0.7;

  /// The still ring of "reduce motion".
  static const double stillScale = 1.2;
  static const double stillOpacity = 0.6;

  /// The ring [i] of the widget, to find it in a test.
  static Key ringKey(int i) => ValueKey('searchWave$i');

  @override
  State<SearchWaves> createState() => _SearchWavesState();
}

class _SearchWavesState extends State<SearchWaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: SearchWaves.period,
  );

  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still) {
      _time.stop();
    } else if (!_time.isAnimating) {
      _time.repeat();
    }
  }

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  /// Ring [i] at [t] (0 to 1 of the period): `ease-out` over its own cycle,
  /// which starts [SearchWaves.stagger] after the one before.
  Widget _ring(int i, double t) {
    final lag =
        SearchWaves.stagger.inMicroseconds / SearchWaves.period.inMicroseconds;
    final progress = Curves.easeOut.transform((t - i * lag) % 1);
    return _Ring(
      key: SearchWaves.ringKey(i),
      diameter: widget.diameter,
      scale:
          SearchWaves.fromScale +
          (SearchWaves.toScale - SearchWaves.fromScale) * progress,
      opacity: SearchWaves.startOpacity * (1 - progress),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Decoration only: nothing reads it out and nothing is touched through it.
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: widget.diameter,
            child: _still
                ? _Ring(
                    key: SearchWaves.ringKey(0),
                    diameter: widget.diameter,
                    scale: SearchWaves.stillScale,
                    opacity: SearchWaves.stillOpacity,
                  )
                : AnimatedBuilder(
                    animation: _time,
                    builder: (context, _) => Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        for (var i = 0; i < SearchWaves.rings; i++)
                          _ring(i, _time.value),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// One ring: a 1 px amber circle at half strength, scaled and faded.
class _Ring extends StatelessWidget {
  const _Ring({
    super.key,
    required this.diameter,
    required this.scale,
    required this.opacity,
  });

  final double diameter;
  final double scale;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
          ),
          child: SizedBox.square(dimension: diameter),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The pieces the screens are made of
// ---------------------------------------------------------------------------

/// Sizes that depend on the layout (spec 3.2: a state message is 22 to 26).
class _Look {
  const _Look({required this.title, required this.maxDecal});

  /// Size of the title of a state.
  final double title;

  /// Tallest the car is drawn.
  final double maxDecal;

  static _Look of(LayoutKind kind) => switch (kind) {
    LayoutKind.phone => const _Look(title: 24, maxDecal: 230),
    LayoutKind.tablet => const _Look(title: 26, maxDecal: 300),
    LayoutKind.landscape => const _Look(title: 22, maxDecal: 190),
    LayoutKind.desktop => const _Look(title: 26, maxDecal: 320),
  };
}

/// The frame all the screens share: the car with whatever goes over it, and
/// under it what the state says.
///
/// - Upright layouts: one column from the top, as in the approved design, with
///   the [notices] above the car. It starts at the same place in every state,
///   and a list that grows only grows downward. The car gives way first when
///   the room is short, as far as [minDecal]; the text never shrinks, so when
///   even that is not enough the column scrolls.
/// - Landscape: the car on the left, and on the right the [notices] and the
///   [details], centred in the height and scrolling when they do not fit.
///
/// [decalShare] is the part of the height the car takes, before it is held
/// between [minDecal] and the layout's tallest.
class _StateFrame extends StatelessWidget {
  const _StateFrame({
    required this.variant,
    required this.details,
    this.notices = const [],
    this.waves = false,
    this.overlay,
    this.decalShare = 0.3,
    this.minDecal = 96,
  });

  final DecalVariant variant;
  final List<Widget> details;
  final List<Widget> notices;
  final bool waves;

  /// Drawn over the car, in the middle of it.
  final Widget? overlay;
  final double decalShare;
  final double minDecal;

  @override
  Widget build(BuildContext context) {
    final kind = layoutFor(MediaQuery.sizeOf(context));
    final look = _Look.of(kind);
    final inset = CockpitMetrics.of(kind).body.copyWith(top: 12, bottom: 12);
    final landscape = kind == LayoutKind.landscape;

    return LayoutBuilder(
      builder: (context, box) {
        final room =
            (box.hasBoundedHeight ? box.maxHeight : 600) - inset.vertical;
        // On the side of the text there is the whole height to take.
        final share = landscape ? decalShare + 0.3 : decalShare;
        final decal = (room * share).clamp(minDecal, look.maxDecal).toDouble();
        final stage = _Stage(
          decal: decal,
          variant: variant,
          waves: waves,
          overlay: overlay,
        );
        final spaced = [
          for (final n in notices)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: n),
        ];

        if (landscape) {
          return Padding(
            padding: inset,
            child: Row(
              children: [
                Expanded(flex: 5, child: Center(child: stage)),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: _ColumnScroll(
                    minHeight: room,
                    maxWidth: 400,
                    centred: true,
                    children: [...spaced, ...details],
                  ),
                ),
              ],
            ),
          );
        }
        return _ColumnScroll(
          padding: inset,
          minHeight: room,
          maxWidth: 480,
          children: [...spaced, stage, const SizedBox(height: 10), ...details],
        );
      },
    );
  }
}

/// A column at most [maxWidth] wide, in the middle of the width, at the top of
/// the room it has ([minHeight]) or, with [centred], in the middle of it. It
/// scrolls when it needs more room.
class _ColumnScroll extends StatelessWidget {
  const _ColumnScroll({
    required this.minHeight,
    required this.maxWidth,
    required this.children,
    this.centred = false,
    this.padding = EdgeInsets.zero,
  });

  final double minHeight;
  final double maxWidth;
  final List<Widget> children;
  final bool centred;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Align(
          alignment: centred ? Alignment.center : Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// The car of a state, [decal] high and half as wide, in a stage a fifth
/// taller. The waves, when there are any, come out of it. [overlay] is drawn
/// over its middle.
///
/// The drawings are decoration: the screen reader gets the words.
class _Stage extends StatelessWidget {
  const _Stage({
    required this.decal,
    required this.variant,
    required this.waves,
    required this.overlay,
  });

  final double decal;
  final DecalVariant variant;
  final bool waves;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: decal * 1.2,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // A ring starts about as wide as the car is long, nearly.
          if (waves) SearchWaves(diameter: decal * 0.84),
          ExcludeSemantics(
            child: SizedBox(
              width: decal / 2,
              height: decal,
              child: CarDecal(variant: variant),
            ),
          ),
          ?overlay,
        ],
      ),
    );
  }
}

/// The title and the line of explanation of a state, centred. They are one
/// announcement for a screen reader, so a state that appears is read out.
class _Message extends StatelessWidget {
  const _Message({this.title, this.body});

  final String? title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final size = _Look.of(layoutFor(MediaQuery.sizeOf(context))).title;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Text(
              title!,
              textAlign: TextAlign.center,
              style: AppType.numeric(size: size)
                  .copyWith(color: AppColors.text, height: 1.2),
            ),
          if (title != null && body != null) const SizedBox(height: 6),
          if (body != null)
            Text(
              body!,
              textAlign: TextAlign.center,
              style: AppType.body(size: 14).copyWith(color: AppColors.text2),
            ),
        ],
      ),
    );
  }
}

/// The button of a state: [onTap] under a [label], amber when it is the way
/// out ([quiet] false) and a plain outline when it is only a way to give up.
/// It is as wide as the room, up to 320, and at least 48 high.
class _Cta extends StatelessWidget {
  const _Cta({required this.label, required this.onTap, this.quiet = false});

  final String label;
  final VoidCallback onTap;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Glass(
          active: !quiet,
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppType.body(size: 14)
                  .copyWith(color: quiet ? AppColors.text2 : AppColors.amber),
            ),
          ),
        ),
      ),
    );
  }
}

/// The two hints of a search that finds nothing: a small grey label over the
/// sentence, one after the other in a glass card.
class _Tips extends StatelessWidget {
  const _Tips({required this.tips});

  /// (label, text) of each hint.
  final List<(String, String)> tips;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 14,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tips.length; i++) ...[
            if (i > 0)
              const SizedBox(
                height: 1,
                child: ColoredBox(color: AppColors.glassEdge),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tips[i].$1,
                    style: AppType.body(size: 12)
                        .copyWith(color: AppColors.text3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tips[i].$2,
                    style: AppType.body(size: 13.5)
                        .copyWith(color: AppColors.text2),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Cars nearby" over the list of cars, with the searching ring at the end.
class _NearbyHeading extends StatelessWidget {
  const _NearbyHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AppType.body(size: 12).copyWith(color: AppColors.text3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // The "Searching" under the name says what it is.
          const RingSpinner(),
        ],
      ),
    );
  }
}

/// A dark disc with the amber symbol of Bluetooth crossed out, over the car.
class _BluetoothGlyph extends StatelessWidget {
  const _BluetoothGlyph();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bg.withValues(alpha: 0.9),
          border: Border.all(color: AppColors.glassEdge),
        ),
        child: const SizedBox.square(
          dimension: 44,
          child: Icon(
            Icons.bluetooth_disabled,
            size: 20,
            color: AppColors.amber,
          ),
        ),
      ),
    );
  }
}

/// The tag "Connection lost" over the ghost car: a dark pill with an amber
/// outline and amber text.
class _LostTag extends StatelessWidget {
  const _LostTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.9),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppType.body(size: 12.5).copyWith(color: AppColors.amber),
        ),
      ),
    );
  }
}

/// The cells and the arrows of the cockpit switched off: the same grid as the
/// real ones, empty glass at half strength, with a dash where the value would
/// be. No finger and no screen reader reaches it.
class _SwitchedOff extends StatelessWidget {
  const _SwitchedOff({required this.columns, required this.pads});

  final int columns;
  final bool pads;

  static const double _radius = 16;

  Widget _box(Key key, double height, {bool dash = false}) => DecoratedBox(
    key: key,
    decoration: BoxDecoration(
      color: AppColors.glass,
      border: Border.all(color: AppColors.glassEdge),
      borderRadius: BorderRadius.circular(_radius),
    ),
    child: SizedBox(
      height: height,
      child: dash
          ? const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 12),
                child: SizedBox(
                  width: 12,
                  height: 1.5,
                  child: ColoredBox(color: AppColors.text3),
                ),
              ),
            )
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) {
    const cells = 4;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var start = 0; start < cells; start += columns) ...[
                if (start > 0) const SizedBox(height: StateCells.gap),
                Row(
                  children: [
                    for (var i = 0; i < columns; i++) ...[
                      if (i > 0) const SizedBox(width: StateCells.gap),
                      Expanded(
                        child: start + i < cells
                            ? _box(
                                LostView.cellKey,
                                StateCells.minHeight,
                                dash: true,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ],
              if (pads) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: TouchPads.gap),
                      Expanded(child: _box(LostView.padKey, TouchPads.height)),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
