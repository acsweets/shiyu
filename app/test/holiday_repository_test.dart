import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/features/retirement/data/holiday_pack.dart';
import 'package:shiyu/features/retirement/data/holiday_repository.dart';

void main() {
  test('六地区内置文件通过校验且覆盖 2026/2027', _verifyAssets);
  test('离线、坏文件和版本回退都保留最新合法数据', _verifyRepository);
}

Future<String> _loadAsset() =>
    File('assets/holidays/calendar.json').readAsString();

Future<void> _verifyAssets() async {
  final Map<String, HolidayPack> packs = parseHolidayCatalog(
    await _loadAsset(),
  );
  for (final HolidayPack pack in packs.values) {
    expect(pack.years, <int>[2026, 2027]);
  }
  expect(packs['CN']!.coreJson, contains('"2027-02-14":true'));
  expect(packs['US']!.coreJson, contains('"2027-07-05":false'));
  expect(packs['JP']!.coreJson, contains('"2026-09-22":false'));
  expect(packs['KR']!.coreJson, contains('"2026-07-17":false'));
  expect(packs['HK']!.coreJson, contains('"2027-02-09":false'));
  expect(packs['TW']!.coreJson, contains('"2027-12-31":false'));
}

Future<void> _verifyRepository() async {
  final Directory temporary = await Directory.systemTemp.createTemp(
    'shiyu-holidays-',
  );
  try {
    await _exerciseCache(temporary);
  } finally {
    await for (final FileSystemEntity item in temporary.list()) {
      await item.delete();
    }
    await temporary.delete();
  }
}

Future<void> _exerciseCache(Directory temporary) async {
  final String bundled = await _loadAsset();
  String? network;
  final LocalHolidayRepository repository = LocalHolidayRepository(
    temporary,
    bundled: _loadAsset,
    download: () async => network ?? (throw const SocketException('offline')),
  );
  expect((await repository.read('CN'))!.origin, HolidayOrigin.bundled);
  expect(await repository.check(), HolidayUpdate.failed);
  network = bundled;
  expect(await repository.check(), HolidayUpdate.latest);

  final HolidayJson catalog = jsonDecode(bundled) as HolidayJson;
  final HolidayJson packs = catalog['packs'] as HolidayJson;
  final HolidayJson china = packs['CN'] as HolidayJson;
  final HolidayJson payload = china['payload'] as HolidayJson;
  final int firstVersion = china['version'] as int;
  china['version'] = firstVersion + 1;
  _seal(china, payload);
  network = jsonEncode(catalog);
  expect(await repository.check(), HolidayUpdate.updated);
  expect((await repository.read('CN'))!.origin, HolidayOrigin.downloaded);

  network = bundled;
  expect(await repository.check(), HolidayUpdate.rejected);
  network = '{';
  expect(await repository.check(), HolidayUpdate.rejected);
  expect(
    await repository.importPack('JP', jsonEncode(china)),
    HolidayUpdate.rejected,
  );

  final HolidayJson dates = payload['date_overrides'] as HolidayJson;
  dates['2028-01-01'] = false;
  china['version'] = firstVersion + 2;
  expect(
    await repository.importPack('CN', jsonEncode(china)),
    HolidayUpdate.rejected,
  );
  _seal(china, payload);
  expect(
    await repository.importPack('CN', jsonEncode(china)),
    HolidayUpdate.rejected,
  );
  dates.remove('2028-01-01');
  dates['2026-11-06'] = false;
  _seal(china, payload);
  expect(
    await repository.importPack('CN', jsonEncode(china)),
    HolidayUpdate.updated,
  );
  final HolidaySelection selected = (await repository.read('CN'))!;
  expect(selected.origin, HolidayOrigin.imported);
  expect(selected.pack.coreJson, contains('"2026-11-06":false'));
  await File('${temporary.path}/import-CN.json').writeAsString('invalid');
  expect((await repository.read('CN'))!.pack.version, firstVersion + 1);
  await File('${temporary.path}/calendar.json').writeAsString('invalid');
  expect((await repository.read('CN'))!.origin, HolidayOrigin.bundled);
  final LocalHolidayRepository missing = LocalHolidayRepository(
    temporary,
    bundled: () async => '{}',
  );
  expect(await missing.read('CN'), isNull);
}

void _seal(HolidayJson pack, HolidayJson payload) {
  pack['sha256'] = sha256
      .convert(utf8.encode(jsonEncode(<Object?>[pack['version'], payload])))
      .toString();
}
