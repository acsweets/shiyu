import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/retirement/data/settings_store.dart';

void main() {
  test('本地设置可以原子替换已有文件', _verifyAtomicStore);
}

Future<void> _verifyAtomicStore() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'shiyu-store-',
  );
  final LocalSettingsStore store = LocalSettingsStore(directory);
  expect(await store.read(), isNull);
  await store.write('{"schema_version":1,"retirement_date":null}');
  const String second = '{"schema_version":1,"retirement_date":"2050-01-01"}';
  await store.write(second);
  expect(await LocalSettingsStore(directory).read(), second);
  expect(await File('${directory.path}/settings.json.tmp').exists(), isFalse);
  await directory.delete(recursive: true);
}
