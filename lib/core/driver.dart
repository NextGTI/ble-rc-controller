// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../input/bindings.dart';
import '../input/controller_profile.dart';
import '../input/input_ref.dart';
import '../input/pad_input.dart';
import 'car_transport.dart';
import 'protocol.dart';

enum LinkState { idle, connecting, connected }

enum MessageKind { connectFailed, dropped, permissionDenied }

class RawSignal {
  RawSignal(this.gamepadName, this.key, this.value);
  final String gamepadName;
  final String key;
  double value;
}

/// Ties everything together: Bluetooth link, controller/keyboard/touch input,
/// bindings and settings. The UI only reads from here and calls methods.
class Driver extends ChangeNotifier with WidgetsBindingObserver {
  Driver({
    required this.transport,
    required SharedPreferences prefs,
    Stream<GamepadEvent>? rawEvents,
    Stream<GamepadConnectionEvent>? connectionEvents,
    Future<List<GamepadController>> Function()? listGamepads,
    GamepadNormalizer? normalizer,
    this.enableKeyboard = true,
    this.carStaleAfter = const Duration(seconds: 6),
  })  : _prefs = prefs,
        _rawEvents = rawEvents,
        _connectionEvents = connectionEvents,
        _listGamepads = listGamepads,
        _normalizer = normalizer ?? GamepadNormalizer() {
    _bindings = decodeBindings(prefs.getString('bindings'));
    _profiles = decodeProfiles(prefs.getString('profiles'));
    _autoConnect = prefs.getBool('autoConnect') ?? true;
    _keyboardEnabled = prefs.getBool('keyboard') ?? true;
    _deadzone = prefs.getDouble('deadzone') ?? 0.35;
    _onScreenControls = prefs.getBool('onScreen') ??
        (defaultTargetPlatform == TargetPlatform.android);
    _localeCode = prefs.getString('locale') ?? 'system';
    _lastCarId = prefs.getString('lastCar');
  }

  final CarTransport transport;
  final SharedPreferences _prefs;
  final Stream<GamepadEvent>? _rawEvents;
  final Stream<GamepadConnectionEvent>? _connectionEvents;
  final Future<List<GamepadController>> Function()? _listGamepads;
  final GamepadNormalizer _normalizer;
  final bool enableKeyboard;

  /// A car not heard from for this long drops off the list.
  final Duration carStaleAfter;

  // --- Bluetooth state ------------------------------------------------------
  BluetoothState _bluetooth = BluetoothState.unknown;
  final Map<String, FoundCar> _cars = {};
  final Map<String, DateTime> _seen = {};
  LinkState _link = LinkState.idle;
  String? _carId;
  int? _battery;
  MessageKind? _message;
  FoundCar? _lostCar;
  FoundCar? _failedCar;

  /// The car of the current connection, kept apart from [_cars]: that list is
  /// pruned while idle, and a car connected after being pruned is not in it.
  FoundCar? _carSnapshot;
  bool _scanning = false;
  int _connectToken = 0;
  bool _writing = false;
  String? _lastCarId;

  StreamSubscription<BluetoothState>? _availabilitySub;
  StreamSubscription<FoundCar>? _scanSub;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<int>? _batterySub;

  // --- Settings ---------------------------------------------------------------
  late Bindings _bindings;
  late Map<String, ControllerProfile> _profiles;
  late bool _autoConnect;

  /// Set when the user disconnects on purpose, so the car that is still
  /// advertising does not pull the app straight back in. Cleared by the next
  /// successful connection.
  bool _autoConnectHeld = false;
  late bool _keyboardEnabled;
  late double _deadzone;
  late bool _onScreenControls;
  late String _localeCode;

  // --- Input state ------------------------------------------------------------
  final PadState _pad = PadState();
  final Map<String, ControllerInfo> _controllers = {};
  final Set<int> _keysDown = {};
  final Set<CarAction> _virtual = {};

