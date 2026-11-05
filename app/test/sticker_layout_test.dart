import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/desktop_stickers/application/sticker_group_view.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_cat_pose.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_layout.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_palette.dart';
import 'package:shiyu/features/desktop_stickers/presentation/countdown_sticker.dart';
import 'package:shiyu/features/desktop_stickers/presentation/desktop_sticker_page.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';
import 'package:shiyu/platform/desktop/floating_window_controller.dart';

import 'support/test_controller.dart';

void main() {
  test('从旧布局迁移并保存分组、显隐、配色和字号', _persistence);
  testWidgets('设置配色和字号后浮窗保留完整倒计时', _groupView);
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
  expect(layout.palette, StickerPalette.macaron);
  expect(layout.titleSize, StickerLayout.defaultTitleSize);
  expect(layout.enabled, <String>{'work', 'retirement'});
  final int group = layout.mainGroup;
  final int workGroup = layout.groupOf('work');
  expect(layout.boundsOf(workGroup)?.topLeft, const Offset(140, 96));
  layout.assign('work', group);
  expect(layout.activeGroups, <int>{group});
  layout.setTitleVisible(group, false);
  expect(layout.showsGroup(group), isTrue);
  layout.setGroupVisible(group, false);
  layout.setPalette(StickerPalette.cool);
  layout.setTitleSize(99);
  expect(layout.titleSize, StickerLayout.maxTitleSize);
  layout.setTitleSize(22);
  expect(layout.activeGroups, <int>{group});
  const Rect bounds = Rect.fromLTWH(240, 60, 500, 240);
  layout.saveBounds(group, bounds);
  await layout.flush();

  final StickerLayout restored = StickerLayout(directory: directory);
  await restored.load();
  expect(restored.members(group), <String>['work', 'retirement']);
  expect(restored.showsTitle(group), isFalse);
  expect(restored.showsGroup(group), isFalse);
  expect(restored.palette, StickerPalette.cool);
  expect(restored.titleSize, 22);
  expect(restored.boundsOf(group), bounds);
  restored.assign('work', null);
  expect(restored.activeGroups.length, 2);
  expect(restored.members(group), <String>['retirement']);
  expect(restored.showsGroup(restored.groupOf('work')), isTrue);
  final File source = File(StickerCatPose.sitting.asset);
  final File legacy = await source.copy('${directory.path}/character.png');
  await restored.reloadCharacter();
  expect(restored.characterOf(group)?.file.path, legacy.path);
  expect(
    restored.characterOf(group)?.bottomInset,
    closeTo(StickerCatPose.sitting.bottomInset, 0.01),
  );
  final int splitGroup = restored.groupOf('work');
  expect(restored.characterOf(splitGroup), isNull);
  final String name = StickerCatPose.values[splitGroup].overrideFileName;
  final File custom = await source.copy('${directory.path}/$name');
  await restored.reloadCharacter();
  expect(restored.characterOf(splitGroup)?.file.path, custom.path);
  expect(restored.characterOf(group)?.file.path, legacy.path);
  await restored.flush();
  layout.dispose();
  restored.dispose();
  await directory.delete(recursive: true);
}

