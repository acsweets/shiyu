# 时余 · shiyu

> 桌面猫猫贴纸支持合并、拆分倒计时浮窗。每个浮窗上沿贴着不同姿态的猫猫，各窗可独立移动、缩放和隐藏标题。主窗有设置入口，隐藏后可从托盘打开设置。关闭示例预览可查看真实业务指标。详见[桌面浮窗分组](docs/界面设计/06-桌面浮窗分组.md)。

[简体中文](README.md) | [English](README.en.md)

独立桌面设置窗提供外观、窗口管理、倒计时和猫猫素材四页，支持实时预览和撤销窗口移动。见[桌面设置设计](docs/界面设计/07-桌面设置设计.md)。

Windows、macOS、Android 和 iOS 使用统一的[橘猫应用图标](app/assets/brand/README.md)。

本地优先的时间与薪资感知工具，面向 Windows、macOS、iOS 和 Android。`workspace/shiyu` 是独立仓库，上级 `workspace` 仅容纳不同项目，不共享 Git 或依赖。

## 当前功能

桌面浮窗与手机主屏幕小组件可显示退休倒计时，Rust 提供六类内置指标和自定义倒计时。应用支持本地设置备份、损坏恢复和六地区离线节假日。[项目记录](docs/项目记录/README.md)保存用户确认的设计与功能基线。

| 功能 | 当前行为 |
| --- | --- |
| 退休倒计时 | 用户选择退休日期与 IANA 时区；Rust 统一返回日历剩余天数和秒数，到期显示“已退休”，未配置时不填充虚构日期 |
| 桌面浮窗 | Windows/macOS 无边框、置顶，倒计时可合并或拆分。各窗可独立拖动、缩放、隐藏窗口或标题。设置提供提示文字大小和马卡龙、冷酷、日落暖调三套整窗配色。托盘/菜单栏提供设置、显示和退出，Ctrl/Cmd+Shift+T 可收起或恢复已开启的浮窗 |
| 桌面三态 | 迷你、标准、展开共用真实 Rust 快照。双击在迷你与标准间切换，设置可选展开。支持六类内置指标、自定义倒计时、排序和显隐。展开态显示可用进度与日期，金额遮蔽同步 |
| 桌面系统入口 | 托盘或菜单栏可显隐、锁定或解除点击穿透、隐藏金额、暂停、检查节假日更新和退出。支持工作区吸附、显示器位置恢复、全屏覆盖开关、金额快捷键和登录时启动。macOS 登录项需要 13 或以上 |
| 桌面皮肤与猫猫素材 | 简约卡片、深色科技两套皮肤，支持浅色、深色和跟随系统，背景不透明度 30%–100%、三档数字字号和强调色。支持本地替换 PNG、导入导出和打开 `.timerpack`。[制作与安装指南](docs/界面设计/04-用户资源制作指南.md) |
| 手机设置 | 打开时余直接配置退休日期和时区。小组件外观提供三套整卡配色、标题显隐和标题字号 |
| 首次引导与完整设置 | 首次安装按个人信息、作息与薪资、真实快照三步引导。支持发薪规则、日期覆盖、假期、八种语言、自动保存和本地 JSON 导入导出。桌面还可编辑自定义倒计时与迷你窗指标偏好 |
| 本地设置 | 桌面应用数据目录、Android 私有文件、iOS App Group。保存前校验，支持旧版迁移和显式恢复上次有效备份，恢复前归档损坏文件 |
| 刷新 | 活跃倒计时在整秒更新。全局隐藏或关闭全部浮窗时暂停桌面刷新，也可从「倒计时」设置手动暂停。再次显示或恢复时按当前系统时间重算 |
| Android 主屏幕小组件 | 橘猫贴在卡片上沿，标题下方一行显示完整退休倒计时。点击组件打开设置。组件经 UniFFI 调 Rust，无需运行 Flutter |
| iOS 主屏幕小组件 | WidgetKit 小/中尺寸猫猫退休倒计时，从 App Group 读取配置并独立调用 Rust。待用户在 Mac 实测 |
| 计算核心 | Rust 快照包含生命、上下班、薪资、发薪、放假、退休及自定义倒计时。支持固定时间复算、批量时间线和内存中的倒计时配置变更 |
| 薪资与隐私 | 税前或税后月薪按当月应出勤日和实际工作时段计算。金额以十进制字符串向下截断，隐藏时快照只返回遮蔽值 |
| 核心契约与日历 | 版本化 JSON、字段校验、显式 now/IANA 时区、个人日期覆盖/自定义假期/地区日期覆盖/工作周优先级；缺节假日数据时明确回退 |
| 六地区节假日 | 内置中国大陆、美国、日本、韩国、中国香港和中国台湾 2026–2027 年数据。设置可检查更新和导入地区 JSON，缺数据时按工作周计算。[数据来源与格式](docs/决策记录/0003-节假日来源与更新.md) |
| 国际化与验证入口 | 移动端沿用八语言 ARB；本次桌面试用界面暂为中文，原生小工具提供中文/英文。`lib/main_probe.dart` 保留独立工程探测 |

手机倒计时显示在系统主屏幕小组件上。Android 显示最近一次计算的天和时分秒，设置更新会触发刷新，常规刷新由系统调度。iOS 通过 WidgetKit 时间线更新，在 iOS 16 及以上可由系统文字计时器显示最后一天的剩余时间。

节点 01 的 Windows/Android 运行已通过，用户已反馈 Mac 验证就绪。本节点 Windows/Android 的命令、结果及待验收项见 [02 验收记录](docs/验收记录/02/README.md)。iOS Widget 的编译、签名及运行由用户在 Mac 复核，不能以 Windows 静态检查替代。

## 尚未完成

- 将六类内置指标和薪资接入移动首页。
- 多屏、全屏及 Apple 原生行为的手工复核见[节点 09 记录](docs/验收记录/09/README.md)和[节点 10 记录](docs/验收记录/10/README.md)。
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

Mac 上运行 `flutter run -d macos`。iOS 小工具构建、签名和添加步骤见 [Apple 说明](native/ios/README.md)。手机打开时余后设置退休日期。Android 可在设置中请求添加小组件，或从启动器的组件列表添加。iOS 在主屏幕编辑模式中添加。详见[手机主屏幕小组件与设置](docs/界面设计/08-手机浮窗与设置.md)。

在仓库根目录执行 `./scripts/check.ps1 -BuildWindows`，检查 Flutter 格式/分析/测试、Windows Release 及 Rust fmt/clippy/test。节点 02–04 原生通道集成测试：

```powershell
cd app
flutter test integration_test/retirement_test.dart -d windows
flutter test integration_test/retirement_test.dart -d emulator-5554
flutter test integration_test/salary_timeline_test.dart -d emulator-5554
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

业务计算只在 Rust 中实现，各视图负责呈现。应用无账号、遥测或个人配置上传，联网仅下载公开节假日数据。提交作者与提交者统一为 `star <1395723441@qq.com>`。

- [节点 02 计划与用户检查清单](docs/开发计划/02-数据契约与基础日历.md)
- [数据契约 v1](docs/技术说明/数据契约-v1.md)
- [项目基础信息](doc/桌面悬浮计时器/项目基础信息.md)
- [M0 历史验收](docs/验收记录/01/README.md)
