import 'dart:async';
import 'dart:typed_data';

import 'package:ble_rc_controller/core/car_transport.dart';
import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/core/protocol.dart';
import 'package:ble_rc_controller/input/controller_profile.dart';
import 'package:ble_rc_controller/input/input_ref.dart';
import 'package:ble_rc_controller/input/pad_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeTransport implements CarTransport {
  final scan = StreamController<FoundCar>.broadcast();
  final conn = StreamController<bool>.broadcast();
  final writes = <Uint8List>[];
  final connected = <String>[];
  bool failConnect = false;

  @override
  Stream<BluetoothState> get availability => const Stream.empty();
  @override
  Future<BluetoothState> currentAvailability() async => BluetoothState.ready;
  @override
  Future<void> requestPermissions() async {}
  @override
  Stream<FoundCar> get scanResults => scan.stream;
  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}
  @override
  Future<void> connect(String id) async {
    if (failConnect) throw StateError('nope');
    connected.add(id);
  }

  @override
  Future<void> disconnect(String id) async => connected.remove(id);
  @override
  Stream<bool> connectionOf(String id) => conn.stream;
  @override
  Future<void> writeControl(String id, Uint8List bytes) async => writes.add(bytes);
  @override
  Stream<int> batteryOf(String id) => Stream.value(77);
}

GamepadEvent btn(String key, double v, {String pad = 'g1'}) => GamepadEvent(
    gamepadId: pad, timestamp: 0, type: KeyType.button, key: key, value: v);
