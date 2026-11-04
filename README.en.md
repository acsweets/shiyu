# Shiyu · 时余

[简体中文](README.md) | [English](README.en.md)

A local-first tool for keeping track of time and earnings, targeting Windows, macOS, iOS, and Android.

## Current features

The project is at the M0 minimal runtime stage. The normal entry point still opens a development status page. The table below describes capabilities present in the code; time and earnings calculations have not been implemented.

| Implemented | Current behavior |
| --- | --- |
| Initialization page | Displays an hourglass icon, app name, tagline, and development status |
| System language support | Page text is available in Simplified Chinese, Traditional Chinese, English, Japanese, Korean, Spanish, German, and French; unsupported languages fall back to Simplified Chinese. There is no in-app language selector yet |
| Adaptive layout | Centers content, limits its maximum width, and allows scrolling when space is limited; respects system text scaling and safe areas |
| Rust runtime integration | Normal startup loads the real Rust library. Flutter/FRB and Android Kotlin/UniFFI share the same core and have passed probe tests |
| Separate development entry point | `lib/main_probe.dart` provides Rust and desktop window/tray/shortcut probes; it is not the final product UI |

Platform status: the Windows release build and real native integration tests have passed. An Android 16 / API 36 / x86_64 emulator has passed build, installation, and integration runtime tests. macOS/iOS build adapters and verification scripts are provided for the user to validate on a Mac. MVP product acceptance testing remains incomplete on all four platforms; emulator success does not establish physical device support.

### Planned MVP features

The following features are part of the frozen requirements and are all pending implementation:

| Feature | Planned behavior |
| --- | --- |
| Life countdown | Show remaining time based on date of birth and expected lifespan |
| Work status | Show work status and countdowns based on schedules, lunch breaks, working days, and holidays |
| Daily/monthly earnings | Calculate earnings from effective working time using decimal arithmetic, with an option to hide amounts |
| Payday countdown | Support a fixed monthly date, the last working day of the month, and twice-monthly paydays |
| Next break | Identify consecutive days off and show countdowns to the start and end of a break |
| Retirement countdown | Show remaining time until the user's chosen retirement date |
| Custom desktop countdowns | Create, edit, delete, and reorder countdowns with updates every second |
| Desktop floating window and system integration | Mini, standard, and expanded modes; transparency, always-on-top behavior, dragging, edge snapping, click-through behavior, multiple displays, system tray/menu bar access, and shortcuts |
| Local settings and holidays | Persist, import, and export settings; configure region and language; bundle holiday data with online updates and offline fallback |
| Skins and resource packs | Two built-in skins, plus resource pack validation, import, export, and installation |
| Mobile app and widgets | Full-screen mobile feature UI and iOS/Android countdown and earnings widgets; mobile custom countdowns are outside version 1.0 |

See the [Frozen MVP requirements 1.0](doc/桌面悬浮计时器/需求/MVP-冻结需求-1.0.md) for the full scope and acceptance criteria (in Chinese).

## Repository boundaries

`workspace` holds multiple independent repositories. It is neither a Git repository nor a shared Dart/Cargo workspace. This repository is rooted at `workspace/shiyu`, with `https://github.com/acsweets/shiyu.git` configured as `origin`. Future projects belong alongside `shiyu`, each with its own Git history, dependencies, and build configuration.

```text
workspace/
├── shiyu/                     # This independent repository
│   ├── app/                   # Flutter app for four platforms; package: shiyu
│   │   ├── lib/app/           # App composition, theme, and routing
│   │   ├── lib/features/      # UI and state organized by feature
│   │   └── lib/l10n/          # ARB files for eight languages and generated code
│   ├── core/                  # Rust workspace within this repository
│   │   └── crates/engine/     # shiyu_core pure computation engine
│   ├── doc/                   # Existing product and technical documentation
│   ├── docs/                  # Development milestones, node plans, and future evidence
│   ├── scripts/               # Repository check scripts
│   └── .github/workflows/     # CI
└── <other-projects>/          # Separate repositories
```

