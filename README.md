# 时余 · shiyu

> 桌面猫猫贴纸支持合并、拆分倒计时浮窗。每个浮窗上沿贴着不同姿态的猫猫，各窗可独立移动、缩放和隐藏标题。主窗有设置入口，隐藏后可从托盘打开设置。关闭示例预览可查看真实业务指标。详见[桌面浮窗分组](docs/界面设计/06-桌面浮窗分组.md)。

[简体中文](README.md) | [English](README.en.md)

独立桌面设置窗提供外观、窗口管理、倒计时和猫猫素材四页，支持实时预览和撤销窗口移动。见[桌面设置设计](docs/界面设计/07-桌面设置设计.md)。

Windows、macOS、Android 和 iOS 使用统一的[橘猫应用图标](app/assets/brand/README.md)。

本地优先的时间与薪资感知工具，面向 Windows、macOS、iOS 和 Android。`workspace/shiyu` 是独立仓库，上级 `workspace` 仅容纳不同项目，不共享 Git 或依赖。

## 当前功能

桌面浮窗和移动首页显示 Rust 计算的内置指标，桌面还支持自定义倒计时。Android 和 iOS 的主屏幕小组件提供倒计时与薪资两种类型。应用支持本地设置备份、损坏恢复和六地区离线节假日。[项目记录](docs/项目记录/README.md)记录当前实现和验证状态。

| 功能 | 当前行为 |
| --- | --- |
| 退休倒计时 | 用户选择退休日期与 IANA 时区；Rust 统一返回日历剩余天数和秒数，到期显示“已退休”，未配置时不填充虚构日期 |
| 生命指标 | 手机在「设置 → 倒计时」、桌面在「完整设置 → 个人信息」填写出生日期，并选择「静待百岁，好好生活」或「已存在世界」。天数从出生当天的 0 开始，按设置时区的日历日增加 |
| 逐项标题显隐 | 桌面在「完整设置 → 悬浮窗」，手机在「设置 → 逐项显示标题」。各项独立控制并保留数值，桌面自定义倒计时也可单独设置。原有浮窗与小组件的标题总开关仍可使用 |
| 桌面浮窗 | Windows/macOS 无边框、置顶，倒计时可合并或拆分。各窗可独立拖动、缩放、隐藏窗口或标题。整窗配色有马卡龙、马卡龙玻璃、冷酷、日落暖调。玻璃色板使用半透明渐变和亮边，可叠加背景透明度设置。托盘/菜单栏提供设置、显示和退出，Ctrl/Cmd+Shift+T 可收起或恢复已开启的浮窗 |
| 桌面三态 | 迷你、标准、展开共用真实 Rust 快照。双击在迷你与标准间切换，设置可选展开。支持六类内置指标、自定义倒计时、排序和显隐。在「倒计时」页可单独显示或隐藏「今日已赚」和生命指标。展开态显示可用进度与日期，金额遮蔽同步 |
| 桌面系统入口 | 托盘或菜单栏可显隐、锁定或解除点击穿透、隐藏金额、暂停、检查节假日更新和退出。支持工作区吸附、显示器位置恢复、全屏覆盖开关、金额快捷键和登录时启动。macOS 登录项需要 13 或以上 |
| 桌面皮肤与猫猫素材 | 简约卡片、深色科技两套皮肤，支持浅色、深色和跟随系统，背景不透明度 30%–100%、三档数字字号和强调色。支持本地替换 PNG、导入导出和打开 `.timerpack`。[制作与安装指南](docs/界面设计/04-用户资源制作指南.md) |
| 移动首页与设置 | 首页逐秒重算活动倒计时和计薪中的金额，右上角可手动刷新。窄屏和大字号切为单列。分类设置可直达倒计时、作息与薪资、日期与假期、逐项显示标题、小组件或通用。作息时间支持点选，分类表单统一从底部保存 |
| 首次引导与完整设置 | 首次安装按个人信息、作息与薪资、真实快照三步引导。支持发薪规则、日期覆盖、假期、八种语言和本地 JSON 导入导出。桌面完整设置自动保存，还可编辑自定义倒计时与迷你窗指标偏好 |
| 本地设置与组件共享 | 桌面应用数据目录、Android 私有文件、iOS App Group。设置保存前校验并支持旧版迁移和备份恢复。移动端将已校验节假日按地区原子同步给原生组件，回退配置时遮蔽金额 |
| 刷新 | 活跃倒计时在整秒更新。全局隐藏或关闭全部浮窗时暂停桌面刷新，也可从「倒计时」设置手动暂停。再次显示或恢复时按当前系统时间重算 |
| Android 主屏幕小组件 | 点击倒计时组件可选择 1 至 4 项，将作息、放假、发薪、退休或生命合并在一张卡片上。薪资卡内猫猫下方可刷新今日和本月已赚，遵循金额遮蔽。组件经 UniFFI 独立调用 Rust |
| iOS 主屏幕小组件 | WidgetKit 小、中尺寸支持倒计时与薪资。iOS 17+ 可编辑通用倒计时组件，在主指标后追加最多三项；薪资组件可手动刷新。iOS 15 和 16 使用固定布局，薪资可从应用首页手动刷新。扩展通过 App Group 和 UniFFI 独立计算，待 Mac 实测 |
| 计算核心 | Rust 快照包含生命、上下班、薪资、发薪、放假、退休及自定义倒计时。支持固定时间复算、批量时间线和内存中的倒计时配置变更 |
| 薪资与隐私 | 税前或税后月薪按当月应出勤日和实际工作时段计算。金额以十进制字符串向下截断，隐藏时快照只返回遮蔽值 |
| 核心契约与日历 | 版本化 JSON、字段校验、显式 now/IANA 时区、个人日期覆盖/自定义假期/地区日期覆盖/工作周优先级；缺节假日数据时明确回退 |
| 六地区节假日 | 内置中国大陆、美国、日本、韩国、中国香港和中国台湾 2026–2027 年数据。设置可检查更新和导入地区 JSON，缺数据时按工作周计算。[数据来源与格式](docs/决策记录/0003-节假日来源与更新.md) |
| 应用语言 | 在手机设置首页或桌面「设置 → 外观」选择跟随系统、简体中文、繁体中文、英语、日语、韩语、西班牙语、德语或法语。移动应用、完整设置、真实指标和桌面设置导航随之切换。部分桌面细项仍为中文，原生小组件提供中文和英文 |