Future<void> _groupView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(500, 146);
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
  expect(find.byType(IconButton), findsOneWidget);
  expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
  expect(find.text('时余'), findsNothing);
  expect(find.text('示例'), findsNothing);
  expect(find.byType(Image), findsOneWidget);
  expect(_catAsset(tester), StickerCatPose.sitting.asset);
  expect(
    _windowBackground(tester),
    StickerPalette.macaron.backgroundFor(layout.mainGroup),
  );
  _expectCatOnCard(tester, StickerCatPose.sitting, 'work');
  layout.setTitleVisible(layout.mainGroup, false);
  await tester.pumpAndSettle();
  expect(find.text('距离放假'), findsNothing);
  expect(find.text(StickerLayout.examples['holiday']!), findsOneWidget);
  expect(tester.takeException(), isNull);

  tester.view.physicalSize = const Size(470, 650);
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.tune_rounded));
  await tester.pumpAndSettle();
  final Finder coolSwatch = find.byWidgetPredicate(_isCoolSwatch);
  expect(tester.getSize(coolSwatch).height, greaterThan(0));
  await tester.tap(find.widgetWithText(ChoiceChip, '冷酷色系'));
  await tester.pumpAndSettle();
  expect(layout.palette, StickerPalette.cool);
  final Finder slider = find.byType(Slider);
  await tester.drag(slider, const Offset(300, 0));
  await tester.pumpAndSettle();
  expect(layout.titleSize, StickerLayout.maxTitleSize);
  await tester.tap(find.text('完成'));
  await tester.pumpAndSettle();
  expect(
    _windowBackground(tester),
    StickerPalette.cool.backgroundFor(layout.mainGroup),
  );
  expect(
    tester
        .widget<Text>(find.text(StickerLayout.examples['work']!))
        .style
        ?.color,
    StickerPalette.cool.foreground,
  );

  tester.view.physicalSize = const Size(500, 146);
  layout.setTitleVisible(layout.mainGroup, true);
  await tester.pumpAndSettle();
  _expectTitleSize(tester, 'work');
  _expectCatOnCard(tester, StickerCatPose.sitting, 'work');
  expect(tester.takeException(), isNull);
  final Set<String> poses = <String>{
    for (int group = 0; group < StickerLayout.titles.length; group++)
      StickerGroupView.fromLayout(layout, controller, group, true).catAsset,
  };
  expect(poses, hasLength(4));
  await tester.pumpWidget(
    MaterialApp(
      home: StickerGroupSurface(
        view: StickerGroupView.fromLayout(
          layout,
          controller,
          layout.groupOf('payday'),
          true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text(StickerLayout.examples['payday']!), findsOneWidget);
  _expectTitleSize(tester, 'payday');
  expect(find.byType(Image), findsOneWidget);
  expect(_catAsset(tester), StickerCatPose.waving.asset);
  _expectCatOnCard(tester, StickerCatPose.waving, 'payday');
  expect(find.byType(IconButton), findsNothing);
  expect(
    _windowBackground(tester),
    StickerPalette.cool.backgroundFor(layout.groupOf('payday')),
  );
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox());
  controller.dispose();
  layout.dispose();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void _expectTitleSize(WidgetTester tester, String id) {
  final Text title = tester.widget<Text>(find.text(StickerLayout.titles[id]!));
  expect(title.style?.fontSize, StickerLayout.maxTitleSize.toDouble());
  final Text timer = tester.widget<Text>(
    find.text(StickerLayout.examples[id]!),
  );
  expect(timer.style?.fontSize, 18);
}

void _expectCatOnCard(WidgetTester tester, StickerCatPose pose, String id) {
  final Finder cat = find.byType(Image);
  final Rect catRect = tester.getRect(cat);
  final double visibleBottom =
      catRect.bottom - catRect.height * pose.bottomInset;
  final double cardTop = tester
      .getTopLeft(
        find.byKey(const ValueKey<String>('sticker-window-background')),
      )
      .dy;
  final double timerTop = tester
      .getTopLeft(find.byKey(ValueKey<String>('sticker-$id')))
      .dy;
  expect(visibleBottom, closeTo(cardTop + 2, 0.01));
  expect(visibleBottom, lessThan(timerTop));
}

String _catAsset(WidgetTester tester) {
  final Image image = tester.widget<Image>(find.byType(Image));
  final ResizeImage resized = image.image as ResizeImage;
  return (resized.imageProvider as AssetImage).assetName;
}

bool _isCoolSwatch(Widget widget) =>
    widget is ColoredBox &&
    widget.color == StickerPalette.cool.backgroundFor(0);

Color? _windowBackground(WidgetTester tester) {
  final DecoratedBox background = tester.widget<DecoratedBox>(
    find.byKey(const ValueKey<String>('sticker-window-background')),
  );
  return (background.decoration as BoxDecoration).color;
}

void _visibility(bool visible) {}
