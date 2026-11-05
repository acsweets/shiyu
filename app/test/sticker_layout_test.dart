import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_layout.dart';
import 'package:shiyu/features/desktop_stickers/presentation/desktop_sticker_page.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';
import 'package:shiyu/platform/desktop/floating_window_controller.dart';

import 'support/test_controller.dart';

void main() {
  test('贴纸位置、主指标和开关独立持久化', _persistence);
  testWidgets('完整示例时间保持连贯，外围贴纸可以拖动', _drag);
}

Future<void> _persistence() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'shiyu-layout-',
  );
  final StickerLayout layout = StickerLayout(directory: directory);
  await layout.load();
  layout.move('holiday', const Offset(-80, 100));
  layout.toggle('payday', false);
  layout.setMain('retirement');
  layout.setPreview(false);
  layout.persist();
  await layout.flush();
  final StickerLayout restored = StickerLayout(directory: directory);
  await restored.load();
  expect(restored.main, 'retirement');
  expect(restored.preview, isFalse);
  expect(restored.enabled.contains('payday'), isFalse);
  expect(restored.positions['holiday'], layout.positions['holiday']);
  layout.dispose();
  restored.dispose();
  await directory.delete(recursive: true);
}

Future<void> _drag(WidgetTester tester) async {
  tester.view.physicalSize = const Size(760, 560);
  tester.view.devicePixelRatio = 1;
  final StickerLayout layout = StickerLayout()..ready = true;
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
  expect(find.text('00天 02小时 36分 18秒'), findsOneWidget);
  final Offset before = layout.positions['holiday']!;
  await tester.drag(
    find.byKey(const ValueKey<String>('sticker-holiday')),
    const Offset(-50, 80),
  );
  await tester.pumpAndSettle();
  expect(layout.positions['holiday']!.dy, greaterThan(before.dy));
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox());
  controller.dispose();

  layout.dispose();

  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void _visibility(bool visible) {}
