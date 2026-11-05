# Apple 平台运行与 Widget 验收

节点 01 的 Mac 验证已由用户反馈就绪（未提供详细设备/系统日志）。以下为**节点 02 新增浮窗与 iOS Widget**的复核步骤，尚未在当前 Windows 环境编译或运行。

## 准备与构建

Mac 安装 Flutter 3.47.2、Rust 1.95.0、Xcode/命令行工具、Python 3。项目已接入 `ShiyuWidgets` target、Runner 依赖与 Embed App Extensions；不需要手动创建 Widget target。Swift 绑定由 UniFFI 0.32.2 生成，不手工修改。

```bash
bash scripts/check_apple.sh
cd app
flutter test integration_test/bridge_test.dart -d macos
flutter test integration_test/retirement_test.dart -d macos
flutter run -d macos
```

`check_apple.sh` 先执行 Swift→UniFFI→Rust 主机探测及固定退休样例，再构建 macOS Release 和 iOS 模拟器 Debug。Widget target 的首个构建阶段运行 `scripts/build_widget_core.sh`，为当前 SDK/架构编译纯 UniFFI 静态库；支持 iPhone arm64、Apple Silicon 模拟器 arm64、Intel 模拟器 x86_64。首次编译需能访问 Rust crates/target 下载源。扩展不链接 Flutter 引擎。

需要更新绑定时在 Mac PowerShell 7 执行 `./scripts/generate_bindings.ps1 -InstallTools`；常规运行使用已提交的生成结果即可。

## iOS 签名与启动

1. 用 Xcode 打开 `app/ios/Runner.xcworkspace`，选择其中 Runner 工程；Flutter 插件由生成的 Swift package 接入。
2. Runner 和 ShiyuWidgets 选择同一开发者 Team。两者的 App Groups entitlement 均为 `group.com.growthrecord.shiyu`。真机需要开发者账号注册并为两者启用同一 App Group。若更改 bundle/group，须同时修改两个 entitlement 和 `SharedWidgetStore.group`，不能只改 Runner。
3. 选择 Runner scheme 和模拟器/设备构建运行；依赖会自动构建、嵌入 ShiyuWidgets.appex。模拟器不需要分发证书；若环境缺 Team，先验证模拟器构建并检查 App Group 容器实际可访问。
4. 在 App 内选择合成测试退休日期（如 2050-01-01）、保存 Asia/Shanghai。共享容器不可用会提示错误，不会回退到扩展看不到的私有目录。
5. 返回手机主屏幕，长按→添加小组件→时余，选择小/中尺寸。iOS 不允许 App 自动把 widget 固定到桌面，时余的设置页提供手动添加说明。

```bash
cd app
flutter devices
flutter test integration_test/retirement_test.dart -d <iOS模拟器ID>
flutter run -d <iOS模拟器ID>
```

## 本节点用户检查 TODO

- [ ] `check_apple.sh` 通过，包含 `Swift retirement contract: PASS`，Runner 内确实嵌入 ShiyuWidgets.appex。
- [ ] macOS 新浮窗显示真实退休天数和秒数；标题区拖动、置顶、展开/收起、关闭隐藏、菜单栏恢复/退出、Cmd+Shift+T 均可用。
- [ ] 日期/时区保存并重启后保留；非法时区被拒绝；到期显示“已退休”，清除日期显示待设置。
- [ ] iOS 主屏幕能添加小/中尺寸 widget，读取 App 保存的同一日期和时区；更改设置后请求刷新，无假日期。
- [ ] 退出主应用后 widget 仍能独立计算；重新进入 App 时配置保持一致。系统可延后 timeline，不要求秒级刷新。
- [ ] 点击 widget 打开应用；主屏幕背景与文字不裁切，深/浅色、字体大小和 iPhone/iPad 布局复核。
- [ ] 记录 macOS/iOS 版本、CPU、Xcode、模拟器/真机型号、命令结果与截图，回填 [02 验收记录](../../docs/验收记录/02/README.md)。

本节点小组件显示橘猫贴纸与退休倒计时，外观从 App Group 读取。其余三类倒计时和薪资小组件留在节点 12。完整移动功能仍归节点 11/12。不要将本节点静态配置检查或用户上次 Mac 验证视为新 Widget 已实测通过。