在手机设置的「主屏幕小组件」可添加组件并调整配色、标题和字号。Android 和 iOS 16 及以上使用系统计时控件更新活动倒计时的秒数，目标与到期状态由系统调度刷新。Android 若延迟刷新，系统计时器在到期后可能短暂显示负值。薪资组件以约一分钟为目标请求重算。见[节点 12 验收](docs/验收记录/12/README.md)。

## 验证状态

Windows 11 Release 和 Android API 36 x86_64 模拟器已有运行记录。macOS 有早期运行反馈，当前版本的 Apple 构建与原生行为待复核。节点 13 继续验证多屏、真机、性能和长稳，节点 14 负责正式签名与分发。[当前项目现状](docs/项目记录/README.md) · [节点 13 验收](docs/验收记录/13/README.md)

## 运行与构建

从仓库根目录 `shiyu/` 开始。应用版本为 `0.1.0+1`，应用标识为 `com.growthrecord.shiyu`。运行目标为 Windows、macOS、Android 和 iOS。

### 共同准备

安装 Flutter **3.47.2**（自带 Dart **3.13.2**）、Git 和 Rustup，将 Flutter 与 Rust 工具加入 PATH。安装目标平台 SDK 后执行下面的命令。首次获取依赖需要网络，常规运行使用仓库已提交的生成绑定。

```sh
flutter doctor -v
rustup toolchain install 1.95.0 --profile minimal --component clippy --component rustfmt
cd app
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format lib/l10n/generated
flutter devices
```

以下平台命令均在 `app/` 执行。`DEVICE_ID` 替换为 `flutter devices` 列出的设备 ID。同一工作树的各平台构建请顺序执行。

### Windows

