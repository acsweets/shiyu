import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_layout.dart';
import 'package:shiyu/features/desktop_stickers/presentation/desktop_sticker_page.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';
import 'package:shiyu/platform/desktop/floating_window_controller.dart';

import 'support/test_controller.dart';

void main() {
  test('从旧布局迁移并保存合并、拆分和标题开关', _persistence);
  testWidgets('合并后完整倒计时同窗呈现，隐藏标题不隐藏时间', _groupView);
}

Future<void> _persistence() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'shiyu-layout-',
  );
  await File('${directory.path}/layout.json').writeAsString(
    '{"version":1,"main":"retirement","preview":false,"enabled":["work","retirement"],"positions":{"work":[120,60]}}',
  );
  final StickerLayout layout = StickerLayout(directory: directory);
  await layout.load();
  expect(layout.main, 'retirement');
  expect(layout.preview, isFalse);
  expect(layout.enabled, <String>{'work', 'retirement'});
  final int group = layout.mainGroup;
  final int workGroup = layout.groupOf('work');
  expect(layout.boundsOf(workGroup)?.topLeft, const Offset(140, 96));
  layout.assign('work', group);
  expect(layout.activeGroups, <int>{group});
  layout.setTitleVisible(group, false);
  const Rect bounds = Rect.fromLTWH(240, 60, 500, 240);
  layout.saveBounds(group, bounds);
  await layout.flush();

  final StickerLayout restored = StickerLayout(directory: directory);
  await restored.load();
  expect(restored.members(group), <String>['work', 'retirement']);
  expect(restored.showsTitle(group), isFalse);
  expect(restored.boundsOf(group), bounds);
  restored.assign('work', null);
  expect(restored.activeGroups.length, 2);
  expect(restored.members(group), <String>['retirement']);
  await restored.flush();
  layout.dispose();
  restored.dispose();
  await directory.delete(recursive: true);
}

Future<void> _groupView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(500, 160);
  tester.view.devicePixelRatio = 1;
  final StickerLayout layout = StickerLayout()..ready = true;
  layout.assign('holiday', layout.mainGroup);
  final RetirementController controller = await createTestController();
  final FloatingWindowController window = FloatingWindowController(_visibility);
  await tester.pumpWidget(
    MaterialApp(
      home: DesktopStickerPage(
        controller: controller,
        window: window,
        layout: layout,
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text(StickerLayout.examples['work']!), findsOneWidget);
  expect(find.text(StickerLayout.examples['holiday']!), findsOneWidget);
  expect(find.text('距离放假'), findsOneWidget);
  layout.setTitleVisible(layout.mainGroup, false);
  await tester.pumpAndSettle();
  expect(find.text('距离放假'), findsNothing);
  expect(find.text(StickerLayout.examples['holiday']!), findsOneWidget);
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox());
  controller.dispose();
  layout.dispose();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void _visibility(bool visible) {}
