/// 通过锁文件固定 UniFFI 生成器版本，避免依赖全局安装的工具。
fn main() {
    uniffi::uniffi_bindgen_main();
}
