# 节点 13 全平台回归与长稳记录

基线为节点 12 的 `f17de06`。2026-11-06 实测，节点 13 仍在验证。[节点计划](../../开发计划/13-全平台回归与性能稳定性.md)

## 冻结验收映射

| 冻结条目 | 已执行或可复现的证据 | 待补 |
| --- | --- | --- |
| 1 默认迷你五项 | 默认 Rust 设置、窗口指标选择及 Flutter 三态测试 | 干净 Windows 和 macOS 的首次启动画面 |
| 2 开关、排序和重启 | 节点 07 设置持久化、节点 08 真实视图与分组 | macOS 手工重启 |
| 3 自定义倒计时 | Rust 与 FRB 的创建、编辑、删除、校验和时间线；Windows 集成 | 桌面用户逐项复核 |
| 4 到期不为负 | Rust 黄金样例、FRB 与 Kotlin 的固定时钟跨秒对照 | Swift 对照 |
| 5 薪资口径与隐私 | Rust/FRB/Kotlin 计算精度、损坏共享设置回退遮蔽、Android 原生桌面截图 | Apple 各界面遮蔽及锁屏复核 |
| 6 桌面三态一致 | Flutter 共享快照测试及 Windows 实际模式尺寸 | macOS 实际尺寸 |
| 7 拖动、吸附、穿透、多屏与快捷键 | 节点 09 Windows 原生行为、快捷键冲突、混合 DPI 和断屏模拟 | 125%/200% 实屏、真实多屏和 macOS |
| 8 发薪规则 | Rust `time_metrics_tests` 的固定日期与三种调整结果 | 用户固定配置复算 |
| 9 假期合并与降级 | Rust 黄金、节点 06 实际日历、Android 与 FRB 同日历完整快照对照 | Apple App Group 与离线复核 |
| 10 两桌面一致 | 两平台同用 Rust；有可重复运行的 Swift UniFFI 探针 | Mac 上执行并与 Windows 对照 |
| 11 移动应用与小组件 | Android API 36 启动器与两种尺寸，完整见节点 11、12 | Android 真机/最低 API、iOS 最低/当前和组件 |
| 12 离线与无上传 | Rust 周工作日回退、离线日历缓存用例、Android 断网冷启及业务网络调用检查 | 全平台实际抓包和低版本断网复核 |
| 13 性能和恢复 | Windows Release 与 Android 模拟器初测、核心 Release 分位数 | 真实 7 天、Apple 和 Android 真机性能、休眠与多屏矩阵 |

## 核心性能

Windows 11 x64 Build 26200，Intel Core i9-14900HX，32 个逻辑处理器。Release 单线程在固定时区和固定 now 下执行完整 JSON 计算和序列化，每组预热 1,000 次，测量 10,000 次。单位为微秒。

| 输入 | 平均 | p50 | p95 | p99 |
| --- | ---: | ---: | ---: | ---: |
| 默认配置 | 6.23 | 6.00 | 7.00 | 10.20 |
| 全内置指标与已校验中国大陆两年日历 | 32.68 | 31.60 | 42.70 | 66.70 |
| 全内置指标及 20 个自定义倒计时 | 46.30 | 44.20 | 63.20 | 109.70 |

三组 p99 在这台机器上均低于 1 ms。Rust workspace Release 的 16 项测试通过。

## 应用性能初测

| 平台与取样方式 | 实测 | 目标 |
| --- | --- | --- |
| Windows 11 x64，隔离 Release 启动至首帧与窗口可见 | 2,156 ms | <2,000 ms |
| 同一 Windows 进程，60 秒、每 5 秒读一次工作集 | 平均 201.81 MiB，峰值 221.82 MiB | <120 MB |
| 同一 Windows 进程，累计 CPU 时间 | 整机平均 0.383%，单核等效 12.262% | 整机平均 <1% |
| Android API 36 x86_64，关闭 Wi-Fi 与移动数据后冷启 3 次 | 3,672 / 1,762 / 1,606 ms | <1,500 ms |
| Android 同次前台采样，`dumpsys meminfo` | PSS 84.70 MiB，RSS 171.91 MiB | <80 MB |
| Android 同次前台采样，`top` 五个非首样本 | 单核等效平均 1.1% | 平均 <2% |

两台 Release 初测均成功启动。Android 在恢复网络前回到应用前台，系统显示 `LaunchState: COLD`。模拟器冷启动和内存初测超目标，需在真机复测。Windows 工作集初测超目标。短测过程中主机还有并行的构建和测试任务，后续复测应保持主机空闲。

