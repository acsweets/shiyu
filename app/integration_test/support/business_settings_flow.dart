import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';
import 'package:shiyu/features/retirement/data/settings_repository.dart';
import 'package:shiyu/features/retirement/data/settings_store.dart';
import 'package:shiyu/features/retirement/domain/core_gateway.dart';

import '../../test/support/test_controller.dart';

Future<void> verifyBusinessSettingsFlow(Directory directory) async {
  final LocalSettingsStore store = LocalSettingsStore(
    directory,
    fileName: 'business-test-settings.json',
  );
  final RetirementController controller = _controller(store);
  try {
    await controller.initialize();
    expect(controller.needsOnboarding, isTrue);
    expect(
      await controller.saveSettings(<String, dynamic>{
        ...controller.settings,
        'birth': <String, dynamic>{
          'date': '2000-01-01',
          'life_expectancy_years': '151',
        },
      }),
      isFalse,
    );
    expect(controller.settingsIssues.single.code, 'invalid_lifespan');
    expect(await store.read(), isNull);

    expect(
      await controller.saveSettings(<String, dynamic>{
        ...controller.settings,
        'birth': <String, dynamic>{
          'date': '2000-01-01',
          'life_expectancy_years': '90.5',
        },
        'salary': <String, dynamic>{'gross_monthly': '22000'},
        'display': <String, dynamic>{
          'onboarding_completed': true,
          'locale': 'ja',
        },
      }),
      isTrue,
    );
    final String exported = (await store.read())!;
    expect(controller.preferredLocale, 'ja');
    expect(controller.needsOnboarding, isFalse);
    expect(
      controller.snapshot!.data['salary'],
      containsPair('today_earned', '****'),
    );
    expect(
      await controller.peekSalary(),
      containsPair('today_earned', isNot('****')),
    );
    expect(
      controller.snapshot!.data['salary'],
      containsPair('today_earned', '****'),
    );
    expect(await store.read(), exported);
    await _verifyCountdown(controller);

    expect(await controller.importSettings('{"schema_version":99}'), isFalse);
    expect(await controller.importSettings('bad json'), isFalse);
    expect(await controller.importSettings(exported), isTrue);
    final RetirementController restarted = _controller(store);
    try {
      await restarted.initialize();
      expect(restarted.settings, jsonDecode(exported));
      expect(restarted.needsOnboarding, isFalse);
    } finally {
      restarted.dispose();
    }
    await _verifyPrivateRecovery(directory, exported);
  } finally {
    controller.dispose();
    final File file = File('${directory.path}/business-test-settings.json');
    if (await file.exists()) await file.delete();
  }
}

Future<void> _verifyPrivateRecovery(
  Directory directory,
  String exported,
) async {
  final LocalSettingsStore primary = LocalSettingsStore(
    directory,
    fileName: 'recovery-primary.json',
  );
  final LocalSettingsStore backup = LocalSettingsStore(
    directory,
    fileName: 'recovery-backup.json',
  );
  final LocalSettingsStore archive = LocalSettingsStore(
    directory,
    fileName: 'recovery-archive.json',
  );
  final RustCoreGateway core = RustCoreGateway();
  final SettingsValues previouslyVisible =
      jsonDecode(exported) as SettingsValues;
  previouslyVisible['hide_amount'] = false;
  await backup.write(jsonEncode(previouslyVisible));
  await primary.write('{');
  final RetirementController restored = RetirementController(
    core: core,
    store: primary,
    widgets: TestWidgets(),
    repository: SettingsRepository(
      core: core,
      primary: primary,
      backup: backup,
      archive: archive,
    ),
  );
  try {
    await restored.initialize();
    expect(restored.editingBlocked, isTrue);
    expect(restored.canRestoreBackup, isTrue);
    expect(
      restored.snapshot!.data['salary'],
      containsPair('today_earned', '****'),
    );
    expect(
      restored.snapshot!.data['salary'],
      containsPair('month_earned', '****'),
    );
    expect(await restored.peekSalary(), isNull);
    expect(await primary.read(), '{');
  } finally {
    restored.dispose();
  }
}

RetirementController _controller(LocalSettingsStore store) =>
    RetirementController(
      core: RustCoreGateway(),
      store: store,
      widgets: TestWidgets(),
      now: () => DateTime.utc(2026, 11, 5, 2),
    );

Future<void> _verifyCountdown(RetirementController controller) async {
  final SettingsValues item = <String, dynamic>{
    'id': 'launch',
    'name': '产品上线',
    'target': '2026-11-05T10:00:00',
  };
  expect(
    await controller.changeCountdown(<String, dynamic>{
      'action': 'upsert',
      'item': item,
    }),
    isFalse,
  );
  expect(controller.settingsIssues.single.code, 'target_not_future');
  item['target'] = '2026-11-05T10:00:05';
  expect(
    await controller.changeCountdown(<String, dynamic>{
      'action': 'upsert',
      'item': item,
    }),
    isTrue,
  );
  item['name'] = '新产品上线';
  item['enabled'] = false;
  expect(
    await controller.changeCountdown(<String, dynamic>{
      'action': 'upsert',
      'item': item,
    }),
    isTrue,
  );
  expect(controller.settings['custom_countdowns'], hasLength(1));
  expect(
    controller.settings['custom_countdowns'].single,
    containsPair('enabled', false),
  );
  expect(
    await controller.changeCountdown(<String, dynamic>{
      'action': 'remove',
      'id': 'launch',
    }),
    isTrue,
  );
  expect(controller.settings['custom_countdowns'], isEmpty);
}
