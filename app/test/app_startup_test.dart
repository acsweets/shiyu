import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/app/shiyu_app.dart';

import 'support/test_controller.dart';

import 'package:shiyu/features/retirement/application/retirement_controller.dart';

void main() {
  testWidgets('中文环境直接打开手机设置', _verifyChineseStartup);
  testWidgets('英文小屏和大字号下可以使用手机设置', _verifyEnglishCompactStartup);
  testWidgets('手机设置保存时区并保留原生小组件入口', _verifyMobileSettings);
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

  expect(find.text('设置'), findsOneWidget);
  expect(find.text('主屏幕小组件'), findsOneWidget);
  expect(find.byKey(const ValueKey<String>('retirementValue')), findsNothing);
  expect(find.text('退休倒计时'), findsOneWidget);
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

  expect(find.text('Settings'), findsOneWidget);
  expect(find.text('Choose retirement date'), findsOneWidget);
  await tester.scrollUntilVisible(
    find.text('Widget appearance'),
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  expect(tester.takeException(), isNull);
}

Future<void> _verifyMobileSettings(WidgetTester tester) async {
  tester.platformDispatcher.localesTestValue = const <Locale>[Locale('zh')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final RetirementController controller = await createTestController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(ShiyuApp(controller: controller));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField), 'Asia/Tokyo');
  expect(controller.timeZone, 'Asia/Shanghai');
  await tester.tap(find.text('保存设置'));
  await tester.pumpAndSettle();
  expect(controller.timeZone, 'Asia/Tokyo');
  expect(find.text('主屏幕小组件'), findsOneWidget);
}