Windows 曾试用 280 × 172 逻辑像素的初始绘制面，测得冷启动 1,844 ms、工作集平均 198.16 MiB、峰值 216.21 MiB。该版本在恢复已保存的高窗布局时出现画面拉伸，已撤回此优化，恢复 1280 × 720 的初始绘制面。修复后的性能待复测。

移动端将原生组件同步移到 Flutter 首帧以后。相同模拟器的第二轮断网冷启为 2,909 / 2,000 / 7,662 ms，PSS 85.32 MiB、RSS 172.07 MiB，五个非首 CPU 样本平均 0.3%。两轮结果波动较大，仍未达到冷启与内存目标。

代码审计在应用业务路径只找到节假日更新的固定 HTTPS GET。请求不发送地区、配置、金额或请求体，并且关闭自动重定向。该项证据为静态审计与离线运行，平台抓包和长期日志审计待补。

## 原生回归

Windows 回归发现连续切换形态时，异步返回的旧原生尺寸可能覆盖新尺寸。修复后 100 次迷你与标准切换均匹配窗口实际宽度，既有的 100 次显隐和 100 次换肤也通过。损坏主设置用合法副本只读恢复时，Rust 快照强制遮蔽两项金额，原文件保留。

Windows 11 Release 恢复同一份 420 × 537 物理像素的主窗布局时，小初始绘制面版本的画面被纵向拉伸，顶部的猫猫和主倒计时被裁切。恢复原初始绘制面后，未重置用户布局，冷启动确认猫猫、设置入口和两项计时完整可见。完整检查与 Windows Release 构建通过。

最终 Windows Release 构建、仓库格式和静态分析、22 项 Flutter 测试、16 项 Rust Debug 测试及 Windows 原生集成通过。Android x86_64 和 ARM64 Release APK 均已构建并检查 Rust 库的 ELF ABI。x86_64 在模拟器安装升级后，Pixel Launcher 保留两个已添加组件。ARM64 仍待真机安装。

启动预览时，在 Android x86_64 Release 复现了两处设置保存问题。R8 移除了 JNA 通过反射读取的 UniFFI 结构体。原生桥接重新序列化 JSON 后，连续保存会被误判为外部修改。补齐保留规则，保存通过校验的原始 JSON，并为应用备份使用独立于 AtomicFile 的文件名。修复后在 API 36 模拟器连续两次保存均显示成功，主屏幕的倒计时和薪资组件仍可查看。本轮修复后的 ARM64 APK 待重建。

## 语言设置回归

Android API 36 模拟器已安装并启动 x86_64 Release，在设置首页展开语言选择，确认包含跟随系统和八种语言。Flutter 测试覆盖手机切换日语、持久化并恢复跟随系统，以及桌面切换英语后设置导航刷新。Windows Release 构建通过。macOS 和 iOS 的语言入口待实机复核。

## 标题和生命指标回归

Windows Release 构建与完整检查通过。24 项 Flutter 测试包含合并窗口单独隐藏一项标题，以及手机切换生命模式、保存设置并保留天数文案。17 项 Rust 测试包含闰日、设置时区的午夜边界、未填生日和默认倒计时兼容。

Android API 36 模拟器已安装 x86_64 Release，确认完整设置中有两种生命模式与七项独立标题开关，已有主屏幕小组件的编辑菜单可选择生命指标。小组件实显、跨端及 Apple 实机复核仍待完成。

## Windows 设置窗标题栏

旧版在鼠标移开时看不到关闭图标。修复后使用 Windows 原生标题栏配色，设置内容仍为白底。Windows 11 浅色主题下在隔离 Release 实例确认关闭图标默认可见，点击后设置窗收起，主浮窗仍在。完整检查与常规 Windows Release 构建通过。

## 今日已赚显隐

Windows Release 已启动，确认「设置 → 倒计时 → 启用倒计时」显示「今日已赚」开关。Flutter 回归覆盖关闭、重新开启、与完整设置共用启用项，以及迷你、标准、展开模式只移除该指标。完整检查通过。macOS 实机与应用重启后的显隐状态待复核。

## 生命指标显隐

「设置 → 倒计时 → 启用倒计时」新增生命倒计时开关，生命倒计时和已度过天数共用同一显隐值。Flutter 回归覆盖开关往返、示例浮窗、两种生命值及三种桌面形态保留其余指标。完整检查与 Windows Release 构建通过，macOS 实机待复核。

中文倒计时模式更名为「静待百岁，好好生活」。Windows Release 用原布局启动后，确认天数模式上方显示「已存在世界」，下方只显示数值和单位。Flutter 回归覆盖新名称、模式切换及隐藏标题后的独立天数。Android x86_64 Release 已在 API 36 模拟器安装启动，包内确认含新版小组件文案。Apple 平台待实机复核。

## 移动设置流程与倒计时

