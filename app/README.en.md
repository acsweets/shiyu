# Shiyu Flutter app

[简体中文](README.md) | [English](README.en.md)

This directory is the Flutter project root. The Git repository is rooted one level above, in `shiyu/`. See the [repository README](../README.en.md) for environment requirements, check commands, requirements, and architecture.

```powershell
flutter pub get
flutter gen-l10n
flutter run -d windows
```

The entry point is `lib/main.dart`, and the root widget is `lib/app/shiyu_app.dart`. Features are organized by domain under `lib/features/`. Business calculations belong in the Rust core under `../core/`.
