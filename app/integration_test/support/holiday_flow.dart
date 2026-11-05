import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';
import 'package:shiyu/features/retirement/data/holiday_repository.dart';
import 'package:shiyu/features/retirement/data/settings_store.dart';
import 'package:shiyu/features/retirement/domain/core_gateway.dart';

import '../../test/support/test_controller.dart';

/// 从内置日历运行真实 Rust 快照，不访问网络或个人存储。
Future<void> verifyHolidayFlow(Directory directory) async {
  final RetirementController controller = RetirementController(
    core: RustCoreGateway(),
    store: LocalSettingsStore(
      directory,
      fileName: 'holiday-test-settings.json',
    ),
    widgets: TestWidgets(),
    holidays: LocalHolidayRepository(directory),
    now: () => DateTime.utc(2027, 2, 14, 2),
  );
  try {
    await controller.initialize();
    expect(controller.snapshot!.calendarStatus, 'available');
    expect(controller.snapshot!.workday, isTrue);
    expect(
      await controller.saveSettings(<String, dynamic>{
        ...controller.settings,
        'hide_amount': false,
        'salary': <String, dynamic>{'gross_monthly': '22000'},
      }),
      isTrue,
    );
    expect(
      controller.snapshot!.data['salary'],
      containsPair('status', 'earning'),
    );
    expect(
      await controller.saveSettings(<String, dynamic>{
        ...controller.settings,
        'holidays': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': '验收假期',
            'start': '2027-02-14',
            'end': '2027-02-15',
            'kind': 'custom',
          },
        ],
      }),
      isTrue,
    );
    expect(controller.snapshot!.workday, isFalse);
    expect(
      controller.snapshot!.data['salary'],
      containsPair('today_earned', '0.00'),
    );
    expect(
      await controller.saveSettings(<String, dynamic>{
        ...controller.settings,
        'date_overrides': <String, bool>{'2027-02-14': true},
      }),
      isTrue,
    );
    expect(controller.snapshot!.workday, isTrue);
    expect(
      controller.snapshot!.data['salary'],
      containsPair('status', 'earning'),
    );
  } finally {
    controller.dispose();
    final File settings = File('${directory.path}/holiday-test-settings.json');
    if (await settings.exists()) await settings.delete();
  }
}
