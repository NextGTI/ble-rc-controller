import 'package:flutter/material.dart';

import '../core/driver.dart';
import '../core/protocol.dart';
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
      final steer = Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _HoldButton(action: CarAction.left, icon: Icons.arrow_back_rounded, size: 84),
          SizedBox(width: 12),
          _HoldButton(action: CarAction.right, icon: Icons.arrow_forward_rounded, size: 84),
        ],
      );
      final pedals = Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _HoldButton(action: CarAction.reverse, icon: Icons.arrow_downward_rounded, size: 84),
          SizedBox(width: 12),
          _HoldButton(action: CarAction.forward, icon: Icons.arrow_upward_rounded, size: 84, primary: true),
        ],
      );
      final extras = Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _HoldButton(action: CarAction.light, icon: Icons.light_mode_outlined, label: l.actionLight, size: 64),
          _HoldButton(action: CarAction.turbo, icon: Icons.bolt_rounded, label: l.actionTurbo, size: 64),
          _HoldButton(action: CarAction.donut, icon: Icons.sync_rounded, label: l.actionDonut, size: 64),
          _HoldButton(action: CarAction.mode, icon: Icons.tune_rounded, label: l.actionMode, size: 64),
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
  });

  final CarAction action;
  final IconData icon;
  final double size;
  final String? label;
  final bool primary;

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
    _driver.setVirtual(widget.action, v);
  }

  @override
  void dispose() {
    // A button that disappears while held must not stay "pressed".
    if (_down) _driver.setVirtual(widget.action, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = widget.primary ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = widget.primary ? scheme.onPrimary : scheme.onSurface;
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _down ? scheme.tertiary : base,
        borderRadius: BorderRadius.circular(widget.size / 4),
        boxShadow: _down ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: widget.size * 0.42, color: _down ? scheme.onTertiary : fg),
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                widget.label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: _down ? scheme.onTertiary : fg),
              ),
            ),
        ],
      ),
    );
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: tile,
    );
  }
}
