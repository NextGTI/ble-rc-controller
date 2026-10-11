import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/driver.dart';
import '../../core/protocol.dart';
import '../../input/input_ref.dart';
import '../../l10n/gen/app_localizations.dart';
import '../cockpit/particles.dart';
import '../cockpit/state_cells.dart';
import '../common/amber_switch.dart';
import '../common/glass.dart';
import '../common/input_tag.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'page_frame.dart';

/// What each input does (spec 5.5): the seven actions in one glass card, each
/// with how it works, its inputs as tags and "+ Adicionar". Under the list, a
/// strip that does not scroll holds "Usar o teclado" and "Restaurar padrão".
///
/// "Adicionar" makes the driver wait for an input (`beginCapture`); the action
/// that waits turns amber, with a pulsing dot, "Aperte o que vai acionar ..."
/// and "Cancelar". The driver ends the wait when it learns an input, so the
/// page only shows what the driver says.
///
/// A controller input is written with the symbol the cells of the panel use
/// (`padGlyph`), a key by its name, a signal the app does not know the way the
/// cells write it.
///
/// A wait for an input belongs to the page: while it lasts the driver takes
/// every key and controller input for itself and sends the car neutral. So the
/// page ends it on every way out (the back chevron, the system back, the panel
/// of the desktop closed by its scrim), the way the teach wizard ends its
/// session. Left open, the cockpit would stay dead and the next key pressed
/// would be bound to the action.
class BindingsPage extends StatefulWidget {
  const BindingsPage({super.key});

  @override
  State<BindingsPage> createState() => _BindingsPageState();
}

class _BindingsPageState extends State<BindingsPage> {
  Driver? _driver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _driver = DriverScope.of(context);
  }

  /// Ends the wait for an input, if there is one.
  void _endCapture() {
    final driver = _driver;
    if (driver != null && driver.capturing != null) driver.cancelCapture();
  }

  @override
  void dispose() {
    // A page that is taken off the screen without being popped (the panel is
    // closed from outside) ends the wait too. Not now: the tree is locked and
    // the driver would tell it to rebuild.
    if (_driver?.capturing != null) scheduleMicrotask(_endCapture);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // A computer clicks; a phone or a tablet touches, whatever its width.
    final clicks = isDesktopPlatform;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _endCapture();
      },
      child: SettingsFrame(
        title: l.bindingsTitle,
        footer: const _Footer(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              clicks ? l.bindingsLeadClick : l.bindingsLeadTouch,
              style: AppType.body(size: 13.5)
                  .copyWith(color: AppColors.text2, height: 1.5),
            ),
          ),
          SettingsCard(
            items: [
              for (final a in CarAction.values)
                _ActionBlock(key: ValueKey<CarAction>(a), action: a),
            ],
          ),
        ],
      ),
    );
  }
}

/// How one input is written on its tag.
String _tagLabel(AppLocalizations l, InputRef ref) {
  final pad = ref.padInput;
  return pad == null ? l.input(ref) : padGlyph(pad);
}

/// One action: its name and how it works, then its tags and the way to add
/// one; or, while the driver waits for an input for it, the request.
class _ActionBlock extends StatelessWidget {
  const _ActionBlock({super.key, required this.action});

  final CarAction action;

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final capturing = driver.capturing == action;
    final name = l.action(action);

