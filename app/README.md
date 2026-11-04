# 时余 Flutter 应用

[简体中文](README.md) | [English](README.en.md)

此目录为 Flutter 工程根目录；Git 根目录在上一级 `shiyu/`。环境、检查命令、需求入口与架构说明见[仓库说明](../README.md)。

## 当前功能

- 初始化首页：显示应用名称、标语、沙漏图标与开发状态。
- 首页跟随系统语言，支持简中、繁中、英语、日语、韩语、西语、德语和法语；未支持的语言回退为简中，暂无应用内语言切换入口。
- 页面适配可用宽度，支持滚动、安全区域和系统字体缩放。
- 普通启动加载真实 Rust 库；Flutter/FRB 和 Android Kotlin/UniFFI 探测通过。独立验证入口为 `lib/main_probe.dart`。

当前尚无业务计时、薪资计算、最终悬浮窗、设置持久化或正式手机小组件。完整清单见[仓库功能说明](../README.md#当前功能)。Windows Release 与原生集成测试、Android x86_64 模拟器实际运行已通过；Apple 平台待用户在 Mac 验证，步骤见 [Apple 说明](../native/ios/README.md)。

## 运行

```powershell
flutter pub get
flutter gen-l10n
flutter run -d windows
```

应用入口为 `lib/main.dart`，根组件为 `lib/app/shiyu_app.dart`。业务功能按领域放在 `lib/features/`；计算规则由 `../core/` 的 Rust 核心实现。
