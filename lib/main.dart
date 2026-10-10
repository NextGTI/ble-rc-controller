import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/ble_transport.dart';
import 'core/driver.dart';

/// Lists the Saira font (SIL OFL 1.1) among the licences the app shows.
void registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL-Saira.txt');
    yield LicenseEntryWithLineBreaks(['saira'], text);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicense();
  final prefs = await SharedPreferences.getInstance();
  final driver = Driver(transport: UniversalBleTransport(), prefs: prefs);
  runApp(BleRcApp(driver: driver));
  // Start after the first frame so the UI is never blocked by Bluetooth setup.
  await driver.start();
}
