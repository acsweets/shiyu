import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../platform/rust/generated/api/diagnostics.dart';
import 'desktop_probe_controller.dart';

/// 独立开发入口，用于检查真实绑定及桌面系统行为。
class ProbeApp extends StatefulWidget {
  const ProbeApp({required this.desktop, super.key});

  /// 移动端不创建或调用桌面控制器。
  final DesktopProbeController? desktop;

  @override
  State<ProbeApp> createState() => _ProbeAppState();
}

class _ProbeAppState extends State<ProbeApp> {
  /// 最近一次真实 Rust 调用的结果或可见错误。
  String _result = '尚未调用 Rust';

  Future<void> _probe() async {
    try {
      final String result = await bridgeProbe(challenge: 41);
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _result = '调用失败：$error');
    }
  }

  void _drag(DragStartDetails details) {
    if (widget.desktop != null) windowManager.startDragging();
  }

  @override
  Widget build(BuildContext context) {
    final DesktopProbeController? desktop = widget.desktop;
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xE0FFFFFF),
        appBar: AppBar(title: const Text('时余 M0 平台验证')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text('平台：${Platform.operatingSystem}'),
            const SizedBox(height: 16),
            SelectableText(_result),
            FilledButton(onPressed: _probe, child: const Text('调用真实 Rust 探测')),
            if (desktop != null) ...<Widget>[
              OutlinedButton(
                onPressed: desktop.makeFrameless,
                child: const Text('无边框 / 透明背景'),
              ),
              OutlinedButton(
                onPressed: desktop.toggleAlwaysOnTop,
                child: const Text('切换置顶'),
              ),
              OutlinedButton(
                onPressed: desktop.testClickThrough,
                child: const Text('点击穿透三秒后自动恢复'),
              ),
              GestureDetector(
                onPanStart: _drag,
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('从这里拖动窗口'),
                ),
              ),
              const Text('Ctrl+Shift+T 显示/隐藏；托盘可恢复窗口或退出。'),
            ],
            const SizedBox(height: 24),
            const Text('此入口仅用于开发验证，不代表计时、薪资或最终浮窗已完成。'),
          ],
        ),
      ),
    );
  }
}
