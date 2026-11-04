# 时余 Flutter 应用

此目录为 Flutter 工程根目录；Git 根目录在上一级 `shiyu/`。环境、检查命令、需求入口与架构说明见[仓库说明](../README.md)。

```powershell
flutter pub get
flutter gen-l10n
flutter run -d windows
```

应用入口为 `lib/main.dart`，根组件为 `lib/app/shiyu_app.dart`。业务功能按领域放在 `lib/features/`；计算规则由 `../core/` 的 Rust 核心实现。
