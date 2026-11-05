import 'package:shiyu/features/retirement/application/retirement_controller.dart';
import 'package:shiyu/features/retirement/data/settings_store.dart';
import 'package:shiyu/features/retirement/domain/core_gateway.dart';
import 'package:shiyu/platform/widgets/widget_bridge.dart';

class MemorySettingsStore implements SettingsStore {
  /// 仅供测试保存，避免读取或改写真实应用数据目录。
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String json) async {
    value = json;
  }
}

class TestCore implements CoreGateway {
  @override
  Future<String> defaults() async =>
      '{"schema_version":1,"time_zone":"Asia/Shanghai","retirement_date":null}';
  @override
  Future<String> validate(String settings) async =>
      '{"ok":true,"settings":$settings,"errors":[]}';
  @override
  Future<String> compute(
    String settings,
    int nowMillis, {
    String holidayJson = '{}',
  }) async =>
      '{"ok":true,"snapshot":{"is_workday":true,"retirement":{"status":"unconfigured","remaining_days":0,"remaining_seconds":0}},"errors":[]}';
}

class TestWidgets extends WidgetBridge {
  @override
  bool get supported => false;
  @override
  Future<void> refresh() async {}
}

Future<RetirementController> createTestController() async {
  final RetirementController controller = RetirementController(
    core: TestCore(),
    store: MemorySettingsStore(),
    widgets: TestWidgets(),
  );
  await controller.initialize();
  return controller;
}
