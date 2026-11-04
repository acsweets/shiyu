# 时余 · shiyu

[简体中文](README.md) | [English](README.en.md)

本地优先的时间与薪资感知工具，面向 Windows、macOS、iOS 和 Android。

## 仓库边界

`workspace` 是多个独立仓库的容器，不是 Git 仓库，也不是 Dart/Cargo workspace。当前 Git 根目录为 `workspace/shiyu`，origin 为 `https://github.com/acsweets/shiyu.git`。后续项目与 `shiyu` 同级，各自维护 Git、依赖与构建配置。

```text
workspace/
├── shiyu/                     # 当前独立仓库
│   ├── app/                   # Flutter 四平台应用，package: shiyu
│   │   ├── lib/app/           # 应用装配、主题与路由
│   │   ├── lib/features/      # 按功能组织的 UI 与状态
│   │   └── lib/l10n/          # 八种语言的 ARB 和生成结果
│   ├── core/                  # 项目内部 Rust workspace
│   │   └── crates/engine/     # shiyu_core 纯计算核心
│   ├── doc/                   # 已有产品与技术文档
│   ├── scripts/               # 项目级检查脚本
│   └── .github/workflows/     # CI
└── <其他项目>/                # 各自独立的仓库
```

## 环境与运行

初始化使用 Flutter **3.47.2 stable** / Dart **3.13.2**、Rust **1.95.0**。CI 固定相同版本；提交应用 `pubspec.lock` 和 Rust `Cargo.lock`。Apple/Android 主应用标识为 `com.growthrecord.shiyu`，当前开发版本为 `0.1.0+1`，产品目标为 MVP 1.0。

从仓库根目录运行：

```powershell
cd app
flutter pub get
flutter gen-l10n
flutter run -d windows
```

Android 使用 `flutter devices` 查到的设备 ID；macOS 在 Mac 上使用 `flutter run -d macos`；iOS 需要 Mac、Xcode 与模拟器/签名条件。模板当前 iOS 最低版本为 15.0，macOS 为 12.0；Android 最低版本沿用固定 Flutter SDK 的默认值。Windows 产品目标为 Windows 10+，仍需在目标系统验证。

## 检查与约定

在仓库根目录运行 `./scripts/check.ps1`，执行本地化生成、格式检查、静态分析、启动冒烟测试和 Rust 检查。添加 `-BuildWindows` 可验证 Windows release 构建。CI 包含同样检查及 Windows 构建；其他平台 CI 与真机验收后续补齐。

2026-11-04 在当前 Windows 机器执行 `./scripts/check.ps1 -BuildWindows` 通过：格式检查、Flutter 静态分析、两项启动测试、Windows release 构建、Rust fmt/clippy。Android 构建未验证：本机许可证未全部接受，Google Maven 网络检查异常；iOS/macOS 需在 Mac 上验证。GitHub CI 配置已纳入仓库，远程运行结果以 Actions 为准。

Flutter 按功能分域，Dart 变量使用显式类型、函数类型通过 typedef 命名；超过三行的匿名回调提取为具名函数。手写代码注释使用中文，成员变量与核心方法添加用途注释。生成的原生模板和绑定通过工具维护。

## 初始化范围

已建立四平台工程、Riverpod 根容器、ARB 国际化和响应式初始化页。Rust crate 仅建立边界，尚无计算实现。Flutter 与 Rust 尚未链接；后续按冻结计划引入 flutter_rust_bridge、UniFFI、jiff、rust_decimal 和设置存储。

当前启动页不是最终悬浮窗。透明/置顶/穿透、托盘、个人设置、节假日数据、六类指标和原生小组件均未实现，不代表 M0 风险验证或 MVP 已完成。初始化页只显示开发状态，不填充虚构薪资或倒计时。

本次初始化未设置账号、遥测或联网请求业务。薪资与个人设置不上传的原则需在后续实现中持续遵守。

## 需求入口

- [项目基础信息](doc/桌面悬浮计时器/项目基础信息.md)
- [MVP 冻结需求 1.0](doc/桌面悬浮计时器/需求/MVP-冻结需求-1.0.md)
- [开发步骤、排期与测试验证](doc/桌面悬浮计时器/需求/最终开发步骤-排期-测试验证.md)

冻结需求优先于历史方案。开发计划中结构示例的 `workspace/` 在当前工程中对应本仓库 `shiyu/`，不对应外层多仓库容器。
