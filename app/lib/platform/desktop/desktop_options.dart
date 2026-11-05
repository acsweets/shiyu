/// 本机窗口偏好，业务设置仍由 Rust 处理。
class DesktopOptions {
  const DesktopOptions({
    this.snap = true,
    this.clickThrough = false,
    this.coverFullscreen = false,
    this.amountShortcut = '',
  });

  factory DesktopOptions.read(Object? value) {
    final Map<Object?, Object?> raw =
        value as Map<Object?, Object?>? ?? const <Object?, Object?>{};
    final Object? shortcut = raw['amountShortcut'];
    return DesktopOptions(
      snap: raw['snap'] != false,
      clickThrough: raw['clickThrough'] == true,
      coverFullscreen: raw['coverFullscreen'] == true,
      amountShortcut:
          shortcut is String &&
              RegExp(r'^[A-Z]$').hasMatch(shortcut) &&
              shortcut != 'T'
          ? shortcut
          : '',
    );
  }

  final bool snap;
  final bool clickThrough;
  final bool coverFullscreen;
  final String amountShortcut;

  Map<String, Object?> get data => <String, Object?>{
    'snap': snap,
    'clickThrough': clickThrough,
    'coverFullscreen': coverFullscreen,
    'amountShortcut': amountShortcut,
  };
}
