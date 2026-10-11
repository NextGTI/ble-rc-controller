import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/l10n/gen/app_localizations.dart';
import 'package:ble_rc_controller/ui/cockpit/particles.dart';
import 'package:ble_rc_controller/ui/strings.dart';
import 'package:ble_rc_controller/ui/theme/theme.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mounts [child] the way the app does, for the widget tests of every screen.
///
/// - The window is [size] logical pixels at a device pixel ratio of 1, and goes
///   back to normal when the test ends.
/// - The app theme, the three delegates of l10n and the language [locale].
/// - [DriverScope] holding [d].
/// - `EffectsScope(particles: false)`, so no decorative animation keeps frames
///   scheduled. A test that wants them puts its own `EffectsScope` around the
///   widget.
/// - `MediaQuery.disableAnimations` set to [reduceMotion].
///
/// [child] sits at the top centre, on a `Material` painted with the background
/// colour (so ink, default text style and the like work), and gets loose
/// constraints: a small widget keeps its own size, a screen that fills its
/// parent still fills the window.
Future<void> pumpWithDriver(
  WidgetTester t,
  Driver d,
  Widget child, {
  Size size = const Size(390, 844),
  String locale = 'pt',
  bool reduceMotion = false,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: Locale(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: DriverScope(
          driver: d,
          child: EffectsScope(particles: false, child: app!),
        ),
      ),
      home: Material(
        color: AppColors.bg,
        child: Align(alignment: Alignment.topCenter, child: child),
      ),
    ),
  );
}
