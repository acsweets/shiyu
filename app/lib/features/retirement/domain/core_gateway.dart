import '../../../platform/rust/generated/api/snapshot.dart' as rust;

abstract interface class CoreGateway {
  Future<String> defaults();
  Future<String> validate(String settings);
  Future<String> changeCountdown(String settings, String change, int nowMillis);
  Future<String> compute(
    String settings,
    int nowMillis, {
    String holidayJson = '{}',
  });
}

class RustCoreGateway implements CoreGateway {
  @override
  Future<String> defaults() => rust.defaultSettings();
  @override
  Future<String> validate(String settings) =>
      rust.validateSettings(settingsJson: settings);
  @override
  Future<String> changeCountdown(
    String settings,
    String change,
    int nowMillis,
  ) => rust.updateCustomCountdown(
    settingsJson: settings,
    changeJson: change,
    nowMillis: nowMillis,
  );
  @override
  Future<String> compute(
    String settings,
    int nowMillis, {
    String holidayJson = '{}',
  }) => rust.computeSnapshot(
    settingsJson: settings,
    holidayJson: holidayJson,
    nowMillis: nowMillis,
  );
}
