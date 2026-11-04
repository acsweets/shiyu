"""核对 APK 中的 Rust 动态库，防止只生成外壳却遗漏原生依赖。"""

import argparse
from pathlib import Path
import struct
import zipfile


def verify_package(apk_path: Path, abi: str) -> None:
    """验证 Rust 库存在、非空且为目标 ABI 对应的 ELF 文件。"""
    machines = {"x86_64": 62, "arm64-v8a": 183, "armeabi-v7a": 40}
    library_path = f"lib/{abi}/libshiyu_bridge.so"
    with zipfile.ZipFile(apk_path) as archive:
        with archive.open(library_path) as library:
            header = library.read(20)
        if header[:4] != b"\x7fELF" or header[5] != 1:
            raise ValueError(f"不是有效的小端 ELF 动态库：{library_path}")
        machine = struct.unpack_from("<H", header, 18)[0]
        if machine != machines[abi]:
            raise ValueError(f"ABI 不匹配：{library_path}，实际 machine={machine}")
        print(f"PASS: {library_path}, {archive.getinfo(library_path).file_size} bytes")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--abi", choices=["x86_64", "arm64-v8a", "armeabi-v7a"], default="x86_64")
    args = parser.parse_args()
    verify_package(args.apk, args.abi)


if __name__ == "__main__":
    main()
