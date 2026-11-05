import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'holiday_pack.dart';

/// 固定公开 URL 返回所有地区，同一次请求不透露用户选择的地区。
final Uri holidayCatalogUri = Uri.https(
  'raw.githubusercontent.com',
  '/acsweets/shiyu/main/app/assets/holidays/calendar.json',
);

Future<String> downloadHolidayCatalog() async {
  final HttpClient client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5);
  try {
    return await _download(client).timeout(const Duration(seconds: 10));
  } finally {
    client.close(force: true);
  }
}

Future<String> _download(HttpClient client) async {
  final HttpClientRequest request = await client.getUrl(holidayCatalogUri);
  request.followRedirects = false;
  final HttpClientResponse response = await request.close();
  if (response.statusCode != HttpStatus.ok ||
      response.contentLength > holidayMaxBytes) {
    throw const HttpException('holiday_download');
  }
  final BytesBuilder bytes = BytesBuilder(copy: false);
  await for (final List<int> chunk in response) {
    if (bytes.length + chunk.length > holidayMaxBytes) {
      throw const FormatException('holiday_download_size');
    }
    bytes.add(chunk);
  }
  return utf8.decode(bytes.takeBytes());
}
