import 'package:blemulator/blemulator.dart';
import 'package:blemulator/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pedantic/pedantic.dart';

import '../../factory/simulation_manager_factory.dart';

class MockedPeripheral extends Mock implements SimulatedPeripheral {}

void main() {
  const DEVICE_ID = 'qwe123';
  DiscoveryMixin discoveryMixin;
  var mockedPeripheral;

  setUp(() {
    mockedPeripheral = MockedPeripheral();
    when(mockedPeripheral.id).thenAnswer((_) => DEVICE_ID);
    when(mockedPeripheral.isConnected()).thenAnswer((_) => true);
    when(mockedPeripheral.onDiscovery()).thenAnswer((_) => Future.sync(() {}));
    when(mockedPeripheral.services()).thenAnswer((_) => <SimulatedService>[]);
    discoveryMixin = SimulationManagerFactory().create()
      ..addSimulatedPeripheral(mockedPeripheral);
  });

  test(
      'discoverAllServicesAndCharacteristics triggers error when transaction with given id has not been finished yet',
      () async {
    when(mockedPeripheral.onDiscoveryRequest())
        .thenAnswer((_) => Future.delayed(Duration(milliseconds: 200)));

    unawaited(expectLater(
      discoveryMixin.discoverAllServicesAndCharacteristics(DEVICE_ID, '1'),
      throwsA(equals(SimulatedBleError(
          BleErrorCode.OperationCancelled, 'Operation cancelled'))),
    ));
    await Future.delayed(Duration(milliseconds: 100));
    unawaited(
        discoveryMixin.discoverAllServicesAndCharacteristics(DEVICE_ID, '1'));
  });

  test(
      'discoverAllServicesAndCharacteristics does not trigger error when transaction with given id has already finished',
      () async {
    when(mockedPeripheral.onDiscoveryRequest())
        .thenAnswer((_) => Future.sync(() {}));

    await expectLater(
      discoveryMixin.discoverAllServicesAndCharacteristics(DEVICE_ID, '1'),
      completion(equals([])),
    );

    await Future.delayed(Duration(milliseconds: 100));

    await discoveryMixin.discoverAllServicesAndCharacteristics(DEVICE_ID, '1');
  });
}
