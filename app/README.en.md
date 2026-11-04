# Shiyu Flutter app

[简体中文](README.md) | [English](README.en.md)

This directory is the Flutter project root. The Git repository is rooted one level above, in `shiyu/`. See the [repository README](../README.en.md) for environment requirements, check commands, requirements, and architecture.

## Current features

- Initialization page showing the app name, tagline, hourglass icon, and development status.
- Page text follows the system language, supporting Simplified Chinese, Traditional Chinese, English, Japanese, Korean, Spanish, German, and French. Unsupported languages fall back to Simplified Chinese; there is no in-app language selector yet.
- Adaptive content width, scrolling, safe areas, and system text scaling.
- Normal startup loads the real Rust library. Flutter/FRB and Android Kotlin/UniFFI probes have passed; `lib/main_probe.dart` is a separate development entry point.

Business countdowns, earnings calculations, the final floating window, persistent settings, and product widgets are pending. See the [repository feature list](../README.en.md#current-features). Windows release/native integration tests and Android x86_64 emulator runtime tests have passed. Apple verification is deferred to the user on a Mac; see the [Apple guide](../native/ios/README.md) (in Chinese).

## Running the app

```powershell
flutter pub get
flutter gen-l10n
flutter run -d windows
```

The entry point is `lib/main.dart`, and the root widget is `lib/app/shiyu_app.dart`. Features are organized by domain under `lib/features/`. Business calculations belong in the Rust core under `../core/`.
