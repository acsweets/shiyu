import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shiyu/main.dart' as application;
import 'package:shiyu/platform/rust/generated/api/diagnostics.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('应用启动并通过真实 Rust 动态库完成探测', _verifyNativeBridge);
}

/// 同时检查打包、加载、异步调用和无符号边界，禁止用 mock 替代原生链路。
Future<void> _verifyNativeBridge(WidgetTester tester) async {
  await application.main();
  await tester.pumpAndSettle();
  expect(await bridgeProbe(challenge: 41), 'shiyu-core:42');
  expect(await bridgeProbe(challenge: 0), 'shiyu-core:1');
  expect(await bridgeProbe(challenge: 0xFFFFFFFF), 'shiyu-core:0');
  expect(tester.takeException(), isNull);

  if (Platform.isAndroid) {
    const MethodChannel channel = MethodChannel('shiyu/m0_probe');
    expect(await channel.invokeMethod<String>('probe'), 'shiyu-core:42');
  }
}
