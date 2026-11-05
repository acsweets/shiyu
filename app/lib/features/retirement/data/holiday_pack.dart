import 'dart:convert';

import 'package:crypto/crypto.dart';

const int holidayMaxBytes = 128 * 1024;
const Map<String, Set<String>> _sourceHosts = <String, Set<String>>{
  'CN': <String>{'www.gov.cn', 'www.beijing.gov.cn', 'www2.xinhuanet.com'},
  'US': <String>{'www.opm.gov'},
  'JP': <String>{'www8.cao.go.jp'},
  'KR': <String>{'www.kasa.go.kr', 'astro.kasi.re.kr', 'www.law.go.kr'},
  'HK': <String>{'data.gov.hk', 'www.gov.hk', 'www.info.gov.hk'},
  'TW': <String>{'data.gov.tw', 'www.dgpa.gov.tw'},
};
final Set<String> holidayRegions = Set<String>.unmodifiable(_sourceHosts.keys);

typedef HolidayJson = Map<String, Object?>;

/// 一份地区数据及其版本、来源和用于核心的最小日期覆盖。
class HolidayPack {
  const HolidayPack._(this.version, this.sha, this.payload);

  final int version;
  final String sha;
  final HolidayJson payload;

  factory HolidayPack.parse(Object? raw, String region) {
    if (raw is! HolidayJson || !_sourceHosts.containsKey(region)) {
      throw const FormatException('holiday_pack');
    }
    final Object? version = raw['version'];
    final Object? sha = raw['sha256'];
    final Object? payload = raw['payload'];
    if (version is! int ||
        version <= 0 ||
        version > 9999999999 ||
        sha is! String ||
        payload is! HolidayJson ||
        payload['schema_version'] is! int ||
        payload['schema_version'] != 1 ||
        payload['region'] != region ||
        sha256
                .convert(utf8.encode(jsonEncode(<Object?>[version, payload])))
                .toString() !=
            sha) {
      throw const FormatException('holiday_integrity');
    }
    final Set<int> years = _parseYears(payload['years']);
    final Object? overrides = payload['date_overrides'];
    final Object? sources = payload['sources'];
    if (overrides is! HolidayJson ||
        sources is! HolidayJson ||
        sources.length != years.length ||
        overrides.length > 366 * years.length) {
      throw const FormatException('holiday_fields');
    }
    for (final int year in years) {
      _checkSources(sources['$year'], region);
    }
    final Set<int> yearsWithRest = <int>{};
    for (final MapEntry<String, Object?> item in overrides.entries) {
      final DateTime? date = DateTime.tryParse('${item.key}T00:00:00Z');
      if (item.value is! bool ||
          date == null ||
          !years.contains(date.year) ||
          date.toIso8601String().split('T').first != item.key) {
        throw const FormatException('holiday_date');
      }
      if (item.value == false) yearsWithRest.add(date.year);
    }
    if (yearsWithRest.length != years.length) {
      throw const FormatException('holiday_missing_year');
    }
    return HolidayPack._(version, sha, payload);
  }

  static Set<int> _parseYears(Object? raw) {
    if (raw is! List<Object?> || raw.isEmpty || raw.length > 5) {
      throw const FormatException('holiday_years');
    }
    final Set<int> years = <int>{};
    for (final Object? year in raw) {
      if (year is! int || year < 1900 || year > 9999 || !years.add(year)) {
        throw const FormatException('holiday_year');
      }
    }
    return years;
  }

  static void _checkSources(Object? raw, String region) {
    if (raw is! List<Object?> || raw.isEmpty || raw.length > 8) {
      throw const FormatException('holiday_sources');
    }
    for (final Object? source in raw) {
      if (source is! String) throw const FormatException('holiday_source');
      final Uri? uri = Uri.tryParse(source);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.userInfo.isNotEmpty ||
          !_sourceHosts[region]!.contains(uri.host)) {
        throw const FormatException('holiday_source');
      }
    }
  }

  List<int> get years => (payload['years'] as List<Object?>).cast<int>();

  String get coreJson => jsonEncode(<String, Object?>{
    'schema_version': 1,
    'region': payload['region'],
    'years': payload['years'],
    'date_overrides': payload['date_overrides'],
  });

  String get widgetJson {
    final String calendar = coreJson;
    return jsonEncode(<String, Object?>{
      'schema_version': 1,
      'version': version,
      'region': payload['region'],
      'calendar': calendar,
      'sha256': sha256.convert(utf8.encode(calendar)).toString(),
    });
  }
}

Map<String, HolidayPack> parseHolidayCatalog(String raw) {
  if (utf8.encode(raw).length > holidayMaxBytes) {
    throw const FormatException('holiday_catalog_size');
  }
  final Object? catalog = jsonDecode(raw);
  if (catalog is! HolidayJson ||
      catalog['schema_version'] is! int ||
      catalog['schema_version'] != 1) {
    throw const FormatException('holiday_catalog');
  }
  final Object? packs = catalog['packs'];
  if (packs is! HolidayJson || packs.length != holidayRegions.length) {
    throw const FormatException('holiday_regions');
  }
  return <String, HolidayPack>{
    for (final String region in holidayRegions)
      region: HolidayPack.parse(packs[region], region),
  };
}
