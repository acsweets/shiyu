# Apple 平台运行与小组件验收

本文适用于当前节点 13 工作树。macOS 有早期运行反馈，当前原生功能和 iOS 组件需要在 Mac 重新验证。Windows 与 Android 的运行结果见[平台验收记录](../../docs/验收记录/13/README.md)。

## 工具链与运行

在 Mac 准备 Flutter 3.47.2、Rustup 与 Rust 1.95.0、Xcode 与命令行工具、CocoaPods、Python 3。Xcode 中安装 iOS 平台和对应模拟器。常规构建使用已提交的 Swift UniFFI 绑定。完整准备命令见[仓库运行指南](../../README.md#运行与构建)。

从仓库根目录执行检查脚本，可运行 Swift → UniFFI → Rust 主机探测及固定退休、薪资和时间线样例，再构建 macOS Release 与 iOS 模拟器 Debug。

```sh
bash scripts/check_apple.sh
cd app
flutter test integration_test/bridge_test.dart -d macos
flutter test integration_test/retirement_test.dart -d macos
flutter run -d macos
```

iOS 在 Xcode 启动模拟器后，从 `app/` 执行以下命令。`DEVICE_ID` 使用 `flutter devices` 的输出。

```sh
flutter devices
flutter run -d DEVICE_ID
flutter test integration_test/retirement_test.dart -d DEVICE_ID
```

如果旧检出生成的 Pods 仍报 iOS 13.0 部署目标错误，更新仓库后从 `app/` 运行 `flutter pub get` 和 `(cd ios && pod install)`，再启动模拟器构建。Podfile 会将低于 15.0 的 iOS Pods 目标提升到 15.0。

如需用 Xcode 构建或为真机设置签名，从 `app/` 准备 Flutter 配置并打开工作区。

```sh
flutter build ios --config-only --no-codesign
open ios/Runner.xcworkspace
```

## iOS 扩展与签名

1. 在工作区选择 Runner 工程。Runner 已依赖 `ShiyuWidgets`，并在 Embed App Extensions 阶段嵌入扩展。选择 Runner scheme，再选择设备或模拟器。
2. 真机签名时，在 Runner 与 ShiyuWidgets 的 Signing & Capabilities 选择同一开发团队，注册对应 Bundle ID，并启用同一 App Group。应用标识为 `com.growthrecord.shiyu`，扩展标识为 `com.growthrecord.shiyu.widgets`。
3. 默认组为 `group.com.growthrecord.shiyu`。使用另一个团队且需要换组名时，同步修改 [Runner entitlement](../../app/ios/Runner/Runner.entitlements)、[扩展 entitlement](../../app/ios/ShiyuWidgets/ShiyuWidgets.entitlements) 和 [SharedWidgetStore.group](../../app/ios/Shared/SharedWidgetStore.swift)。模拟器也要实测共享容器可访问。
4. 扩展构建阶段通过 [build_widget_core.sh](../../scripts/build_widget_core.sh) 编译 `shiyu_ffi` 静态库。目标覆盖 iPhone arm64、Apple Silicon 模拟器 arm64 和 Intel 模拟器 x86_64。首次构建需要可访问 Rust targets 和 crates 下载源。
5. 启动应用后保存测试配置。随后返回主屏幕，长按进入编辑，打开系统组件图库并添加时余的倒计时和薪资小组件。

如修改 Rust 导出 API，可在 PowerShell 7 中从仓库根目录运行 `./scripts/generate_bindings.ps1 -InstallTools` 生成绑定。[原生插件依赖说明](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)

## 验收项

- [ ] Mac 主机探测打印 Swift 桥接、退休及薪资时间线通过。模拟器构建可检查 `app/build/ios/iphonesimulator/Runner.app/PlugIns/ShiyuWidgets.appex`。
- [ ] macOS 主窗正常恢复原布局，支持置顶、拖动缩放、三态、菜单栏恢复/退出与 Cmd+Shift+T。检查多显示器、全屏空间及 macOS 13+ 登录启动。
- [ ] iOS 首页按秒更新活动计时。配置合成出生、退休、时区与薪资数据，保存和重启后可读取。
- [ ] iOS 主屏幕可添加小、中尺寸倒计时和薪资组件。验证两项合并薪资卡与今日、本月单项卡。iOS 15 验证时间线快照，iOS 16+ 验证活动目标的计时文字，iOS 17+ 验证通用组件混排、单项中尺寸布局和卡内刷新。iOS 15 和 16 从应用首页手动刷新薪资。
- [ ] 切换「静待百岁，好好生活」与「已存在世界」，检查标题、纯天数行、独立标题开关和金额遮蔽。检查背景配色和字号，核对组件卡面。
- [ ] 记录系统、CPU、Xcode、设备类型、命令及实测结果，回填[节点 13 验收](../../docs/验收记录/13/README.md)。正式分发签名和公证另见[节点 14](../../docs/开发计划/14-签名打包与发布验收.md)。
