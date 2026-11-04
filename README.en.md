# Shiyu · 时余

[简体中文](README.md) | [English](README.en.md)

A local-first tool for keeping track of time and earnings, targeting Windows, macOS, iOS, and Android.

## Current features

The project is at the initialization stage. Running the app opens a development status page. The table below describes capabilities present in the code; time and earnings calculations have not been implemented.

| Implemented | Current behavior |
| --- | --- |
| Initialization page | Displays an hourglass icon, app name, tagline, and development status |
| System language support | Page text is available in Simplified Chinese, Traditional Chinese, English, Japanese, Korean, Spanish, German, and French; unsupported languages fall back to Simplified Chinese. There is no in-app language selector yet |
| Adaptive layout | Centers content, limits its maximum width, and allows scrolling when space is limited; respects system text scaling and safe areas |

Platform status: the Windows release build has passed on the current Windows 11 machine, along with startup tests. Android, iOS, and macOS project files have been generated, but builds and device testing remain unverified. Product acceptance testing is incomplete on all four platforms.

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

For Android, use a device ID reported by `flutter devices`. For macOS, run `flutter run -d macos` on a Mac. iOS requires a Mac, Xcode, and an available simulator or device signing setup. The generated project currently targets iOS 15.0+ and macOS 12.0+. Android retains the pinned Flutter SDK's default minimum version. The Windows product target is Windows 10+, which still requires validation on the target systems.

## Checks and conventions

Run `./scripts/check.ps1` from the repository root to generate localizations, check formatting, run static analysis and startup smoke tests, and check the Rust workspace. Add `-BuildWindows` to verify a Windows release build. CI includes these checks and the Windows build. CI for other platforms and device acceptance testing will be added later.

On November 4, 2026, `./scripts/check.ps1 -BuildWindows` passed on the current Windows machine: formatting, Flutter static analysis, two startup tests, the Windows release build, and Rust fmt/clippy. Android builds have not been verified: some local SDK licenses remain unaccepted, and the Google Maven connectivity check reported an issue. iOS/macOS require verification on a Mac. The GitHub CI configuration is included in the repository; consult Actions for remote run results.

Flutter code is organized by feature. Dart variables use explicit types, function types are named through typedefs, and anonymous callbacks longer than three lines are extracted into named functions. Comments in handwritten code are in Chinese, with purpose comments for member fields and core methods. Native templates and bindings are maintained through their generation tools.

## Initialization scope

The repository includes project scaffolding for four platforms, a root Riverpod container, ARB localization, and a responsive initialization page. The Rust crate establishes the module boundary but contains no calculation implementation. Flutter and Rust are not yet linked. flutter_rust_bridge, UniFFI, jiff, rust_decimal, and settings storage will be introduced according to the frozen development plan.

See “Current features” above for feature progress. This scaffold does not complete M0 risk validation or the MVP. The initialization page contains no fabricated earnings or countdown values.

This initialization adds no accounts, telemetry, or application network requests. Future implementation must preserve the principle that salary data and personal settings stay on the device.

## Requirements

The following source documents are in Chinese:

- [Sequential development plan and milestones](docs/开发计划/README.md): an existing baseline followed by nodes 01–14, each with implementation TODOs, review steps, and completion criteria.
- [Project information](doc/桌面悬浮计时器/项目基础信息.md)
- [Frozen MVP requirements 1.0](doc/桌面悬浮计时器/需求/MVP-冻结需求-1.0.md)
- [Development steps, schedule, and testing](doc/桌面悬浮计时器/需求/最终开发步骤-排期-测试验证.md)

The frozen requirements take precedence over historical proposals. In the development plan's example directory structure, `workspace/` corresponds to this repository's `shiyu/` directory, rather than the outer container for multiple repositories.
