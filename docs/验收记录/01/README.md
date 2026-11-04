# 节点 01 验收报告

日期：2026-11-04。实现版本以本报告所属 Git 提交为准。

结论：按用户调整的首个里程碑范围，Windows 与 Android 已实际构建并运行真实 Rust 集成测试。macOS/iOS 代码和验证流程已提供，由用户后续在 Mac 验证，保持未实测状态。

## 平台矩阵

| 平台 / 环境 | 构建 | 实际运行 | 验证边界 |
| --- | --- | --- | --- |
| Windows 11 / x64 / VS 2022 | Release 通过 | 两项真实原生集成测试通过 | 非 Windows 10 验收；视觉、拖动、实际快捷键和穿透操作待用户复核 |
| Android 16 / API 36 / x86_64 | debug APK 通过 | 模拟器安装与集成测试通过 | AVD 为 Medium_Phone_API_36.1；不代表硬件真机通过 |
| Android ARM64 | debug 分 ABI APK 与 ELF 校验通过 | 未连接硬件设备 | 不预报真机通过 |
| macOS 12+ | 构建适配与脚本已提供 | 待用户在 Mac 验证 | 含 Swift 主机探测和桌面探测入口 |
| iOS 15+ | 构建适配与脚本已提供 | 待用户在 Mac 验证 | 提供模拟器构建流程；真机需用户签名团队 |

## 实际执行并通过的检查

| 命令（默认在 app/） | 结果 |
| --- | --- |
| 仓库根目录 `./scripts/check.ps1 -BuildWindows` | 格式检查、Flutter analyze、2 项启动测试、Windows Release、Rust fmt/clippy/test 通过 |
| `flutter test integration_test/bridge_test.dart -d windows` | 1 项真实集成测试通过，普通应用入口启动后调用打包 Rust 库 |
| `flutter test integration_test/desktop_window_test.dart -d windows` | 1 项真实系统调用测试通过 |
| `flutter test integration_test/bridge_test.dart -d emulator-5554` | 1 项真实集成测试通过，含 Kotlin/UniFFI 调用；安装耗时日志约 2 秒，测试约 3 秒 |
| `flutter build apk --debug --target-platform android-x64` | 普通入口 debug APK 构建通过 |
| `python ../scripts/verify_android_package.py build/app/outputs/flutter-apk/app-debug.apk` | ELF 小端、x86_64 ABI 和 Rust 库存在检查通过；库大小 1565216 字节 |
| `flutter build apk --debug --target-platform android-arm64 --split-per-abi` | ARM64 debug 包构建通过 |
| `python ../scripts/verify_android_package.py build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk --abi arm64-v8a` | ARM64 ELF/ABI 校验通过；Rust 库大小 1493192 字节 |
| 仓库根目录 `./scripts/generate_bindings.ps1` | FRB、Kotlin 和 Swift 生成成功 |

Rust workspace 当前有 1 项探测边界单元测试；其余 crate 暂无业务测试。2 项 Flutter 启动测试不加载真实原生库，真实绑定结果以上述 integration_test 为准。

### 绑定返回值

| 输入 | 期望与测试通过值 |
| --- | --- |
| 41 | `shiyu-core:42` |
| 0 | `shiyu-core:1` |
| 4294967295 | `shiyu-core:0` |
| Android Kotlin 调试通道传入 41 | `shiyu-core:42` |

没有用 Dart/Swift/Kotlin 重新实现这个探测结果；调用均转到同一个 `shiyu_core`。该接口只证明运行链路，尚无计时/薪资业务。

### 桌面验证的含义

自动测试完成窗口插件初始化、托盘/快捷键注册与释放、无边框/背景设置、置顶状态读回、隐藏状态读回、恢复可见以及穿透设置/解除。测试没有模拟真实鼠标穿过窗口或实际按系统快捷键；这些手工效果仍在节点 01 用户检查清单中。

Android 的普通应用 `main()` 已由真实模拟器集成测试启动；最终普通 APK 另外完成构建与包内 ELF 校验，未额外进行手工安装复测。debug 原生 widget 有源码，但尚未完成 widget host 独立冷启动实测。无截图或录像作为本次通过依据，不将它们伪列为已交付证据。

## 产物

以下是本地生成路径，不纳入源码仓库；Windows 必须保留完整 Release 目录中的 DLL 和 data，不能只复制 exe。

- Windows：`app/build/windows/x64/runner/Release/shiyu.exe` 与同目录 `shiyu_bridge.dll`、插件 DLL、data。
- Android 模拟器：`app/build/app/outputs/flutter-apk/app-debug.apk`，x86_64 debug。
- Android ARM64 手机测试包：`app/build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk`；硬件运行状态仍为未验证。
- 产物大小与 SHA-256 见 [artifact-hashes.json](artifact-hashes.json)，用于核对当前本地构建，重新构建后哈希可能变化。
- CI 配置包含 Windows 构建及 Android x86_64 APK/Rust 库检查；新的远程运行结果见 Actions，不以本机结果代替 CI 状态。

## 本机环境修复与复现

全局 Gradle 代理为 127.0.0.1:7891，实际可用端口为 7890。本次使用独立短目录 `C:/Users/19814/.gradle-shiyu` 作为 GRADLE_USER_HOME，在其中设置本机代理；没有改动全局 `.gradle/gradle.properties`。仓库路径下的过长 Gradle 缓存曾使 Kotlin DSL 无法读取依赖；短缓存路径解决此问题。

当前机器复现时可在仓库根目录运行：

```powershell
./scripts/check_m0.ps1 -AndroidDeviceId emulator-5554 -GradleUserHome C:/Users/19814/.gradle-shiyu
```

其他机器按自己的网络和缓存路径配置，不能照搬本机代理。本机部分其他 Android SDK 许可证的 doctor 警告不代表本次使用的 API 36 构建失败；本次构建与运行结果已单独验证。

Rust 数字工具链识别、Gradle 9 ExecOperations、SDK/NDK 和批处理失败返回码的适配见 [构建补丁说明](../../../app/rust_builder/SHIYU_PATCHES.md)。增加包内库检查，是因为打包产物存在本身不能证明 Rust 库已经随包交付。

## Apple 移交与后续

- [ ] 用户在 Mac 按 [Apple 验证说明](../../../native/ios/README.md) 执行 Swift 探测、macOS/iOS 构建与真实 FRB 测试。
- [ ] 用户复核 Mac 菜单栏、Cmd+Shift+T、窗口透明与穿透，记录设备、系统、架构及 Xcode 版本。
- [ ] 后续补齐 Android 物理设备、其他 ABI/系统版本、Windows 10 等测试矩阵。

下一开发节点为 [02 数据契约与基础日历](../../开发计划/02-数据契约与基础日历.md)。完整悬浮窗、节假日、六指标和正式小组件仍按后续计划实现；本报告不授予产品发布通过结论。

## 后续用户反馈（2026-11-04）

用户反馈“mac 已验证就绪”，未提供系统/CPU/Xcode 与详细日志，记录为用户报告通过，不补写开发者实测。节点 02 的新增 macOS 浮窗和 iOS Widget 仍需按新检查点复核。
