import 'dart:async';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../app/settings_locale.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../retirement/presentation/settings/business_settings_page.dart';
import '../../application/sticker_business_access.dart';
import '../../application/sticker_settings_state.dart';
import 'settings_controls.dart';
import 'sticker_settings.dart';

/// 设置窗使用独立引擎，读取主引擎状态后再显示。
Future<void> runStickerSettingsWindow(String ownerId) async {
  WidgetsFlutterBinding.ensureInitialized();
  final WindowController owner = WindowController.fromWindowId(ownerId);
  final _SettingsConnection connection = _SettingsConnection(owner);
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: const Size(940, 660),
      minimumSize: const Size(680, 490),
      center: true,
      title: '时余 · 设置',
      // Windows 的原生标题栏与按钮由系统配色，白底由 Flutter 内容绘制。
      backgroundColor: Platform.isWindows ? null : SettingsPaper.surface,
      alwaysOnTop: true,
    ),
  );
  try {
    final StickerSettingsState initial = await connection.read();
    final WindowController self = await WindowController.fromCurrentEngine();
    await self.setWindowMethodHandler(connection.handle);
    await windowManager.setPreventClose(true);
    runApp(_SettingsApp(connection: connection, initial: initial));
    await connection.show();
  } on WindowChannelException {
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }
}

class _SettingsConnection {
  const _SettingsConnection(this.owner);

  /// 接收全部设置请求的主窗口。
  final WindowController owner;

  Future<StickerSettingsState> read() async {
    final Map<Object?, Object?>? data = await owner
        .invokeMethod<Map<Object?, Object?>>('settings.read');
    if (data == null) throw StateError('设置主窗口已退出');
    return StickerSettingsState(data);
  }

  Future<StickerSettingsReply> dispatch(
    StickerSetting action,
    Map<String, Object?> arguments,
  ) async {
    final Map<Object?, Object?>? data = await owner
        .invokeMethod<Map<Object?, Object?>>(
          'settings.change',
          <String, Object?>{'action': action.name, 'arguments': arguments},
        );
    if (data == null) throw StateError('设置主窗口已退出');
    return StickerSettingsReply.fromData(data);
  }

  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'focus':
        await show();
      case 'destroy':
        // 先返回跨窗口消息，再销毁当前引擎。
        unawaited(Future<void>.delayed(Duration.zero, _destroy));
      default:
        throw MissingPluginException(call.method);
    }
    return null;
  }

  /// 设置获焦时盖过置顶浮窗，失焦后让出层级。
  Future<void> show() async {
    await windowManager.setAlwaysOnTop(true);
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _destroy() async {
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }
}

class _SettingsApp extends StatefulWidget {
  const _SettingsApp({required this.connection, required this.initial});

  /// 独立设置窗和主窗口之间的连接。
  final _SettingsConnection connection;

  /// 首帧已经读取好的设置。
  final StickerSettingsState initial;

  @override
  State<_SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<_SettingsApp> with WindowListener {
  /// 整个设置窗共享同一条读写队列。
  late final StickerSettingsSession _session;
  bool _wizard = false;
  String? _locale;

  @override
  void initState() {
    super.initState();
    _session = StickerSettingsSession(
      widget.initial,
      widget.connection.read,
      widget.connection.dispatch,
    );
    _wizard = widget.initial.business?.firstRun ?? false;
    _locale = _readLocale();
    _session.addListener(_applyLocale);
    windowManager.addListener(this);
  }

  String? _readLocale() => _session.state.preferredLocale;

  void _applyLocale() {
    final String? next = _readLocale();
    if (mounted && next != _locale) setState(() => _locale = next);
  }

  void _finishWizard() => setState(() => _wizard = false);

  @override
  void onWindowClose() => unawaited(windowManager.hide());

  @override
  void onWindowFocus() {
    unawaited(windowManager.setAlwaysOnTop(true));
    _session.refresh();
  }

  @override
  void onWindowBlur() => unawaited(windowManager.setAlwaysOnTop(false));

  @override
  void dispose() {
    windowManager.removeListener(this);
    _session.removeListener(_applyLocale);
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: SettingsPaper.theme,
    locale: settingsLocale(_locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: _wizard
        ? BusinessSettingsPage(
            access: stickerBusinessAccess(_session),
            initial: _session.state.business!,
            desktop: true,
            onFinished: _finishWizard,
          )
        : StickerSettings(session: _session),
  );
}
