# 节点 02 验收记录

日期：2026-11-04；实现版本以本报告所属 Git 提交为准。基线为 af16376。第二用户检查点：桌面浮窗与 Android/iOS 小工具运行。此节点提供退休倒计时切片，用户验收项见 [节点文档](../../开发计划/02-数据契约与基础日历.md)。

## 实测与状态

| 环境 | 检查 | 结果 |
| --- | --- | --- |
| Windows 11 x64 / VS 2022 | retirement_test.dart | 通过：真实 FRB、原子保存、非法时区拒绝、置顶/360 宽度/防关闭读回 |
| Android 16/API 36 x86_64 模拟器 | retirement_test.dart | 通过：真实 FRB/UniFFI 完整 JSON 一致性、原子保存及无效输入保护；1 项集成测试约 5 秒 |
| Rust 1.95.0 / Windows | fmt、clippy、workspace test | 通过；8 项契约/日历/退休测试及 1 项原探测测试 |
| iOS 工程静态核对 / Windows | OpenStep PBX、plist、两 target 三配置 entitlement、源文件引用 | 通过；不代表 Xcode 编译或 WidgetKit 运行通过 |
| macOS 上个节点 | 用户反馈 Mac 验证就绪 | 用户报告，详细设备/系统日志未提供；本节点新代码仍待复核 |
| 新 macOS 浮窗 / iOS Widget | 真实编译、签名、系统宿主运行 | 待用户按 Apple 指南在 Mac 执行 |

最终检查已通过：`scripts/check.ps1 -BuildWindows`（Flutter 格式/分析、4 项测试、Windows Release、Rust fmt/clippy、9 项测试）；普通 Android x64 APK 构建/安装、ELF 校验通过。APK 为 `app/build/app/outputs/flutter-apk/app-debug.apk`，Windows 为 `app/build/windows/x64/runner/Release/shiyu.exe`，均为本地忽略产物，不作为签名发布包。

Android 系统宿主实测：从应用 pin 请求添加 widget；UI 选择合成日期 2050-01-01 后，组件显示 **8,459 days left / Asia/Shanghai**。返回主屏幕后 `am kill com.growthrecord.shiyu`，PID 27477 消失；点击组件 Refresh 后新进程 PID 27930 成功刷新，未启动 Activity。读取该进程 maps 并与本次 APK ZIP 数据偏移比对：Rust `libshiyu_bridge.so`（0x34f8000）已映射，Flutter `libflutter.so`（0x628000）未映射，证明不依赖 Flutter 引擎。之后点击组件打开 App、清除合成日期，确认组件恢复待设置，保留桌面组件供用户检查。

[Android 小工具实测截图](android-widget-synthetic.png) 使用合成日期，截图拍于主应用退出后的 widget 冷启动验证；测试后已清除日期。

Windows 普通 Release 启动显示无边框浮窗，展开配置页正常，关闭按钮隐藏且进程保留；Ctrl+Shift+T 能隐藏，再从模拟器窗口触发全局快捷键恢复；ShowWindowAsync 完成后重新截图确认可见。标题拖动已提供原生调用，但注入拖动未得到窗口位移证据，实际鼠标拖动仍保留用户复核。

## 2026-11-05 手机界面重设计

- `scripts/check.ps1` 通过。Flutter 的 7 项测试覆盖英文 320 × 480 大字号设置页和手机时区保存，Rust 的 9 项测试通过。
- Android 16 x86_64 模拟器 `emulator-5554` 安装调试 APK，包内 Rust ELF 校验通过。通过中文日期选择器保存测试日期，确认设置显示年份、首页显示完整单行倒计时且每秒变化。验证拖动、三套色卡、标题显隐、字号、位置重置，强制停止后复核外观与隐藏状态，从齿轮恢复浮窗。
- 从设置触发 Android 启动器的小组件添加确认，验证后取消确认并清除临时日期。iOS 运行、横屏及真机验收仍待复核。

## 可重复命令

```powershell
# 仓库根目录
./scripts/check.ps1 -BuildWindows
cd app
flutter test integration_test/retirement_test.dart -d windows
flutter test integration_test/retirement_test.dart -d emulator-5554
flutter build apk --debug --target-platform android-x64
```

Android 本机使用 `GRADLE_USER_HOME=C:/Users/19814/.gradle-shiyu`，为本项目进程隔离全局缓存/代理配置；Gradle 进程使用 GRADLE_OPTS 传入本机 127.0.0.1:7890 代理，Flutter 设置 NO_PROXY=localhost,127.0.0.1。不要把 Flutter 的本地 VM service 连接代理出去；配置不写入仓库。AVD 为 Medium_Phone_API_36.1，Android 16/API 36 x86_64，非硬件真机。

集成测试使用合成 2050-01-01，移动端在 finally 恢复原日期/时区；Windows 使用临时目录。没有真实薪资/生日数据。普通启动不虚构用户退休日期。

## 已修复问题

- Windows 插件 setSkipTaskbar 前未调用 waitUntilReadyToShow 导致任务栏 COM 指针为空、原生崩溃；现先初始化就绪状态，Windows 原生集成重跑通过。
- Windows 嵌套构建调用本地化生成器的 dart format 子进程出现完成输出后挂起；关闭生成器嵌套格式化，检查脚本显式单独运行格式化，不修改全局 Dart/Flutter。
- iOS Runner Release entitlement 遗漏已修正，Project 级误配移除；所有 Runner/widget 配置指向各自 entitlement。扩展嵌入阶段前移，防止与 Flutter 打包脚本形成循环依赖。
- Jiff 默认本地时间解析会容错调整；现显式 unambiguous 拒绝重叠/不存在的午夜，Pacific/Apia 跳日样例验证通过。

## 用户验收与限制

- [ ] 用户复核 Windows/macOS 浮窗拖动、置顶、展开/隐藏/恢复、实际快捷键。
- [ ] 用户复核 Android 桌面小工具与设置联动。
- [ ] 用户在 Mac 构建新代码并完成 iOS App Group/WidgetKit 系统宿主验证。
- [ ] 第二检查点通过后再进入节点 03。

本节点仅退休日历天数 widget。Android 系统周期不短于 30 分钟，支持手动/配置刷新；iOS Timeline 刷新由系统控制。没有薪资 widget、四指标完整 widget 或后台秒级刷新承诺。坏设置文件保持只读；用户修复入口、版本迁移/备份仍在节点 05。
