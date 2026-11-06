# Shiyu · 时余

> Group desktop countdowns in a floating window or split them across windows. A cat in a different pose rests against the top edge of each window. Move and resize windows independently, and hide titles in settings. Open settings from the main window or the tray or menu bar. Turn off the sample preview to see live metrics. See [desktop window groups](docs/界面设计/06-桌面浮窗分组.md).

[简体中文](README.md) | [English](README.en.md)

The separate desktop Settings window includes Appearance, Window Management, Countdowns, and Cat Assets, with live preview and undo for moving countdowns. See the [desktop settings design](docs/界面设计/07-桌面设置设计.md).

Windows, macOS, Android, and iOS share the [orange tabby app icon](app/assets/brand/README.md).

A local-first time and earnings tool for Windows, macOS, iOS, and Android. `workspace/shiyu` is an independent Git repository; its parent holds unrelated projects with separate dependencies and histories.

## Current features

Desktop floating windows and the mobile dashboard show metrics calculated by Rust. Desktop also supports custom countdowns. Android and iOS offer countdown and earnings home screen widgets. The app supports local settings backups, recovery, and offline holiday data for six regions. The [project record](docs/项目记录/README.md) tracks the current implementation and verification status.

| Feature | Current behavior |
| --- | --- |
| Retirement countdown | User-selected retirement date and IANA time zone. Rust returns calendar days and remaining seconds. Reached dates show “Retired”; no target is fabricated on first launch |
| Life metric | Enter a birth date in Settings → Countdowns on mobile or Full Settings → Personal Information on desktop. Choose Life countdown or Days lived. The value line shows only the day count and unit. The count starts at zero on the birth date and increases at midnight in the configured time zone |
| Titles by metric | Open Full Settings → Floating Window on desktop or Settings → Titles by Metric on mobile. Hide individual titles while keeping their values visible. This includes custom countdowns on desktop. Floating windows and widgets also retain their master title switches |
| Desktop floating window | Frameless, always-on-top Windows/macOS windows with countdown grouping, independent movement and resizing, per-window visibility and title controls, and an adjustable title font size. Choose Macaron, Macaron Glass, Cool, or Warm Sunset. Macaron Glass has a translucent gradient and a light border and works with the background opacity control. The tray or menu bar provides settings, show, and exit. Ctrl/Cmd+Shift+T hides or restores the enabled windows |
| Desktop modes | Mini, Standard, and Expanded share the live Rust snapshot. Double-click to switch between Mini and Standard, or choose Expanded in settings. Reorder or hide metrics and add custom countdowns. Use Countdowns settings to show or hide Earned Today and the Life countdown. Expanded shows available progress and dates while respecting amount visibility |
| Desktop system controls | The tray or menu bar controls visibility, click-through, amount masking, refresh, and holiday checks. Settings support edge snapping, per-display placement, full-screen coverage, an earnings shortcut, and launch at login. Login items require macOS 13 or later |
| Desktop skins and cat assets | Choose Simple Card or Dark Tech, light, dark, or system appearance, 30–100% background opacity, one of three number sizes, and an accent. Replace PNGs locally or import, export, and open `.timerpack` files. [Resource guide](docs/界面设计/04-用户资源制作指南.md) |
| Mobile dashboard and settings | Active countdowns and accruing earnings recalculate each second. The top bar also offers manual refresh. Narrow screens and larger text use one column. The settings hub links directly to countdowns, schedule and pay, dates and holidays, titles, widgets, and general preferences. Pick shift times and save each form from the bottom of the screen |
| Onboarding and full settings | New installs guide you through personal information, work and pay, and a live preview. Configure paydays, date overrides, holidays, and one of eight languages. Import or export settings as local JSON. Desktop full settings autosave and include custom countdowns and mini-window metric preferences |
| Local settings and widget data | Desktop app support directory, Android private storage, and iOS App Group. Settings are validated before saving, with legacy migration and backup recovery. Mobile apps atomically share verified holiday data by region with native widgets. Amounts are masked when widget settings fall back to a backup |
| Refresh | Active countdowns refresh on whole seconds. Desktop refresh pauses when all floating windows are hidden or when paused in Countdowns settings. It recalculates from the current system time when shown or resumed |
| Android home screen widgets | Tap a countdown widget to combine one to four of work, holidays, payday, retirement and life in a single card. The button inside the earnings card below the cat refreshes today and this month and respects amount masking. Both call Rust via UniFFI |
| iOS home screen widgets | Small and medium WidgetKit layouts support countdowns and earnings. On iOS 17 or later, add up to three countdowns beside the main metric and refresh earnings directly on the widget. iOS 15 and 16 use preset layouts and offer manual earnings refresh from the app dashboard. The extension reads App Group data and calls Rust via UniFFI. Requires verification on a Mac |
| Calculation core | Rust snapshots cover lifespan, work shifts, earnings, paydays, breaks, retirement, and custom countdowns. Supports fixed-clock snapshots, batched timelines, and in-memory countdown updates |
| Earnings and privacy | Gross or net monthly pay accrues across scheduled workdays and actual working time. Amounts are truncated as decimal strings, and hidden snapshots expose only the mask |
| Core contracts/calendar | Versioned JSON, field validation, explicit now and IANA zone. Personal date overrides precede custom holidays, regional date overrides and weekly workdays. Missing holiday data produces an explicit fallback status |
| Regional holidays | Bundled 2026–2027 holiday data for mainland China, the US, Japan, South Korea, Hong Kong, and Taiwan. Settings can check for updates and import regional JSON. Missing data falls back to the weekly schedule. [Sources and format](docs/决策记录/0003-节假日来源与更新.md) |
| App language | In mobile Settings or desktop Settings → Appearance, choose the system language, Simplified Chinese, Traditional Chinese, English, Japanese, Korean, Spanish, German, or French. The mobile app, full settings, live metrics, and desktop settings navigation follow this choice. Some desktop controls remain in Chinese. Native widgets offer Chinese and English |

