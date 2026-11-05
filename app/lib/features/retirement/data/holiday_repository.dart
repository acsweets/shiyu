import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'holiday_download.dart';
import 'holiday_pack.dart';
import 'settings_store.dart';

typedef HolidayTextReader = Future<String> Function();

enum HolidayUpdate { idle, checking, latest, updated, failed, rejected }

enum HolidayOrigin { bundled, downloaded, imported }

typedef HolidaySelection = ({HolidayPack pack, HolidayOrigin origin});

abstract interface class HolidayRepository {
  Future<HolidaySelection?> read(String region);
  Future<HolidayUpdate> check();
  Future<HolidayUpdate> importPack(String region, String raw);
}

/// 选取最新的有效数据。网络与导入失败时原缓存保持完整。
class LocalHolidayRepository implements HolidayRepository {
  LocalHolidayRepository(
    this.directory, {
    HolidayTextReader? bundled,
    HolidayTextReader? download,
  }) : _bundled = bundled ?? _readAsset,
       _download = download ?? downloadHolidayCatalog;

  final Directory directory;
  final HolidayTextReader _bundled;
  final HolidayTextReader _download;
  Future<Map<String, HolidayPack>>? _bundledPacks;

  static Future<String> _readAsset() =>
      rootBundle.loadString('assets/holidays/calendar.json');

  LocalSettingsStore get _downloaded =>
      LocalSettingsStore(directory, fileName: 'calendar.json');

  LocalSettingsStore _imported(String region) =>
      LocalSettingsStore(directory, fileName: 'import-$region.json');

  @override
  Future<HolidaySelection?> read(String region) async {
    if (!holidayRegions.contains(region)) return null;
    HolidaySelection? selected;
    final HolidayPack? bundled = (await _builtIn())[region];
    if (bundled != null) {
      selected = (pack: bundled, origin: HolidayOrigin.bundled);
    }
    final HolidayPack? cached = (await _readCache())[region];
    if (cached != null && cached.version > (selected?.pack.version ?? 0)) {
      selected = (pack: cached, origin: HolidayOrigin.downloaded);
    }
    final HolidayPack? imported = await _readImport(region);
    if (imported != null && imported.version > (selected?.pack.version ?? 0)) {
      selected = (pack: imported, origin: HolidayOrigin.imported);
    }
    return selected;
  }

  @override
  Future<HolidayUpdate> check() async {
    try {
      final String raw = await _download();
      final Map<String, HolidayPack> candidate = parseHolidayCatalog(raw);
      final Map<String, HolidayPack> bundled = await _builtIn();
      final Map<String, HolidayPack> cached = await _readCache();
      bool changed = false;
      for (final String region in holidayRegions) {
        final HolidayPack next = candidate[region]!;
        final HolidayPack? previous = cached[region];
        final HolidayPack? installed = bundled[region];
        if (_invalidSuccessor(next, previous) ||
            _invalidSuccessor(next, installed)) {
          return HolidayUpdate.rejected;
        }
        if (next.version > (previous?.version ?? 0) &&
            next.version > (installed?.version ?? 0)) {
          changed = true;
        }
      }
      if (!changed) return HolidayUpdate.latest;
      await _downloaded.write(raw);
      return HolidayUpdate.updated;
    } on FormatException {
      return HolidayUpdate.rejected;
    } catch (_) {
      return HolidayUpdate.failed;
    }
  }

  @override
  Future<HolidayUpdate> importPack(String region, String raw) async {
    try {
      if (utf8.encode(raw).length > holidayMaxBytes) {
        return HolidayUpdate.rejected;
      }
      final HolidayPack candidate = HolidayPack.parse(jsonDecode(raw), region);
      final HolidayPack? selected = (await read(region))?.pack;
      if (_invalidSuccessor(candidate, selected)) return HolidayUpdate.rejected;
      if (candidate.version == selected?.version) return HolidayUpdate.latest;
      await _imported(region).write(raw);
      return HolidayUpdate.updated;
    } on FormatException {
      return HolidayUpdate.rejected;
    } catch (_) {
      return HolidayUpdate.failed;
    }
  }

  bool _invalidSuccessor(HolidayPack next, HolidayPack? previous) {
    if (previous == null) return false;
    final int currentYear = DateTime.now().year;
    return next.version < previous.version ||
        (next.version == previous.version && next.sha != previous.sha) ||
        previous.years.any(
          (int year) => year >= currentYear && !next.years.contains(year),
        );
  }

  Future<Map<String, HolidayPack>> _builtIn() =>
      _bundledPacks ??= _parseCatalog(_bundled);

  Future<Map<String, HolidayPack>> _readCache() =>
      _parseCatalog(_readDownloaded);

  Future<String> _readDownloaded() async => await _downloaded.read() ?? '';

  Future<Map<String, HolidayPack>> _parseCatalog(
    HolidayTextReader reader,
  ) async {
    try {
      return parseHolidayCatalog(await reader());
    } catch (_) {
      return const <String, HolidayPack>{};
    }
  }

  Future<HolidayPack?> _readImport(String region) async {
    try {
      final String? raw = await _imported(region).read();
      return raw == null ? null : HolidayPack.parse(jsonDecode(raw), region);
    } catch (_) {
      return null;
    }
  }
}
