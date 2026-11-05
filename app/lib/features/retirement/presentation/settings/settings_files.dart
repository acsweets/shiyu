import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../../data/settings_repository.dart';

const XTypeGroup _jsonFiles = XTypeGroup(
  label: 'JSON',
  extensions: <String>['json'],
  mimeTypes: <String>['application/json'],
  uniformTypeIdentifiers: <String>['public.json'],
);

Future<String?> pickSettingsFile() async {
  final XFile? file = await openFile(
    acceptedTypeGroups: const <XTypeGroup>[_jsonFiles],
  );
  if (file == null) return null;
  final BytesBuilder bytes = BytesBuilder(copy: false);
  await for (final List<int> chunk in file.openRead(0, settingsMaxBytes + 1)) {
    if (bytes.length + chunk.length > settingsMaxBytes) {
      throw const FormatException('settings_size');
    }
    bytes.add(chunk);
  }
  return utf8.decode(bytes.takeBytes());
}

Future<bool> exportSettingsFile(SettingsValues values) async {
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  final Uint8List bytes = Uint8List.fromList(
    utf8.encode(encoder.convert(values)),
  );
  const String name = 'shiyu-settings.json';
  if (Platform.isAndroid || Platform.isIOS) {
    return await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(
            data: bytes,
            fileName: name,
            localOnly: true,
          ),
        ) !=
        null;
  }
  final FileSaveLocation? location = await getSaveLocation(
    suggestedName: name,
    acceptedTypeGroups: const <XTypeGroup>[_jsonFiles],
  );
  if (location == null) return false;
  await XFile.fromData(
    bytes,
    name: name,
    mimeType: 'application/json',
  ).saveTo(location.path);
  return true;
}