## Environment and running the app

The project was initialized with Flutter **3.47.2 stable** / Dart **3.13.2** and Rust **1.95.0**. CI pins the same versions. The app's `pubspec.lock` and Rust's `Cargo.lock` are committed. The Apple/Android application identifier is `com.growthrecord.shiyu`. The current development version is `0.1.0+1`, targeting MVP 1.0.

From the repository root:

```powershell
cd app
flutter pub get
flutter gen-l10n
flutter run -d windows
```

For Android, use a device ID reported by `flutter devices`. For macOS, run `flutter run -d macos` on a Mac. iOS requires a Mac, Xcode, and an available simulator or device signing setup. The project targets iOS 15.0+, macOS 12.0+, and Android API 24+. The Windows product target is Windows 10+, which still requires validation on the target systems.

## Checks and conventions

Run `./scripts/check.ps1` from the repository root to generate localizations, check formatting, run static analysis and startup smoke tests, and check the Rust workspace. Add `-BuildWindows` to verify a Windows release build. CI includes these checks and the Windows build. CI for other platforms and device acceptance testing will be added later.

On November 4, 2026, Windows release builds, Flutter formatting/analysis/two startup tests, Rust fmt/clippy/test, and real Windows/Android native integration tests passed. Run `./scripts/check_m0.ps1 -AndroidDeviceId <device-ID>` to check the runtime paths; optionally pass `-GradleUserHome <short-cache-path>` to isolate local proxy or path configuration. CI includes Windows and Android APK builds with a Rust library packaging check; consult Actions for remote results.

See the [M0 verification report](docs/验收记录/01/README.md) for commands, artifacts, and environment limitations. Run `flutter run -d windows -t lib/main_probe.dart` from `app/` for the desktop probes. The [Mac verification guide](native/ios/README.md) covers Apple builds and the generated Swift binding probe (in Chinese).

An ARM64 debug APK for phone testing has also passed compilation and packaged Rust ABI checks. Physical device runtime verification remains pending; local artifact paths are listed in the report.

Flutter code is organized by feature. Dart variables use explicit types, function types are named through typedefs, and anonymous callbacks longer than three lines are extracted into named functions. Comments in handwritten code are in Chinese, with purpose comments for member fields and core methods. Native templates and bindings are maintained through their generation tools.

## Engineering scope and progress

The repository includes scaffolding for four platforms, a root Riverpod container, ARB localization, and a responsive initialization page. FRB and UniFFI now call the same Rust core, which currently provides only a runtime probe. jiff, rust_decimal, formal data contracts, business calculations, and settings storage remain planned. Android debug builds contain a native probe widget; product countdown/earnings widgets and independent widget cold-start acceptance remain pending.

See “Current features” above for progress. At the user's request, the first milestone covers Windows/Android runtime success, with Apple verification deferred to the user. This does not complete the original four-platform G0 or the MVP. The initialization page contains no fabricated earnings or countdown values.

This initialization adds no accounts, telemetry, or application network requests. Future implementation must preserve the principle that salary data and personal settings stay on the device.

## Requirements

The following source documents are in Chinese:

- [Sequential development plan and milestones](docs/开发计划/README.md): an existing baseline followed by nodes 01–14, each with implementation TODOs, review steps, and completion criteria.
- [Project information](doc/桌面悬浮计时器/项目基础信息.md)
- [Frozen MVP requirements 1.0](doc/桌面悬浮计时器/需求/MVP-冻结需求-1.0.md)
- [Development steps, schedule, and testing](doc/桌面悬浮计时器/需求/最终开发步骤-排期-测试验证.md)

The frozen requirements take precedence over historical proposals. In the development plan's example directory structure, `workspace/` corresponds to this repository's `shiyu/` directory, rather than the outer container for multiple repositories.
