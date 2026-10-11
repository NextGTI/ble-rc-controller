import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BLE RC Controller'**
  String get appTitle;

  /// No description provided for @navCars.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get navCars;

  /// No description provided for @navDrive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get navDrive;

  /// No description provided for @navControls.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get navControls;

  /// No description provided for @navControllers.
  ///
  /// In en, this message translates to:
  /// **'Controllers'**
  String get navControllers;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @carsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get carsTitle;

  /// No description provided for @carsSearching.
  ///
  /// In en, this message translates to:
  /// **'Looking for cars…'**
  String get carsSearching;

  /// No description provided for @carsHint.
  ///
  /// In en, this message translates to:
  /// **'Turn the car on. It shows up here by itself (names starting with “SL-”).'**
  String get carsHint;

  /// No description provided for @btOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off'**
  String get btOffTitle;

  /// No description provided for @btOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn Bluetooth on to find your car.'**
  String get btOffBody;

  /// No description provided for @btDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth blocked'**
  String get btDeniedTitle;

  /// No description provided for @btDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluetooth for this app in your system settings.'**
  String get btDeniedBody;

  /// No description provided for @btUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth LE not available'**
  String get btUnsupportedTitle;

  /// No description provided for @btUnsupportedBody.
  ///
  /// In en, this message translates to:
  /// **'This device cannot talk to the car.'**
  String get btUnsupportedBody;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connectTo.
  ///
  /// In en, this message translates to:
  /// **'Connect to {car}'**
  String connectTo(String car);

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @connectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectedLabel;

  /// No description provided for @noCar.
  ///
  /// In en, this message translates to:
  /// **'No car connected'**
  String get noCar;

  /// No description provided for @noCarHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a car from the list to connect (click or tap).'**
  String get noCarHint;

  /// No description provided for @msgConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Turn the car off and on, and make sure no other app is connected to it.'**
  String get msgConnectFailed;

  /// No description provided for @msgDropped.
  ///
  /// In en, this message translates to:
  /// **'The car disconnected.'**
  String get msgDropped;

  /// No description provided for @msgPermission.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission was denied.'**
  String get msgPermission;

  /// No description provided for @batteryPercent.
  ///
  /// In en, this message translates to:
  /// **'Battery {percent}%'**
  String batteryPercent(int percent);

  /// No description provided for @rememberLast.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to the last car'**
  String get rememberLast;

  /// No description provided for @actionForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get actionForward;

  /// No description provided for @actionReverse.
  ///
  /// In en, this message translates to:
  /// **'Reverse'**
  String get actionReverse;

  /// No description provided for @actionLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get actionLeft;

  /// No description provided for @actionRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get actionRight;

  /// No description provided for @actionLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get actionLight;

  /// No description provided for @actionTurbo.
  ///
  /// In en, this message translates to:
  /// **'Turbo'**
  String get actionTurbo;

  /// No description provided for @actionDonut.
  ///
  /// In en, this message translates to:
  /// **'360° spin'**
  String get actionDonut;

  /// No description provided for @hintHold.
  ///
  /// In en, this message translates to:
  /// **'while pressed'**
  String get hintHold;

  /// No description provided for @hintToggle.
  ///
  /// In en, this message translates to:
  /// **'each press switches on/off'**
  String get hintToggle;

  /// No description provided for @controlsIntro.
  ///
  /// In en, this message translates to:
  /// **'Tap “Add”, then press a controller button, push a stick or press a key. Each action can have several inputs.'**
  String get controlsIntro;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @pressAnything.
  ///
  /// In en, this message translates to:
  /// **'Press a button, direction or key…'**
  String get pressAnything;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @restoreDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get restoreDefaults;

  /// No description provided for @useKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Use the keyboard'**
  String get useKeyboard;

  /// No description provided for @sharedInput.
  ///
  /// In en, this message translates to:
  /// **'This input is also assigned to another action.'**
  String get sharedInput;

  /// No description provided for @controllersTitle.
  ///
  /// In en, this message translates to:
  /// **'Controllers'**
  String get controllersTitle;

  /// No description provided for @noController.
  ///
  /// In en, this message translates to:
  /// **'No controller found'**
  String get noController;

  /// No description provided for @noControllerHint.
  ///
  /// In en, this message translates to:
  /// **'Pair your controller over Bluetooth or USB, then press any button.'**
  String get noControllerHint;

  /// No description provided for @controllerRecognised.
  ///
  /// In en, this message translates to:
  /// **'Recognised layout'**
  String get controllerRecognised;

  /// No description provided for @controllerCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom mapping'**
  String get controllerCustom;

  /// No description provided for @teachController.
  ///
  /// In en, this message translates to:
  /// **'Teach this controller…'**
  String get teachController;

  /// No description provided for @forgetMapping.
  ///
  /// In en, this message translates to:
  /// **'Forget custom mapping'**
  String get forgetMapping;

  /// No description provided for @teachTitle.
  ///
  /// In en, this message translates to:
  /// **'Teach controller'**
  String get teachTitle;

  /// No description provided for @teachIntro.
  ///
  /// In en, this message translates to:
  /// **'Press the button (or move the stick) the app asks for. Skip anything your controller does not have. Press Esc to cancel.'**
  String get teachIntro;

  /// No description provided for @teachProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String teachProgress(int n, int total);

  /// No description provided for @teachDone.
  ///
  /// In en, this message translates to:
  /// **'All set! This controller now works with every action.'**
  String get teachDone;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @inputMonitor.
  ///
  /// In en, this message translates to:
  /// **'Input monitor'**
  String get inputMonitor;

  /// No description provided for @monitorHint.
  ///
  /// In en, this message translates to:
  /// **'Press buttons and move sticks: the raw signals show up here. Handy for unknown controllers.'**
  String get monitorHint;

  /// No description provided for @monitorEmpty.
  ///
  /// In en, this message translates to:
  /// **'No signals yet.'**
  String get monitorEmpty;

  /// No description provided for @rawInput.
  ///
  /// In en, this message translates to:
  /// **'Raw: {key}'**
  String rawInput(String key);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @deadzone.
  ///
  /// In en, this message translates to:
  /// **'Stick dead zone: {percent}%'**
  String deadzone(int percent);

  /// No description provided for @onScreen.
  ///
  /// In en, this message translates to:
  /// **'On-screen buttons'**
  String get onScreen;

  /// No description provided for @onScreenHint.
  ///
  /// In en, this message translates to:
  /// **'For tablets and phones'**
  String get onScreenHint;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Unofficial, independent open-source project (MIT). It is not affiliated with, endorsed or sponsored by any car, toy or fuel brand. All names belong to their owners.'**
  String get disclaimer;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @driveLive.
  ///
  /// In en, this message translates to:
  /// **'Live inputs'**
  String get driveLive;

  /// No description provided for @keyboardTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get keyboardTipTitle;

  /// No description provided for @safetyNote.
  ///
  /// In en, this message translates to:
  /// **'Inputs only count while this window is in front. If you switch apps the car stops.'**
  String get safetyNote;

  /// No description provided for @noCarShort.
  ///
  /// In en, this message translates to:
  /// **'No car'**
  String get noCarShort;

  /// No description provided for @statusSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get statusSearching;

  /// No description provided for @statusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get statusConnecting;

  /// No description provided for @statusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get statusReconnecting;

  /// No description provided for @batteryLabel.
  ///
  /// In en, this message translates to:
  /// **'battery'**
  String get batteryLabel;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn the car on'**
  String get searchTitle;

  /// No description provided for @searchBody.
  ///
  /// In en, this message translates to:
  /// **'It shows up here by itself, within a few seconds.'**
  String get searchBody;

  /// No description provided for @tipNotShowingLabel.
  ///
  /// In en, this message translates to:
  /// **'Not showing up?'**
  String get tipNotShowingLabel;

  /// No description provided for @tipNotShowing.
  ///
  /// In en, this message translates to:
  /// **'Close other apps connected to it. The car accepts one connection at a time.'**
  String get tipNotShowing;

  /// No description provided for @tipStillLabel.
  ///
  /// In en, this message translates to:
  /// **'Still nothing?'**
  String get tipStillLabel;

  /// No description provided for @tipStill.
  ///
  /// In en, this message translates to:
  /// **'Turn the car off and on again.'**
  String get tipStill;

  /// No description provided for @carsNearby.
  ///
  /// In en, this message translates to:
  /// **'Cars nearby'**
  String get carsNearby;

  /// No description provided for @actionConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get actionConnect;

  /// No description provided for @actionSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get actionSwitch;

  /// No description provided for @signalStrong.
  ///
  /// In en, this message translates to:
  /// **'strong signal'**
  String get signalStrong;

  /// No description provided for @signalMedium.
  ///
  /// In en, this message translates to:
  /// **'medium signal'**
  String get signalMedium;

  /// No description provided for @signalWeak.
  ///
  /// In en, this message translates to:
  /// **'weak signal'**
  String get signalWeak;

  /// No description provided for @btEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth'**
  String get btEnable;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @connectingTitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {car}'**
  String connectingTitle(String car);

  /// No description provided for @connectingBody.
  ///
  /// In en, this message translates to:
  /// **'It takes a few seconds.'**
  String get connectingBody;

  /// No description provided for @lostTag.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get lostTag;

  /// No description provided for @lostBody.
  ///
  /// In en, this message translates to:
  /// **'The car stopped. The app reconnects as soon as it shows up.'**
  String get lostBody;

  /// No description provided for @connectFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to {car}'**
  String connectFailedTitle(String car);

  /// No description provided for @connectFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Turn the car off and on, and make sure no other app is connected to it.'**
  String get connectFailedBody;

  /// No description provided for @lightOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get lightOn;

  /// No description provided for @lightOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get lightOff;

  /// No description provided for @turboOn.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get turboOn;

  /// No description provided for @turboOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get turboOff;

  /// No description provided for @spinOn.
  ///
  /// In en, this message translates to:
  /// **'Spinning'**
  String get spinOn;

  /// No description provided for @spinOff.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get spinOff;

  /// No description provided for @cellController.
  ///
  /// In en, this message translates to:
  /// **'Controller'**
  String get cellController;

  /// No description provided for @noControllerShort.
  ///
  /// In en, this message translates to:
  /// **'No controller'**
  String get noControllerShort;

  /// No description provided for @keySpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get keySpace;

  /// No description provided for @legendSteer.
  ///
  /// In en, this message translates to:
  /// **'Steer'**
  String get legendSteer;

  /// No description provided for @steerRight.
  ///
  /// In en, this message translates to:
  /// **'{deg}° right'**
  String steerRight(int deg);

  /// No description provided for @steerLeft.
  ///
  /// In en, this message translates to:
  /// **'{deg}° left'**
  String steerLeft(int deg);

  /// No description provided for @gaugeLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get gaugeLeft;

  /// No description provided for @gaugeRight.
  ///
  /// In en, this message translates to:
  /// **'right'**
  String get gaugeRight;

  /// No description provided for @scaleForward.
  ///
  /// In en, this message translates to:
  /// **'forward'**
  String get scaleForward;

  /// No description provided for @scaleReverse.
  ///
  /// In en, this message translates to:
  /// **'reverse'**
  String get scaleReverse;

  /// No description provided for @scaleTurbo.
  ///
  /// In en, this message translates to:
  /// **'turbo'**
  String get scaleTurbo;

  /// No description provided for @groupCommands.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get groupCommands;

  /// No description provided for @groupDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get groupDriving;

  /// No description provided for @groupApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get groupApp;

  /// No description provided for @bindingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Buttons and keys'**
  String get bindingsTitle;

  /// No description provided for @bindingsHint.
  ///
  /// In en, this message translates to:
  /// **'What each input does'**
  String get bindingsHint;

  /// No description provided for @deadzoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Stick dead zone'**
  String get deadzoneTitle;

  /// No description provided for @deadzoneHint.
  ///
  /// In en, this message translates to:
  /// **'Ignores light touches on the stick'**
  String get deadzoneHint;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutHint.
  ///
  /// In en, this message translates to:
  /// **'Version {version}, open source'**
  String aboutHint(String version);

  /// No description provided for @bindingsLeadTouch.
  ///
  /// In en, this message translates to:
  /// **'Tap Add, then press a controller button, move a stick or press a key.'**
  String get bindingsLeadTouch;

  /// No description provided for @bindingsLeadClick.
  ///
  /// In en, this message translates to:
  /// **'Click Add, then press a controller button, move a stick or press a key.'**
  String get bindingsLeadClick;

  /// No description provided for @captureWaiting.
  ///
  /// In en, this message translates to:
  /// **'Press whatever should trigger {action}'**
  String captureWaiting(String action);

  /// No description provided for @connectedSection.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectedSection;

  /// No description provided for @recognized.
  ///
  /// In en, this message translates to:
  /// **'Recognised'**
  String get recognized;

  /// No description provided for @taught.
  ///
  /// In en, this message translates to:
  /// **'Taught'**
  String get taught;

  /// No description provided for @liveSignals.
  ///
  /// In en, this message translates to:
  /// **'Live signals'**
  String get liveSignals;

  /// No description provided for @liveSignalsHint.
  ///
  /// In en, this message translates to:
  /// **'Press buttons to see the signals. Handy for checking a controller the app does not know.'**
  String get liveSignalsHint;

  /// No description provided for @teachNew.
  ///
  /// In en, this message translates to:
  /// **'Teach a new controller'**
  String get teachNew;

  /// No description provided for @forgetTaught.
  ///
  /// In en, this message translates to:
  /// **'Forget what was taught'**
  String get forgetTaught;

  /// No description provided for @teachStep.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String teachStep(int n, int total);

  /// No description provided for @teachGroupFace.
  ///
  /// In en, this message translates to:
  /// **'Face buttons'**
  String get teachGroupFace;

  /// No description provided for @teachGroupShoulders.
  ///
  /// In en, this message translates to:
  /// **'Bumpers and triggers'**
  String get teachGroupShoulders;

  /// No description provided for @teachGroupMiddle.
  ///
  /// In en, this message translates to:
  /// **'Middle buttons'**
  String get teachGroupMiddle;

  /// No description provided for @teachGroupSticks.
  ///
  /// In en, this message translates to:
  /// **'Sticks'**
  String get teachGroupSticks;

  /// No description provided for @teachGroupDpad.
  ///
  /// In en, this message translates to:
  /// **'D-pad'**
  String get teachGroupDpad;

  /// No description provided for @teachHint_a.
  ///
  /// In en, this message translates to:
  /// **'✕ on PlayStation, A on Xbox, B on Switch'**
  String get teachHint_a;

  /// No description provided for @teachHint_b.
  ///
  /// In en, this message translates to:
  /// **'○ on PlayStation, B on Xbox, A on Switch'**
  String get teachHint_b;

  /// No description provided for @teachHint_x.
  ///
  /// In en, this message translates to:
  /// **'□ on PlayStation, X on Xbox, Y on Switch'**
  String get teachHint_x;

  /// No description provided for @teachHint_y.
  ///
  /// In en, this message translates to:
  /// **'△ on PlayStation, Y on Xbox, X on Switch'**
  String get teachHint_y;

  /// No description provided for @teachHint_leftBumper.
  ///
  /// In en, this message translates to:
  /// **'L1 on PlayStation, LB on Xbox, L on Switch'**
  String get teachHint_leftBumper;

  /// No description provided for @teachHint_rightBumper.
  ///
  /// In en, this message translates to:
  /// **'R1 on PlayStation, RB on Xbox, R on Switch'**
  String get teachHint_rightBumper;

  /// No description provided for @teachHint_leftTrigger.
  ///
  /// In en, this message translates to:
  /// **'L2 on PlayStation, LT on Xbox, ZL on Switch'**
  String get teachHint_leftTrigger;

  /// No description provided for @teachHint_rightTrigger.
  ///
  /// In en, this message translates to:
  /// **'R2 on PlayStation, RT on Xbox, ZR on Switch'**
  String get teachHint_rightTrigger;

  /// No description provided for @teachHint_back.
  ///
  /// In en, this message translates to:
  /// **'Share on PlayStation, View on Xbox, − on Switch'**
  String get teachHint_back;

  /// No description provided for @teachHint_start.
  ///
  /// In en, this message translates to:
  /// **'Options on PlayStation, Menu on Xbox, + on Switch'**
  String get teachHint_start;

  /// No description provided for @padA.
  ///
  /// In en, this message translates to:
  /// **'Bottom button (A / ✕)'**
  String get padA;

  /// No description provided for @padB.
  ///
  /// In en, this message translates to:
  /// **'Right button (B / ○)'**
  String get padB;

  /// No description provided for @padX.
  ///
  /// In en, this message translates to:
  /// **'Left button (X / □)'**
  String get padX;

  /// No description provided for @padY.
  ///
  /// In en, this message translates to:
  /// **'Top button (Y / △)'**
  String get padY;

  /// No description provided for @padLeftBumper.
  ///
  /// In en, this message translates to:
  /// **'Left bumper (LB / L1)'**
  String get padLeftBumper;

  /// No description provided for @padRightBumper.
  ///
  /// In en, this message translates to:
  /// **'Right bumper (RB / R1)'**
  String get padRightBumper;

  /// No description provided for @padLeftTrigger.
  ///
  /// In en, this message translates to:
  /// **'Left trigger (LT / L2)'**
  String get padLeftTrigger;

  /// No description provided for @padRightTrigger.
  ///
  /// In en, this message translates to:
  /// **'Right trigger (RT / R2)'**
  String get padRightTrigger;

  /// No description provided for @padBack.
  ///
  /// In en, this message translates to:
  /// **'Back (View / Share / −)'**
  String get padBack;

  /// No description provided for @padStart.
  ///
  /// In en, this message translates to:
  /// **'Start (Menu / Options / +)'**
  String get padStart;

  /// No description provided for @padHome.
  ///
  /// In en, this message translates to:
  /// **'Home (Guide / PS)'**
  String get padHome;

  /// No description provided for @padLeftStick.
  ///
  /// In en, this message translates to:
  /// **'Left stick click (L3)'**
  String get padLeftStick;

  /// No description provided for @padRightStick.
  ///
  /// In en, this message translates to:
  /// **'Right stick click (R3)'**
  String get padRightStick;

  /// No description provided for @padTouchpad.
  ///
  /// In en, this message translates to:
  /// **'Touchpad'**
  String get padTouchpad;

  /// No description provided for @padDpadUp.
  ///
  /// In en, this message translates to:
  /// **'D-pad ↑'**
  String get padDpadUp;

  /// No description provided for @padDpadDown.
  ///
  /// In en, this message translates to:
  /// **'D-pad ↓'**
  String get padDpadDown;

  /// No description provided for @padDpadLeft.
  ///
  /// In en, this message translates to:
  /// **'D-pad ←'**
  String get padDpadLeft;

  /// No description provided for @padDpadRight.
  ///
  /// In en, this message translates to:
  /// **'D-pad →'**
  String get padDpadRight;

  /// No description provided for @padLeftStickUp.
  ///
  /// In en, this message translates to:
  /// **'Left stick ↑'**
  String get padLeftStickUp;

  /// No description provided for @padLeftStickDown.
  ///
  /// In en, this message translates to:
  /// **'Left stick ↓'**
  String get padLeftStickDown;

  /// No description provided for @padLeftStickLeft.
  ///
  /// In en, this message translates to:
  /// **'Left stick ←'**
  String get padLeftStickLeft;

  /// No description provided for @padLeftStickRight.
  ///
  /// In en, this message translates to:
  /// **'Left stick →'**
  String get padLeftStickRight;

  /// No description provided for @padRightStickUp.
  ///
  /// In en, this message translates to:
  /// **'Right stick ↑'**
  String get padRightStickUp;

  /// No description provided for @padRightStickDown.
  ///
  /// In en, this message translates to:
  /// **'Right stick ↓'**
  String get padRightStickDown;

  /// No description provided for @padRightStickLeft.
  ///
  /// In en, this message translates to:
  /// **'Right stick ←'**
  String get padRightStickLeft;

  /// No description provided for @padRightStickRight.
  ///
  /// In en, this message translates to:
  /// **'Right stick →'**
  String get padRightStickRight;

  /// No description provided for @teach_a.
  ///
  /// In en, this message translates to:
  /// **'Press the bottom button'**
  String get teach_a;

  /// No description provided for @teach_b.
  ///
  /// In en, this message translates to:
  /// **'Press the right button'**
  String get teach_b;

  /// No description provided for @teach_x.
  ///
  /// In en, this message translates to:
  /// **'Press the left button'**
  String get teach_x;

  /// No description provided for @teach_y.
  ///
  /// In en, this message translates to:
  /// **'Press the top button'**
  String get teach_y;

  /// No description provided for @teach_leftBumper.
  ///
  /// In en, this message translates to:
  /// **'Press the left bumper'**
  String get teach_leftBumper;

  /// No description provided for @teach_rightBumper.
  ///
  /// In en, this message translates to:
  /// **'Press the right bumper'**
  String get teach_rightBumper;

  /// No description provided for @teach_leftTrigger.
  ///
  /// In en, this message translates to:
  /// **'Squeeze the left trigger'**
  String get teach_leftTrigger;

  /// No description provided for @teach_rightTrigger.
  ///
  /// In en, this message translates to:
  /// **'Squeeze the right trigger'**
  String get teach_rightTrigger;

  /// No description provided for @teach_back.
  ///
  /// In en, this message translates to:
  /// **'Press the middle button on the left'**
  String get teach_back;

  /// No description provided for @teach_start.
  ///
  /// In en, this message translates to:
  /// **'Press the middle button on the right'**
  String get teach_start;

  /// No description provided for @teach_leftStickX.
  ///
  /// In en, this message translates to:
  /// **'Push the left stick all the way right'**
  String get teach_leftStickX;

  /// No description provided for @teach_leftStickY.
  ///
  /// In en, this message translates to:
  /// **'Push the left stick all the way up'**
  String get teach_leftStickY;

  /// No description provided for @teach_rightStickX.
  ///
  /// In en, this message translates to:
  /// **'Push the right stick all the way right'**
  String get teach_rightStickX;

  /// No description provided for @teach_rightStickY.
  ///
  /// In en, this message translates to:
  /// **'Push the right stick all the way up'**
  String get teach_rightStickY;

  /// No description provided for @teach_dpadUp.
  ///
  /// In en, this message translates to:
  /// **'Press the D-pad up'**
  String get teach_dpadUp;

  /// No description provided for @teach_dpadDown.
  ///
  /// In en, this message translates to:
  /// **'Press the D-pad down'**
  String get teach_dpadDown;

  /// No description provided for @teach_dpadLeft.
  ///
  /// In en, this message translates to:
  /// **'Press the D-pad left'**
  String get teach_dpadLeft;

  /// No description provided for @teach_dpadRight.
  ///
  /// In en, this message translates to:
  /// **'Press the D-pad right'**
  String get teach_dpadRight;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
