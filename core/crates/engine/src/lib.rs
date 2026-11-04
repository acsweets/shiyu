//! 时余的纯计算核心。
//!
//! 时间、日历和薪资计算将在此实现，调用方需显式提供当前时间与时区。
//! 当前仅提供 M0 链路探测，不包含业务计算。

mod diagnostics;

pub use diagnostics::bridge_probe;
