import '../../../platform/rust/generated/api/snapshot.dart' as rust;

abstract interface class CoreGateway {
  Future<String> defaults();
  Future<String> validate(String settings);
  Future<String> compute(String settings, int nowMillis);
}

class RustCoreGateway implements CoreGateway {
  @override
  Future<String> defaults() => rust.defaultSettings();
  @override
  Future<String> validate(String settings) =>
      rust.validateSettings(settingsJson: settings);
  @override
  Future<String> compute(String settings, int nowMillis) =>
      rust.computeSnapshot(
        settingsJson: settings,
        holidayJson: '{}',
        nowMillis: nowMillis,
      );
}
