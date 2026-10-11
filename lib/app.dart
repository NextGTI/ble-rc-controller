import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/driver.dart';
import 'l10n/gen/app_localizations.dart';
import 'ui/shell.dart';
import 'ui/strings.dart';
import 'ui/theme/theme.dart';

class BleRcApp extends StatelessWidget {
  const BleRcApp({super.key, required this.driver});

  final Driver driver;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: driver,
      builder: (context, _) {
        final code = driver.localeCode;
        return MaterialApp(
          onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
          debugShowCheckedModeBanner: false,
          locale: code == 'system' ? null : Locale(code),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // One theme, dark (spec 3.1): no light theme and no darkTheme, so
          // the system's brightness changes nothing.
          theme: buildAppTheme(),
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: appSystemBars,
            child: DriverScope(driver: driver, child: child!),
          ),
          home: const Shell(),
        );
      },
    );
  }
}
