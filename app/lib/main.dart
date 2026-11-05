import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:path_provider/path_provider.dart';

import 'app/runtime_shiyu_app.dart';
import 'features/desktop_stickers/application/sticker_metric_selection.dart';
import 'features/desktop_stickers/data/sticker_layout.dart';
import 'features/desktop_stickers/presentation/settings/sticker_settings_window.dart';
import 'features/desktop_stickers/presentation/sticker_child.dart';
import 'features/retirement/application/retirement_controller.dart';
import 'features/retirement/data/holiday_repository.dart';
import 'features/retirement/data/settings_repository.dart';
import 'features/retirement/data/settings_store.dart';
import 'features/retirement/domain/core_gateway.dart';
import 'platform/desktop/floating_window_controller.dart';
import 'platform/rust/generated/frb_generated.dart';
import 'platform/widgets/widget_bridge.dart';

/// 启动应用并在根节点提供 Riverpod 容器。
Future<void> main(List<String> arguments) async {
  if (arguments.length == 3 && arguments.first == 'multi_window') {
    final Map<String, dynamic> options =
        jsonDecode(arguments[2]) as Map<String, dynamic>;
    if (options['settings'] == true) {
      await runStickerSettingsWindow(options['owner'] as String);
    } else {
      await runStickerChild(options);
    }
    return;
  }
  await runShiyu();
}

/// 测试可关闭浮窗行为或替换存储，避免修改用户的真实设置。
Future<RetirementController> runShiyu({
  bool floating = true,
  SettingsStore? storage,
  StickerLayout? desktopLayout,
  bool checkHolidays = true,
  bool showOnboarding = true,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final WidgetBridge widgets = WidgetBridge();
  final SettingsStore store = storage ?? await createSettingsStore(widgets);
  final Directory? directory = store is LocalSettingsStore
      ? store.directory
      : storage == null
      ? Directory('${(await getApplicationSupportDirectory()).path}/shiyu')
      : null;
  final CoreGateway core = RustCoreGateway();
  final RetirementController controller = RetirementController(
    core: core,
    store: store,
    widgets: widgets,
    repository: directory == null
        ? null
        : SettingsRepository(
            core: core,
            primary: store,
            backup: LocalSettingsStore(
              directory,
              fileName: 'settings.json.bak',
            ),
            archive: LocalSettingsStore(
              directory,
              fileName: 'settings.json.damaged',
            ),
          ),
    holidays: directory == null
        ? null
        : LocalHolidayRepository(Directory('${directory.path}/holidays')),
  );
  await controller.initialize();
  FloatingWindowController? window;
  if (floating && (Platform.isWindows || Platform.isMacOS)) {
    desktopLayout ??= StickerLayout();
    if (!desktopLayout.ready) await desktopLayout.load();
    final StickerLayout layout = desktopLayout;
    window = FloatingWindowController(
      (bool visible) => controller.setVisible(
        visible && StickerMetricSelection(layout, controller).hasVisibleMetrics,
      ),
      business: controller,
    );
    await window.initialize(
      showMain: desktopLayout.showsGroup(desktopLayout.mainGroup),
      options: desktopLayout.desktop,
    );
  }
  runApp(
    ProviderScope(
      overrides: <Override>[
        runtimeControllerProvider.overrideWith((Ref ref) => controller),
      ],
      child: RuntimeShiyuApp(
        window: window,
        desktopLayout: desktopLayout,
        onboarding: showOnboarding && storage == null,
      ),
    ),
  );
  if (checkHolidays && storage == null) {
    unawaited(controller.checkHolidayUpdates(silent: true));
  }
  return controller;
}
