//! 时余的纯计算核心。
//!
//! 时间、日历和薪资计算将在此实现，调用方需显式提供当前时间与时区。
//! 当前提供版本化契约、基础日历与五类时间指标。

mod calendar;
mod contract;
mod diagnostics;
mod metrics;
mod snapshot;
mod validation;

pub use diagnostics::bridge_probe;
pub use snapshot::{compute_snapshot, default_settings, validate_settings};