  /// On-screen buttons that stay on until tapped again (turbo and 360° spin).
  final Set<CarAction> _latched = {};
  final Map<String, double> _rawValues = {};
  final Map<String, double> _rawRest = {};
  final Set<String> _rawAnalog = {};
  final Map<CarAction, bool> _prevHeld = {};
  bool _light = false;
  CarAction? _capturing;
  TeachSession? _teach;
  CarCommand _cmd = const CarCommand();
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);
  CarCommand? _lastSentCmd;

  StreamSubscription<GamepadEvent>? _rawSub;
  StreamSubscription<GamepadConnectionEvent>? _connEvtSub;
  Timer? _tickTimer;
  Timer? _pruneTimer;

  /// Bumped on every raw controller event; the input monitor listens to it.
  final ValueNotifier<int> rawRevision = ValueNotifier(0);
  final Map<String, RawSignal> rawSignals = {};

  // ---------------------------------------------------------------------------
  // Public read-only state
  // ---------------------------------------------------------------------------
  BluetoothState get bluetooth => _bluetooth;
  List<FoundCar> get cars =>
      (_cars.values.toList()..sort((a, b) => a.name.compareTo(b.name)));
  LinkState get link => _link;
  String? get carId => _carId;
  FoundCar? get connectedCar => _carId == null ? null : (_cars[_carId] ?? _carSnapshot);
  int? get battery => _battery;
  MessageKind? get message => _message;

  /// The car whose link dropped while auto-reconnect was on. The app is waiting
  /// for it to show up again. Cleared by a new connection, by connecting to a
  /// different car (even if that attempt fails), by a deliberate disconnect, by
  /// switching auto-reconnect off and when Bluetooth stops being ready.
  FoundCar? get lostCar => _lostCar;

  /// True while the app waits to reconnect to [lostCar].
  bool get reconnecting => _lostCar != null && _link == LinkState.idle;

  /// The car of the last failed connection. Set together with
  /// [MessageKind.connectFailed]; cleared by [dismissMessage] and by the next
  /// [connect].
  FoundCar? get failedCar => _failedCar;

  CarCommand get command => _cmd;
  Bindings get bindings => _bindings;
  CarAction? get capturing => _capturing;
  TeachSession? get teaching => _teach;
  List<ControllerInfo> get controllers => _controllers.values.toList();
  Map<String, ControllerProfile> get profiles => _profiles;
  bool get autoConnect => _autoConnect;
  bool get keyboardEnabled => _keyboardEnabled;
  double get deadzone => _deadzone;
  bool get onScreenControls => _onScreenControls;
  String get localeCode => _localeCode;
  Set<PadInput> get pressedPad => _pad.pressedSet(_deadzone);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    if (enableKeyboard) HardwareKeyboard.instance.addHandler(_onKey);

    _tickTimer = Timer.periodic(const Duration(milliseconds: 20), (_) => _tick());
    _pruneTimer = Timer.periodic(const Duration(seconds: 1), (_) => _prune());

    _startGamepads();

    try {
      await transport.requestPermissions();
    } catch (_) {
      _message = MessageKind.permissionDenied;
      notifyListeners();
    }
    _scanSub = transport.scanResults.listen(_onFound, onError: (_) {});
    _availabilitySub = transport.availability.listen(_onAvailability);
    _onAvailability(await transport.currentAvailability());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (enableKeyboard) HardwareKeyboard.instance.removeHandler(_onKey);
    _tickTimer?.cancel();
    _pruneTimer?.cancel();
    _rawSub?.cancel();
    _connEvtSub?.cancel();
    _scanSub?.cancel();
    _availabilitySub?.cancel();
    _connSub?.cancel();
    _batterySub?.cancel();
    rawRevision.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Inputs only count while the app is in front. Otherwise a released key or
    // button could be missed and the car would keep driving.
    if (state != AppLifecycleState.resumed) clearInputs();
  }

  /// Forget every held input and stop the car.
  void clearInputs() {
    _keysDown.clear();
    _pad.clear();
    _rawValues.clear();
    _virtual.clear();
    _latched.clear();
    _prevHeld.clear();
    _sendNow(_cmd.neutral);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Bluetooth
  // ---------------------------------------------------------------------------
  /// Whether the system can be asked to turn Bluetooth on (Android only).
  bool get canEnableBluetooth => transport.canEnableBluetooth;

  /// Asks the system to turn Bluetooth on. The availability stream reports
  /// the result, so nothing else is needed here.
  Future<void> enableBluetooth() async {
    await transport.enableBluetooth();
  }

  /// Asks for the Bluetooth permission again. If it is granted the denial
  /// goes away and Bluetooth is read afresh; if not, the message stays.
  Future<void> retryPermissions() async {
    try {
      await transport.requestPermissions();
    } catch (_) {
      return;
    }
    if (_message == MessageKind.permissionDenied) _message = null;
    _onAvailability(await transport.currentAvailability());
  }

  void _onAvailability(BluetoothState s) {
    _bluetooth = s;
    if (s == BluetoothState.ready) {
      _startScan();
    } else {
      _scanning = false;
      _lostCar = null;
    }
    notifyListeners();
  }

  Future<void> _startScan() async {
    if (_bluetooth != BluetoothState.ready || _scanning || _link != LinkState.idle) {
      return;
    }
    _scanning = true;
    try {
      await transport.startScan();
    } catch (_) {
      _scanning = false;
    }
  }

  void _onFound(FoundCar car) {
    final isNew = !_cars.containsKey(car.id);
    _cars[car.id] = car;
    _seen[car.id] = DateTime.now();
    if (isNew) {
      notifyListeners();
      if (_autoConnect && !_autoConnectHeld && _link == LinkState.idle && car.id == _lastCarId) {
        connect(car.id);
      }
    } else if (_link == LinkState.idle) {
      // Signal strength changes: refresh occasionally via the prune timer.
    }
  }

  void _prune() {
    if (_link != LinkState.idle) return;
    final limit = DateTime.now().subtract(carStaleAfter);
    final stale = _seen.entries.where((e) => e.value.isBefore(limit)).map((e) => e.key).toList();
    for (final id in stale) {
      _cars.remove(id);
      _seen.remove(id);
    }
    notifyListeners(); // also refreshes signal bars
  }

  Future<void> connect(String id) async {
    // The car list is pruned while idle (and a car busy elsewhere does not
    // advertise), so pin down which car this is before anything can drop it.
    // It names a failure and is the lost car if the link drops later.
    final car = _cars[id] ??
        (_carId == id ? _carSnapshot : null) ??
        (_failedCar?.id == id ? _failedCar : null) ??
        (_lostCar?.id == id ? _lostCar : null);
    // Picking a different car ends the wait for the lost one, even if this
    // attempt fails. Retrying the lost car keeps it until it connects.
    if (_lostCar != null && _lostCar!.id != id) _lostCar = null;
    if (_link != LinkState.idle) await disconnect();
    final token = ++_connectToken;
    _message = null;
    _failedCar = null;
    _link = LinkState.connecting;
    _carId = id;
    _carSnapshot = car;
    _scanning = false;
    notifyListeners();
    try {
      await transport.stopScan();
      await transport.connect(id);
    } catch (_) {
      if (token != _connectToken) return;
      _link = LinkState.idle;
      _carId = null;
      _carSnapshot = null;
      _failedCar = car;
      _message = MessageKind.connectFailed;
      notifyListeners();
      _startScan();
      return;
    }
    if (token != _connectToken) {
      await transport.disconnect(id);
      return;
    }
    _connSub = transport.connectionOf(id).listen((up) {
      if (!up && token == _connectToken) _onDropped();
    }, onError: (_) {});
    _batterySub = transport.batteryOf(id).listen((b) {
      _battery = b;
      notifyListeners();
    }, onError: (_) {});
    _link = LinkState.connected;
    _autoConnectHeld = false;
    _lostCar = null;
    _lastCarId = id;
    await _prefs.setString('lastCar', id);
    _lastSentCmd = null;
    notifyListeners();
  }

  Future<void> disconnect() async {
    _autoConnectHeld = true;
    _lostCar = null;
    _latched.clear();
    _connectToken++;
    final id = _carId;
    if (id != null && _link == LinkState.connected) {
      await _sendNow(_cmd.neutral);
    }
    await _connSub?.cancel();
    await _batterySub?.cancel();
    _connSub = null;
    _batterySub = null;
    _link = LinkState.idle;
    _carId = null;
    _carSnapshot = null;
    _battery = null;
    notifyListeners();
    if (id != null) await transport.disconnect(id);
    _startScan();
  }

  void _onDropped() {
    // Only a ready Bluetooth can bring the car back. A drop reported after the
    // adapter went off must not start a "reconnecting" state.
    _lostCar = _autoConnect && _bluetooth == BluetoothState.ready ? connectedCar : null;
    _latched.clear();
    _connSub?.cancel();
    _batterySub?.cancel();
    _connSub = null;
    _batterySub = null;
    _link = LinkState.idle;
    _carId = null;
    _carSnapshot = null;
    _battery = null;
    _message = MessageKind.dropped;
    notifyListeners();
    _startScan();
  }

  void dismissMessage() {
    _message = null;
    _failedCar = null;
    notifyListeners();
  }

  Future<void> _sendNow(CarCommand c) async {
    final id = _carId;
    if (id == null || _link != LinkState.connected) return;
    try {
      await transport.writeControl(id, c.toBytes());
      _lastSentCmd = c;
      _lastSent = DateTime.now();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Controller input
  // ---------------------------------------------------------------------------
  void _startGamepads() {
    try {
      final raw = _rawEvents ?? Gamepads.events;
      _rawSub = raw.listen(_onRaw, onError: (_) {});
      final conn = _connectionEvents ?? Gamepads.connectionEvents;
      _connEvtSub = conn.listen(_onConnection, onError: (_) {});
      _refreshControllers();
    } catch (_) {
      // No gamepad support on this platform/build: keyboard and touch still work.
    }
  }

  Future<void> _refreshControllers() async {
    try {
      final list = await (_listGamepads ?? Gamepads.list)();
      for (final g in list) {
        _controllers[g.id] = ControllerInfo(
          id: g.id,
          name: g.name,
          vendorId: g.vendorId,
          productId: g.productId,
        );
        g.dispose();
      }
      notifyListeners();
    } catch (_) {}
  }

  void _onConnection(GamepadConnectionEvent e) {
    if (e.type == GamepadConnectionEventType.connected) {
      _controllers[e.gamepadId] = ControllerInfo(id: e.gamepadId, name: e.name);
      _refreshControllers();
    } else {
      _controllers.remove(e.gamepadId);
      _normalizer.removeDevice(e.gamepadId);
      if (_controllers.isEmpty) {
        _pad.clear();
        _rawValues.clear();
      }
    }
    notifyListeners();
  }

  ControllerInfo _infoFor(GamepadEvent e) {
    var info = _controllers[e.gamepadId];
    if (info == null || (info.vendorId == null && e.vendorId != null)) {
      info = ControllerInfo(
        id: e.gamepadId,
        name: info?.name ?? 'Controller',
        vendorId: e.vendorId ?? info?.vendorId,
        productId: e.productId ?? info?.productId,
      );
      final isNew = !_controllers.containsKey(e.gamepadId);
      _controllers[e.gamepadId] = info;
      if (isNew) _refreshControllers();
    }
    return info;
  }

  void _onRaw(GamepadEvent e) {
    final info = _infoFor(e);
    final profile = _profiles[info.profileKey];

    // Raw bookkeeping (monitor, raw bindings, teaching, capture).
    final prev = _rawValues[e.key];
    final isAnalog = e.type == KeyType.analog;
    if (isAnalog) {
      _rawAnalog.add(e.key);
      _rawRest.putIfAbsent(e.key, () => e.value);
    }
    _rawValues[e.key] = e.value;
    final sig = rawSignals.putIfAbsent(e.key, () => RawSignal(info.name, e.key, e.value));
    sig.value = e.value;
    rawRevision.value++;

    final before = _pad.pressedSet(_deadzone);

    // 1. Mapping the user taught for this model, 2. the built-in database.
    var recognised = false;
    final learned = profile?.rawMap[e.key];
    if (learned != null) {
      for (final m in learned) {
        _applyLearned(m, e.value);
      }
      recognised = true;
    } else {
      for (final n in _normalizer.normalize(e)) {
        if (n.button != null) _pad.setButton(n.button!, n.value);
        if (n.axis != null) _pad.setAxis(n.axis!, n.value);
        recognised = true;
      }
    }

    if (_teach != null) _teachFeed(e, prev, info);
    if (_capturing != null) _captureFeed(e, prev, recognised, before);
  }

  void _applyLearned(RawMapping m, double v) {
    final s = m.sign * v;
    final axis = m.axis;
    if (axis != null) {
      final isTrigger = axis == GamepadAxis.leftTrigger || axis == GamepadAxis.rightTrigger;
      _pad.setAxis(axis, isTrigger ? math.max(0, s) : s.clamp(-1.0, 1.0));
      return;
    }
    final button = m.button;
    if (button != null) _pad.setButton(button, math.max(0, s));
  }

  /// How far a raw signal moved from its resting value, and the direction.
  double _delta(String key, double v) =>
      _rawAnalog.contains(key) ? v - (_rawRest[key] ?? 0) : v;

  bool _rawPressed(String key, int sign) {
    final v = _rawValues[key];
    if (v == null) return false;
    final d = _delta(key, v) * sign;
    return d > (_rawAnalog.contains(key) ? math.max(_deadzone, 0.5) : 0.5);
  }

  // ---------------------------------------------------------------------------
  // Learning a binding for one action
  // ---------------------------------------------------------------------------
  void beginCapture(CarAction action) {
    _teach = null;
    _capturing = action;
    notifyListeners();
  }

  void cancelCapture() {
    _capturing = null;
    notifyListeners();
  }

  void _captureFeed(GamepadEvent e, double? prev, bool recognised, Set<PadInput> before) {
    final action = _capturing;
    if (action == null) return;
    final after = _pad.pressedSet(_deadzone);
    final fresh = after.difference(before);
    if (fresh.isNotEmpty) {
      addBinding(action, InputRef.pad(fresh.first));
      _capturing = null;
      notifyListeners();
      return;
    }
    if (recognised) return;
    // A signal the app does not know: bind it raw.
    final now = _delta(e.key, e.value);
    final was = prev == null ? 0.0 : _delta(e.key, prev);
    const threshold = 0.7;
    if (now.abs() >= threshold && was.abs() < threshold) {
      addBinding(action, InputRef.raw(e.key, now < 0 ? -1 : 1));
      _capturing = null;
      notifyListeners();
    }
  }

  void addBinding(CarAction action, InputRef ref) {
    final list = List<InputRef>.of(_bindings[action] ?? const []);
    if (!list.contains(ref)) list.add(ref);
    _bindings = {..._bindings, action: list};
    _saveBindings();
    notifyListeners();
  }

  void removeBinding(CarAction action, InputRef ref) {
    final list = List<InputRef>.of(_bindings[action] ?? const [])..remove(ref);
    _bindings = {..._bindings, action: list};
    _saveBindings();
    notifyListeners();
  }

  void resetBindings() {
    _bindings = defaultBindings();
    _saveBindings();
    notifyListeners();
  }

  List<CarAction> actionsUsing(InputRef ref) =>
      [for (final a in CarAction.values) if (_bindings[a]?.contains(ref) ?? false) a];

  void _saveBindings() => _prefs.setString('bindings', encodeBindings(_bindings));

  // ---------------------------------------------------------------------------
  // Teaching an unknown controller
  // ---------------------------------------------------------------------------
  void beginTeaching(ControllerInfo info) {
    _capturing = null;
    final existing = _profiles[info.profileKey];
    _teach = TeachSession(existing ??
        ControllerProfile(key: info.profileKey, name: info.name));
    notifyListeners();
  }

  void skipTeachStep() {
    final t = _teach;
    if (t == null || t.finished) return;
    t.advance();
    if (t.finished) _commitTeaching();
    notifyListeners();
  }

  void cancelTeaching() {
    _teach = null;
    notifyListeners();
  }

  /// Closes the finished wizard.
  void finishTeaching() {
    _teach = null;
    notifyListeners();
  }

  void _teachFeed(GamepadEvent e, double? prev, ControllerInfo info) {
    final t = _teach;
    if (t == null || t.finished) return;
    final step = t.current;
    final now = _delta(e.key, e.value);
    final was = prev == null ? 0.0 : _delta(e.key, prev);
    final analog = e.type == KeyType.analog;

    final threshold = step.kind == TeachKind.stickAxis ? 0.7 : 0.6;
    if (now.abs() < threshold || was.abs() >= threshold) return;
    if (step.kind == TeachKind.stickAxis && !analog) return;
    final sign = now < 0 ? -1 : 1;
    // Ignore a signal already taught for another role in this session.
    if (t.draft[e.key]?.any((m) => m.role == step.id) ?? false) return;
    t.add(e.key, RawMapping(step.id, sign));
    t.advance();
    if (t.finished) _commitTeaching();
    notifyListeners();
  }

  void _commitTeaching() {
    final t = _teach;
    if (t == null) return;
    final p = t.profile;
    // Taught signals replace anything older for the same roles.
    final roles = {for (final l in t.draft.values) for (final m in l) m.role};
    for (final list in p.rawMap.values) {
      list.removeWhere((m) => roles.contains(m.role));
    }
    p.rawMap.removeWhere((_, v) => v.isEmpty);
    for (final e in t.draft.entries) {
      p.rawMap.putIfAbsent(e.key, () => []).addAll(e.value);
    }
    _profiles = {..._profiles, p.key: p};
    _saveProfiles();
  }

  void forgetProfile(String key) {
    _profiles = {..._profiles}..remove(key);
    _saveProfiles();
    notifyListeners();
  }

  void _saveProfiles() => _prefs.setString('profiles', encodeProfiles(_profiles));

  // ---------------------------------------------------------------------------
  // Keyboard
  // ---------------------------------------------------------------------------
  bool _typingInTextField() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyRepeatEvent) {
      return _capturing != null || (_keyboardEnabled && _isBoundKey(event.physicalKey));
    }
    final down = event is KeyDownEvent;
    final key = event.physicalKey;

    if (down && _capturing != null) {
      if (key == PhysicalKeyboardKey.escape) {
        cancelCapture();
      } else {
        addBinding(_capturing!, InputRef.key(key));
        _capturing = null;
        notifyListeners();
      }
      return true;
    }
    if (_teach != null && !_teach!.finished && down && key == PhysicalKeyboardKey.escape) {
      cancelTeaching();
      return true;
    }
    if (!_keyboardEnabled || _typingInTextField()) return false;
    // Leave system shortcuts alone.
    final hw = HardwareKeyboard.instance;
    if (hw.isMetaPressed || hw.isControlPressed || hw.isAltPressed) {
      _keysDown.remove(key.usbHidUsage);
      return false;
    }
    if (down) {
      _keysDown.add(key.usbHidUsage);
    } else {
      _keysDown.remove(key.usbHidUsage);
    }
    return _isBoundKey(key);
  }

  bool _isBoundKey(PhysicalKeyboardKey key) {
    for (final list in _bindings.values) {
      for (final r in list) {
        if (r.keyUsage == key.usbHidUsage) return true;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // On-screen (touch / mouse) controls
  // ---------------------------------------------------------------------------
  void setVirtual(CarAction action, bool down) {
    final changed = down ? _virtual.add(action) : _virtual.remove(action);
    if (changed) _tick();
  }

  bool isLatched(CarAction action) => _latched.contains(action);

  /// A tap on an on-screen button that switches on and stays on until tapped
  /// again. Controller and keyboard inputs still apply only while held.
  void toggleLatched(CarAction action) {
    if (!_latched.remove(action)) _latched.add(action);
    _tick();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------
  set autoConnect(bool v) {
    _autoConnect = v;
    if (!v) _lostCar = null;
    _prefs.setBool('autoConnect', v);
    notifyListeners();
  }

  set keyboardEnabled(bool v) {
    _keyboardEnabled = v;
    _keysDown.clear();
    _prefs.setBool('keyboard', v);
    notifyListeners();
  }

  set deadzone(double v) {
    _deadzone = v;
    _prefs.setDouble('deadzone', v);
    notifyListeners();
  }

  set onScreenControls(bool v) {
    _onScreenControls = v;
    if (!v) _latched.clear(); // nothing left on screen to switch it off
    _prefs.setBool('onScreen', v);
    notifyListeners();
  }

  set localeCode(String v) {
    _localeCode = v;
    _prefs.setString('locale', v);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Evaluating inputs and sending
  // ---------------------------------------------------------------------------
  bool _refDown(InputRef r) {
    switch (r.kind) {
      case InputKind.pad:
        final p = r.padInput;
        return p != null && _pad.pressed(p, _deadzone);
      case InputKind.key:
        return _keyboardEnabled && _keysDown.contains(r.keyUsage);
      case InputKind.raw:
        return _rawPressed(r.rawKey!, r.rawSign);
    }
  }

  bool _held(CarAction a) =>
      _virtual.contains(a) || _latched.contains(a) || (_bindings[a]?.any(_refDown) ?? false);

  CarCommand _read({required bool toggles}) {
    final held = {for (final a in CarAction.values) a: _held(a)};
    if (toggles && held[CarAction.light]! && _prevHeld[CarAction.light] != true) {
      _light = !_light;
    }
    _prevHeld
      ..clear()
      ..addAll(held);
    final f = held[CarAction.forward]!, r = held[CarAction.reverse]!;
    final l = held[CarAction.left]!, rt = held[CarAction.right]!;
    return CarCommand(
      forward: f && !r,
      reverse: r && !f,
      left: l && !rt,
      right: rt && !l,
      light: _light,
      turbo: held[CarAction.turbo]!,
      donut: held[CarAction.donut]!,
    );
  }

  void _tick() {
    final wasBusy = _capturing != null || _teach != null;
    var c = _read(toggles: !wasBusy);
    if (wasBusy) c = c.neutral;
    if (c != _cmd) {
      _cmd = c;
      notifyListeners();
    }
    if (_link != LinkState.connected || _writing) return;
    final stale = DateTime.now().difference(_lastSent) > const Duration(milliseconds: 200);
    if (c != _lastSentCmd || stale) {
      _writing = true;
      _sendNow(c).whenComplete(() => _writing = false);
    }
  }
}
