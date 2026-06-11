/// BLE identifiers for the IncreMat mat. These MUST match the values
/// programmed into the ESP32-S3 firmware (and the caregiver app's copy).
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
