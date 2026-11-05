import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 只接受单卷小型 ZIP，校验目录和每个条目后再流式读取，永不使用包内路径写盘。
class TimerPackZip {
  static const int maxFileBytes = 2 * 1024 * 1024;
  static const int maxDecodedBytes = 6 * 1024 * 1024;
  static const int maxZipBytes = 8 * 1024 * 1024;
  static const int _local = 0x04034b50;
  static const int _central = 0x02014b50;
  static const int _end = 0x06054b50;

  static Map<String, Uint8List> read(Uint8List raw, Set<String> allowed) {
    if (raw.length < 22 || raw.length > maxZipBytes) _bad();
    final ByteData source = ByteData.sublistView(raw);
    final int end = raw.length - 22;
    final int count = _short(source, end + 10);
    final int directory = _word(source, end + 16);
    if (_word(source, end) != _end ||
        _word(source, end + 4) != 0 ||
        _short(source, end + 8) != count ||
        _short(source, end + 20) != 0 ||
        count == 0 ||
        count > allowed.length ||
        directory + _word(source, end + 12) != end) {
      _bad();
    }
    final Map<String, Uint8List> result = <String, Uint8List>{};
    int position = directory;
    int total = 0;
    for (int index = 0; index < count; index++) {
      final _ZipItem item = _header(raw, source, position, end);
      if (!allowed.contains(item.name) || result.containsKey(item.name)) _bad();
      total += item.size;
      if (total > maxDecodedBytes) _bad();
      result[item.name] = _content(raw, source, item, directory);
      position = item.next;
    }
    if (position != end) _bad();
    return result;
  }

  static _ZipItem _header(Uint8List raw, ByteData data, int offset, int end) {
    if (offset + 46 > end || _word(data, offset) != _central) _bad();
    final int flags = _short(data, offset + 8);
    final int method = _short(data, offset + 10);
    final int packed = _word(data, offset + 20);
    final int size = _word(data, offset + 24);
    final int nameLength = _short(data, offset + 28);
    final int fileType = (_word(data, offset + 38) >> 16) & 0xf000;
    final int nameOffset = offset + 46;
    final int next =
        nameOffset +
        nameLength +
        _short(data, offset + 30) +
        _short(data, offset + 32);
    if (next > end ||
        nameLength == 0 ||
        nameLength > 80 ||
        (flags & ~0x080e) != 0 ||
        (method != 0 && method != 8) ||
        (fileType != 0 && fileType != 0x8000 && fileType != 0x4000) ||
        _short(data, offset + 34) != 0 ||
        size > maxFileBytes ||
        packed > maxZipBytes) {
      _bad();
    }
    return (
      name: ascii.decode(
        Uint8List.sublistView(raw, nameOffset, nameOffset + nameLength),
      ),
      flags: flags,
      method: method,
      packed: packed,
      size: size,
      crc: _word(data, offset + 16),
      local: _word(data, offset + 42),
      next: next,
    );
  }

  static Uint8List _content(
    Uint8List raw,
    ByteData data,
    _ZipItem item,
    int directory,
  ) {
    final int local = item.local;
    if (local + 30 > directory ||
        _word(data, local) != _local ||
        _short(data, local + 6) != item.flags ||
        _short(data, local + 8) != item.method) {
      _bad();
    }
    final int nameEnd = local + 30 + _short(data, local + 26);
    final int from = nameEnd + _short(data, local + 28);
    final int to = from + item.packed;
    if (to > directory ||
        ascii.decode(Uint8List.sublistView(raw, local + 30, nameEnd)) !=
            item.name) {
      _bad();
    }
    if ((item.flags & 8) == 0 &&
        (_word(data, local + 14) != item.crc ||
            _word(data, local + 18) != item.packed ||
            _word(data, local + 22) != item.size)) {
      _bad();
    }
    final Uint8List bytes = item.method == 0
        ? Uint8List.sublistView(raw, from, to)
        : _inflate(raw, from, to, item.size);
    if (bytes.length != item.size || _crc32(bytes) != item.crc) _bad();
    return bytes;
  }

