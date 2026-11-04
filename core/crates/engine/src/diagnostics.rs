/// 返回与挑战值相关的确定性结果，供不同语言验证真实 Rust 调用。
pub fn bridge_probe(challenge: u32) -> String {
    format!("shiyu-core:{}", challenge.wrapping_add(1))
}

#[cfg(test)]
mod tests {
    use super::bridge_probe;

    #[test]
    fn probe_handles_values_and_unsigned_boundary() {
        assert_eq!(bridge_probe(41), "shiyu-core:42");
        assert_eq!(bridge_probe(0), "shiyu-core:1");
        assert_eq!(bridge_probe(u32::MAX), "shiyu-core:0");
    }
}
