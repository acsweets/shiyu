import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/shiyu_app.dart';
import 'platform/rust/generated/frb_generated.dart';

/// 启动应用并在根节点提供 Riverpod 容器。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const ProviderScope(child: ShiyuApp()));
}
