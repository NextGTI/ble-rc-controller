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
  String get disconnect => 'Disconnect';

  @override
  String get connectedLabel => 'Connected';

  @override
  String get msgDropped => 'The car disconnected.';

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
  String get hintHold => 'while pressed';

  @override
  String get hintToggle => 'each press switches on/off';

  @override
  String get add => 'Add';

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get restoreDefaults => 'Restore defaults';

  @override
  String get useKeyboard => 'Use the keyboard';

  @override
  String get sharedInput => 'This input is also assigned to another action.';

  @override
  String get controllersTitle => 'Controllers';

  @override
  String get noControllerHint =>
      'Pair your controller over Bluetooth or USB, then press any button.';

  @override
  String get teachTitle => 'Teach controller';

  @override
  String get teachDone =>
      'All set! This controller now works with every action.';

  @override
  String get done => 'Done';

  @override
  String get skip => 'Skip';

  @override
  String rawInput(String key) {
    return 'Raw: $key';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get onScreen => 'On-screen buttons';

  @override
  String get onScreenHint => 'For tablets and phones';

  @override
  String get disclaimer =>
      'Unofficial, independent open-source project (MIT). It is not affiliated with, endorsed or sponsored by any car, toy or fuel brand. All names belong to their owners.';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get noCarShort => 'No car';

  @override
  String get statusSearching => 'Searching';

  @override
  String get statusConnecting => 'Connecting';

  @override
  String get statusReconnecting => 'Reconnecting';

  @override
  String get batteryLabel => 'battery';

  @override
  String get searchTitle => 'Turn the car on';

  @override
  String get searchBody => 'It shows up here by itself, within a few seconds.';

  @override
  String get tipNotShowingLabel => 'Not showing up?';

  @override
  String get tipNotShowing =>
      'Close other apps connected to it. The car accepts one connection at a time.';

  @override
  String get tipStillLabel => 'Still nothing?';

  @override
  String get tipStill => 'Turn the car off and on again.';

  @override
  String get carsNearby => 'Cars nearby';

  @override
  String get actionConnect => 'Connect';

  @override
  String get actionSwitch => 'Switch';

  @override
  String get signalStrong => 'strong signal';

  @override
  String get signalMedium => 'medium signal';

  @override
  String get signalWeak => 'weak signal';

  @override
  String get btEnable => 'Turn on Bluetooth';

  @override
  String get retry => 'Try again';

  @override
  String get close => 'Close';

  @override
  String connectingTitle(String car) {
    return 'Connecting to $car';
  }

  @override
  String get connectingBody => 'It takes a few seconds.';

  @override
  String get lostTag => 'Connection lost';

  @override
  String get lostBody =>
      'The car stopped. The app reconnects as soon as it shows up.';

  @override
  String connectFailedTitle(String car) {
    return 'Could not connect to $car';
  }

  @override
  String get connectFailedBody =>
      'Turn the car off and on, and make sure no other app is connected to it.';

  @override
  String get lightOn => 'On';

  @override
  String get lightOff => 'Off';

  @override
  String get turboOn => 'Active';

  @override
  String get turboOff => 'Off';

  @override
  String get spinOn => 'Spinning';

  @override
  String get spinOff => 'Stopped';

  @override
  String get cellController => 'Controller';

  @override
  String get noControllerShort => 'No controller';

  @override
  String get keySpace => 'Space';

  @override
  String get legendSteer => 'Steer';

  @override
  String steerRight(int deg) {
    return '$deg° right';
  }

  @override
  String steerLeft(int deg) {
    return '$deg° left';
  }

  @override
  String get gaugeLeft => 'left';

  @override
  String get gaugeRight => 'right';

  @override
  String get scaleForward => 'forward';

  @override
  String get scaleReverse => 'reverse';

  @override
  String get scaleTurbo => 'turbo';

  @override
  String get groupCommands => 'Commands';

  @override
  String get groupDriving => 'Driving';

  @override
  String get groupApp => 'App';

  @override
  String get bindingsTitle => 'Buttons and keys';

  @override
  String get bindingsHint => 'What each input does';

  @override
  String get deadzoneTitle => 'Stick dead zone';

  @override
  String get deadzoneHint => 'Ignores light touches on the stick';

  @override
  String get aboutTitle => 'About';

  @override
  String aboutHint(String version) {
    return 'Version $version, open source';
  }

  @override
  String get aboutMaker => 'Made by';

  @override
  String get aboutRepository => 'Source code';

  @override
  String get aboutLicenseMit => 'MIT license';

  @override
  String get aboutLicenses => 'Open-source licences';

  @override
  String get bindingsLeadTouch =>
      'Tap Add, then press a controller button, move a stick or press a key.';

  @override
  String get bindingsLeadClick =>
      'Click Add, then press a controller button, move a stick or press a key.';

  @override
  String captureWaiting(String action) {
    return 'Press whatever should trigger $action';
  }

  @override
  String get connectedSection => 'Connected';

  @override
  String get recognized => 'Recognised';

  @override
  String get taught => 'Taught';

  @override
  String get liveSignals => 'Live signals';

  @override
  String get liveSignalsHint =>
      'Press buttons to see the signals. Handy for checking a controller the app does not know.';

  @override
  String get teachNew => 'Teach a new controller';

  @override
  String get forgetTaught => 'Forget what was taught';

  @override
  String teachStep(int n, int total) {
    return 'Step $n of $total';
  }

  @override
  String get teachGroupFace => 'Face buttons';

  @override
  String get teachGroupShoulders => 'Bumpers and triggers';

  @override
  String get teachGroupMiddle => 'Middle buttons';

  @override
  String get teachGroupSticks => 'Sticks';

  @override
  String get teachGroupDpad => 'D-pad';

  @override
  String get teachHint_a => '✕ on PlayStation, A on Xbox, B on Switch';

  @override
  String get teachHint_b => '○ on PlayStation, B on Xbox, A on Switch';

  @override
  String get teachHint_x => '□ on PlayStation, X on Xbox, Y on Switch';

  @override
  String get teachHint_y => '△ on PlayStation, Y on Xbox, X on Switch';

  @override
  String get teachHint_leftBumper =>
      'L1 on PlayStation, LB on Xbox, L on Switch';

  @override
  String get teachHint_rightBumper =>
      'R1 on PlayStation, RB on Xbox, R on Switch';

  @override
  String get teachHint_leftTrigger =>
      'L2 on PlayStation, LT on Xbox, ZL on Switch';

  @override
  String get teachHint_rightTrigger =>
      'R2 on PlayStation, RT on Xbox, ZR on Switch';

  @override
  String get teachHint_back =>
      'Share on PlayStation, View on Xbox, − on Switch';

  @override
  String get teachHint_start =>
      'Options on PlayStation, Menu on Xbox, + on Switch';

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
  String get teach_a => 'Press the bottom button';

  @override
  String get teach_b => 'Press the right button';

  @override
  String get teach_x => 'Press the left button';

  @override
  String get teach_y => 'Press the top button';

  @override
  String get teach_leftBumper => 'Press the left bumper';

  @override
  String get teach_rightBumper => 'Press the right bumper';

  @override
  String get teach_leftTrigger => 'Squeeze the left trigger';

  @override
  String get teach_rightTrigger => 'Squeeze the right trigger';

  @override
  String get teach_back => 'Press the middle button on the left';

  @override
  String get teach_start => 'Press the middle button on the right';

  @override
  String get teach_leftStickX => 'Push the left stick all the way right';

  @override
  String get teach_leftStickY => 'Push the left stick all the way up';

  @override
  String get teach_rightStickX => 'Push the right stick all the way right';

  @override
  String get teach_rightStickY => 'Push the right stick all the way up';

  @override
  String get teach_dpadUp => 'Press the D-pad up';

  @override
  String get teach_dpadDown => 'Press the D-pad down';

  @override
  String get teach_dpadLeft => 'Press the D-pad left';

  @override
  String get teach_dpadRight => 'Press the D-pad right';
}
