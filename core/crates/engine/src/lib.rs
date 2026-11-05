//! 时余的纯计算核心。
//!
//! 时间、日历和薪资计算将在此实现，调用方需显式提供当前时间与时区。
//! 提供版本化契约、基础日历、六类内置指标及自定义倒计时。

mod calendar;
mod contract;
mod custom_countdown;
mod diagnostics;
mod display;
mod metrics;
mod salary_amount;
mod snapshot;
mod timeline;
mod validation;

pub use custom_countdown::update_custom_countdown;
pub use diagnostics::bridge_probe;
pub use snapshot::{compute_snapshot, default_settings, validate_settings};
pub use timeline::compute_timeline;
