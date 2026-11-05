import 'dart:async';

import 'package:flutter/material.dart';

import '../../retirement/application/retirement_controller.dart';
import '../../../platform/desktop/floating_window_controller.dart';
import '../data/sticker_layout.dart';
import 'countdown_sticker.dart';
import 'sticker_settings.dart';

class DesktopStickerPage extends StatefulWidget {
  const DesktopStickerPage({
    required this.controller,
    required this.window,
    this.layout,
    super.key,
  });

  /// 真实核心快照与业务设置。
  final RetirementController controller;

  /// 系统窗口、托盘和快捷键入口。
  final FloatingWindowController window;

  /// 测试可以传入临时外观存储。
  final StickerLayout? layout;
  @override
  State<DesktopStickerPage> createState() => _DesktopStickerPageState();
}

class _DesktopStickerPageState extends State<DesktopStickerPage>
    with WidgetsBindingObserver {
  /// 当前贴纸位置、开关与资源。
  late final StickerLayout _layout;
  @override
  void initState() {
    super.initState();
    _layout = widget.layout ?? StickerLayout();
    if (!_layout.ready) unawaited(_layout.load());
    _layout.addListener(_changed);
    widget.controller.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    widget.controller.setVisible(true);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.setVisible(false);
    widget.controller.removeListener(_changed);
    _layout.removeListener(_changed);
    if (widget.layout == null) _layout.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.controller.setVisible(true);
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      widget.controller.setVisible(false);
    }
  }

  void _dragWindow(DragStartDetails details) => unawaited(widget.window.drag());
  Future<void> _settings() =>
      showDialog<void>(context: context, builder: _settingsDialog);
  Widget _settingsDialog(BuildContext context) =>
      StickerSettings(layout: _layout, controller: widget.controller);

  /// 仅将 Rust 的非负秒数格式化为连贯文字，不另算业务目标。
  String _value(String id) {
    if (_layout.preview) return StickerLayout.examples[id]!;
    if (id != 'retirement') return '待接入';
    final String? status = widget.controller.snapshot?.status;
    if (status == 'retired') return '已退休';
    if (status != 'active') return '请设置退休日期';
    final Duration time = Duration(
      seconds: widget.controller.snapshot!.seconds,
    );
    return '${time.inDays}天 ${_two(time.inHours % 24)}小时 ${_two(time.inMinutes % 60)}分 ${_two(time.inSeconds % 60)}秒';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
  Widget _sticker(String id) {
    final Offset position = _layout.positions[id]!;
    final Size size = _layout.size(id);
    return Positioned(
      key: ValueKey<String>('position-$id'),
      left: position.dx,
      top: position.dy,
      width: size.width,
      height: size.height,
      child: CountdownSticker(
        id: id,
        title: StickerLayout.titles[id]!,
        value: _value(id),
        main: id == _layout.main,
        preview: _layout.preview,
        layout: _layout,
        onMove: (Offset delta) => _layout.move(id, delta),
        onEnd: _layout.persist,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFC68A59),
        surface: const Color(0xFFFFFBF4),
      ),
    ),
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: StickerLayout.canvas.width,
            height: StickerLayout.canvas.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  left: 24,
                  right: 24,
                  top: 4,
                  height: 40,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: _dragWindow,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBF4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _layout.preview
                                  ? '时余  /  猫猫贴纸 · 示例预览'
                                  : '时余  /  猫猫贴纸',
                              style: const TextStyle(
                                color: CountdownSticker.ink,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _tool(Icons.tune_rounded, '设置与贴纸开关', _settings),
                      const SizedBox(width: 8),
                      _tool(Icons.close_rounded, '隐藏到托盘', widget.window.hide),
                    ],
                  ),
                ),
                ..._layout.enabled
                    .where((String id) => id != _layout.main)
                    .map(_sticker),
                if (_layout.enabled.contains(_layout.main))
                  _sticker(_layout.main),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _layout.writeFailed
                            ? '排布保存失败，请检查应用目录'
                            : _layout.preview
                            ? '拖动贴纸自由摆放 · 示例时间仅供看效果 · Ctrl/Cmd+Shift+T 隐藏/恢复'
                            : '拖动贴纸自由摆放 · 右上角配置退休日期和时区',
                        style: const TextStyle(
                          color: CountdownSticker.ink,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _tool(IconData icon, String tooltip, VoidCallback action) => Material(
    color: const Color(0xFFFFFBF4),
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: action,
      tooltip: tooltip,
      icon: Icon(icon, size: 18, color: CountdownSticker.ink),
    ),
  );
}
