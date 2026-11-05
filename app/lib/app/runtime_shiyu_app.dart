import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../features/desktop_stickers/data/sticker_layout.dart';
import '../features/retirement/application/retirement_controller.dart';
import '../platform/desktop/floating_window_controller.dart';
import 'shiyu_app.dart';

/// 根容器持有应用唯一的业务状态，页面按需订阅其快照。
final ChangeNotifierProvider<RetirementController> runtimeControllerProvider =
    ChangeNotifierProvider<RetirementController>(_missingRuntime);

RetirementController _missingRuntime(Ref ref) =>
    throw StateError('Runtime controller must be provided at startup');

class RuntimeShiyuApp extends ConsumerStatefulWidget {
  const RuntimeShiyuApp({this.window, this.desktopLayout, super.key});

  final FloatingWindowController? window;
  final StickerLayout? desktopLayout;

  @override
  ConsumerState<RuntimeShiyuApp> createState() => _RuntimeShiyuAppState();
}

class _RuntimeShiyuAppState extends ConsumerState<RuntimeShiyuApp>
    with WidgetsBindingObserver {
  static const MethodChannel _runtime = MethodChannel('shiyu/runtime');
  late final RetirementController _controller;
  final bool _mobile = Platform.isAndroid || Platform.isIOS;
  bool _sleeping = false;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(runtimeControllerProvider);
    if (_mobile) {
      WidgetsBinding.instance.addObserver(this);
      didChangeAppLifecycleState(
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed,
      );
      _controller.setVisible(true);
    } else if (widget.window != null) {
      _runtime.setMethodCallHandler(_onSystemEvent);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.setSystemSuspended(
      state == AppLifecycleState.hidden ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached,
    );
  }

  Future<void> _onSystemEvent(MethodCall call) async {
    switch (call.method) {
      case 'sleep':
        _sleeping = true;
      case 'wake':
        _sleeping = false;
      case 'lock':
        _locked = true;
      case 'unlock':
        _locked = false;
      case 'clockChanged':
        _controller.clockChanged();
        return;
      default:
        return;
    }
    _controller.setSystemSuspended(_sleeping || _locked);
  }

  @override
  Widget build(BuildContext context) => ShiyuApp(
    controller: _controller,
    window: widget.window,
    desktopLayout: widget.desktopLayout,
  );

  @override
  void dispose() {
    if (_mobile) {
      WidgetsBinding.instance.removeObserver(this);
    } else if (widget.window != null) {
      _runtime.setMethodCallHandler(null);
    }
    super.dispose();
  }
}
