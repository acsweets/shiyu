/// 将探测挑战交给共享核心，供 Flutter 验证绑定和动态库打包。
pub fn bridge_probe(challenge: u32) -> String {
    shiyu_core::bridge_probe(challenge)
}
