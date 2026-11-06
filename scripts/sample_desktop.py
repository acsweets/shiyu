"""采集真实进程的驻留内存、CPU 时间与连续存活时长。"""

import argparse
import ctypes
from ctypes import wintypes
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


class WindowsProcess:
    class Memory(ctypes.Structure):
        _fields_ = [("size", wintypes.DWORD), ("faults", wintypes.DWORD)] + [
            (name, ctypes.c_size_t)
            for name in ("peak", "resident", "paged_peak", "paged",
                         "nonpaged_peak", "nonpaged", "pagefile", "pagefile_peak")
        ]

    def __init__(self, pid: int):
        self.kernel = ctypes.WinDLL("kernel32", use_last_error=True)
        self.psapi = ctypes.WinDLL("psapi", use_last_error=True)
        self.kernel.OpenProcess.argtypes = (wintypes.DWORD, wintypes.BOOL, wintypes.DWORD)
        self.kernel.OpenProcess.restype = wintypes.HANDLE
        self.kernel.CloseHandle.argtypes = (wintypes.HANDLE,)
        self.kernel.GetExitCodeProcess.argtypes = (wintypes.HANDLE, ctypes.POINTER(wintypes.DWORD))
        self.kernel.GetProcessTimes.argtypes = (wintypes.HANDLE,) + (
            ctypes.POINTER(wintypes.FILETIME),
        ) * 4
        self.psapi.GetProcessMemoryInfo.argtypes = (
            wintypes.HANDLE, ctypes.POINTER(self.Memory), wintypes.DWORD,
        )
        self.handle = self.kernel.OpenProcess(0x0400 | 0x0010, False, pid)
        if not self.handle:
            raise ctypes.WinError(ctypes.get_last_error())

    @staticmethod
    def _seconds(value: wintypes.FILETIME) -> float:
        ticks = (value.dwHighDateTime << 32) | value.dwLowDateTime
        return ticks / 10_000_000

    def read(self) -> tuple[float, int]:
        code = wintypes.DWORD()
        if not self.kernel.GetExitCodeProcess(self.handle, ctypes.byref(code)):
            raise ctypes.WinError(ctypes.get_last_error())
        if code.value != 259:
            raise ProcessLookupError(f"进程已退出，退出码 {code.value}")
        created, exited, kernel, user = (wintypes.FILETIME() for _ in range(4))
        if not self.kernel.GetProcessTimes(
            self.handle, ctypes.byref(created), ctypes.byref(exited),
            ctypes.byref(kernel), ctypes.byref(user),
        ):
            raise ctypes.WinError(ctypes.get_last_error())
        memory = self.Memory()
        memory.size = ctypes.sizeof(memory)
        if not self.psapi.GetProcessMemoryInfo(
            self.handle, ctypes.byref(memory), memory.size,
        ):
            raise ctypes.WinError(ctypes.get_last_error())
        return self._seconds(kernel) + self._seconds(user), memory.resident

    def close(self) -> None:
        self.kernel.CloseHandle(self.handle)


class MacProcess:
    def __init__(self, pid: int):
        self.pid = pid
        self.start = None

    def read(self) -> tuple[float, int]:
        result = subprocess.run(
            ["/bin/ps", "-p", str(self.pid), "-o", "time=", "-o", "rss=", "-o", "lstart="],
            capture_output=True, text=True, check=False,
        )
        if result.returncode or not result.stdout.strip():
            raise ProcessLookupError("进程已退出")
        cpu, rss, started = result.stdout.strip().split(maxsplit=2)
        if self.start is not None and started != self.start:
            raise ProcessLookupError("PID 已被另一进程复用")
        self.start = started
        days, separator, clock = cpu.partition("-")
        seconds = int(days) * 86400 if separator else 0
        seconds += sum(
            float(value) * 60 ** power
            for power, value in enumerate(reversed((clock if separator else days).split(":")))
        )
        return seconds, int(rss) * 1024

    def close(self) -> None:
        pass


def collect(pid: int, seconds: int, interval: int, output: Path) -> int:
    if sys.platform not in ("win32", "darwin"):
        raise ValueError("仅支持 Windows 和 macOS")
    process = WindowsProcess(pid) if sys.platform == "win32" else MacProcess(pid)
    processors = os.cpu_count() or 1
    try:
        with output.open("x", encoding="utf-8") as log:
            def record(data: dict) -> None:
                log.write(json.dumps({"utc": utc_now(), **data}, ensure_ascii=False) + "\n")
                log.flush()

            record({"event": "start", "pid": pid, "requested_seconds": seconds,
                    "platform": sys.platform, "logical_processors": processors})
            begin = time.monotonic()
            count = 0
            peak = 0
            total_resident = 0
            first_cpu = 0.0
            previous = begin
            try:
                while True:
                    cpu, resident = process.read()
                    now = time.monotonic()
                    duration = now - begin
                    peak = max(peak, resident)
                    total_resident += resident
                    if count == 0:
                        first_cpu = cpu
                    count += 1
                    record({"event": "sample", "elapsed_seconds": round(duration, 3),
                            "sample_gap_seconds": round(now - previous, 3),
                            "cpu_seconds": cpu, "resident_bytes": resident})
                    previous = now
                    if duration >= seconds:
                        break
                    time.sleep(min(interval, seconds - duration))
            except (OSError, KeyboardInterrupt) as error:
                record({"event": "interrupted", "samples": count,
                        "elapsed_seconds": round(time.monotonic() - begin, 3),
                        "reason": str(error) or type(error).__name__})
                return 1

            core_pct = (cpu - first_cpu) * 100 / duration
            summary = {"event": "complete", "samples": count,
                       "elapsed_seconds": round(duration, 3), "cpu_pct_one_core": round(core_pct, 3),
                       "cpu_pct_system": round(core_pct / processors, 3),
                       "mean_resident_mib": round(total_resident / count / 2**20, 2),
                       "peak_resident_mib": round(peak / 2**20, 2)}
            record(summary)
            print(json.dumps(summary, ensure_ascii=False))
            return 0
    finally:
        process.close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pid", required=True, type=int)
    parser.add_argument("--seconds", type=int, default=604800)
    parser.add_argument("--interval", type=int, default=60)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if min(args.pid, args.seconds, args.interval) < 1:
        parser.error("PID、时长和采样间隔必须为正整数")
    return collect(args.pid, args.seconds, args.interval, args.output)


if __name__ == "__main__":
    raise SystemExit(main())
