import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shiyu/features/diagnostics/desktop_probe_controller.dart';
import 'package:shiyu/main.dart' as application;
import 'package:window_manager/window_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('桌面窗口与系统入口可以初始化并恢复', _verifyDesktopWindow);
}

/// 使用真实插件检查窗口读回及穿透恢复，保留视觉效果和实际快捷键供用户复核。
Future<void> _verifyDesktopWindow(WidgetTester tester) async {
  if (!Platform.isWindows && !Platform.isMacOS) return;
  await application.main();
  await tester.pumpAndSettle();
  final DesktopProbeController controller = DesktopProbeController();
  await controller.initialize();
  try {
    await controller.makeFrameless();
    await windowManager.setAlwaysOnTop(true);
    expect(await windowManager.isAlwaysOnTop(), isTrue);
    await windowManager.hide();
    expect(await windowManager.isVisible(), isFalse);
    await controller.restore();
    await _waitUntilVisible();
    expect(await windowManager.isVisible(), isTrue);
    await controller.testClickThrough();
    await controller.restore();
    await _waitUntilVisible();
    expect(await windowManager.isVisible(), isTrue);
  } finally {
    await windowManager.setAlwaysOnTop(false);
    await controller.dispose();
  }
}

/// Windows 使用 ShowWindowAsync，等待系统完成显示，不假设通道返回即已可见。
Future<void> _waitUntilVisible() async {
  final Stopwatch deadline = Stopwatch()..start();
  while (!await windowManager.isVisible()) {
    if (deadline.elapsed > const Duration(seconds: 2)) {
      throw StateError('窗口未在两秒内恢复可见');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
