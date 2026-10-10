import 'package:flutter/material.dart';

import 'tokens.dart';

/// The app's only theme: dark, with amber as the accent (spec 3.1).
ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.amber,
    onPrimary: AppColors.bg,
    secondary: AppColors.text2,
    onSecondary: AppColors.bg,
    surface: AppColors.bg,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.text2,
    outline: AppColors.trace,
    outlineVariant: AppColors.traceWeak,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: AppType.family,
    textTheme: _textTheme(),
  );
}

/// Sizes from the type table in spec 3.2. Phone / desktop pairs take two slots.
TextTheme _textTheme() {
  return TextTheme(
    displayLarge: AppType.numeric(size: 56), // car name, desktop
    displayMedium: AppType.numeric(size: 44), // battery, desktop
    displaySmall: AppType.numeric(size: 42), // car name, phone
    headlineLarge: AppType.numeric(size: 36), // battery, phone
    headlineMedium: AppType.numeric(size: 28), // screen title
    headlineSmall: AppType.numeric(size: 26), // state message
    titleLarge: AppType.numeric(size: 22), // state message, compact
    titleMedium: AppType.body(size: 15), // row text
    titleSmall: AppType.body(size: 13.5),
    bodyLarge: AppType.body(size: 15),
    bodyMedium: AppType.body(size: 13.5),
    bodySmall: AppType.body(size: 12),
    labelLarge: AppType.body(size: 13.5),
    labelMedium: AppType.body(size: 12), // label and hint
    labelSmall: AppType.body(size: 10.5),
  ).apply(bodyColor: AppColors.text, displayColor: AppColors.text);
}
