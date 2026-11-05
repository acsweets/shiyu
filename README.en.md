# Shiyu · 时余

> Group desktop countdowns in a single floating window or split them across windows. Move and resize each window independently, and use settings to hide the window or its titles. The cat sits above the main card alongside a settings icon. Open settings from the tray or menu bar when the main window is hidden. Turn off the sample preview to see the real Rust retirement countdown. See [desktop window groups](docs/界面设计/06-桌面浮窗分组.md).

[简体中文](README.md) | [English](README.en.md)

A local-first time and earnings tool for Windows, macOS, iOS, and Android. `workspace/shiyu` is an independent Git repository; its parent holds unrelated projects with separate dependencies and histories.

## Current features

Node 02 delivers a **working retirement countdown slice**, with the remaining MVP features still pending.

| Feature | Current behavior |
| --- | --- |
| Retirement countdown | User-selected retirement date and IANA time zone. Rust returns calendar days and remaining seconds. Reached dates show “Retired”; no target is fabricated on first launch |
| Desktop floating window | Frameless, transparent, always-on-top Windows/macOS windows with countdown grouping, independent movement and resizing, and per-window visibility and title controls. The tray or menu bar provides settings, show, and exit. Ctrl/Cmd+Shift+T hides or restores the enabled windows |
| Mobile settings | Android/iOS retirement date and time zone inputs. Foreground updates recompute from the actual time every second; background UI ticks stop and resume with fresh calculations |
| Local settings | Desktop app support directory, Android private storage and iOS App Group. Validate before atomic replacement; reload after restart; invalid files are not automatically overwritten |
| Android native widget | Retirement calendar days, time zone, update time, manual refresh and tap to open. Calls Rust via UniFFI without starting a Flutter engine |
| iOS native widget | Independent embedded WidgetKit target, App Group and Rust static-library build are connected. Small/medium retirement widget with system-scheduled timelines; this node requires user verification on a Mac |
| Core contracts/calendar | Versioned JSON, field validation, explicit now and IANA zone. Personal date overrides precede custom holidays, regional date overrides and weekly workdays. Missing holiday data produces an explicit fallback status |
| Localization/probes | Existing mobile UI uses ARB for eight languages; the new desktop review UI is Chinese. Native widgets use Chinese/English. `lib/main_probe.dart` remains a separate engineering probe |

Widgets currently show **retirement days only**, with no promise of second-by-second background updates. Android requests a system-controlled 30-minute interval, plus manual/settings-triggered refreshes. iOS requests a timeline after the next Rust calendar boundary; the OS controls delivery. Foreground and widget display precision differs while sharing the same rules.

Node 01 Windows/Android runtime checks passed, and the user has reported Mac validation ready. See the [node 02 acceptance record](docs/验收记录/02/README.md) for this node’s executed checks and outstanding acceptance items. New iOS widget compilation, signing and runtime verification require the user’s Mac; static checks on Windows do not establish an Apple runtime pass.

## Still pending

- Life, work status, daily/monthly earnings, payday and next-break calculations and complete settings.
- Custom desktop countdowns; full three-mode window/metric ordering, edge snapping, click-through, multiple displays, full-screen behavior, skins and resource packs.
- Bundled six-region holiday data and updates; import/export, migration/backup/recovery and onboarding.
- All four countdown widget metrics and earnings widgets; physical Android and this node’s Apple checks; performance, endurance, signed releases.

These remain in the [node plan](docs/开发计划/README.md). Early retirement integration does not complete nodes 08–12. See the [frozen MVP scope](doc/桌面悬浮计时器/需求/MVP-冻结需求-1.0.md).

## Run and verify

Pinned tools: Flutter **3.47.2** / Dart **3.13.2**, Rust **1.95.0**, with committed lockfiles. Minimums: iOS 15, macOS 12, Android API 24. Application ID: `com.growthrecord.shiyu`; development version: `0.1.0+1`.

```powershell
cd app
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format lib/l10n/generated
flutter run -d windows
# Use a device ID returned by flutter devices
flutter run -d emulator-5554
```

On Mac, use `flutter run -d macos`. The [Apple guide](native/ios/README.md) covers widget builds, signing and adding the widget. On Android, tap “Add home screen widget” or add the Shiyu retirement widget from the launcher. Choose your own retirement date first.

From the repository root, run `./scripts/check.ps1 -BuildWindows` for Flutter formatting/analysis/tests, Windows Release and Rust fmt/clippy/tests. Native node 02 checks:

```powershell
cd app
flutter test integration_test/retirement_test.dart -d windows
flutter test integration_test/retirement_test.dart -d emulator-5554
```

Tests use synthetic dates and restore existing mobile settings; desktop tests use temporary storage. Run platform builds sequentially in this Flutter project. Localization formatting runs explicitly in the check script to avoid an observed nested Windows formatter hang. A separate short-path `GRADLE_USER_HOME` can isolate local proxy/path issues without changing global settings. CI checks Windows/Android; consult Actions for actual remote results.

## Repository layout

```text
workspace/
├── shiyu/                # This independent repository
│   ├── app/              # Flutter app and platform hosts
│   ├── core/             # Internal Rust workspace: engine / Flutter bridge / UniFFI
│   ├── native/ios/       # Swift bindings and host smoke check
│   ├── doc/              # Original requirements and technical documents
│   ├── docs/             # Node plans, contracts, decisions and acceptance records
│   └── scripts/          # Build, binding generation and checks
└── <other-repositories>/
```

Rust owns business calculations; views only present results. There are no accounts, telemetry or personal configuration uploads. The retirement slice makes no network requests. Both Git author and committer must be `star <1395723441@qq.com>`.

- [Node 02 plan and user checklist](docs/开发计划/02-数据契约与基础日历.md)
- [Data contract v1](docs/技术说明/数据契约-v1.md)
- [Project background](doc/桌面悬浮计时器/项目基础信息.md)
- [Historical M0 acceptance](docs/验收记录/01/README.md)
