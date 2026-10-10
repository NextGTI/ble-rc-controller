import 'package:ble_rc_controller/core/car_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('four bar levels map to three words', () {
    expect(const FoundCar(id: 'a', name: 'SL-X', rssi: -55).signalStrength,
        SignalStrength.strong);
    expect(const FoundCar(id: 'a', name: 'SL-X', rssi: -70).signalStrength,
        SignalStrength.medium);
    expect(const FoundCar(id: 'a', name: 'SL-X', rssi: -80).signalStrength,
        SignalStrength.medium);
    expect(const FoundCar(id: 'a', name: 'SL-X', rssi: -90).signalStrength,
        SignalStrength.weak);
  });
}
