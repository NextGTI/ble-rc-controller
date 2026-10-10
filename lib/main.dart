import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/ble_transport.dart';
import 'core/driver.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final driver = Driver(transport: UniversalBleTransport(), prefs: prefs);
  runApp(BleRcApp(driver: driver));
  // Start after the first frame so the UI is never blocked by Bluetooth setup.
  await driver.start();
}