Use Home Screen Widgets in mobile Settings to add a widget or adjust its colors, titles, and text size. Android and iOS 16 or later use system timers for live countdown seconds. The OS schedules target and status changes. Android's timer can briefly show a negative value after a deadline if the refresh is delayed. The app requests earnings updates about once a minute. [Node 12 checks](docs/验收记录/12/README.md)

## Verification status

Windows 11 Release and the Android API 36 x86_64 emulator have runtime evidence. Earlier macOS runs were reported. The current Apple builds and native behavior await verification. Node 13 tracks multi-display, physical devices, performance and endurance. Node 14 covers signed distribution. [Current project record](docs/项目记录/README.md) · [Node 13 acceptance record](docs/验收记录/13/README.md)

## Run and build

Start in the `shiyu/` repository root. The development version is `0.1.0+1` and the application ID is `com.growthrecord.shiyu`. The repository targets Windows, macOS, Android, and iOS.

### Shared setup

Install Flutter **3.47.2**, which includes Dart **3.13.2**, plus Git and Rustup. Add the Flutter and Rust tools to PATH. Set up the target platform SDK and run the following commands. The first dependency restore requires network access. Normal builds use the bindings checked into the repository.

```sh
flutter doctor -v
rustup toolchain install 1.95.0 --profile minimal --component clippy --component rustfmt
cd app
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format lib/l10n/generated
flutter devices
```

Run each platform block from `app/`. Replace `DEVICE_ID` with the actual ID from `flutter devices`. Run platform builds sequentially in a single working tree.

### Windows

