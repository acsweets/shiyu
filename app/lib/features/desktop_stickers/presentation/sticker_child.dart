import 'dart:async';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../application/sticker_group_view.dart';
import '../data/sticker_layout.dart';
import 'countdown_sticker.dart';

/// 子窗引擎直接进入展示页面，不重复注册托盘或读取业务配置。
Future<void> runStickerChild(Map<String, dynamic> options) async {
  WidgetsFlutterBinding.ensureInitialized();
  final WindowController owner = WindowController.fromWindowId(
    options['owner'] as String,
  );
  final Map<String, Object?> identity = <String, Object?>{
    'group': options['group'],
    'token': options['token'],
  };
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow();
  final Map<Object?, Object?>? data;
  try {
    data = await owner.invokeMethod<Map<Object?, Object?>>('view', identity);
  } on WindowChannelException {
    await windowManager.close();
    return;
  }
  if (data == null) {
    await windowManager.close();
    return;
  }
  final StickerGroupView view = StickerGroupView(data);
  await windowManager.setTitle('时余 · 倒计时');
  await windowManager.setAsFrameless();
  await windowManager.setBackgroundColor(Colors.transparent);
  await windowManager.setAlwaysOnTop(true);
  await windowManager.setSkipTaskbar(true);
  await windowManager.setMinimumSize(StickerLayout.minimum);
  await windowManager.setBounds(view.initialBounds);
  await windowManager.setPreventClose(true);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _StickerChild(owner: owner, identity: identity, initialView: view),
    ),
  );
  if (view.visible) await windowManager.show(inactive: true);
}

class _StickerChild extends StatefulWidget {
  const _StickerChild({
    required this.owner,
    required this.identity,
    required this.initialView,
  });

  /// 主引擎端点。
  final WindowController owner;

  /// 对应窗口槽位与实例令牌。
  final Map<String, Object?> identity;

  /// 首次展示前读取的快照。
  final StickerGroupView initialView;

  @override
  State<_StickerChild> createState() => _StickerChildState();
}

class _StickerChildState extends State<_StickerChild> with WindowListener {
  /// 本窗当前的快照。
  late StickerGroupView _view;

  /// 轮询轻量快照，独立引擎不需要自己的业务时钟。
  late final Timer _timer;

  /// 避免窗口操作交叠。
  bool _reading = false;

  /// 避免关闭时重复发送。
  bool _closing = false;

  /// 上次报告的几何信息。
  Rect? _reported;

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
    windowManager.addListener(this);
    unawaited(_register());
    _timer = Timer.periodic(const Duration(milliseconds: 450), _tick);
  }

  Future<void> _register() async {
    final WindowController window = await WindowController.fromCurrentEngine();
    await window.setWindowMethodHandler(_command);
  }

  Future<Object?> _command(MethodCall call) async {
    if (call.method != 'bounds') throw MissingPluginException(call.method);
    final Rect? bounds = StickerLayout.decodeBounds(call.arguments);
    if (bounds != null) await windowManager.setBounds(bounds);
    return null;
  }

  void _tick(Timer timer) => unawaited(_refresh());

  /// 分组已合并、拆分或关闭时回收旧子窗。
  Future<void> _refresh() async {
    if (_reading || _closing) return;
    _reading = true;
    try {
      final Rect bounds = await windowManager.getBounds();
      final Map<Object?, Object?>? data = await widget.owner
          .invokeMethod<Map<Object?, Object?>>('view', <String, Object?>{
            ...widget.identity,
            if (bounds != _reported)
              'bounds': StickerLayout.encodeBounds(bounds),
          });
      if (!mounted || _closing) return;
      if (data == null) {
        await _close();
        return;
      }
      _reported = bounds;
      final StickerGroupView next = StickerGroupView(data);
      final File? character = next.character;
      if (next.assetRevision != _view.assetRevision && character != null) {
        await FileImage(character).evict();
      }
      if (next.visible != _view.visible) {
        if (next.visible) {
          await windowManager.show(inactive: true);
        } else {
          await windowManager.hide();
        }
      }
      if (mounted) setState(() => _view = next);
    } on WindowChannelException {
      await _close();
    } finally {
      _reading = false;
    }
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer.cancel();
    windowManager.removeListener(this);
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  Future<void> _request(String action) async {
    try {
      await widget.owner.invokeMethod<Object?>(action, widget.identity);
    } on WindowChannelException {
      await _close();
    }
  }

  void _hide() => unawaited(_request('hide'));
  void _toggleMode() => unawaited(_request('toggle_mode'));

  @override
  void onWindowClose() => _hide();

  @override
  void dispose() {
    _timer.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      StickerGroupSurface(view: _view, onToggleMode: _toggleMode);
}