GamepadEvent axis(String key, double v, {String pad = 'g1'}) => GamepadEvent(
    gamepadId: pad, timestamp: 0, type: KeyType.analog, key: key, value: v);

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 70));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTransport transport;
  late StreamController<GamepadEvent> raw;
  late StreamController<GamepadConnectionEvent> connEvents;
  late Driver driver;

  Future<void> setUp0([Map<String, Object> prefs = const {}, Duration? carStaleAfter]) async {
    SharedPreferences.setMockInitialValues(prefs);
    transport = FakeTransport();
    raw = StreamController<GamepadEvent>.broadcast();
    connEvents = StreamController<GamepadConnectionEvent>.broadcast();
    driver = Driver(
      transport: transport,
      prefs: await SharedPreferences.getInstance(),
      rawEvents: raw.stream,
      connectionEvents: connEvents.stream,
      listGamepads: () async => [],
      // Windows key names, so the test does not depend on the host OS.
      normalizer: GamepadNormalizer.forPlatform(GamepadPlatform.windows),
      enableKeyboard: false,
      carStaleAfter: carStaleAfter ?? const Duration(seconds: 6),
    );
    await driver.start();
  }

  tearDown(() async {
    driver.dispose();
    await raw.close();
    await connEvents.close();
  });

  Future<void> connectCar() async {
    transport.scan.add(const FoundCar(id: 'car1', name: 'SL-SF-25', rssi: -55));
    await settle();
    await driver.connect('car1');
  }

  test('a found car shows up, and connecting works', () async {
    await setUp0();
    transport.scan.add(const FoundCar(id: 'car1', name: 'SL-SF-25', rssi: -55));
    await settle();
    expect(driver.cars.single.model, 'SF-25');
    await driver.connect('car1');
    expect(driver.link, LinkState.connected);
    await settle();
    expect(driver.battery, 77);
  });

  test('a deliberate disconnect is not undone by auto-reconnect', () async {
    // The last car is remembered, so it would be picked up again on its own.
    await setUp0({'lastCar': 'car1'}, const Duration(milliseconds: 50));
    transport.scan.add(const FoundCar(id: 'car1', name: 'SL-SF-25', rssi: -55));
    await settle();
    expect(driver.link, LinkState.connected, reason: 'auto-connect to the last car on startup');

    await driver.disconnect();
    expect(driver.link, LinkState.idle);

    // The car keeps advertising. Once its stale entry has been pruned, it is
    // "new" again when it reappears: that must not reconnect.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    transport.scan.add(const FoundCar(id: 'car1', name: 'SL-SF-25', rssi: -55));
    await settle();
    expect(driver.link, LinkState.idle);

    // Connecting by hand works, and re-arms auto-reconnect for dropped links.
    await driver.connect('car1');
    expect(driver.link, LinkState.connected);
    transport.conn.add(false);
    await settle();
    expect(driver.link, LinkState.idle);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    transport.scan.add(const FoundCar(id: 'car1', name: 'SL-SF-25', rssi: -55));
    await settle();
    expect(driver.link, LinkState.connected, reason: 'a dropped link still reconnects');
  });

  test('failed connection reports a message and returns to idle', () async {
    await setUp0();
    transport.failConnect = true;
    await driver.connect('car1');
    expect(driver.link, LinkState.idle);
    expect(driver.message, MessageKind.connectFailed);
  });

  test('right trigger drives forward, release stops it', () async {
    await setUp0();
    await connectCar();
    raw.add(axis('rightTrigger', 1.0));
    await settle();
    expect(driver.command.forward, isTrue);
    expect(transport.writes.last, [1, 1, 0, 0, 0, 0, 0, 0]);
    raw.add(axis('rightTrigger', 0.0));
    await settle();
    expect(driver.command.forward, isFalse);
    expect(transport.writes.last, [1, 0, 0, 0, 0, 0, 0, 0]);
  });

  test('left stick steers but up/down on it does not drive', () async {
    await setUp0();
    await connectCar();
    raw.add(axis('leftThumbstickX', -1.0));
    raw.add(axis('leftThumbstickY', 1.0));
    await settle();
    expect(driver.command.left, isTrue);
    expect(driver.command.forward, isFalse);
    expect(driver.command.reverse, isFalse);
  });

  test('light toggles on each press', () async {
    await setUp0();
    await connectCar();
    raw.add(btn('a', 1));
    await settle();
    raw.add(btn('a', 0));
    await settle();
    expect(driver.command.light, isTrue);
    raw.add(btn('a', 1));
    await settle();
    raw.add(btn('a', 0));
    await settle();
    expect(driver.command.light, isFalse);
  });

  test('forward and reverse together cancel out', () async {
    await setUp0();
    await connectCar();
    raw.add(axis('rightTrigger', 1));
    raw.add(axis('leftTrigger', 1));
    await settle();
    expect(driver.command.forward, isFalse);
    expect(driver.command.reverse, isFalse);
  });

  test('the packet is re-sent as a heartbeat while idle', () async {
    await setUp0();
    await connectCar();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(transport.writes.length, greaterThanOrEqualTo(2));
  });

  test('clearInputs stops the car', () async {
    await setUp0();
    await connectCar();
    raw.add(axis('rightTrigger', 1));
    await settle();
    expect(driver.command.forward, isTrue);
    driver.clearInputs();
    await settle();
    expect(driver.command.forward, isFalse);
    expect(transport.writes.last[1], 0);
  });

  test('disconnect sends a neutral packet first', () async {
    await setUp0();
    await connectCar();
    raw.add(axis('rightTrigger', 1));
    await settle();
    await driver.disconnect();
    expect(transport.writes.last, [1, 0, 0, 0, 0, 0, 0, 0]);
    expect(driver.link, LinkState.idle);
  });

  test('a dropped connection is reported', () async {
    await setUp0();
    await connectCar();
    transport.conn.add(false);
    await settle();
    expect(driver.link, LinkState.idle);
    expect(driver.message, MessageKind.dropped);
  });

  test('on-screen buttons drive the car', () async {
    await setUp0();
    await connectCar();
    driver.setVirtual(CarAction.forward, true);
    await settle();
    expect(driver.command.forward, isTrue);
    driver.setVirtual(CarAction.forward, false);
    await settle();
    expect(driver.command.forward, isFalse);
  });

  for (final action in [CarAction.turbo, CarAction.donut]) {
    bool on() => action == CarAction.turbo ? driver.command.turbo : driver.command.donut;
    final byte = action == CarAction.turbo ? 6 : 7;

    test('the on-screen ${action.name} stays on until tapped again', () async {
      await setUp0();
      await connectCar();
      driver.toggleLatched(action);
      await settle();
      expect(driver.isLatched(action), isTrue);
      expect(on(), isTrue);
      expect(transport.writes.last[byte], 1);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(on(), isTrue, reason: 'no finger on the screen, still on');
      driver.toggleLatched(action);
      await settle();
      expect(on(), isFalse);
      expect(transport.writes.last[byte], 0);
    });

    test('a latched ${action.name} is released on disconnect, on a dropped link and on clearInputs', () async {
      await setUp0();
      await connectCar();
      driver.toggleLatched(action);
      await driver.disconnect();
      expect(driver.isLatched(action), isFalse);

      await connectCar();
      driver.toggleLatched(action);
      transport.conn.add(false);
      await settle();
      expect(driver.isLatched(action), isFalse);

      await driver.connect('car1');
      driver.toggleLatched(action);
      driver.clearInputs();
      await settle();
      expect(driver.isLatched(action), isFalse);
      expect(on(), isFalse);
    });
  }

  test('the controller turbo and 360° spin still only apply while held', () async {
    await setUp0();
    await connectCar();
    raw.add(btn('b', 1));
    raw.add(btn('y', 1));
    await settle();
    expect(driver.command.turbo, isTrue);
    expect(driver.command.donut, isTrue);
    raw.add(btn('b', 0));
    raw.add(btn('y', 0));
    await settle();
    expect(driver.command.turbo, isFalse);
    expect(driver.command.donut, isFalse);
  });

  test('capture binds a standard controller input to an action', () async {
    await setUp0();
    driver.beginCapture(CarAction.turbo);
    raw.add(btn('rightShoulder', 1));
    await settle();
    expect(driver.capturing, isNull);
    expect(driver.bindings[CarAction.turbo], contains(InputRef.pad(PadInput.rightBumper)));
  });

  test('capture binds an unknown signal as a raw input', () async {
    await setUp0();
    driver.beginCapture(CarAction.donut);
    raw.add(btn('weird-button-9', 1));
    await settle();
    expect(driver.bindings[CarAction.donut], contains(InputRef.raw('weird-button-9', 1)));
    // ...and that raw input now triggers the action.
    await connectCar();
    raw.add(btn('weird-button-9', 0));
    await settle();
    raw.add(btn('weird-button-9', 1));
    await settle();
    expect(driver.command.donut, isTrue);
  });

  test('capture suppresses driving and ignores an already-held button', () async {
    await setUp0();
    raw.add(btn('a', 1)); // held before capture starts
    await settle();
    driver.beginCapture(CarAction.turbo);
    await settle();
    expect(driver.capturing, CarAction.turbo, reason: 'a held button is not a new press');
    driver.cancelCapture();
  });

  test('teaching an unknown controller maps its raw signals to roles', () async {
    await setUp0();
    const info = ControllerInfo(id: 'g1', name: 'Mystery Pad', vendorId: 0x1234, productId: 0x5678);
    driver.beginTeaching(info);

    // Step 1 "a": the mystery pad calls it btn-7.
    raw.add(btn('btn-7', 1));
    await settle();
    expect(driver.teaching!.index, 1);
    raw.add(btn('btn-7', 0));

    // Skip everything up to the first stick axis (index 10).
    while (driver.teaching!.index < 10) {
      driver.skipTeachStep();
    }
    // Left stick X: user pushes right, but this pad reports it inverted.
    raw.add(axis('axisA', 0.0));
    await settle();
    raw.add(axis('axisA', -1.0));
    await settle();
    expect(driver.teaching!.index, 11);

    while (!driver.teaching!.finished) {
      driver.skipTeachStep();
    }
    final profile = driver.profiles[info.profileKey]!;
    expect(profile.isCustom, isTrue);
    expect(profile.rawMap['btn-7']!.single.role, 'a');
    expect(profile.rawMap['axisA']!.single.role, 'axis:leftStickX');
    expect(profile.rawMap['axisA']!.single.sign, -1);

    // The taught mapping is applied to later events from that controller.
    driver.finishTeaching();
    raw.add(GamepadEvent(
        gamepadId: 'g1', timestamp: 0, type: KeyType.button, key: 'btn-7', value: 1, vendorId: 0x1234, productId: 0x5678));
    await settle();
    expect(driver.pressedPad, contains(PadInput.a));
    raw.add(GamepadEvent(
        gamepadId: 'g1', timestamp: 0, type: KeyType.analog, key: 'axisA', value: -1, vendorId: 0x1234, productId: 0x5678));
    await settle();
    expect(driver.pressedPad, contains(PadInput.leftStickRight), reason: 'inverted axis flipped by the taught sign');
  });

  test('bindings and profiles persist', () async {
    await setUp0();
    driver.addBinding(CarAction.turbo, InputRef.raw('X', 1));
    final prefs = await SharedPreferences.getInstance();
    final again = Driver(
      transport: FakeTransport(),
      prefs: prefs,
      rawEvents: const Stream.empty(),
      connectionEvents: const Stream.empty(),
      listGamepads: () async => [],
      enableKeyboard: false,
    );
    expect(again.bindings[CarAction.turbo], contains(InputRef.raw('X', 1)));
    again.dispose();
  });

  test('settings persist', () async {
    await setUp0({'deadzone': 0.5, 'locale': 'es', 'keyboard': false});
    expect(driver.deadzone, 0.5);
    expect(driver.localeCode, 'es');
    expect(driver.keyboardEnabled, isFalse);
  });
}
