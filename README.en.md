# Shiyu · 时余

> Group desktop countdowns in a single floating window or split them across windows. Each cat rests against the top edge of its window in a different pose. Grouped countdowns share one cat. Move and resize each window independently, and use settings to hide the window or its titles. Open settings from the main window icon, or from the tray or menu bar when the main window is hidden. Turn off the sample preview to see the real Rust retirement countdown. See [desktop window groups](docs/界面设计/06-桌面浮窗分组.md).

[简体中文](README.md) | [English](README.en.md)

The separate desktop Settings window includes Appearance, Window Management, Countdowns, and Cat Assets, with live preview and undo for moving countdowns. See the [desktop settings design](docs/界面设计/07-桌面设置设计.md).

Windows, macOS, Android, and iOS share the [orange tabby app icon](app/assets/brand/README.md).

A local-first time and earnings tool for Windows, macOS, iOS, and Android. `workspace/shiyu` is an independent Git repository; its parent holds unrelated projects with separate dependencies and histories.

## Current features

The project is at node 04. The retirement countdown is available in desktop floating windows and mobile home screen widgets. Rust now exposes all six built-in metrics and custom countdowns. The [project record](docs/项目记录/README.md) captures the approved design and feature baseline.

| Feature | Current behavior |
| --- | --- |
| Retirement countdown | User-selected retirement date and IANA time zone. Rust returns calendar days and remaining seconds. Reached dates show “Retired”; no target is fabricated on first launch |
| Desktop floating window | Frameless, always-on-top Windows/macOS windows with countdown grouping, independent movement and resizing, per-window visibility and title controls, and an adjustable title font size. Choose Macaron, Cool, or Warm Sunset for the full card background. The tray or menu bar provides settings, show, and exit. Ctrl/Cmd+Shift+T hides or restores the enabled windows |
| Mobile settings | The app opens directly to settings for the retirement date, time zone, and home screen widget appearance. Choose from three palettes, show or hide the title, and adjust its size |
| Local settings | Desktop app support directory, Android private storage and iOS App Group. Validate before atomic replacement; reload after restart; invalid files are not automatically overwritten |
| Android home screen widget | The cat sits above the card, with the title above a single-line retirement countdown. Tap the widget to open settings. It calls Rust via UniFFI independently of Flutter |
| iOS home screen widget | Small and medium WidgetKit layouts show the cat retirement countdown. The extension reads App Group settings and calls Rust independently. Requires verification on a Mac |
| Calculation core | Rust snapshots cover lifespan, work shifts, earnings, paydays, breaks, retirement, and custom countdowns. Supports fixed-clock snapshots, batched timelines, and in-memory countdown updates |
| Earnings and privacy | Gross or net monthly pay accrues across scheduled workdays and actual working time. Amounts are truncated as decimal strings, and hidden snapshots expose only the mask |
| Core contracts/calendar | Versioned JSON, field validation, explicit now and IANA zone. Personal date overrides precede custom holidays, regional date overrides and weekly workdays. Missing holiday data produces an explicit fallback status |
| Localization/probes | Existing mobile UI uses ARB for eight languages; the new desktop review UI is Chinese. Native widgets use Chinese/English. `lib/main_probe.dart` remains a separate engineering probe |

On phones, the countdown lives on the system home screen. Android displays the most recent countdown snapshot as days and a clock. Settings changes trigger a refresh, and the OS schedules regular updates. iOS uses a WidgetKit timeline, with a system countdown during the final day on iOS 16 and later.

Node 01 Windows/Android runtime checks passed, and the user has reported Mac validation ready. See the [node 02 acceptance record](docs/验收记录/02/README.md) for this node’s executed checks and outstanding acceptance items. New iOS widget compilation, signing and runtime verification require the user’s Mac; static checks on Windows do not establish an Apple runtime pass.

## Still pending

- Complete settings and UI integration for earnings, lifespan, work status, paydays, and breaks.
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

On Mac, use `flutter run -d macos`. The [Apple guide](native/ios/README.md) covers widget builds, signing and adding the widget. On mobile, open Shiyu and choose your retirement date. On Android, add the widget from Settings or your launcher. On iOS, add it from the home screen widget gallery. See the [mobile home screen widget and settings design](docs/界面设计/08-手机浮窗与设置.md).

From the repository root, run `./scripts/check.ps1 -BuildWindows` for Flutter formatting/analysis/tests, Windows Release and Rust fmt/clippy/tests. Native integration checks for nodes 02–04.

```powershell
cd app
flutter test integration_test/retirement_test.dart -d windows
flutter test integration_test/retirement_test.dart -d emulator-5554
flutter test integration_test/salary_timeline_test.dart -d emulator-5554
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
