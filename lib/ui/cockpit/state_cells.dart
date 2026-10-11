import 'package:flutter/widgets.dart';

import '../../core/protocol.dart';
import '../../input/bindings.dart';
import '../../input/pad_input.dart';
import '../../l10n/gen/app_localizations.dart';
import '../common/glass.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'touch_pads.dart';

/// The symbol of a controller input in the cells (spec 4.4).
///
/// The DualShock 4 is the reference controller, so the face buttons are the
/// PlayStation shapes (the standard `a` is the bottom button, ✕), the shoulder
/// and stick buttons are L1/R1, L2/R2, L3/R3, and a stick direction is the
/// stick's letter and an arrow ("L ↑").
String padGlyph(PadInput p) {
  switch (p) {
    case PadInput.a:
      return '✕';
    case PadInput.b:
      return '○';
    case PadInput.x:
      return '□';
    case PadInput.y:
      return '△';
    case PadInput.leftBumper:
      return 'L1';
    case PadInput.rightBumper:
      return 'R1';
    case PadInput.leftTrigger:
      return 'L2';
    case PadInput.rightTrigger:
      return 'R2';
    case PadInput.back:
      return 'Share';
    case PadInput.start:
      return 'Options';
    case PadInput.home:
      return 'PS';
    case PadInput.leftStick:
      return 'L3';
    case PadInput.rightStick:
      return 'R3';
    case PadInput.touchpad:
      return 'Touchpad';
    case PadInput.dpadUp:
      return '↑';
    case PadInput.dpadDown:
      return '↓';
    case PadInput.dpadLeft:
      return '←';
    case PadInput.dpadRight:
      return '→';
    case PadInput.leftStickUp:
      return 'L ↑';
    case PadInput.leftStickDown:
      return 'L ↓';
    case PadInput.leftStickLeft:
      return 'L ←';
    case PadInput.leftStickRight:
      return 'L →';
    case PadInput.rightStickUp:
      return 'R ↑';
    case PadInput.rightStickDown:
      return 'R ↓';
    case PadInput.rightStickLeft:
      return 'R ←';
    case PadInput.rightStickRight:
      return 'R →';
  }
}

/// What a cell shows as the shortcut of [a] (spec 4.4, 7.6): the first
/// controller input bound to it, as a [padGlyph]; a signal the app did not
/// recognise, the way the settings write it; and, with no controller input,
/// the first key. Null when [a] has no input at all.
String? shortcutSymbol(AppLocalizations l, Bindings b, CarAction a) {
  final pad = firstPadInput(b, a);
  if (pad != null) {
    final p = pad.padInput;
    return p == null ? l.input(pad) : padGlyph(p);
  }
  final keys = keyInputs(b, a);
  return keys.isEmpty ? null : l.keyName(keys.first);
}

/// The glass grid with the four states of the car (spec 4.4): Light, Turbo,
/// 360° spin and the controller in use. Each cell has a small name, the
/// shortcut of its action and the value; an active cell is amber.
///
/// The cells read the command the car is getting, so they follow the
/// controller and the keyboard as well as the screen.
///
/// With [tappable] (phone and tablet) the three action cells are buttons
/// (spec 4.5): a tap on Light switches the light, and a tap on Turbo or on
/// 360° spin latches it on until the next tap. The Controller cell is never a
/// button.
///
/// [columns] cells fit in a row: 2 gives a 2 by 2 grid, 4 a single row.
class StateCells extends StatelessWidget {
  const StateCells({super.key, required this.tappable, this.columns = 2})
    : assert(columns > 0);

  final bool tappable;
  final int columns;

  /// Smallest height of a cell.
  static const double minHeight = 56;

  /// Space between cells, across and down.
  static const double gap = 8;

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final command = driver.command;
    final controllers = driver.controllers;

    String symbolOf(CarAction a) => shortcutSymbol(l, driver.bindings, a) ?? '';

    final cells = <Widget>[
      _Cell(
        label: l.action(CarAction.light),
        symbol: symbolOf(CarAction.light),
        value: command.light ? l.lightOn : l.lightOff,
        active: command.light,
        press: tappable ? _Press.hold : _Press.none,
        action: CarAction.light,
      ),
      _Cell(
        label: l.action(CarAction.turbo),
        symbol: symbolOf(CarAction.turbo),
        value: command.turbo ? l.turboOn : l.turboOff,
        active: command.turbo,
        press: tappable ? _Press.latch : _Press.none,
        action: CarAction.turbo,
      ),
      _Cell(
        label: l.action(CarAction.donut),
        symbol: symbolOf(CarAction.donut),
        value: command.donut ? l.spinOn : l.spinOff,
        active: command.donut,
        press: tappable ? _Press.latch : _Press.none,
        action: CarAction.donut,
      ),
      _Cell(
        label: l.cellController,
        symbol: '',
        value: controllers.isEmpty
            ? l.noControllerShort
            : controllers.first.name,
        active: false,
        press: _Press.none,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var start = 0; start < cells.length; start += columns) ...[
          if (start > 0) const SizedBox(height: gap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < columns; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                // A short last row keeps the width of the cells above it.
                Expanded(
                  child: start + i < cells.length
                      ? cells[start + i]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// How a cell reacts to a finger.
enum _Press {
  /// It does not.
  none,

  /// A press and a release, the way a button of the controller does it: the
  /// driver flips the light on the press.
  hold,

  /// A press switches the action on, and it stays on until the next press.
  latch,
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.symbol,
    required this.value,
    required this.active,
    required this.press,
    this.action,
  }) : assert(press == _Press.none || action != null);

  final String label;

  /// The shortcut, or empty for none.
  final String symbol;
  final String value;
  final bool active;
  final _Press press;
  final CarAction? action;

  static const EdgeInsets _padding = EdgeInsets.fromLTRB(12, 11, 12, 10);

  @override
  Widget build(BuildContext context) {
    // The halo of an active glass is for the value; the small texts keep none.
    final small = AppType.body(size: 11)
        .copyWith(color: AppColors.text3, shadows: const []);
    final valueStyle = AppType.body(size: 15)
        .copyWith(color: active ? null : AppColors.text2);

    final text = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: valueStyle,
    );

    final glass = Glass(
      active: active,
      radius: 16,
      padding: _padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: StateCells.minHeight - _padding.vertical,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small,
                  ),
                ),
                if (symbol.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(symbol, maxLines: 1, style: small),
                ],
              ],
            ),
            const SizedBox(height: 3),
            text,
          ],
        ),
      ),
    );

    Widget face = glass;
    VoidCallback? onTap;
    if (press != _Press.none) {
      final driver = DriverScope.of(context);
      final a = action!;
      if (press == _Press.hold) {
        // Reached from a screen reader: one press and release.
        onTap = () {
          driver.setVirtual(a, true);
          driver.setVirtual(a, false);
        };
        face = HoldRegion(action: a, builder: (context, held) => glass);
      } else {
        onTap = () => driver.toggleLatched(a);
        face = Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => driver.toggleLatched(a),
          child: glass,
        );
      }
    }

    return Semantics(
      container: true,
      button: press != _Press.none,
      label: '$label, $value',
      onTap: onTap,
      excludeSemantics: true,
      child: face,
    );
  }
}