    return _WaitFrame(
      active: capturing,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 9, 13, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    name,
                    style: AppType.body(size: 15)
                        .copyWith(color: AppColors.text),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.actionHint(action),
                      textAlign: TextAlign.end,
                      style: AppType.body(size: 12)
                          .copyWith(color: AppColors.text3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final ref in driver.bindings[action] ?? const <InputRef>[])
                  InputTag(
                    label: _tagLabel(l, ref),
                    kind: ref.kind,
                    shared: driver.actionsUsing(ref).length > 1,
                    onRemove: () => driver.removeBinding(action, ref),
                  ),
                // While it waits, the request below takes the place of this.
                if (!capturing)
                  _AddChip(
                    label: '+ ${l.add}',
                    semanticLabel: '${l.add} $name',
                    onTap: () => driver.beginCapture(action),
                  ),
              ],
            ),
            if (capturing)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const _PulseDot(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        container: true,
                        liveRegion: true,
                        child: Text(
                          l.captureWaiting(name),
                          style: AppType.body(size: 13.5)
                              .copyWith(color: AppColors.amber),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: driver.cancelCapture,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.text2,
                        textStyle: AppType.body(size: 13.5),
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      child: Text(l.cancel),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The frame that lights amber (border and soft fill) around the action that
/// waits for an input, and fades back when it stops. Without [active] it is
/// invisible and takes the same room, so the list does not move.
class _WaitFrame extends StatelessWidget {
  const _WaitFrame({required this.active, required this.child});

  final bool active;
  final Widget child;

  static final Color _edge = AppColors.amber.withValues(alpha: 0.35);
  static final Color _top = AppColors.amber.withValues(alpha: 0.08);
  static final Color _bottom = AppColors.amber.withValues(alpha: 0.02);

  @override
  Widget build(BuildContext context) {
    // Both looks are gradients and borders of the same shape, so the change
    // between them is one smooth fade.
    return Padding(
      padding: const EdgeInsets.all(3),
      child: AnimatedContainer(
        duration: Glass.timeOf(context),
        curve: Glass.curve,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: active
                ? [_top, _bottom]
                : [_top.withValues(alpha: 0), _bottom.withValues(alpha: 0)],
          ),
          border: Border.all(
            color: active ? _edge : _edge.withValues(alpha: 0),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      ),
    );
  }
}

/// The dot that pulses while an input is awaited: it fades to a quarter and
/// shrinks to 80% and back in 1.2 s. It stands still, lit, with the system's
/// "reduce motion" on and where the decorative effects are off.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !EffectsScope.particlesOf(context)) {
      _beat.stop();
      _beat.value = 0;
    } else if (!_beat.isAnimating) {
      _beat.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eased = CurvedAnimation(parent: _beat, curve: Curves.easeInOut);
    return ExcludeSemantics(
      child: SizedBox(
        width: 10,
        height: 10,
        child: Center(
          child: RepaintBoundary(
            child: FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0.25).animate(eased),
              child: ScaleTransition(
                scale: Tween<double>(begin: 1, end: 0.8).animate(eased),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.amber, blurRadius: 8),
                    ],
                  ),
                  child: const SizedBox(width: 7, height: 7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "+ Adicionar": a pill with a dashed outline, 48 high. To a screen reader it
/// says which action it adds to.
class _AddChip extends StatelessWidget {
  const _AddChip({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(InputTag.target / 2),
          child: CustomPaint(
            painter: const _DashedPill(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: InputTag.target,
                minHeight: InputTag.target,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    style: AppType.body(size: 13.5)
                        .copyWith(color: AppColors.text2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A rounded outline made of short dashes.
class _DashedPill extends CustomPainter {
  const _DashedPill();

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.traceWeak;
    for (final metric in outline.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += _dash + _gap) {
        canvas.drawPath(metric.extractPath(at, at + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPill oldDelegate) => false;
}

/// The strip under the list: "Usar o teclado" with its switch, and "Restaurar
/// padrão". It does not scroll with the actions. On a narrow screen the second
/// goes to its own line.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    return Glass(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            // The switch has no name of its own: it is read with its label.
            MergeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      l.useKeyboard,
                      style: AppType.body(size: 15)
                          .copyWith(color: AppColors.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AmberSwitch(
                    value: driver.keyboardEnabled,
                    onChanged: (v) => driver.keyboardEnabled = v,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: driver.resetBindings,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.amber,
                textStyle: AppType.body(size: 13.5),
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Text(l.restoreDefaults),
            ),
          ],
        ),
      ),
    );
  }
}
