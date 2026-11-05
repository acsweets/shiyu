import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shiyu/main.dart' as application;
import 'package:shiyu/features/desktop_stickers/data/sticker_layout.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_mode.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';
import 'package:shiyu/features/retirement/data/settings_store.dart';
import 'package:shiyu/platform/rust/generated/api/snapshot.dart' as rust;
import 'package:shiyu/features/desktop_stickers/presentation/desktop_sticker_page.dart';
import 'package:shiyu/platform/desktop/floating_window_controller.dart';
import 'package:window_manager/window_manager.dart';

import 'support/holiday_flow.dart';
import 'support/business_settings_flow.dart';
import 'support/desktop_behavior_flow.dart';
import 'support/desktop_skin_flow.dart';

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
    checkHolidays: false,
    showOnboarding: false,
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
    await _verifyTimeMetrics();
    await verifyHolidayFlow(temporary);
    await verifyBusinessSettingsFlow(temporary);
    const int now = 1793764800000;
    // 以相同设置、日历与墙钟比较两条正式绑定。
    final String dartJson = await rust.computeSnapshot(
      settingsJson: jsonEncode(controller.settings),
      holidayJson: controller.holidayData?.pack.coreJson ?? '{}',
      nowMillis: now,
    );
    if (Platform.isAndroid) {
      expect(controller.holidayData, isNotNull);
      expect(
        find.byKey(const ValueKey<String>('mobile-metric-work')),
        findsOneWidget,
      );
      const MethodChannel channel = MethodChannel('shiyu/widgets');
      final String? nativeJson = await channel.invokeMethod<String>(
        'snapshot',
        now,
      );
      expect(jsonDecode(nativeJson!), jsonDecode(dartJson));
      final String calendar = controller.holidayData!.pack.widgetJson;
      expect(
        await channel.invokeMethod<bool>('writeCalendar', calendar),
        isFalse,
      );
      await expectLater(
        channel.invokeMethod<bool>(
          'writeCalendar',
          calendar.replaceFirst('"sha256":"', '"sha256":"bad'),
        ),
        throwsA(isA<PlatformException>()),
      );
      expect(await channel.invokeMethod<String>('snapshot', now), nativeJson);
    }
    if (desktop) {
      expect(await windowManager.isAlwaysOnTop(), isTrue);
      expect(await windowManager.isPreventClose(), isTrue);
      expect(
        (await windowManager.getSize()).width,
        greaterThanOrEqualTo(StickerLayout.minimum.width - 1),
      );
      await _verifyMainWindowVisibility(tester, window!, layout);
      await verifyDesktopBehavior(tester, window);
      await verifyDesktopSkin(tester, layout, temporary);
    }
  } finally {
    await controller.save(originalDate, originalZone);
    await window?.dispose();
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    layout.dispose();
  }
}

/// 用合成设置核对真实 FRB 时间指标，避免改动用户的生辰或发薪设置。
Future<void> _verifyTimeMetrics() async {
  const String settings = '''
{
  "time_zone": "Asia/Shanghai",
  "birth": {"date": "1996-02-29"},
  "payday": {"rule": "fixed_day", "days": [15]}
}
''';
  final String raw = await rust.computeSnapshot(
    settingsJson: settings,
    holidayJson: '{}',
    nowMillis: 1793764800000,
  );
  final Map<String, dynamic> reply = jsonDecode(raw) as Map<String, dynamic>;
  expect(reply['ok'], isTrue);
  final Map<String, dynamic> snapshot =
      reply['snapshot'] as Map<String, dynamic>;
  expect(snapshot['unavailable_metrics'], isEmpty);
  expect(snapshot['work'], containsPair('status', 'lunch_break'));
  expect(snapshot['life'], containsPair('status', 'active'));
  expect(snapshot['payday'], containsPair('target_date', '2026-11-16'));
  expect(snapshot['holiday'], containsPair('status', 'upcoming'));
}

Future<void> _verifyMainWindowVisibility(
  WidgetTester tester,
  FloatingWindowController window,
  StickerLayout layout,
) async {
  expect(await windowManager.isVisible(), isFalse);
  await window.show();
  expect(await windowManager.isVisible(), isFalse);
  layout.setGroupVisible(layout.mainGroup, true);
  await tester.pumpAndSettle();
  expect(layout.showsGroup(layout.mainGroup), isTrue);
  expect(await windowManager.isVisible(), isTrue);
  final Finder countdown = find.byKey(
    const ValueKey<String>('sticker-retirement'),
  );
  await tester.tap(countdown);
  await tester.pump(const Duration(milliseconds: 65));
  await tester.tap(countdown);
  await tester.pumpAndSettle();
  expect(layout.mode, StickerMode.standard);
  expect((await windowManager.getSize()).width, greaterThanOrEqualTo(519));
}
