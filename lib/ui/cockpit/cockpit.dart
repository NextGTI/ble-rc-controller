import 'package:flutter/material.dart';

import '../../core/driver.dart';
import '../common/ambient.dart';
import '../common/glass.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'cockpit_header.dart';
import 'cockpit_metrics.dart';
import 'cockpit_states.dart';
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
/// - landscape (wider than tall and under 500 high, a phone turned sideways of
///   any width): the instrument on the left and, on the right, the cells (2 by
///   2) and the arrows;
/// - desktop (900 or more wide): the cells in one row of four, the arrows (only
///   with the on-screen controls on) and the key legend under the instrument.
///   The garage is the column beside it, not part of this widget.
///
/// The key legend belongs to the platform, not to the width: it is there on a
/// computer with "Use the keyboard" on, and never on an Android tablet that
/// has the desktop layout because it is wide.
///
/// On a short screen the cells and the arrows keep their size and the
/// instrument shrinks. The cells are buttons everywhere but on the desktop,
/// where they are only with the on-screen controls on.
///
/// Without a car connected the middle of the cockpit is one of the screens of
/// `cockpit_states.dart`, chosen by `panelStateOf` in the order of spec 5.2:
/// Bluetooth not ready, connecting, connected (the instrument above), waiting
/// to reconnect, and searching. The header names the same state, because it asks the same
/// function.
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
    final metrics = CockpitMetrics.of(kind);
    final panel = panelStateOf(driver);
    final connected = panel == PanelState.connected;
    final light = driver.command.light;

    final header = Padding(
      padding: metrics.header,
      child: CockpitHeader(
        onSettings: widget.onSettings,
        onCarTap: widget.onCarTap,
      ),
    );

    // The cells and arrows (and the glass of the state screens) blur the same
    // backdrop: once for all of them, not once each on every frame.
    return GlassGroup(
      child: Stack(
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
                      return frame == null
                          ? Rect.zero
                          : Instrument.beamIn(frame);
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
              child: _content(panel, driver, kind, metrics, header),
            ),
          ),
        ],
      ),
    );
  }

  Widget _connected(
    Driver driver,
    LayoutKind kind,
    CockpitMetrics metrics,
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
      columns: metrics.cellColumns,
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
              // The legend is for a keyboard in the hands: a computer, not an
              // Android tablet with the desktop layout.
              if (isDesktopPlatform && driver.keyboardEnabled) ...[
                const SizedBox(height: 16),
                const KeyLegend(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// What fills the cockpit for [panel]: the connected cockpit, or the header
  /// over the screen of the state.
  Widget _content(
    PanelState panel,
    Driver driver,
    LayoutKind kind,
    CockpitMetrics metrics,
    Widget header,
  ) {
    final Widget view;
    switch (panel) {
      case PanelState.connected:
        return _connected(driver, kind, metrics, header);
      case PanelState.bluetooth:
        view = BluetoothView(bluetoothBlockOf(driver)!);
      case PanelState.connecting:
        view = const ConnectingView();
      case PanelState.lost:
        view = const LostView();
      case PanelState.searching:
        view = const SearchingView();
    }
    return Column(
      children: [
        header,
        Expanded(child: view),
      ],
    );
  }
}
