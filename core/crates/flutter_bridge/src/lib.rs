//! Flutter 绑定入口；业务实现始终保留在 shiyu_core。

pub mod api;
mod frb_generated;

// 保留 UniFFI 导出符号，使 Flutter 和原生端使用同一份打包库。
shiyu_ffi::uniffi_reexport_scaffolding!();