  static Uint8List _inflate(Uint8List raw, int from, int to, int size) {
    final _LimitedSink output = _LimitedSink(size);
    final Sink<List<int>> decoder = ZLibDecoder(raw: true)
        .startChunkedConversion(output);
    for (int offset = from; offset < to; offset += 1024) {
      decoder.add(
        Uint8List.sublistView(raw, offset, (offset + 1024).clamp(offset, to)),
      );
    }
    decoder.close();
    return output.bytes.takeBytes();
  }

  /// 导出采用 ZIP STORE，标准 ZIP 工具可以查看和修改。
  static Uint8List write(Map<String, Uint8List> files) {
    final BytesBuilder body = BytesBuilder(copy: false);
    final BytesBuilder directory = BytesBuilder(copy: false);
    for (final MapEntry<String, Uint8List> item in files.entries) {
      final List<int> name = ascii.encode(item.key);
      final int length = item.value.length;
      final int crc = _crc32(item.value);
      final ByteData local = ByteData(30)
        ..setUint32(0, _local, Endian.little)
        ..setUint16(4, 20, Endian.little)
        ..setUint32(14, crc, Endian.little)
        ..setUint32(18, length, Endian.little)
        ..setUint32(22, length, Endian.little)
        ..setUint16(26, name.length, Endian.little);
      final ByteData entry = ByteData(46)
        ..setUint32(0, _central, Endian.little)
        ..setUint16(4, 20, Endian.little)
        ..setUint16(6, 20, Endian.little)
        ..setUint32(16, crc, Endian.little)
        ..setUint32(20, length, Endian.little)
        ..setUint32(24, length, Endian.little)
        ..setUint16(28, name.length, Endian.little)
        ..setUint32(42, body.length, Endian.little);
      body
        ..add(local.buffer.asUint8List())
        ..add(name)
        ..add(item.value);
      directory
        ..add(entry.buffer.asUint8List())
        ..add(name);
    }
    final ByteData footer = ByteData(22)
      ..setUint32(0, _end, Endian.little)
      ..setUint16(8, files.length, Endian.little)
      ..setUint16(10, files.length, Endian.little)
      ..setUint32(12, directory.length, Endian.little)
      ..setUint32(16, body.length, Endian.little);
    body
      ..add(directory.takeBytes())
      ..add(footer.buffer.asUint8List());
    return body.takeBytes();
  }

  static int _short(ByteData source, int at) =>
      source.getUint16(at, Endian.little);
  static int _word(ByteData source, int at) =>
      source.getUint32(at, Endian.little);
  static Never _bad() => throw const FormatException('timerpack_zip');

  static final List<int> _crcTable = List<int>.generate(256, _crcEntry);

  static int _crcEntry(int value) {
    for (int index = 0; index < 8; index++) {
      value = (value >> 1) ^ (value.isOdd ? 0xedb88320 : 0);
    }
    return value;
  }

  static int _crc32(Uint8List bytes) {
    int crc = 0xffffffff;
    for (final int byte in bytes) {
      crc = (crc >> 8) ^ _crcTable[(crc ^ byte) & 0xff];
    }
    return crc ^ 0xffffffff;
  }
}

typedef _ZipItem = ({
  String name,
  int flags,
  int method,
  int packed,
  int size,
  int crc,
  int local,
  int next,
});

class _LimitedSink implements Sink<List<int>> {
  _LimitedSink(this.limit);
  final int limit;
  final BytesBuilder bytes = BytesBuilder(copy: false);

  @override
  void add(List<int> data) {
    if (bytes.length + data.length > limit) {
      throw const FormatException('timerpack_inflated_size');
    }
    bytes.add(data);
  }

  @override
  void close() {}
}
