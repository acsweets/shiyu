# 节点 11 移动首页与共享容器

前置版本为 `834a37d`，实现版本以本报告所在提交为准。[节点计划](../../开发计划/11-移动应用与共享容器.md)

## 操作入口

- 首次安装沿用三步引导。进入首页后可查看上下班、放假、发薪、生命、退休、今日与本月薪资。点击右上角齿轮打开设置，小屏或系统放大字体时首页改为单列。
- 设置中的「通用设置」负责语言、地区、作息、发薪、薪资与金额遮蔽。移动页面保留从桌面设置导入的合法自定义倒计时字段，不提供该字段的编辑入口。
- 在「主屏幕小组件」查看系统添加方式。切换语言、地区、金额遮蔽和作息会更新原生共享数据并请求刷新；假日更新与导入成功也会同步。

## 数据和回退

Android 用应用私有文件和 AtomicFile，iOS 用 App Group `group.com.growthrecord.shiyu` 的原子文件写入。地区文件分别存放，包含共享契约版本、地区、数据版本、Rust 日历和 SHA-256。原生组件按已校验设置的地区选择日历，损坏时读同地区副本，缺失时使用 Rust 周工作日规则。

原生入口优先校验主设置，缺失或损坏时尝试最近一次有效副本，再使用默认设置。回退路径强制金额遮蔽。主应用的只读恢复入口继续保留可显式恢复的合法副本。iOS App Group 不可访问时，首页提示检查共享存储，扩展按默认设置显示。

## 验证命令

```powershell
./scripts/check.ps1
cd app
flutter test integration_test/retirement_test.dart integration_test/salary_timeline_test.dart -d emulator-5554 --no-pub
```

iOS Runner 和扩展的构建、App Group 权限、系统添加与关闭主应用后的运行由用户在 Mac 实测。Android 最低 API 24、真机重启以及全语言逐屏检查仍待复核。

Windows 11 x64 的仓库检查、Release 构建和桌面原生集成通过，含 22 项 Flutter 测试与 16 项 Rust 测试。Android API 36 x86_64 模拟器上两项原生集成通过。Android UniFFI 与 Flutter FRB 的同日历固定时钟快照完整一致；错误摘要被拒绝并保留已保存数据。薪资时间线、金额精度和校验错误由合成数据对比。Android 构建仍报告 flutter_file_dialog 的未来 Kotlin Gradle Plugin 兼容性提示。
