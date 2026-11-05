# 时余 Flutter 应用

桌面端可以按倒计时合并或拆分浮窗、独立拖动和缩放、按窗口隐藏标题。示例预览可关闭以显示真实退休数据。详见[浮窗分组](../docs/界面设计/06-桌面浮窗分组.md)。

[简体中文](README.md) | [English](README.en.md)

Flutter 根目录是本目录；独立 Git 根目录为上级 `shiyu/`。

当前提供真实退休倒计时、退休日期/时区设置与本地原子保存、Windows/macOS 浮窗及托盘/快捷键入口、Android 原生退休小工具，以及已接入 Xcode 的 iOS Widget 扩展。前台按秒显示，小工具显示日历剩余天数；薪资和其他指标仍待后续节点。本节点 Apple 新代码待用户在 Mac 实测。

```powershell
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format lib/l10n/generated
flutter run -d windows
```

移动端使用 `flutter devices` 返回的 ID。Android 在应用内添加小工具；iOS 按 [Apple 指南](../native/ios/README.md) 配置同组签名并添加小工具。

功能边界、工具链和检查命令见[中文仓库说明](../README.md)；验收步骤见[节点 02](../docs/验收记录/02/README.md)。入口为 `lib/main.dart`，退休功能位于 `lib/features/retirement/`，计算规则在 Rust `../core/`。
