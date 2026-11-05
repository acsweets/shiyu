import 'package:flutter/services.dart';

const MethodChannel desktopRuntimeChannel = MethodChannel('shiyu/runtime');

Future<bool> desktopFlag(String method, [Object? argument]) async {
  try {
    return await desktopRuntimeChannel.invokeMethod<bool>(method, argument) ??
        false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
