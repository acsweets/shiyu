import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';

import 'support/test_controller.dart';

class UnsupportedVersionCore extends TestCore {
  @override
  Future<String> validate(String settings) async =>
      '{"ok":false,"errors":[{"field":"schema_version","code":"unsupported_version"}]}';
}

void main() {
  test('未来版本设置保留原件且禁止用默认值覆盖', _verifyUnknownVersion);
}

Future<void> _verifyUnknownVersion() async {
  const String original = '{"schema_version":99,"future_field":true}';
  final MemorySettingsStore store = MemorySettingsStore()..value = original;
  final RetirementController controller = RetirementController(
    core: UnsupportedVersionCore(),
    store: store,
    widgets: TestWidgets(),
  );
  await controller.initialize();
  expect(controller.editingBlocked, isTrue);
  expect(await controller.save('2050-01-01', 'Asia/Shanghai'), isFalse);
  expect(store.value, original);
  controller.dispose();
}
