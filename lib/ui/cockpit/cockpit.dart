import 'package:flutter/material.dart';

import '../../core/driver.dart';
import '../common/ambient.dart';
import '../garage/car_list.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'cockpit_header.dart';
import 'instrument.dart';
import 'key_legend.dart';
import 'particles.dart';
import 'state_cells.dart';
import 'touch_pads.dart';

/// The cockpit, the first screen of the app (spec 5.2): the header, and under
/// it what the state of the link asks for.
///
/// With a car connected it is the instrument (steering gauge, car and throttle
/// scale), the four state cells and, depending on the layout, the arrow pads
/// and the key legend, over the ambient light and with the dust of spec 4.7
/// behind all of it. Spec 6 sets the arrangement by the size of the window:
/// - phone: one column, the cells in a 2 by 2 grid, the arrows full width;
/// - tablet: the same with a larger instrument, the cells in one row of four
///   and the arrows at most 480 wide, centred;
/// - landscape (a screen at least 600 wide and under 500 high): the instrument
///   on the left and, on the right, the cells (2 by 2) and the arrows;
/// - desktop: the cells in one row of four, the arrows (only with the on-screen
///   controls on) and the key legend (only with the keyboard on), under the
///   instrument. The garage is the column beside it, not part of this widget.
///
/// On a short screen the cells and the arrows keep their size and the
/// instrument shrinks. The cells are buttons everywhere but on the desktop,
/// where they are only with the on-screen controls on.
///
/// Without a car connected the cockpit shows the header and, except on the
/// desktop where the garage column lists the cars, the list of cars in the
/// middle; the screens for each of those states come later.
///
/// [onSettings] opens the settings. [onCarTap] is for the layouts without a
/// garage column: it makes the name in the header open the sheet of cars.
///
/// The cockpit paints its own background and fills the space it is given.
class Cockpit extends StatefulWidget {
  const Cockpit({super.key, required this.onSettings, this.onCarTap});

  final VoidCallback onSettings;
  final VoidCallback? onCarTap;

  @override
  State<Cockpit> createState() => _CockpitState();
}

/// What is different in each layout.
class _Metrics {
  const _Metrics({
    required this.header,
    required this.body,
    required this.minimum,
    this.maxInstrument = double.infinity,
    this.maxPads = double.infinity,
  });

  /// Space at the sides of the header, and of the cells and arrows.
  final EdgeInsets header;
  final EdgeInsets body;

  /// Least space kept at the top and bottom of the window, where the system
  /// bars do not already leave it.
  final EdgeInsets minimum;

  /// Largest side of the instrument, and widest the row of arrows gets.
  final double maxInstrument;
  final double maxPads;

  static const _phone = _Metrics(
    header: EdgeInsets.symmetric(horizontal: 24),
    body: EdgeInsets.symmetric(horizontal: 18),
    minimum: EdgeInsets.only(top: 24, bottom: 20),
  );

  static const _tablet = _Metrics(
    header: EdgeInsets.symmetric(horizontal: 32),
    body: EdgeInsets.symmetric(horizontal: 32),
    minimum: EdgeInsets.only(top: 24, bottom: 20),
    maxInstrument: 480,
    maxPads: 480,
  );

  static const _landscape = _Metrics(
    header: EdgeInsets.symmetric(horizontal: 24),
    body: EdgeInsets.symmetric(horizontal: 24),
    minimum: EdgeInsets.only(top: 24, bottom: 20),
  );

  // The approved desktop design: 36 on the left, 28 on the right.
  static const _desktop = _Metrics(
    header: EdgeInsets.fromLTRB(36, 0, 28, 0),
    body: EdgeInsets.fromLTRB(36, 0, 28, 0),
    minimum: EdgeInsets.only(top: 28, bottom: 28),
    maxInstrument: 440,
    maxPads: 480,
  );

  static _Metrics of(LayoutKind kind) => switch (kind) {
    LayoutKind.phone => _phone,
    LayoutKind.tablet => _tablet,
    LayoutKind.landscape => _landscape,
    LayoutKind.desktop => _desktop,
  };
}

class _CockpitState extends State<Cockpit> {
  /// The particle field: the space the dust lives in.
  final GlobalKey _field = GlobalKey();

