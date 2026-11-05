# 节点 06 六地区节假日与离线数据验收

日期 2026-11-05。前置版本为节点 05 的 `23f2edf`，实现版本以本报告所在的 Git 提交为准。[节点计划](../../开发计划/06-六地区节假日与离线数据.md) · [来源、许可和文件格式](../../决策记录/0003-节假日来源与更新.md)

## 数据抽查

| 地区 | 示例 |
| --- | --- |
| 中国大陆 | 2027-02-05 至 02-13 放假，02-14 周日补班 |
| 美国 | 2027-07-05 为联邦独立日观察日 |
| 日本 | 2026-09-22 为夹在祝日之间的休息日 |
| 韩国 | 2026-07-17 为新增的制宪节公休日 |
| 中国香港 | 2027-02-09 为农历年初四替代假期 |
| 中国台湾 | 2027-12-31 为次年元旦的补假 |

## 已验证

- Dart 自动测试校验六地区内置数据，模拟离线、JSON 损坏、摘要不符、地区与年份错配及回滚。下载失败后重新读取旧缓存，缓存损坏后使用内置数据。无有效数据时返回缺失，Rust 按工作周降级。
- Android 16 x86_64 模拟器使用内置数据进行真实 Rust 计算。2027-02-14 补班计薪，自定义假期覆盖后当天金额为零，个人工作日覆盖后恢复计薪。测试显式关闭启动联网检查，使用临时配置和固定时钟。
- Windows 11 x64 隔离执行 `scripts/check.ps1 -BuildWindows`，Flutter 静态分析、13 项 Flutter 测试、16 项 Rust 测试及 Windows Release 构建通过。
- Windows Debug Runner 的退休集成测试通过，同样覆盖内置日历、补班计薪、自定义假期与个人覆盖。
- 更新器固定使用 `GET /acsweets/shiyu/main/app/assets/holidays/calendar.json`，Host 为 `raw.githubusercontent.com`。请求不含查询参数、自定义标识头或请求体，拒绝重定向。更新与缓存路径由自动测试覆盖。

## 用户复核

桌面在「倒计时」设置中找到节假日数据。手机在设置页下方查看同一入口。可断网启动，确认界面仍显示地区、年份和版本。手动检查或导入失败时，原数据应继续可用。有效单地区文件的准备方法见来源文档。

Apple 文件选择器、联网权限和实际运行待在 Mac 复核。移动小组件的共享日历接入在节点 11/12。

```powershell
./scripts/check.ps1 -BuildWindows
cd app
flutter test integration_test/retirement_test.dart -d windows --no-pub
flutter test integration_test/retirement_test.dart -d emulator-5554 --no-pub
```
