import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/app/runtime_shiyu_app.dart';
import 'package:shiyu/app/shiyu_app.dart';

import 'support/test_controller.dart';

import 'package:shiyu/features/retirement/application/retirement_controller.dart';

void main() {
  testWidgets('中文首页展示 Rust 指标并从右上角进入设置', _verifyChineseStartup);
  testWidgets('英文小屏和大字号下可以使用手机设置', _verifyEnglishCompactStartup);
  testWidgets('手机设置保存时区并保留原生小组件入口', _verifyMobileSettings);
  testWidgets('手机设置首页切换语言并可恢复跟随系统', _verifyMobileLanguage);
  testWidgets('手机可切换生命计数并单独隐藏其标题', _verifyLifeDisplay);
  testWidgets('手机倒计时设置独立保存今日已赚显隐和金额遮蔽', _verifyEarningsControls);
}

Future<void> _verifyChineseStartup(WidgetTester tester) async {
  tester.platformDispatcher.localesTestValue = const <Locale>[Locale('zh')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final RetirementController controller = await createTestController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ProviderScope(child: ShiyuApp(controller: controller)),
  );
  await tester.pumpAndSettle();

  expect(
    find.byKey(const ValueKey<String>('mobile-metric-work')),
    findsOneWidget,
  );
  expect(
    find.byKey(const ValueKey<String>('mobile-metric-today_salary')),
    findsOneWidget,
  );
  expect(
    find.byKey(const ValueKey<String>('mobile-metric-month_salary')),
    findsOneWidget,
  );
  expect(find.text('主屏幕小组件'), findsNothing);
  await tester.tap(find.byTooltip('设置'));
  await tester.pumpAndSettle();
  expect(find.text('主屏幕小组件'), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _verifyEnglishCompactStartup(WidgetTester tester) async {
  tester.platformDispatcher.localesTestValue = const <Locale>[Locale('en')];
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  tester.view.physicalSize = const Size(320, 480);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final RetirementController controller = await createTestController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ProviderScope(child: ShiyuApp(controller: controller)),
  );
  await tester.pumpAndSettle();

  expect(
    find.byKey(const ValueKey<String>('mobile-metric-work')),
    findsOneWidget,
  );
  expect(tester.takeException(), isNull);
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  expect(find.text('Settings'), findsOneWidget);
  expect(find.text('Countdowns'), findsOneWidget);
  final Finder widgets = find.text('Home screen widget');
  await tester.scrollUntilVisible(widgets.hitTestable(), 140);
  await tester.tap(widgets);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Widget appearance'), 200);
  await tester.scrollUntilVisible(find.text('Macaron Glass'), 200);
  expect(tester.takeException(), isNull);
}

Future<void> _verifyMobileSettings(WidgetTester tester) async {
  tester.platformDispatcher.localesTestValue = const <Locale>[Locale('zh')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final RetirementController controller = await createTestController();
  addTearDown(controller.dispose);
  final String? catalog = await tester.runAsync(
    () => rootBundle.loadString('assets/time_zones.txt'),
  );
  expect(catalog, contains('Europe/Lisbon'));
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: _TimeZoneTestBundle(catalog!),
      child: ShiyuApp(controller: controller),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('设置'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('通用'));
  await tester.pumpAndSettle();
  await _selectTimeZone(tester, 'Europe/Lisbon');
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
  expect(find.text('放弃未保存的修改？'), findsOneWidget);
  await tester.tap(find.text('放弃修改'));
  await tester.pumpAndSettle();
  expect(controller.timeZone, 'Asia/Shanghai');
  await tester.tap(find.text('通用'));
  await tester.pumpAndSettle();
  await _selectTimeZone(tester, 'Asia/Tokyo');
  expect(controller.timeZone, 'Asia/Shanghai');
  await tester.pump();
  await tester.tap(find.text('保存设置'));
  await tester.pumpAndSettle();
  expect(controller.timeZone, 'Asia/Tokyo');
  expect(find.text('主屏幕小组件'), findsOneWidget);
  await tester.tap(find.text('作息与薪资'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('09:00'));
  await tester.pumpAndSettle();
  expect(find.byType(TimePickerDialog), findsOneWidget);
}

Future<void> _verifyEarningsControls(WidgetTester tester) async {
  final RetirementController controller = await createTestController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ShiyuApp(controller: controller, locale: const Locale('zh')),
  );
  await tester.pumpAndSettle();
  final Finder todayCard = find.byKey(
    const ValueKey<String>('mobile-metric-today_salary'),
  );
  final Finder monthCard = find.byKey(
    const ValueKey<String>('mobile-metric-month_salary'),
  );
  final Finder visibility = find.byKey(
    const ValueKey<String>('metric-visibility-today_salary'),
  );
  final Finder privacy = find.byKey(const ValueKey<String>('amount-privacy'));
  expect(todayCard, findsOneWidget);
  await tester.tap(find.byTooltip('设置'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('倒计时'));
  await tester.pumpAndSettle();
  expect(tester.widget<SwitchListTile>(visibility).value, isTrue);
  expect(tester.widget<SwitchListTile>(privacy).value, isTrue);
  await tester.tap(visibility);
  await tester.pumpAndSettle();
  expect(tester.widget<SwitchListTile>(privacy).value, isTrue);
  await tester.tap(privacy);
  await tester.pumpAndSettle();
  await tester.tap(find.text('保存设置'));
  await tester.pumpAndSettle();
  expect(
    controller.displaySettings['enabled_metrics'],
    isNot(contains('today_salary')),
  );
  expect(controller.settings['hide_amount'], isFalse);
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
  expect(todayCard, findsNothing);
  expect(monthCard, findsOneWidget);
}

Future<void> _selectTimeZone(WidgetTester tester, String value) async {
  await tester.tap(find.byKey(const ValueKey<String>('time-zone-picker')));
  await tester.pumpAndSettle();
  final Finder search = find.byKey(const ValueKey<String>('time-zone-search'));
  await tester.enterText(search, 'Invalid/Zone');
  await tester.pumpAndSettle();
  expect(find.text('没有匹配的时区'), findsOneWidget);
  await tester.enterText(search, value);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(MenuItemButton, value));
  await tester.pumpAndSettle();
}

class _TimeZoneTestBundle extends CachingAssetBundle {
  _TimeZoneTestBundle(this.catalog);

  /// 用真实资产内容同步完成加载，避免测试时钟阻塞平台通道。
  final String catalog;

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      key == 'assets/time_zones.txt'
      ? SynchronousFuture<String>(catalog)
      : rootBundle.loadString(key, cache: cache);
}

Future<void> _verifyMobileLanguage(WidgetTester tester) async {
  tester.platformDispatcher.localesTestValue = const <Locale>[Locale('en')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final RetirementController controller = await createTestController();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        runtimeControllerProvider.overrideWith((Ref ref) => controller),
      ],
      child: const RuntimeShiyuApp(onboarding: false),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();

  final Finder picker = find.byKey(
    const ValueKey<String>('app-language-picker'),
  );
  await tester.ensureVisible(picker);
  expect(tester.widget<DropdownButton<String>>(picker).items, hasLength(9));
  await tester.tap(picker);
  await tester.pumpAndSettle();
  await tester.tap(find.text('日本語').last);
  await tester.pumpAndSettle();
  expect(controller.preferredLocale, 'ja');
  expect(find.text('表示言語'), findsOneWidget);
  expect(
    jsonDecode((await controller.store.read())!)['display'],
    containsPair('locale', 'ja'),
  );

  await tester.tap(picker);
  await tester.pumpAndSettle();
  await tester.tap(find.text('システム言語').last);
  await tester.pumpAndSettle();
  expect(controller.preferredLocale, isNull);
  expect(find.text('Settings'), findsOneWidget);
}

Future<void> _verifyLifeDisplay(WidgetTester tester) async {
  tester.platformDispatcher.localesTestValue = const <Locale>[Locale('zh')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final RetirementController controller = await createTestController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(ShiyuApp(controller: controller));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('设置'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('倒计时'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('静待百岁，好好生活'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('已存在世界').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('保存设置'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('逐项显示标题'));
  await tester.pumpAndSettle();
  final Finder lifeSwitch = find.byKey(
    const ValueKey<String>('metric-title-life'),
  );
  await tester.ensureVisible(lifeSwitch);
  await tester.tap(lifeSwitch);
  await tester.pumpAndSettle();
  final Finder holidaySwitch = find.byKey(
    const ValueKey<String>('metric-title-holiday'),
  );
  expect(tester.widget<SwitchListTile>(holidaySwitch).value, isTrue);
  expect(tester.widget<SwitchListTile>(lifeSwitch).value, isFalse);
  expect(
    jsonDecode((await controller.store.read())!)['display'],
    containsPair('life_mode', 'elapsed_days'),
  );
  await tester.tap(find.text('保存设置'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();

  final Finder lifeCard = find.byKey(
    const ValueKey<String>('mobile-metric-life'),
  );
  await tester.scrollUntilVisible(lifeCard, 240);
  expect(
    find.descendant(of: lifeCard, matching: find.text('1,234 天')),
    findsOneWidget,
  );
  expect(find.text('已存在世界'), findsNothing);
}
