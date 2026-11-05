# 节点 05 本地存储与运行时调度验收

日期 2026-11-05。前置版本为节点 04 的 `b99decd`，实现版本以本报告所属 Git 提交为准。[节点计划](../../开发计划/05-本地存储与运行时调度.md)

## 设置保存与恢复

- 配置通过 Rust 校验后原子替换。桌面使用当前用户的应用支持目录，Windows 继承该目录的访问控制，macOS 本地文件写入前设为 `0600`。移动主配置沿用 Android 私有存储与 iOS App Group。
- 备份在应用支持目录 `shiyu/settings.json.bak`。首次成功保存时尝试创建备份，之后保存前备份原先的合法配置。显式版本 0 迁移前也保留旧文件。
- 如果主配置损坏且备份有效，应用会只读打开备份。在桌面设置的「倒计时」页或手机退休设置中选择「恢复设置备份」，先另存为 `settings.json.damaged` 再恢复主文件。过大或无读取权限的文件需先解决文件访问问题。未来版本保持原件和只读状态。
- 保存异常测试使用合成数据。测试在原子替换前注入失败，复核当前合法配置和备份仍可加载。实际断电与磁盘未落盘场景未测。

## 刷新复核

1. 关闭示例数据，配置一个未来退休日期。打开桌面「倒计时」设置并开启「暂停刷新」。
2. 等待两分钟后关闭暂停。浮窗立即显示按当前系统时间计算的剩余时间。
3. 用 Ctrl/Cmd+Shift+T 隐藏再显示浮窗，或在设置中关闭全部浮窗再开启一个。隐藏期间停止定时刷新，显示后重新计算。
4. 在实机锁屏、睡眠或修改系统时间与时区后检查恢复。业务时区仍使用所选 IANA 时区，系统变化触发重新读取当前时刻。

## 平台证据

| 环境 | 验证 |
| --- | --- |
| Windows 11 x64，构建 26200 | `scripts/check.ps1 -BuildWindows` 隔离构建。Flutter 静态分析、11 项 Flutter 测试和 16 项 Rust 测试通过，成功生成 Release Runner。可控时钟覆盖整秒、跨日、暂停、隐藏、暂停期间时间跳变和释放 |
| Windows 11 x64，构建 26200 | 退休集成测试使用隔离 Debug Runner 运行通过，检查真实 FRB、合法保存、非法输入及主窗显隐 |
| Android 16 x86_64，`emulator-5554` | 退休集成测试构建、安装和运行通过。验证合法保存、拒绝非法时区、真实 FRB 计算与 Kotlin UniFFI 快照一致 |
| macOS / iOS | macOS Runner 接入系统通知，iOS 采用 Flutter 前后台事件。编译、运行和权限检查待用户在 Mac 复核 |

整机锁屏、睡眠和修改系统时钟的实测待单独复核。测试覆盖应用收到生命周期信号后的调度行为。

```powershell
./scripts/check.ps1 -BuildWindows
cd app
flutter test integration_test/retirement_test.dart -d windows --no-pub
flutter test integration_test/retirement_test.dart -d emulator-5554 --no-pub
```
