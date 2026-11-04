import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/shiyu_app.dart';
import 'platform/rust/generated/frb_generated.dart';
import 'features/retirement/application/retirement_controller.dart';
import 'features/retirement/data/settings_store.dart';
import 'features/retirement/domain/core_gateway.dart';
import 'platform/widgets/widget_bridge.dart';
import 'platform/desktop/floating_window_controller.dart';

/// 启动应用并在根节点提供 Riverpod 容器。
Future<void> main() async {
  await runShiyu();
}

/// 测试可关闭浮窗行为或替换存储，避免修改用户的真实设置。
Future<RetirementController> runShiyu({
  bool floating = true,
  SettingsStore? storage,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final WidgetBridge widgets = WidgetBridge();
  final RetirementController controller = RetirementController(
    core: RustCoreGateway(),
    store: storage ?? await createSettingsStore(widgets),
    widgets: widgets,
  );
  await controller.initialize();
  FloatingWindowController? window;
  if (floating && (Platform.isWindows || Platform.isMacOS)) {
    window = FloatingWindowController(controller.setVisible);
    await window.initialize();
  }
  runApp(
    ProviderScope(
      child: ShiyuApp(controller: controller, window: window),
    ),
  );
  return controller;
}