Install Visual Studio on Windows with the Desktop development with C++ workload and Windows SDK. [Flutter Windows setup](https://docs.flutter.dev/platform-integration/windows/setup)

```powershell
flutter run -d windows
# Exit the debug instance before building and opening Release
flutter build windows --release
.\build\windows\x64\runner\Release\shiyu.exe
```

The x64 Release executable, DLLs and `data/` are in the same directory. Keep the directory together when copying the build. To switch builds, exit the old instance from the Shiyu tray menu. Windows sends subsequent launches to the existing instance, which can stay running with its windows hidden.

### macOS

Install Xcode and its command-line tools on a Mac and complete Xcode first-launch setup. Install CocoaPods for plugins that still use podspecs. The deployment target is macOS 12, and launch at login requires macOS 13 or later. [Flutter macOS setup](https://docs.flutter.dev/platform-integration/macos/setup) · [Flutter native plugin dependencies](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)

```sh
flutter run -d macos
flutter build macos --release
open build/macos/Build/Products/Release/shiyu.app
```

Use the menu bar to restore hidden windows. Local Release builds are for development. Signing and notarization are tracked in the [release node](docs/开发计划/14-签名打包与发布验收.md).

### Android

Install Android Studio or Android SDK tools. Repository CI uses JDK 21, Android SDK Platform 36 and NDK **28.2.13676358**. Install Platform-Tools and Command-line Tools, then run `flutter doctor --android-licenses` to complete SDK license setup. The minimum device API is 24. Start an emulator or connect a physical device with USB debugging enabled. [Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup)

```sh
flutter devices
flutter run -d DEVICE_ID

# Release APK for an x86_64 emulator
flutter build apk --release --target-platform android-x64
adb -s DEVICE_ID install -r build/app/outputs/flutter-apk/app-release.apk
```

For an ARM64 device or emulator, build with `flutter build apk --release --target-platform android-arm64`. Both single-ABI commands write `app-release.apk`. Copy and rename the first artifact if you need both. Release currently uses the debug signing key for local installs. After saving settings in the app, add Countdown and Earnings from Settings → Home Screen Widgets or the launcher widget picker.

### iOS

Use a Mac with Xcode, an iOS simulator runtime and CocoaPods. The deployment target is iOS 15. Start the simulator in Xcode. For a physical device, enable Developer Mode and configure `Runner` and `ShiyuWidgets` with the same developer team and App Group. [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup) · [Shiyu Apple signing and verification](native/ios/README.md)

```sh
flutter devices
flutter run -d DEVICE_ID
flutter build ios --simulator --debug
```

The simulator build produces `build/ios/iphonesimulator/Runner.app`. For signing in Xcode, prepare the configuration with `flutter build ios --config-only --no-codesign` and open `ios/Runner.xcworkspace`. Runner builds and embeds the extension. Launch the app, save settings and add Shiyu from the home screen widget gallery. iOS 16 or later supports system timer text. The main countdown widget becomes editable on iOS 17 or later.

### Checks and troubleshooting

- From the repository root, use PowerShell 7 to run `pwsh -File scripts/check.ps1`. On Windows, add `-BuildWindows` for a Release build. On a Mac, run `bash scripts/check_apple.sh` to verify the Swift-to-Rust bridge and build macOS Release and iOS simulator Debug.
- From `app/`, run `flutter test integration_test/retirement_test.dart -d DEVICE_ID` to exercise the real binding and settings flow. Use `windows` or `macos` for desktop and the actual device ID for mobile.
- If a device is missing, check the emulator or device connection, then run `flutter doctor -v` and `flutter devices`. If Gradle cannot download dependencies, check the repository and proxy in the error. Offline builds require a complete cache. If a widget cannot read settings, check that it was added, the app saved its settings, and the iOS targets have matching signing and App Group configuration. [Troubleshooting index](docs/项目记录/技术架构与验证.md#构建与验证)

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

Rust owns business calculations. Views present the results. The app uses the network only to download public holiday data and has no accounts, telemetry, or personal configuration uploads. Both Git author and committer must be `star <1395723441@qq.com>`.

- [Development plan and checklists](docs/开发计划/README.md)
- [Data contract v1](docs/技术说明/数据契约-v1.md)
- [Project background](doc/桌面悬浮计时器/项目基础信息.md)
- [Historical M0 acceptance](docs/验收记录/01/README.md)
