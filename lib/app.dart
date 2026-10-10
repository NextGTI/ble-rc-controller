import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/driver.dart';
import 'l10n/gen/app_localizations.dart';
import 'ui/home_page.dart';
import 'ui/strings.dart';

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
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          builder: (context, child) => DriverScope(driver: driver, child: child!),
          home: const HomePage(),
        );
      },
    );
  }

  /// Neutral surfaces with a red accent (the default seed tints every card pink).
  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD32F2F),
      brightness: b,
      dynamicSchemeVariant: DynamicSchemeVariant.neutral,
    ).copyWith(
      primary: dark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F),
      onPrimary: dark ? Colors.black : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
