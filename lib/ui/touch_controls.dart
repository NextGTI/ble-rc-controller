import 'package:flutter/material.dart';

import '../core/driver.dart';
import '../core/protocol.dart';
import 'motion.dart';
import 'strings.dart';
import '../l10n/gen/app_localizations.dart';

/// On-screen controls for phones, tablets and mouse users. Every button
/// reports "down" on pointer-down and "up" on pointer-up/cancel, so several
/// can be held at once (multi-touch).
class TouchControls extends StatelessWidget {
  const TouchControls({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return LayoutBuilder(builder: (context, c) {
      final narrow = c.maxWidth < 520;
      // On phones four big buttons share one row, so size them to fit the
      // available width (a 360 dp phone has only ~328 dp inside the margins).
      final big = narrow ? ((c.maxWidth - 36) / 4).clamp(52.0, 84.0) : 84.0;
      final small = ((c.maxWidth - 24) / 4).clamp(48.0, 64.0);
      final steer = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HoldButton(action: CarAction.left, icon: Icons.arrow_back_rounded, size: big),
          const SizedBox(width: 12),
          _HoldButton(action: CarAction.right, icon: Icons.arrow_forward_rounded, size: big),
        ],
      );
      final pedals = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HoldButton(action: CarAction.reverse, icon: Icons.arrow_downward_rounded, size: big),
          const SizedBox(width: 12),
          _HoldButton(action: CarAction.forward, icon: Icons.arrow_upward_rounded, size: big, primary: true),
        ],
      );
      final extras = Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _HoldButton(action: CarAction.light, icon: Icons.light_mode_outlined, label: l.actionLight, size: small),
          _HoldButton(action: CarAction.turbo, icon: Icons.bolt_rounded, label: l.actionTurbo, size: small, latch: true),
          _HoldButton(action: CarAction.donut, icon: Icons.sync_rounded, label: l.actionDonut, size: small, latch: true),
        ],
      );
      if (narrow) {
        return Column(children: [
          extras,
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [steer, pedals]),
        ]);
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [steer, Flexible(child: extras), pedals],
      );
    });
  }
}

class _HoldButton extends StatefulWidget {
  const _HoldButton({
    required this.action,
    required this.icon,
    required this.size,
    this.label,
    this.primary = false,
    this.latch = false,
  });

  final CarAction action;
  final IconData icon;
  final double size;
  final String? label;
  final bool primary;

  /// A tap switches the action on and it stays on until tapped again, instead
  /// of lasting only while the finger is down.
  final bool latch;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _down = false;
  late Driver _driver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _driver = DriverScope.of(context);
  }

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    if (widget.latch) {
      if (v) _driver.toggleLatched(widget.action);
    } else {
      _driver.setVirtual(widget.action, v);
    }
  }

  @override
  void dispose() {
    // A button that disappears while held must not stay "pressed".
    if (_down && !widget.latch) _driver.setVirtual(widget.action, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = widget.primary ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = widget.primary ? scheme.onPrimary : scheme.onSurface;
    // A latched button stays lit while on; the others only while touched.
    final active = widget.latch ? _driver.isLatched(widget.action) : _down;
    final tile = AnimatedContainer(
      duration: motion(context, 70),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: active ? scheme.tertiary : base,
        borderRadius: BorderRadius.circular(widget.size / 4),
        boxShadow: active ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: widget.size * 0.42, color: active ? scheme.onTertiary : fg),
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                widget.label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: active ? scheme.onTertiary : fg),
              ),
            ),
        ],
      ),
    );
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(scale: _down ? .93 : 1, duration: motion(context, 80), curve: Curves.easeOut, child: tile),
    );
  }
}
