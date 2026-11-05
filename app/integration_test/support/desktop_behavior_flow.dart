import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyu/platform/desktop/desktop_bridge.dart';
import 'package:shiyu/platform/desktop/desktop_options.dart';
import 'package:shiyu/platform/desktop/floating_window_controller.dart';
import 'package:window_manager/window_manager.dart';

typedef RegisterNative = ffi.Int32 Function(
  ffi.Pointer<ffi.Void>,
  ffi.Int32,
  ffi.Uint32,
  ffi.Uint32,
);
typedef RegisterDart = int Function(ffi.Pointer<ffi.Void>, int, int, int);
typedef UnregisterNative = ffi.Int32 Function(ffi.Pointer<ffi.Void>, ffi.Int32);
typedef UnregisterDart = int Function(ffi.Pointer<ffi.Void>, int);

Future<void> verifyDesktopBehavior(
  WidgetTester tester,
  FloatingWindowController window,
) async {
  if (!Platform.isWindows) return;
  expect(window.startupSupported, isTrue);
  final VoidCallback? original = window.openSettings;
  int activations = 0;
  window.openSettings = () => activations++;
  try {
    final ProcessResult repeated = await Process.run(
      Platform.resolvedExecutable,
      <String>[],
    );
    expect(repeated.exitCode, 0);
    for (int count = 0; count < 8 && activations == 0; count++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(activations, 1);
  } finally {
    window.openSettings = original;
  }
  await _verifyShortcutConflict();
  expect(
    await window.applyOptions(const DesktopOptions(clickThrough: true)),
    isTrue,
  );
  expect(await window.applyOptions(const DesktopOptions()), isTrue);
  await window.setSystemFullscreen(true);
  expect(await windowManager.isVisible(), isFalse);
  expect(
    await window.applyOptions(const DesktopOptions(coverFullscreen: true)),
    isTrue,
  );
  expect(await windowManager.isVisible(), isTrue);
  await window.setSystemFullscreen(false);
  expect(await window.applyOptions(const DesktopOptions()), isTrue);
  for (int index = 0; index < 100; index++) {
    await window.hide();
    await window.show();
  }
  expect(await windowManager.isVisible(), isTrue);
}

Future<void> _verifyShortcutConflict() async {
  final ffi.DynamicLibrary user32 = ffi.DynamicLibrary.open('user32.dll');
  final RegisterDart register = user32
      .lookupFunction<RegisterNative, RegisterDart>('RegisterHotKey');
  final UnregisterDart unregister = user32
      .lookupFunction<UnregisterNative, UnregisterDart>('UnregisterHotKey');
  const int identity = 911;
  const int controlShift = 0x0002 | 0x0004;
  for (final int letter in 'JKLQUV'.codeUnits) {
    if (register(ffi.nullptr, identity, controlShift, letter) == 0) continue;
    try {
      expect(
        await desktopFlag('amountShortcut', String.fromCharCode(letter)),
        isFalse,
      );
    } finally {
      unregister(ffi.nullptr, identity);
    }
    expect(
      await desktopFlag('amountShortcut', String.fromCharCode(letter)),
      isTrue,
    );
    expect(await desktopFlag('amountShortcut', ''), isTrue);
    return;
  }
  fail('No free key to create an isolated native conflict');
}
