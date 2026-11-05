import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/retirement/application/retirement_controller.dart';
import 'package:shiyu/features/retirement/data/settings_repository.dart';
import 'package:shiyu/features/retirement/data/settings_store.dart';

import 'support/test_controller.dart';

class UnsupportedVersionCore extends TestCore {
  @override
  Future<String> validate(String settings) async =>
      '{"ok":false,"errors":[{"field":"schema_version","code":"unsupported_version"}]}';
}

void main() {
  test('未来版本设置保留原件且禁止用默认值覆盖', _verifyUnknownVersion);
  test('迁移前备份，损坏启动保持只读，显式恢复才替换原件', _verifyRecovery);
  test('写入异常后保留合法主配置，重新启动仍可加载', _verifyFailedWrite);
  test('原子替换不会留下临时目录', _verifyAtomicStore);
}

class VersionedCore extends TestCore {
  @override
  Future<String> validate(String settings) async {
    try {
      final SettingsValues values = jsonDecode(settings) as SettingsValues;
      if (values['schema_version'] == 1) return await super.validate(settings);
    } catch (_) {
      // 模拟 Rust 对损坏 JSON 的拒绝。
    }
    return '{"ok":false,"errors":[]}';
  }
}

class InterruptedStore extends MemorySettingsStore {
  bool interrupted = false;

  @override
  Future<void> write(String json) async {
    if (interrupted) throw const FileSystemException('simulated interruption');
    await super.write(json);
  }
}

Future<void> _verifyRecovery() async {
  const String legacy = '{"schema_version":0,"retirement_date":"2050-01-01"}';
  const String damaged = '{"schema_version":';
  final MemorySettingsStore primary = MemorySettingsStore()..value = legacy;
  final MemorySettingsStore backup = MemorySettingsStore();
  final MemorySettingsStore archive = MemorySettingsStore();
  final SettingsRepository repository = SettingsRepository(
    core: VersionedCore(),
    primary: primary,
    backup: backup,
    archive: archive,
  );
  expect((await repository.load()).values['schema_version'], 1);
  expect(primary.value, contains('"schema_version":1'));
  expect(backup.value, legacy);
  primary.value = damaged;
  final LoadedSettings result = await repository.load();
  expect(result.canRestore, isTrue);
  expect(result.problem, 'invalid_settings');
  expect(primary.value, damaged);
  expect(archive.value, isNull);
  expect(await repository.restoreBackup(), result.values);
  expect(archive.value, damaged);
  expect((await repository.load()).problem, isNull);
}

Future<void> _verifyFailedWrite() async {
  const String previous = '{"schema_version":1,"retirement_date":"2050-01-01"}';
  final InterruptedStore primary = InterruptedStore()..value = previous;
  final MemorySettingsStore backup = MemorySettingsStore();
  final SettingsRepository repository = SettingsRepository(
    core: VersionedCore(),
    primary: primary,
    backup: backup,
  );
  await repository.load();
  primary.interrupted = true;
  await expectLater(
    repository.save(<String, dynamic>{
      'schema_version': 1,
      'retirement_date': '2060-01-01',
    }),
    throwsA(isA<FileSystemException>()),
  );
  expect(primary.value, previous);
  expect(backup.value, previous);
  expect((await repository.load()).values['retirement_date'], '2050-01-01');
}

Future<void> _verifyAtomicStore() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'shiyu-atomic-',
  );
  try {
    final LocalSettingsStore store = LocalSettingsStore(directory);
    await store.write('{"schema_version":0}');
    await store.write('{"schema_version":1}');
    expect(await store.read(), '{"schema_version":1}');
    expect(await directory.list().length, 1);
    if (!Platform.isWindows) {
      final FileStat stat = await File('${directory.path}/settings.json')
          .stat();
      expect(stat.mode & 0x1ff, 0x180);
    }
  } finally {
    await File('${directory.path}/settings.json').delete();
    await directory.delete();
  }
}

Future<void> _verifyUnknownVersion() async {
  const String original = '{"schema_version":99,"future_field":true}';
  final MemorySettingsStore store = MemorySettingsStore()..value = original;
  final RetirementController controller = RetirementController(
    core: UnsupportedVersionCore(),
    store: store,
    widgets: TestWidgets(),
  );
  await controller.initialize();
  expect(controller.editingBlocked, isTrue);
  expect(await controller.save('2050-01-01', 'Asia/Shanghai'), isFalse);
  expect(store.value, original);
  controller.dispose();
}
