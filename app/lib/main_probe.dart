import 'dart:io';

import 'package:flutter/material.dart';

import 'features/diagnostics/desktop_probe_controller.dart';
import 'features/diagnostics/probe_app.dart';
import 'platform/rust/generated/frb_generated.dart';

/// 显式启动的 M0 验证程序，与普通应用入口分开。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  DesktopProbeController? desktop;
  if (Platform.isWindows || Platform.isMacOS) {
    desktop = DesktopProbeController();
    await desktop.initialize();
  }
  runApp(ProbeApp(desktop: desktop));
}
