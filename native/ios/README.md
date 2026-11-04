# Apple 平台原生探测

`Generated/` 由锁定的 UniFFI 0.32.2 生成，禁止手工修改。`Smoke/main.swift` 使用该绑定调用 `shiyu_core` 的探测接口，不包含业务或个人数据。

## 在 Mac 上复核

安装仓库指定的 Flutter 3.47.2、Rust 1.95.0、Xcode（含命令行工具）、CocoaPods 与 Python 3。然后在仓库根目录执行：

```bash
bash scripts/check_apple.sh
cd app
flutter test integration_test/bridge_test.dart -d macos
flutter test integration_test/desktop_window_test.dart -d macos
flutter devices
flutter test integration_test/bridge_test.dart -d <iOS模拟器ID>
flutter run -d macos -t lib/main_probe.dart
```

脚本先编译并执行 Swift → UniFFI → Rust 的主机探测，再构建 macOS Release 与 iOS 模拟器 Debug。macOS/iOS Flutter 应用由 `rust_builder` 自动编译和打包 Rust，普通启动会先初始化真实动态/静态绑定。

需要重新生成时，在 Mac 的 PowerShell 7 中执行 `./scripts/generate_bindings.ps1 -InstallTools`；不需要生成即可先用已提交的绑定运行验证。模拟器无需真机分发证书；iOS 真机仍需配置自己的签名团队。

## 检查 TODO

- [ ] Swift 主机探测输出 `Swift -> UniFFI -> shiyu_core: PASS`。
- [ ] macOS/iOS 构建成功，Flutter 原生集成测试通过，界面正常显示。
- [ ] Mac 探测程序可置顶、拖动、切换无边框，从菜单栏恢复窗口；Cmd+Shift+T 显示/隐藏。
- [ ] 点击穿透后约三秒自动恢复；手工检查透明效果与实际窗口交互。
- [ ] 分别记录系统、架构、Xcode、设备和运行命令；将结果回填节点 01 验收记录。

这些步骤尚未在 Windows 上执行，Apple 平台状态为待用户验证。这里没有创建 iOS Widget Extension target；正式原生小组件与共享容器仍按节点 11/12 实现，不能将 Swift 主机探测视为 WidgetKit 验收通过。
