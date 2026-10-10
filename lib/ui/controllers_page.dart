import 'package:flutter/material.dart';

import '../input/controller_profile.dart';
import '../input/pad_input.dart';
import '../l10n/gen/app_localizations.dart';
import 'strings.dart';
import 'widgets.dart';

/// Detected controllers, custom mapping for unknown ones, and a live monitor.
class ControllersPage extends StatelessWidget {
  const ControllersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final d = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;

    if (d.teaching != null) return _TeachWizard(session: d.teaching!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.controllersTitle, style: t.headlineSmall),
        const SizedBox(height: 12),
        if (d.controllers.isEmpty)
          SectionCard(
            child: Row(children: [
              Icon(Icons.sports_esports, size: 36, color: Theme.of(context).hintColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.noController, style: t.titleMedium),
                  Text(l.noControllerHint, style: t.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
                ]),
              ),
            ]),
          ),
        for (final c in d.controllers) ...[
          _ControllerCard(info: c),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        _Monitor(),
      ],
    );
  }
}

class _ControllerCard extends StatelessWidget {
  const _ControllerCard({required this.info});

  final ControllerInfo info;

  @override
  Widget build(BuildContext context) {
    final d = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final custom = d.profiles[info.profileKey]?.isCustom ?? false;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.sports_esports, color: Colors.blue, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(info.name, style: t.titleMedium),
                Text(custom ? l.controllerCustom : l.controllerRecognised,
                    style: t.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.school_outlined),
              label: Text(l.teachController),
              onPressed: () => d.beginTeaching(info),
            ),
            if (custom)
              OutlinedButton(
                onPressed: () => d.forgetProfile(info.profileKey),
                child: Text(l.forgetMapping),
              ),
          ]),
        ],
      ),
    );
  }
}

/// Live view: standard inputs that are pressed, and every raw signal seen.
class _Monitor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final d = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.monitor_heart_outlined),
        title: Text(l.inputMonitor),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.monitorHint, style: t.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: d.rawRevision,
            builder: (context, _, _) {
              final pressed = d.pressedPad;
              final signals = d.rawSignals.values.toList()..sort((a, b) => a.key.compareTo(b.key));
              if (signals.isEmpty) return Text(l.monitorEmpty);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final p in PadInput.values)
                      if (pressed.contains(p)) Chip(label: Text(l.pad(p)), visualDensity: VisualDensity.compact),
                  ]),
                  const SizedBox(height: 8),
                  for (final s in signals)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text(s.key, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                        Expanded(
                          flex: 2,
                          child: LinearProgressIndicator(value: ((s.value + 1) / 2).clamp(0.0, 1.0)),
                        ),
                        SizedBox(width: 56, child: Text(s.value.toStringAsFixed(2), textAlign: TextAlign.end)),
                      ]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TeachWizard extends StatelessWidget {
  const _TeachWizard({required this.session});

  final TeachSession session;

  @override
  Widget build(BuildContext context) {
    final d = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final total = teachSteps.length;
    final finished = session.finished;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.teachTitle, style: t.headlineSmall),
        const SizedBox(height: 4),
        Text(session.profile.name, style: t.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
        const SizedBox(height: 12),
        SectionCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (finished) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 12),
                Text(l.teachDone, style: t.titleLarge),
                const SizedBox(height: 20),
                FilledButton(onPressed: d.finishTeaching, child: Text(l.done)),
              ] else ...[
                Text(l.teachProgress(session.index + 1, total), style: t.labelLarge),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: session.index / total),
                const SizedBox(height: 24),
                Text(l.teach(session.current.id), style: t.headlineSmall),
                const SizedBox(height: 8),
                Text(l.teachIntro, style: t.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
                const SizedBox(height: 20),
                Row(children: [
                  OutlinedButton(onPressed: d.skipTeachStep, child: Text(l.skip)),
                  const SizedBox(width: 8),
                  TextButton(onPressed: d.cancelTeaching, child: Text(l.cancel)),
                ]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
