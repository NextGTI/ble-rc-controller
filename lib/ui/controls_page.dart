import 'package:flutter/material.dart';

import '../core/protocol.dart';
import '../input/input_ref.dart';
import '../l10n/gen/app_localizations.dart';
import 'strings.dart';
import 'widgets.dart';

/// Lets the user decide which controller input or key triggers each action.
class ControlsPage extends StatelessWidget {
  const ControlsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final d = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(l.controlsIntro,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final a in CarAction.values) ...[
                _ActionRow(action: a),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l.useKeyboard),
                  value: d.keyboardEnabled,
                  onChanged: (v) => d.keyboardEnabled = v ?? true,
                ),
              ),
              TextButton(onPressed: d.resetBindings, child: Text(l.restoreDefaults)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});

  final CarAction action;

  @override
  Widget build(BuildContext context) {
    final d = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final capturing = d.capturing == action;
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.action(action), style: t.titleMedium),
                Text(l.actionHint(action), style: t.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
              ],
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final ref in d.bindings[action] ?? const <InputRef>[])
                  _BindingChip(
                    label: l.input(ref),
                    kind: ref.kind,
                    shared: d.actionsUsing(ref).length > 1,
                    sharedMessage: l.sharedInput,
                    removeLabel: l.remove,
                    onRemove: () => d.removeBinding(action, ref),
                  ),
                if (capturing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(l.pressAnything),
                      const SizedBox(width: 8),
                      InkWell(onTap: d.cancelCapture, child: Text(l.cancel, style: TextStyle(color: Theme.of(context).colorScheme.primary))),
                    ]),
                  )
                else
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(l.add),
                    onPressed: () => d.beginCapture(action),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BindingChip extends StatelessWidget {
  const _BindingChip({
    required this.label,
    required this.kind,
    required this.shared,
    required this.sharedMessage,
    required this.removeLabel,
    required this.onRemove,
  });

  final String label;
  final InputKind kind;
  final bool shared;
  final String sharedMessage;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      InputKind.pad => Icons.sports_esports_outlined,
      InputKind.key => Icons.keyboard_outlined,
      InputKind.raw => Icons.tune,
    };
    return InputChip(
      avatar: Icon(icon, size: 18),
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        if (shared) ...[
          const SizedBox(width: 4),
          Tooltip(message: sharedMessage, child: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange)),
        ],
      ]),
      deleteButtonTooltipMessage: removeLabel,
      onDeleted: onRemove,
    );
  }
}
