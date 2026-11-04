#!/usr/bin/env bash
set -euo pipefail

# 本脚本只在 Mac 上运行；不通过 Windows 推断 Apple 平台结果。
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This check requires macOS and Xcode." >&2
  exit 1
fi
project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root/core"
cargo build -p shiyu_ffi --locked
target_dir="$(cargo metadata --format-version 1 --no-deps | python3 -c 'import json,sys; print(json.load(sys.stdin)["target_directory"])')"
mkdir -p "$project_root/.tooling"
swiftc "$project_root/native/ios/Generated/ShiyuCore.swift" \
  "$project_root/native/ios/Smoke/main.swift" \
  -I "$project_root/native/ios/Generated" -L "$target_dir/debug" \
  -Xcc "-fmodule-map-file=$project_root/native/ios/Generated/ShiyuCoreFFI.modulemap" \
  -lshiyu_ffi -o "$project_root/.tooling/swift-probe"
DYLD_LIBRARY_PATH="$target_dir/debug${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" "$project_root/.tooling/swift-probe"
cd "$project_root/app"
flutter pub get --enforce-lockfile
flutter build macos --release
flutter build ios --simulator --debug
echo "Apple builds passed; run the integration tests and inspect platform behavior on your devices."
