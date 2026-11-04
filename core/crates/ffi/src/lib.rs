//! 原生小组件的 UniFFI 门面，与 Flutter 共享同一个计算核心。

uniffi::setup_scaffolding!();

/// 验证原生调用链，不访问网络、配置或个人数据。
#[uniffi::export]
pub fn bridge_probe(challenge: u32) -> String {
    shiyu_core::bridge_probe(challenge)
}
