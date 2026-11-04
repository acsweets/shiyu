import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/app/shiyu_app.dart';

void main() {
  testWidgets('中文环境可以启动', _verifyChineseStartup);
  testWidgets('英文小屏和大字号下可以启动', _verifyEnglishCompactStartup);
}

Future<void> _verifyChineseStartup(WidgetTester tester) async {
  tester.platformDispatcher.localesTestValue = const <Locale>[Locale('zh')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(const ProviderScope(child: ShiyuApp()));
  await tester.pumpAndSettle();

  expect(find.text('时余'), findsOneWidget);
  expect(find.text('感知时间，留住生活。'), findsOneWidget);
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
  await tester.pumpWidget(const ProviderScope(child: ShiyuApp()));
  await tester.pumpAndSettle();

  expect(find.text('Time Remaining'), findsOneWidget);
  expect(tester.takeException(), isNull);
}
