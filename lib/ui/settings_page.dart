import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import 'strings.dart';
import 'widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final d = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.settingsTitle, style: t.headlineSmall),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.language, style: t.titleSmall),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'system', label: Text(l.languageSystem)),
                  const ButtonSegment(value: 'en', label: Text('English')),
                  const ButtonSegment(value: 'es', label: Text('Español')),
                  const ButtonSegment(value: 'pt', label: Text('Português')),
                ],
                selected: {d.localeCode},
                onSelectionChanged: (s) => d.localeCode = s.first,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.deadzone((d.deadzone * 100).round()), style: t.titleSmall),
              Slider(
                value: d.deadzone,
                min: 0.1,
                max: 0.7,
                onChanged: (v) => d.deadzone = v,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.onScreen),
                subtitle: Text(l.onScreenHint),
                value: d.onScreenControls,
                onChanged: (v) => d.onScreenControls = v,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.useKeyboard),
                value: d.keyboardEnabled,
                onChanged: (v) => d.keyboardEnabled = v,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.rememberLast),
                value: d.autoConnect,
                onChanged: (v) => d.autoConnect = v,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.about, style: t.titleSmall),
              const SizedBox(height: 8),
              Text(l.disclaimer, style: t.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
            ],
          ),
        ),
      ],
    );
  }
}
