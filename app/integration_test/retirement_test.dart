import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shiyu/main.dart' as application;
import 'package:shiyu/features/desktop_stickers/data/sticker_layout.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';
import 'package:shiyu/features/retirement/data/settings_store.dart';
import 'package:shiyu/platform/rust/generated/api/snapshot.dart' as rust;
import 'package:shiyu/features/desktop_stickers/presentation/desktop_sticker_page.dart';
import 'package:shiyu/platform/desktop/floating_window_controller.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('设置原子保存、真实退休快照及原生组件共享计算', _verifyRetirement);
}

Future<void> _verifyRetirement(WidgetTester tester) async {
  final bool desktop = Platform.isWindows || Platform.isMacOS;
  final Directory temporary = await Directory.systemTemp.createTemp(
    'shiyu-retirement-',
  );
  final StickerLayout layout = StickerLayout(directory: temporary)
    ..main = 'retirement'
    ..enabled = <String>{'retirement'};
  layout.setGroupVisible(layout.mainGroup, false);
  final RetirementController controller = await application.runShiyu(
    floating: desktop,
    desktopLayout: desktop ? layout : null,
    storage: desktop ? LocalSettingsStore(temporary) : null,
  );
  await tester.pumpAndSettle();
  final String? originalDate = controller.retirementDate;
  final String originalZone = controller.timeZone;
  final FloatingWindowController? window = desktop
      ? tester
            .widget<DesktopStickerPage>(find.byType(DesktopStickerPage))
            .window
      : null;
  try {
    expect(await controller.save('2050-01-01', 'Asia/Shanghai'), isTrue);
    await tester.pumpAndSettle();
    expect(controller.snapshot!.status, 'active');
    expect(controller.snapshot!.days, greaterThan(0));
    final Map<String, dynamic> stored =
        jsonDecode((await controller.store.read())!) as Map<String, dynamic>;
    expect(stored['retirement_date'], '2050-01-01');
    expect(await controller.save('2050-01-01', 'Invalid/Zone'), isFalse);
    expect(controller.timeZone, 'Asia/Shanghai');
    const int now = 1793764800000;
    final String dartJson = await rust.computeSnapshot(
      settingsJson: jsonEncode(controller.settings),
      holidayJson: '{}',
      nowMillis: now,
    );
    if (Platform.isAndroid) {
      const MethodChannel channel = MethodChannel('shiyu/widgets');
      final String? nativeJson = await channel.invokeMethod<String>(
        'snapshot',
        now,
      );
      expect(jsonDecode(nativeJson!), jsonDecode(dartJson));
    }
    if (desktop) {
      expect(await windowManager.isAlwaysOnTop(), isTrue);
      expect(await windowManager.isPreventClose(), isTrue);
      expect(
        (await windowManager.getSize()).width,
        greaterThanOrEqualTo(StickerLayout.minimum.width - 1),
      );
      await _verifyMainWindowVisibility(tester, window!, layout);
    }
  } finally {
    await controller.save(originalDate, originalZone);
    await window?.dispose();
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    layout.dispose();
  }
}

Future<void> _verifyMainWindowVisibility(
  WidgetTester tester,
  FloatingWindowController window,
  StickerLayout layout,
) async {
  expect(await windowManager.isVisible(), isFalse);
  window.onTrayMenuItemClick(MenuItem(key: 'settings', label: '设置'));
  await tester.pumpAndSettle();
  expect(await windowManager.isVisible(), isTrue);
  expect(find.text('显示主窗口'), findsOneWidget);
  await tester.tap(find.text('显示主窗口'));
  await tester.tap(find.text('完成'));
  await tester.pumpAndSettle();
  expect(layout.showsGroup(layout.mainGroup), isTrue);
  expect(await windowManager.isVisible(), isTrue);
}
