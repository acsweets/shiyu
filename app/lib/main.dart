import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/shiyu_app.dart';

/// 启动应用并在根节点提供 Riverpod 容器。
void main() {
  runApp(const ProviderScope(child: ShiyuApp()));
}