Android API 36 模拟器实测。旧设置同时提供退休快捷表单和完整设置，作息与标题需要先进入完整设置，手动保存和自动保存混用。新版首页按任务进入单页，分类表单统一保存，作息时间用选择器。实际提交无效时区后保留草稿并标记字段，放弃草稿后重新打开仍是原时区。小组件的添加与外观在同一页。

旧退休小组件在相隔 4 秒的两张截图中只有更新时间变化。新版在应用退到后台时从 `845 天 11:35:51` 递减至 `845 天 11:35:46`，既有组件实例可直接使用。Flutter 回归覆盖新目标从低频切回整秒、保存与放弃、大字号设置导航和切换生命显示。Android 系统延迟调度时可能晚更新到期状态，须复核临界值和省电场景。iOS 系统计时分支待实机验证。

## 马卡龙玻璃色板

Windows Release 构建与完整检查通过。Flutter 测试验证设置预览使用半透明渐变，四张色卡等宽，皮肤包可以保存、重读并恢复新配色。Android API 36 模拟器选中马卡龙玻璃，已有主屏幕小组件即时显示渐变、亮边和透出的壁纸。macOS 与 iOS 实机待核对。

## 小组件卡面

Android API 36 模拟器升级后，主屏幕倒计时卡片显示标题和数值，底部没有相对更新时间，两张截图中的剩余时间从 13:37 走到 13:31。Android 倒计时和薪资共用简化后的布局，完整检查与 Release 构建通过。iOS 卡片已同步调整，待实机核对。

## 小组件组合与薪资刷新

Android API 36 x86_64 Release 安装升级后，旧实例保留原布局。进入现有倒计时组件，勾选作息、放假、退休、生命后保存，四项在同一张卡片显示，第五项在选满时不可再选。使用计薪样例在启动器点击宽薪资卡内、猫猫正下方的按钮，今日与本月金额立即更新，应用保持在后台。应用首页也实测金额随计薪时间变化。紧凑薪资卡为两行金额预留高度，最小尺寸的启动器实显待复核。

完整检查通过，Flutter 回归覆盖只有薪资变化时的整秒刷新，以及点击首页按钮后立即重算并请求更新小组件。iOS 17+ 已接入 App Intents 的多项配置与卡内刷新按钮，待在 Mac 构建并运行验证。iOS 15 和 16 沿用预设倒计时布局，手动刷新入口在应用首页。

## 复现与 7 天采样

```powershell
./scripts/check.ps1 -BuildWindows
cd core
cargo bench -p shiyu_core --bench compute_snapshot --locked
cargo test --workspace --release --locked
cd ../app
flutter test integration_test/retirement_test.dart -d windows --no-pub
flutter build apk --release --target-platform android-x64
flutter build apk --release --split-per-abi --target-platform android-arm64
```

Android Release 构建保留 Flutter 的依赖准备。紧接 Debug 集成测试使用 `--no-pub` 可能留下仅 Debug 使用的插件注册表。

桌面可用节点 13 的隔离 Release 入口测量真实首帧和驻留内存。构建到独立工作区，避免替换运行中的正式安装。短测示例从仓库根目录开始。

```powershell
cd app
flutter build windows --release --target=tool/desktop_verification.dart
cd ..
$sample = Join-Path $env:TEMP ('shiyu-sample-' + [guid]::NewGuid().ToString('N'))
python -B scripts/verify_desktop_process.py --executable ./app/build/windows/x64/runner/Release/shiyu.exe --output $sample --seconds 60 --interval 5
```

macOS 对应命令为 `flutter build macos --release --target=tool/desktop_verification.dart`，可执行文件在 `app/build/macos/Build/Products/Release/shiyu.app/Contents/MacOS/shiyu`。Apple 功能复核用 `bash scripts/check_apple.sh`，并使用实际设备和 App Group 验证组件。iOS 无签名 Release 检查可执行 `flutter build ios --release --no-codesign`。

长稳针对同一 Release 版本和同一进程。可将隔离验证脚本的 `--seconds` 设为 `604800` 且 `--interval` 设为 `60`，也可对已经运行的 Release 使用以下采样方式。

```text
python -B scripts/sample_desktop.py --pid PID --seconds 604800 --interval 60 --output /path/to/samples.jsonl
```

保留两平台的 JSONL 开始记录、逐次样本、结束摘要及退出或睡眠事件。CPU 同时报告整机逻辑核和单核两种比例。采样以单调时钟计算持续时间，记录采样间隔和提前退出。复核真实跨过 7 天、内存趋势、异常退出后设置恢复，并分别完成 10 次休眠唤醒及跨时区、多屏、锁屏用例。短测结果单独记入本页。
