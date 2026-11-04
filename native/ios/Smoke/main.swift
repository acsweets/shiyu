import Foundation

// 在 Mac 上验证生成的 Swift 绑定实际调用同一个 Rust 核心。
precondition(bridgeProbe(challenge: 41) == "shiyu-core:42")
precondition(bridgeProbe(challenge: UInt32.max) == "shiyu-core:0")
print("Swift -> UniFFI -> shiyu_core: PASS")
