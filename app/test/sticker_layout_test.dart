import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/app/settings_locale.dart';
import 'package:shiyu/features/desktop_stickers/application/sticker_group_view.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_cat_pose.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_layout.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_palette.dart';
import 'package:shiyu/features/desktop_stickers/presentation/countdown_sticker.dart';
import 'package:shiyu/features/desktop_stickers/presentation/desktop_sticker_page.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';
import 'package:shiyu/l10n/generated/app_localizations.dart';
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
  await layout.setPalette(StickerPalette.cool);
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
    ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) => MaterialApp(
        locale:
            settingsLocale(controller.preferredLocale) ?? const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: child,
      ),
      child: DesktopStickerPage(
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
  await controller.saveSettings(<String, dynamic>{
    ...controller.settings,
    'display': <String, dynamic>{
      'hidden_metric_titles': <String>['holiday'],
    },
  });
  await tester.pumpAndSettle();
  expect(find.text('距离放假'), findsNothing);
  expect(find.text('距离下班'), findsOneWidget);
  expect(find.text(StickerLayout.examples['holiday']!), findsOneWidget);
  layout.setTitleVisible(layout.mainGroup, false);
  await tester.pumpAndSettle();
  expect(find.text('距离放假'), findsNothing);
  expect(find.text('距离下班'), findsNothing);
  expect(find.text(StickerLayout.examples['holiday']!), findsOneWidget);
  expect(tester.takeException(), isNull);

  tester.view.physicalSize = const Size(940, 660);
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.tune_rounded));
  await tester.pumpAndSettle();
  _expectSettingsStyle(tester);
  await _setDesktopLanguage(tester, 'English');
  expect(controller.preferredLocale, 'en');
  expect(find.widgetWithText(TextButton, 'Appearance'), findsOneWidget);
  await _setDesktopLanguage(tester, '简体中文');
  expect(controller.preferredLocale, 'zh');
  await _verifyMetricSwitches(tester, layout, controller);
  await tester.tap(find.widgetWithText(OutlinedButton, '马卡龙玻璃'));
  await tester.pumpAndSettle();
  expect(layout.palette, StickerPalette.macaronGlass);
  final Finder preview = find.byWidgetPredicate(_isSettingsPreview);
  final DecoratedBox background = tester.widget<DecoratedBox>(
    find.descendant(
      of: preview,
      matching: find.byKey(const ValueKey<String>('sticker-window-background')),
    ),
  );
  final BoxDecoration glass = background.decoration as BoxDecoration;
  final LinearGradient gradient = glass.gradient! as LinearGradient;
  expect(glass.color, isNull);
  expect(gradient.colors.first.a, closeTo(0.94, 0.01));
  expect(gradient.colors.last.a, closeTo(0.74, 0.01));
  final Finder coolSwatch = find.byWidgetPredicate(_isCoolSwatch);
  expect(tester.getSize(coolSwatch).height, greaterThan(0));
  await tester.tap(find.widgetWithText(OutlinedButton, '冷酷色系'));
  await tester.pumpAndSettle();
  expect(layout.palette, StickerPalette.cool);
  final Finder slider = find.byKey(
    const ValueKey<String>('sticker-title-size'),
  );
  await tester.ensureVisible(slider);
  await tester.drag(slider, const Offset(300, 0));
  await tester.pumpAndSettle();
  expect(layout.titleSize, StickerLayout.maxTitleSize);
  await tester.tap(find.widgetWithText(TextButton, '窗口管理'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byTooltip('移动距离放假'),
      matching: find.byType(OutlinedButton),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.widgetWithText(MenuItemButton, '新的独立窗口'), findsOneWidget);
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
  expect(layout.groupOf('holiday'), isNot(layout.mainGroup));
  expect(layout.groupOf('holiday'), 1);
  await tester.tap(find.text('撤销'));
  await tester.pumpAndSettle();
  expect(layout.groupOf('holiday'), layout.mainGroup);
  await tester.tap(find.byTooltip('关闭设置'));
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

Future<void> _setDesktopLanguage(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const ValueKey<String>('app-language-picker')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _verifyMetricSwitches(
  WidgetTester tester,
  StickerLayout layout,
  RetirementController controller,
) async {
  await tester.tap(find.widgetWithText(TextButton, '倒计时'));
  await tester.pumpAndSettle();
  final Map<String, String> before = StickerGroupView.fromLayout(
    layout,
    controller,
    layout.mainGroup,
    true,
  ).values;
  expect(before['today_salary'], '****');
  expect(before['life'], isNotNull);
  expect(find.text('静待百岁，好好生活'), findsOneWidget);
  for (final String id in <String>['today_salary', 'life']) {
    final Finder toggle = find.byKey(ValueKey<String>('metric-visibility-$id'));
    await tester.ensureVisible(toggle);
    expect(tester.widget<Switch>(toggle).value, isTrue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(toggle).value, isFalse);
    expect(controller.displaySettings['enabled_metrics'], isNot(contains(id)));
    final Map<String, String> hidden = StickerGroupView.fromLayout(
      layout,
      controller,
      layout.mainGroup,
      true,
    ).values;
    expect(hidden, <String, String>{...before}..remove(id));
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(toggle).value, isTrue);
    expect(controller.displaySettings['enabled_metrics'], contains(id));
  }
  expect(controller.preferredLocale, 'zh');
  await tester.tap(find.widgetWithText(TextButton, '外观'));
  await tester.pumpAndSettle();
}

void _expectSettingsStyle(WidgetTester tester) {
  for (final String label in <String>['浮窗配色', '为桌面上的浮窗选择一套颜色。', '冷酷色系']) {
    final BuildContext context = tester.element(find.text(label));
    expect(DefaultTextStyle.of(context).style.fontWeight, FontWeight.w700);
    expect(Theme.of(context).scaffoldBackgroundColor, Colors.white);
  }
  final Rect macaron = tester.getRect(
    find.widgetWithText(OutlinedButton, '马卡龙色系'),
  );
  final Rect glass = tester.getRect(
    find.widgetWithText(OutlinedButton, '马卡龙玻璃'),
  );
  final Rect cool = tester.getRect(find.widgetWithText(OutlinedButton, '冷酷色系'));
  final Rect sunset = tester.getRect(
    find.widgetWithText(OutlinedButton, '日落暖调'),
  );
  expect(macaron.width, closeTo(cool.width, 0.01));
  expect(macaron.width, closeTo(glass.width, 0.01));
  expect(cool.width, closeTo(sunset.width, 0.01));
  expect(glass.left - macaron.right, closeTo(14, 0.01));
  expect(cool.top - macaron.bottom, closeTo(14, 0.01));
  expect(sunset.left - cool.right, closeTo(14, 0.01));
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

bool _isSettingsPreview(Widget widget) =>
    widget is StickerGroupSurface && !widget.interactive;

Color? _windowBackground(WidgetTester tester) =>
    _windowDecoration(tester).color;

BoxDecoration _windowDecoration(WidgetTester tester) {
  final DecoratedBox background = tester.widget<DecoratedBox>(
    find.byKey(const ValueKey<String>('sticker-window-background')),
  );
  return background.decoration as BoxDecoration;
}

void _visibility(bool visible) {}
