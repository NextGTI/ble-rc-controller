import 'dart:io';

import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/l10n/gen/app_localizations.dart';
import 'package:ble_rc_controller/ui/cockpit/particles.dart';
import 'package:ble_rc_controller/ui/strings.dart';
import 'package:ble_rc_controller/ui/theme/theme.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_transport.dart';

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

/// Teaches the test font the real Saira, so the widths and heights a screen
/// works with are the ones the app has (without it every glyph is a square of
/// Ahem). Call it from `setUpAll`.
Future<void> loadSaira() async {
  final bytes = File('assets/fonts/Saira-Variable.ttf').readAsBytesSync();
  final loader = FontLoader('Saira')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// A driver on a fake transport, with no controllers and no keyboard hook, for
/// the tests of screens that only read it and call its methods. It is not
/// started, so it owns no timer; [dispose] it with the test.
///
/// [prefs] are the stored settings it starts from.
Future<Driver> newDriver({Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final driver = Driver(
    transport: FakeTransport(),
    prefs: await SharedPreferences.getInstance(),
    rawEvents: const Stream<GamepadEvent>.empty(),
    connectionEvents: const Stream<GamepadConnectionEvent>.empty(),
    listGamepads: () async => [],
    enableKeyboard: false,
  );
  addTearDown(driver.dispose);
  return driver;
}

/// The backdrop key of every `BackdropFilter` under [root], in tree order: null
/// for a filter that works alone, the key of the group for one that shares its
/// blur with the others of that group.
List<BackdropKey?> backdropKeysUnder(WidgetTester t, Finder root) => [
  for (final e in t.elementList(
    find.descendant(of: root, matching: find.byType(BackdropFilter)),
  ))
    (e.renderObject! as RenderBackdropFilter).backdropKey,
];
