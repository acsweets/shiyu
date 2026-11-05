import 'dart:io';

/// 按地区读取本地假日日历。缺失时由 Rust 使用周工作日回退。
abstract interface class HolidayRepository {
  Future<String> read(String region);
}

class LocalHolidayRepository implements HolidayRepository {
  const LocalHolidayRepository(this.directory);

  /// 应用私有的假日缓存目录。
  final Directory directory;

  @override
  Future<String> read(String region) async {
    if (!const <String>{'CN', 'US', 'JP', 'KR', 'HK', 'TW'}.contains(region)) {
      return '{}';
    }
    final File file = File('${directory.path}/$region.json');
    if (!await file.exists()) return '{}';
    if (await file.length() > 512 * 1024) return '{}';
    return file.readAsString();
  }
}
