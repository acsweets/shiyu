import 'dart:convert';

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
  Future<String> changeCountdown(
    String settings,
    String change,
    int nowMillis,
  ) async => '{"ok":false,"errors":[]}';

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
  }) async {
    final Map<String, dynamic> values =
        jsonDecode(settings) as Map<String, dynamic>;
    final Map<String, dynamic>? display =
        values['display'] as Map<String, dynamic>?;
    return jsonEncode(<String, Object?>{
      'ok': true,
      'snapshot': <String, Object?>{
        'is_workday': true,
        'retirement': <String, Object?>{
          'status': 'unconfigured',
          'remaining_days': 0,
          'remaining_seconds': 0,
        },
        'hidden_metric_titles': display?['hidden_metric_titles'],
        if (display?['life_mode'] == 'elapsed_days')
          'life': <String, Object?>{'status': 'elapsed', 'elapsed_days': 1234},
      },
      'errors': <Object?>[],
    });
  }
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
