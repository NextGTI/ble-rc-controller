// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BLE RC Controller';

  @override
  String get navCars => 'Cars';

  @override
  String get navDrive => 'Drive';

  @override
  String get navControls => 'Buttons';

  @override
  String get navControllers => 'Controllers';

  @override
  String get navSettings => 'Settings';

  @override
  String get carsTitle => 'Cars';

  @override
  String get carsSearching => 'Looking for cars…';

  @override
  String get carsHint =>
      'Turn the car on. It shows up here by itself (names starting with “SL-”).';

  @override
  String get btOffTitle => 'Bluetooth is off';

  @override
  String get btOffBody => 'Turn Bluetooth on to find your car.';

  @override
  String get btDeniedTitle => 'Bluetooth blocked';

  @override
  String get btDeniedBody =>
      'Allow Bluetooth for this app in your system settings.';

  @override
  String get btUnsupportedTitle => 'Bluetooth LE not available';

  @override
  String get btUnsupportedBody => 'This device cannot talk to the car.';

  @override
  String get connect => 'Connect';

  @override
  String connectTo(String car) {
    return 'Connect to $car';
  }

  @override
  String get disconnect => 'Disconnect';

  @override
  String get connecting => 'Connecting…';

  @override
  String get connectedLabel => 'Connected';

  @override
  String get noCar => 'No car connected';

  @override
  String get noCarHint => 'Pick a car from the list to connect (click or tap).';

  @override
  String get msgConnectFailed =>
      'Could not connect. Turn the car off and on, and make sure no other app is connected to it.';

  @override
  String get msgDropped => 'The car disconnected.';

  @override
  String get msgPermission => 'Bluetooth permission was denied.';

  @override
  String batteryPercent(int percent) {
    return 'Battery $percent%';
  }

  @override
  String get rememberLast => 'Reconnect to the last car';

  @override
  String get actionForward => 'Forward';

  @override
  String get actionReverse => 'Reverse';

  @override
  String get actionLeft => 'Left';

  @override
  String get actionRight => 'Right';

  @override
  String get actionLight => 'Light';

  @override
  String get actionTurbo => 'Turbo';

  @override
  String get actionDonut => '360° spin';

  @override
  String get actionMode => 'Mode 1/2';

  @override
  String modeValue(int mode) {
    return 'Mode $mode';
  }

  @override
  String get hintHold => 'while pressed';

  @override
  String get hintToggle => 'each press switches on/off';

  @override
  String get controlsIntro =>
      'Tap “Add”, then press a controller button, push a stick or press a key. Each action can have several inputs.';

  @override
  String get add => 'Add';

  @override
  String get pressAnything => 'Press a button, direction or key…';

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get restoreDefaults => 'Restore defaults';

  @override
  String get useKeyboard => 'Use the keyboard (only while the app is in front)';

  @override
  String get sharedInput => 'This input is also assigned to another action.';

  @override
  String get controllersTitle => 'Controllers';

  @override
  String get noController => 'No controller found';

  @override
  String get noControllerHint =>
      'Pair your controller over Bluetooth or USB, then press any button.';

  @override
  String get controllerRecognised => 'Recognised layout';

  @override
  String get controllerCustom => 'Custom mapping';

  @override
  String get teachController => 'Teach this controller…';

  @override
  String get forgetMapping => 'Forget custom mapping';

  @override
  String get teachTitle => 'Teach controller';

  @override
  String get teachIntro =>
      'Press the button (or move the stick) the app asks for. Skip anything your controller does not have. Press Esc to cancel.';

  @override
  String teachProgress(int n, int total) {
    return 'Step $n of $total';
  }

  @override
  String get teachDone =>
      'All set! This controller now works with every action.';

  @override
  String get done => 'Done';

  @override
  String get skip => 'Skip';

  @override
  String get inputMonitor => 'Input monitor';

  @override
  String get monitorHint =>
      'Press buttons and move sticks: the raw signals show up here. Handy for unknown controllers.';

  @override
  String get monitorEmpty => 'No signals yet.';

  @override
  String rawInput(String key) {
    return 'Raw: $key';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String deadzone(int percent) {
    return 'Stick dead zone: $percent%';
  }

  @override
  String get onScreen => 'Show on-screen controls';

  @override
  String get onScreenHint =>
      'Touch buttons for phones and tablets (or mouse clicks).';

  @override
  String get about => 'About';

  @override
  String get disclaimer =>
      'Unofficial, independent open-source project (MIT). It is not affiliated with, endorsed or sponsored by any car, toy or fuel brand. All names belong to their owners.';

  @override
  String get driveLive => 'Live inputs';

  @override
  String get keyboardTipTitle => 'Keyboard';

  @override
  String get safetyNote =>
      'Inputs only count while this window is in front. If you switch apps the car stops.';

  @override
  String get padA => 'Bottom button (A / ✕)';

  @override
  String get padB => 'Right button (B / ○)';

  @override
  String get padX => 'Left button (X / □)';

  @override
  String get padY => 'Top button (Y / △)';

  @override
  String get padLeftBumper => 'Left bumper (LB / L1)';

  @override
  String get padRightBumper => 'Right bumper (RB / R1)';

  @override
  String get padLeftTrigger => 'Left trigger (LT / L2)';

  @override
  String get padRightTrigger => 'Right trigger (RT / R2)';

  @override
  String get padBack => 'Back (View / Share / −)';

  @override
  String get padStart => 'Start (Menu / Options / +)';

  @override
  String get padHome => 'Home (Guide / PS)';

  @override
  String get padLeftStick => 'Left stick click (L3)';

  @override
  String get padRightStick => 'Right stick click (R3)';

  @override
  String get padTouchpad => 'Touchpad';

  @override
  String get padDpadUp => 'D-pad ↑';

  @override
  String get padDpadDown => 'D-pad ↓';

  @override
  String get padDpadLeft => 'D-pad ←';

  @override
  String get padDpadRight => 'D-pad →';

  @override
  String get padLeftStickUp => 'Left stick ↑';

  @override
  String get padLeftStickDown => 'Left stick ↓';

  @override
  String get padLeftStickLeft => 'Left stick ←';

  @override
  String get padLeftStickRight => 'Left stick →';

  @override
  String get padRightStickUp => 'Right stick ↑';

  @override
  String get padRightStickDown => 'Right stick ↓';

  @override
  String get padRightStickLeft => 'Right stick ←';

  @override
  String get padRightStickRight => 'Right stick →';

  @override
  String get teach_a => 'Press the bottom face button (A / ✕)';

  @override
  String get teach_b => 'Press the right face button (B / ○)';

  @override
  String get teach_x => 'Press the left face button (X / □)';

  @override
  String get teach_y => 'Press the top face button (Y / △)';

  @override
  String get teach_leftBumper => 'Press the left bumper (LB / L1)';

  @override
  String get teach_rightBumper => 'Press the right bumper (RB / R1)';

  @override
  String get teach_leftTrigger => 'Squeeze the left trigger (LT / L2)';

  @override
  String get teach_rightTrigger => 'Squeeze the right trigger (RT / R2)';

  @override
  String get teach_back => 'Press Back (View / Share / −)';

  @override
  String get teach_start => 'Press Start (Menu / Options / +)';

  @override
  String get teach_leftStickX => 'Push the left stick all the way to the RIGHT';

  @override
  String get teach_leftStickY => 'Push the left stick all the way UP';

  @override
  String get teach_rightStickX =>
      'Push the right stick all the way to the RIGHT';

  @override
  String get teach_rightStickY => 'Push the right stick all the way UP';

  @override
  String get teach_dpadUp => 'Press D-pad UP';

  @override
  String get teach_dpadDown => 'Press D-pad DOWN';

  @override
  String get teach_dpadLeft => 'Press D-pad LEFT';

  @override
  String get teach_dpadRight => 'Press D-pad RIGHT';
}