  /// The square of the instrument.
  final GlobalKey _frame = GlobalKey();

  /// The square of the instrument in the coordinates of the particle field, or
  /// null while either one is not laid out. The dust asks for it at each frame,
  /// so it follows a turn of the screen or a new size with no help.
  Rect? _frameInField() {
    final frame = _frame.currentContext?.findRenderObject();
    final field = _field.currentContext?.findRenderObject();
    if (frame is! RenderBox || field is! RenderBox) return null;
    if (!frame.attached || !field.attached) return null;
    if (!frame.hasSize || !field.hasSize) return null;
    return frame.localToGlobal(Offset.zero, ancestor: field) & frame.size;
  }

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final kind = layoutFor(MediaQuery.sizeOf(context));
    final metrics = _Metrics.of(kind);
    final connected = driver.link == LinkState.connected;
    final light = driver.command.light;

    final header = Padding(
      padding: metrics.header,
      child: CockpitHeader(
        onSettings: widget.onSettings,
        onCarTap: widget.onCarTap,
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        AmbientBackdrop(sweep: connected),
        // Between the light and the content, so the glass blurs it. It takes
        // its place in the list when there is no car too, so the content does
        // not change place in the tree.
        if (connected)
          ParticleField(
            key: _field,
            command: () => driver.command,
            carCenter: () {
              final frame = _frameInField();
              return frame == null
                  ? Offset.zero
                  : Instrument.carCenterIn(frame);
            },
            hero: () => _frameInField() ?? Rect.zero,
            beam: light
                ? () {
                    final frame = _frameInField();
                    return frame == null ? Rect.zero : Instrument.beamIn(frame);
                  }
                : null,
            count: kind == LayoutKind.desktop ? 150 : 95,
          )
        else
          const SizedBox.shrink(),
        SafeArea(
          minimum: metrics.minimum,
          child: Material(
            type: MaterialType.transparency,
            child: connected
                ? _connected(driver, kind, metrics, header)
                : _waiting(kind, metrics, header),
          ),
        ),
      ],
    );
  }

  Widget _connected(
    Driver driver,
    LayoutKind kind,
    _Metrics metrics,
    Widget header,
  ) {
    final desktop = kind == LayoutKind.desktop;
    final instrument = Instrument(
      frameKey: _frame,
      maxSide: metrics.maxInstrument,
    );
    final cells = StateCells(
      // The cells are buttons on the touch layouts. On the desktop they are
      // only with the on-screen controls on, which work by click.
      tappable: !desktop || driver.onScreenControls,
      columns: kind == LayoutKind.phone || kind == LayoutKind.landscape ? 2 : 4,
    );
    final pads = driver.onScreenControls ? const TouchPads() : null;

    if (kind == LayoutKind.landscape) {
      return Column(
        children: [
          header,
          const SizedBox(height: 6),
          Expanded(
            child: Padding(
              padding: metrics.body,
              child: Row(
                children: [
                  Expanded(flex: 5, child: instrument),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        // Short as the screen is, large text can make the
                        // cells and arrows taller than it: they scroll then.
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              cells,
                              if (pads != null) ...[
                                const SizedBox(height: 12),
                                pads,
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        header,
        const SizedBox(height: 6),
        // The only part that gives way when the screen is short. It sits on
        // the same axis as the cells and the arrows below it.
        Expanded(
          child: Padding(padding: metrics.body, child: instrument),
        ),
        Padding(
          padding: metrics.body.copyWith(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cells,
              if (pads != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: metrics.maxPads),
                    child: pads,
                  ),
                ),
              ],
              if (desktop && driver.keyboardEnabled) ...[
                const SizedBox(height: 16),
                const KeyLegend(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Everything but a connected car, until the screens for those states
  /// exist: the header and the cars, which the desktop already shows in the
  /// garage column.
  Widget _waiting(LayoutKind kind, _Metrics metrics, Widget header) {
    return Column(
      children: [
        header,
        Expanded(
          child: kind == LayoutKind.desktop
              ? const SizedBox.shrink()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: SingleChildScrollView(
                      padding: metrics.body.copyWith(top: 12, bottom: 12),
                      child: const CarList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