在 Windows 上安装 Visual Studio 的「使用 C++ 的桌面开发」工作负载及 Windows SDK。[Flutter Windows 环境](https://docs.flutter.dev/platform-integration/windows/setup)

```powershell
flutter run -d windows
# 结束调试实例后构建并启动 Release
flutter build windows --release
.\build\windows\x64\runner\Release\shiyu.exe
```

x64 Release 的 EXE、DLL 和 `data/` 位于同一目录，复制时保留整个目录。切换版本前在系统托盘右键「时余 → 退出」。关闭窗口可能只隐藏旧实例，Windows 会把新版启动请求转给仍在运行的实例。

### macOS

在 Mac 上安装 Xcode 和命令行工具，完成 Xcode 首次启动配置。安装 CocoaPods 以解析仍使用 podspec 的插件。应用部署目标为 macOS 12，登录启动要求 macOS 13 或以上。[Flutter macOS 环境](https://docs.flutter.dev/platform-integration/macos/setup) · [原生插件依赖说明](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)

```sh
flutter run -d macos
flutter build macos --release
open build/macos/Build/Products/Release/shiyu.app
```

浮窗隐藏后可从菜单栏恢复。本地 Release 用于开发验证，正式签名与公证跟随[发布节点](docs/开发计划/14-签名打包与发布验收.md)。

### Android

安装 Android Studio 或 Android SDK 工具。仓库 CI 使用 JDK 21、Android SDK Platform 36 和 NDK **28.2.13676358**。另需 Platform-Tools、命令行工具及 SDK 许可，可用 `flutter doctor --android-licenses` 完成许可配置。设备最低为 API 24。启动模拟器或连接已开启 USB 调试的真机。[Flutter Android 环境](https://docs.flutter.dev/platform-integration/android/setup)

```sh
flutter devices
flutter run -d DEVICE_ID

# x86_64 模拟器的 Release APK
flutter build apk --release --target-platform android-x64
adb -s DEVICE_ID install -r build/app/outputs/flutter-apk/app-release.apk
```

ARM64 真机或模拟器用 `flutter build apk --release --target-platform android-arm64`。两条单架构命令输出同名 `app-release.apk`，需要保留两份时先复制并分别命名。当前 Release 使用调试密钥签名，可用于开发安装。应用内保存配置后，从「设置 → 主屏幕小组件」或系统启动器添加倒计时和薪资组件。

### iOS

使用 Mac、Xcode、iOS 模拟器运行时及 CocoaPods。部署目标为 iOS 15。先在 Xcode 中启动模拟器。真机需启用开发者模式，`Runner` 与 `ShiyuWidgets` 使用同一个有 App Group 能力的开发团队。[Flutter iOS 环境](https://docs.flutter.dev/platform-integration/ios/setup) · [本项目 Apple 签名与验收](native/ios/README.md)

```sh
flutter devices
flutter run -d DEVICE_ID
flutter build ios --simulator --debug
```

模拟器构建输出为 `build/ios/iphonesimulator/Runner.app`。需要用 Xcode 配签名时，执行 `flutter build ios --config-only --no-codesign` 准备配置并打开 `ios/Runner.xcworkspace`。Runner 自动构建和嵌入扩展。应用内保存设置后，从 iOS 主屏幕组件图库添加时余。iOS 16+ 支持系统计时文字，iOS 17+ 支持编辑通用倒计时组件。

### 检查与排障

- 在仓库根目录用 PowerShell 7 执行 `pwsh -File scripts/check.ps1`。Windows 加 `-BuildWindows` 可包含 Release 构建。Mac 执行 `bash scripts/check_apple.sh` 可验证 Swift 调用 Rust，并构建 macOS Release 和 iOS 模拟器 Debug。
- 在 `app/` 执行 `flutter test integration_test/retirement_test.dart -d DEVICE_ID` 可测试真实绑定和设置流程。Windows 用 `windows`，macOS 用 `macos`，手机使用实际设备 ID。
- 找不到设备时检查模拟器或真机连接，再运行 `flutter doctor -v` 与 `flutter devices`。Android 下载失败时核对错误中的依赖仓库和 Gradle 代理，离线构建依赖完整缓存。小组件读不到设置时，检查系统是否已添加、应用是否保存成功，并在 iOS 核对签名与 App Group。[排障索引](docs/项目记录/技术架构与验证.md#构建与验证)

## 代码与文档

```text
workspace/
├── shiyu/                # 本独立仓库
│   ├── app/              # Flutter 应用及各平台宿主
│   ├── core/             # 内部 Rust workspace：engine / Flutter 桥 / UniFFI
│   ├── native/ios/       # UniFFI Swift 绑定及主机校验
│   ├── doc/              # 原始需求和技术文档
│   ├── docs/             # 逐节点计划、契约、决策及验收记录
│   └── scripts/          # 构建、绑定生成、检查
└── <其他独立仓库>/
```

业务计算只在 Rust 中实现，各视图负责呈现。应用无账号、遥测或个人配置上传，联网仅下载公开节假日数据。提交作者与提交者统一为 `star <1395723441@qq.com>`。

- [逐节点开发计划与检查清单](docs/开发计划/README.md)
- [数据契约 v1](docs/技术说明/数据契约-v1.md)
- [项目基础信息](doc/桌面悬浮计时器/项目基础信息.md)
- [M0 历史验收](docs/验收记录/01/README.md)
