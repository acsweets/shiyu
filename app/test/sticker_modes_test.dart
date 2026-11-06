import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/desktop_stickers/application/sticker_group_view.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_layout.dart';
import 'package:shiyu/features/desktop_stickers/data/sticker_mode.dart';
import 'package:shiyu/features/desktop_stickers/presentation/countdown_sticker.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';
import 'package:shiyu/features/retirement/domain/retirement_snapshot.dart';

import 'support/test_controller.dart';

void main() {
  testWidgets('三态共享快照、完整时间与遮蔽，窄窗可滚动，全部隐藏仍可配置', _verifyModes);
}

Future<void> _verifyModes(WidgetTester tester) async {
  final RetirementController controller = await createTestController();
  final StickerLayout layout = StickerLayout()..preview = false;
  addTearDown(controller.dispose);
  addTearDown(layout.dispose);
  for (final String id in StickerLayout.titles.keys) {
    layout.assign(id, layout.mainGroup);
  }
  controller.settings['display'] = <String, dynamic>{'locale': 'en'};
  controller.snapshot = RetirementSnapshot.fromJson(<String, dynamic>{
    'calendar_status': 'available',
    'is_workday': true,
    'life': <String, dynamic>{
      'status': 'active',
      'remaining_seconds': 86401,
      'target_millis': 120000000,
    },
    'retirement': <String, dynamic>{
      'status': 'active',
      'remaining_days': 1,
      'remaining_seconds': 86404,
      'target_millis': 120000000,
    },
    'work': <String, dynamic>{
      'status': 'working',
      'remaining_seconds': 3723,
      'target_millis': 120000000,
      'target_kind': 'work_end',
      'progress': 0.5,
    },
    'salary': <String, dynamic>{
      'hidden': true,
      'today_earned': '****',
      'month_earned': '****',
      'currency': 'CNY',
      'today_progress': 0.5,
    },
    'holiday': <String, dynamic>{
      'status': 'on_holiday',
      'remaining_seconds': 3600,
      'target_millis': 120000000,
      'next_interval': <String, dynamic>{
        'first_rest_date': '2027-02-05',
        'last_rest_date': '2027-02-13',
      },
    },
    'custom_countdowns': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'launch',
        'name': 'Launch',
        'status': 'expired',
        'remaining_seconds': 0,
        'target_millis': 1,
      },
    ],
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(280, 146);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final StickerGroupView mini = _view(layout, controller);
  expect(mini.label('holiday'), 'On break');
  expect(mini.values['holiday'], '01:00:00');
  expect(mini.values['life'], '1 d · 00:00:01');
  expect(mini.values.keys, <String>[
    'work',
    'today_salary',
    'holiday',
    'life',
    'retirement',
    'custom/launch',
  ]);
  await tester.pumpWidget(_host(mini));
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey<String>('sticker-custom/launch')),
    80,
  );
  expect(find.text('Ended'), findsOneWidget);

  tester.view.physicalSize = const Size(540, 650);
  layout.setMode(StickerMode.standard);
  final StickerGroupView standard = _view(layout, controller);
  expect(standard.values['work'], mini.values['work']);
  expect(standard.values.keys, containsAll(<String>['month_salary', 'payday']));
  layout.setMode(StickerMode.expanded);
  final StickerGroupView expanded = _view(layout, controller);
  expect(expanded.values, standard.values);
  expect(expanded.metrics['today_salary']!['progress'], isNull);
  expect(expanded.metrics['holiday']!['detail'], '2027-02-05 – 2027-02-13');
  await tester.pumpWidget(_host(expanded));
  await tester.pumpAndSettle();
  expect(find.byType(LinearProgressIndicator), findsOneWidget);
  expect(find.text('****'), findsNWidgets(2));
  expect(tester.takeException(), isNull);

  controller.settings['display'] = <String, dynamic>{
    'locale': 'en',
    'enabled_metrics': <String>['work', 'holiday', 'life', 'retirement'],
  };
  for (final StickerMode mode in StickerMode.values) {
    layout.setMode(mode);
    final Map<String, String> visible = _view(layout, controller).values;
    final Map<String, String> baseline = mode == StickerMode.mini
        ? mini.values
        : standard.values;
    expect(visible, <String, String>{...baseline}..remove('today_salary'));
  }

  controller.snapshot = RetirementSnapshot.fromJson(<String, dynamic>{
    ...controller.snapshot!.data,
    'life': <String, dynamic>{'status': 'elapsed', 'elapsed_days': 1234},
  });
  expect(_view(layout, controller).values['life'], '1,234 days');
  controller.settings['display'] = <String, dynamic>{
    'locale': 'en',
    'enabled_metrics': <String>[
      'work',
      'today_salary',
      'holiday',
      'retirement',
    ],
  };
  for (final StickerMode mode in StickerMode.values) {
    layout.setMode(mode);
    final Map<String, String> visible = _view(layout, controller).values;
    final Map<String, String> baseline = mode == StickerMode.mini
        ? mini.values
        : standard.values;
    expect(visible, <String, String>{...baseline}..remove('life'));
  }

  controller.settings['display'] = <String, dynamic>{
    'locale': 'en',
    'enabled_metrics': <String>[],
  };
  controller.snapshot = RetirementSnapshot.fromJson(<String, dynamic>{
    'is_workday': true,
    'retirement': <String, dynamic>{
      'status': 'unconfigured',
      'remaining_days': 0,
      'remaining_seconds': 0,
    },
  });
  await tester.pumpWidget(_host(_view(layout, controller)));
  expect(find.text('All metrics are hidden'), findsOneWidget);
  expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
}

StickerGroupView _view(StickerLayout layout, RetirementController controller) =>
    StickerGroupView.fromLayout(layout, controller, layout.mainGroup, true);

Widget _host(StickerGroupView view) => MaterialApp(
  home: StickerGroupSurface(
    view: view,
    interactive: false,
    onSettings: _settings,
  ),
);

void _settings() {}
