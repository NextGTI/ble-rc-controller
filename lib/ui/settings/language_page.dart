import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../common/settings_row.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'page_frame.dart';

/// The codes the page offers, in order: the language of the system, then the
/// three the app speaks. `system` is what the `Driver` keeps in `localeCode`
/// when the app follows the system.
const List<String> languageCodes = ['system', 'pt', 'en', 'es'];

/// The name of the language [code] as its own speakers write it: "English" is
/// the same in every language of the app, so only "Sistema" is translated.
/// A code the app does not offer is the system's.
String languageName(AppLocalizations l, String code) => switch (code) {
  'pt' => 'Português',
  'en' => 'English',
  'es' => 'Español',
  _ => l.languageSystem,
};

/// The language of the app (spec 5.4): the system's, Português, English or
/// Español, with the current choice marked by an amber check.
///
/// Choosing one changes the language at once and stays on the page.
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    // A code the app does not know counts as "Sistema", as the page names it.
    final current = languageCodes.contains(driver.localeCode)
        ? driver.localeCode
        : languageCodes.first;

    return SettingsFrame(
      title: l.language,
      children: [
        SettingsCard(
          items: [
            for (final code in languageCodes)
              SettingsRow(
                title: languageName(l, code),
                trailing: _Mark(selected: code == current),
                onTap: () => driver.localeCode = code,
              ),
          ],
        ),
      ],
    );
  }
}

/// The check of the chosen row. The other rows keep the same room, so the
/// names do not move; to a screen reader every row says whether it is chosen.
class _Mark extends StatelessWidget {
  const _Mark({required this.selected});

  final bool selected;

  static const double _side = 22;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: SizedBox(
        width: _side,
        height: _side,
        child: selected
            ? const Icon(Icons.check, size: _side, color: AppColors.amber)
            : null,
      ),
    );
  }
}
