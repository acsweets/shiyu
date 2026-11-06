import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/app/shiyu_app.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';

import 'support/test_controller.dart';

class RecordingCore extends TestCore {
  RecordingCore({this.requiresTarget = false, this.earning = false});

  /// 用于覆盖从静止快照切换到活动快照。
  final bool requiresTarget;

  /// 模拟仅有计薪变化而没有活动倒计时的快照。
  final bool earning;

  /// 记录 Rust 网关收到的墙钟。
  final List<int> calls = <int>[];

  @override
  Future<String> compute(
    String settings,
    int nowMillis, {
    String holidayJson = '{}',
  }) async {
    calls.add(nowMillis);
    final int seconds =
        !requiresTarget || settings.contains('"retirement_date":"') ? 86400 : 0;
    final String salary = earning
        ? ',"salary":{"status":"earning","today_earned":"${nowMillis ~/ 1000 % 60}.00","currency":"CNY"}'
        : '';
    return '{"ok":true,"snapshot":{"is_workday":true,"retirement":{"status":"counting","remaining_days":0,"remaining_seconds":$seconds}$salary}}';
  }
}

class RecordingWidgets extends TestWidgets {
  /// 模拟已发送到系统的刷新请求数。
  int refreshes = 0;

  @override
  bool get supported => true;

  @override
  Future<void> refresh() async {
    refreshes++;
  }
}

void main() {
  testWidgets('按整秒调度，隐藏和暂停时停止，时钟变更后重新计算', _verifySchedule);
  testWidgets('保存新目标后从低频等待切回逐秒刷新', _verifyNewTarget);
  testWidgets('手机计薪按秒更新，手动刷新立即重算并请求更新小组件', _verifyEarnings);
}

Future<void> _verifyEarnings(WidgetTester tester) async {
  final RecordingCore core = RecordingCore(requiresTarget: true, earning: true);
  final RecordingWidgets widgets = RecordingWidgets();
  final DateTime start = DateTime.utc(2026, 11, 6, 8);
  final DateTime testStart = tester.binding.clock.now();
  final RetirementController controller = RetirementController(
    core: core,
    store: MemorySettingsStore(),
    widgets: widgets,
    now: () => start.add(tester.binding.clock.now().difference(testStart)),
  );
  addTearDown(controller.dispose);
  await controller.initialize();
  controller.setVisible(true);
  await tester.pumpWidget(
    ShiyuApp(controller: controller, locale: const Locale('en')),
  );
  await tester.pump();
  expect(find.text('0.00 CNY'), findsOneWidget);
  await tester.pump(const Duration(seconds: 1));
  expect(find.text('1.00 CNY'), findsOneWidget);

  controller.setVisible(false);
  await tester.pump(const Duration(seconds: 1));
  expect(find.text('1.00 CNY'), findsOneWidget);
  await tester.tap(find.byTooltip('Refresh earnings'));
  await tester.pumpAndSettle();
  expect(find.text('2.00 CNY'), findsOneWidget);
  expect(widgets.refreshes, 1);
}

Future<void> _verifyNewTarget(WidgetTester tester) async {
  final RecordingCore core = RecordingCore(requiresTarget: true);
  final RetirementController controller = RetirementController(
    core: core,
    store: MemorySettingsStore(),
    widgets: TestWidgets(),
    now: tester.binding.clock.now,
  );
  await controller.initialize();
  controller.setVisible(true);
  await tester.pump();
  final int quietCalls = core.calls.length;
  await tester.pump(const Duration(seconds: 2));
  expect(core.calls, hasLength(quietCalls));
  expect(await controller.save('2029-03-01', 'Asia/Shanghai'), isTrue);
  final int updatedCalls = core.calls.length;
  await tester.pump(const Duration(seconds: 1));
  expect(core.calls, hasLength(updatedCalls + 1));
  controller.dispose();
}

Future<void> _verifySchedule(WidgetTester tester) async {
  final RecordingCore core = RecordingCore();
  final DateTime start = DateTime.utc(2026, 11, 5, 23, 59, 59, 250);
  final DateTime testStart = tester.binding.clock.now();
  Duration offset = Duration.zero;
  final RetirementController controller = RetirementController(
    core: core,
    store: MemorySettingsStore(),
    widgets: TestWidgets(),
    now: () =>
        start.add(tester.binding.clock.now().difference(testStart) + offset),
  );
  addTearDown(controller.dispose);
  await controller.initialize();
  controller.setVisible(true);
  await tester.pump();
  expect(core.calls.last, start.millisecondsSinceEpoch);
  final int initialCalls = core.calls.length;
  await tester.pump(const Duration(milliseconds: 749));
  expect(core.calls, hasLength(initialCalls));
  await tester.pump(const Duration(milliseconds: 1));
  expect(core.calls.last, DateTime.utc(2026, 11, 6).millisecondsSinceEpoch);

  controller.setPaused(true);
  await tester.pump(const Duration(minutes: 2));
  expect(core.calls, hasLength(initialCalls + 1));
  controller.setPaused(false);
  await tester.pump();
  expect(
    core.calls.last,
    DateTime.utc(2026, 11, 6, 0, 2).millisecondsSinceEpoch,
  );

  controller.setSystemSuspended(true);
  await tester.pump(const Duration(seconds: 10));
  expect(core.calls, hasLength(initialCalls + 2));
  offset = const Duration(hours: 3);
  controller.clockChanged();
  await tester.pump();
  expect(core.calls, hasLength(initialCalls + 2));
  controller.setSystemSuspended(false);
  await tester.pump();
  expect(
    core.calls.last,
    DateTime.utc(2026, 11, 6, 3, 2, 10).millisecondsSinceEpoch,
  );

  controller.setVisible(false);
  await tester.pump(const Duration(seconds: 5));
  expect(core.calls, hasLength(initialCalls + 3));
  controller.setVisible(true);
  await tester.pump();
  offset = const Duration(hours: 4);
  controller.clockChanged();
  await tester.pump();
  expect(
    core.calls.last,
    DateTime.utc(2026, 11, 6, 4, 2, 15).millisecondsSinceEpoch,
  );
  controller.dispose();
  await tester.pump(const Duration(minutes: 1));
  expect(core.calls, hasLength(initialCalls + 5));
}
