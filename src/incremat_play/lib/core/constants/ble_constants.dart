/// BLE identifiers for the IncreMat mat. These MUST match the values
/// programmed into the ESP32-S3 firmware (and the caregiver app's copy).
///
/// The Play app only needs a SUBSET of the caregiver app's characteristics: it
/// reads reps and mat-placement directly off the mat so the senior sees their
/// own count live. (See the caregiver app's ble_constants.dart for the full
/// GATT/UUID explanation.) Two apps connecting at once is why the firmware must
/// allow 2 simultaneous BLE connections.
class BleConstants {
  static const String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c3319100';
  static const String repCountCharUuid = '4fafc201-1fb5-459e-8fcc-c5c9c3319101';
  static const String matPlacedCharUuid =
      '4fafc201-1fb5-459e-8fcc-c5c9c3319104';

  // Firmware protocol used by the Play app:
  //   repCount  char → notify, 2 bytes little-endian uint16 = cumulative reps
  //   matPlaced char → notify, 1 byte: 1 = on chair, 0 = removed

  static const String deviceNamePrefix = 'IncreMat';
  static const int scanTimeoutSeconds = 15;
  static const int connectionTimeoutSeconds = 10;
}
