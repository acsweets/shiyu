# 节点 04 薪资与自定义倒计时验收

日期 2026-11-05，前置核心基线 `1a618b1`。实现版本以本报告所属 Git 提交为准。[节点计划与检查点](../../开发计划/04-薪资与自定义倒计时核心.md) · [数据契约](../../技术说明/数据契约-v1.md)

## 可以复核的结果

| 合成输入 | 预期 |
| --- | --- |
| 上海 2026 年 1 月，月薪 22000、22 个应出勤日、09:00–18:00、12:00–13:00 午休 | 1 月 5 日 12:00 今日已赚 375.00，本月 2375.00。午休保持不变，18:00 今日 1000.00 |
| 20 个应出勤日，月薪 1000，有效工作 8 小时，上班经过 1 秒 | 两位 0.00、三位 0.001、四位 0.0017 |
| 1 月末结束计薪，随后进入 2 月 | 1 月本月金额结清为 22000.00，2 月重新按本月应出勤日计算 |
| 上述配置开启隐藏金额 | 单点与时间线的两项金额都为 `****` |
| 创建「产品上线」，目标为时间线首项之后 1 秒 | 三个相隔 1 秒的快照剩余秒数为 1、0、0，后两项已到期 |

[薪资黄金样例](../../../core/testdata/salary_cases.json)包含 15 组设置和 24 个固定时钟检查，覆盖调休、自定义假期、夏令时、重新计薪、税后、极限金额与零工时。另按分钟检查 543 个时刻的有效工时和精确分摊。

## Release 性能

Windows 11 x64，Intel Core i9-14900HX，Rust 1.95.0，单线程，固定 UTC 毫秒。每组预热 1000 次，采样 10000 次。测量包含解析输入、计算与序列化。申请字节数包含重新分配，用于衡量每次调用的分配量。

| 工作负载 | 平均 µs | p50 µs | p95 µs | p99 µs | 分配次数/次 | 申请字节/次 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 默认设置 | 4.90 | 4.80 | 6.70 | 8.20 | 34 | 5339 |
| 薪资、合成假日及 20 个倒计时 | 27.06 | 25.40 | 38.70 | 63.10 | 132 | 27111 |

两组 p95 均低于 1 ms。本表记录固定设备与数据的实测结果。

## 平台验证

| 环境 | 验证 | 结果 |
| --- | --- | --- |
| Windows 11 x64 | `scripts/check.ps1 -BuildWindows`、Rust workspace Debug、Windows UniFFI C ABI | 通过格式、静态分析、Flutter 7 项测试和 Rust 16 项测试。隔离工作目录成功构建 Windows Release。实际调用 Windows DLL 的新增符号，核对金额字符串、到期和负步长错误 |
| Windows 11 x64 | Rust workspace Release、Flutter FRB 集成 | 16 项 Rust 测试通过。Flutter 从真实 Rust 读取固定金额和到期状态 |
| Android 16 x86_64 模拟器 | Flutter FRB 与 Kotlin UniFFI 集成 | 同一组输入的完整时间线一致。普通调试 APK 通过 Rust ELF 校验并完成安装与启动 |
| macOS / iOS | Swift smoke 与真实宿主 | Swift 语法、新生成的 Swift/C 入口已静态核对。运行、签名和相同输入对照待 Mac |

## 复跑命令

```powershell
cargo test --manifest-path core/Cargo.toml --workspace --release --locked
cargo test --manifest-path core/Cargo.toml -p shiyu_core --locked --test salary_and_countdowns_tests
cargo bench --manifest-path core/Cargo.toml -p shiyu_core --locked --bench compute_snapshot
./scripts/check.ps1 -BuildWindows
cd app
flutter test integration_test/salary_timeline_test.dart -d windows
flutter test integration_test/salary_timeline_test.dart -d emulator-5554
```

Mac 运行 `bash scripts/check_apple.sh` 验证 Swift UniFFI 与构建，再在 `app/` 运行 `flutter test integration_test/salary_timeline_test.dart -d macos` 对照 Flutter。新增能力目前通过核心接口验收，正式薪资界面和桌面倒计时编辑与持久化依后续节点推进。
