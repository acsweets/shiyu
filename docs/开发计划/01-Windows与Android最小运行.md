# 节点 01：Windows 与 Android 最小运行

[计划总览](README.md) · [平台与绑定决策](../决策记录/0001-M0平台与绑定.md) · [验收记录](../验收记录/01/README.md)

- 状态：已完成（按用户调整的 Windows/Android 运行范围；Apple 待用户验证）
- 范围：当前首个 M0 运行里程碑，不等同于原始四平台 G0 全量风险通过。
- 前置：[00 工程初始化基线](00-工程初始化基线.md) 已完成。
- 下一节点：[02 数据契约与基础日历](02-数据契约与基础日历.md)。

## 目标与进入条件

按用户 2026-11-04 的调整，以当前 Windows 平台和 Android 实际构建、运行成功为首个里程碑。macOS/iOS 提供源码与复核方式，用户后续在 Mac 自行验证；等待 Apple 实测不阻断当前平台继续开发。

## 开发 TODO

- [x] 固定 Flutter 3.47.2、Dart 3.13.2、Rust 1.95.0、FRB 2.12.0 与 UniFFI 0.32.2。
- [x] 建立纯 Rust 探测函数、FRB 适配器和 UniFFI 门面，二者复用同一 engine。
- [x] 普通应用启动初始化真实 Rust 绑定；保留可重复生成的 Dart/Kotlin/Swift 源码。
- [x] 通过 Windows Release 构建及 Flutter → Rust 真实集成测试。
- [x] 通过 Android x86_64 模拟器构建/安装/运行及 Flutter、Kotlin 两条真实 Rust 调用。
- [x] 提供独立桌面探测入口：无边框/透明背景、置顶、拖动、短暂穿透、托盘恢复、显示隐藏快捷键。
- [x] 增加真实桌面系统调用测试及有界显示状态等待；视觉效果与实际键鼠操作保留用户复核。
- [x] 提供 Android debug 专用原生探测 widget 源码，不作为正式计时组件交付。
- [x] 提供 Apple 构建适配、Swift 主机探测及 Mac 验证脚本；iOS/macOS 最低版本分别为 15.0/12.0。
- [x] 增加 Rust 单元测试检查、Windows/Android CI 构建配置及 APK 内 Rust 库检查。
- [x] 普通启动 APK 的最终打包检查及验收记录归档。

## 你需要检查的点

- [ ] 在 Windows 的 app/ 下执行 `flutter run -d windows`，普通初始化首页能显示。
- [ ] 在 Android 模拟器执行 `flutter run -d <设备ID>`，或运行集成测试，确认无动态库加载异常。
- [ ] 执行独立入口 `flutter run -d windows -t lib/main_probe.dart`，点击探测应返回 `shiyu-core:42`。
- [ ] 在独立入口检查拖动、置顶、透明效果、穿透三秒恢复、Ctrl+Shift+T 和托盘恢复/退出。
- [ ] 需要试用 Android debug 探测 widget 时，从系统组件列表添加“时余 M0 Rust 探测”；独立 widget 冷启动未作为本里程碑通过条件。
- [ ] 在 Mac 按 [Apple 说明](../../native/ios/README.md) 执行构建、Swift/Flutter 探测和实际键鼠验证，将环境与结果回填验收记录。

## 开发者验证 TODO

- [x] Windows Release 构建成功。
- [x] Windows 真实 FRB 测试通过，覆盖 41、0、u32 最大值。
- [x] Windows 桌面探测系统调用测试通过：置顶读回、隐藏/恢复可见、穿透设置/解除、托盘和快捷键注册/释放。
- [x] Android 16 / API 36 / x86_64 模拟器真实 FRB + Kotlin/UniFFI 测试通过。
- [x] Flutter 格式、静态分析、两项启动测试、Rust fmt/clippy/test 通过。
- [x] FRB、Kotlin、Swift 生成脚本实际执行成功。
- [x] 普通 APK ELF 与 ABI 检查通过。
- [ ] Apple 实际构建/运行：由用户后续在 Mac 执行，保持待验证。

## 交付物

- Windows Release、已在模拟器运行的 Android x86_64 debug APK，以及构建/ABI 检查通过的 ARM64 debug 手机测试包（尚未真机验证）。
- 独立探测入口、原生绑定生成器、平台检查脚本及 [验收记录](../验收记录/01/README.md)。
- [Apple 验证移交](../../native/ios/README.md)、[工具链决策](../决策记录/0001-M0平台与绑定.md)。

## 完成条件与下一步

Windows 与 Android 实际启动及真实 Rust 调用通过，普通产物打包验证通过，Apple 代码/说明已提交且待验证状态明确后，本里程碑完成。进入节点 02 实现正式数据契约与基础日历。

## 风险与边界

尚未实现六类指标、薪资、设置持久化和最终悬浮窗。Android 真机/其他 ABI、macOS/iOS 以及原生 widget 冷启动没有本机通过结论。

原 M0 的时间模型决策移到 02、节假日来源许可移到 06、完整窗口/全屏策略移到 09、正式原生小组件与共享数据移到 11/12。后续发布仍需要全部冻结平台证据；本次用户调整不删除冻结需求。

## 验收记录

以 [01 验收报告](../验收记录/01/README.md) 的命令、环境、结果与产物为准。用户检查项未预先勾选。
