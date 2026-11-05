# 时余 · shiyu

> 桌面猫猫贴纸支持合并、拆分倒计时浮窗。每个浮窗的上沿贴着一只不同姿态的猫猫，同窗的倒计时共用一只。各窗可独立移动、缩放和隐藏标题，并在设置里控制显隐。设置图标只在主窗显示，主窗隐藏后可从托盘打开设置。关闭效果预览后显示真实退休倒计时。详见[桌面浮窗分组](docs/界面设计/06-桌面浮窗分组.md)。

[简体中文](README.md) | [English](README.en.md)

独立桌面设置窗提供外观、窗口管理、倒计时和猫猫素材四页，支持实时预览和撤销窗口移动。见[桌面设置设计](docs/界面设计/07-桌面设置设计.md)。

Windows、macOS、Android 和 iOS 使用统一的[橘猫应用图标](app/assets/brand/README.md)。

本地优先的时间与薪资感知工具，面向 Windows、macOS、iOS 和 Android。`workspace/shiyu` 是独立仓库，上级 `workspace` 仅容纳不同项目，不共享 Git 或依赖。

## 当前功能

目前开发至节点 02，提供**退休倒计时的可运行切片**，尚未完成全部 MVP。

| 功能 | 当前行为 |
| --- | --- |
| 退休倒计时 | 用户选择退休日期与 IANA 时区；Rust 统一返回日历剩余天数和秒数，到期显示“已退休”，未配置时不填充虚构日期 |
| 桌面浮窗 | Windows/macOS 无边框、置顶，倒计时可合并或拆分。各窗可独立拖动、缩放、隐藏窗口或标题。设置提供提示文字大小和马卡龙、冷酷、日落暖调三套整窗配色。托盘/菜单栏提供设置、显示和退出，Ctrl/Cmd+Shift+T 可收起或恢复已开启的浮窗 |
| 手机浮窗与设置 | Android/iOS 首页可拖动猫猫倒计时浮窗，标题下方一行显示完整倒计时。白底设置支持退休日期与时区、三套色卡、浮窗和标题显隐、标题字号、位置重置以及主屏幕小组件入口。前台每秒刷新，浮窗外观与位置重启后保留 |
| 本地设置 | 桌面应用数据目录、Android 私有文件、iOS App Group；先校验再原子保存，重启读取，坏文件不自动覆盖 |
| Android 原生小工具 | 从桌面添加退休倒计时，直接经 UniFFI 调 Rust；显示剩余天数、时区和更新时间，点击刷新，点击卡片打开应用；不启动 Flutter 引擎 |
| iOS 原生小工具 | 已接好独立 WidgetKit target、App Group、Rust 静态库构建与嵌入；支持小/中尺寸退休倒计时，时间线由系统调度；本节点新增内容待用户在 Mac 实测 |
| 核心契约与日历 | 版本化 JSON、字段校验、显式 now/IANA 时区、个人日期覆盖/自定义假期/地区日期覆盖/工作周优先级；缺节假日数据时明确回退 |
| 国际化与验证入口 | 移动端沿用八语言 ARB；本次桌面试用界面暂为中文，原生小工具提供中文/英文。`lib/main_probe.dart` 保留独立工程探测 |

小工具本节点仅显示**退休剩余天数**，不承诺后台秒级刷新。Android 周期刷新为系统约束下的 30 分钟，并支持手动刷新及设置更新；iOS 按 Rust 返回的下一日历边界申请时间线刷新，实际执行由系统决定。应用内浮窗把剩余秒数显示为完整的天与时分秒，小组件显示日历剩余天数。两者使用同一退休目标和时区。

节点 01 的 Windows/Android 运行已通过，用户已反馈 Mac 验证就绪。本节点 Windows/Android 的命令、结果及待验收项见 [02 验收记录](docs/验收记录/02/README.md)。iOS Widget 的编译、签名及运行由用户在 Mac 复核，不能以 Windows 静态检查替代。

## 尚未完成

- 生命、上下班、今日/本月薪资、发薪日、下次放假计算与完整设置。
- 桌面自定义倒计时，完整三态/指标开关排序、吸边、穿透、多屏与全屏策略、两套皮肤和资源包。
- 六地区内置节假日数据及更新、导入导出、迁移/备份/恢复、完整首次引导。
- 四类倒计时及薪资小组件、Android 真机和 Apple 本节点实测、性能与长稳、签名发布。

这些仍按 [逐节点开发计划](docs/开发计划/README.md) 推进，退休切片提前接入浮窗/共享容器不代表节点 08–12 全部完成。冻结范围见 [MVP 1.0](doc/桌面悬浮计时器/需求/MVP-冻结需求-1.0.md)。

## 运行与检查

工具链：Flutter **3.47.2** / Dart **3.13.2**、Rust **1.95.0**，锁文件提交到仓库。iOS 最低 15、macOS 最低 12、Android 最低 API 24；应用标识 `com.growthrecord.shiyu`，开发版本 `0.1.0+1`。

```powershell
cd app
flutter pub get --enforce-lockfile
flutter gen-l10n
dart format lib/l10n/generated
flutter run -d windows
# Android 用 flutter devices 查到的设备 ID
flutter run -d emulator-5554
```

Mac 上运行 `flutter run -d macos`。iOS 小工具构建、签名和添加步骤见 [Apple 说明](native/ios/README.md)。手机首次使用时，点右上角齿轮设置退休日期。Android 可在设置的「主屏幕小组件」分组点“添加桌面小组件”，也可从启动器的组件列表添加“时余 · 退休倒计时”。详见[手机浮窗与设置](docs/界面设计/08-手机浮窗与设置.md)。

在仓库根目录执行 `./scripts/check.ps1 -BuildWindows`，检查 Flutter 格式/分析/测试、Windows Release 及 Rust fmt/clippy/test。节点 02 真机通道测试：

```powershell
cd app
flutter test integration_test/retirement_test.dart -d windows
flutter test integration_test/retirement_test.dart -d emulator-5554
```

测试使用合成日期，结束时恢复移动端原配置；桌面使用临时目录。不要同时运行同一 Flutter 工程的不同平台构建。Windows 本机嵌套格式化进程曾挂起，现由检查脚本显式格式化本地化生成代码。Android 可用独立短路径 `GRADLE_USER_HOME` 隔离本机代理或长路径问题，勿改全局环境。CI 执行 Windows/Android 构建与检查，远程状态以 Actions 为准。

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

业务计算只在 Rust 中实现，各视图负责呈现。当前无账号、遥测或个人配置上传，退休功能不发起网络请求。提交作者与提交者统一为 `star <1395723441@qq.com>`。

- [节点 02 计划与用户检查清单](docs/开发计划/02-数据契约与基础日历.md)
- [数据契约 v1](docs/技术说明/数据契约-v1.md)
- [项目基础信息](doc/桌面悬浮计时器/项目基础信息.md)
- [M0 历史验收](docs/验收记录/01/README.md)
