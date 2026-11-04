#!/usr/bin/env bash
set -euo pipefail

# Xcode Widget target 独立构建纯 UniFFI 静态库，不链接 Flutter 引擎。
project_root="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/.cargo/bin:$PATH"
output_dir="$BUILT_PRODUCTS_DIR/ShiyuWidgetCore"
target_dir="$DERIVED_FILE_DIR/WidgetRust"
mkdir -p "$output_dir"
libraries=()
for architecture in $ARCHS; do
  case "$PLATFORM_NAME:$architecture" in
    iphoneos:arm64) target=aarch64-apple-ios ;;
    iphonesimulator:arm64) target=aarch64-apple-ios-sim ;;
    iphonesimulator:x86_64) target=x86_64-apple-ios ;;
    *) echo "Unsupported widget platform: $PLATFORM_NAME / $architecture" >&2; exit 1 ;;
  esac
  rustup target add --toolchain 1.95.0 "$target"
  cargo +1.95.0 build --manifest-path "$project_root/core/Cargo.toml" -p shiyu_ffi \
    --target "$target" --target-dir "$target_dir" --release --locked
  libraries+=("$target_dir/$target/release/libshiyu_ffi.a")
done
xcrun lipo -create "${libraries[@]}" -output "$output_dir/libshiyu_ffi.a"
