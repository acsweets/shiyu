import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';

import 'support/test_controller.dart';

class RecordingCore extends TestCore {
  final List<int> calls = <int>[];

  @override
  Future<String> compute(
    String settings,
    int nowMillis, {
    String holidayJson = '{}',
  }) async {
    calls.add(nowMillis);
    return '{"ok":true,"snapshot":{"is_workday":true,"retirement":{"status":"counting","remaining_days":0,"remaining_seconds":86400}}}';
  }
}

void main() {
  testWidgets('按整秒调度，隐藏和暂停时停止，时钟变更后重新计算', _verifySchedule);
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
