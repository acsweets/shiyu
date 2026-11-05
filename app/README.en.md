# Shiyu Flutter app

The desktop cat stickers can be grouped or split into independent, resizable system windows with per-window title controls. Turn off the labeled sample preview for real retirement data. See [desktop window groups](../docs/界面设计/06-桌面浮窗分组.md).

[简体中文](README.md) | [English](README.en.md)

This directory is the Flutter root. The independent Git repository is its parent, `shiyu/`.

Current features include a real retirement countdown, retirement date/time zone settings with atomic local storage, Windows/macOS floating window and tray/shortcut integration, an Android native retirement widget, and an iOS Widget extension connected to Xcode. The foreground displays seconds; widgets display calendar days. Earnings and other metrics remain pending. New Apple code in this node requires user verification on a Mac.

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format lib/l10n/generated
flutter run -d windows
```

For mobile, use the device ID reported by `flutter devices`. Add the Android widget from the app. Follow the [Apple guide](../native/ios/README.md) for shared-group signing and iOS widget setup.

See the [English repository README](../README.en.md) for scope, toolchains and checks, and the [node 02 acceptance guide](../docs/验收记录/02/README.md) for verification. The entry point is `lib/main.dart`; retirement UI/state is under `lib/features/retirement/`; business rules are in Rust under `../core/`.
