import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shiyu/platform/rust/generated/api/snapshot.dart' as rust;
import 'package:shiyu/platform/rust/generated/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('两套真实绑定保持薪资精度与时间线一致', _verifySalaryTimeline);
}

/// 使用合成配置测试真实 Rust 绑定，不保存到设备。
Future<void> _verifySalaryTimeline(WidgetTester tester) async {
  await RustLib.init();
  const int start = 1767585600000;
  const String settings =
      '{"hide_amount":false,"salary":{"gross_monthly":"22000"}}';
  const String command = '''
{"action":"upsert","item":{"id":"launch","name":"产品上线","target":"2026-01-05T12:00:01"}}
''';
  final String update = await rust.updateCustomCountdown(
    settingsJson: settings,
    changeJson: command,
    nowMillis: start,
  );
  final Map<String, dynamic> changed =
      jsonDecode(update) as Map<String, dynamic>;
  expect(changed['ok'], isTrue);
  final String normalized = jsonEncode(changed['settings']);

  final String raw = await rust.computeTimeline(
    settingsJson: normalized,
    holidayJson: '{}',
    startMillis: start,
    stepSeconds: 1,
    count: 3,
  );
  final Map<String, dynamic> timeline = jsonDecode(raw) as Map<String, dynamic>;
  expect(timeline['ok'], isTrue);
  final List<dynamic> entries = timeline['snapshots'] as List<dynamic>;
  expect(entries, hasLength(3));
  final Map<String, dynamic> first = entries[0] as Map<String, dynamic>;
  final Map<String, dynamic> next = entries[1] as Map<String, dynamic>;
  expect(first['salary'], containsPair('today_earned', '375.00'));
  expect(next['salary'], containsPair('month_earned', '2375.00'));
  expect(first['custom_countdowns'][0]['remaining_seconds'], 1);
  expect(next['custom_countdowns'][0]['status'], 'expired');
  expect(next['custom_countdowns'][0]['remaining_seconds'], 0);
  final String point = await rust.computeSnapshot(
    settingsJson: normalized,
    holidayJson: '{}',
    nowMillis: start,
  );
  final Map<String, dynamic> snapshot =
      jsonDecode(point) as Map<String, dynamic>;
  expect(snapshot['snapshot'], first);

  if (Platform.isAndroid) {
    const MethodChannel channel = MethodChannel('shiyu/widgets');
    final String? native = await channel.invokeMethod<String>(
      'verifyCoreTimeline',
      <String, Object>{
        'settingsJson': normalized,
        'holidayJson': '{}',
        'startMillis': start,
        'stepSeconds': 1,
        'count': 3,
      },
    );
    expect(jsonDecode(native!), timeline);
    final List<String>? recovery = await channel.invokeListMethod<String>(
      'verifyWidgetRecovery',
      <String, Object>{'settingsJson': normalized, 'now': start},
    );
    expect(recovery, hasLength(4));
    expect(jsonDecode(recovery!.first), snapshot);
    for (final String item in recovery.skip(1)) {
      final Map<String, dynamic> reply =
          jsonDecode(item) as Map<String, dynamic>;
      final Map<String, dynamic> value =
          reply['snapshot'] as Map<String, dynamic>;
      expect(value['salary'], containsPair('today_earned', '****'));
      expect(value['salary'], containsPair('month_earned', '****'));
      expect(value['work'], first['work']);
    }
  }
}
